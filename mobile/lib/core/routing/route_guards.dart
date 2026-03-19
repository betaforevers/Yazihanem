import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/features/auth/domain/auth_state.dart';
import 'package:yazihanem_mobile/features/auth/providers/auth_provider.dart';

/// Route guard utilities for GoRouter.
///
/// Auth redirect and admin guard are now integrated directly into
/// app_router.dart using the reactive authStateProvider.
/// This file provides utility functions for custom route-level guards.

/// Check if the current user has admin role.
/// Returns redirect path if not admin, null if allowed.
String? adminGuard(WidgetRef ref) {
  final authState = ref.read(authStateProvider);
  if (authState is AuthAuthenticated && authState.user.isAdmin) {
    return null; // Allowed
  }
  return '/dashboard'; // Not admin → redirect
}

/// Check if the current user has editor or admin role.
/// Returns redirect path if viewer, null if allowed.
String? editorGuard(WidgetRef ref) {
  final authState = ref.read(authStateProvider);
  if (authState is AuthAuthenticated && authState.user.isEditor) {
    return null; // Allowed
  }
  return '/dashboard'; // Not editor → redirect
}
