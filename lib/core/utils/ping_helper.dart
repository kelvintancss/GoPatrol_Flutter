import 'dart:async';
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class PingHelper {
  final Dio dio;

  PingHelper({required this.dio});

  /// TCP Connection Test like VMS
  Future<Map<String, dynamic>> tcpPing(
    String host, {
    int port = 443,
    int timeoutMs = 5000,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      ).timeout(Duration(milliseconds: timeoutMs));
      socket.destroy();
      stopwatch.stop();

      return {
        'success': true,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'type': 'tcp',
        'message': 'TCP to $host:$port succeeded',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': null,
        'type': 'tcp',
        'message': 'TCP failed: $e',
      };
    }
  }

  /// ICMP Ping using dart_ping:^10.0.0
  Future<Map<String, dynamic>> icmpPing(String host, {int count = 4}) async {
    final ping = Ping(host, count: count);
    final List<PingEvent> events = [];

    await for (final event in ping.stream) {
      events.add(event);
    }

    final responses = events.whereType<PingResponse>();
    final errors = events.whereType<PingError>();
    final summary = events.whereType<PingSummary>().firstOrNull;

    final successful = responses.length;
    final total = count;

    // Calculate average latency from successful responses
    final latencies = responses
        .map((r) => r.time?.inMilliseconds ?? 0)
        .where((ms) => ms > 0);

    final avgLatency = latencies.isNotEmpty
        ? (latencies.reduce((a, b) => a + b) / latencies.length).round()
        : null;

    final packetLoss = summary?.packetLoss ?? (successful == 0 ? 100 : 0);

    return {
      'success': successful > 0,
      'latencyMs': avgLatency,
      'packetsTransmitted': total,
      'packetsReceived': successful,
      'packetLoss': packetLoss,
      'type': 'icmp',
      'message':
          '$successful/$total received (${packetLoss.toStringAsFixed(0)}% loss)',
    };
  }

  /// HTTP Ping (most realistic for your app)
  Future<Map<String, dynamic>> httpPing(
    String url, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await dio.head(
        url,
        options: Options(sendTimeout: timeout, receiveTimeout: timeout),
      );
      stopwatch.stop();
      return {
        'success': true,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'statusCode': response.statusCode,
        'type': 'http',
        'message': 'HTTP ping successful',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'type': 'http',
        'message': 'HTTP failed: ${e.toString()}',
      };
    }
  }

  /// Full connection check
  Future<Map<String, dynamic>> fullConnectionCheck(String serverUrl) async {
    final uri = Uri.parse(serverUrl);
    final host = uri.host.isNotEmpty ? uri.host : serverUrl;

    final results = <String, dynamic>{};

    // 1. Basic internet access
    final hasInternet = await InternetConnection().hasInternetAccess;
    results['hasInternet'] = hasInternet;

    if (!hasInternet) {
      results['overall'] = 'No internet connection';
      return results;
    }

    // 2. TCP Ping
    final tcp = await tcpPing(host);
    results['tcp'] = tcp;

    // 3. ICMP Ping (best effort)
    try {
      final icmp = await icmpPing(host);
      results['icmp'] = icmp;
    } catch (e) {
      results['icmp'] = {'success': false, 'message': 'ICMP unavailable: $e'};
    }

    // 4. HTTP Ping to your actual server
    final http = await httpPing(serverUrl);
    results['http'] = http;

    // Overall assessment
    final validLatencies = [
      tcp['latencyMs'],
      results['icmp']?['latencyMs'],
      http['latencyMs'],
    ].whereType<int>().toList();

    final avgLatency = validLatencies.isNotEmpty
        ? validLatencies.reduce((a, b) => a + b) ~/ validLatencies.length
        : 9999;

    results['avgLatencyMs'] = avgLatency;
    results['isGood'] = avgLatency < 1200 && http['success'] == true;
    return results;
  }
}
