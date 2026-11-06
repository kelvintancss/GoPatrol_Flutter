import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/app/app_router.dart';
import 'package:patrol/app/app_theme.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/features/auth/cubit/auth_cubit.dart';
import 'package:patrol/core/services/user_preference.dart';
import 'package:patrol/features/home/widgets/home_date_time_widget.dart';
import 'package:patrol/gen/assets.gen.dart';
import 'package:patrol/service_locator.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _backPressExitWindow = Duration(seconds: 2);

  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    sl<PatrolHomeDataManager>().start();
  }

  void _onBackPressed() {
    final now = DateTime.now();
    final last = _lastBackPressTime;
    if (last != null && now.difference(last) <= _backPressExitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPressTime = now;
    CustomDialog.showAppToast('Press back again to minimize the app.');
  }

  void _showMenu(BuildContext context) {
    showBtmSheet(
      context,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(Constants.appPaddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LanguageDropdown(),
            Divider(height: 30.h),
            GestureDetector(
              onTap: () {
                context.pop();
                context.push(AppRouter.patrolRecordList);
              },
              child: 'Patrol (Local Data)'.bodyText(),
            ),
            Divider(height: 30.h),
            GestureDetector(
              onTap: () {
                context.pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) _confirmLogout(context);
                });
              },
              child: 'Logout'.bodyText(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    await CustomDialog.showDialogWithOption(
      context,
      title: 'Logout',
      desc: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      confirmCallback: () async {
        if (context.mounted) {
          context.read<AuthCubit>().logout(
            navBackHome: () => context.go(AppRouter.splash),
          );
        }
        return true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              10.pw,
              'CSS Patrol'.titleWithoutBoldText(color: Colors.white),
            ],
          ),
          isMainPage: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _showMenu(context),
          ),
          flexiSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColor.deepGreen, AppColor.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: ValueListenableBuilder<PatrolHomeData?>(
            valueListenable: sl<PatrolHomeDataManager>().homeData,
            builder: (context, homeData, _) {
              final projectName = homeData?.projectName.isNotEmpty ?? false
                  ? homeData!.projectName
                  : (sl<UserPreferences>().getUserProjectName ?? '');
              final vmsActive = homeData?.vmsActive ?? false;

              return _HomeBody(projectName: projectName, vmsActive: vmsActive);
            },
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.projectName, required this.vmsActive});

  final String projectName;
  final bool vmsActive;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(15.0),
      children: [
        10.ph,
        // ── Project Info Card ──
        Card(
          elevation: 2,
          child: Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
            ),
            child: Row(
              spacing: 10.w,
              children: [
                IconWidget(
                  imgPath: Assets.images.myPropertyEmtListIcon.path,
                  height: 30.h,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    projectName.titleWithoutBoldText(fontSize: 18.sp),
                  ],
                ),
              ],
            ),
          ),
        ),
        15.ph,
        // ── Date/Time Card ──
        Card(
          elevation: 2,
          child: Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
              color: AppColor.white,
            ),
            child: const HomeDateTimeWidget(),
          ),
        ),
        20.ph,
        // ── Start Patrol Button ──
        GestureDetector(
          // Patrol start time/active flag are set on the patrol page once a
          // shift is picked.
          onTap: () => context.push(AppRouter.patrol),
          child: Container(
            width: double.infinity,
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(Constants.borderRadiusLarge),
            ),
            child: Center(
              child: 'Start Patrol'.titleBoldText(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
        20.ph,
        // ── Row 1: Incident/Visitor Log ──
        ResponsiveGridList(
          listViewBuilderOptions: ListViewBuilderOptions(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          horizontalGridSpacing: 2.w,
          verticalGridSpacing: 16,
          horizontalGridMargin: 0,
          verticalGridMargin: 5,
          minItemWidth: 300,
          minItemsPerRow: 2,
          maxItemsPerRow: 2,
          children: [
            GestureDetector(
              onTap: () => context.push(AppRouter.incident),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  border: const Border.fromBorderSide(
                    BorderSide(color: Color.fromARGB(248, 114, 172, 69)),
                  ),
                  color: const Color.fromARGB(248, 240, 255, 228),
                  borderRadius: BorderRadius.circular(
                    Constants.borderRadiusLarge,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconWidget(
                      imgPath: Assets.images.incident.path,
                      height: 50,
                    ),
                    20.ph,
                    context.loc.incident.titleBoldText(
                      color: AppColor.deepGreen,
                    ),
                  ],
                ),
              ),
            ),
            if (vmsActive)
              GestureDetector(
                onTap: () => context.push(AppRouter.visitorLog),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    border: const Border.fromBorderSide(
                      BorderSide(color: AppColor.lushGreen),
                    ),
                    color: const Color.fromARGB(
                      255,
                      175,
                      247,
                      194,
                    ).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                      Constants.borderRadiusLarge,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconWidget(
                        imgPath: Assets.images.incident.path,
                        height: 50,
                      ),
                      20.ph,
                      context.loc.visitorLog.titleBoldText(
                        color: const Color.fromARGB(248, 114, 172, 69),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        10.ph,
        // ── Row 2: Patrol Log/Facility Log ──
        ResponsiveGridList(
          listViewBuilderOptions: ListViewBuilderOptions(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          horizontalGridSpacing: 2.w,
          verticalGridSpacing: 16,
          horizontalGridMargin: 0,
          verticalGridMargin: 5,
          minItemWidth: 300,
          minItemsPerRow: 2,
          maxItemsPerRow: 2,
          children: [
            GestureDetector(
              onTap: () => context.push(AppRouter.patrolLog),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppColor.lushGreen),
                  ),
                  color: const Color.fromARGB(
                    255,
                    175,
                    247,
                    194,
                  ).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(
                    Constants.borderRadiusLarge,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconWidget(
                      imgPath: Assets.images.incident.path,
                      height: 50,
                    ),
                    20.ph,
                    context.loc.patrolLog.titleBoldText(
                      color: AppColor.deepGreen,
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(AppRouter.facilityLog),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  border: const Border.fromBorderSide(
                    BorderSide(color: Color.fromARGB(248, 114, 172, 69)),
                  ),
                  color: const Color.fromARGB(248, 240, 255, 228),
                  borderRadius: BorderRadius.circular(
                    Constants.borderRadiusLarge,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconWidget(
                      imgPath: Assets.images.incident.path,
                      height: 50,
                    ),
                    20.ph,
                    context.loc.facilityLog.titleBoldText(
                      color: const Color.fromARGB(248, 114, 172, 69),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        20.ph,
      ],
    );
  }
}
