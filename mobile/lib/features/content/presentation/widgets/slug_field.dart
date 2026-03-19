import 'package:flutter/material.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';

/// Slug input field with auto-generation from title.
///
/// Converts Turkish characters and spaces to URL-friendly slugs:
/// "Flutter ile Geliştirme" → "flutter-ile-gelistirme"
class SlugField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const SlugField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  /// Generate slug from a title string.
  static String generateSlug(String title) {
    const turkishMap = {
      'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
      'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u',
    };

    var slug = title.toLowerCase();
    turkishMap.forEach((key, value) {
      slug = slug.replaceAll(key, value);
    });

    slug = slug.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    slug = slug.replaceAll(RegExp(r'[\s]+'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-');
    slug = slug.replaceAll(RegExp(r'^-|-$'), '');

    return slug;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autocorrect: false,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Slug gerekli';
        if (!RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(value)) {
          return 'Slug sadece küçük harf, rakam ve tire içerebilir';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Slug',
        hintText: 'url-dostu-baslık',
        prefixIcon: const Icon(Icons.link_rounded),
        suffixIcon: IconButton(
          onPressed: enabled ? () {} : null,
          icon: const Icon(Icons.auto_fix_high_rounded,
              color: AppColors.primary),
          tooltip: 'Başlıktan oluştur',
        ),
      ),
    );
  }
}
