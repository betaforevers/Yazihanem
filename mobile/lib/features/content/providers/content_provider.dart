import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/core/config/app_config.dart';
import 'package:yazihanem_mobile/features/content/data/content_remote_source.dart';
import 'package:yazihanem_mobile/features/content/data/content_repository.dart';
import 'package:yazihanem_mobile/features/content/domain/models/content_model.dart';

/// Provider for [ContentRemoteSource].
final contentRemoteSourceProvider = Provider<ContentRemoteSource>((ref) {
  return ContentRemoteSource(ref.watch(apiClientProvider));
});

/// Provider for [ContentRepository].
/// In dev mode, enables mock data for UI testing.
final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return ContentRepository(
    remoteSource: ref.watch(contentRemoteSourceProvider),
    useMock: config.environment == AppEnvironment.dev,
  );
});

/// Content list state.
class ContentListState {
  final List<ContentModel> items;
  final bool isLoading;
  final String? error;
  final String? statusFilter;
  final int currentPage;
  final bool hasMore;

  const ContentListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.currentPage = 1,
    this.hasMore = true,
  });

  ContentListState copyWith({
    List<ContentModel>? items,
    bool? isLoading,
    String? error,
    String? statusFilter,
    int? currentPage,
    bool? hasMore,
  }) {
    return ContentListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Content list provider — manages list + filtering + pagination.
final contentListProvider =
    StateNotifierProvider<ContentListNotifier, ContentListState>((ref) {
  return ContentListNotifier(ref.watch(contentRepositoryProvider));
});

class ContentListNotifier extends StateNotifier<ContentListState> {
  final ContentRepository _repository;

  ContentListNotifier(this._repository) : super(const ContentListState());

  /// Load first page of content.
  Future<void> loadContent({String? statusFilter}) async {
    state = state.copyWith(
      isLoading: true,
      statusFilter: statusFilter,
      currentPage: 1,
    );

    try {
      final response = await _repository.listContent(
        status: statusFilter,
        page: 1,
      );
      state = state.copyWith(
        items: response.contents,
        isLoading: false,
        hasMore: response.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load next page (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;

    try {
      final response = await _repository.listContent(
        status: state.statusFilter,
        page: nextPage,
      );
      state = state.copyWith(
        items: [...state.items, ...response.contents],
        isLoading: false,
        currentPage: nextPage,
        hasMore: response.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Delete content and refresh list.
  Future<void> deleteContent(String id) async {
    await _repository.deleteContent(id);
    state = state.copyWith(
      items: state.items.where((c) => c.id != id).toList(),
    );
  }

  /// Publish content and update in list.
  Future<ContentModel> publishContent(String id) async {
    final published = await _repository.publishContent(id);
    final updatedItems = state.items.map((c) {
      return c.id == id ? published : c;
    }).toList();
    state = state.copyWith(items: updatedItems);
    return published;
  }

  /// Refresh after create/edit.
  Future<void> refresh() => loadContent(statusFilter: state.statusFilter);
}

/// Single content detail provider (family by ID).
final contentDetailProvider =
    FutureProvider.family<ContentModel, String>((ref, id) {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getContent(id);
});
