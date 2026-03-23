import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/core/config/app_config.dart';
import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/core/storage/local_db.dart';
import 'package:yazihanem_mobile/features/boat/data/boat_repository.dart';
import 'package:yazihanem_mobile/features/boat/domain/models/boat_model.dart';

final boatRepositoryProvider = Provider<BoatRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final db = ref.watch(localDbProvider);
  return BoatRepository(useMock: config.environment == AppEnvironment.dev, db: db);
});

class BoatListState {
  final List<BoatModel> items;
  final bool isLoading;
  final String? error;

  const BoatListState({this.items = const [], this.isLoading = false, this.error});

  BoatListState copyWith({List<BoatModel>? items, bool? isLoading, String? error}) {
    return BoatListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final boatListProvider =
    StateNotifierProvider<BoatListNotifier, BoatListState>((ref) {
  return BoatListNotifier(ref.watch(boatRepositoryProvider));
});

class BoatListNotifier extends StateNotifier<BoatListState> {
  final BoatRepository _repository;

  BoatListNotifier(this._repository) : super(const BoatListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.listAll();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> create({required String ad, required double komisyonYuzde}) async {
    await _repository.create(ad: ad, komisyonYuzde: komisyonYuzde);
    await load();
  }

  Future<void> update(String id, {String? ad, double? komisyonYuzde}) async {
    await _repository.update(id, ad: ad, komisyonYuzde: komisyonYuzde);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = state.copyWith(items: state.items.where((b) => b.id != id).toList());
  }
}
