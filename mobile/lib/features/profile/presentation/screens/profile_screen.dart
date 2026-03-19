import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/auth/domain/auth_state.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';
import 'package:yazihanem_mobile/features/auth/providers/auth_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';


/// Profile screen showing user info, menu items, and logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user =
        authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              // ───── Avatar ─────
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary,
                child: Text(
                  _initials(user),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // ───── Name ─────
              Text(
                user?.fullName ?? 'Kullanıcı',
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              // ───── Email ─────
              Text(
                user?.email ?? '',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              // ───── Role badge ─────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _roleColor(user?.role).withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadius),
                ),
                child: Text(
                  _roleLabel(user?.role),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _roleColor(user?.role),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // ───── Menu items ─────
              _MenuSection(
                items: [
                  _MenuItem(
                    icon: Icons.business_rounded,
                    label: 'Yazıhane',
                    subtitle: user?.tenant ?? '',
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Şifre Değiştir',
                    onTap: () => context.go('/profile/change-password'),
                  ),
                  _MenuItem(
                    icon: Icons.settings_rounded,
                    label: 'Ayarlar',
                    onTap: () => context.go('/profile/settings'),
                  ),
                  const _MenuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'Uygulama Hakkında',
                    subtitle: 'v1.0.0',
                  ),
                ],
              ),
              // ───── Admin Panel (admin only) ─────
              if (user?.isAdmin == true) ...[
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.xs, bottom: AppSpacing.sm),
                    child: Text(
                      'YÖNETİM',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                _MenuSection(
                  items: [
                    _MenuItem(
                      icon: Icons.manage_accounts_rounded,
                      label: 'Kullanıcı Yönetimi',
                      subtitle: 'Kullanıcıları yönet',
                      onTap: () => context.go('/profile/admin/users'),
                      iconColor: AppColors.error,
                    ),
                    _MenuItem(
                      icon: Icons.history_rounded,
                      label: 'Denetim Kayıtları',
                      subtitle: 'İşlem geçmişi',
                      onTap: () => context.go('/profile/admin/audit-logs'),
                      iconColor: AppColors.error,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              // ───── Logout ─────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showLogoutDialog(context, ref),
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.error),
                  label: Text(
                    'Çıkış Yap',
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(UserModel? user) {
    if (user == null) return '?';
    final f = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final l = user.lastName.isNotEmpty ? user.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  Color _roleColor(UserRole? role) {
    return switch (role) {
      UserRole.admin => AppColors.error,
      UserRole.editor => AppColors.warning,
      UserRole.viewer => AppColors.info,
      null => AppColors.textMuted,
    };
  }

  String _roleLabel(UserRole? role) {
    return switch (role) {
      UserRole.admin => 'Yönetici',
      UserRole.editor => 'Editör',
      UserRole.viewer => 'Görüntüleyici',
      null => '',
    };
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content:
            const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('Çıkış Yap',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Menu Components ───────────────

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                const Divider(
                    height: 1, color: AppColors.divider, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? AppColors.primary;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        ),
        child: Icon(icon, color: effectiveColor, size: 20),
      ),
      title: Text(label, style: AppTextStyles.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.bodySmall)
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted)
          : null,
      onTap: onTap,
    );
  }
}
