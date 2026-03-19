import 'package:flutter/foundation.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';

@immutable
class AppUserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool isActive;
  final String tenant;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AppUserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    required this.tenant,
    required this.createdAt,
    this.lastLoginAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => role == UserRole.admin;

  factory AppUserModel.fromJson(Map<String, dynamic> json) => AppUserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        role: UserRole.fromString(json['role'] as String? ?? 'viewer'),
        isActive: json['is_active'] as bool? ?? true,
        tenant: json['tenant'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now(),
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.tryParse(json['last_login_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'role': role.name,
        'is_active': isActive,
        'tenant': tenant,
        'created_at': createdAt.toIso8601String(),
        if (lastLoginAt != null)
          'last_login_at': lastLoginAt!.toIso8601String(),
      };

  AppUserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    bool? isActive,
    String? tenant,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) =>
      AppUserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        tenant: tenant ?? this.tenant,
        createdAt: createdAt ?? this.createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      );
}
