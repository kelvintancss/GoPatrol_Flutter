import 'dart:convert';

/// One shift row from `/patrol/getPatrolCalendarShift` — the response's
/// `resultSet[0].patrolcalendar` is a JSON-encoded string holding a list of
/// these.
class PatrolCalendarShift {
  final String calendarId;
  final String day;
  final String shiftId;
  final String shiftName;
  final String timeStart;
  final String timeEnd;

  PatrolCalendarShift({
    required this.calendarId,
    required this.day,
    required this.shiftId,
    required this.shiftName,
    required this.timeStart,
    required this.timeEnd,
  });

  factory PatrolCalendarShift.fromJson(Map<String, dynamic> json) {
    return PatrolCalendarShift(
      calendarId: json['calendar_id'] as String? ?? '',
      day: json['day'] as String? ?? '',
      shiftId: json['shift_id'] as String? ?? '',
      shiftName: json['shift_name'] as String? ?? '',
      timeStart: json['timestart'] as String? ?? '',
      timeEnd: json['timeend'] as String? ?? '',
    );
  }
}

/// Parses the JSON-encoded `patrolcalendar` string; returns an empty list
/// for null/blank/malformed input.
List<PatrolCalendarShift> parsePatrolCalendarShifts(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PatrolCalendarShift.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}

/// `/patrol/getPatrolShiftRoute` response — `resultSet[0].shiftroute` is a
/// JSON-encoded string with this shape.
class PatrolShiftRoute {
  final String version;

  /// Sent as `patrol_route_id` on `/patrol/addpatrolrecord`.
  final String patrolRouteId;
  final List<PatrolShiftRouteItem> routes;

  PatrolShiftRoute({
    required this.version,
    this.patrolRouteId = '',
    required this.routes,
  });

  factory PatrolShiftRoute.fromJson(Map<String, dynamic> json) {
    final routes = (json['router_list'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PatrolShiftRouteItem.fromJson)
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return PatrolShiftRoute(
      version: json['version'] as String? ?? '',
      patrolRouteId: json['patrol_route_id']?.toString() ?? '',
      routes: routes,
    );
  }
}

class PatrolShiftRouteItem {
  final String checkpointId;
  final String checkpointRemark;
  final String scanCode;
  final String timeStart;
  final String timeEnd;
  final int sequence;

  /// Null when the checkpoint has no digital form attached.
  final PatrolDigitalForm? digitalForm;

  PatrolShiftRouteItem({
    required this.checkpointId,
    required this.checkpointRemark,
    required this.scanCode,
    required this.timeStart,
    required this.timeEnd,
    required this.sequence,
    this.digitalForm,
  });

  factory PatrolShiftRouteItem.fromJson(Map<String, dynamic> json) {
    final form = json['digitalFormDetail'];
    return PatrolShiftRouteItem(
      checkpointId: json['checkpoint_id'] as String? ?? '',
      checkpointRemark: json['checkpoint_remark'] as String? ?? '',
      scanCode: json['scancode']?.toString() ?? '',
      timeStart: json['timestart'] as String? ?? '',
      timeEnd: json['timeend'] as String? ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      digitalForm:
          form is Map<String, dynamic> ? PatrolDigitalForm.fromJson(form) : null,
    );
  }
}

class PatrolDigitalForm {
  final String id;
  final String formId;
  final String formName;
  final int isRequireApproval;
  final List<PatrolFormItem> formItems;

  PatrolDigitalForm({
    required this.id,
    required this.formId,
    required this.formName,
    this.isRequireApproval = 0,
    this.formItems = const [],
  });

  factory PatrolDigitalForm.fromJson(Map<String, dynamic> json) {
    return PatrolDigitalForm(
      id: json['id'] as String? ?? '',
      formId: json['formid'] as String? ?? '',
      formName: json['form_name'] as String? ?? '',
      isRequireApproval: (json['is_require_approval'] as num?)?.toInt() ?? 0,
      formItems: (json['form_item'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PatrolFormItem.new)
          .toList(),
    );
  }
}

/// One `form_item` of a digital form. Keeps the raw JSON map so a submitted
/// answer can echo every field back with only `formValue` /
/// `formItemGroupList` filled in (same shape as CSS Home's `FormItem`).
class PatrolFormItem {
  final Map<String, dynamic> raw;

  PatrolFormItem(this.raw);

  /// Null for display-only rows (e.g. HEADER) — those aren't answers.
  dynamic get itemNo => raw['itemno'];
  String get typeId => (raw['typeID'] as String? ?? '').toUpperCase();
  String get pageHeaderText => raw['pageHeaderText']?.toString() ?? '';
  String get labelText => raw['formLabelText']?.toString() ?? '';
  String get placeholderText => raw['formPlaceholderText']?.toString() ?? '';
  String get groupName => raw['formItemGroupName']?.toString() ?? '';
  String? get fileUrl => raw['fileurl']?.toString();
  String? get formValue => raw['formValue']?.toString();
  bool get isMandatory => raw['formMandatory'] == true;
  bool get hasGroupList => raw['formItemGroupList'] != null;

  /// `formItemGroupList` arrives as a JSON-encoded string; returns fresh,
  /// mutable copies of `{formItemGroupItem, formItemGroupItemValue}` maps.
  List<Map<String, dynamic>> decodeGroupList() {
    var value = raw['formItemGroupList'];
    try {
      if (value is String) value = jsonDecode(value);
    } catch (_) {
      return [];
    }
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

/// Parses a JSON-encoded digital form (e.g. `digitalFormCheckpointSkip`);
/// null for null/blank/malformed input.
PatrolDigitalForm? parsePatrolDigitalForm(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return PatrolDigitalForm.fromJson(decoded);
  } catch (_) {
    return null;
  }
}

/// Parses the JSON-encoded `shiftroute` string; returns null for
/// null/blank/malformed input.
PatrolShiftRoute? parsePatrolShiftRoute(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return PatrolShiftRoute.fromJson(decoded);
  } catch (_) {
    return null;
  }
}

/// Whether an NFC scan id matches a route checkpoint's scancode.
bool isSameScanCode(String a, String b) =>
    a.trim().toUpperCase() == b.trim().toUpperCase();

/// Index into [routes] (sorted by sequence) of the next checkpoint to scan,
/// given the recorded checkpoint ids oldest-first; equals `routes.length`
/// once every checkpoint is done. Only in-order matches advance the pointer.
int nextRouteIndex(
  List<PatrolShiftRouteItem> routes,
  Iterable<String> checkpointIdsOldestFirst,
) {
  var index = 0;
  for (final id in checkpointIdsOldestFirst) {
    if (index >= routes.length) break;
    if (id == routes[index].checkpointId) index++;
  }
  return index;
}
