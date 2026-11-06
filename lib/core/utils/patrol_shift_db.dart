import 'package:intl/intl.dart';
import 'package:patrol/core/utils/patrol_calendar_model.dart';
import 'package:sqflite/sqflite.dart';

/// The shift picked for the current patrol, plus its route snapshot from
/// `/patrol/getPatrolShiftRoute` ([routeJson] is the raw `shiftroute`
/// string, stored verbatim).
class PatrolActiveShift {
  final String calendarId;
  final String shiftId;
  final String patrolRouteId;
  final String shiftName;
  final String timeStart;
  final String timeEnd;
  final String routeJson;

  /// Raw `digitalFormCheckpointSkip`; empty when the shift has none.
  final String skipFormJson;
  final String savedAt;

  PatrolActiveShift({
    required this.calendarId,
    required this.shiftId,
    required this.patrolRouteId,
    required this.shiftName,
    required this.timeStart,
    required this.timeEnd,
    required this.routeJson,
    this.skipFormJson = '',
    required this.savedAt,
  });

  PatrolShiftRoute? get route => parsePatrolShiftRoute(routeJson);

  PatrolDigitalForm? get skipForm => parsePatrolDigitalForm(skipFormJson);

  factory PatrolActiveShift.fromMap(Map<String, dynamic> map) {
    final routeJson = map['shiftroute'] as String? ?? '';
    final patrolRouteId = map['patrol_route_id'] as String? ?? '';
    return PatrolActiveShift(
      calendarId: map['calendar_id'] as String? ?? '',
      shiftId: map['shift_id'] as String? ?? '',
      // Rows saved before the column existed: fall back to the route JSON.
      patrolRouteId: patrolRouteId.isNotEmpty
          ? patrolRouteId
          : parsePatrolShiftRoute(routeJson)?.patrolRouteId ?? '',
      shiftName: map['shift_name'] as String? ?? '',
      timeStart: map['timestart'] as String? ?? '',
      timeEnd: map['timeend'] as String? ?? '',
      routeJson: routeJson,
      skipFormJson: map['skip_form'] as String? ?? '',
      savedAt: map['saved_at'] as String? ?? '',
    );
  }
}

class PatrolShiftDatabase {
  PatrolShiftDatabase._();
  static final PatrolShiftDatabase instance = PatrolShiftDatabase._();

  static const _dbName = 'patrol_shift.db';
  static const tableName = 'patrol_shift';

  static const _dateFormat = 'yyyy-MM-dd HH:mm:ss';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final path = await getDatabasesPath();
    _db = await openDatabase(
      '$path/$_dbName',
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY,
            calendar_id TEXT,
            shift_id TEXT,
            patrol_route_id TEXT,
            shift_name TEXT,
            timestart TEXT,
            timeend TEXT,
            shiftroute TEXT,
            skip_form TEXT,
            saved_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN patrol_route_id TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $tableName ADD COLUMN skip_form TEXT');
        }
      },
    );
  }

  /// Single-row snapshot — confirming a new shift overwrites the previous
  /// one; [clear] wipes it when the patrol is stopped.
  Future<void> save({
    required PatrolCalendarShift shift,
    required String patrolRouteId,
    required String routeJson,
    String skipFormJson = '',
  }) async {
    final db = _db;
    if (db == null) return;
    await db.insert(
      tableName,
      {
        'id': 1,
        'calendar_id': shift.calendarId,
        'shift_id': shift.shiftId,
        'patrol_route_id': patrolRouteId,
        'shift_name': shift.shiftName,
        'timestart': shift.timeStart,
        'timeend': shift.timeEnd,
        'shiftroute': routeJson,
        'skip_form': skipFormJson,
        'saved_at': DateFormat(_dateFormat).format(DateTime.now()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PatrolActiveShift?> get() async {
    final db = _db;
    if (db == null) return null;
    final rows =
        await db.query(tableName, where: 'id = ?', whereArgs: [1], limit: 1);
    if (rows.isEmpty) return null;
    return PatrolActiveShift.fromMap(rows.first);
  }

  Future<void> clear() async {
    await _db?.delete(tableName);
  }
}
