import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/admin/domain/models/app_user_model.dart';
import 'package:yazihanem_mobile/features/admin/providers/admin_provider.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Form screen for creating or editing a user.
class UserFormScreen extends ConsumerStatefulWidget {
  /// If provided, we are in edit mode; null means create mode.
  final String? userId;

  const UserFormScreen({super.key, this.userId});

  bool get isEditMode => userId != null;

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  UserRole _selectedRole = UserRole.viewer;
  bool _isActive = true;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _initFromUser(AppUserModel user) {
    if (_initialized) return;
    _initialized = true;
    _emailController.text = user.email;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _selectedRole = user.role;
    _isActive = user.isActive;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(userManagementProvider.notifier);
      if (widget.isEditMode) {
        await notifier.updateUser(
          widget.userId!,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          role: _selectedRole,
          isActive: _isActive,
        );
      } else {
        await notifier.createUser(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          role: _selectedRole,
        );
      }
      if (mounted) context.go('/profile/admin/users');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditMode) {
      final usersAsync = ref.watch(userManagementProvider);
      return usersAsync.when(
        data: (users) {
          final user = users.where((u) => u.id == widget.userId).firstOrNull;
          if (user == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Kullanıcı Düzenle')),
              body: const Center(child: Text('Kullanıcı bulunamadı')),
            );
          }
          _initFromUser(user);
          return _buildForm(context);
        },
        loading: () => const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Kullanıcı Düzenle')),
          body: Center(child: Text('Hata: $e')),
        ),
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(
            widget.isEditMode ? 'Kullanıcı Düzenle' : 'Yeni Kullanıcı'),
        leading: BackButton(
            onPressed: () => context.go('/profile/admin/users')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // ───── Email ─────
              const _SectionLabel(label: 'E-posta'),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _emailController,
                enabled: !widget.isEditMode,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  hintText: 'ornek@sirket.com',
                  prefixIcon: Icons.email_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'E-posta zorunludur';
                  }
                  if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ───── First Name ─────
              const _SectionLabel(label: 'Ad'),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  hintText: 'Adınız',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ad zorunludur';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ───── Last Name ─────
              const _SectionLabel(label: 'Soyad'),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  hintText: 'Soyadınız',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Soyad zorunludur';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ───── Role Dropdown ─────
              const _SectionLabel(label: 'Rol'),
              const SizedBox(height: AppSpacing.xs),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(color: AppColors.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: _selectedRole,
                    isExpanded: true,
                    dropdownColor: AppColors.bgCard,
                    style: AppTextStyles.bodyLarge,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted),
                    onChanged: (role) {
                      if (role != null) setState(() => _selectedRole = role);
                    },
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.admin,
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Yönetici (Admin)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: UserRole.editor,
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                size: 18, color: AppColors.info),
                            SizedBox(width: 8),
                            Text('Editör'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: UserRole.viewer,
                        child: Row(
                          children: [
                            Icon(Icons.visibility_rounded,
                                size: 18, color: AppColors.textMuted),
                            SizedBox(width: 8),
                            Text('Görüntüleyici'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ───── isActive toggle (edit mode only) ─────
              if (widget.isEditMode) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.toggle_on_rounded,
                          color: AppColors.textMuted, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hesap Durumu',
                                style: AppTextStyles.bodyLarge),
                            Text(
                              _isActive ? 'Aktif' : 'Pasif',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _isActive
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ───── Save Button ─────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.isEditMode ? 'Güncelle' : 'Kaydet',
                          style: AppTextStyles.buttonText,
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

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.bgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.labelLarge);
  }
}
