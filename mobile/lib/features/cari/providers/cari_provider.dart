import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/core/config/app_config.dart';
import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/core/storage/local_db.dart';
import 'package:yazihanem_mobile/features/cari/data/cari_repository.dart';
import 'package:yazihanem_mobile/features/cari/domain/models/cari_model.dart';

final cariRepositoryProvider = Provider<CariRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final db = ref.watch(localDbProvider);
  return CariRepository(useMock: config.environment == AppEnvironment.dev, db: db);
});

class CariListState {
  final List<CariModel> items;
  final bool isLoading;
  final String? error;

  const CariListState({this.items = const [], this.isLoading = false, this.error});

  CariListState copyWith({List<CariModel>? items, bool? isLoading, String? error}) {
    return CariListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final cariListProvider =
    StateNotifierProvider<CariListNotifier, CariListState>((ref) {
  return CariListNotifier(ref.watch(cariRepositoryProvider));
});

class CariListNotifier extends StateNotifier<CariListState> {
  final CariRepository _repository;

  CariListNotifier(this._repository) : super(const CariListState());

  Future<void> load({bool activeOnly = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repository.listAll(activeOnly: activeOnly);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CariModel> create({
    required String unvan,
    required String vergiNo,
    required String vergiDairesi,
    String? telefon,
    String? adres,
    bool eFaturaMukellef = false,
  }) async {
    final cari = await _repository.create(
      unvan: unvan,
      vergiNo: vergiNo,
      vergiDairesi: vergiDairesi,
      telefon: telefon,
      adres: adres,
      eFaturaMukellef: eFaturaMukellef,
    );
    await load();
    return cari;
  }

  Future<void> update(
    String id, {
    String? unvan,
    String? vergiNo,
    String? vergiDairesi,
    String? telefon,
    String? adres,
    bool? eFaturaMukellef,
    bool? isActive,
  }) async {
    await _repository.update(
      id,
      unvan: unvan,
      vergiNo: vergiNo,
      vergiDairesi: vergiDairesi,
      telefon: telefon,
      adres: adres,
      eFaturaMukellef: eFaturaMukellef,
      isActive: isActive,
    );
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = state.copyWith(items: state.items.where((c) => c.id != id).toList());
  }
}
