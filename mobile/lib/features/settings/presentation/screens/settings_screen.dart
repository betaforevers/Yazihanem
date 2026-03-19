import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Settings screen with app info, server config, and about sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final isDev = config.isDev;
    final baseUrl = config.apiBaseUrl;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: BackButton(onPressed: () => context.go('/profile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),

            // ───── Uygulama Section ─────
            const _SectionHeader(label: 'Uygulama'),
            const SizedBox(height: AppSpacing.xs),
            _SettingsCard(
              children: [
                const _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Uygulama Versiyonu',
                  trailing: Text(
                    '1.0.0+1',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                _SettingsTile(
                  icon: Icons.label_outline_rounded,
                  label: 'Ortam',
                  trailing: _EnvironmentBadge(isDev: isDev),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                const _SettingsTile(
                  icon: Icons.language_rounded,
                  label: 'Dil',
                  trailing: Text(
                    'Türkçe',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ───── Sunucu Section ─────
            const _SectionHeader(label: 'Sunucu'),
            const SizedBox(height: AppSpacing.xs),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.dns_rounded,
                  label: 'Sunucu Adresi',
                  trailing: Flexible(
                    child: Text(
                      baseUrl,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                _SettingsTile(
                  icon: Icons.cloud_outlined,
                  label: 'Bağlantı Modu',
                  trailing: Text(
                    isDev ? 'Mock (Geliştirme)' : 'Canlı',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDev ? AppColors.warning : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                const _SettingsTile(
                  icon: Icons.timer_outlined,
                  label: 'Bağlantı Zaman Aşımı',
                  trailing: Text(
                    '30 saniye',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ───── Hakkında Section ─────
            const _SectionHeader(label: 'Hakkında'),
            const SizedBox(height: AppSpacing.xs),
            const _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.apps_rounded,
                  label: 'Uygulama Adı',
                  trailing: Text(
                    'Yazıhanem',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.divider, indent: 56),
                _SettingsTile(
                  icon: Icons.business_rounded,
                  label: 'Geliştirici',
                  trailing: Text(
                    'Yazıhanem Yazılım',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.divider, indent: 56),
                _SettingsTile(
                  icon: Icons.copyright_rounded,
                  label: 'Telif Hakkı',
                  trailing: Text(
                    '© 2026 Yazıhanem',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.divider, indent: 56),
                _SettingsTile(
                  icon: Icons.code_rounded,
                  label: 'Teknoloji',
                  trailing: Text(
                    'Flutter + Go',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ───── App Icon / Branding ─────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadiusLg),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.anchor_rounded,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Yazıhanem',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Balık Mezat Yönetim Sistemi',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'v1.0.0+1',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Section Header ───────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─────────────── Settings Card ───────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

// ─────────────── Settings Tile ───────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: trailing,
    );
  }
}

// ─────────────── Environment Badge ───────────────

class _EnvironmentBadge extends StatelessWidget {
  final bool isDev;
  const _EnvironmentBadge({required this.isDev});

  @override
  Widget build(BuildContext context) {
    final color = isDev ? AppColors.warning : AppColors.success;
    final label = isDev ? 'GELİŞTİRME' : 'CANLI';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
