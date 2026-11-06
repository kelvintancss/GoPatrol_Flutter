import 'package:dio_client/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:patrol/core/utils/constants.dart';
import 'package:patrol/core/utils/ping_helper.dart';
import 'package:patrol/service_locator.dart';

class ConnectionCheckerScreen extends StatefulWidget {
  const ConnectionCheckerScreen({super.key});

  @override
  State<ConnectionCheckerScreen> createState() =>
      _ConnectionCheckerScreenState();
}

class _ConnectionCheckerScreenState extends State<ConnectionCheckerScreen> {
  late final PingHelper pingHelper = PingHelper(dio: sl<DioClient>().dioObject);
  Map<String, dynamic>? results;
  bool isLoading = false;

  String get serverUrl => Constants.apiBaseUrl;

  Future<void> runPing() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final res = await pingHelper.fullConnectionCheck(serverUrl);
      if (!mounted) return;
      setState(() => results = res);

      if (res['hasInternet'] == true && res['isGood'] == true) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => results = {'error': e.toString()});
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    runPing();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInternet = results?['hasInternet'] == true;
    final bool isGood = results?['isGood'] == true;
    final bool isPoor = hasInternet && !isGood;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        Navigator.pop(context, false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connection Checker'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (results != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusRow('Internet', hasInternet),
                            _buildResultRow(
                              'Avg Latency',
                              '${results!['avgLatencyMs'] ?? 'N/A'} ms',
                            ),
                            _buildStatusRow('Status', null, isPoor: isPoor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Continue Anyway'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : runPing,
                      child: const Text('Retry Test'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool? value, {bool isPoor = false}) {
    String statusText = '';
    Color statusColor = Colors.grey;

    if (label == 'Internet') {
      statusText = value == true ? 'Connected' : 'Disconnected';
      statusColor = value == true ? Colors.green : Colors.red;
    } else if (label == 'Status') {
      final bool hasInternet = results?['hasInternet'] == true;

      if (!hasInternet) {
        statusText = 'No Internet Connection';
        statusColor = Colors.red;
      } else if (isPoor) {
        statusText = 'Poor/Slow Connection';
        statusColor = Colors.orange;
      } else {
        statusText = 'Good Connection';
        statusColor = Colors.green;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
