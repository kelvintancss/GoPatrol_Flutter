import 'package:dio/dio.dart';
import 'package:patrol/core/widgets/custom_dialog.dart';
import 'package:property_service/property_service.dart';
import 'package:patrol/core/repository/base_repository.dart';
import 'package:patrol/core/utils/app_extension.dart';

import '../model/model.dart';

class PropertyRepository with BaseRepository {
  final PropertyService propertyService;

  PropertyRepository({required this.propertyService});

  Future<PropertyItem?> getProjectId({String projectCode = ""}) async {
    final hashed = (secret + projectCode + authToken).toString().hashMd5;
    Jmap fieldMap = {};
    fieldMap['hash'] = hashed;
    fieldMap['auth_token'] = authToken;
    fieldMap['platform'] = platform;
    fieldMap['code'] = projectCode;

    var data = FormData.fromMap(fieldMap);
    final response = await propertyService.getProjectId(data);
    response.printSingle;
    if (response.isSuccess()) {
      return PropertyItem.fromJson(response.responseData);
    } else {
      return null;
    }
  }

  Future<HomeResponseModel?> postGetHomeInfo() async {
    final hashed = (secret + authToken).toString().hashMd5;
    Jmap fieldMap = {};
    fieldMap['hash'] = hashed;
    fieldMap['auth_token'] = authToken;
    fieldMap['platform'] = platform;

    var formData = FormData.fromMap(fieldMap);
    final response = await propertyService.postGetHomeInfo(formData);
    // response.printSingle;
    if (response.isSuccess()) {
      return HomeResponseModel.fromJson(response.responseData['0']);
    }
    CustomDialog.showAppDialog(response.processCodeToMessage());
    return null;
  }
}
