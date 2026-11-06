import 'dart:async';

import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/core/services/firebase_helper.dart';
import 'package:patrol/core/services/secure_storage.dart';
import 'package:patrol/core/services/user_preference.dart';
import 'package:patrol/core/utils/app_extension.dart';
import 'package:patrol/features/general/cubit/general_cubit.dart';
import 'package:patrol/gen/assets.gen.dart';
import 'package:patrol/service_locator.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    initSplash();
  }

  Future<void> initSplash() async {
    final projectId = sl<UserPreferences>().getUserProjectId;
    final isUserLoggedIn = sl<UserPreferences>().isUserLoggedIn();

    // Already logged in with a bound property — this is purely a local-state
    // decision, so go straight in without waiting on any network call
    // (temp/auth token refresh, app version check). Those calls can stall
    // for a long time when offline, which would otherwise strand an
    // already-logged-in user on the splash screen for no reason.
    if (projectId != null && projectId.isNotEmpty && isUserLoggedIn) {
      unawaited(sl<SecureStorage>().clearIfFirstUserUninstall());
      unawaited(sl<FirebaseHelper>().requestPermission());

      final isPatrolActive = sl<UserPreferences>().isPatrolActive();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(isPatrolActive ? AppRouter.patrol : AppRouter.home);
        }
      });
      return;
    }

    /// App initialize data...
    try {
      final generalCubit = context.read<GeneralCubit>();

      await sl<SecureStorage>().clearIfFirstUserUninstall();
      await sl<FirebaseHelper>().requestPermission();
      if (await sl<SecureStorage>().isAuthTokenEmpty()) {
        await generalCubit.getTempToken();
        await generalCubit.fetchAuthToken();
      }
      await generalCubit.fetchAppVersion();
    } catch (e) {
      debugPrint("Error app initialization: $e");
    }

    /// Check if guest or logined user redirect to target page
    if (projectId == null || projectId.isEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(AppRouter.property);
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go(AppRouter.login);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.hardEdge,
                child: Image.asset(Assets.images.appIcon.path, fit: BoxFit.contain),
              ).animate().shimmer(duration: 500.ms).slide(delay: 300.ms),
            ),
            20.ph,
            Flexible(
              child: DelayedDisplay(delay: const Duration(milliseconds: 500), child: "CSS Patrol".titleBoldText()),
            ),
          ],
        ),
      ),
    );
  }
}
