import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yazihanem_mobile/features/auth/data/auth_repository.dart';
import 'package:yazihanem_mobile/features/auth/domain/auth_state.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';
import 'package:yazihanem_mobile/features/auth/providers/auth_provider.dart';

// ─── Mock ───

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthNotifier notifier;
  late MockAuthRepository mockRepo;

  const testUser = UserModel(
    id: 'user-123',
    email: 'test@yazihanem.com',
    firstName: 'Test',
    lastName: 'User',
    role: UserRole.editor,
    tenant: 'test-tenant',
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    notifier = AuthNotifier(mockRepo);
  });

  group('AuthNotifier', () {
    test('initial state is AuthInitial', () {
      expect(notifier.state, isA<AuthInitial>());
    });

    test('checkAuth → AuthAuthenticated when token is valid', () async {
      when(() => mockRepo.tryAutoLogin())
          .thenAnswer((_) async => testUser);

      await notifier.checkAuth();

      expect(notifier.state, isA<AuthAuthenticated>());
      expect((notifier.state as AuthAuthenticated).user.email,
          'test@yazihanem.com');
    });

    test('checkAuth → AuthUnauthenticated when no token', () async {
      when(() => mockRepo.tryAutoLogin())
          .thenAnswer((_) async => null);

      await notifier.checkAuth();

      expect(notifier.state, isA<AuthUnauthenticated>());
    });

    test('login → AuthLoading → AuthAuthenticated on success', () async {
      final states = <AuthState>[];
      notifier.addListener(states.add);

      when(() => mockRepo.login('test@yazihanem.com', 'password123'))
          .thenAnswer((_) async => testUser);

      await notifier.login('test@yazihanem.com', 'password123');

      // Should have gone through: AuthLoading → AuthAuthenticated
      expect(states.whereType<AuthLoading>().length, 1);
      expect(notifier.state, isA<AuthAuthenticated>());
    });

    test('login → AuthLoading → AuthError on failure', () async {
      when(() => mockRepo.login(any(), any()))
          .thenThrow(Exception('Invalid credentials'));

      await notifier.login('wrong@email.com', 'wrong');

      expect(notifier.state, isA<AuthError>());
      expect((notifier.state as AuthError).message,
          contains('Invalid credentials'));
    });

    test('logout → AuthUnauthenticated', () async {
      // First login
      when(() => mockRepo.login(any(), any()))
          .thenAnswer((_) async => testUser);
      await notifier.login('test@yazihanem.com', 'password123');
      expect(notifier.state, isA<AuthAuthenticated>());

      // Then logout
      when(() => mockRepo.logout()).thenAnswer((_) async {});
      await notifier.logout();

      expect(notifier.state, isA<AuthUnauthenticated>());
      verify(() => mockRepo.logout()).called(1);
    });

    test('changePassword → AuthUnauthenticated with reason', () async {
      when(() => mockRepo.changePassword('old', 'new12345'))
          .thenAnswer((_) async {});

      await notifier.changePassword('old', 'new12345');

      expect(notifier.state, isA<AuthUnauthenticated>());
      expect((notifier.state as AuthUnauthenticated).reason,
          contains('Şifre değiştirildi'));
    });

    test('changePassword → AuthError on failure', () async {
      when(() => mockRepo.changePassword(any(), any()))
          .thenThrow(Exception('Current password is incorrect'));

      await notifier.changePassword('wrong', 'new12345');

      expect(notifier.state, isA<AuthError>());
    });

    test('setTenantDomain delegates to repository', () async {
      when(() => mockRepo.saveTenantDomain('test.yazihanem.com'))
          .thenAnswer((_) async {});

      await notifier.setTenantDomain('test.yazihanem.com');

      verify(() => mockRepo.saveTenantDomain('test.yazihanem.com')).called(1);
    });

    test('hasTenantDomain delegates to repository', () async {
      when(() => mockRepo.hasTenantDomain())
          .thenAnswer((_) async => true);

      final result = await notifier.hasTenantDomain();
      expect(result, true);
    });
  });
}
