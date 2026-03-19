import 'package:flutter/material.dart';
import 'package:yazihanem_mobile/features/fish/domain/models/fish_model.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Fish list card widget.
class FishCard extends StatelessWidget {
  final FishModel fish;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FishCard({super.key, required this.fish, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
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
            // Fish icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: const Icon(Icons.set_meal_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),

            // Fish info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fish.tur,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(fish.miktarLabel,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),

            // Unit badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _unitColor(fish.birimTuru).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                fish.birimTuru.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: _unitColor(fish.birimTuru),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (onDelete != null) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _unitColor(UnitType type) {
    return switch (type) {
      UnitType.adet => AppColors.primary,
      UnitType.gram => AppColors.warning,
      UnitType.kilogram => AppColors.success,
    };
  }
}
