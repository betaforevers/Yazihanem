import 'package:flutter/foundation.dart';

@immutable
class AuditLogModel {
  final String id;
  final String userId;
  final String userEmail;
  final String action; // 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT'
  final String resource; // 'auction', 'cari', 'fish', 'boat', 'user'
  final String? resourceId;
  final String description;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.resource,
    this.resourceId,
    required this.description,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        userEmail: json['user_email'] as String,
        action: json['action'] as String,
        resource: json['resource'] as String,
        resourceId: json['resource_id'] as String?,
        description: json['description'] as String,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now(),
      );
}
