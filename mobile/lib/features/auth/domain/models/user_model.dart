import 'package:flutter/foundation.dart';

/// User model matching backend auth response.
///
/// Backend login response `user` field:
/// ```json
/// { "id": "uuid", "email": "...", "first_name": "...",
///   "last_name": "...", "role": "admin|editor|viewer", "tenant": "..." }
/// ```
@immutable
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String tenant;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.tenant,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'viewer'),
      tenant: json['tenant'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'role': role.name,
        'tenant': tenant,
      };

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => role == UserRole.admin;
  bool get isEditor => role == UserRole.editor || role == UserRole.admin;

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    String? tenant,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      tenant: tenant ?? this.tenant,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          role == other.role &&
          tenant == other.tenant;

  @override
  int get hashCode => Object.hash(id, email, firstName, lastName, role, tenant);

  @override
  String toString() => 'UserModel(id: $id, email: $email, role: ${role.name})';
}

/// User roles matching backend enum.
enum UserRole {
  admin,
  editor,
  viewer;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => UserRole.viewer,
    );
  }
}
