import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'ping_service.dart';

class SpeedTestResult {
  final int averagePing;
  final int jitter;
  final double downloadSpeedMbps;

  SpeedTestResult({
    required this.averagePing,
    required this.jitter,
    required this.downloadSpeedMbps,
  });
}

class SpeedTestService {
  final PingService _pingService = PingService();
  
  // Cloudflare provides a standard speedtest payload endpoint.
  // We request exactly 15MB to generate enough time variance for accurate speed indexing.
  final String _downloadUrl = 'https://speed.cloudflare.com/__down?bytes=15000000';
  final String _pingTarget = '1.1.1.1'; // Cloudflare DNS as a baseline for ping/jitter

  Future<SpeedTestResult> runFullTest({
    Function(String status)? onProgress,
  }) async {
    // 1. Calculate Ping and Jitter
    onProgress?.call('Pinging server...');
    List<int> pings = [];
    for (int i = 0; i < 5; i++) {
      final p = await _pingService.pingAddress(_pingTarget);
      if (p != null) pings.add(p);
      await Future.delayed(const Duration(milliseconds: 100)); // slight delay between pings
    }

    int avgPing = 0;
    int jitter = 0;

    if (pings.isNotEmpty) {
      avgPing = (pings.reduce((a, b) => a + b) / pings.length).round();
      
      // Calculate Jitter (Mean Deviation from Average)
      double totalDeviation = 0;
      for (var p in pings) {
        totalDeviation += (p - avgPing).abs();
      }
      jitter = (totalDeviation / pings.length).round();
    }

    // 2. Calculate Download Speed
    onProgress?.call('Testing download speed...');
    double downloadMbps = 0.0;
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_downloadUrl));
      
      final stopwatch = Stopwatch()..start();
      final response = await client.send(request);
      
      int totalBytes = 0;
      final completer = Completer<void>();
      
      response.stream.listen(
        (List<int> chunk) {
          totalBytes += chunk.length;
        },
        onDone: () {
          stopwatch.stop();
          completer.complete();
        },
        onError: (e) {
          stopwatch.stop();
          completer.complete();
        },
      );
      
      await completer.future;
      client.close();

      final elapsedMilliseconds = stopwatch.elapsedMilliseconds;
      if (elapsedMilliseconds > 0 && totalBytes > 0) {
        // Convert Bytes to Bits
        final bits = totalBytes * 8;
        // Bits per millisecond = Kilobits per second
        // Megabits per second = Kilobits / 1000
        final bitsPerSecond = (bits / elapsedMilliseconds) * 1000;
        downloadMbps = bitsPerSecond / 1000000;
      }
    } catch (e) {
      // Ignore download errors and just return 0
    }

    return SpeedTestResult(
      averagePing: avgPing,
      jitter: jitter,
      downloadSpeedMbps: double.parse(downloadMbps.toStringAsFixed(2)),
    );
  }
}
