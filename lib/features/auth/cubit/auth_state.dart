import 'package:equatable/equatable.dart';

enum AuthenticateStatus {
  loading,
  success,
  fail,
  error,
  init,
  logoutLoading,
  loginLoading,
  loginSuccess,
  loginError,
}

class AuthState extends Equatable {
  final AuthenticateStatus status;

  const AuthState({this.status = AuthenticateStatus.init});

  AuthState copyWith({AuthenticateStatus? status}) {
    return AuthState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
