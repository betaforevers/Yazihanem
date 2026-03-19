import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yazihanem_mobile/features/admin/domain/models/dashboard_stats_model.dart';
import 'package:yazihanem_mobile/features/admin/providers/admin_provider.dart';
import 'package:yazihanem_mobile/features/auth/domain/auth_state.dart';
import 'package:yazihanem_mobile/features/auth/providers/auth_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Dashboard / Ana Sayfa screen showing today's stats and recent auctions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final authState = ref.watch(authStateProvider);
    final user =
        authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardStatsProvider),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ───── Header ─────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ana Sayfa',
                              style: AppTextStyles.headlineLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Hoş geldiniz, ${user?.firstName ?? 'Kullanıcı'}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      // Date badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.borderRadius),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy', 'tr_TR')
                              .format(DateTime.now()),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ───── Stats Grid ─────
              SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (stats) => _StatsGrid(stats: stats),
                  loading: () => const _StatsGridSkeleton(),
                  error: (e, _) => _ErrorWidget(
                    message: 'İstatistikler yüklenemedi',
                    onRetry: () => ref.invalidate(dashboardStatsProvider),
                  ),
                ),
              ),

              // ───── Quick Actions ─────
              const SliverToBoxAdapter(child: _QuickActions()),

              // ───── Recent Auctions ─────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                  child: Text(
                    'Son Mezatlar',
                    style: AppTextStyles.headlineSmall,
                  ),
                ),
              ),

              statsAsync.when(
                data: (stats) => SliverList.separated(
                  itemCount: stats.recentAuctions.length,
                  separatorBuilder: (context, i) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = stats.recentAuctions[index];
                    return Padding(
                      padding: AppSpacing.pagePadding,
                      child: _RecentAuctionTile(
                        item: item,
                        onTap: () => context.go('/auction/${item.id}'),
                      ),
                    );
                  },
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, st) => const SliverToBoxAdapter(child: SizedBox()),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── Stats Grid ───────────────

class _StatsGrid extends StatelessWidget {
  final DashboardStatsModel stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
        locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.gavel_rounded,
                  iconColor: Colors.orange,
                  label: 'Bugün Mezat',
                  value: '${stats.todayAuctionCount}',
                  subtitle: 'fiş',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.payments_rounded,
                  iconColor: AppColors.success,
                  label: 'Bugün Tutar',
                  value: currency.format(stats.todayTotalAmount),
                  subtitle: 'toplam',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.store_rounded,
                  iconColor: AppColors.info,
                  label: 'Toplam Cari',
                  value: '${stats.totalCariCount}',
                  subtitle: 'kayıtlı',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.primary,
                  label: 'Toplam Fiş',
                  value: '${stats.totalAuctionCount}',
                  subtitle: 'mezat fişi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ─────────────── Skeleton Loader ───────────────

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SkeletonCard()),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _SkeletonCard()),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _SkeletonCard()),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _SkeletonCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.divider),
      ),
    );
  }
}

// ─────────────── Quick Actions ───────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hızlı Erişim', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.gavel_rounded,
                  label: 'Mezat',
                  color: Colors.orange,
                  onTap: () => context.go('/auction'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.store_rounded,
                  label: 'Cariler',
                  color: AppColors.info,
                  onTap: () => context.go('/cari'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.set_meal_rounded,
                  label: 'Balıklar',
                  color: AppColors.primary,
                  onTap: () => context.go('/fish'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.sailing_rounded,
                  label: 'Tekneler',
                  color: AppColors.primaryLight,
                  onTap: () => context.go('/boat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Recent Auction Tile ───────────────

class _RecentAuctionTile extends StatelessWidget {
  final RecentAuctionItem item;
  final VoidCallback onTap;

  const _RecentAuctionTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
        locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final timeAgo = _timeAgo(item.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: const Icon(Icons.gavel_rounded,
                  color: Colors.orange, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fisNo,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.store_rounded,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          item.cariUnvan,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(item.amount),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(timeAgo, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }
}

// ─────────────── Error Widget ───────────────

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
