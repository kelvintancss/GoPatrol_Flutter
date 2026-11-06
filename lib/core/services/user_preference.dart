import 'dart:convert';

import 'package:patrol/core/model/ocr_frame_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  UserPreferences({required this.prefs});

  final SharedPreferences prefs;

  // Key
  static const String _userFirst = "USER_FIRST";
  static const String _userProjectId = "USER_PROJECT_ID";
  static const String _userProjectName = "USER_PROJECT_NAME";
  static const String _userLoggedIn = "USER_LOGGED_IN";
  static const String _patrolActive = "PATROL_ACTIVE";
  static const String _patrolStartTime = "PATROL_START_TIME";

  static const String _dialCodeList = "DIAL_CODE_LIST";
  static const String _countryList = "COUNTRY_LIST";
  static const String _deleteReasonList = "DELETE_REASON_LIST";
  static const String _userIpAddress = "USER_IP_ADDRESS";
  static const String _languageCode = "LANGUAGE_CODE";

  static const String _magCheckIn = "MAG_CHECK_IN";
  static const String _magRegister = "MAG_REGISTER";
  static const String _magCheckOut = "MAG_CHECK_OUT";

  static const String _ocrFrame = "OCR_FRAME";

  ///**App Data List */
  Future<void> setDialCodeList(String lang) async {
    await prefs.setString(_dialCodeList, lang);
  }

  String? getDialCodeList() {
    return prefs.getString(_dialCodeList);
  }

  Future<void> setCountryList(String lang) async {
    await prefs.setString(_countryList, lang);
  }

  String? getCountryList() {
    return prefs.getString(_countryList);
  }

  Future<void> setDeleteReasonList(String lang) async {
    await prefs.setString(_deleteReasonList, lang);
  }

  String? getDeleteReasonList() {
    return prefs.getString(_deleteReasonList);
  }

  Future<void> setUserIp(String ip) async {
    await prefs.setString(_userIpAddress, ip);
  }

  String? getIpAddress() {
    return prefs.getString(_userIpAddress);
  }
  /// MAG Barrier settings
  /// With Check In, Check Out, Register
  Future<void> setMagCheckIn(bool value) async {
    await prefs.setBool(_magCheckIn, value);
  }

  bool? getMagCheckIn() {
    return prefs.getBool(_magCheckIn);
  }

  Future<void> setMagCheckOut(bool value) async {
    await prefs.setBool(_magCheckOut, value);
  }

  bool? getMagCheckOut() {
    return prefs.getBool(_magCheckOut);
  }

  Future<void> setMagRegister(bool value) async {
    await prefs.setBool(_magRegister, value);
  }

  bool? getMagRegister() {
    return prefs.getBool(_magRegister);
  }

  /// Set the app language
  /// [zh] code by default
  /// [code] it required to set new language code
  Future<void> setLanguageCode(String code) async {
    await prefs.setString(_languageCode, code);
  }

  /// Get the app language
  /// [zh] return by default
  /// [_languageCode] key
  String get getLangCodeOrDefault {
    return prefs.getString(_languageCode) ?? 'en';
  }

  ///** General Usage */
  /// Clear ALL shared preferences data
  Future<void> clearSharedPreferences() async {
    await prefs.clear();
  }

  /// Set user first run app for handle keychain data
  /// [bool] true -> user first time enter app (either install/re-install)
  /// else false -> set user entered already
  Future<void> setUserFirstRun(bool value) async {
    await prefs.setBool(_userFirst, value);
  }

  /// Check user if first run
  /// [bool] true -> user is first run
  /// else false -> user entered already
  /// default value -> true
  bool getUserFirstRun() {
    return prefs.getBool(_userFirst) ?? true;
  }

  // UserProjectData
  Future<void> setUserProjectId(String data) async {
    await prefs.setString(_userProjectId, data);
  }

  String? get getUserProjectId => prefs.getString(_userProjectId);

  Future<void> setUserProjectName(String data) async {
    await prefs.setString(_userProjectName, data);
  }

  String? get getUserProjectName => prefs.getString(_userProjectName);

  Future<void> resetAllUserProjectData() async {
    await prefs.remove(_userProjectId);
    await prefs.remove(_userProjectName);
  }

  Future<void> setUserLoggedIn(String data) async {
    await prefs.setString(_userLoggedIn, data);
  }

  /// Explicit logout marker — [clearIfFirstUserUninstall]'s reset path
  /// preserves whatever login state is true at the moment it runs, so an
  /// actual logout must clear this beforehand rather than relying on that
  /// reset to do it.
  Future<void> clearUserLoggedIn() async {
    await prefs.remove(_userLoggedIn);
  }

  // OCR frame setting
  Future<void> setOcrFrame(OcrFrameItem user) async {
    final jsonString = jsonEncode(user.toJson()); // convert to string
    await prefs.setString(_ocrFrame, jsonString);
  }

  // Read object
   Future<OcrFrameItem?> getOcrFrame() async {
    final jsonString = prefs.getString(_ocrFrame);

    if (jsonString == null) return null; // not found

    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return OcrFrameItem.fromJson(jsonMap);
  }


  /// Check if user is logged in
  /// [bool] true -> user logged in
  /// else false -> non-login user
  bool isUserLoggedIn() {
    return prefs.getString(_userLoggedIn) != null;
  }

  /// Set whether a patrol session is currently active (started but not yet
  /// stopped), so app relaunches can resume straight into the patrol page.
  Future<void> setPatrolActive(bool value) async {
    await prefs.setBool(_patrolActive, value);
  }

  bool isPatrolActive() {
    return prefs.getBool(_patrolActive) ?? false;
  }

  /// Timestamp of when the current patrol session was started, so the
  /// patrol page can record it even after an app relaunch resumes into it.
  Future<void> setPatrolStartTime(DateTime value) async {
    await prefs.setString(_patrolStartTime, value.toIso8601String());
  }

  DateTime? getPatrolStartTime() {
    final value = prefs.getString(_patrolStartTime);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}
