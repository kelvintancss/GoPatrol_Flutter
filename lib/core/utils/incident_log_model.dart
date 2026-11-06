import 'dart:convert';

import 'package:patrol/core/utils/patrol_calendar_model.dart';

/// Shared shape for both the SQLite `incident` snapshot (today's data,
/// stored verbatim from `/patrol/getpatrolhomedata`) and the
/// `/patrol/getincidentreport` response's `report` field — both are
/// JSON-encoded strings with this same structure, keyed `incidentlog`.
class IncidentLogReport {
  final int totalPage;
  final int currentPage;
  final List<IncidentLogMonth> log;

  IncidentLogReport({
    required this.totalPage,
    required this.currentPage,
    required this.log,
  });

  factory IncidentLogReport.fromJson(Map<String, dynamic> json) {
    return IncidentLogReport(
      totalPage: (json['total_page'] as num?)?.toInt() ?? 1,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      log: (json['incidentlog'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(IncidentLogMonth.fromJson)
          .toList(),
    );
  }
}

class IncidentLogMonth {
  final String month;
  final List<IncidentLogDateGroup> dateGroups;

  IncidentLogMonth({required this.month, required this.dateGroups});

  factory IncidentLogMonth.fromJson(Map<String, dynamic> json) {
    return IncidentLogMonth(
      month: json['month'] as String? ?? '',
      dateGroups: (json['dategroup'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(IncidentLogDateGroup.fromJson)
          .toList(),
    );
  }
}

class IncidentLogDateGroup {
  final String dateInputDay;
  final List<IncidentLogEntry> data;

  IncidentLogDateGroup({required this.dateInputDay, required this.data});

  factory IncidentLogDateGroup.fromJson(Map<String, dynamic> json) {
    return IncidentLogDateGroup(
      dateInputDay: json['dateinput_day'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(IncidentLogEntry.fromJson)
          .toList(),
    );
  }
}

class IncidentLogEntry {
  final int id;
  final String cssLoginCode;
  final String dateInput;

  /// `incidentForm_List.form_name`.
  final String formName;

  /// `incidentForm_List.digitalFormDetail` — the submitted form items, with
  /// answers in `formValue` / `formItemGroupList`.
  final List<PatrolFormItem> formItems;

  /// `incidentForm_List.attach_image` — image URLs.
  final List<String> attachImages;

  IncidentLogEntry({
    required this.id,
    required this.cssLoginCode,
    required this.dateInput,
    required this.formName,
    required this.formItems,
    required this.attachImages,
  });

  factory IncidentLogEntry.fromJson(Map<String, dynamic> json) {
    final form = _decodeJson(json['incidentForm_List']);
    final formMap = form is Map ? Map<String, dynamic>.from(form) : null;
    final detail = _decodeJson(formMap?['digitalFormDetail']);
    return IncidentLogEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cssLoginCode: json['css_login_code'] as String? ?? '',
      dateInput: json['dateinput'] as String? ?? '',
      formName: formMap?['form_name']?.toString() ?? '',
      formItems: detail is List
          ? detail
              .whereType<Map>()
              .map((e) => PatrolFormItem(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      attachImages: _parseImageUrls(formMap?['attach_image']),
    );
  }
}

/// Decodes [value] when it arrives as a JSON-encoded string; otherwise
/// returns it as is (null when the string is malformed).
dynamic _decodeJson(dynamic value) {
  if (value is! String) return value;
  if (value.trim().isEmpty) return null;
  try {
    return jsonDecode(value);
  } catch (_) {
    return null;
  }
}

/// `attach_image` shape isn't fixed yet — accepts a URL list, a list of
/// objects holding a URL, a JSON string of either, or a comma-separated
/// string.
List<String> _parseImageUrls(dynamic value) {
  final decoded = _decodeJson(value);
  if (decoded == null && value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  final list = decoded is List ? decoded : [?decoded];
  final urls = <String>[];
  for (final item in list) {
    if (item is String && item.trim().isNotEmpty) {
      urls.add(item.trim());
    } else if (item is Map) {
      final url = item.values.whereType<String>().firstWhere(
            (v) => v.startsWith('http'),
            orElse: () => '',
          );
      if (url.isNotEmpty) urls.add(url);
    }
  }
  return urls;
}

/// Null on missing/blank/malformed input rather than throwing — both call
/// sites (local SQLite snapshot, API response) treat "no data" as an empty
/// list rather than an error.
IncidentLogReport? parseIncidentLogReport(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return IncidentLogReport.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
