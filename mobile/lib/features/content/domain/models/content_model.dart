import 'package:flutter/foundation.dart';

/// Content model matching backend `entity.Content`.
///
/// Backend fields:
/// ```json
/// { "id", "tenant_id", "title", "slug", "body",
///   "status": "draft|published|archived",
///   "author_id", "published_at", "created_at", "updated_at" }
/// ```
@immutable
class ContentModel {
  final String id;
  final String tenantId;
  final String title;
  final String slug;
  final String body;
  final ContentStatus status;
  final String authorId;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentModel({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.slug,
    required this.body,
    required this.status,
    required this.authorId,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? '',
      title: json['title'] as String,
      slug: json['slug'] as String,
      body: json['body'] as String? ?? '',
      status: ContentStatus.fromString(json['status'] as String? ?? 'draft'),
      authorId: json['author_id'] as String? ?? '',
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'title': title,
        'slug': slug,
        'body': body,
        'status': status.value,
        'author_id': authorId,
        'published_at': publishedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Short excerpt from body for list display.
  String get excerpt {
    if (body.length <= 120) return body;
    return '${body.substring(0, 120)}...';
  }

  bool get isDraft => status == ContentStatus.draft;
  bool get isPublished => status == ContentStatus.published;
  bool get isArchived => status == ContentStatus.archived;

  ContentModel copyWith({
    String? id,
    String? tenantId,
    String? title,
    String? slug,
    String? body,
    ContentStatus? status,
    String? authorId,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      body: body ?? this.body,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ContentModel(id: $id, title: $title, status: ${status.value})';
}

/// Content publication status matching backend enum.
enum ContentStatus {
  draft('draft'),
  published('published'),
  archived('archived');

  final String value;
  const ContentStatus(this.value);

  static ContentStatus fromString(String value) {
    return ContentStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ContentStatus.draft,
    );
  }

  String get label {
    return switch (this) {
      ContentStatus.draft => 'Taslak',
      ContentStatus.published => 'Yayında',
      ContentStatus.archived => 'Arşiv',
    };
  }
}
