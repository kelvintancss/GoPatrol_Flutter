import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'GoGuard'**
  String get appName;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started'**
  String get getStarted;

  /// No description provided for @skipLabel.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipLabel;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @welcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get welcomeLabel;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequiredTitle;

  /// No description provided for @permissionPermanentlyDeniedDscp.
  ///
  /// In en, this message translates to:
  /// **'Permission is permanently denied. Please enable it in settings.'**
  String get permissionPermanentlyDeniedDscp;

  /// No description provided for @permissionRequiredDscp.
  ///
  /// In en, this message translates to:
  /// **'Permission is required to continue. Please enable it in settings.'**
  String get permissionRequiredDscp;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR Code'**
  String get invalidQrCode;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactTitle;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsTitle;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @checkPoint.
  ///
  /// In en, this message translates to:
  /// **'Check Point'**
  String get checkPoint;

  /// No description provided for @patrol.
  ///
  /// In en, this message translates to:
  /// **'Patrol'**
  String get patrol;

  /// No description provided for @visitorLog.
  ///
  /// In en, this message translates to:
  /// **'Visitor Log'**
  String get visitorLog;

  /// No description provided for @incident.
  ///
  /// In en, this message translates to:
  /// **'Incident'**
  String get incident;

  /// No description provided for @patrolLog.
  ///
  /// In en, this message translates to:
  /// **'Patrol Log'**
  String get patrolLog;

  /// No description provided for @facilityLog.
  ///
  /// In en, this message translates to:
  /// **'Facility Log'**
  String get facilityLog;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @generalErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get generalErrorMsg;

  /// No description provided for @uploadImageErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. (Upload Image)'**
  String get uploadImageErrorMsg;

  /// No description provided for @okLabel.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// No description provided for @selectLabel.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @clearAllLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllLabel;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @chooseAnOption.
  ///
  /// In en, this message translates to:
  /// **'Choose An Option'**
  String get chooseAnOption;

  /// No description provided for @openCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get openCamera;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select From Gallery'**
  String get selectFromGallery;

  /// No description provided for @uploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload files'**
  String get uploadFiles;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get uploadImage;

  /// No description provided for @accountSignedInByOther.
  ///
  /// In en, this message translates to:
  /// **'We\'ve logged you out as your account is being used on another device. Not you? Change password and log in again.'**
  String get accountSignedInByOther;

  /// No description provided for @typeHere.
  ///
  /// In en, this message translates to:
  /// **'Type here...'**
  String get typeHere;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @scanAgainLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgainLabel;

  /// No description provided for @requestTimeoutDscp.
  ///
  /// In en, this message translates to:
  /// **'The request is taking too long. Please check your internet connection and try again.'**
  String get requestTimeoutDscp;

  /// No description provided for @connectionTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection Timeout'**
  String get connectionTimeoutLabel;

  /// No description provided for @checkConnectionDscp.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get checkConnectionDscp;

  /// No description provided for @connectionLossLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection Lost'**
  String get connectionLossLabel;

  /// No description provided for @checkConnectionDscp2.
  ///
  /// In en, this message translates to:
  /// **'Please check your Wi-Fi or mobile data.\nThe app will resume automatically when connection is restored.'**
  String get checkConnectionDscp2;

  /// No description provided for @connectionRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get connectionRetryLabel;

  /// No description provided for @checkingLabel.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checkingLabel;

  /// No description provided for @myPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Property'**
  String get myPropertyTitle;

  /// No description provided for @linkPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Property'**
  String get linkPropertyTitle;

  /// No description provided for @propertyLinkNow.
  ///
  /// In en, this message translates to:
  /// **'Link your property now'**
  String get propertyLinkNow;

  /// No description provided for @propertyLinkEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask your management officer for a property code or QR code to link one now.'**
  String get propertyLinkEmptyDesc;

  /// No description provided for @linkNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Link Now'**
  String get linkNowLabel;

  /// No description provided for @scanPropertyCode.
  ///
  /// In en, this message translates to:
  /// **'Scan Property QR Code'**
  String get scanPropertyCode;

  /// No description provided for @searchByPropertyCode.
  ///
  /// In en, this message translates to:
  /// **'Search By Property Code'**
  String get searchByPropertyCode;

  /// No description provided for @scanFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Scan from Gallery'**
  String get scanFromGallery;

  /// No description provided for @noPropertyFound.
  ///
  /// In en, this message translates to:
  /// **'No Projects found'**
  String get noPropertyFound;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @propertyName.
  ///
  /// In en, this message translates to:
  /// **'Property name'**
  String get propertyName;

  /// No description provided for @usernameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be empty.'**
  String get usernameEmpty;

  /// No description provided for @passwordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty.'**
  String get passwordEmpty;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginFailed;

  /// No description provided for @loginAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your account.'**
  String get loginAccount;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcomeTo;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @passwords.
  ///
  /// In en, this message translates to:
  /// **'Passwords'**
  String get passwords;

  /// No description provided for @entrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance'**
  String get entrance;

  /// No description provided for @entranceHint.
  ///
  /// In en, this message translates to:
  /// **'Select an entrance (optional)'**
  String get entranceHint;

  /// No description provided for @forgetPassword.
  ///
  /// In en, this message translates to:
  /// **'Forget password?'**
  String get forgetPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// No description provided for @adminVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Verification'**
  String get adminVerificationTitle;

  /// No description provided for @adminVerificationDscp.
  ///
  /// In en, this message translates to:
  /// **'Enter you admin password to continue'**
  String get adminVerificationDscp;

  /// No description provided for @adminVerifySuccess.
  ///
  /// In en, this message translates to:
  /// **'Admin verification successful!'**
  String get adminVerifySuccess;

  /// No description provided for @adminVerifyFail.
  ///
  /// In en, this message translates to:
  /// **'Admin verification failed!'**
  String get adminVerifyFail;

  /// No description provided for @adminVerifyError.
  ///
  /// In en, this message translates to:
  /// **'Error verifying admin'**
  String get adminVerifyError;

  /// No description provided for @adminPasswordValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter admin password'**
  String get adminPasswordValidation;

  /// No description provided for @visitTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit Type'**
  String get visitTypeTitle;

  /// No description provided for @noVisitTypeAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Visit Type Available'**
  String get noVisitTypeAvailable;

  /// No description provided for @unknownVisitType.
  ///
  /// In en, this message translates to:
  /// **'Unknown Visit Type'**
  String get unknownVisitType;

  /// No description provided for @walkInTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk-In'**
  String get walkInTitle;

  /// No description provided for @walkInServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk-In Service'**
  String get walkInServiceTitle;

  /// No description provided for @pudoTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick Up/Drop-Off'**
  String get pudoTitle;

  /// No description provided for @pleaseSelectFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select Property Code and Unit Type first'**
  String get pleaseSelectFirst;

  /// No description provided for @pleaseSelectLotNo.
  ///
  /// In en, this message translates to:
  /// **'Please select unit(s) to proceed'**
  String get pleaseSelectLotNo;

  /// No description provided for @pleaseSelectServiceType.
  ///
  /// In en, this message translates to:
  /// **'Please select service type to proceed'**
  String get pleaseSelectServiceType;

  /// No description provided for @noMatchingLotNo.
  ///
  /// In en, this message translates to:
  /// **'No matching lots found'**
  String get noMatchingLotNo;

  /// No description provided for @deptcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Code'**
  String get deptcodeLabel;

  /// No description provided for @deptcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Select property code'**
  String get deptcodeHint;

  /// No description provided for @unitTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Type'**
  String get unitTypeLabel;

  /// No description provided for @unitTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select unit type'**
  String get unitTypeHint;

  /// No description provided for @sortingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sorting'**
  String get sortingLabel;

  /// No description provided for @sortingHint.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortingHint;

  /// No description provided for @deliveryServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Service'**
  String get deliveryServiceLabel;

  /// No description provided for @deliveryServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Select Delivery Service Type'**
  String get deliveryServiceHint;

  /// No description provided for @allProjectCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'All Project Code'**
  String get allProjectCodeLabel;

  /// No description provided for @unitAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Find Unit Address'**
  String get unitAddressHint;

  /// No description provided for @noContactFound.
  ///
  /// In en, this message translates to:
  /// **'No contact found'**
  String get noContactFound;

  /// No description provided for @noUnitFound.
  ///
  /// In en, this message translates to:
  /// **'No unit found'**
  String get noUnitFound;

  /// No description provided for @scanOrInputQR.
  ///
  /// In en, this message translates to:
  /// **'Scan/Input QR Code'**
  String get scanOrInputQR;

  /// No description provided for @selectContactValidation.
  ///
  /// In en, this message translates to:
  /// **'Please select a contact'**
  String get selectContactValidation;

  /// No description provided for @phoneNo1Label.
  ///
  /// In en, this message translates to:
  /// **'Phone No. 1'**
  String get phoneNo1Label;

  /// No description provided for @phoneNo2Label.
  ///
  /// In en, this message translates to:
  /// **'Phone No. 2'**
  String get phoneNo2Label;

  /// No description provided for @phoneNo3Label.
  ///
  /// In en, this message translates to:
  /// **'Phone No. 3'**
  String get phoneNo3Label;

  /// No description provided for @ocrTitle.
  ///
  /// In en, this message translates to:
  /// **'OCR Text Scanner'**
  String get ocrTitle;

  /// No description provided for @startOCRLabel.
  ///
  /// In en, this message translates to:
  /// **'Start OCR'**
  String get startOCRLabel;

  /// No description provided for @scanOCRTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Identity Card'**
  String get scanOCRTitle;

  /// No description provided for @scanOCRDescription.
  ///
  /// In en, this message translates to:
  /// **'Position your ID clearly within the frame'**
  String get scanOCRDescription;

  /// No description provided for @scanLabel.
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get scanLabel;

  /// No description provided for @noImageLabel.
  ///
  /// In en, this message translates to:
  /// **'No image captured yet'**
  String get noImageLabel;

  /// No description provided for @extractedInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Extracted Information'**
  String get extractedInfoLabel;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @idNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'ID Number'**
  String get idNumberLabel;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @registerLabel.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLabel;

  /// No description provided for @visitingLabel.
  ///
  /// In en, this message translates to:
  /// **'Visiting'**
  String get visitingLabel;

  /// No description provided for @lotNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Lot No'**
  String get lotNoLabel;

  /// No description provided for @visitorName.
  ///
  /// In en, this message translates to:
  /// **'Visitor Name'**
  String get visitorName;

  /// No description provided for @visitorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter visitor\'s name'**
  String get visitorNameHint;

  /// No description provided for @visitorContactNo.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get visitorContactNo;

  /// No description provided for @visitorContactNoHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 0123456789'**
  String get visitorContactNoHint;

  /// No description provided for @visitorVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get visitorVehicle;

  /// No description provided for @visitorVehicleNoOptional.
  ///
  /// In en, this message translates to:
  /// **'Vehicle no (Optional)'**
  String get visitorVehicleNoOptional;

  /// No description provided for @visitorVehicleNoHint.
  ///
  /// In en, this message translates to:
  /// **'Enter visitor\'s vehicle number'**
  String get visitorVehicleNoHint;

  /// No description provided for @visitorIdNo.
  ///
  /// In en, this message translates to:
  /// **'ID Number'**
  String get visitorIdNo;

  /// No description provided for @visitorIdNoHint.
  ///
  /// In en, this message translates to:
  /// **'Enter visitor\'s identity card'**
  String get visitorIdNoHint;

  /// No description provided for @visitorNoOfPax.
  ///
  /// In en, this message translates to:
  /// **'Number of Pax'**
  String get visitorNoOfPax;

  /// No description provided for @visitorRemarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get visitorRemarks;

  /// No description provided for @nameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Name is empty'**
  String get nameEmptyError;

  /// No description provided for @contactNoEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Contact Number is empty'**
  String get contactNoEmptyError;

  /// No description provided for @vehicleNoEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number is empty'**
  String get vehicleNoEmptyError;

  /// No description provided for @idNoEmptyError.
  ///
  /// In en, this message translates to:
  /// **'ID Number is empty'**
  String get idNoEmptyError;

  /// No description provided for @noPaxEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Number of pax is empty'**
  String get noPaxEmptyError;

  /// No description provided for @visitorCarParkError.
  ///
  /// In en, this message translates to:
  /// **'Please assign a car park for the visitor'**
  String get visitorCarParkError;

  /// No description provided for @visitorPassError.
  ///
  /// In en, this message translates to:
  /// **'Please assign a visitor pass for the visitor'**
  String get visitorPassError;

  /// No description provided for @selectCarParkLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Car Park'**
  String get selectCarParkLabel;

  /// No description provided for @selectVisitorPassLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Visitor Pass'**
  String get selectVisitorPassLabel;

  /// No description provided for @enterQRCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter QR code'**
  String get enterQRCodeLabel;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccessful;

  /// No description provided for @registrationUnsuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration unsuccessful!'**
  String get registrationUnsuccessful;

  /// No description provided for @selectDualPassTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to proceed?'**
  String get selectDualPassTitle;

  /// No description provided for @selectPassTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Please select visitor pass type'**
  String get selectPassTypeLabel;

  /// No description provided for @usedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get usedLabel;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @termAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to log out?'**
  String get logoutWarning;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @userCode.
  ///
  /// In en, this message translates to:
  /// **'User Code'**
  String get userCode;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// No description provided for @projectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectLabel;

  /// No description provided for @sosLog.
  ///
  /// In en, this message translates to:
  /// **'SOS LOG'**
  String get sosLog;

  /// No description provided for @callLog.
  ///
  /// In en, this message translates to:
  /// **'CALL LOG'**
  String get callLog;

  /// No description provided for @facilityBookingLog.
  ///
  /// In en, this message translates to:
  /// **'FACILITY BOOKING LOG'**
  String get facilityBookingLog;

  /// No description provided for @vms2AppLog.
  ///
  /// In en, this message translates to:
  /// **'VMS2 APP LOG'**
  String get vms2AppLog;

  /// No description provided for @goGuardManagementSystem.
  ///
  /// In en, this message translates to:
  /// **'GoGuard Management System'**
  String get goGuardManagementSystem;

  /// No description provided for @availableParking.
  ///
  /// In en, this message translates to:
  /// **'Available Parking'**
  String get availableParking;

  /// No description provided for @activeVisitor.
  ///
  /// In en, this message translates to:
  /// **'Active Visitor'**
  String get activeVisitor;

  /// No description provided for @scanOrInputQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan/Input QR Code'**
  String get scanOrInputQrCode;

  /// No description provided for @searchKeyword.
  ///
  /// In en, this message translates to:
  /// **'Search Keyword (Unit/Visitor name/code...)'**
  String get searchKeyword;

  /// No description provided for @todayAppointment.
  ///
  /// In en, this message translates to:
  /// **'Today Appointment'**
  String get todayAppointment;

  /// No description provided for @visitLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visitLabel;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @expiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredLabel;

  /// No description provided for @residentLabel.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get residentLabel;

  /// No description provided for @visitorLabel.
  ///
  /// In en, this message translates to:
  /// **'Visitor'**
  String get visitorLabel;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remarks;

  /// No description provided for @checkInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check In Success'**
  String get checkInSuccess;

  /// No description provided for @checkInSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Visitor has checked in.'**
  String get checkInSuccessDesc;

  /// No description provided for @checkOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check Out Success'**
  String get checkOutSuccess;

  /// No description provided for @checkOutSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Visitor has checked out.'**
  String get checkOutSuccessDesc;

  /// No description provided for @selectVisitPass.
  ///
  /// In en, this message translates to:
  /// **'Select Visit Pass'**
  String get selectVisitPass;

  /// No description provided for @selectParking.
  ///
  /// In en, this message translates to:
  /// **'Select Parking'**
  String get selectParking;

  /// No description provided for @appointmentDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Detail'**
  String get appointmentDetailTitle;

  /// No description provided for @checkoutListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No check-ins today'**
  String get checkoutListEmptyTitle;

  /// No description provided for @checkoutListEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Checked-in users will appear here once they arrive.'**
  String get checkoutListEmptyDesc;

  /// No description provided for @checkinListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get checkinListEmptyTitle;

  /// No description provided for @checkinListEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'There are no pre-registered visitors waiting to check in.'**
  String get checkinListEmptyDesc;

  /// No description provided for @checkoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Checkout confirmation'**
  String get checkoutConfirmation;

  /// No description provided for @checkoutConfirmationDesc.
  ///
  /// In en, this message translates to:
  /// **'You are about to checkout for Visitor'**
  String get checkoutConfirmationDesc;

  /// No description provided for @checkinInvalidQRError.
  ///
  /// In en, this message translates to:
  /// **'This appointment has been scheduled for a future date. Please be advised that the QR code is invalid.'**
  String get checkinInvalidQRError;

  /// No description provided for @checkoutInvalidQRError.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not registered in our system. Please ask the visitor to verify or provide a valid QR code.'**
  String get checkoutInvalidQRError;

  /// No description provided for @confirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @ownerTenantLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner/Tenant'**
  String get ownerTenantLabel;

  /// No description provided for @generalLabel.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalLabel;

  /// No description provided for @callLabel.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callLabel;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get notFound;

  /// No description provided for @homeLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get homeLog;

  /// No description provided for @goguardLog.
  ///
  /// In en, this message translates to:
  /// **'GoGuard Log'**
  String get goguardLog;

  /// No description provided for @clearLog.
  ///
  /// In en, this message translates to:
  /// **'Clear Log'**
  String get clearLog;

  /// No description provided for @vmsAppLog.
  ///
  /// In en, this message translates to:
  /// **' VMS APP Log'**
  String get vmsAppLog;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @clearLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to clear log?'**
  String get clearLogDesc;

  /// No description provided for @noLogFound.
  ///
  /// In en, this message translates to:
  /// **'No log found'**
  String get noLogFound;

  /// No description provided for @magBarrier.
  ///
  /// In en, this message translates to:
  /// **'MAG Barrier'**
  String get magBarrier;

  /// No description provided for @magBarrierSettings.
  ///
  /// In en, this message translates to:
  /// **'MAG Barrier Settings'**
  String get magBarrierSettings;

  /// No description provided for @updateMagBarrierSettingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Update MAG barrier settings successfully.'**
  String get updateMagBarrierSettingSuccess;

  /// No description provided for @selectYourPassType.
  ///
  /// In en, this message translates to:
  /// **'Select your pass type'**
  String get selectYourPassType;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ms': return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
