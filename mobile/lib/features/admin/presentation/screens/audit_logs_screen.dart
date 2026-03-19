import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/admin/domain/models/audit_log_model.dart';
import 'package:yazihanem_mobile/features/admin/providers/admin_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Read-only audit log list screen.
class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Denetim Kayıtları'),
        leading: BackButton(onPressed: () => context.go('/profile')),
      ),
      body: logsAsync.when(
        data: (logs) => _LogList(logs: logs),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.md),
              const Text('Kayıtlar yüklenemedi', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref.invalidate(auditLogsProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogList extends StatelessWidget {
  final List<AuditLogModel> logs;
  const _LogList({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('Kayıt bulunamadı',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: logs.length,
      separatorBuilder: (context, i) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return _LogTile(log: logs[index]);
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  final AuditLogModel log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final actionColor = _actionColor(log.action);
    final actionLabel = _actionLabel(log.action);
    final resourceLabel = _resourceLabel(log.resource);
    final timeAgo = _timeAgo(log.createdAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action badge icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(AppSpacing.borderRadiusSm),
            ),
            child: Icon(_actionIcon(log.action),
                color: actionColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action + resource row
                Row(
                  children: [
                    _ActionBadge(label: actionLabel, color: actionColor),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        resourceLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Description
                Text(log.description,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.xs),

                // User email + time
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        log.userEmail,
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(timeAgo, style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    return switch (action) {
      'CREATE' => AppColors.success,
      'UPDATE' => AppColors.info,
      'DELETE' => AppColors.error,
      'LOGIN' => const Color(0xFF14B8A6), // teal
      'LOGOUT' => Colors.orange,
      _ => AppColors.textMuted,
    };
  }

  String _actionLabel(String action) {
    return switch (action) {
      'CREATE' => 'OLUŞTUR',
      'UPDATE' => 'GÜNCELLE',
      'DELETE' => 'SİL',
      'LOGIN' => 'GİRİŞ',
      'LOGOUT' => 'ÇIKIŞ',
      _ => action,
    };
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'CREATE' => Icons.add_circle_outline_rounded,
      'UPDATE' => Icons.edit_rounded,
      'DELETE' => Icons.delete_outline_rounded,
      'LOGIN' => Icons.login_rounded,
      'LOGOUT' => Icons.logout_rounded,
      _ => Icons.info_outline_rounded,
    };
  }

  String _resourceLabel(String resource) {
    return switch (resource) {
      'auction' => 'Mezat',
      'cari' => 'Cari',
      'fish' => 'Balık',
      'boat' => 'Tekne',
      'user' => 'Kullanıcı',
      'auth' => 'Auth',
      _ => resource,
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }
}

class _ActionBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ActionBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
