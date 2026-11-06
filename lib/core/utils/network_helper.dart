import 'dart:async';

import 'package:patrol/core/utils/log_entry.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Listen the internet connection status
/// log the status
class NetworkHelper {
  late StreamSubscription<InternetStatus>? subscription;
  static bool _lostConnect = false;
  static bool get lostConnect => _lostConnect;

  NetworkHelper() {
    subscription = InternetConnection().onStatusChange.listen((InternetStatus status) async {
      if (status == InternetStatus.connected) {
        // Internet is connected
        _lostConnect = false;
        await AppLogger.instance.log("Network connection restored");
      } else {
        // Internet is disconnected
        _lostConnect = true;
      }
    });
  }

  void dispose() {
    subscription?.cancel();
  }
}
