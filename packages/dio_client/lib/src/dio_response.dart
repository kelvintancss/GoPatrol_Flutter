import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'api_constants.dart';

/// Custom http response model
abstract class DioResponse extends Response {
  DioResponse({
    required this.response,
    this.url,
    required super.requestOptions,
  });

  final dynamic response;
  final String? url;

  get code {
    return response.data["status"]["code"];
  }

  get responseData {
    return response.data;
  }

  @override
  get statusCode {
    return response.data["status"]["code"];
  }

  @override
  get statusMessage {
    return response.data["status"]["message"];
  }

  get printSingle {
    var encoder = const JsonEncoder.withIndent("  ");
    var jsonObjJmap = response.data as Map;
    var jsonStr = encoder.convert(jsonObjJmap);
    debugPrint("$url\n$jsonStr");
  }

  bool isSuccess() {
    return code == ApiConstants.success;
  }

  bool isInvalidAuthToken() {
    return code == ApiConstants.invalidAuthToken;
  }
}

class SuccessResponse extends DioResponse {
  SuccessResponse({required super.response, super.url, required super.requestOptions});
}

class FailureResponse extends DioResponse {
  FailureResponse({required super.response, required super.requestOptions});
}
