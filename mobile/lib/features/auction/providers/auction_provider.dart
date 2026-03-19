import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/core/config/app_config.dart';
import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/features/auction/data/auction_repository.dart';
import 'package:yazihanem_mobile/features/auction/domain/models/auction_model.dart';
import 'package:yazihanem_mobile/features/cari/domain/models/cari_model.dart';
import 'package:yazihanem_mobile/features/fish/domain/models/fish_model.dart';
import 'package:yazihanem_mobile/features/boat/domain/models/boat_model.dart';

final auctionRepositoryProvider = Provider<AuctionRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return AuctionRepository(useMock: config.environment == AppEnvironment.dev);
});

class AuctionListState {
  final List<AuctionModel> items;
  final bool isLoading;
  final String? error;

  const AuctionListState({this.items = const [], this.isLoading = false, this.error});

  AuctionListState copyWith({List<AuctionModel>? items, bool? isLoading, String? error}) {
    return AuctionListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final auctionListProvider =
    StateNotifierProvider<AuctionListNotifier, AuctionListState>((ref) {
  return AuctionListNotifier(ref.watch(auctionRepositoryProvider));
});

class AuctionListNotifier extends StateNotifier<AuctionListState> {
  final AuctionRepository _repository;

  AuctionListNotifier(this._repository) : super(const AuctionListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.listAll();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<AuctionModel> create() async {
    final auction = await _repository.create();
    await load();
    return auction;
  }

  Future<void> addItem(
    String auctionId, {
    required FishModel balik,
    required BoatModel tekne,
    required double miktar,
    required double birimFiyat,
  }) async {
    await _repository.addItem(auctionId,
        balik: balik, tekne: tekne, miktar: miktar, birimFiyat: birimFiyat);
    await load();
  }

  Future<void> removeItem(String auctionId, String itemId) async {
    await _repository.removeItem(auctionId, itemId);
    await load();
  }

  Future<void> closeAuction(String auctionId) async {
    await _repository.close(auctionId);
    await load();
  }

  Future<void> assignCari(String auctionId, CariModel? cari) async {
    await _repository.assignCari(auctionId, cari);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = state.copyWith(items: state.items.where((a) => a.id != id).toList());
  }
}
