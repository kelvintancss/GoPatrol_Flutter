import 'dart:convert';

/// Shared shape for both the SQLite `facility` snapshot (today's data,
/// stored verbatim from `/patrol/getpatrolhomedata`) and the
/// `/patrol/getFacilityReport` response's `report` field — both are
/// JSON-encoded strings with this same structure, keyed `facilitylog`.
class FacilityLogReport {
  final int totalPage;
  final int currentPage;
  final List<FacilityLogMonth> log;

  FacilityLogReport({
    required this.totalPage,
    required this.currentPage,
    required this.log,
  });

  factory FacilityLogReport.fromJson(Map<String, dynamic> json) {
    return FacilityLogReport(
      totalPage: (json['total_page'] as num?)?.toInt() ?? 1,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      log: (json['facilitylog'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FacilityLogMonth.fromJson)
          .toList(),
    );
  }
}

class FacilityLogMonth {
  final String month;
  final List<FacilityLogDateGroup> dateGroups;

  FacilityLogMonth({required this.month, required this.dateGroups});

  factory FacilityLogMonth.fromJson(Map<String, dynamic> json) {
    return FacilityLogMonth(
      month: json['month'] as String? ?? '',
      dateGroups: (json['dategroup'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FacilityLogDateGroup.fromJson)
          .toList(),
    );
  }
}

class FacilityLogDateGroup {
  final String bookingDate;
  final String bookingDay;
  final List<FacilityLogEntry> data;

  FacilityLogDateGroup({
    required this.bookingDate,
    required this.bookingDay,
    required this.data,
  });

  factory FacilityLogDateGroup.fromJson(Map<String, dynamic> json) {
    return FacilityLogDateGroup(
      bookingDate: json['booking_date'] as String? ?? '',
      bookingDay: json['booking_day'] as String? ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FacilityLogEntry.fromJson)
          .toList(),
    );
  }
}

class FacilityLogEntry {
  final String lotNo;
  final String facility;
  final String contactName;
  final String? contactNo;
  final String? bookingTimeIn;
  final String? bookingTimeOut;

  FacilityLogEntry({
    required this.lotNo,
    required this.facility,
    required this.contactName,
    this.contactNo,
    this.bookingTimeIn,
    this.bookingTimeOut,
  });

  factory FacilityLogEntry.fromJson(Map<String, dynamic> json) {
    return FacilityLogEntry(
      lotNo: json['lotno'] as String? ?? '',
      facility: json['facility'] as String? ?? '',
      contactName: json['contact_name'] as String? ?? '',
      contactNo: json['contact_no'] as String?,
      bookingTimeIn: json['booking_time_in'] as String?,
      bookingTimeOut: json['booking_time_out'] as String?,
    );
  }
}

/// Null on missing/blank/malformed input rather than throwing — both call
/// sites (local SQLite snapshot, API response) treat "no data" as an empty
/// list rather than an error.
FacilityLogReport? parseFacilityLogReport(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return FacilityLogReport.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
