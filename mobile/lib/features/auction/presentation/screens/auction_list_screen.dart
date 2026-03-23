import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/auction/domain/models/auction_model.dart';
import 'package:yazihanem_mobile/features/auction/providers/auction_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';
import 'package:yazihanem_mobile/shared/widgets/shimmer_list.dart';

/// Auction slips list screen.
class AuctionListScreen extends ConsumerStatefulWidget {
  const AuctionListScreen({super.key});

  @override
  ConsumerState<AuctionListScreen> createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends ConsumerState<AuctionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auctionListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auctionListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Mezat Fişleri')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(auctionListProvider.notifier).load(),
        color: AppColors.primary,
        child: _buildBody(state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final auction = await ref.read(auctionListProvider.notifier).create();
          if (context.mounted) context.go('/auction/${auction.id}');
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.gavel_rounded, color: Colors.white),
        label: const Text('Yeni Fiş',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody(AuctionListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const ShimmerList(itemCount: 6, itemHeight: 90);
    }

    if (state.error != null && state.items.isEmpty) {
      return ErrorRetryWidget(
        message: 'Mezat fişleri yüklenemedi\n${state.error}',
        onRetry: () => ref.read(auctionListProvider.notifier).load(),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.gavel_rounded,
        message: 'Henüz mezat fişi yok\nYeni fiş oluşturmak için + butonuna basın',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final auction = state.items[index];
        return _AuctionCard(
          auction: auction,
          onTap: () => context.go('/auction/${auction.id}'),
        );
      },
    );
  }
}

class _AuctionCard extends StatelessWidget {
  final AuctionModel auction;
  final VoidCallback? onTap;

  const _AuctionCard({required this.auction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOpen = auction.durum == AuctionDurum.acik;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(
            color: isOpen ? Colors.orange.withValues(alpha: 0.4) : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Gavel icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isOpen ? Colors.orange : AppColors.textMuted)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: Icon(Icons.gavel_rounded,
                  color: isOpen ? Colors.orange : AppColors.textMuted,
                  size: 24),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(auction.fisNo,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isOpen ? Colors.orange : AppColors.textMuted)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          auction.durum.label,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isOpen ? Colors.orange : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${auction.kalemSayisi} kalem • ${_formatDate(auction.mezatTarihi)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                  if (auction.cari != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.store_rounded,
                            size: 11, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            auction.cari!.unvan,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Total + PDF icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${auction.toplamTutar.toStringAsFixed(0)}',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                InkWell(
                  onTap: () =>
                      context.go('/auction/${auction.id}/preview'),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded,
                            size: 13,
                            color:
                                AppColors.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 2),
                        Text('PDF',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
