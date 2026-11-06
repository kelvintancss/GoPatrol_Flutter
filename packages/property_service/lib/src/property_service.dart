import 'package:dio_client/dio_client.dart';

abstract class PropertyApi {
  Future<dynamic> getProjectId(dynamic data);
  Future<dynamic> postGetHomeInfo(dynamic data);
}

class PropertyService extends PropertyApi {
  final DioClient dioClient;

  PropertyService({required this.dioClient});

  @override
  Future<DioResponse> getProjectId(data) async {
    return await dioClient.post('/projectid', data: data);
  }

  @override
  Future<DioResponse> postGetHomeInfo(data) async {
    return await dioClient.post('/goguard/homeinfo', data: data);
  }
}
