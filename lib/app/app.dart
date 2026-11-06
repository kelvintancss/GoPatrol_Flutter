import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/services/firebase_helper.dart';
import 'package:patrol/core/utils/locale_controller.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/app_loading_widget.dart';
import 'package:patrol/features/auth/cubit/auth_cubit.dart';
import 'package:patrol/features/general/cubit/general_cubit.dart';
import 'package:patrol/features/property/cubit/property_cubit.dart';
import 'package:patrol/l10n/app_localizations.dart';
import 'package:patrol/service_locator.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

class PatrolApp extends StatelessWidget {
  const PatrolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GeneralCubit()),
        BlocProvider(create: (context) => PropertyCubit()),
        BlocProvider<AuthCubit>(create: (context) => AuthCubit()),
      ],
      child: const _PatrolView(),
    );
  }
}

class _PatrolView extends StatefulWidget {
  const _PatrolView();

  @override
  State<_PatrolView> createState() => _PatrolViewState();
}

class _PatrolViewState extends State<_PatrolView> {
  Future<void> initApp() async {
    sl<FirebaseHelper>().runFirebaseService();
  }

  @override
  void initState() {
    initApp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812), minTextAdapt: true);
    return GlobalLoaderOverlay(
      overlayColor: Colors.black.withValues(alpha: 0.2),
      overlayWidgetBuilder: (_) => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [AppLoadingWidget()]),
      ),
      child: ValueListenableBuilder<Locale>(
        valueListenable: LocaleController.notifier,
        builder: (context, locale, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: AppLocalizations.of(context)?.appName ?? "",
            theme: buildTheme().copyWith(extensions: const [ShirneDialogTheme()]),
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            routerConfig: appRouter,
            localizationsDelegates: const [
              ShirneDialogLocalizations.delegate,
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              MyDialog.navigatorKey = rootNavigatorKey;
              return child!;
            },
          );
        },
      ),
    );
  }
}
