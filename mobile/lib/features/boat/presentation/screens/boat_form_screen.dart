import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/boat/providers/boat_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Boat create/edit form screen.
class BoatFormScreen extends ConsumerStatefulWidget {
  final String? boatId;

  const BoatFormScreen({super.key, this.boatId});

  bool get isEditing => boatId != null;

  @override
  ConsumerState<BoatFormScreen> createState() => _BoatFormScreenState();
}

class _BoatFormScreenState extends ConsumerState<BoatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  double _komisyonYuzde = 10;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadBoat();
  }

  Future<void> _loadBoat() async {
    setState(() => _isLoading = true);
    try {
      final boat = await ref.read(boatRepositoryProvider).getById(widget.boatId!);
      _adController.text = boat.ad;
      _komisyonYuzde = boat.komisyonYuzde;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(boatListProvider.notifier);

      if (widget.isEditing) {
        await notifier.update(widget.boatId!,
            ad: _adController.text.trim(), komisyonYuzde: _komisyonYuzde);
      } else {
        await notifier.create(
            ad: _adController.text.trim(), komisyonYuzde: _komisyonYuzde);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Tekne güncellendi' : 'Tekne eklendi'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/boat');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Tekne Düzenle' : 'Yeni Tekne'),
      ),
      body: _isLoading && widget.isEditing
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Boat icon header
                    const Icon(Icons.sailing_rounded,
                        size: 64, color: Colors.blue),
                    const SizedBox(height: AppSpacing.lg),

                    // Tekne adı
                    TextFormField(
                      controller: _adController,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Tekne adı gerekli' : null,
                      decoration: const InputDecoration(
                        labelText: 'Tekne Adı',
                        hintText: 'ör. Karadeniz Yıldızı',
                        prefixIcon: Icon(Icons.directions_boat_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Komisyon yüzdesi
                    Text('Komisyon Yüzdesi',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.sm),

                    // Big percentage display
                    Center(
                      child: Text(
                        '%${_komisyonYuzde.toStringAsFixed(1)}',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.success,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Slider
                    Slider(
                      value: _komisyonYuzde,
                      min: 0,
                      max: 30,
                      divisions: 60,
                      activeColor: AppColors.success,
                      inactiveColor: AppColors.success.withValues(alpha: 0.2),
                      label: '%${_komisyonYuzde.toStringAsFixed(1)}',
                      onChanged: (v) => setState(() => _komisyonYuzde = v),
                    ),

                    // Quick select buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [5.0, 8.0, 10.0, 12.0, 15.0].map((v) {
                        final isSelected = _komisyonYuzde == v;
                        return ChoiceChip(
                          label: Text('%${v.toStringAsFixed(0)}'),
                          selected: isSelected,
                          selectedColor: AppColors.success,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _komisyonYuzde = v),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Save button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSave,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          widget.isEditing ? 'Güncelle' : 'Kaydet',
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
