import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart' show FlutterNativeSplash;
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/core/repository/base_repository.dart';
import 'package:patrol/core/services/secure_storage.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/core/utils/app_reload_provider.dart';
import 'package:patrol/core/utils/constants.dart';
import 'package:patrol/core/widgets/custom_dialog.dart';
import 'package:patrol/service_locator.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

class DioInterceptor extends Interceptor with BaseRepository, AppReloadProvider {
  final _secureLocator = sl<SecureStorage>();

  DioInterceptor();

  // prevent multiple api call for error handling
  bool isProcessing = false;

  // Several background requests (patrol/incident sync, home data refresh)
  // can all be in flight on the same now-stale token at once. Without this,
  // each one's code-10 response independently re-triggers the full
  // wipe-and-navigate recovery below in quick succession — visible as a
  // flash back to splash and, under bad timing, landing on the login page
  // even for an already-logged-in user. Once one of them has just run the
  // recovery, the others' code-10s are stale fallout from requests sent
  // before the token was refreshed, not new evidence of a broken session.
  DateTime? _lastRecoveryAt;
  static const _recoveryCooldown = Duration(seconds: 5);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // print("url: " + response.realUri.toString());
    // print("The respoonse :${response.data}");

    if (response.data is Map) {
      try {
        var respCode = (response.data['status']['code'] ?? "-100").toString();
        if (respCode.toString() == "8") {
          CustomDialog.showAppDialog("${MyDialog.navigatorKey.currentContext!.loc.generalErrorMsg} (code:$respCode)");
        }
        if (respCode.toString() == Constants.invalidAuthToken.toString()) {
          final withinCooldown = _lastRecoveryAt != null &&
              DateTime.now().difference(_lastRecoveryAt!) < _recoveryCooldown;
          if (isProcessing == false && !withinCooldown) {
            FlutterNativeSplash.remove();
            isProcessing = true;
            try {
              await authenicateUserAccess();
              _lastRecoveryAt = DateTime.now();
              // Background sync managers can fire their very first request
              // before the app has even built a navigator (e.g. a pending
              // record waiting to sync at cold start) — nothing to
              // redirect yet in that case, but the token refresh above
              // still needs to happen.
              final navContext = CustomDialog.getContext;
              if (navContext != null) {
                final router = GoRouter.of(navContext);
                final String location = router.currLocation;
                if (location == AppRouter.splash) {
                  router.canPopOrGoInitial(AppRouter.home);
                } else {
                  router.canPopOrGoInitial(AppRouter.splash);
                }
              }
            } finally {
              // Always resets, even if authenicateUserAccess() or the
              // navigation above throws — otherwise isProcessing gets
              // stuck true and every future invalid-token response is
              // silently ignored for the rest of the app session.
              isProcessing = false;
            }
            // Falls through to super.onResponse(...) below instead of
            // returning early — the recovery above only refreshes the
            // token and redirects in the background. It must NOT swallow
            // this response: the original caller (postLogout(), any
            // repository call) is still awaiting it, and without
            // forwarding the response that await hangs forever, since
            // nothing else ever completes it. The caller's own
            // response.isSuccess() check already treats this non-1 status
            // code as a failure, so forwarding it is safe.
          }
        }
      } catch (e) {
        CustomDialog.showAppDialog(MyDialog.navigatorKey.currentContext!.loc.generalErrorMsg);
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers["token"] = _secureLocator.token;
    options.headers["key"] = apiKey;
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint("==========ERROR START==========");
    debugPrint(err.toString());
    debugPrint("========== ERROR END ==========");

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        debugPrint('⏱ Connection timeout');
        // sl<FileHelper>().writeLog()
        break;

      case DioExceptionType.sendTimeout:
        debugPrint('📤 Send timeout');

        break;

      case DioExceptionType.receiveTimeout:
        debugPrint('📥 Receive timeout');

        break;

      case DioExceptionType.badResponse:
        debugPrint('❗ Server error: ${err.response?.statusCode}');

        break;

      case DioExceptionType.connectionError:
        debugPrint('🌐 No internet / DNS issue');

        break;

      case DioExceptionType.unknown:
        debugPrint('⚠️ Unknown error: ${err.error}');

        break;

      default:
        debugPrint('Other error');
    }

    handler.next(err);
    // Close crashanalytic
    // super.onError(err, handler);
  }
}

class BadRequestException extends DioException {
  BadRequestException(RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return "Invalid request";
  }
}

class InternalServiceException extends DioException {
  InternalServiceException(RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return "Unknown error occurred, please try again later.";
  }
}

class ConflictException extends DioException {
  ConflictException(RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return "Conflict occurred";
  }
}

class UnauthorizedException extends DioException {
  UnauthorizedException(RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return "Access denied";
  }
}

class NotFoundException extends DioException {
  NotFoundException(RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return "The requested information could not be found";
  }
}

class NoInternetConnectionException extends DioException {
  NoInternetConnectionException(RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return "No internet connection detected, please try again.";
  }
}

class DeadlineExceededException extends DioException {
  DeadlineExceededException(RequestOptions r) : super(requestOptions: r);

  @override
  String toString() {
    return "The connection has timed out, please try again.";
  }
}
