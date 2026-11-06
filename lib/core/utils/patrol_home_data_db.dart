import 'package:intl/intl.dart';
import 'package:patrol/core/utils/patrol_calendar_model.dart';
import 'package:sqflite/sqflite.dart';

class PatrolHomeData {
  final String facility;
  final String patrol;
  final String incident;

  /// Raw `incident_digitalform` — the form filled when adding an incident.
  final String incidentDigitalForm;
  final String checkin;
  final String checkout;
  final bool vmsActive;
  final String projectName;
  final String updatedAt;

  PatrolHomeData({
    required this.facility,
    required this.patrol,
    required this.incident,
    required this.incidentDigitalForm,
    required this.checkin,
    required this.checkout,
    required this.vmsActive,
    required this.projectName,
    required this.updatedAt,
  });

  factory PatrolHomeData.fromMap(Map<String, dynamic> map) {
    return PatrolHomeData(
      facility: map['facility'] as String? ?? '',
      patrol: map['patrol'] as String? ?? '',
      incident: map['incident'] as String? ?? '',
      incidentDigitalForm: map['incident_digitalform'] as String? ?? '',
      checkin: map['checkin'] as String? ?? '',
      checkout: map['checkout'] as String? ?? '',
      vmsActive: (map['vmsactive'] as int? ?? 0) == 1,
      projectName: map['projectname'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  PatrolDigitalForm? get incidentForm =>
      parsePatrolDigitalForm(incidentDigitalForm);
}

class PatrolHomeDataDatabase {
  PatrolHomeDataDatabase._();
  static final PatrolHomeDataDatabase instance = PatrolHomeDataDatabase._();

  static const _dbName = 'patrol_home_data.db';
  static const tableName = 'patrol_home_data';

  static const _dateFormat = 'yyyy-MM-dd HH:mm:ss';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final path = await getDatabasesPath();
    _db = await openDatabase(
      '$path/$_dbName',
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY,
            facility TEXT,
            patrol TEXT,
            incident TEXT,
            checkin TEXT,
            checkout TEXT,
            vmsactive INTEGER,
            projectname TEXT,
            incident_digitalform TEXT,
            updated_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN incident TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN checkin TEXT');
          await db.execute('ALTER TABLE $tableName ADD COLUMN checkout TEXT');
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN vmsactive INTEGER',
          );
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN projectname TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN incident_digitalform TEXT',
          );
        }
      },
    );
  }

  /// Single-row snapshot of the latest `/patrol/getpatrolhomedata` response —
  /// each successful fetch overwrites it rather than accumulating history.
  Future<void> save({
    required String facility,
    required String patrol,
    required String incident,
    required String incidentDigitalForm,
    required String checkin,
    required String checkout,
    required bool vmsActive,
    required String projectName,
  }) async {
    final db = _db;
    if (db == null) return;
    await db.insert(
      tableName,
      {
        'id': 1,
        'facility': facility,
        'patrol': patrol,
        'incident': incident,
        'incident_digitalform': incidentDigitalForm,
        'checkin': checkin,
        'checkout': checkout,
        'vmsactive': vmsActive ? 1 : 0,
        'projectname': projectName,
        'updated_at': DateFormat(_dateFormat).format(DateTime.now()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Replaces only the stored `incident_digitalform` — for the fresher copy
  /// that `/patrol/getincidentreport` returns between 5-minute refreshes.
  Future<void> saveIncidentDigitalForm(String incidentDigitalForm) async {
    final db = _db;
    if (db == null) return;
    final updated = await db.update(
      tableName,
      {'incident_digitalform': incidentDigitalForm},
      where: 'id = ?',
      whereArgs: [1],
    );
    if (updated == 0) {
      await db.insert(tableName, {
        'id': 1,
        'incident_digitalform': incidentDigitalForm,
        'updated_at': DateFormat(_dateFormat).format(DateTime.now()),
      });
    }
  }

  Future<PatrolHomeData?> get() async {
    final db = _db;
    if (db == null) return null;
    final rows = await db.query(tableName, where: 'id = ?', whereArgs: [1], limit: 1);
    if (rows.isEmpty) return null;
    return PatrolHomeData.fromMap(rows.first);
  }
}
