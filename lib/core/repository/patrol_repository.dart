import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:patrol/core/repository/base_repository.dart';
import 'package:patrol/core/utils/facility_log_model.dart';
import 'package:patrol/core/utils/incident_log_model.dart';
import 'package:patrol/core/utils/incident_record_db.dart';
import 'package:patrol/core/utils/patrol_calendar_model.dart';
import 'package:patrol/core/utils/patrol_form_photo.dart';
import 'package:patrol/core/utils/patrol_log_model.dart';
import 'package:patrol/core/utils/patrol_record_db.dart';
import 'package:patrol/core/utils/visitor_log_model.dart';
import 'package:patrol_service/patrol_service.dart';

/// Outcome of an addPatrolRecord call — [message] carries `status.message`
/// from the API response regardless of success/fail, so callers can persist
/// it for later inspection (e.g. "Same UUID exist").
class PatrolSyncResult {
  final bool success;
  final String? message;

  /// Raw `resultSet[0].patrol_route_history` on success — a JSON-encoded
  /// `[{uuid, digital_form_id, checkpoint_id, form_attachment}]` list that
  /// drives the follow-up photo upload.
  final String? routeHistory;

  PatrolSyncResult({required this.success, this.message, this.routeHistory});
}

/// Outcome of a getPatrolHomeData call — [facility], [patrol], [incident],
/// [checkin] and [checkout] are the (still JSON-encoded-string) fields
/// straight from `resultSet[0]`.
class PatrolHomeDataResult {
  final bool success;
  final String? facility;
  final String? patrol;
  final String? incident;

  /// Raw `incident_digitalform` (the Add Incident form).
  final String? incidentDigitalForm;
  final String? checkin;
  final String? checkout;
  final bool vmsActive;
  final String? projectName;
  final String? message;

  PatrolHomeDataResult({
    required this.success,
    this.facility,
    this.patrol,
    this.incident,
    this.incidentDigitalForm,
    this.checkin,
    this.checkout,
    this.vmsActive = false,
    this.projectName,
    this.message,
  });
}

/// Outcome of a getFacilityReport call — [report] is parsed from the
/// (still JSON-encoded-string) `resultSet[0].report` field.
class FacilityReportResult {
  final bool success;
  final FacilityLogReport? report;
  final String? message;

  FacilityReportResult({required this.success, this.report, this.message});
}

/// Outcome of an addIncident call — [message] carries `status.message` from
/// the API response regardless of success/fail, so callers can persist it
/// for later inspection.
class IncidentSyncResult {
  final bool success;
  final String? message;

  /// `digital_form_id` from `resultSet[0].addincident` on success — needed
  /// for the follow-up photo upload.
  final String? digitalFormId;

  IncidentSyncResult({required this.success, this.message, this.digitalFormId});
}

/// Outcome of a getIncidentReport call — [report] is parsed from the
/// (still JSON-encoded-string) `resultSet[0].report` field.
class IncidentReportResult {
  final bool success;
  final IncidentLogReport? report;

  /// Raw `incident_digitalform` — same as getpatrolhomedata's, but fresh.
  final String? incidentDigitalForm;
  final String? message;

  IncidentReportResult({
    required this.success,
    this.report,
    this.incidentDigitalForm,
    this.message,
  });
}

/// Outcome of a getPatrolReport call — [report] is parsed from the
/// (still JSON-encoded-string) `resultSet[0].report` field.
class PatrolReportResult {
  final bool success;
  final PatrolLogReport? report;
  final String? message;

  PatrolReportResult({required this.success, this.report, this.message});
}

/// Outcome of a getVisitorReport call — [report] is parsed from the
/// (still JSON-encoded-string) `resultSet[0].report` field. Shares
/// [VisitorLogReport] with the SQLite `checkin`/`checkout` snapshots since
/// both come from the same JSON shape.
class VisitorReportResult {
  final bool success;
  final VisitorLogReport? report;
  final String? message;

  VisitorReportResult({required this.success, this.report, this.message});
}

/// Outcome of a getPatrolCalendarShift call — [shifts] is parsed from the
/// (still JSON-encoded-string) `resultSet[0].patrolcalendar` field.
class PatrolCalendarShiftResult {
  final bool success;
  final List<PatrolCalendarShift> shifts;
  final String? message;

  PatrolCalendarShiftResult({
    required this.success,
    this.shifts = const [],
    this.message,
  });
}

/// Outcome of a getPatrolShiftRoute call — [route] is parsed from the
/// (still JSON-encoded-string) `resultSet[0].shiftroute` field.
class PatrolShiftRouteResult {
  final bool success;
  final PatrolShiftRoute? route;

  /// Raw `shiftroute` string, for storing verbatim in SQLite.
  final String routeJson;

  /// Raw `digitalFormCheckpointSkip` — the form filled when a checkpoint is
  /// skipped; empty when the shift has none.
  final String skipFormJson;
  final String? message;

  PatrolShiftRouteResult({
    required this.success,
    this.route,
    this.routeJson = '',
    this.skipFormJson = '',
    this.message,
  });
}

class PatrolRepository with BaseRepository {
  final PatrolService patrolService;

  PatrolRepository({required this.patrolService});

  Future<PatrolSyncResult> addPatrolRecord({
    required PatrolRecordHeader header,
    required List<PatrolRecordBody> records,
  }) async {
    Jmap fieldMap = {};
    fieldMap['auth_token'] = authToken;
    fieldMap['hash'] = hashSecretAuthToken;
    fieldMap['startdate'] = header.startDate;
    fieldMap['enddate'] = header.endDate;
    fieldMap['uuid'] = header.uuid;
    fieldMap['calendar_id'] = header.calendarId;
    fieldMap['shift_id'] = header.shiftId;
    fieldMap['patrol_route_id'] = header.patrolRouteId;
    fieldMap['patrol_record'] = records
        .map((body) => {
              'checkpoint_id': body.checkpointId,
              'checkdate': body.scanDate,
              'org_form_id': body.orgFormId,
              'form_id': '',
              'isskip': body.isSkip,
              'form_attachment': body.formAttachment,
              'form_answer': _decodeFormAnswer(body.formAnswer),
            })
        .toList();

    debugPrint(
      '[PatrolSync] ${header.uuid} sending form_attachment: '
      '${records.map((r) => '${r.checkpointId}=${r.formAttachment}').join(', ')}',
    );
    final response = await patrolService.addPatrolRecord(fieldMap);
    // response.printSingle;

    final status = response.responseData?['status'];
    final resultSet = response.responseData?['resultSet'];
    final first =
        resultSet is List && resultSet.isNotEmpty ? resultSet.first : null;
    return PatrolSyncResult(
      success: response.isSuccess(),
      message: status is Map ? status['message'] as String? : null,
      routeHistory:
          first is Map ? _asJsonString(first['patrol_route_history']) : null,
    );
  }

  /// Uploads one checkpoint's digital-form photos as multipart form-data.
  /// [photos] are already-compressed `.webp` files; `json_image` lists
  /// their names in the same order as the `uploadImages[]` parts. Photos
  /// whose file no longer exists are skipped.
  Future<PatrolSyncResult> addPatrolRecordImage({
    required String digitalFormId,
    required String checkpointId,
    required List<PatrolFormPhoto> photos,
  }) {
    return _uploadFormImages(
      patrolService.addPatrolRecordImage,
      fields: {'digital_form_id': digitalFormId, 'checkpoint_id': checkpointId},
      photos: photos,
    );
  }

  /// Same as [addPatrolRecordImage], for an incident's digital form.
  Future<PatrolSyncResult> addIncidentImage({
    required String digitalFormId,
    required List<PatrolFormPhoto> photos,
  }) {
    return _uploadFormImages(
      patrolService.addIncidentImage,
      fields: {'digital_form_id': digitalFormId},
      photos: photos,
    );
  }

  Future<PatrolSyncResult> _uploadFormImages(
    Future<dynamic> Function(dynamic data) post, {
    required Map<String, String> fields,
    required List<PatrolFormPhoto> photos,
  }) async {
    final existing = <PatrolFormPhoto>[];
    for (final photo in photos) {
      if (await File(photo.path).exists()) existing.add(photo);
    }
    // Nothing left to send — treat as done so it isn't retried forever.
    if (existing.isEmpty) return PatrolSyncResult(success: true);

    final formData = FormData();
    formData.fields.addAll([
      MapEntry('auth_token', authToken),
      MapEntry('hash', hashSecretAuthToken),
      ...fields.entries,
      MapEntry(
        'json_image',
        jsonEncode(
          existing
              .map((p) => {'document_name': p.name, 'extension': 'webp'})
              .toList(),
        ),
      ),
    ]);
    for (final photo in existing) {
      formData.files.add(
        MapEntry(
          'uploadImages[]',
          await MultipartFile.fromFile(photo.path, filename: photo.name),
        ),
      );
    }

    final response = await post(formData);
    // response.printSingle;

    final status = response.responseData?['status'];
    return PatrolSyncResult(
      success: response.isSuccess(),
      message: status is Map ? status['message'] as String? : null,
    );
  }

  /// `patrol_route_history` is documented as a JSON string, but accept an
  /// already-decoded list too rather than failing the whole sync.
  String? _asJsonString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return jsonEncode(value);
  }

  /// Stored answers are a JSON string; the API wants the list itself, or
  /// null when the checkpoint has no form.
  List<dynamic>? _decodeFormAnswer(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<PatrolHomeDataResult> getPatrolHomeData() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Jmap fieldMap = {};
    fieldMap['auth_token'] = authToken;
    fieldMap['hash'] = hashSecretAuthToken;
    fieldMap['startdate'] = today;
    fieldMap['enddate'] = today;
    fieldMap['page'] = '1';

    final response = await patrolService.getPatrolHomeData(fieldMap);
    final status = response.responseData?['status'];
    final message = status is Map ? status['message'] as String? : null;

    if (!response.isSuccess()) {
      return PatrolHomeDataResult(success: false, message: message);
    }

    final resultSet = response.responseData?['resultSet'];
    if (resultSet is! List || resultSet.isEmpty) {
      return PatrolHomeDataResult(success: false, message: message);
    }

    final first = resultSet.first;
    return PatrolHomeDataResult(
      success: true,
      facility: first is Map ? first['facility'] as String? ?? '' : '',
      patrol: first is Map ? first['patrol'] as String? ?? '' : '',
      incident: first is Map ? first['incident'] as String? ?? '' : '',
      incidentDigitalForm: first is Map
          ? _asJsonString(first['incident_digitalform']) ?? ''
          : '',
      checkin: first is Map ? first['checkin'] as String? ?? '' : '',
      checkout: first is Map ? first['checkout'] as String? ?? '' : '',
      vmsActive: first is Map ? (first['vmsactive'] as num?)?.toInt() == 1 : false,
      projectName: first is Map ? first['projectname'] as String? ?? '' : '',
      message: message,
    );
  }

  Future<FacilityReportResult> getFacilityReport({
    required String startDate,
    required String endDate,
  }) async {
    Jmap fieldMap = {};
    fieldMap['auth_token'] = authToken;
    fieldMap['hash'] = hashSecretAuthToken;
    fieldMap['startdate'] = startDate;
    fieldMap['enddate'] = endDate;
    fieldMap['page'] = '1';

    final response = await patrolService.getFacilityReport(fieldMap);
    final status = response.responseData?['status'];
    final message = status is Map ? status['message'] as String? : null;

    if (!response.isSuccess()) {
      return FacilityReportResult(success: false, message: message);
    }

    final resultSet = response.responseData?['resultSet'];
    if (resultSet is! List || resultSet.isEmpty) {
      return FacilityReportResult(success: false, message: message);
    }

    final first = resultSet.first;
    final rawReport = first is Map ? first['report'] as String? : null;
    return FacilityReportResult(
      success: true,
      report: parseFacilityLogReport(rawReport),
      message: message,
    );
  }

  /// Posts an incident's digital form (same `form_answer` shape as
  /// `patrol_record` in [addPatrolRecord]); photos follow separately via
  /// [addIncidentImage] using the returned `digital_form_id`.
  Future<IncidentSyncResult> addIncident({
    required IncidentRecord record,
  }) async {
    Jmap fieldMap = {};
    fieldMap['auth_token'] = authToken;
    fieldMap['hash'] = hashSecretAuthToken;
    fieldMap['dateinput'] = record.addDate;
    fieldMap['uuid'] = record.uuid;
    fieldMap['patrol_incident'] = {
      'org_form_id': record.orgFormId,
      'form_id': '',
      'form_attachment': record.formAttachment,
      'form_answer': _decodeFormAnswer(record.formAnswer),
    };

    final response = await patrolService.addIncident(fieldMap);
    // response.printSingle;

    final status = response.responseData?['status'];
    final message = status is Map ? status['message'] as String? : null;
    if (!response.isSuccess()) {
      return IncidentSyncResult(success: false, message: message);
    }

    final resultSet = response.responseData?['resultSet'];
    final first =
        resultSet is List && resultSet.isNotEmpty ? resultSet.first : null;
    return IncidentSyncResult(
      success: true,
      message: message,
      digitalFormId: _findDigitalFormId(
        first is Map ? first['addincident'] : null,
        record.uuid,
      ),
    );
  }

  /// `addincident` is a JSON-encoded `[{uuid, digital_form_id,
  /// form_attachment}]` list — picks the row for [uuid], else the first.
  String? _findDigitalFormId(dynamic raw, String uuid) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List) return null;
      final rows = decoded.whereType<Map>().toList();
      if (rows.isEmpty) return null;
      final row = rows.firstWhere(
        (r) => r['uuid']?.toString() == uuid,
        orElse: () => rows.first,
      );
      final id = row['digital_form_id']?.toString() ?? '';
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  Future<IncidentReportResult> getIncidentReport({
    required String startDate,
    required String endDate,
  }) async {
    Jmap fieldMap = {};
    fieldMap['auth_token'] = authToken;
    fieldMap['hash'] = hashSecretAuthToken;
    fieldMap['startdate'] = startDate;
    fieldMap['enddate'] = endDate;
    fieldMap['page'] = 1;

    final response = await patrolService.getIncidentReport(fieldMap);
    final status = response.responseData?['status'];
    final message = status is Map ? status['message'] as String? : null;

    if (!response.isSuccess()) {
      return IncidentReportResult(success: false, message: message);
    }

    final resultSet = response.responseData?['resultSet'];
    if (resultSet is! List || resultSet.isEmpty) {
      return IncidentReportResult(success: false, message: message);
    }

    final first = resultSet.first;
    final rawReport = first is Map ? first['report'] as String? : null;
    return IncidentReportResult(
      success: true,
      report: parseIncidentLogReport(rawReport),
      incidentDigitalForm: first is Map
          ? _asJsonString(first['incident_digitalform'])
          : null,
      message: message,
    );
  }

  Future<PatrolReportResult> getPatrolReport({
    required String startDate,
    required String endDate,
  }) async {
    Jmap fieldMap = {};
    fieldMap['auth_token'] = authToken;
    fieldMap['hash'] = hashSecretAuthToken;
    fieldMap['startdate'] = startDate;
    fieldMap['enddate'] = endDate;
    fieldMap['page'] = 1;

    final response = await patrolService.getPatrolReport(fieldMap);
    final status = response.responseData?['status'];
    final message = status is Map ? status['message'] as String? : null;

    if (!response.isSuccess()) {
      return PatrolReportResult(success: false, message: message);
    }

    final resultSet = response.responseData?['resultSet'];
    if (resultSet is! List || resultSet.isEmpty) {
      return PatrolReportResult(success: false, message: message);
    }

    final first = resultSet.first;
    final rawReport = first is Map ? first['report'] as String? : null;
    return PatrolReportResult(
      success: true,
      report: parsePatrolLogReport(rawReport),
      message: message,
    );
  }

  Future<VisitorReportResult> getVisitorReport({
    required String startDate,
    required String endDate,
    required String logType,
    String searchText = '',
  }) async {
    Jmap fieldMap = {};
    fieldMap['auth_token'] = authToken;
    fieldMap['hash'] = hashSecretAuthToken;
    fieldMap['startdate'] = startDate;
    fieldMap['enddate'] = endDate;
    fieldMap['searchtext'] = searchText;
    fieldMap['log_type'] = logType;
    fieldMap['page'] = 1;

    final response = await patrolService.getVisitorReport(fieldMap);
    final status = response.responseData?['status'];
    final message = status is Map ? status['message'] as String? : null;

    if (!response.isSuccess()) {
      return VisitorReportResult(success: false, message: message);
    }

    final resultSet = response.responseData?['resultSet'];
    if (resultSet is! List || resultSet.isEmpty) {
      return VisitorReportResult(success: false, message: message);
    }

    final first = resultSet.first;
    final rawReport = first is Map ? first['report'] as String? : null;
    return VisitorReportResult(
      success: true,
      report: parseVisitorLogReport(rawReport),
      message: message,
    );
  }

  Future<PatrolCalendarShiftResult> getPatrolCalendarShift() async {
    Jmap fieldMap = {};
    fieldMap['auth_token'] = authToken;
    fieldMap['hash'] = hashSecretAuthToken;

    final response = await patrolService.getPatrolCalendarShift(fieldMap);
    final status = response.responseData?['status'];
    final message = status is Map ? status['message'] as String? : null;

    if (!response.isSuccess()) {
      return PatrolCalendarShiftResult(success: false, message: message);
    }

    final resultSet = response.responseData?['resultSet'];
    if (resultSet is! List || resultSet.isEmpty) {
      return PatrolCalendarShiftResult(success: true, message: message);
    }

    final first = resultSet.first;
    final raw = first is Map ? first['patrolcalendar'] as String? : null;
    return PatrolCalendarShiftResult(
      success: true,
      shifts: parsePatrolCalendarShifts(raw),
      message: message,
    );
  }

  Future<PatrolShiftRouteResult> getPatrolShiftRoute({
    required String shiftId,
  }) async {
    Jmap fieldMap = {};
    fieldMap['auth_token'] = authToken;
    fieldMap['hash'] = hashSecretAuthToken;
    fieldMap['shift_id'] = shiftId;

    final response = await patrolService.getPatrolShiftRoute(fieldMap);
    final status = response.responseData?['status'];
    final message = status is Map ? status['message'] as String? : null;

    if (!response.isSuccess()) {
      return PatrolShiftRouteResult(success: false, message: message);
    }

    final resultSet = response.responseData?['resultSet'];
    if (resultSet is! List || resultSet.isEmpty) {
      return PatrolShiftRouteResult(success: true, message: message);
    }

    final first = resultSet.first;
    final raw = first is Map ? first['shiftroute'] as String? : null;
    return PatrolShiftRouteResult(
      success: true,
      route: parsePatrolShiftRoute(raw),
      routeJson: raw ?? '',
      skipFormJson: first is Map
          ? _asJsonString(first['digitalFormCheckpointSkip']) ?? ''
          : '',
      message: message,
    );
  }
}
