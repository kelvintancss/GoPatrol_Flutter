import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/core/widgets/widgets.dart';
import 'package:patrol/core/repository/base_repository.dart';
import 'package:patrol/core/utils/incident_log_model.dart';
import 'package:patrol/core/utils/patrol_calendar_model.dart';
import 'package:patrol/core/utils/patrol_form_photo.dart';
import 'package:patrol/core/utils/patrol_log_model.dart';
import 'package:patrol/core/utils/visitor_log_model.dart';
import 'package:patrol/features/auth/view/login_page.dart';
import 'package:patrol/features/general/view/splash_page.dart';
import 'package:patrol/features/home/view/home_page.dart';
import 'package:patrol/features/facility_log/view/facility_log_page.dart';
import 'package:patrol/features/incident/view/add_incident_page.dart';
import 'package:patrol/features/incident/view/incident_log_detail_page.dart';
import 'package:patrol/features/incident/view/incident_page.dart';
import 'package:patrol/features/incident/view/incident_record_list_page.dart';
import 'package:patrol/features/patrol_log/view/patrol_log_detail_page.dart';
import 'package:patrol/features/patrol_log/view/patrol_log_page.dart';
import 'package:patrol/features/patrol/view/patrol_digital_form_page.dart';
import 'package:patrol/features/patrol/view/patrol_page.dart';
import 'package:patrol/features/patrol/view/patrol_record_detail_page.dart';
import 'package:patrol/features/patrol/view/patrol_record_list_page.dart';
import 'package:patrol/features/property/view/property_page.dart';
import 'package:patrol/features/property/view/search_property_page.dart';
import 'package:patrol/features/property/view/scan_qr_page.dart';
import 'package:patrol/features/visitor_log/view/visitor_log_detail_page.dart';
import 'package:patrol/features/visitor_log/view/visitor_log_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Lets a page (e.g. [RouteAware]) know when a route pushed on top of it
/// has been popped, so it can refresh its data on return.
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

abstract class AppRouter {
  static const String splash = '/splash';
  static const String property = '/property';
  static const String searchProperty = '/searchProperty';
  static const String scanQr = '/scanQr';
  static const String login = '/login';
  static const String home = '/home';
  static const String patrol = '/patrol';
  static const String patrolDigitalForm = '/patrolDigitalForm';
  static const String patrolRecordList = '/patrolRecordList';
  static const String patrolRecordDetail = '/patrolRecordDetail';
  static const String incident = '/incident';
  static const String addIncident = '/addIncident';
  static const String incidentRecordList = '/incidentRecordList';
  static const String incidentLogDetail = '/incidentLogDetail';
  static const String facilityLog = '/facilityLog';
  static const String patrolLog = '/patrolLog';
  static const String patrolLogDetail = '/patrolLogDetail';
  static const String visitorLog = '/visitorLog';
  static const String visitorLogDetail = '/visitorLogDetail';

  static const splashName = 'splash';
  static const propertyName = 'property';
  static const searchPropertyName = 'searchProperty';
  static const scanQrName = 'scanQr';
  static const loginName = 'login';
  static const homeName = 'home';
  static const patrolName = 'patrol';
  static const patrolDigitalFormName = 'patrolDigitalForm';
  static const patrolRecordListName = 'patrolRecordList';
  static const patrolRecordDetailName = 'patrolRecordDetail';
  static const incidentName = 'incident';
  static const addIncidentName = 'addIncident';
  static const incidentRecordListName = 'incidentRecordList';
  static const incidentLogDetailName = 'incidentLogDetail';
  static const facilityLogName = 'facilityLog';
  static const patrolLogName = 'patrolLog';
  static const patrolLogDetailName = 'patrolLogDetail';
  static const visitorLogName = 'visitorLog';
  static const visitorLogDetailName = 'visitorLogDetail';
}

final _router = GoRouter(
  initialLocation: AppRouter.splash,
  navigatorKey: rootNavigatorKey,
  observers: [routeObserver],
  routes: [
    GoRoute(
      name: AppRouter.splashName,
      path: AppRouter.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      name: AppRouter.propertyName,
      path: AppRouter.property,
      builder: (context, state) => const PropertyPage(),
    ),
    GoRoute(
      name: AppRouter.scanQrName,
      path: AppRouter.scanQr,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ScanQrPage(showGalleryButton: extra?['showGalleryButton'] ?? true);
      },
    ),
    GoRoute(
      name: AppRouter.loginName,
      path: AppRouter.login,
      builder: (context, state) {
        final queryParam = state.uri.queryParameters;
        return LoginPage(
          projectId: queryParam['projectId'] ?? '',
          projectName: queryParam['projectName'] ?? '',
        );
      },
    ),
    GoRoute(
      name: AppRouter.searchPropertyName,
      path: AppRouter.searchProperty,
      builder: (context, state) {
        var extra = state.extra as Jmap?;
        var isOpenScan = extra?['isOpenScan'] ?? false;
        return SearchPropertyPage(isOpenScan: isOpenScan);
      },
    ),
    GoRoute(
      name: AppRouter.homeName,
      path: AppRouter.home,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      name: AppRouter.patrolName,
      path: AppRouter.patrol,
      builder: (context, state) => const PatrolPage(),
    ),
    GoRoute(
      name: AppRouter.patrolDigitalFormName,
      path: AppRouter.patrolDigitalForm,
      builder: (context, state) {
        final extra = state.extra as Jmap;
        return PatrolDigitalFormPage(
          checkpoint: extra['checkpoint'] as PatrolShiftRouteItem,
          form: extra['form'] as PatrolDigitalForm,
          initialAnswers:
              extra['initialAnswers'] as List<Map<String, dynamic>>?,
          initialPhotos:
              extra['initialPhotos'] as List<PatrolFormPhoto>? ?? const [],
        );
      },
    ),
    GoRoute(
      name: AppRouter.patrolRecordListName,
      path: AppRouter.patrolRecordList,
      builder: (context, state) => const PatrolRecordListPage(),
    ),
    GoRoute(
      name: AppRouter.patrolRecordDetailName,
      path: AppRouter.patrolRecordDetail,
      builder: (context, state) {
        final extra = state.extra as Jmap?;
        return PatrolRecordDetailPage(uuid: extra?['uuid'] as String? ?? '');
      },
    ),
    GoRoute(
      name: AppRouter.incidentName,
      path: AppRouter.incident,
      builder: (context, state) => const IncidentPage(),
    ),
    GoRoute(
      name: AppRouter.addIncidentName,
      path: AppRouter.addIncident,
      builder: (context, state) {
        final extra = state.extra as Jmap?;
        return AddIncidentPage(uuid: extra?['uuid'] as String?);
      },
    ),
    GoRoute(
      name: AppRouter.incidentRecordListName,
      path: AppRouter.incidentRecordList,
      builder: (context, state) => const IncidentRecordListPage(),
    ),
    GoRoute(
      name: AppRouter.incidentLogDetailName,
      path: AppRouter.incidentLogDetail,
      builder: (context, state) =>
          IncidentLogDetailPage(entry: state.extra as IncidentLogEntry),
    ),
    GoRoute(
      name: AppRouter.facilityLogName,
      path: AppRouter.facilityLog,
      builder: (context, state) => const FacilityLogPage(),
    ),
    GoRoute(
      name: AppRouter.patrolLogName,
      path: AppRouter.patrolLog,
      builder: (context, state) => const PatrolLogPage(),
    ),
    GoRoute(
      name: AppRouter.patrolLogDetailName,
      path: AppRouter.patrolLogDetail,
      builder: (context, state) {
        final extra = state.extra as Jmap;
        return PatrolLogDetailPage(entry: extra['entry'] as PatrolLogEntry);
      },
    ),
    GoRoute(
      name: AppRouter.visitorLogName,
      path: AppRouter.visitorLog,
      builder: (context, state) => const VisitorLogPage(),
    ),
    GoRoute(
      name: AppRouter.visitorLogDetailName,
      path: AppRouter.visitorLogDetail,
      builder: (context, state) =>
          VisitorLogDetailPage(entry: state.extra as VisitorLogEntry),
    ),
  ],
  errorBuilder: (context, state) => const ErrorRouteWidget(),
);

final appRouter = _router;
