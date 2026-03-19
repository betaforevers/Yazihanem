/// All backend API endpoint paths.
///
/// Centralized endpoint definitions matching the Go Fiber backend routes.
class ApiEndpoints {
  ApiEndpoints._();

  // ───────── Auth ─────────
  static const authLogin = '/api/v1/auth/login';
  static const authLogout = '/api/v1/auth/logout';
  static const authRefresh = '/api/v1/auth/refresh';
  static const authMe = '/api/v1/auth/me';
  static const authChangePassword = '/api/v1/auth/change-password';

  // ───────── Content ─────────
  static const content = '/api/v1/content';
  static const contentMy = '/api/v1/content/my';
  static String contentById(String id) => '/api/v1/content/$id';
  static String contentBySlug(String slug) => '/api/v1/content/slug/$slug';
  static String contentPublish(String id) => '/api/v1/content/$id/publish';

  // ───────── Media ─────────
  static const mediaUpload = '/api/v1/media/upload';
  static const media = '/api/v1/media';
  static String mediaById(String id) => '/api/v1/media/$id';

  // ───────── Admin: Users ─────────
  static const adminUsers = '/api/v1/admin/users';
  static String adminUserById(String id) => '/api/v1/admin/users/$id';
  static String adminUserActivate(String id) => '/api/v1/admin/users/$id/activate';
  static String adminUserDeactivate(String id) => '/api/v1/admin/users/$id/deactivate';

  // ───────── Admin: Audit ─────────
  static const adminAuditLogs = '/api/v1/admin/audit-logs';
  static const adminAuditStats = '/api/v1/admin/audit-logs/stats';
  static const adminStats = '/api/v1/admin/stats';

  // ───────── Tenant ─────────
  static const register = '/api/v1/register';

  // ───────── Health ─────────
  static const health = '/health';
}
