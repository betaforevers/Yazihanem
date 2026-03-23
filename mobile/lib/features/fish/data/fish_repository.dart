import 'dart:async';
import 'package:yazihanem_mobile/core/storage/local_db.dart';
import 'package:yazihanem_mobile/features/fish/domain/models/fish_model.dart';

/// Fish data repository with mock data for dev mode.
class FishRepository {
  final bool useMock;
  final LocalDbService? _db;

  FishRepository({this.useMock = false, LocalDbService? db}) : _db = db;

  static final _mockFishes = <FishModel>[
    FishModel(id: 'f1', tenantId: 'dev', tur: 'Çipura', birimTuru: UnitType.kilogram, miktar: 50, createdAt: DateTime.now().subtract(const Duration(days: 3)), updatedAt: DateTime.now().subtract(const Duration(days: 3))),
    FishModel(id: 'f2', tenantId: 'dev', tur: 'Levrek', birimTuru: UnitType.kilogram, miktar: 30, createdAt: DateTime.now().subtract(const Duration(days: 2)), updatedAt: DateTime.now().subtract(const Duration(days: 2))),
    FishModel(id: 'f3', tenantId: 'dev', tur: 'Hamsi', birimTuru: UnitType.kilogram, miktar: 200, createdAt: DateTime.now().subtract(const Duration(days: 1)), updatedAt: DateTime.now().subtract(const Duration(days: 1))),
    FishModel(id: 'f4', tenantId: 'dev', tur: 'Palamut', birimTuru: UnitType.adet, miktar: 150, createdAt: DateTime.now().subtract(const Duration(hours: 12)), updatedAt: DateTime.now().subtract(const Duration(hours: 12))),
    FishModel(id: 'f5', tenantId: 'dev', tur: 'Lüfer', birimTuru: UnitType.adet, miktar: 80, createdAt: DateTime.now().subtract(const Duration(hours: 6)), updatedAt: DateTime.now().subtract(const Duration(hours: 6))),
    FishModel(id: 'f6', tenantId: 'dev', tur: 'Sardalya', birimTuru: UnitType.kilogram, miktar: 100, createdAt: DateTime.now().subtract(const Duration(hours: 3)), updatedAt: DateTime.now().subtract(const Duration(hours: 3))),
    FishModel(id: 'f7', tenantId: 'dev', tur: 'Mezgit', birimTuru: UnitType.kilogram, miktar: 25, createdAt: DateTime.now().subtract(const Duration(hours: 1)), updatedAt: DateTime.now().subtract(const Duration(hours: 1))),
    FishModel(id: 'f8', tenantId: 'dev', tur: 'Barbunya', birimTuru: UnitType.gram, miktar: 5000, createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];

  int _mockIdCounter = 100;

  Future<List<FishModel>> listAll() async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 300));
        final items = List<FishModel>.from(_mockFishes);
        unawaited(_db?.cacheFishList(items.map((f) => f.toJson()).toList()));
        return items;
      }
      throw UnimplementedError('Backend API not yet available');
    } catch (_) {
      final cached = _db?.getCachedFishList();
      if (cached != null && cached.isNotEmpty) {
        return cached.map(FishModel.fromJson).toList();
      }
      rethrow;
    }
  }

  Future<FishModel> getById(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockFishes.firstWhere((f) => f.id == id);
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<FishModel> create({
    required String tur,
    required UnitType birimTuru,
    required double miktar,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      _mockIdCounter++;
      final fish = FishModel(
        id: 'f-$_mockIdCounter',
        tenantId: 'dev',
        tur: tur,
        birimTuru: birimTuru,
        miktar: miktar,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockFishes.insert(0, fish);
      return fish;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<FishModel> update(String id, {
    String? tur,
    UnitType? birimTuru,
    double? miktar,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _mockFishes.indexWhere((f) => f.id == id);
      if (index == -1) throw Exception('Balık bulunamadı');
      final updated = _mockFishes[index].copyWith(
        tur: tur,
        birimTuru: birimTuru,
        miktar: miktar,
        updatedAt: DateTime.now(),
      );
      _mockFishes[index] = updated;
      return updated;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<void> delete(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockFishes.removeWhere((f) => f.id == id);
      return;
    }
    throw UnimplementedError('Backend API not yet available');
  }
}
