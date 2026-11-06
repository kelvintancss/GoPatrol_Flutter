import 'dart:convert';

/// Shared shape for both the SQLite `patrol` snapshot (today's data, stored
/// verbatim from `/patrol/getpatrolhomedata`) and the
/// `/patrol/getPatrolReport` response's `report` field — both are
/// JSON-encoded strings with this same structure, keyed `patrollog`.
class PatrolLogReport {
  final int totalPage;
  final int currentPage;
  final List<PatrolLogMonth> log;

  PatrolLogReport({
    required this.totalPage,
    required this.currentPage,
    required this.log,
  });

  factory PatrolLogReport.fromJson(Map<String, dynamic> json) {
    return PatrolLogReport(
      totalPage: (json['total_page'] as num?)?.toInt() ?? 1,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      log: (json['patrollog'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PatrolLogMonth.fromJson)
          .toList(),
    );
  }
}

class PatrolLogMonth {
  final String month;
  final List<PatrolLogDateGroup> dateGroups;

  PatrolLogMonth({required this.month, required this.dateGroups});

  factory PatrolLogMonth.fromJson(Map<String, dynamic> json) {
    return PatrolLogMonth(
      month: json['month'] as String? ?? '',
      dateGroups: (json['dategroup'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PatrolLogDateGroup.fromJson)
          .toList(),
    );
  }
}

class PatrolLogDateGroup {
  final String dateInputDay;
  final List<PatrolLogEntry> data;

  PatrolLogDateGroup({required this.dateInputDay, required this.data});

  factory PatrolLogDateGroup.fromJson(Map<String, dynamic> json) {
    return PatrolLogDateGroup(
      dateInputDay: json['dateinput_day'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PatrolLogEntry.fromJson)
          .toList(),
    );
  }
}

class PatrolLogEntry {
  final String patrolId;
  final String uuid;
  final String cssLoginCode;
  final String startDate;
  final String endDate;
  final String calendarDay;
  final String shiftName;

  /// Checkpoints scanned / checkpoints in the shift route.
  final int routeCount;
  final int totalRouteCount;
  final List<PatrolLogRoute> routeList;

  PatrolLogEntry({
    this.patrolId = '',
    required this.uuid,
    required this.cssLoginCode,
    required this.startDate,
    required this.endDate,
    this.calendarDay = '',
    this.shiftName = '',
    this.routeCount = 0,
    this.totalRouteCount = 0,
    this.routeList = const [],
  });

  factory PatrolLogEntry.fromJson(Map<String, dynamic> json) {
    return PatrolLogEntry(
      patrolId: json['patrol_id']?.toString() ?? '',
      uuid: json['uuid'] as String? ?? '',
      cssLoginCode: json['css_login_code'] as String? ?? '',
      startDate: json['startdate'] as String? ?? '',
      endDate: json['enddate'] as String? ?? '',
      calendarDay: json['calendar_day'] as String? ?? '',
      shiftName: json['shift_name'] as String? ?? '',
      routeCount: (json['route_count'] as num?)?.toInt() ?? 0,
      totalRouteCount: (json['total_route_count'] as num?)?.toInt() ?? 0,
      routeList: _decodeList(json['route_list'])
          .map(PatrolLogRoute.fromJson)
          .toList(),
    );
  }
}

/// One checkpoint of the shift route, with whether it was scanned.
class PatrolLogRoute {
  final String checkpointId;
  final String scanCode;
  final String remark;
  final String timeStart;
  final String timeEnd;
  final bool scanned;
  final String checkDate;
  final String formId;

  PatrolLogRoute({
    required this.checkpointId,
    required this.scanCode,
    required this.remark,
    required this.timeStart,
    required this.timeEnd,
    required this.scanned,
    required this.checkDate,
    required this.formId,
  });

  factory PatrolLogRoute.fromJson(Map<String, dynamic> json) {
    return PatrolLogRoute(
      checkpointId: json['checkpoint_id']?.toString() ?? '',
      scanCode: json['scancode']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      timeStart: json['timestart']?.toString() ?? '',
      timeEnd: json['timeend']?.toString() ?? '',
      // API spells it `scanded`.
      scanned: json['scanded']?.toString() == '1',
      checkDate: json['checkdate']?.toString() ?? '',
      formId: json['form_id']?.toString() ?? '',
    );
  }
}

/// `route_list` arrives as a JSON-encoded string; accept a decoded list too.
List<Map<String, dynamic>> _decodeList(dynamic value) {
  try {
    final decoded = value is String ? jsonDecode(value) : value;
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } catch (_) {
    return [];
  }
}

/// API dates are ISO (`2026-10-14T10:39:41`); show them as
/// `2026-10-14 10:39:41`.
String formatPatrolLogDate(String raw) => raw.replaceFirst('T', ' ');

/// Null on missing/blank/malformed input rather than throwing — both call
/// sites (local SQLite snapshot, API response) treat "no data" as an empty
/// list rather than an error.
PatrolLogReport? parsePatrolLogReport(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return PatrolLogReport.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
