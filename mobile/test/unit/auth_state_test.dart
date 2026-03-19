import 'package:flutter_test/flutter_test.dart';
import 'package:yazihanem_mobile/features/auth/domain/auth_state.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';

void main() {
  const testUser = UserModel(
    id: 'test-id',
    email: 'test@yazihanem.com',
    firstName: 'Test',
    lastName: 'User',
    role: UserRole.editor,
    tenant: 'test-tenant',
  );

  group('AuthState', () {
    test('AuthInitial is the default state', () {
      const state = AuthInitial();
      expect(state, isA<AuthState>());
      expect(state, isA<AuthInitial>());
    });

    test('AuthLoading indicates in-progress operation', () {
      const state = AuthLoading();
      expect(state, isA<AuthState>());
      expect(state, isA<AuthLoading>());
    });

    test('AuthAuthenticated carries user data', () {
      const state = AuthAuthenticated(testUser);
      expect(state, isA<AuthState>());
      expect(state.user.email, 'test@yazihanem.com');
      expect(state.user.role, UserRole.editor);
    });

    test('AuthUnauthenticated can carry a reason', () {
      const state = AuthUnauthenticated(reason: 'Şifre değiştirildi');
      expect(state, isA<AuthState>());
      expect(state.reason, 'Şifre değiştirildi');
    });

    test('AuthUnauthenticated reason is optional', () {
      const state = AuthUnauthenticated();
      expect(state.reason, isNull);
    });

    test('AuthError carries error message', () {
      const state = AuthError('Geçersiz kimlik bilgileri');
      expect(state, isA<AuthState>());
      expect(state.message, 'Geçersiz kimlik bilgileri');
    });

    test('AuthAuthenticated equality works', () {
      const state1 = AuthAuthenticated(testUser);
      const state2 = AuthAuthenticated(testUser);
      expect(state1, equals(state2));
    });

    test('sealed class allows exhaustive switching', () {
      const AuthState state = AuthInitial();

      final result = switch (state) {
        AuthInitial() => 'initial',
        AuthLoading() => 'loading',
        AuthAuthenticated() => 'authenticated',
        AuthUnauthenticated() => 'unauthenticated',
        AuthError() => 'error',
      };

      expect(result, 'initial');
    });
  });
}
