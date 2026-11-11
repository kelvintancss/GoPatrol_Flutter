import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app.dart' show PatrolApp;
import 'package:patrol/core/utils/constants.dart';
import 'package:patrol/flavors.dart';
import 'package:patrol/service_locator.dart';

void main() async {
  F.appFlavor = Flavor.demo;
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  // Config comes from the flavor's google-services.json (Android) /
  // GoogleService-Info.plist (iOS) — Firebase project `css-patrol`.
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  await startup(Constants.demoApiBaseUrl);
  runApp(const PatrolApp());
}
