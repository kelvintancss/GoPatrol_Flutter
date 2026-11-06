import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app.dart' show PatrolApp;
import 'package:patrol/core/utils/constants.dart';
import 'package:patrol/flavors.dart';
import 'package:patrol/service_locator.dart';

void main() async {
  F.appFlavor = Flavor.production;
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD4iCAgQE_dtdMEGxzWZOMJKzpyR5xpjlI",
      appId: "1:119470567625:android:7f7892ce9cdbdbb5b79d18",
      messagingSenderId: "119470567625",
      projectId: "vmsnew-a3c5b",
    ),
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  await startup(Constants.productionApiBaseUrl);
  runApp(const PatrolApp());
}
