import 'package:patrol/flavors.dart';

class Constants {
  Constants._();
  static const String appName = 'Patrol';
  // Url
  static const String stagingApiBaseUrl =
      'https://cssadmin.custsolution.com/app/patrol/'; //'https://cssadmin.custsolution.com/app/vms/';
  static const String demoApiBaseUrl =
      'https://cssdemo.custsolution.com/app/patrol/';
  static const String productionApiBaseUrl =
      'https://cloud.cssdecisions.com/app/patrol/';

  static String get apiBaseUrl {
    switch (F.appFlavor) {
      case Flavor.staging:
        return stagingApiBaseUrl;
      case Flavor.demo:
        return demoApiBaseUrl;
      case Flavor.production:
        return productionApiBaseUrl;
    }
  }

  static const String privacyPolicyUrl =
      "https://www.cssdecisions.com/CSSEC/CSSFiles/CSS_PRIVACY_POLICY.pdf";
  static const String termsAndConditionUrl =
      "https://www.cssdecisions.com/CSSEC/CSSFiles/CSS_TERMS_AND_CONDITIONS.pdf";

  /// Common / Code
  static const languageCodeEn = "en";
  static const languageCodeZh = "zh";
  static const languageCodeMy = "my";
  static const apiSuccess = 1;
  static const apiFail = -1;
  static const int invalidAuthToken = 10;
  static const int linkPropertyRequest = 58;
  static const myMobileMinLength = 8;

  /// Spacing
  static const double appPaddingExtra = 18.0;
  static const double appPadding = 12.0;
  static const double appPaddingMedium = 14;
  static const double buttonRadius = 8.0;
  static const double bottomSpacing = 34;
  static const double formSpacing = 15;

  // Size
  static const double navIconsMain = 24.0;

  // Border side
  static const double borderRadiusNormal = 13;
  static const double borderRadiusSmall = 8;
  static const double borderRadiusLarge = 20;

  /// register
  static const String visitorWalkInVisitorCode = 'VPWALKINVISITOR';
  static const String visitorPickUpDropOffVisitorCode = 'VPPUDO';
  static const String visitorRegularVisitVisitorCode = 'VPWALKINSERVICE';
  static const String visitorContactUnit = 'Contact-Unit';
  static const String visitorContactUnitSkipable = 'Contact-Unit-Skipable';
  static const String visitorOnSiteRegistration = 'On-Site-Registration';
  static const String visitorOvernightLimitDay = 'Overnight-Limit-Day';
  static const String visitorFloorDelivery = 'Floor-Delivery';
  static const String visitorMultiLevelSelection = 'Multi-Level-Selection';
  static const String visitorRecurringPassSelection =
      'Recurring-Pass-Selection';
  static const String visitorOCR = 'OCR';
  static const String visitorTakeImage = 'Take-Image';
  static const String visitorVisitorCarPark = 'Visitor-Car-Park';
  static const String visitorPassRequired = 'Pass-Required';
  static const String visitorTypeRegularVisitor = 'Regular Visitors';
  static const String visitorTypeRegularTransport = 'Regular Transport';
  static const String visitorSupportDualPass = 'Support-Dual-Pass';

  static const String vmsAppointmentPendingStatus = 'PD';
  static const String vmsAppointmentPendingApproveStatus = 'PA';
  static const String vmsAppointmentRejectedApproveStatus = 'RJ';
  static const String vmsAppointmentCancelledStatus = 'CL';
  static const String vmsAppointmentCheckedInStatus = 'AC';
  static const String vmsAppointmentCheckedOutStatus = 'CO';
  static const String vmsAppointmentUpcomingtStatus = 'UA';
}

enum VmsLogType { facilitylog, checkinlog, checkoutlog, soslog, sosgoguardlog }

enum DayRange {
  today("today"),
  yesterday("yesterday"),
  day7("7days"),
  day30("30days"),
  day60("60days"),
  day90("90days");

  const DayRange(this.value);
  final String value;

  static DayRange getByValue(int i) {
    return DayRange.values.firstWhere((x) => x.value == i);
  }
}
