import 'package:flutter/material.dart';

/// Application color palette — premium dark theme with teal accent.
///
/// Re-exported from theme_config.dart for standalone import.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF0D9488);       // Teal 600
  static const primaryLight = Color(0xFF2DD4BF);  // Teal 400
  static const primaryDark = Color(0xFF0F766E);   // Teal 700

  // Backgrounds
  static const bgDark = Color(0xFF0F172A);        // Slate 900
  static const bgCard = Color(0xFF1E293B);        // Slate 800
  static const bgElevated = Color(0xFF334155);    // Slate 700

  // Text
  static const textPrimary = Color(0xFFF8FAFC);   // Slate 50
  static const textSecondary = Color(0xFF94A3B8);  // Slate 400
  static const textMuted = Color(0xFF64748B);      // Slate 500

  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Content status badge
  static const draftBg = Color(0xFF1E3A5F);
  static const draftText = Color(0xFF60A5FA);
  static const publishedBg = Color(0xFF14532D);
  static const publishedText = Color(0xFF4ADE80);
  static const archivedBg = Color(0xFF44403C);
  static const archivedText = Color(0xFFA8A29E);

  // Surface
  static const divider = Color(0xFF334155);
  static const shimmerBase = Color(0xFF1E293B);
  static const shimmerHighlight = Color(0xFF334155);
}
