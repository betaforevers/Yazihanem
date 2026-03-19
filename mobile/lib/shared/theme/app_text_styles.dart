import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Application typography — Inter font family.
class AppTextStyles {
  AppTextStyles._();

  static const _fontFamily = 'Inter';

  static const headlineLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  static const headlineMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.3,
  );

  static const headlineSmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.3,
  );

  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textMuted, height: 1.4,
  );

  static const labelLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.5,
  );

  static const buttonText = TextStyle(
    fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w600,
    color: Colors.white, letterSpacing: 0.3,
  );
}
