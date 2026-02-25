import 'dart:io';
import 'dart:convert';
import 'package:process_run/shell.dart';

class DnsEngine {
  final Shell shell = Shell();

  Future<void> _runElevated(String scriptContent) async {
    // Encode the script to Base64 to bypass all escaping/quote issues in PowerShell
    final encodedCommand = base64Encode(utf16.encode(scriptContent));
    
    // Elevates to Administrator silently avoiding shell freeze
    await Process.run('powershell', [
      '-WindowStyle', 'Hidden',
      '-Command',
      'Start-Process powershell -WindowStyle Hidden -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -EncodedCommand $encodedCommand" -Wait'
    ]);
  }

  Future<void> setDns(String primary, String secondary) async {
    if (Platform.isWindows) {
      String servers = secondary.isNotEmpty ? '"$primary", "$secondary"' : '"$primary"';
      String script = '''
\$adapters = Get-NetAdapter | Where-Object { \$_.Status -eq 'Up' -and \$_.Virtual -eq \$false }
foreach (\$adapter in \$adapters) {
    Set-DnsClientServerAddress -InterfaceAlias \$adapter.Name -ServerAddresses $servers
}
      ''';
      await _runElevated(script);
    } else if (Platform.isLinux) {
      try {
        await shell.run('resolvectl dns wlan0 $primary $secondary');
      } catch (e) {
         print("Linux DNS set error: $e");
      }
    }
  }

  Future<void> clearDns() async {
    if (Platform.isWindows) {
      String script = '''
\$adapters = Get-NetAdapter | Where-Object { \$_.Status -eq 'Up' -and \$_.Virtual -eq \$false }
foreach (\$adapter in \$adapters) {
    Set-DnsClientServerAddress -InterfaceAlias \$adapter.Name -ResetServerAddresses
}
      ''';
      await _runElevated(script);
    } else if (Platform.isLinux) {
      try {
        await shell.run('resolvectl revert wlan0');
      } catch(e) {}
    }
  }

  Future<void> flushDns() async {
    if (Platform.isWindows) {
      await Process.run('ipconfig', ['/flushdns']);
    } else if (Platform.isLinux) {
      await shell.run('resolvectl flush-caches');
    }
  }
}

// Simple UTF-16LE encoder needed for PowerShell Base64 encoding
final utf16 = Utf16Codec();
class Utf16Codec extends Encoding {
  @override
  Converter<List<int>, String> get decoder => throw UnimplementedError();
  @override
  Converter<String, List<int>> get encoder => _Utf16Encoder();
  @override
  String get name => 'utf-16le';
}

class _Utf16Encoder extends Converter<String, List<int>> {
  @override
  List<int> convert(String string) {
    final units = string.codeUnits;
    final result = <int>[];
    for (final unit in units) {
      result.add(unit & 0xff);
      result.add(unit >> 8);
    }
    return result;
  }
}
