part of 'general_cubit.dart';

enum GeneralStatus { init, loading, success, fail, error }

class GeneralState extends Equatable {
  final GeneralStatus status;
  final String? tempAuthToken;
  final AppSettingModel? appSettingModel;
  const GeneralState({this.status = GeneralStatus.init, this.tempAuthToken, this.appSettingModel});

  GeneralState copyWith({GeneralStatus? status, String? tempAuthToken, AppSettingModel? appSettingModel}) {
    return GeneralState(
      status: status ?? this.status,
      tempAuthToken: tempAuthToken ?? this.tempAuthToken,
      appSettingModel: appSettingModel ?? this.appSettingModel,
    );
  }

  @override
  List<Object?> get props => [status, tempAuthToken, appSettingModel];
}
