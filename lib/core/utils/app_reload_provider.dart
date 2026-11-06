import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:patrol/core/services/secure_storage.dart';
import 'package:patrol/core/services/user_preference.dart';
import 'package:patrol/features/general/cubit/general_cubit.dart';
import 'package:patrol/service_locator.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

mixin AppReloadProvider {
  BuildContext get _context => MyDialog.navigatorKey.currentContext!;

  SecureStorage get _secure => sl<SecureStorage>();

  GeneralCubit get _generalCubit => BlocProvider.of<GeneralCubit>(_context);

  /// Refresh all data including token, user & general data
  /// Clear local preferences
  ///
  /// Does NOT touch the persisted "is logged in" token itself — an already
  /// logged-in user hitting an invalid-token response (e.g. an expired
  /// app-level session token) should get that token silently refreshed,
  /// not be logged out. [SecureStorage.clearIfFirstUserUninstall] is what
  /// decides what survives this reset, based on the state at the moment
  /// it's called.
  Future<void> authenicateUserAccess() async {
    await sl<UserPreferences>().setUserFirstRun(true);
    await _secure.clearIfFirstUserUninstall();
    await reloadAppGeneral(isClear: true);
  }

  Future<void> reloadAppGeneral({isClear = false}) async {
    if (isClear) {
      _generalCubit.resetGeneral();
      await _generalCubit.getTempToken();
      await _generalCubit.fetchAuthToken();
    }
    _generalCubit.fetchAppVersion();
  }
}
