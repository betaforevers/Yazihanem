import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/fish/domain/models/fish_model.dart';
import 'package:yazihanem_mobile/features/fish/presentation/widgets/fish_card.dart';
import 'package:yazihanem_mobile/features/fish/providers/fish_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/widgets/shimmer_list.dart';

/// Fish list screen with search, delete, and FAB.
class FishListScreen extends ConsumerStatefulWidget {
  const FishListScreen({super.key});

  @override
  ConsumerState<FishListScreen> createState() => _FishListScreenState();
}

class _FishListScreenState extends ConsumerState<FishListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fishListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fishListProvider);
    final List<FishModel> filtered = _searchQuery.isEmpty
        ? state.items
        : state.items
            .where((f) =>
                f.tur.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Balıklar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Balık türü ara...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(fishListProvider.notifier).load(),
        color: AppColors.primary,
        child: _buildBody(state, filtered),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/fish/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Balık Ekle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody(FishListState state, List<FishModel> filtered) {
    if (state.isLoading && state.items.isEmpty) {
      return const ShimmerList(itemCount: 6, itemHeight: 80);
    }

    if (state.error != null && state.items.isEmpty) {
      return ErrorRetryWidget(
        message: 'Balıklar yüklenemedi\n${state.error}',
        onRetry: () => ref.read(fishListProvider.notifier).load(),
      );
    }

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.set_meal_rounded,
        message: _searchQuery.isEmpty ? 'Henüz balık kaydı yok' : '"$_searchQuery" için sonuç bulunamadı',
        actionLabel: _searchQuery.isEmpty ? 'Balık Ekle' : null,
        onAction: _searchQuery.isEmpty ? () => context.go('/fish/new') : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final fish = filtered[index];
        return FishCard(
          fish: fish,
          onTap: () => context.go('/fish/${fish.id}/edit'),
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Balığı Sil'),
                content: Text('${fish.tur} silinecek. Emin misiniz?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(fishListProvider.notifier).delete(fish.id);
            }
          },
        );
      },
    );
  }
}
