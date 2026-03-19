import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/boat/presentation/widgets/boat_card.dart';
import 'package:yazihanem_mobile/features/boat/providers/boat_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Boat list screen with FAB and delete.
class BoatListScreen extends ConsumerStatefulWidget {
  const BoatListScreen({super.key});

  @override
  ConsumerState<BoatListScreen> createState() => _BoatListScreenState();
}

class _BoatListScreenState extends ConsumerState<BoatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boatListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boatListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Tekneler')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(boatListProvider.notifier).load(),
        color: AppColors.primary,
        child: _buildBody(state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/boat/new'),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tekne Ekle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody(BoatListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sailing_rounded,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('Henüz tekne kaydı yok',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final boat = state.items[index];
        return BoatCard(
          boat: boat,
          onTap: () => context.go('/boat/${boat.id}/edit'),
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Tekneyi Sil'),
                content: Text('${boat.ad} silinecek. Emin misiniz?'),
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
              ref.read(boatListProvider.notifier).delete(boat.id);
            }
          },
        );
      },
    );
  }
}
