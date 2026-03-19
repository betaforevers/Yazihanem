import 'package:flutter/foundation.dart';
import 'package:yazihanem_mobile/features/cari/domain/models/cari_model.dart';
import 'package:yazihanem_mobile/features/fish/domain/models/fish_model.dart';
import 'package:yazihanem_mobile/features/boat/domain/models/boat_model.dart';

/// Auction slip (mezat fişi) model.
@immutable
class AuctionModel {
  final String id;
  final String tenantId;
  final String fisNo;
  final DateTime mezatTarihi;
  final CariModel? cari;
  final List<AuctionItemModel> kalemler;
  final AuctionDurum durum;
  final DateTime createdAt;

  const AuctionModel({
    required this.id,
    required this.tenantId,
    required this.fisNo,
    required this.mezatTarihi,
    this.cari,
    this.kalemler = const [],
    this.durum = AuctionDurum.acik,
    required this.createdAt,
  });

  /// Total amount calculated from items.
  double get toplamTutar =>
      kalemler.fold(0, (sum, item) => sum + item.toplamFiyat);

  /// Number of items.
  int get kalemSayisi => kalemler.length;

  AuctionModel copyWith({
    String? id,
    String? tenantId,
    String? fisNo,
    DateTime? mezatTarihi,
    CariModel? cari,
    bool clearCari = false,
    List<AuctionItemModel>? kalemler,
    AuctionDurum? durum,
    DateTime? createdAt,
  }) {
    return AuctionModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      fisNo: fisNo ?? this.fisNo,
      mezatTarihi: mezatTarihi ?? this.mezatTarihi,
      cari: clearCari ? null : (cari ?? this.cari),
      kalemler: kalemler ?? this.kalemler,
      durum: durum ?? this.durum,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuctionModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Auction item (mezat kalemi) — a single line on the auction slip.
@immutable
class AuctionItemModel {
  final String id;
  final FishModel balik;
  final BoatModel tekne;
  final double miktar;
  final double birimFiyat;

  const AuctionItemModel({
    required this.id,
    required this.balik,
    required this.tekne,
    required this.miktar,
    required this.birimFiyat,
  });

  double get toplamFiyat => miktar * birimFiyat;

  String get ozet =>
      '${balik.tur} — ${tekne.ad} — $miktar ${balik.birimTuru.label} × ₺${birimFiyat.toStringAsFixed(2)}';

  AuctionItemModel copyWith({
    String? id,
    FishModel? balik,
    BoatModel? tekne,
    double? miktar,
    double? birimFiyat,
  }) {
    return AuctionItemModel(
      id: id ?? this.id,
      balik: balik ?? this.balik,
      tekne: tekne ?? this.tekne,
      miktar: miktar ?? this.miktar,
      birimFiyat: birimFiyat ?? this.birimFiyat,
    );
  }
}

/// Auction slip status.
enum AuctionDurum {
  acik('acik'),
  kapali('kapali'),
  faturalandi('faturalandi');

  final String value;
  const AuctionDurum(this.value);

  String get label => switch (this) {
        AuctionDurum.acik => 'Açık',
        AuctionDurum.kapali => 'Kapalı',
        AuctionDurum.faturalandi => 'Faturalandı',
      };
}
