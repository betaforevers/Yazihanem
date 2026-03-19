import 'package:yazihanem_mobile/features/boat/domain/models/boat_model.dart';

/// Boat data repository with mock data for dev mode.
class BoatRepository {
  final bool useMock;

  BoatRepository({this.useMock = false});

  static final _mockBoats = <BoatModel>[
    BoatModel(id: 'b1', tenantId: 'dev', ad: 'Karadeniz Yıldızı', komisyonYuzde: 8, createdAt: DateTime.now().subtract(const Duration(days: 10)), updatedAt: DateTime.now().subtract(const Duration(days: 10))),
    BoatModel(id: 'b2', tenantId: 'dev', ad: 'Mavi Dalga', komisyonYuzde: 10, createdAt: DateTime.now().subtract(const Duration(days: 7)), updatedAt: DateTime.now().subtract(const Duration(days: 7))),
    BoatModel(id: 'b3', tenantId: 'dev', ad: 'Rüzgar', komisyonYuzde: 7.5, createdAt: DateTime.now().subtract(const Duration(days: 5)), updatedAt: DateTime.now().subtract(const Duration(days: 5))),
    BoatModel(id: 'b4', tenantId: 'dev', ad: 'Deniz Kızı', komisyonYuzde: 12, createdAt: DateTime.now().subtract(const Duration(days: 3)), updatedAt: DateTime.now().subtract(const Duration(days: 3))),
    BoatModel(id: 'b5', tenantId: 'dev', ad: 'Fırtına', komisyonYuzde: 9, createdAt: DateTime.now().subtract(const Duration(days: 1)), updatedAt: DateTime.now().subtract(const Duration(days: 1))),
  ];

  int _mockIdCounter = 100;

  Future<List<BoatModel>> listAll() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return List.from(_mockBoats);
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<BoatModel> getById(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockBoats.firstWhere((b) => b.id == id);
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<BoatModel> create({required String ad, required double komisyonYuzde}) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      _mockIdCounter++;
      final boat = BoatModel(
        id: 'b-$_mockIdCounter',
        tenantId: 'dev',
        ad: ad,
        komisyonYuzde: komisyonYuzde,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockBoats.insert(0, boat);
      return boat;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<BoatModel> update(String id, {String? ad, double? komisyonYuzde}) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _mockBoats.indexWhere((b) => b.id == id);
      if (index == -1) throw Exception('Tekne bulunamadı');
      final updated = _mockBoats[index].copyWith(
        ad: ad,
        komisyonYuzde: komisyonYuzde,
        updatedAt: DateTime.now(),
      );
      _mockBoats[index] = updated;
      return updated;
    }
    throw UnimplementedError('Backend API not yet available');
  }

  Future<void> delete(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockBoats.removeWhere((b) => b.id == id);
      return;
    }
    throw UnimplementedError('Backend API not yet available');
  }
}
