import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:patrol/core/repository/patrol_repository.dart';
import 'package:patrol/core/utils/incident_record_db.dart';
import 'package:patrol/core/utils/patrol_form_photo.dart';
import 'package:patrol/service_locator.dart';

/// Silently syncs locally-saved incident reports to the server.
///
/// Every write stays local-first (sqlite). This only ever attempts to push
/// pending rows when a connection is available, and it never surfaces
/// loading/success/error UI — sync outcome is recorded purely via
/// `incident_record.syncstatus`.
class IncidentSyncManager with WidgetsBindingObserver {
  static const _pollInterval = Duration(minutes: 5);

  Timer? _timer;

  /// Uuids currently being synced.
  final Set<String> _inFlight = {};

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _restartTimer();
    // Timer.periodic only fires after the first interval elapses, so any
    // records left pending from a previous session would otherwise sit
    // untouched for up to 5 minutes after every cold start.
    syncPending();
  }

  /// (Re)schedules the periodic sweep from now.
  ///
  /// Used both for the initial [start] and to realign the schedule after a
  /// background resume, so the next real tick is a full interval away
  /// instead of firing again almost immediately.
  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => syncPending());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // The OS can freeze the whole process (and its Timers) while
    // backgrounded, so pending records may have sat unsynced the entire
    // time away. Realign the schedule and retry immediately instead of
    // waiting on the frozen Timer to eventually catch up on its own.
    _restartTimer();
    syncPending();
  }

  /// Attempts to push a single just-saved incident right away. Fire-and-forget
  /// from the caller's perspective — no loading UI, no error surfaced.
  Future<void> trySyncNow(String uuid) async {
    if (!await _hasInternet()) return;
    final record = await IncidentRecordDatabase.instance.getIncidentByUuid(
      uuid,
    );
    if (record == null) return;
    await _syncRecord(record);
  }

  /// Periodic sweep: if there are pending rows and a connection is
  /// available, push them all.
  Future<void> syncPending() async {
    final pendingCount = await IncidentRecordDatabase.instance
        .getPendingCount();
    if (pendingCount == 0) return;
    if (!await _hasInternet()) return;

    final records = await IncidentRecordDatabase.instance.getPendingIncidents();
    for (final record in records) {
      await _syncRecord(record);
    }
  }

  /// User-triggered retry (e.g. the "Sync Incident" button on the record
  /// list). Unlike [syncPending], this also retries rows already marked
  /// 'fail', since a manual tap is an explicit request to try again.
  ///
  /// Returns false only when there's no connection, so the caller can tell
  /// the user to check their network; true otherwise (regardless of how
  /// individual rows landed — that's reflected per-row via syncstatus).
  Future<bool> syncNow() async {
    if (!await _hasInternet()) return false;

    final records = await IncidentRecordDatabase.instance
        .getUnsyncedIncidents();
    for (final record in records) {
      await _syncRecord(record);
    }
    return true;
  }

  /// Two steps, like the patrol record upload: `/patrol/addincident`, then
  /// (when there are photos) `/patrol/addincidentimage` with the returned
  /// `digital_form_id`. A `partial` record only retries the second step.
  Future<void> _syncRecord(IncidentRecord record) async {
    // trySyncNow and a sweep can overlap — never post one record twice.
    if (!_inFlight.add(record.uuid)) return;
    final db = IncidentRecordDatabase.instance;
    try {
      var current = record;
      if (current.syncStatus != 'partial') {
        if (current.isLegacy) {
          await db.updateSyncStatus(
            current.uuid,
            'fail',
            message: 'Old incident format can no longer be synced.',
          );
          return;
        }
        final result = await sl<PatrolRepository>().addIncident(
          record: current,
        );
        if (!result.success) {
          await db.updateSyncStatus(
            current.uuid,
            'fail',
            message: result.message,
          );
          return;
        }
        if (current.photos.isEmpty) {
          await db.updateSyncStatus(
            current.uuid,
            'success',
            message: result.message,
          );
          return;
        }
        final digitalFormId = result.digitalFormId ?? '';
        if (digitalFormId.isNotEmpty) {
          await db.setDigitalFormId(current.uuid, digitalFormId);
        }
        await db.updateSyncStatus(
          current.uuid,
          'partial',
          message: digitalFormId.isEmpty
              ? 'Photos not uploadable: no digital_form_id returned.'
              : result.message,
        );
        current = await db.getIncidentByUuid(current.uuid) ?? current;
      }
      await _uploadPhotos(current);
    } catch (e) {
      await db.updateSyncStatus(
        record.uuid,
        record.syncStatus == 'partial' ? 'partial' : 'fail',
        message: e.toString(),
      );
    } finally {
      _inFlight.remove(record.uuid);
    }
  }

  Future<void> _uploadPhotos(IncidentRecord record) async {
    final db = IncidentRecordDatabase.instance;
    final photos = record.photos;
    if (photos.isEmpty) {
      await db.updateSyncStatus(record.uuid, 'success', message: 'Success');
      return;
    }
    // No id to attach the photos to — nothing a retry could fix.
    if (record.digitalFormId.isEmpty) return;

    final result = await sl<PatrolRepository>().addIncidentImage(
      digitalFormId: record.digitalFormId,
      photos: photos,
    );
    if (!result.success) {
      await db.updateSyncStatus(
        record.uuid,
        'partial',
        message: 'Photo upload failed: ${result.message ?? '-'}',
      );
      return;
    }
    await PatrolFormPhotoStore.deleteFiles(photos.map((p) => p.path));
    await db.markPhotosUploaded(record.uuid);
    await db.updateSyncStatus(record.uuid, 'success', message: 'Success');
  }

  Future<bool> _hasInternet() async {
    try {
      // Bounded even if the underlying check ever hangs (e.g. DNS stalls
      // instead of failing fast), so callers always get a timely answer.
      return await InternetConnection().hasInternetAccess.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }
}
