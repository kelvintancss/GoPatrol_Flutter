import 'package:intl/intl.dart';
import 'package:patrol/core/utils/patrol_form_photo.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// One locally-saved incident. `syncstatus` is `pending` → `success`, or
/// `fail` (addincident failed), or `partial` (addincident done, photos
/// still waiting for `/patrol/addincidentimage`).
class IncidentRecord {
  final int id;
  final String uuid;
  final String syncStatus;
  final String addDate;

  /// Old (pre digital form) incidents only.
  final String remark;
  final String? message;

  /// `incident_digitalform.id`.
  final String orgFormId;
  final String formName;

  /// JSON-encoded answered form items.
  final String formAnswer;

  /// JSON-encoded [PatrolFormPhoto] list still waiting to upload; cleared
  /// once uploaded.
  final String formPhotos;

  /// Sent as `form_attachment` — the photo count at submit time.
  final int formAttachment;

  /// From the addincident response; drives the photo upload.
  final String digitalFormId;

  IncidentRecord({
    required this.id,
    required this.uuid,
    required this.syncStatus,
    required this.addDate,
    required this.remark,
    this.message,
    this.orgFormId = '',
    this.formName = '',
    this.formAnswer = '',
    this.formPhotos = '',
    this.formAttachment = 0,
    this.digitalFormId = '',
  });

  factory IncidentRecord.fromMap(Map<String, dynamic> map) {
    return IncidentRecord(
      id: map['id'] as int,
      uuid: map['uuid'] as String? ?? '',
      syncStatus: map['syncstatus'] as String? ?? 'pending',
      addDate: map['adddate'] as String,
      remark: map['remark'] as String? ?? '',
      message: map['message'] as String?,
      orgFormId: map['org_form_id'] as String? ?? '',
      formName: map['form_name'] as String? ?? '',
      formAnswer: map['form_answer'] as String? ?? '',
      formPhotos: map['form_photos'] as String? ?? '',
      formAttachment: map['form_attachment'] as int? ?? 0,
      digitalFormId: map['digital_form_id'] as String? ?? '',
    );
  }

  /// Saved before incidents became a digital form (remark + photo rows).
  bool get isLegacy => orgFormId.isEmpty && formAnswer.isEmpty;

  List<PatrolFormPhoto> get photos => decodePatrolFormPhotos(formPhotos);
}

class IncidentPhoto {
  final int id;
  final String incidentUuid;
  final String photoPath;
  final String syncStatus;

  IncidentPhoto({
    required this.id,
    required this.incidentUuid,
    required this.photoPath,
    required this.syncStatus,
  });

  factory IncidentPhoto.fromMap(Map<String, dynamic> map) {
    return IncidentPhoto(
      id: map['id'] as int,
      incidentUuid: map['incident_uuid'] as String? ?? '',
      photoPath: map['photo_path'] as String? ?? '',
      syncStatus: map['syncstatus'] as String? ?? 'pending',
    );
  }
}

class IncidentRecordDatabase {
  IncidentRecordDatabase._();
  static final IncidentRecordDatabase instance = IncidentRecordDatabase._();

  static const _dbName = 'incident_record.db';
  static const tableName = 'incident_record';
  static const tablePhoto = 'incident_photo';

  static const _dateFormat = 'yyyy-MM-dd HH:mm:ss';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final path = await getDatabasesPath();
    _db = await openDatabase(
      '$path/$_dbName',
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT,
            syncstatus TEXT DEFAULT 'pending',
            adddate TEXT,
            remark TEXT,
            message TEXT,
            org_form_id TEXT,
            form_name TEXT,
            form_answer TEXT,
            form_photos TEXT,
            form_attachment INTEGER DEFAULT 0,
            digital_form_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $tablePhoto (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            incident_uuid TEXT,
            photo_path TEXT,
            syncstatus TEXT DEFAULT 'pending'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN uuid TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE $tablePhoto (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              incident_uuid TEXT,
              photo_path TEXT,
              syncstatus TEXT DEFAULT 'pending'
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN message TEXT');
        }
        if (oldVersion < 5) {
          for (final column in [
            'org_form_id TEXT',
            'form_name TEXT',
            'form_answer TEXT',
            'form_photos TEXT',
            'form_attachment INTEGER DEFAULT 0',
            'digital_form_id TEXT',
          ]) {
            await db.execute('ALTER TABLE $tableName ADD COLUMN $column');
          }
        }
      },
    );
  }

  /// Saves a submitted incident digital form; returns its generated uuid.
  Future<String> addIncident({
    required String orgFormId,
    required String formName,
    required String formAnswer,
    required List<PatrolFormPhoto> photos,
  }) async {
    final db = _db;
    final uuid = const Uuid().v4();
    if (db == null) return uuid;
    await db.insert(tableName, {
      'uuid': uuid,
      'adddate': DateFormat(_dateFormat).format(DateTime.now()),
      'remark': '',
      'org_form_id': orgFormId,
      'form_name': formName,
      'form_answer': formAnswer,
      'form_photos': photos.isEmpty ? null : encodePatrolFormPhotos(photos),
      'form_attachment': photos.length,
    });
    return uuid;
  }

  Future<void> setDigitalFormId(String uuid, String digitalFormId) async {
    final db = _db;
    if (db == null) return;
    await db.update(
      tableName,
      {'digital_form_id': digitalFormId},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Photos are on the server (and their files deleted) — forget them.
  Future<void> markPhotosUploaded(String uuid) async {
    final db = _db;
    if (db == null) return;
    await db.update(
      tableName,
      {'form_photos': null},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> addIncidentPhotos({
    required String incidentUuid,
    required List<String> photoPaths,
  }) async {
    final db = _db;
    if (db == null || photoPaths.isEmpty) return;
    await db.transaction((txn) async {
      for (final path in photoPaths) {
        await txn.insert(tablePhoto, {
          'incident_uuid': incidentUuid,
          'photo_path': path,
        });
      }
    });
  }

  /// Attach order (oldest first).
  Future<List<IncidentPhoto>> getPhotosByIncidentUuid(String uuid) async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(
      tablePhoto,
      where: 'incident_uuid = ?',
      whereArgs: [uuid],
      orderBy: 'id ASC',
    );
    return rows.map(IncidentPhoto.fromMap).toList();
  }

  /// Newest first.
  Future<List<IncidentRecord>> getIncidents() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(tableName, orderBy: 'id DESC');
    return rows.map(IncidentRecord.fromMap).toList();
  }

  Future<IncidentRecord?> getIncidentByUuid(String uuid) async {
    final db = _db;
    if (db == null) return null;
    final rows = await db.query(
      tableName,
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return IncidentRecord.fromMap(rows.first);
  }

  /// Records still awaiting a successful sync — new ones, plus ones whose
  /// photos haven't uploaded yet — oldest first.
  Future<List<IncidentRecord>> getPendingIncidents() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(
      tableName,
      where: "syncstatus IN ('pending', 'partial')",
      orderBy: 'id ASC',
    );
    return rows.map(IncidentRecord.fromMap).toList();
  }

  /// Records not yet successfully synced — pending or previously failed —
  /// oldest first. Used for manual retry (unlike [getPendingIncidents],
  /// which backs the passive 5-minute sweep and only picks up brand-new
  /// rows).
  Future<List<IncidentRecord>> getUnsyncedIncidents() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(
      tableName,
      where: "syncstatus IN ('pending', 'fail', 'partial')",
      orderBy: 'id ASC',
    );
    return rows.map(IncidentRecord.fromMap).toList();
  }

  Future<int> getPendingCount() async {
    final db = _db;
    if (db == null) return 0;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM $tableName "
      "WHERE syncstatus IN ('pending', 'partial')",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateSyncStatus(
    String uuid,
    String syncStatus, {
    String? message,
  }) async {
    final db = _db;
    if (db == null) return;
    await db.update(
      tableName,
      {'syncstatus': syncStatus, 'message': message},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (syncStatus == 'success') await _pruneOldSuccessRecords();
  }

  /// Keeps only the [keep] most-recently-added successfully-synced
  /// incidents — older 'success' records (and their photo rows) are
  /// deleted to bound local storage growth. Pending/failed records are
  /// never touched here regardless of how many there are.
  Future<void> _pruneOldSuccessRecords({int keep = 3}) async {
    final db = _db;
    if (db == null) return;
    final successRows = await db.query(
      tableName,
      where: 'syncstatus = ?',
      whereArgs: ['success'],
      orderBy: 'id DESC',
    );
    if (successRows.length <= keep) return;

    final staleUuids = successRows
        .skip(keep)
        .map((row) => row['uuid'] as String)
        .toList();

    await db.transaction((txn) async {
      for (final uuid in staleUuids) {
        await txn.delete(
          tablePhoto,
          where: 'incident_uuid = ?',
          whereArgs: [uuid],
        );
        await txn.delete(tableName, where: 'uuid = ?', whereArgs: [uuid]);
      }
    });
  }

  /// Wipes all incident history — both header and body tables — along with
  /// any form photo files still waiting to upload.
  Future<void> clearAll() async {
    final db = _db;
    if (db == null) return;
    final photoRows = await db.query(
      tableName,
      columns: ['form_photos'],
      where: "form_photos IS NOT NULL AND form_photos != ''",
    );
    await PatrolFormPhotoStore.deleteFiles(
      photoRows
          .expand((row) => decodePatrolFormPhotos(row['form_photos'] as String?))
          .map((p) => p.path),
    );
    await db.transaction((txn) async {
      await txn.delete(tableName);
    });
  }
}
