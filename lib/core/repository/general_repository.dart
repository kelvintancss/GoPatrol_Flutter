import 'package:dio/dio.dart' show FormData;
import 'package:general_service/general_service.dart';
import 'package:patrol/core/model/model.dart';
import 'package:patrol/core/repository/base_repository.dart';
import 'package:patrol/core/utils/app_extension.dart';

class GeneralRepository with BaseRepository {
  final GeneralService generalService;

  GeneralRepository({required this.generalService});

  Future<dynamic> getAppVersion() async {
    final hashed = (secret + authToken).toString().hashMd5;

    Jmap fieldMap = {};
    fieldMap['hash'] = hashed;
    fieldMap['auth_token'] = authToken;
    fieldMap['platform'] = platform;
    var formData = FormData.fromMap(fieldMap);
    final response = await generalService.version(formData);
    if (response.isSuccess()) {
      return AppSettingModel.fromJson(response.responseData);
    } else {}
  }
}
