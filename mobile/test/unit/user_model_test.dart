import 'package:flutter_test/flutter_test.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';

void main() {
  group('UserModel', () {
    const sampleJson = {
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'email': 'test@yazihanem.com',
      'first_name': 'Bedirhan',
      'last_name': 'Kayaalti',
      'role': 'admin',
      'tenant': 'test-tenant',
    };

    test('fromJson creates correct model', () {
      final user = UserModel.fromJson(sampleJson);

      expect(user.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(user.email, 'test@yazihanem.com');
      expect(user.firstName, 'Bedirhan');
      expect(user.lastName, 'Kayaalti');
      expect(user.role, UserRole.admin);
      expect(user.tenant, 'test-tenant');
    });

    test('toJson produces correct map', () {
      final user = UserModel.fromJson(sampleJson);
      final json = user.toJson();

      expect(json['id'], sampleJson['id']);
      expect(json['email'], sampleJson['email']);
      expect(json['first_name'], sampleJson['first_name']);
      expect(json['last_name'], sampleJson['last_name']);
      expect(json['role'], 'admin');
      expect(json['tenant'], sampleJson['tenant']);
    });

    test('fullName combines first and last name', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.fullName, 'Bedirhan Kayaalti');
    });

    test('fullName handles empty lastName', () {
      final user = UserModel.fromJson({
        ...sampleJson,
        'last_name': '',
      });
      expect(user.fullName, 'Bedirhan');
    });

    test('isAdmin returns true for admin role', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.isAdmin, true);
      expect(user.isEditor, true); // admin can also edit
    });

    test('isEditor returns true for editor role', () {
      final user = UserModel.fromJson({
        ...sampleJson,
        'role': 'editor',
      });
      expect(user.isAdmin, false);
      expect(user.isEditor, true);
    });

    test('viewer has no admin or editor access', () {
      final user = UserModel.fromJson({
        ...sampleJson,
        'role': 'viewer',
      });
      expect(user.isAdmin, false);
      expect(user.isEditor, false);
    });

    test('copyWith creates modified copy', () {
      final user = UserModel.fromJson(sampleJson);
      final modified = user.copyWith(email: 'new@yazihanem.com');

      expect(modified.email, 'new@yazihanem.com');
      expect(modified.firstName, user.firstName); // unchanged
      expect(modified.id, user.id); // unchanged
    });

    test('equality works correctly', () {
      final user1 = UserModel.fromJson(sampleJson);
      final user2 = UserModel.fromJson(sampleJson);
      expect(user1, equals(user2));
    });

    test('fromJson handles missing fields gracefully', () {
      final user = UserModel.fromJson({
        'id': 'test-id',
        'email': 'test@test.com',
      });

      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.role, UserRole.viewer); // defaults to viewer
      expect(user.tenant, '');
    });
  });

  group('UserRole', () {
    test('fromString parses valid roles', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('editor'), UserRole.editor);
      expect(UserRole.fromString('viewer'), UserRole.viewer);
    });

    test('fromString is case-insensitive', () {
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('Editor'), UserRole.editor);
    });

    test('fromString defaults to viewer for unknown roles', () {
      expect(UserRole.fromString('unknown'), UserRole.viewer);
      expect(UserRole.fromString(''), UserRole.viewer);
    });
  });
}
