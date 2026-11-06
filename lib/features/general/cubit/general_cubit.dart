import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:patrol/core/model/app_setting_model.dart';
import 'package:patrol/core/repository/auth_repository.dart';
import 'package:patrol/core/repository/general_repository.dart';
import 'package:patrol/service_locator.dart';

part 'general_state.dart';

class GeneralCubit extends Cubit<GeneralState> {
  GeneralCubit() : super(const GeneralState());

  final _authRepository = sl<AuthRepository>();
  final _generalRepository = sl<GeneralRepository>();

  Future<void> getTempToken() async {
    try {
      final response = await _authRepository.generateTempToken();
      if (response.isNotEmpty) {
        emit(state.copyWith(tempAuthToken: response));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchAuthToken() async {
    emit(state.copyWith(status: GeneralStatus.loading));
    try {
      await _authRepository.postAuthToken(tempToken: state.tempAuthToken ?? "");
    } catch (e) {
      debugPrint(e.toString());
      emit(state.copyWith(status: GeneralStatus.error));
    }
  }

  Future<dynamic> fetchAppVersion() async {
    emit(state.copyWith(status: GeneralStatus.loading));
    try {
      final res = await _generalRepository.getAppVersion();
      if (res is AppSettingModel) {
        emit(
          state.copyWith(status: GeneralStatus.success, appSettingModel: res),
        );
        return 1;
      }
      emit(state.copyWith(status: GeneralStatus.fail));
      return -1;
    } catch (e) {
      debugPrint(e.toString());
      emit(state.copyWith(status: GeneralStatus.error));
      return -1;
    }
  }

  void resetGeneral() => emit(const GeneralState());
}
