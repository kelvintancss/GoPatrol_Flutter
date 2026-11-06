import 'package:dio_client/dio_client.dart';

abstract class PatrolApi {
  Future<dynamic> addPatrolRecord(dynamic data);
  Future<dynamic> addPatrolRecordImage(dynamic data);
  Future<dynamic> getPatrolHomeData(dynamic data);
  Future<dynamic> getFacilityReport(dynamic data);
  Future<dynamic> addIncident(dynamic data);
  Future<dynamic> addIncidentImage(dynamic data);
  Future<dynamic> getIncidentReport(dynamic data);
  Future<dynamic> getPatrolReport(dynamic data);
  Future<dynamic> getVisitorReport(dynamic data);
  Future<dynamic> getPatrolCalendarShift(dynamic data);
  Future<dynamic> getPatrolShiftRoute(dynamic data);
}

class PatrolService extends PatrolApi {
  final DioClient dioClient;

  PatrolService({required this.dioClient});

  @override
  Future<DioResponse> addPatrolRecord(data) async {
    return await dioClient.post('/patrol/addpatrolrecord', data: data);
  }

  @override
  Future<DioResponse> addPatrolRecordImage(data) async {
    return await dioClient.post('/patrol/addpatrolrecordimage', data: data);
  }

  @override
  Future<DioResponse> getPatrolHomeData(data) async {
    return await dioClient.post('/patrol/getpatrolhomedata', data: data);
  }

  @override
  Future<DioResponse> getFacilityReport(data) async {
    return await dioClient.post('/patrol/getFacilityReport', data: data);
  }

  @override
  Future<DioResponse> addIncident(data) async {
    return await dioClient.post('/patrol/addincident', data: data);
  }

  @override
  Future<DioResponse> addIncidentImage(data) async {
    return await dioClient.post('/patrol/addincidentimage', data: data);
  }

  @override
  Future<DioResponse> getIncidentReport(data) async {
    return await dioClient.post('/patrol/getincidentreport', data: data);
  }

  @override
  Future<DioResponse> getPatrolReport(data) async {
    return await dioClient.post('/patrol/getPatrolReport', data: data);
  }

  @override
  Future<DioResponse> getVisitorReport(data) async {
    return await dioClient.post('/patrol/getvisitorreport', data: data);
  }

  @override
  Future<DioResponse> getPatrolCalendarShift(data) async {
    return await dioClient.post('/patrol/getPatrolCalendarShift', data: data);
  }

  @override
  Future<DioResponse> getPatrolShiftRoute(data) async {
    return await dioClient.post('/patrol/getPatrolShiftRoute', data: data);
  }
}
