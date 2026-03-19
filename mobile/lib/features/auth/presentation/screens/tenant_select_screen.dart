import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/auth/providers/auth_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Tenant domain selection screen.
///
/// Users enter their organization's tenant domain here.
/// The domain is saved to secure storage and used as the
/// X-Tenant-Domain header for all subsequent API requests.
class TenantSelectScreen extends ConsumerStatefulWidget {
  const TenantSelectScreen({super.key});

  @override
  ConsumerState<TenantSelectScreen> createState() => _TenantSelectScreenState();
}

class _TenantSelectScreenState extends ConsumerState<TenantSelectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _domainController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentDomain();
  }

  Future<void> _loadCurrentDomain() async {
    final repository = ref.read(authRepositoryProvider);
    final hasDomain = await repository.hasTenantDomain();
    if (hasDomain) {
      final domain = await repository.getTenantDomain();
      if (domain != null && mounted) {
        _domainController.text = domain;
      }
    }
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final domain = _domainController.text.trim().toLowerCase();
    await ref.read(authStateProvider.notifier).setTenantDomain(domain);

    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─── Icon ───
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                const Text('Tenant Seçimi', style: AppTextStyles.headlineLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kuruluşunuzun alan adını girin',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ─── Form ───
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadiusLg),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _domainController,
                          autocorrect: false,
                          textInputAction: TextInputAction.done,
                          enabled: !_isLoading,
                          onFieldSubmitted: (_) => _handleSubmit(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tenant domain gerekli';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Domain',
                            hintText: 'kurulusunuz.yazihanem.com',
                            prefixIcon: Icon(Icons.dns_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Devam Et',
                                    style: AppTextStyles.buttonText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
