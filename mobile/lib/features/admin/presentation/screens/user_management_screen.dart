import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/admin/domain/models/app_user_model.dart';
import 'package:yazihanem_mobile/features/admin/providers/admin_provider.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// User management screen — list, toggle active, edit, delete users.
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userManagementProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        leading: BackButton(onPressed: () => context.go('/profile')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.go('/profile/admin/users/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Yeni Kullanıcı',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: usersAsync.when(
        data: (users) => _UserList(users: users),
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
              const Text('Kullanıcılar yüklenemedi',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.read(userManagementProvider.notifier).refresh(),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserList extends ConsumerWidget {
  final List<AppUserModel> users;
  const _UserList({required this.users});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('Kullanıcı bulunamadı',
                style:
                    AppTextStyles.headlineSmall.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(userManagementProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: users.length,
        separatorBuilder: (context, i) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final user = users[index];
          return _UserCard(user: user);
        },
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AppUserModel user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = _roleColor(user.role);
    final roleLabel = _roleLabel(user.role);
    final initials = _initials(user);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(
          color: user.isActive ? AppColors.divider : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: roleColor.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName : user.email,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _RoleBadge(label: roleLabel, color: roleColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text(user.email,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      user.isActive
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 12,
                      color: user.isActive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      user.isActive ? 'Aktif' : 'Pasif',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: user.isActive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<_UserAction>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textMuted),
            color: AppColors.bgCard,
            onSelected: (action) =>
                _handleAction(context, ref, action, user),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _UserAction.edit,
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded,
                        size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _UserAction.toggleActive,
                child: Row(
                  children: [
                    Icon(
                      user.isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: user.isActive
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(user.isActive ? 'Pasife Al' : 'Aktife Al'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _UserAction.delete,
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Sil',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    _UserAction action,
    AppUserModel user,
  ) {
    switch (action) {
      case _UserAction.edit:
        context.go('/profile/admin/users/${user.id}/edit');
      case _UserAction.toggleActive:
        ref.read(userManagementProvider.notifier).updateUser(
              user.id,
              isActive: !user.isActive,
            );
      case _UserAction.delete:
        showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Kullanıcıyı Sil'),
            content: Text(
                '${user.fullName.isNotEmpty ? user.fullName : user.email} silinecek. Emin misiniz?'),
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
        ).then((confirmed) {
          if (confirmed == true) {
            ref.read(userManagementProvider.notifier).deleteUser(user.id);
          }
        });
    }
  }

  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.admin => AppColors.error,
      UserRole.editor => AppColors.info,
      UserRole.viewer => AppColors.textMuted,
    };
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.admin => 'Admin',
      UserRole.editor => 'Editör',
      UserRole.viewer => 'Görüntüleyici',
    };
  }

  String _initials(AppUserModel user) {
    final f = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final l = user.lastName.isNotEmpty ? user.lastName[0] : '';
    final initials = '$f$l'.toUpperCase();
    return initials.isNotEmpty ? initials : (user.email.isNotEmpty ? user.email[0].toUpperCase() : '?');
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge({required this.label, required this.color});

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
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

enum _UserAction { edit, toggleActive, delete }
