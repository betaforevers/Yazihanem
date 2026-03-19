import 'package:flutter/foundation.dart';

/// Fish model for the fish auction system.
///
/// Each yazıhane registers fish types with quantity.
/// Quantity can be in pieces (adet), grams, or kilograms.
@immutable
class FishModel {
  final String id;
  final String tenantId;
  final String tur;
  final UnitType birimTuru;
  final double miktar;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FishModel({
    required this.id,
    required this.tenantId,
    required this.tur,
    required this.birimTuru,
    required this.miktar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FishModel.fromJson(Map<String, dynamic> json) {
    return FishModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? '',
      tur: json['tur'] as String,
      birimTuru: UnitType.fromString(json['birim_turu'] as String? ?? 'kilogram'),
      miktar: (json['miktar'] as num?)?.toDouble() ?? 0,
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
        'tur': tur,
        'birim_turu': birimTuru.value,
        'miktar': miktar,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Display-friendly quantity with unit.
  String get miktarLabel {
    final formatted = miktar == miktar.roundToDouble()
        ? miktar.toInt().toString()
        : miktar.toStringAsFixed(1);
    return '$formatted ${birimTuru.label}';
  }

  FishModel copyWith({
    String? id,
    String? tenantId,
    String? tur,
    UnitType? birimTuru,
    double? miktar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FishModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tur: tur ?? this.tur,
      birimTuru: birimTuru ?? this.birimTuru,
      miktar: miktar ?? this.miktar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FishModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Quantity unit type.
enum UnitType {
  adet('adet'),
  gram('gram'),
  kilogram('kilogram');

  final String value;
  const UnitType(this.value);

  static UnitType fromString(String value) {
    return UnitType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => UnitType.kilogram,
    );
  }

  String get label {
    return switch (this) {
      UnitType.adet => 'Adet',
      UnitType.gram => 'gr',
      UnitType.kilogram => 'kg',
    };
  }
}
