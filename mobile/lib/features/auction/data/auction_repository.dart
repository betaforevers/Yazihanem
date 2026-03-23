import 'dart:async';
import 'package:yazihanem_mobile/core/storage/local_db.dart';
import 'package:yazihanem_mobile/features/auction/domain/models/auction_model.dart';
import 'package:yazihanem_mobile/features/cari/domain/models/cari_model.dart';
import 'package:yazihanem_mobile/features/fish/domain/models/fish_model.dart';
import 'package:yazihanem_mobile/features/boat/domain/models/boat_model.dart';

/// Auction data repository with mock data for dev mode.
class AuctionRepository {
  final bool useMock;
  final LocalDbService? _db;

  AuctionRepository({this.useMock = false, LocalDbService? db}) : _db = db;

  static final _mockFish = FishModel(
    id: 'f1', tenantId: 'dev', tur: 'Çipura',
    birimTuru: UnitType.kilogram, miktar: 50,
    createdAt: DateTime.now(), updatedAt: DateTime.now(),
  );
  static final _mockBoat = BoatModel(
    id: 'b1', tenantId: 'dev', ad: 'Karadeniz Yıldızı',
    komisyonYuzde: 8,
    createdAt: DateTime.now(), updatedAt: DateTime.now(),
  );

  static final _mockCari1 = CariModel(
    id: 'c1',
    tenantId: 'dev',
    kod: 'C0001',
    unvan: 'Ahmet Balıkçılık Ltd. Şti.',
    vergiNo: '1234567890',
    vergiDairesi: 'Trabzon VD',
    telefon: '0462 555 11 22',
    eFaturaMukellef: true,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final _mockAuctions = <AuctionModel>[
    AuctionModel(
      id: 'a1',
      tenantId: 'dev',
      fisNo: 'MZT-2026-001',
      mezatTarihi: DateTime.now().subtract(const Duration(days: 1)),
      durum: AuctionDurum.kapali,
      cari: _mockCari1,
      kalemler: [
        AuctionItemModel(id: 'ai1', balik: _mockFish, tekne: _mockBoat, miktar: 20, birimFiyat: 150),
        AuctionItemModel(
          id: 'ai2',
          balik: FishModel(id: 'f2', tenantId: 'dev', tur: 'Levrek', birimTuru: UnitType.kilogram, miktar: 30, createdAt: DateTime.now(), updatedAt: DateTime.now()),
          tekne: BoatModel(id: 'b2', tenantId: 'dev', ad: 'Mavi Dalga', komisyonYuzde: 10, createdAt: DateTime.now(), updatedAt: DateTime.now()),
          miktar: 15,
          birimFiyat: 200,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AuctionModel(
      id: 'a2',
      tenantId: 'dev',
      fisNo: 'MZT-2026-002',
      mezatTarihi: DateTime.now(),
      durum: AuctionDurum.acik,
      kalemler: [],
      createdAt: DateTime.now(),
    ),
  ];

  int _mockIdCounter = 100;
  int _mockItemCounter = 200;

  Future<List<AuctionModel>> listAll() async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 300));
        final items = List<AuctionModel>.from(_mockAuctions);
        unawaited(_db?.cacheAuctionList(items.map((a) => a.toJson()).toList()));
        return items;
      }
      throw UnimplementedError('Backend API not yet available');
    } catch (_) {
      final cached = _db?.getCachedAuctionList();
      if (cached != null && cached.isNotEmpty) {
        return cached.map(AuctionModel.fromJson).toList();
      }
      rethrow;
    }
  }

  Future<AuctionModel> getById(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockAuctions.firstWhere((a) => a.id == id);
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<AuctionModel> create() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      _mockIdCounter++;
      final auction = AuctionModel(
        id: 'a-$_mockIdCounter',
        tenantId: 'dev',
        fisNo: 'MZT-2026-${_mockIdCounter.toString().padLeft(3, '0')}',
        mezatTarihi: DateTime.now(),
        kalemler: [],
        durum: AuctionDurum.acik,
        createdAt: DateTime.now(),
      );
      _mockAuctions.insert(0, auction);
      return auction;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<AuctionModel> addItem(
    String auctionId, {
    required FishModel balik,
    required BoatModel tekne,
    required double miktar,
    required double birimFiyat,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockItemCounter++;
      final index = _mockAuctions.indexWhere((a) => a.id == auctionId);
      if (index == -1) throw Exception('Mezat fişi bulunamadı');

      final item = AuctionItemModel(
        id: 'ai-$_mockItemCounter',
        balik: balik,
        tekne: tekne,
        miktar: miktar,
        birimFiyat: birimFiyat,
      );

      final updated = _mockAuctions[index].copyWith(
        kalemler: [..._mockAuctions[index].kalemler, item],
      );
      _mockAuctions[index] = updated;
      return updated;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<AuctionModel> removeItem(String auctionId, String itemId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      final index = _mockAuctions.indexWhere((a) => a.id == auctionId);
      if (index == -1) throw Exception('Mezat fişi bulunamadı');

      final updated = _mockAuctions[index].copyWith(
        kalemler: _mockAuctions[index].kalemler.where((i) => i.id != itemId).toList(),
      );
      _mockAuctions[index] = updated;
      return updated;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<AuctionModel> close(String auctionId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _mockAuctions.indexWhere((a) => a.id == auctionId);
      if (index == -1) throw Exception('Mezat fişi bulunamadı');

      final updated = _mockAuctions[index].copyWith(durum: AuctionDurum.kapali);
      _mockAuctions[index] = updated;
      return updated;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<AuctionModel> assignCari(String auctionId, CariModel? cari) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      final index = _mockAuctions.indexWhere((a) => a.id == auctionId);
      if (index == -1) throw Exception('Mezat fişi bulunamadı');
      final updated = cari != null
          ? _mockAuctions[index].copyWith(cari: cari)
          : _mockAuctions[index].copyWith(clearCari: true);
      _mockAuctions[index] = updated;
      return updated;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<void> delete(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockAuctions.removeWhere((a) => a.id == id);
      return;
    }
    throw UnimplementedError('Backend API not yet available');
  }
}
