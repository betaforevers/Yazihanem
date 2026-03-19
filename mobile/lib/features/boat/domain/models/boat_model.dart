import 'package:flutter/foundation.dart';

/// Boat model for the fish auction system.
///
/// Each yazıhane registers boats with a commission percentage.
@immutable
class BoatModel {
  final String id;
  final String tenantId;
  final String ad;
  final double komisyonYuzde;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BoatModel({
    required this.id,
    required this.tenantId,
    required this.ad,
    required this.komisyonYuzde,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BoatModel.fromJson(Map<String, dynamic> json) {
    return BoatModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? '',
      ad: json['ad'] as String,
      komisyonYuzde: (json['komisyon_yuzde'] as num?)?.toDouble() ?? 0,
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
        'ad': ad,
        'komisyon_yuzde': komisyonYuzde,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  String get komisyonLabel => '%${komisyonYuzde.toStringAsFixed(1)}';

  BoatModel copyWith({
    String? id,
    String? tenantId,
    String? ad,
    double? komisyonYuzde,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BoatModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      ad: ad ?? this.ad,
      komisyonYuzde: komisyonYuzde ?? this.komisyonYuzde,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoatModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
