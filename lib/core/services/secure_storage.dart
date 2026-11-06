import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:patrol/core/services/firebase_helper.dart';
import 'package:patrol/service_locator.dart';

import 'user_preference.dart';

class SecureStorage {
  factory SecureStorage() => _instance ??= SecureStorage._();

  //AndroidOptions _secureOption() => const AndroidOptions(encryptedSharedPreferences: true);

  SecureStorage._() : _storage = const FlutterSecureStorage();

  static SecureStorage? _instance;
  final FlutterSecureStorage _storage;

  // Key
  static const String _authTokenKey = "AUTH_TOKEN";
  static const String _tempTokenKey = "TEMP_TOKEN";
  static const String _deviceTokenKey = "DEVICE_TOKEN";
  static const String _userAuthTokenKey = "USER_AUTH_TOKEN";

  // Get value
  String? _tempToken;
  String? _authToken;
  String? _userAuthToken;
  String? _deviceToken;

  Future<void> init() async {
    _tempToken = "";
    _authToken = await _storage.read(key: _authTokenKey);
    _userAuthToken = await _storage.read(key: _userAuthTokenKey);
    _deviceToken = await _storage.read(key: _deviceTokenKey);
  }

  /// NON-LOGIN
  /// Save temp token
  Future<void> persistPrivateTempToken(String token) async {
    _tempToken = token;

    await _storage.write(key: _tempTokenKey, value: token);
  }

  /// NON-LOGIN
  /// Save auth token
  Future<void> persistPrivateAuthToken(String token) async {
    _authToken = token;
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// LOGIN (REMEMBER ME)
  /// Save user auth token && remember me
  Future<void> persistPrivateUserAuthToken([String? token]) async {
    _userAuthToken = token ?? _authToken;
    await _storage.write(key: _userAuthTokenKey, value: token ?? _authToken);
  }

  /// FIREBASE TOKEN
  /// Save Firebase device token
  Future<void> persistDeviceToken(String token) async {
    _deviceToken = token;

    await _storage.write(key: _deviceTokenKey, value: token);
  }

  /// Delete all local preference
  Future<void> deleteAll() async {
    return await _storage.deleteAll();
  }

  /// Return true if non-login else false
  Future<bool> isAuthTokenEmpty() async {
    final userAuthToken = await _storage.read(key: _userAuthTokenKey) ?? "";
    return userAuthToken.isEmpty;
  }

  /// Check if user is first run app &&
  /// Return true if non-user else false
  Future<bool> clearIfFirstUserUninstall() async {
    if ((sl<UserPreferences>().getUserFirstRun()) || await isAuthTokenEmpty() || !sl<UserPreferences>().isUserLoggedIn()) {
      print("first run");
      // Read straight from storage (not the in-memory fields below, which
      // may still be un-hydrated at this point) so a currently-valid
      // logged-in token can be restored after deleteAll() below.
      final currentUserAuthToken = await _storage.read(key: _userAuthTokenKey);
      _tempToken = null;
      _authToken = null;
      _userAuthToken = null;
      _deviceToken = null;
      final currentProjectId = sl<UserPreferences>().getUserProjectId;
      final currentProjectName = sl<UserPreferences>().getUserProjectName;
      final currentUserLoggedIn = sl<UserPreferences>().isUserLoggedIn();
      final currentMagCheckin = sl<UserPreferences>().getMagCheckIn();
      final currentMagCheckout = sl<UserPreferences>().getMagCheckOut();
      final currentMagRegister = sl<UserPreferences>().getMagRegister();

      await deleteAll();
      String loc = sl<UserPreferences>().getLangCodeOrDefault;
      await sl<UserPreferences>().clearSharedPreferences();
      await sl<UserPreferences>().setLanguageCode(loc);
      final deviceT = await sl<FirebaseHelper>().getDeviceToken();
      await persistDeviceToken(deviceT ?? "");
      if (currentProjectId != null && currentProjectName != null) {
        await sl<UserPreferences>().setUserProjectId(currentProjectId);
        await sl<UserPreferences>().setUserProjectName(currentProjectName);
      }
      // Without this, an already-logged-in user gets silently logged out
      // the moment any background call (patrol/incident sync, home data
      // refresh) hits an invalid-token response — clearSharedPreferences()
      // above wipes USER_LOGGED_IN and deleteAll() wipes USER_AUTH_TOKEN,
      // and nothing used to restore either, so splash would fall back to
      // the slow/guest path (and isAuthTokenEmpty() would stay stuck
      // permanently true) on every future launch even though the user
      // never logged out.
      if (currentUserLoggedIn) {
        await sl<UserPreferences>().setUserLoggedIn("Logged In");
        if (currentUserAuthToken != null && currentUserAuthToken.isNotEmpty) {
          await persistPrivateUserAuthToken(currentUserAuthToken);
        }
      }
      /// Mag barrier settings
      /// START ##########
      /// #####################
      if (currentMagCheckin != null) {
        await sl<UserPreferences>().setMagCheckIn(currentMagCheckin);
      }
      if (currentMagCheckout != null) {
        await sl<UserPreferences>().setMagCheckOut(currentMagCheckout);
      }
      if (currentMagRegister != null) {
        await sl<UserPreferences>().setMagRegister(currentMagRegister);
      }
      /// Mag barrier settings
      /// END ##########
      /// #####################
      await sl<UserPreferences>().setUserFirstRun(false);

      return true;
    }

    await init();
    return false;
  }

  // Getter method

  String get token => _authToken ?? "";

  String get deviceToken => _deviceToken ?? "";

  String get tempToken => _tempToken ?? "";

  String get userToken => _userAuthToken ?? "";
}
