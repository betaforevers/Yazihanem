import 'package:flutter/foundation.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';

/// Authentication state — sealed class pattern.
///
/// Three possible states:
/// - [AuthInitial]: App just started, auth status unknown
/// - [AuthAuthenticated]: User is logged in
/// - [AuthUnauthenticated]: User is logged out or token invalid
@immutable
sealed class AuthState {
  const AuthState();
}

/// Initial state — auth check has not been performed yet.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// User is authenticated with a valid session.
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  final String? reason;
  const AuthUnauthenticated({this.reason});
}

/// Auth operation is in progress (login, logout, etc.)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Auth operation failed.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
