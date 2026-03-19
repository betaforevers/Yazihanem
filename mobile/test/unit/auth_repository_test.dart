import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yazihanem_mobile/core/api/api_exceptions.dart';
import 'package:yazihanem_mobile/features/auth/data/auth_remote_source.dart';
import 'package:yazihanem_mobile/features/auth/data/auth_repository.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';
import 'package:yazihanem_mobile/core/storage/secure_storage.dart';

// ─── Mocks ───

class MockAuthRemoteSource extends Mock implements AuthRemoteSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AuthRepository repository;
  late MockAuthRemoteSource mockRemote;
  late MockSecureStorageService mockStorage;

  const testUser = UserModel(
    id: 'user-123',
    email: 'test@yazihanem.com',
    firstName: 'Test',
    lastName: 'User',
    role: UserRole.editor,
    tenant: 'test-tenant',
  );

  const loginResponse = LoginResponseData(
    accessToken: 'jwt-token-123',
    expiresIn: 900,
    tokenType: 'Bearer',
    user: testUser,
  );

  setUp(() {
    mockRemote = MockAuthRemoteSource();
    mockStorage = MockSecureStorageService();
    repository = AuthRepository(
      remoteSource: mockRemote,
      secureStorage: mockStorage,
    );
  });

  group('login', () {
    test('saves tokens and returns user on success', () async {
      when(() => mockRemote.login('test@yazihanem.com', 'password123'))
          .thenAnswer((_) async => loginResponse);
      when(() => mockStorage.saveAccessToken('jwt-token-123'))
          .thenAnswer((_) async {});
      when(() => mockStorage.saveUserId('user-123'))
          .thenAnswer((_) async {});

      final user = await repository.login('test@yazihanem.com', 'password123');

      expect(user.email, 'test@yazihanem.com');
      expect(user.role, UserRole.editor);
      verify(() => mockStorage.saveAccessToken('jwt-token-123')).called(1);
      verify(() => mockStorage.saveUserId('user-123')).called(1);
    });

    test('throws on invalid credentials', () async {
      when(() => mockRemote.login(any(), any()))
          .thenThrow(const UnauthorizedException());

      expect(
        () => repository.login('wrong@email.com', 'wrong'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('logout', () {
    test('clears storage even if API fails', () async {
      when(() => mockRemote.logout())
          .thenThrow(const NetworkException());
      when(() => mockStorage.clearAll())
          .thenAnswer((_) async {});

      await repository.logout(); // Should not throw

      verify(() => mockStorage.clearAll()).called(1);
    });

    test('calls API and clears storage on success', () async {
      when(() => mockRemote.logout())
          .thenAnswer((_) async {});
      when(() => mockStorage.clearAll())
          .thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockRemote.logout()).called(1);
      verify(() => mockStorage.clearAll()).called(1);
    });
  });

  group('tryAutoLogin', () {
    test('returns null when no token stored', () async {
      when(() => mockStorage.hasToken())
          .thenAnswer((_) async => false);

      final user = await repository.tryAutoLogin();
      expect(user, isNull);
    });

    test('returns user when token is valid', () async {
      when(() => mockStorage.hasToken())
          .thenAnswer((_) async => true);
      when(() => mockRemote.getMe())
          .thenAnswer((_) async => testUser);

      final user = await repository.tryAutoLogin();
      expect(user, equals(testUser));
    });

    test('refreshes token on 401 and retries', () async {
      when(() => mockStorage.hasToken())
          .thenAnswer((_) async => true);

      // First getMe fails with 401
      var callCount = 0;
      when(() => mockRemote.getMe()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw const UnauthorizedException();
        return testUser;
      });

      when(() => mockRemote.refreshToken()).thenAnswer(
        (_) async => const RefreshResponseData(
          accessToken: 'new-token',
          expiresIn: 900,
          tokenType: 'Bearer',
        ),
      );
      when(() => mockStorage.saveAccessToken('new-token'))
          .thenAnswer((_) async {});

      final user = await repository.tryAutoLogin();

      expect(user, equals(testUser));
      verify(() => mockStorage.saveAccessToken('new-token')).called(1);
    });

    test('returns null when both token and refresh fail', () async {
      when(() => mockStorage.hasToken())
          .thenAnswer((_) async => true);
      when(() => mockRemote.getMe())
          .thenThrow(const UnauthorizedException());
      when(() => mockRemote.refreshToken())
          .thenThrow(const UnauthorizedException());
      when(() => mockStorage.clearAll())
          .thenAnswer((_) async {});

      final user = await repository.tryAutoLogin();

      expect(user, isNull);
      verify(() => mockStorage.clearAll()).called(1);
    });
  });

  group('changePassword', () {
    test('calls API and clears storage', () async {
      when(() => mockRemote.changePassword('old123', 'new12345'))
          .thenAnswer((_) async {});
      when(() => mockStorage.clearAll())
          .thenAnswer((_) async {});

      await repository.changePassword('old123', 'new12345');

      verify(() => mockRemote.changePassword('old123', 'new12345')).called(1);
      verify(() => mockStorage.clearAll()).called(1);
    });
  });

  group('tenant domain', () {
    test('saveTenantDomain delegates to storage', () async {
      when(() => mockStorage.saveTenantDomain('test.yazihanem.com'))
          .thenAnswer((_) async {});

      await repository.saveTenantDomain('test.yazihanem.com');

      verify(() => mockStorage.saveTenantDomain('test.yazihanem.com')).called(1);
    });

    test('hasTenantDomain returns true when domain exists', () async {
      when(() => mockStorage.getTenantDomain())
          .thenAnswer((_) async => 'test.yazihanem.com');

      expect(await repository.hasTenantDomain(), true);
    });

    test('hasTenantDomain returns false when empty', () async {
      when(() => mockStorage.getTenantDomain())
          .thenAnswer((_) async => null);

      expect(await repository.hasTenantDomain(), false);
    });
  });
}
