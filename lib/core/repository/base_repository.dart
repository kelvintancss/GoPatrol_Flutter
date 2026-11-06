import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:patrol/core/services/services.dart' show SecureStorage, UserPreferences;
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/env/env.dart' show AppEnv;
import 'package:patrol/flavors.dart';
import 'package:patrol/service_locator.dart';



typedef Jmap = Map<String, dynamic>;

/// This class contains security and general information data used for access the entire application 
/// @author Hew
mixin BaseRepository {
  get apiKey {
    if (F.appFlavor == Flavor.staging) {
      return AppEnv.stagingApiKey;
    }
    if (F.appFlavor == Flavor.demo) {
      return AppEnv.stagingApiKey;
    } else {
      return AppEnv.prodApiKey;
    }
  }

  get secret {
    if (F.appFlavor == Flavor.staging) {
      return AppEnv.stagingSecretKey;
    }
    if (F.appFlavor == Flavor.demo) {
      return AppEnv.stagingSecretKey;
    } else {
      return AppEnv.prodSecretKey;
    }
  }

  /// user type token
  get authToken => sl<SecureStorage>().token;


  /// user type temp token
  get tempToken => sl<SecureStorage>().tempToken;


  /// FCM token
  get deviceToken => sl<SecureStorage>().deviceToken;

  /// os platform etc: "IOS 16.0" or "ANDROID 12"
  get mobileOs => Platform.isIOS ? sl<IosDeviceInfo>().model : sl<AndroidDeviceInfo>().model;

  /// IOS or ANDROID
  get platform =>  Platform.isIOS ? "IOS" : "ANDROID";

  get deviceModel => Platform.isIOS ? sl<IosDeviceInfo>().modelName : sl<AndroidDeviceInfo>().name;

  /// App language support 
  get appLanguageCode => sl<UserPreferences>().getLangCodeOrDefault ==
          Constants.languageCodeEn
      ? Constants.languageCodeEn
      : Constants.languageCodeEn;
  
  get userIp => sl<UserPreferences>().getIpAddress();

  get userProjectid => sl<UserPreferences>().getUserProjectId;
  
  get userAgent => "CSS App/4.0";
  
  // Default hash value for APIs

  //md5.convert(utf8.encode((secret + authToken))).toString();
  get hashSecretAuthToken => (secret + authToken).toString().hashMd5;

  /// Shortcut for normal hashed and data to Map type
  get hashSecretAuthTokenToMap {
    final fieldMap = <String, dynamic>{};
    fieldMap['hash'] = hashSecretAuthToken;
    return fieldMap;
  }
}