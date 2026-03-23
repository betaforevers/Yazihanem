import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/core/config/app_config.dart';
import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/core/storage/local_db.dart';
import 'package:yazihanem_mobile/features/fish/data/fish_repository.dart';
import 'package:yazihanem_mobile/features/fish/domain/models/fish_model.dart';

final fishRepositoryProvider = Provider<FishRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final db = ref.watch(localDbProvider);
  return FishRepository(useMock: config.environment == AppEnvironment.dev, db: db);
});

class FishListState {
  final List<FishModel> items;
  final bool isLoading;
  final String? error;

  const FishListState({this.items = const [], this.isLoading = false, this.error});

  FishListState copyWith({List<FishModel>? items, bool? isLoading, String? error}) {
    return FishListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final fishListProvider =
    StateNotifierProvider<FishListNotifier, FishListState>((ref) {
  return FishListNotifier(ref.watch(fishRepositoryProvider));
});

class FishListNotifier extends StateNotifier<FishListState> {
  final FishRepository _repository;

  FishListNotifier(this._repository) : super(const FishListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.listAll();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> create({
    required String tur,
    required UnitType birimTuru,
    required double miktar,
  }) async {
    await _repository.create(tur: tur, birimTuru: birimTuru, miktar: miktar);
    await load();
  }

  Future<void> update(String id, {String? tur, UnitType? birimTuru, double? miktar}) async {
    await _repository.update(id, tur: tur, birimTuru: birimTuru, miktar: miktar);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = state.copyWith(items: state.items.where((f) => f.id != id).toList());
  }
}
