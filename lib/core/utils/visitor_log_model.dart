import 'dart:convert';

/// Shared shape for both the SQLite `checkin`/`checkout` snapshots (today's
/// data, stored verbatim from `/patrol/getpatrolhomedata`) and the
/// `/patrol/getvisitorreport` response's `report` field — both are
/// JSON-encoded strings with this same structure, keyed `visitorlog`.
class VisitorLogReport {
  final int totalPage;
  final int currentPage;
  final List<VisitorLogMonth> log;

  VisitorLogReport({
    required this.totalPage,
    required this.currentPage,
    required this.log,
  });

  factory VisitorLogReport.fromJson(Map<String, dynamic> json) {
    return VisitorLogReport(
      totalPage: (json['total_page'] as num?)?.toInt() ?? 1,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      log: (json['visitorlog'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(VisitorLogMonth.fromJson)
          .toList(),
    );
  }
}

class VisitorLogMonth {
  final String month;
  final List<VisitorLogDateGroup> dateGroups;

  VisitorLogMonth({required this.month, required this.dateGroups});

  factory VisitorLogMonth.fromJson(Map<String, dynamic> json) {
    return VisitorLogMonth(
      month: json['month'] as String? ?? '',
      dateGroups: (json['dategroup'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(VisitorLogDateGroup.fromJson)
          .toList(),
    );
  }
}

class VisitorLogDateGroup {
  final String createdDate;
  final List<VisitorLogEntry> data;

  VisitorLogDateGroup({required this.createdDate, required this.data});

  factory VisitorLogDateGroup.fromJson(Map<String, dynamic> json) {
    return VisitorLogDateGroup(
      createdDate: json['created_date'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(VisitorLogEntry.fromJson)
          .toList(),
    );
  }
}

class VisitorLogEntry {
  final String recordId;
  final String recordSource;
  final String vmsType;
  final String lotNo;
  final String visitorName;
  final String? visitorContactNo;
  final String? visitorVehicleNo;
  final String? visitorIdNo;
  final String? visitorEmail;
  final int? visitorPax;
  final String? preGenCodeNo;
  final String? visitDateTo;
  final String? checkInDate;
  final String? remarks;
  final int? entryId;
  final String? actionType;
  final String? created;
  final int? rn;
  final bool overstay;

  VisitorLogEntry({
    required this.recordId,
    required this.recordSource,
    required this.vmsType,
    required this.lotNo,
    required this.visitorName,
    this.visitorContactNo,
    this.visitorVehicleNo,
    this.visitorIdNo,
    this.visitorEmail,
    this.visitorPax,
    this.preGenCodeNo,
    this.visitDateTo,
    this.checkInDate,
    this.remarks,
    this.entryId,
    this.actionType,
    this.created,
    this.rn,
    this.overstay = false,
  });

  factory VisitorLogEntry.fromJson(Map<String, dynamic> json) {
    return VisitorLogEntry(
      recordId: json['record_id'] as String? ?? '',
      recordSource: json['record_source'] as String? ?? '',
      vmsType: json['vms_type'] as String? ?? '',
      lotNo: json['lotno'] as String? ?? '',
      visitorName: json['visitor_name'] as String? ?? '',
      visitorContactNo: json['visitor_contact_no'] as String?,
      visitorVehicleNo: json['visitor_vehicle_no'] as String?,
      visitorIdNo: json['visitor_id_no'] as String?,
      visitorEmail: json['visitor_email'] as String?,
      visitorPax: (json['visitor_pax'] as num?)?.toInt(),
      preGenCodeNo: json['pre_gen_code_no'] as String?,
      visitDateTo: json['visit_date_to'] as String?,
      checkInDate: json['check_in_date'] as String?,
      remarks: json['remarks'] as String?,
      entryId: (json['entry_id'] as num?)?.toInt(),
      actionType: json['action_type'] as String?,
      created: json['created'] as String?,
      rn: (json['rn'] as num?)?.toInt(),
      overstay: json['overstay'] as bool? ?? false,
    );
  }
}

/// Null on missing/blank/malformed input rather than throwing — both call
/// sites (local SQLite snapshot, API response) treat "no data" as an empty
/// list rather than an error.
VisitorLogReport? parseVisitorLogReport(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return VisitorLogReport.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
