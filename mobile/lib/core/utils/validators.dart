/// Form and data validators.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email adresi gerekli';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Geçerli bir email adresi girin';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli';
    if (value.length < 8) return 'Şifre en az 8 karakter olmalıdır';
    return null;
  }

  static String? required(String? value, [String field = 'Bu alan']) {
    if (value == null || value.trim().isEmpty) return '$field gerekli';
    return null;
  }

  static String? slug(String? value) {
    if (value == null || value.isEmpty) return 'Slug gerekli';
    final slugRegex = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
    if (!slugRegex.hasMatch(value)) {
      return 'Slug sadece küçük harf, rakam ve tire içerebilir';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String field = 'Bu alan']) {
    if (value == null || value.length < min) {
      return '$field en az $min karakter olmalıdır';
    }
    return null;
  }
}
