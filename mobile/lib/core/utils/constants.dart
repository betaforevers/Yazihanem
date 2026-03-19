/// App-wide constants.
class AppConstants {
  AppConstants._();

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Content
  static const int maxTitleLength = 200;
  static const int maxSlugLength = 200;

  // Media
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB
  static const List<String> allowedImageTypes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
  ];
  static const List<String> allowedDocTypes = [
    'application/pdf', 'text/plain',
  ];

  // Cache TTL
  static const Duration contentListTTL = Duration(minutes: 5);
  static const Duration contentDetailTTL = Duration(hours: 1);
  static const Duration userProfileTTL = Duration(hours: 24);
  static const Duration tenantMetaTTL = Duration(hours: 1);
}
