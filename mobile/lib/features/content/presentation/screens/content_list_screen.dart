import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/content/domain/models/content_model.dart';
import 'package:yazihanem_mobile/features/content/presentation/widgets/content_card.dart';
import 'package:yazihanem_mobile/features/content/providers/content_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Content list screen with filtering, pull-to-refresh, and FAB.
class ContentListScreen extends ConsumerStatefulWidget {
  const ContentListScreen({super.key});

  @override
  ConsumerState<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends ConsumerState<ContentListScreen> {
  ContentStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    // Load content on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentListProvider.notifier).loadContent();
    });
  }

  void _onFilterChanged(ContentStatus? status) {
    setState(() => _selectedFilter = status);
    ref
        .read(contentListProvider.notifier)
        .loadContent(statusFilter: status?.value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contentListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('İçerikler'),
        actions: [
          PopupMenuButton<ContentStatus?>(
            icon: Icon(
              Icons.filter_list_rounded,
              color: _selectedFilter != null
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
            onSelected: _onFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tümü'),
              ),
              const PopupMenuItem(
                value: ContentStatus.draft,
                child: Text('Taslak'),
              ),
              const PopupMenuItem(
                value: ContentStatus.published,
                child: Text('Yayında'),
              ),
              const PopupMenuItem(
                value: ContentStatus.archived,
                child: Text('Arşiv'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(contentListProvider.notifier).refresh(),
        color: AppColors.primary,
        child: _buildBody(state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/content/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Yeni İçerik',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody(ContentListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Hata: ${state.error}',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () =>
                  ref.read(contentListProvider.notifier).refresh(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Henüz içerik yok',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'İlk içeriğinizi oluşturmak için + butonuna tıklayın',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final content = state.items[index];
        return ContentCard(
          content: content,
          onTap: () => context.go('/content/${content.id}'),
        );
      },
    );
  }
}
