import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:patrol/core/repository/patrol_repository.dart';
import 'package:patrol/core/utils/patrol_form_photo.dart';
import 'package:patrol/core/utils/patrol_record_db.dart';
import 'package:patrol/service_locator.dart';

/// Silently syncs locally-saved patrol records to the server.
///
/// Every write stays local-first (sqlite). This only ever attempts to push
/// pending rows when a connection is available, and it never surfaces
/// loading/success/error UI — sync outcome is recorded purely via
/// `patrol_record_header.syncstatus`.
class PatrolSyncManager with WidgetsBindingObserver {
  static const _pollInterval = Duration(minutes: 5);

  Timer? _timer;

  /// Guards against overlapping photo sweeps (e.g. a trySyncNow racing the
  /// periodic timer) uploading the same photos twice.
  bool _isUploadingPhotos = false;

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

  /// Attempts to push a single just-saved session right away. Fire-and-forget
  /// from the caller's perspective — no loading UI, no error surfaced.
  Future<void> trySyncNow(String uuid) async {
    if (!await _hasInternet()) return;
    final header = await PatrolRecordDatabase.instance.getHeaderByUuid(uuid);
    if (header == null) return;
    await _syncHeader(header);
    await _syncPendingPhotos();
  }

  /// Periodic sweep: if there are pending rows and a connection is
  /// available, push them all.
  Future<void> syncPending() async {
    final pendingCount = await PatrolRecordDatabase.instance.getPendingCount();
    final pendingPhotos =
        await PatrolRecordDatabase.instance.getPendingPhotoBodies();
    if (pendingCount == 0 && pendingPhotos.isEmpty) return;
    if (!await _hasInternet()) return;

    final headers = await PatrolRecordDatabase.instance.getPendingHeaders();
    for (final header in headers) {
      await _syncHeader(header);
    }
    await _syncPendingPhotos();
  }

  /// User-triggered retry (e.g. the "Sync Record" button on the record
  /// list). Unlike [syncPending], this also retries rows already marked
  /// 'fail', since a manual tap is an explicit request to try again.
  ///
  /// Returns false only when there's no connection, so the caller can tell
  /// the user to check their network; true otherwise (regardless of how
  /// individual rows landed — that's reflected per-row via syncstatus).
  Future<bool> syncNow() async {
    if (!await _hasInternet()) return false;

    final headers = await PatrolRecordDatabase.instance.getUnsyncedHeaders();
    for (final header in headers) {
      await _syncHeader(header);
    }
    await _syncPendingPhotos();
    return true;
  }

  Future<void> _syncHeader(PatrolRecordHeader header) async {
    final body = await PatrolRecordDatabase.instance.getBodyByUuid(
      header.uuid,
    );
    try {
      final result = await sl<PatrolRepository>().addPatrolRecord(
        header: header,
        records: body,
      );
      var status = result.success ? 'success' : 'fail';
      var message = result.message;
      if (result.success) {
        final problems = await PatrolRecordDatabase.instance
            .applyRouteHistory(header.uuid, result.routeHistory);
        // Photos still to upload — only 'success' once those go up too
        // (see _syncPendingPhotos).
        if (await PatrolRecordDatabase.instance.hasPendingPhotos(
          header.uuid,
        )) {
          status = 'partial';
          if (problems.isNotEmpty) {
            message = 'Photos not uploadable: ${problems.join('; ')}';
          }
        }
      }
      await PatrolRecordDatabase.instance.updateSyncStatus(
        header.uuid,
        status,
        message: message,
        routeHistory: result.routeHistory,
      );
    } catch (e) {
      await PatrolRecordDatabase.instance.updateSyncStatus(
        header.uuid,
        'fail',
        message: e.toString(),
      );
    }
  }

  /// Uploads digital-form photos for 'partial' records, one checkpoint at a
  /// time. Uploaded photos are deleted locally; failures stay queued for the
  /// next sweep without blocking the remaining checkpoints. A record turns
  /// 'success' once none of its photos are left.
  Future<void> _syncPendingPhotos() async {
    if (_isUploadingPhotos) return;
    _isUploadingPhotos = true;
    try {
      final bodies =
          await PatrolRecordDatabase.instance.getPendingPhotoBodies();
      // Last failure message per session, kept on the 'partial' header.
      final failures = <String, String>{};
      for (final body in bodies) {
        final bodyId = body.id;
        if (bodyId == null) continue;
        try {
          final photos = body.photos;
          final result = await sl<PatrolRepository>().addPatrolRecordImage(
            digitalFormId: body.digitalFormId,
            checkpointId: body.checkpointId,
            photos: photos,
          );
          if (!result.success) {
            failures[body.uuid] = result.message ?? 'Photo upload failed';
            continue;
          }
          await PatrolFormPhotoStore.deleteFiles(photos.map((p) => p.path));
          await PatrolRecordDatabase.instance.markPhotosUploaded(bodyId);
        } catch (e) {
          // Left queued — retried on the next sweep.
          failures[body.uuid] = e.toString();
        }
      }

      for (final uuid in bodies.map((b) => b.uuid).toSet()) {
        if (await PatrolRecordDatabase.instance.hasPendingPhotos(uuid)) {
          await PatrolRecordDatabase.instance.updateSyncStatus(
            uuid,
            'partial',
            message: 'Photo upload failed: ${failures[uuid] ?? '-'}',
          );
        } else {
          await PatrolRecordDatabase.instance.updateSyncStatus(
            uuid,
            'success',
            message: 'Success',
          );
        }
      }
    } finally {
      _isUploadingPhotos = false;
    }
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
