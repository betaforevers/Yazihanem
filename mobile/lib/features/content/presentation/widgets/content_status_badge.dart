import 'package:flutter/material.dart';
import 'package:yazihanem_mobile/features/content/domain/models/content_model.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Status badge widget for content items.
///
/// - Draft → amber/yellow
/// - Published → green
/// - Archived → grey
class ContentStatusBadge extends StatelessWidget {
  final ContentStatus status;
  final bool compact;

  const ContentStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (status) {
      ContentStatus.draft => (AppColors.warning, AppColors.warning.withValues(alpha: 0.15)),
      ContentStatus.published => (AppColors.success, AppColors.success.withValues(alpha: 0.15)),
      ContentStatus.archived => (AppColors.textMuted, AppColors.textMuted.withValues(alpha: 0.15)),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: (compact ? AppTextStyles.bodySmall : AppTextStyles.bodySmall)
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
