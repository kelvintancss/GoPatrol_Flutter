import 'package:dio_client/dio_client.dart';

abstract class AuthApi {
  Future<dynamic> postTempToken(dynamic data);
  Future<dynamic> postAuthToken(dynamic data);
  Future<dynamic> postVerifyAdminPassword(dynamic data);
  Future<dynamic> postLogin(dynamic data);
  Future<dynamic> postLogout(dynamic data);
}

class AuthService extends AuthApi {
  final DioClient dioClient;

  AuthService({required this.dioClient});

  @override
  Future<DioResponse> postTempToken(data) async {
    return await dioClient.post('/token', data: data);
  }

  @override
  Future<DioResponse> postAuthToken(data) async {
    return await dioClient.post('/token/authorize', data: data);
  }

  @override
  Future<DioResponse> postVerifyAdminPassword(data) async {
    return await dioClient.post('/verifyadminpwd', data: data);
  }

  @override
  Future<DioResponse> postLogin(data) async {
    return await dioClient.post('/patrol/login', data: data);
  }

  @override
  Future<DioResponse> postLogout(data) async {
    return await dioClient.post('/patrol/logout', data: data);
  }
}
