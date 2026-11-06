import 'package:auth_service/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:patrol/core/repository/base_repository.dart';
import 'package:patrol/core/services/secure_storage.dart';
import 'package:patrol/core/services/user_preference.dart';
import 'package:patrol/core/utils/utils.dart';
import 'package:patrol/core/widgets/custom_dialog.dart';
import 'package:patrol/service_locator.dart';

class AuthRepository with BaseRepository {
  final AuthService authService;

  AuthRepository({required this.authService});

  Future<String> generateTempToken() async {
    final myHash = (platform + secret + deviceToken).toString().hashMd5;
    Jmap data = {};
    data['hash'] = myHash;
    data['platform'] = platform;
    data['notification_token'] = deviceToken;
    data['device_os'] = mobileOs;
    data['device_model'] = deviceModel;
    data['user_agent'] = 'CSS App/4.0';
    final response = await authService.postTempToken(data);
    response.printSingle;
    if (response.isSuccess()) {
      return response.responseData['resultSet']['temp_token'] ?? "";
    } else {
      return "";
    }
  }

  Future<void> postAuthToken({String tempToken = ""}) async {
    final hashed = (secret + tempToken).toString().hashMd5;
    Jmap data = {};
    data['hash'] = hashed;
    data['temp_token'] = tempToken;
    final response = await authService.postAuthToken(data);
    response.printSingle;
    if (response.isSuccess()) {
      final res = response.responseData['resultSet']['accesstoken'] ?? "";
      if (res.isNotEmpty) {
        await sl<SecureStorage>().persistPrivateAuthToken(res);
      } else {
        throw Exception("Auth token is empty");
      }
    } else {}
  }

  Future<dynamic> postVerifyAdminPassword({String password = ""}) async {
    String encryptedMD5Password = password.toString().hashMd5;
    final hashed = (secret + encryptedMD5Password + authToken)
        .toString()
        .hashMd5;
    Jmap fieldMap = {};
    fieldMap['hash'] = hashed;
    fieldMap['auth_token'] = authToken;
    fieldMap['platform'] = platform;
    fieldMap['patrol_admin_pwd'] = encryptedMD5Password;
    var formData = FormData.fromMap(fieldMap);
    final response = await authService.postVerifyAdminPassword(formData);
    if (response.isSuccess()) {
      await sl<UserPreferences>().resetAllUserProjectData();
      return 1;
    }
    CustomDialog.showAppDialog(response.processCodeToMessage());
    return -1;
  }

  Future<dynamic> postLogin({
    String projectId = "",
    String projectName = "",
    String loginId = "",
    String password = "",
  }) async {
    final encryptedPassword = password.hashMd5;
    final hashed =
        (secret + projectId + encryptedPassword + loginId + authToken)
            .toString()
            .hashMd5;
    Jmap fieldMap = {};
    fieldMap['hash'] = hashed;
    fieldMap['auth_token'] = authToken;
    fieldMap['platform'] = platform;
    fieldMap['project_id'] = projectId;
    fieldMap['login_id'] = loginId;
    fieldMap['login_pwd'] = encryptedPassword;
    var formData = FormData.fromMap(fieldMap);
    final response = await authService.postLogin(formData);
    if (response.isSuccess()) {
      await sl<SecureStorage>().persistPrivateUserAuthToken(authToken);
      await sl<UserPreferences>().setUserProjectId(projectId);
      await sl<UserPreferences>().setUserProjectName(projectName);
      await sl<UserPreferences>().setUserLoggedIn("Logged In");
      return 1;
    }
    CustomDialog.showAppDialog(response.processCodeToMessage());
    return -1;
  }

  Future<dynamic> postLogout() async {
    final hashed = (secret + authToken).toString().hashMd5;
    Jmap fieldMap = {};
    fieldMap['hash'] = hashed;
    fieldMap['auth_token'] = authToken;
    fieldMap['platform'] = platform;
    final response = await authService.postLogout(fieldMap);
    response.printSingle;
    if (response.isSuccess()) {
      return 1;
    }
    CustomDialog.showAppDialog(response.processCodeToMessage());
    return -1;
  }
}
