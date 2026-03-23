import 'dart:async';
import 'package:yazihanem_mobile/core/storage/local_db.dart';
import 'package:yazihanem_mobile/features/cari/domain/models/cari_model.dart';

/// Cari (merchant) data repository with mock data for dev mode.
class CariRepository {
  final bool useMock;
  final LocalDbService? _db;

  CariRepository({this.useMock = false, LocalDbService? db}) : _db = db;

  static final _mockCariler = <CariModel>[
    CariModel(
      id: 'c1',
      tenantId: 'dev',
      kod: 'C0001',
      unvan: 'Ahmet Balıkçılık Ltd. Şti.',
      vergiNo: '1234567890',
      vergiDairesi: 'Trabzon VD',
      telefon: '0462 555 11 22',
      adres: 'Trabzon Balık Hali, No:12, Trabzon',
      eFaturaMukellef: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    CariModel(
      id: 'c2',
      tenantId: 'dev',
      kod: 'C0002',
      unvan: 'Karadeniz Su Ürünleri A.Ş.',
      vergiNo: '9876543210',
      vergiDairesi: 'Rize VD',
      telefon: '0464 333 44 55',
      adres: 'Rize Merkez, Sahil Cad. No:7',
      eFaturaMukellef: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    CariModel(
      id: 'c3',
      tenantId: 'dev',
      kod: 'C0003',
      unvan: 'Mehmet Demir (Şahıs)',
      vergiNo: '55544433320',
      vergiDairesi: 'Samsun VD',
      telefon: '0535 777 88 99',
      adres: 'Samsun Balık Pazarı, No:3',
      eFaturaMukellef: false,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    CariModel(
      id: 'c4',
      tenantId: 'dev',
      kod: 'C0004',
      unvan: 'Doğu Karadeniz Gıda San.',
      vergiNo: '1122334455',
      vergiDairesi: 'Giresun VD',
      telefon: '0454 211 33 44',
      adres: 'Giresun, Sahil Bulvarı No:21',
      eFaturaMukellef: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    CariModel(
      id: 'c5',
      tenantId: 'dev',
      kod: 'C0005',
      unvan: 'Mavi Okyanus Pazarlama',
      vergiNo: '6677889900',
      vergiDairesi: 'Ordu VD',
      telefon: '0452 100 22 33',
      adres: 'Ordu, Liman Mah. No:5',
      eFaturaMukellef: false,
      isActive: false,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  int _mockIdCounter = 100;

  Future<List<CariModel>> listAll({bool activeOnly = false}) async {
    try {
      if (useMock) {
        await Future.delayed(const Duration(milliseconds: 300));
        final list = List<CariModel>.from(_mockCariler);
        unawaited(_db?.cacheCariList(list.map((c) => c.toJson()).toList()));
        if (activeOnly) return list.where((c) => c.isActive).toList();
        return list;
      }
      throw UnimplementedError('Backend API not yet available');
    } catch (_) {
      final cached = _db?.getCachedCariList();
      if (cached != null && cached.isNotEmpty) {
        final list = cached.map(CariModel.fromJson).toList();
        if (activeOnly) return list.where((c) => c.isActive).toList();
        return list;
      }
      rethrow;
    }
  }

  Future<CariModel> getById(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockCariler.firstWhere((c) => c.id == id,
          orElse: () => throw Exception('Cari bulunamadı'));
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<CariModel> create({
    required String unvan,
    required String vergiNo,
    required String vergiDairesi,
    String? telefon,
    String? adres,
    bool eFaturaMukellef = false,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      _mockIdCounter++;
      final nextKod = 'C${_mockIdCounter.toString().padLeft(4, '0')}';
      final cari = CariModel(
        id: 'c-$_mockIdCounter',
        tenantId: 'dev',
        kod: nextKod,
        unvan: unvan,
        vergiNo: vergiNo,
        vergiDairesi: vergiDairesi,
        telefon: telefon,
        adres: adres,
        eFaturaMukellef: eFaturaMukellef,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockCariler.insert(0, cari);
      return cari;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<CariModel> update(
    String id, {
    String? unvan,
    String? vergiNo,
    String? vergiDairesi,
    String? telefon,
    String? adres,
    bool? eFaturaMukellef,
    bool? isActive,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _mockCariler.indexWhere((c) => c.id == id);
      if (index == -1) throw Exception('Cari bulunamadı');
      final updated = _mockCariler[index].copyWith(
        unvan: unvan,
        vergiNo: vergiNo,
        vergiDairesi: vergiDairesi,
        telefon: telefon,
        adres: adres,
        eFaturaMukellef: eFaturaMukellef,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      _mockCariler[index] = updated;
      return updated;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<void> delete(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockCariler.removeWhere((c) => c.id == id);
      return;
    }
    throw UnimplementedError('Backend API not yet available');
  }
}
