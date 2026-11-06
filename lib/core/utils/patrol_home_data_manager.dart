import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:patrol/core/repository/patrol_repository.dart';
import 'package:patrol/core/utils/log_entry.dart';
import 'package:patrol/core/utils/patrol_home_data_db.dart';
import 'package:patrol/service_locator.dart';

/// Silently keeps the home page's facility/patrol snapshot fresh.
///
/// [start] is meant to be called once, from the home page's first entry —
/// it fetches immediately and then keeps refreshing every 5 minutes for the
/// rest of the app's lifetime. No loading UI, no error surfaced; a failed
/// fetch just leaves the previous snapshot in place until the next tick.
class PatrolHomeDataManager with WidgetsBindingObserver {
  static const _pollInterval = Duration(minutes: 5);

  Timer? _timer;

  /// When the next background fetch is due — read directly by
  /// [HomeDateTimeWidget] each second to render a "Next Sync" countdown.
  final ValueNotifier<DateTime?> nextSyncAt = ValueNotifier(null);

  /// Latest saved snapshot — read by [HomePage] (via `ValueListenableBuilder`)
  /// to drive the project name and the Visitor Log tile's visibility.
  final ValueNotifier<PatrolHomeData?> homeData = ValueNotifier(null);

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _restartTimer();
    _loadCachedHomeData();
    fetchNow();
  }

  Future<void> _loadCachedHomeData() async {
    homeData.value = await PatrolHomeDataDatabase.instance.get();
  }

  /// (Re)schedules the periodic tick from now, resetting [nextSyncAt].
  ///
  /// Used both for the initial [start] and to realign the schedule after a
  /// background resume, so the next real tick is a full interval away
  /// instead of firing again almost immediately.
  void _restartTimer() {
    _timer?.cancel();
    _scheduleNextSync();
    _timer = Timer.periodic(_pollInterval, (_) {
      _scheduleNextSync();
      fetchNow();
    });
  }

  void _scheduleNextSync() {
    nextSyncAt.value = DateTime.now().add(_pollInterval);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    nextSyncAt.value = null;
    homeData.value = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // The OS can freeze the whole process (and its Timers) while
    // backgrounded, so a stale/past nextSyncAt here means the periodic tick
    // never actually fired while we were away — the "Next Sync" countdown
    // would otherwise sit at 00:00 until the frozen Timer eventually
    // catches up on its own. Catch up immediately instead.
    final next = nextSyncAt.value;
    if (next == null || !next.isAfter(DateTime.now())) {
      _restartTimer();
      fetchNow();
    }
  }

  Future<void> fetchNow() async {
    if (!await _hasInternet()) {
      AppLogger.instance.network(
        '[PatrolHomeData] fetchNow skipped — no internet access detected',
      );
      return;
    }

    try {
      final result = await sl<PatrolRepository>().getPatrolHomeData();
      if (!result.success) {
        AppLogger.instance.error(
          '[PatrolHomeData] getPatrolHomeData failed: ${result.message}',
        );
        return;
      }
      await PatrolHomeDataDatabase.instance.save(
        facility: result.facility ?? '',
        patrol: result.patrol ?? '',
        incident: result.incident ?? '',
        incidentDigitalForm: result.incidentDigitalForm ?? '',
        checkin: result.checkin ?? '',
        checkout: result.checkout ?? '',
        vmsActive: result.vmsActive,
        projectName: result.projectName ?? '',
      );
      final saved = await PatrolHomeDataDatabase.instance.get();
      homeData.value = saved;
      AppLogger.instance.info(
        '[PatrolHomeData] saved — facility len ${saved?.facility.length ?? -1}, '
        'patrol len ${saved?.patrol.length ?? -1}, '
        'incident len ${saved?.incident.length ?? -1}, '
        'incidentDigitalForm len ${saved?.incidentDigitalForm.length ?? -1}, '
        'checkin len ${saved?.checkin.length ?? -1}, '
        'checkout len ${saved?.checkout.length ?? -1}, '
        'vmsActive ${saved?.vmsActive}, projectName ${saved?.projectName}, '
        'updatedAt ${saved?.updatedAt}',
      );
    } catch (e) {
      // Silent to the user — the next 5-minute tick retries — but logged so
      // a failed save is diagnosable after the fact.
      AppLogger.instance.error('[PatrolHomeData] fetchNow threw: $e');
    }
  }

  Future<bool> _hasInternet() async {
    try {
      // Bounded even if the underlying check ever hangs (e.g. DNS stalls
      // instead of failing fast), so this never stalls the caller.
      return await InternetConnection().hasInternetAccess.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }
}
