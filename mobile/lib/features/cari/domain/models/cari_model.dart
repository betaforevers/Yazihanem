import 'package:flutter/foundation.dart';

/// Cari (current account / merchant) model.
@immutable
class CariModel {
  final String id;
  final String tenantId;
  final String kod;
  final String unvan;
  final String vergiNo;
  final String vergiDairesi;
  final String? telefon;
  final String? adres;
  final bool eFaturaMukellef;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CariModel({
    required this.id,
    required this.tenantId,
    required this.kod,
    required this.unvan,
    required this.vergiNo,
    required this.vergiDairesi,
    this.telefon,
    this.adres,
    this.eFaturaMukellef = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CariModel.fromJson(Map<String, dynamic> json) => CariModel(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        kod: json['kod'] as String,
        unvan: json['unvan'] as String,
        vergiNo: json['vergi_no'] as String,
        vergiDairesi: json['vergi_dairesi'] as String,
        telefon: json['telefon'] as String?,
        adres: json['adres'] as String?,
        eFaturaMukellef: json['e_fatura_mukellef'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenant_id': tenantId,
        'kod': kod,
        'unvan': unvan,
        'vergi_no': vergiNo,
        'vergi_dairesi': vergiDairesi,
        'telefon': telefon,
        'adres': adres,
        'e_fatura_mukellef': eFaturaMukellef,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  CariModel copyWith({
    String? id,
    String? tenantId,
    String? kod,
    String? unvan,
    String? vergiNo,
    String? vergiDairesi,
    String? telefon,
    String? adres,
    bool? eFaturaMukellef,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CariModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      kod: kod ?? this.kod,
      unvan: unvan ?? this.unvan,
      vergiNo: vergiNo ?? this.vergiNo,
      vergiDairesi: vergiDairesi ?? this.vergiDairesi,
      telefon: telefon ?? this.telefon,
      adres: adres ?? this.adres,
      eFaturaMukellef: eFaturaMukellef ?? this.eFaturaMukellef,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CariModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
