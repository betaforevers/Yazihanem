import 'package:intl/intl.dart';

/// Useful extension methods.

extension StringExtension on String {
  /// Capitalize first letter.
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Generate slug from title (Turkish-safe).
  String toSlug() {
    return toLowerCase()
        .replaceAll(RegExp(r'[çÇ]'), 'c')
        .replaceAll(RegExp(r'[ğĞ]'), 'g')
        .replaceAll(RegExp(r'[ıİ]'), 'i')
        .replaceAll(RegExp(r'[öÖ]'), 'o')
        .replaceAll(RegExp(r'[şŞ]'), 's')
        .replaceAll(RegExp(r'[üÜ]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

extension DateTimeExtension on DateTime {
  /// Format as "5 Mar 2026"
  String get formatted => DateFormat('d MMM yyyy', 'tr').format(this);

  /// Format as "5 Mar 2026, 14:30"
  String get formattedWithTime =>
      DateFormat('d MMM yyyy, HH:mm', 'tr').format(this);

  /// Relative time: "2 saat önce", "Dün", etc.
  String get relative {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 2) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return formatted;
  }
}

extension FileSizeExtension on int {
  /// Format bytes: "1.5 MB", "320 KB"
  String get fileSize {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
