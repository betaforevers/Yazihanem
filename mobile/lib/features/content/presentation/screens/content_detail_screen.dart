import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/content/presentation/widgets/content_status_badge.dart';
import 'package:yazihanem_mobile/features/content/providers/content_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Content detail screen — shows full content with actions.
class ContentDetailScreen extends ConsumerWidget {
  final String contentId;

  const ContentDetailScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentDetailProvider(contentId));

    return contentAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(),
        body: Center(
          child: Text('Hata: $error',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.error)),
        ),
      ),
      data: (content) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          title: const Text('İçerik Detayı'),
          actions: [
            // Edit button
            IconButton(
              onPressed: () => context.go('/content/${content.id}/edit'),
              icon: const Icon(Icons.edit_rounded),
            ),
            // More menu
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'publish' && content.isDraft) {
                  await ref
                      .read(contentListProvider.notifier)
                      .publishContent(content.id);
                  if (context.mounted) {
                    ref.invalidate(contentDetailProvider(contentId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İçerik yayınlandı'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('İçeriği Sil'),
                      content: const Text(
                          'Bu içerik kalıcı olarak silinecek. Emin misiniz?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error),
                          child: const Text('Sil'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref
                        .read(contentListProvider.notifier)
                        .deleteContent(content.id);
                    if (context.mounted) context.go('/content');
                  }
                }
              },
              itemBuilder: (context) => [
                if (content.isDraft)
                  const PopupMenuItem(
                    value: 'publish',
                    child: ListTile(
                      leading: Icon(Icons.publish_rounded,
                          color: AppColors.success),
                      title: Text('Yayınla'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_rounded,
                        color: AppColors.error),
                    title: Text('Sil'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status + date
              Row(
                children: [
                  ContentStatusBadge(status: content.status),
                  const Spacer(),
                  Text(
                    _formatFullDate(content.updatedAt),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(content.title, style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.xs),

              // Slug
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '/${content.slug}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Body
              Container(
                width: double.infinity,
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  content.body.isNotEmpty
                      ? content.body
                      : 'İçerik boş',
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.7,
                    color: content.body.isNotEmpty
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),

              if (content.publishedAt != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Yayınlanma: ${_formatFullDate(content.publishedAt!)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
