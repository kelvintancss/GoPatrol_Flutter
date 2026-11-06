import 'dart:io' show Platform;

import 'package:auth_service/auth_service.dart' show AuthService;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio_client/dio_client.dart' show DioClient;
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/material.dart';

import 'package:general_service/general_service.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/utils/image_helper.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/general/view/connection_checker_screen.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:patrol_service/patrol_service.dart';
import 'package:property_service/property_service.dart';
import 'package:get_it/get_it.dart';
import 'package:patrol/core/network/dio_interceptor.dart';
import 'package:patrol/core/repository/repository.dart';
import 'package:patrol/core/services/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

final sl = GetIt.instance;

/// inject/setup
Future<void> startup(String baseUrl) async {
  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();

  // Base
  sl.registerSingleton<SecureStorage>(SecureStorage());
  // Must happen before anything below can fire a network request (the sync
  // managers' first pass runs immediately on .start(), further down this
  // same function) — otherwise authToken/userToken read as empty in
  // memory even though a valid session is sitting in secure storage,
  // which the backend then rejects as an invalid token and silently
  // resets the logged-in session for no real reason.
  await sl<SecureStorage>().init();
  sl.registerLazySingleton<UserPreferences>(
    () => UserPreferences(prefs: prefs),
  );
  sl.registerSingleton<FirebaseHelper>(FirebaseHelper());
  if (Platform.isIOS) {
    sl.registerSingleton<IosDeviceInfo>(await DeviceInfoPlugin().iosInfo);
  } else {
    sl.registerSingleton<AndroidDeviceInfo>(
      await DeviceInfoPlugin().androidInfo,
    );
  }

  await AppLogger.instance.init(); // then load logs
  await PatrolCheckpointStorage.instance.init();
  await PatrolRecordDatabase.instance.init();
  await PatrolHomeDataDatabase.instance.init();
  await IncidentRecordDatabase.instance.init();
  await PatrolShiftDatabase.instance.init();

  sl.registerSingleton<PackageInfo>(packageInfo);

  // Network
  sl.registerSingleton<DioClient>(
    DioClient(baseUrl: baseUrl, interceptors: [DioInterceptor()]),
  );

  /// dio retry entry for internet connection issues
  sl<DioClient>().addInterceptor(
    RetryInterceptor(
      dio: sl<DioClient>().dioObject,
      logPrint: (s) {},
      retries: 4,
      retryDelays: List.generate(4, (i) => Duration.zero),
      retryEvaluator: (error, attempt) async {
        if (error.message?.startsWith("The connection errored") == true &&
            !error.requestOptions.uri.path.endsWith("/homeinfo")) {
          await AppLogger.instance.log(
            "Network disconnected - Manual network check triggered (Attempt: $attempt)",
          );

          final BuildContext? context = CustomDialog.getContext;
          if (context == null || !context.mounted) return false;

          if (context.loaderOverlay.visible) {
            context.loaderOverlay.hide();
          }

          if (attempt < 4) {
            final delay = const [
              Duration(seconds: 10),
              Duration(seconds: 15),
              Duration(seconds: 20),
              Duration(seconds: 25),
            ][attempt - 1];

            final dialogResult = await showDialog<String>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const AlertDialog(
                title: Text("Connection Lost"),
                content: Text("Retrying..."),
              ),
            );
            if (!context.mounted) return false;
            return dialogResult == 'retry';
          }

          while (true) {
            if (!context.mounted) return false;

            final checkResult =
                await Navigator.of(context, rootNavigator: true).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const ConnectionCheckerScreen(),
                    fullscreenDialog: true,
                  ),
                );
            if (!context.mounted) return false;

            if (checkResult == true) {
              return true;
            }
            return false;
          }
        }
        return false;
      },
    ),
  );

  sl.registerSingleton<NetworkHelper>(
    NetworkHelper(),
    dispose: (param) {
      param.dispose();
    },
  );
  sl.registerSingleton<AuthService>(AuthService(dioClient: sl()));
  sl.registerSingleton<GeneralService>(GeneralService(dioClient: sl()));
  sl.registerSingleton<PropertyService>(PropertyService(dioClient: sl()));
  sl.registerSingleton<PatrolService>(PatrolService(dioClient: sl()));

  sl.registerSingleton<ImagePicker>(ImagePicker());
  sl.registerSingleton<ImageHelper>(ImageHelper(sl()));

  sl.registerSingleton<AuthRepository>(AuthRepository(authService: sl()));
  sl.registerSingleton<GeneralRepository>(
    GeneralRepository(generalService: sl()),
  );
  sl.registerSingleton<PropertyRepository>(
    PropertyRepository(propertyService: sl()),
  );
  sl.registerSingleton<PatrolRepository>(
    PatrolRepository(patrolService: sl()),
  );

  sl.registerSingleton<PatrolSyncManager>(
    PatrolSyncManager(),
    dispose: (param) => param.dispose(),
  );
  sl<PatrolSyncManager>().start();

  sl.registerSingleton<IncidentSyncManager>(
    IncidentSyncManager(),
    dispose: (param) => param.dispose(),
  );
  sl<IncidentSyncManager>().start();

  // Not started here — the home page kicks this off on its first entry
  // (see HomePage.initState), not at app boot.
  sl.registerSingleton<PatrolHomeDataManager>(
    PatrolHomeDataManager(),
    dispose: (param) => param.dispose(),
  );
}
