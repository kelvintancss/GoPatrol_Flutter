import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'dio_response.dart';

typedef Jmap = Map<String, dynamic>;

class DioClient {
  DioClient({
    required this.baseUrl,
    this.headers,
    this.interceptors,
    this.connectTimeout = 60,
    this.receiveTimeout = 60,
    this.sendTimeout = 60,
  }) {
    _dio.options
      ..baseUrl = baseUrl
      ..headers = headers
      ..sendTimeout = Duration(seconds: connectTimeout)
      ..receiveTimeout = Duration(seconds: receiveTimeout)
      ..connectTimeout = Duration(seconds: sendTimeout);
    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors!);
    }
  }

  final String baseUrl;
  final Map<String, dynamic>? headers;
  final List<Interceptor>? interceptors;
  final int connectTimeout;
  final int receiveTimeout;
  final int sendTimeout;

  final Dio _dio = Dio();
  Dio get dioObject => _dio;

  // Dio get dio {
  //   final dio = Dio(BaseOptions(
  //     baseUrl: baseUrl,
  //     headers: headers,
  //     connectTimeout: Duration(seconds: connectTimeout),
  //     receiveTimeout: Duration(seconds: receiveTimeout),
  //     sendTimeout: Duration(seconds: sendTimeout),
  //   ));

  //   if (interceptors != null) {
  //     dio.interceptors.addAll(interceptors!);
  //   }

  //   return dio;
  // }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Future<DioResponse> get(
    String url, {
    Jmap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return SuccessResponse(
          response: response,
          requestOptions: response.requestOptions,
          url: url);
    } catch (e) {
      rethrow;
    }
  }

  Future<DioResponse> post(
    String url, {
    dynamic data,
    Jmap? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return SuccessResponse(
          response: response,
          url: url,
          requestOptions: response.requestOptions);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path,
      {dynamic data, Jmap? queryParameters}) async {
    return await _dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(String path,
      {dynamic data, Jmap? queryParameters}) async {
    return await _dio.delete(path,
        data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(String path,
      {dynamic data, Jmap? queryParameters}) async {
    return await _dio.patch(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> head(String path, {Jmap? queryParameters}) async {
    return await _dio.head(path, queryParameters: queryParameters);
  }

  Future<Response> download(String url, String savePath,
      {Jmap? queryParameters}) async {
    return await _dio.download(url, savePath, queryParameters: queryParameters);
  }

  Future<Response> upload(String path, String filePath,
      {Jmap? queryParameters}) async {
    return await _dio.post(path,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath),
        }),
        queryParameters: queryParameters);
  }

  // ignore: unused_element
  void _printApiResponse(
    String url,
    Map<String, dynamic>? queryParameters,
    Response response,
  ) {
    var encoder = const JsonEncoder.withIndent("  ");
    var queryStr = encoder.convert(queryParameters);

    try {
      var jsonObjJmap = response.data as Jmap;
      var jsonStr = encoder.convert(jsonObjJmap);

      debugPrint("URL:\n$url\n");
      debugPrint("Input:\n$queryStr\n");
      debugPrint("Response:\n$jsonStr\n");
    } catch (e) {
      debugPrint("URL:\n$url\n");
      debugPrint("Input:\n$queryStr\n");
      debugPrint("Response:\n${response.data}\n");
    }
  }
}
