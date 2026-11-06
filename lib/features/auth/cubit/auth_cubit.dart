import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:patrol/core/repository/auth_repository.dart';
import 'package:patrol/core/services/services.dart';
import 'package:patrol/core/utils/app_reload_provider.dart';
import 'package:patrol/core/utils/patrol_record_db.dart';
import 'package:patrol/core/utils/incident_record_db.dart';
import 'package:patrol/core/widgets/custom_dialog.dart';
import 'package:patrol/features/auth/cubit/auth_state.dart';
import 'package:patrol/service_locator.dart';

class AuthCubit extends Cubit<AuthState> with AppReloadProvider {
  AuthCubit() : super(const AuthState());

  final AuthRepository authRepository = sl<AuthRepository>();

  void reset() => emit(const AuthState());

  Future<void> postVerifyAdminPassword({required String password}) async {
    emit(state.copyWith(status: AuthenticateStatus.loading));
    try {
      final response = await authRepository.postVerifyAdminPassword(
        password: password,
      );
      if (response == 1) {
        emit(state.copyWith(status: AuthenticateStatus.success));
      } else {
        emit(state.copyWith(status: AuthenticateStatus.fail));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthenticateStatus.error));
    }
  }

  Future<void> postLogin({
    required String projectId,
    required String projectName,
    required String loginId,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthenticateStatus.loginLoading));
    try {
      final response = await authRepository.postLogin(
        projectId: projectId,
        projectName: projectName,
        loginId: loginId,
        password: password,
      );
      if (response == 1) {
        emit(state.copyWith(status: AuthenticateStatus.loginSuccess));
      } else {
        emit(state.copyWith(status: AuthenticateStatus.loginError));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthenticateStatus.loginError));
    }
  }

  Future<void> logout({required Function() navBackHome}) async {
    emit(state.copyWith(status: AuthenticateStatus.logoutLoading));
    // postLogout() is best-effort (it just tells the server to invalidate
    // this session) — whether it succeeds, fails, or the app-level token
    // happens to be stale right at this moment shouldn't block the user
    // from actually logging out locally, so its outcome is deliberately
    // ignored here.
    try {
      await authRepository.postLogout();
    } catch (_) {
      // Ignored — local logout proceeds regardless.
    }

    CustomDialog.showAppToast("Logout success");
    // authenicateUserAccess()'s reset preserves whatever login state is
    // true at the moment it runs (so a mid-session invalid-token refresh
    // doesn't silently log an active user out) — for an actual logout
    // that means the markers must be cleared here first, or the reset
    // just restores them and the user never actually leaves the
    // logged-in state.
    await sl<UserPreferences>().clearUserLoggedIn();
    await sl<SecureStorage>().persistPrivateUserAuthToken("");
    await authenicateUserAccess();
    await PatrolRecordDatabase.instance.clearAll();
    await IncidentRecordDatabase.instance.clearAll();
    reset();
    emit(state.copyWith(status: AuthenticateStatus.init));
    navBackHome();
  }
}
