import 'package:dio_client/dio_client.dart';

abstract class GeneralApi {
  Future<dynamic> version(dynamic data);
  Future<dynamic> sos(dynamic data);
  Future<dynamic> callLog(dynamic data);
  Future<dynamic> getGoGuardLog(dynamic data);
}

class GeneralService extends GeneralApi {
  final DioClient dioClient;

  GeneralService({required this.dioClient});

  @override
  Future<DioResponse> version(data) async {
    return await dioClient.post('/version', data: data);
  }

  @override
  Future<DioResponse> sos(data) async {
    return await dioClient.post('/goguard/sos', data: data);
  }

  @override
  Future<DioResponse> callLog(data) async {
    return await dioClient.post('/goguard/getcalllog', data: data);
  }

  @override
  Future<DioResponse> getGoGuardLog(data) async {
    return await dioClient.post('/goguard/getvmslog', data: data);
  }
}
