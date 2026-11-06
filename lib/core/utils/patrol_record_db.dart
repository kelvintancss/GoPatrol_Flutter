import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:patrol/core/utils/patrol_checkpoint_entry.dart';
import 'package:patrol/core/utils/patrol_form_photo.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class PatrolRecordHeader {
  final String uuid;
  final String startDate;
  final String endDate;

  /// `pending` → not uploaded yet; `fail` → addpatrolrecord rejected;
  /// `partial` → record uploaded but its form photos aren't (yet);
  /// `success` → record and all photos uploaded.
  final String syncStatus;
  final String? message;
  final String calendarId;
  final String shiftId;
  final String patrolRouteId;

  /// Raw `resultSet[0].patrol_route_history` from a successful upload
  /// (`[{uuid, digital_form_id, checkpoint_id, form_attachment}]`).
  final String? routeHistory;

  PatrolRecordHeader({
    required this.uuid,
    required this.startDate,
    required this.endDate,
    required this.syncStatus,
    this.message,
    this.calendarId = '',
    this.shiftId = '',
    this.patrolRouteId = '',
    this.routeHistory,
  });

  factory PatrolRecordHeader.fromMap(Map<String, dynamic> map) {
    return PatrolRecordHeader(
      uuid: map['uuid'] as String,
      startDate: map['startdate'] as String,
      endDate: map['enddate'] as String,
      syncStatus: map['syncstatus'] as String? ?? 'pending',
      message: map['message'] as String?,
      calendarId: map['calendar_id'] as String? ?? '',
      shiftId: map['shift_id'] as String? ?? '',
      patrolRouteId: map['patrol_route_id'] as String? ?? '',
      routeHistory: map['route_history'] as String?,
    );
  }
}

class PatrolRecordBody {
  final int? id;
  final String uuid;
  final String scanDate;

  /// Route `checkpoint_id` — what gets uploaded.
  final String checkpointId;

  /// The scanned NFC scancode, for display.
  final String scanCode;

  /// `digitalFormDetail.id`; empty when the checkpoint has no form.
  final String orgFormId;

  /// JSON-encoded answered form items; null when the checkpoint has no form.
  final String? formAnswer;

  /// Number of photos attached to the form — sent as `form_attachment`.
  final int formAttachment;

  /// JSON-encoded [PatrolFormPhoto] list still waiting to be uploaded;
  /// cleared (and the files deleted) once uploaded.
  final String? formPhotos;

  /// From `patrol_route_history.digital_form_id` after the record upload;
  /// needed for the photo upload.
  final String digitalFormId;

  /// Sent as `isskip` — the checkpoint was skipped rather than scanned.
  final bool isSkip;

  PatrolRecordBody({
    this.id,
    this.uuid = '',
    required this.scanDate,
    required this.checkpointId,
    this.scanCode = '',
    this.orgFormId = '',
    this.formAnswer,
    this.formAttachment = 0,
    this.formPhotos,
    this.digitalFormId = '',
    this.isSkip = false,
  });

  List<PatrolFormPhoto> get photos => decodePatrolFormPhotos(formPhotos);

  factory PatrolRecordBody.fromMap(Map<String, dynamic> map) {
    return PatrolRecordBody(
      id: map['id'] as int?,
      uuid: map['uuid'] as String? ?? '',
      scanDate: map['scandate'] as String,
      checkpointId: map['checkpoint_id'] as String? ?? '',
      scanCode: map['scancode'] as String? ?? '',
      orgFormId: map['org_form_id'] as String? ?? '',
      formAnswer: map['form_answer'] as String?,
      formAttachment: map['form_attachment'] as int? ?? 0,
      formPhotos: map['form_photos'] as String?,
      digitalFormId: map['digital_form_id'] as String? ?? '',
      isSkip: (map['is_skip'] as int? ?? 0) == 1,
    );
  }
}

class PatrolRecordDatabase {
  PatrolRecordDatabase._();
  static final PatrolRecordDatabase instance = PatrolRecordDatabase._();

  static const _dbName = 'patrol_record.db';
  static const tableHeader = 'patrol_record_header';
  static const tableBody = 'patrol_record_body';

  static const _dateFormat = 'yyyy-MM-dd HH:mm:ss';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final path = await getDatabasesPath();
    _db = await openDatabase(
      '$path/$_dbName',
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableHeader (
            uuid TEXT PRIMARY KEY,
            startdate TEXT,
            enddate TEXT,
            syncstatus TEXT DEFAULT 'pending',
            message TEXT,
            calendar_id TEXT,
            shift_id TEXT,
            patrol_route_id TEXT,
            route_history TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableBody (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT,
            scandate TEXT,
            scancode TEXT,
            checkpoint_id TEXT,
            org_form_id TEXT,
            form_answer TEXT,
            form_attachment INTEGER DEFAULT 0,
            form_photos TEXT,
            digital_form_id TEXT,
            is_skip INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE $tableHeader
            ADD COLUMN syncstatus TEXT DEFAULT 'pending'
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $tableHeader ADD COLUMN message TEXT');
        }
        if (oldVersion < 4) {
          for (final column in [
            'calendar_id TEXT',
            'shift_id TEXT',
            'route_history TEXT',
          ]) {
            await db.execute('ALTER TABLE $tableHeader ADD COLUMN $column');
          }
          for (final column in [
            'org_form_id TEXT',
            'form_answer TEXT',
            'form_attachment INTEGER DEFAULT 0',
          ]) {
            await db.execute('ALTER TABLE $tableBody ADD COLUMN $column');
          }
        }
        if (oldVersion < 5) {
          // `code` used to hold the checkpoint id; split it into explicit
          // `checkpoint_id` + `scancode` columns. The old `code` column is
          // left in place (unused) since SQLite can't drop it portably.
          await db.execute(
            'ALTER TABLE $tableBody ADD COLUMN scancode TEXT',
          );
          await db.execute(
            'ALTER TABLE $tableBody ADD COLUMN checkpoint_id TEXT',
          );
          await db.execute('UPDATE $tableBody SET checkpoint_id = code');
        }
        if (oldVersion < 6) {
          for (final column in ['form_photos TEXT', 'digital_form_id TEXT']) {
            await db.execute('ALTER TABLE $tableBody ADD COLUMN $column');
          }
        }
        if (oldVersion < 7) {
          await db.execute(
            'ALTER TABLE $tableHeader ADD COLUMN patrol_route_id TEXT',
          );
        }
        if (oldVersion < 8) {
          await db.execute(
            'ALTER TABLE $tableBody ADD COLUMN is_skip INTEGER DEFAULT 0',
          );
        }
      },
    );
  }

  /// Persists a completed patrol session: one header row plus one body row
  /// per checkpoint scan, sharing a single generated uuid.
  ///
  /// Returns the generated uuid so callers can attempt an immediate sync.
  Future<String> savePatrolRecord({
    required DateTime startDate,
    required DateTime endDate,
    required String calendarId,
    required String shiftId,
    required String patrolRouteId,
    required List<PatrolCheckpointEntry> entries,
  }) async {
    final uuid = const Uuid().v4();
    final db = _db;
    if (db == null) return uuid;

    final formatter = DateFormat(_dateFormat);

    await db.transaction((txn) async {
      await txn.insert(tableHeader, {
        'uuid': uuid,
        'startdate': formatter.format(startDate),
        'enddate': formatter.format(endDate),
        'calendar_id': calendarId,
        'shift_id': shiftId,
        'patrol_route_id': patrolRouteId,
      });

      // Oldest first, so body row order (id ASC) matches scan order.
      // Stable sort: skipped checkpoints share one timestamp and must keep
      // their route order. Storage hands entries newest-first.
      final ordered = entries.reversed.toList();
      mergeSort(ordered, compare: (a, b) => a.timestamp.compareTo(b.timestamp));
      for (final entry in ordered) {
        final photos = entry.photos;
        await txn.insert(tableBody, {
          'uuid': uuid,
          'scandate': formatter.format(entry.timestamp),
          'scancode': entry.scanCode,
          'checkpoint_id': entry.checkpointId,
          'org_form_id': entry.orgFormId,
          'form_answer': entry.hasForm ? entry.formAnswer : null,
          'form_attachment': photos.length,
          'form_photos': photos.isEmpty ? null : encodePatrolFormPhotos(photos),
          'is_skip': entry.isSkip ? 1 : 0,
        });
      }
    });

    return uuid;
  }

  /// Newest first.
  Future<List<PatrolRecordHeader>> getHeaders() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(tableHeader, orderBy: 'startdate DESC');
    return rows.map(PatrolRecordHeader.fromMap).toList();
  }

  Future<PatrolRecordHeader?> getHeaderByUuid(String uuid) async {
    final db = _db;
    if (db == null) return null;
    final rows = await db.query(
      tableHeader,
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PatrolRecordHeader.fromMap(rows.first);
  }

  /// Headers still awaiting a successful sync, oldest first.
  Future<List<PatrolRecordHeader>> getPendingHeaders() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(
      tableHeader,
      where: 'syncstatus = ?',
      whereArgs: ['pending'],
      orderBy: 'startdate ASC',
    );
    return rows.map(PatrolRecordHeader.fromMap).toList();
  }

  /// Headers not yet successfully synced — pending or previously failed —
  /// oldest first. Used for manual retry (unlike [getPendingHeaders], which
  /// backs the passive 5-minute sweep and only picks up brand-new rows).
  Future<List<PatrolRecordHeader>> getUnsyncedHeaders() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(
      tableHeader,
      where: "syncstatus IN ('pending', 'fail')",
      orderBy: 'startdate ASC',
    );
    return rows.map(PatrolRecordHeader.fromMap).toList();
  }

  Future<int> getPendingCount() async {
    final db = _db;
    if (db == null) return 0;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $tableHeader WHERE syncstatus = ?',
      ['pending'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateSyncStatus(
    String uuid,
    String syncStatus, {
    String? message,
    String? routeHistory,
  }) async {
    final db = _db;
    if (db == null) return;
    await db.update(
      tableHeader,
      {
        'syncstatus': syncStatus,
        'message': message,
        if (routeHistory != null) 'route_history': routeHistory,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (syncStatus == 'success') await _pruneOldSuccessRecords();
  }

  /// Keeps only the [keep] most-recently-started successfully-synced
  /// sessions — older 'success' headers (and their body rows) are deleted
  /// to bound local storage growth. Pending/failed headers are never
  /// touched here regardless of how many there are.
  Future<void> _pruneOldSuccessRecords({int keep = 3}) async {
    final db = _db;
    if (db == null) return;
    // 'partial' headers (photos still waiting to upload) never match here.
    final successRows = await db.query(
      tableHeader,
      where: 'syncstatus = ?',
      whereArgs: ['success'],
      orderBy: 'startdate DESC',
    );
    if (successRows.length <= keep) return;

    final staleUuids = successRows
        .skip(keep)
        .map((row) => row['uuid'] as String)
        .toList();

    await db.transaction((txn) async {
      for (final uuid in staleUuids) {
        await txn.delete(tableBody, where: 'uuid = ?', whereArgs: [uuid]);
        await txn.delete(tableHeader, where: 'uuid = ?', whereArgs: [uuid]);
      }
    });
  }

  /// Scan order (oldest first) for the given patrol session.
  Future<List<PatrolRecordBody>> getBodyByUuid(String uuid) async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(
      tableBody,
      where: 'uuid = ?',
      whereArgs: [uuid],
      orderBy: 'id ASC',
    );
    return rows.map(PatrolRecordBody.fromMap).toList();
  }

  static const _hasPhotos = "form_photos IS NOT NULL AND form_photos != ''";

  /// Applies `patrol_route_history` from a successful record upload: rows
  /// whose history entry has `form_attachment > 0` get their
  /// `digital_form_id` (making them eligible for the photo upload).
  ///
  /// History entries are matched to rows by `checkpoint_id`, in scan order
  /// (the same checkpoint can appear more than once in a route).
  ///
  /// Photos are never deleted here: a row with photos but no usable history
  /// entry keeps them (its session stays 'partial'). Returns a description
  /// of each such row, empty when every photo row got a `digital_form_id`.
  Future<List<String>> applyRouteHistory(
    String uuid,
    String? routeHistory,
  ) async {
    final db = _db;
    if (db == null) return [];
    final bodies = await getBodyByUuid(uuid);
    final photoBodies = bodies.where((b) => b.photos.isNotEmpty).toList();
    debugPrint(
      '[PatrolSync] $uuid route_history=$routeHistory, '
      'rows with photos: ${photoBodies.map((b) => '${b.checkpointId}'
          '(${b.photos.length})').join(', ')}',
    );

    List<Map<String, dynamic>> history = [];
    try {
      final decoded = jsonDecode(routeHistory ?? '');
      if (decoded is List) {
        history = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      // Missing/malformed — every photo row is reported as unmatched below.
    }

    final problems = <String>[];
    final used = <int>{};
    for (final body in bodies) {
      final bodyId = body.id;
      if (bodyId == null) continue;
      var index = -1;
      for (final (i, item) in history.indexed) {
        if (used.contains(i)) continue;
        if (item['checkpoint_id']?.toString() == body.checkpointId) {
          index = i;
          break;
        }
      }
      if (index >= 0) used.add(index);
      final item = index >= 0 ? history[index] : null;
      final attachments =
          int.tryParse(item?['form_attachment']?.toString() ?? '') ?? 0;
      final digitalFormId = item?['digital_form_id']?.toString() ?? '';

      if (attachments > 0 && digitalFormId.isNotEmpty) {
        await db.update(
          tableBody,
          {'digital_form_id': digitalFormId},
          where: 'id = ?',
          whereArgs: [bodyId],
        );
      } else if (body.photos.isNotEmpty) {
        problems.add(
          item == null
              ? 'checkpoint_id ${body.checkpointId} not in patrol_route_history'
              : 'checkpoint_id ${body.checkpointId}: form_attachment='
                  '${item['form_attachment']}, '
                  'digital_form_id="$digitalFormId"',
        );
      }
    }
    if (problems.isNotEmpty) {
      debugPrint('[PatrolSync] $uuid photos not uploadable: $problems');
    }
    return problems;
  }

  /// Whether any row of session [uuid] still has photos to upload.
  Future<bool> hasPendingPhotos(String uuid) async {
    final db = _db;
    if (db == null) return false;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $tableBody WHERE uuid = ? AND $_hasPhotos',
      [uuid],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  /// Rows of 'partial' sessions (record uploaded) whose photos still need to
  /// go up, oldest first.
  Future<List<PatrolRecordBody>> getPendingPhotoBodies() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.rawQuery('''
      SELECT b.* FROM $tableBody b
      JOIN $tableHeader h ON h.uuid = b.uuid
      WHERE h.syncstatus = 'partial'
        AND b.$_hasPhotos
        AND b.digital_form_id IS NOT NULL AND b.digital_form_id != ''
      ORDER BY b.id ASC
    ''');
    return rows.map(PatrolRecordBody.fromMap).toList();
  }

  /// Clears a row's pending photo list (the caller deletes the files);
  /// `form_attachment` keeps the count.
  Future<void> markPhotosUploaded(int bodyId) async {
    final db = _db;
    if (db == null) return;
    await db.update(
      tableBody,
      {'form_photos': null},
      where: 'id = ?',
      whereArgs: [bodyId],
    );
  }

  /// Wipes all patrol history — both header and body tables — along with
  /// any photo files still waiting to upload.
  Future<void> clearAll() async {
    final db = _db;
    if (db == null) return;
    final photoRows = await db.query(
      tableBody,
      columns: ['form_photos'],
      where: _hasPhotos,
    );
    await PatrolFormPhotoStore.deleteFiles(
      photoRows
          .expand((row) => decodePatrolFormPhotos(row['form_photos'] as String?))
          .map((p) => p.path),
    );
    await db.transaction((txn) async {
      await txn.delete(tableBody);
      await txn.delete(tableHeader);
    });
  }
}
