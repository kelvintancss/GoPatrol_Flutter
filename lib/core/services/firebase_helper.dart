import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/core/services/secure_storage.dart';
import 'package:patrol/core/widgets/custom_dialog.dart';
import 'package:patrol/service_locator.dart';
import 'package:permission_handler/permission_handler.dart';

class FirebaseHelper {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  late NotificationSettings _settings;

  // extra foreground notification setup
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications',
    description: "This channel is used for important notifications.", // title description
    importance: Importance.max,
  );

  static FirebaseHelper? _instance;
  FirebaseHelper._() {
    debugPrint("Firebase init");
  }

  factory FirebaseHelper() => _instance ??= FirebaseHelper._();

  void runFirebaseService() {
    createNewChannel();
    initialMessage();
    _firebaseMessagingBackgroundOnTap();
    _firebaseMessagingForegroundHandler();
  }

  Future<void> initialMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage == null) return;
    print("Initial notification tapped: ${initialMessage.data}");
    print("Initial notification tapped: ${initialMessage.notification?.toMap()}");
    _handlePushLink(initialMessage.data);
  }

  Future createNewChannel() async {
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      channel,
    );

    /// when cold start
    final RemoteMessage? _message = await messaging.getInitialMessage();
    if (_message != null) {}
    debugPrint("hello message $_message");
  }

  Future requestPermission() async {
    debugPrint("requesting...");
    await generalRequestPermission();
    try {
      _settings = await messaging.requestPermission();
      messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      if (Platform.isIOS) {
        String? apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) {
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null) {}
        }
      } else {}
      debugPrint("topic subscribe all");
      if (await sl<SecureStorage>().isAuthTokenEmpty()) {}
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      String? token;
      if (Platform.isIOS) {
        var isApn = await messaging.getAPNSToken();
        if (isApn != null) {
          token = await messaging.getToken();
        } else {
          await Future.delayed(const Duration(seconds: 2));
          await messaging.getAPNSToken();
          token = await messaging.getToken();
        }
      } else {
        token = await messaging.getToken();
      }
      debugPrint("Firebase token: $token");
      return token;
    } catch (e) {
      debugPrint("token fail ${e.toString()}");
      return null;
    }
  }

  _firebaseMessagingForegroundHandler() async {
    try {
      const InitializationSettings initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings("@mipmap/ic_launcher"),
        iOS: DarwinInitializationSettings(),
      );
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle tap here
          print("Notication on click...");
          if (response.payload != null) {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _handlePushLink(data);
          }
        },
      );
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        // If `onMessage` is triggered with a notification, construct our own
        // local notification to show to users using the created channel.
        print("Notication received ${message.data}");
        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            payload: jsonEncode(message.data),
            NotificationDetails(
              android: AndroidNotificationDetails(channel.id, channel.name, icon: android.smallIcon, channelDescription: channel.description),
            ),
          );
          return;
        }
        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.data}');
        }
      });
    } catch (_) {}
  }

  _firebaseMessagingBackgroundOnTap() async {
    // When app is in background and user taps the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Background notification tapped: ${message.data}");
      print("Background notification tapped: ${message.notification?.toMap()}");
      _handlePushLink(message.data);
    });
  }

  bool get isMessageAllow => _settings.authorizationStatus == AuthorizationStatus.authorized;

  Future<bool> getManuallyRequestMessage() async {
    _settings = await messaging.requestPermission();
    return isMessageAllow;
  }

  Future<void> deleteNotifToken() async {
    try {
      await messaging.deleteToken();
    } catch (e) {
      debugPrint("Remove token faild ${e.toString()}");
    }
  }

  Future<void> generalRequestPermission() async {
    await Permission.notification.request();
  }

  _handlePushLink(Map<String, dynamic> data) {
    var action = data['page_route'];
    var param1 = data['param1']; // param1 always property id
    var param2 = data['param2'];
    var param3 = data['param3'];
    var param4 = data['param4'];
    var param5 = data['param5'];
    if (action != null && CustomDialog.getContext != null) {
      CustomDialog.getContext?.go(AppRouter.home);
    }
  }
}
