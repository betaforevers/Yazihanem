import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/fish/domain/models/fish_model.dart';
import 'package:yazihanem_mobile/features/fish/providers/fish_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Fish create/edit form screen.
class FishFormScreen extends ConsumerStatefulWidget {
  final String? fishId;

  const FishFormScreen({super.key, this.fishId});

  bool get isEditing => fishId != null;

  @override
  ConsumerState<FishFormScreen> createState() => _FishFormScreenState();
}

class _FishFormScreenState extends ConsumerState<FishFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _turController = TextEditingController();
  final _miktarController = TextEditingController();
  UnitType _selectedUnit = UnitType.kilogram;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadFish();
  }

  Future<void> _loadFish() async {
    setState(() => _isLoading = true);
    try {
      final fish = await ref.read(fishRepositoryProvider).getById(widget.fishId!);
      _turController.text = fish.tur;
      _miktarController.text = fish.miktar.toString();
      _selectedUnit = fish.birimTuru;
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
    _turController.dispose();
    _miktarController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(fishListProvider.notifier);
      final miktar = double.parse(_miktarController.text.trim());

      if (widget.isEditing) {
        await notifier.update(widget.fishId!,
            tur: _turController.text.trim(),
            birimTuru: _selectedUnit,
            miktar: miktar);
      } else {
        await notifier.create(
            tur: _turController.text.trim(),
            birimTuru: _selectedUnit,
            miktar: miktar);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Balık güncellendi' : 'Balık eklendi'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/fish');
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
        title: Text(widget.isEditing ? 'Balık Düzenle' : 'Yeni Balık'),
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
                    // Fish icon header
                    const Icon(Icons.set_meal_rounded,
                        size: 64, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.lg),

                    // Tür (type)
                    TextFormField(
                      controller: _turController,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Balık türü gerekli' : null,
                      decoration: const InputDecoration(
                        labelText: 'Balık Türü',
                        hintText: 'ör. Çipura, Levrek, Hamsi',
                        prefixIcon: Icon(Icons.phishing_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Birim seçimi (unit type)
                    Text('Birim Türü',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<UnitType>(
                      segments: const [
                        ButtonSegment(
                          value: UnitType.adet,
                          label: Text('Adet'),
                          icon: Icon(Icons.tag_rounded),
                        ),
                        ButtonSegment(
                          value: UnitType.gram,
                          label: Text('Gram'),
                          icon: Icon(Icons.scale_rounded),
                        ),
                        ButtonSegment(
                          value: UnitType.kilogram,
                          label: Text('Kilogram'),
                          icon: Icon(Icons.fitness_center_rounded),
                        ),
                      ],
                      selected: {_selectedUnit},
                      onSelectionChanged: (s) =>
                          setState(() => _selectedUnit = s.first),
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? AppColors.primary
                              : AppColors.bgCard,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Miktar (quantity)
                    TextFormField(
                      controller: _miktarController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Miktar gerekli';
                        final num = double.tryParse(v.trim());
                        if (num == null || num <= 0) return 'Geçerli bir miktar girin';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Miktar',
                        hintText: 'ör. 50',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        suffixText: _selectedUnit.label,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Save button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSave,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
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
