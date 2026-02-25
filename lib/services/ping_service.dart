import 'dart:io';

class PingService {
  Future<int?> pingAddress(String address) async {
    try {
      if (Platform.isWindows) {
        var result = await Process.run('ping', ['-n', '1', address]);
        final output = result.stdout.toString();
        // Parse time=xxms
        final regex = RegExp(r'time[=<](\d+)ms');
        final match = regex.firstMatch(output);
        if (match != null) {
          return int.parse(match.group(1)!);
        }
      } else {
        // Linux / macOS format
        var result = await Process.run('ping', ['-c', '1', address]);
        final output = result.stdout.toString();
        // Parse time=xx ms
        final regex = RegExp(r'time[=<]?([\d.]+)\s*ms');
        final match = regex.firstMatch(output);
        if (match != null) {
          return double.parse(match.group(1)!).toInt();
        }
      }
    } catch (e) {
      print('Ping Error: $e');
    }
    return null;
  }
}
