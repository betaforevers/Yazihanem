import 'package:yazihanem_mobile/features/admin/domain/models/app_user_model.dart';
import 'package:yazihanem_mobile/features/admin/domain/models/audit_log_model.dart';
import 'package:yazihanem_mobile/features/admin/domain/models/dashboard_stats_model.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';

class AdminRepository {
  // In-memory mock data
  final List<AppUserModel> _users = [
    AppUserModel(
      id: 'u1',
      email: 'admin@yazihanem.com',
      firstName: 'Ahmet',
      lastName: 'Yılmaz',
      role: UserRole.admin,
      isActive: true,
      tenant: 'yazihanem',
      createdAt: DateTime(2025, 1, 10),
      lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppUserModel(
      id: 'u2',
      email: 'editor@yazihanem.com',
      firstName: 'Fatma',
      lastName: 'Demir',
      role: UserRole.editor,
      isActive: true,
      tenant: 'yazihanem',
      createdAt: DateTime(2025, 3, 5),
      lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppUserModel(
      id: 'u3',
      email: 'mehmet@yazihanem.com',
      firstName: 'Mehmet',
      lastName: 'Kaya',
      role: UserRole.viewer,
      isActive: false,
      tenant: 'yazihanem',
      createdAt: DateTime(2025, 6, 20),
    ),
  ];

  final List<AuditLogModel> _logs = [
    AuditLogModel(
      id: 'l1',
      userId: 'u1',
      userEmail: 'admin@yazihanem.com',
      action: 'CREATE',
      resource: 'auction',
      resourceId: '1',
      description: 'Mezat fişi oluşturuldu: MZ-2026-0312',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AuditLogModel(
      id: 'l2',
      userId: 'u2',
      userEmail: 'editor@yazihanem.com',
      action: 'CREATE',
      resource: 'cari',
      resourceId: '5',
      description: 'Yeni cari eklendi: Ahmet Balık Ltd.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AuditLogModel(
      id: 'l3',
      userId: 'u1',
      userEmail: 'admin@yazihanem.com',
      action: 'UPDATE',
      resource: 'fish',
      resourceId: '3',
      description: 'Balık güncellendi: Hamsi',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    AuditLogModel(
      id: 'l4',
      userId: 'u1',
      userEmail: 'admin@yazihanem.com',
      action: 'LOGIN',
      resource: 'auth',
      description: 'Kullanıcı girişi yapıldı',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    AuditLogModel(
      id: 'l5',
      userId: 'u2',
      userEmail: 'editor@yazihanem.com',
      action: 'DELETE',
      resource: 'boat',
      resourceId: '2',
      description: 'Tekne silindi: Deniz Yıldızı',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  Future<DashboardStatsModel> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return DashboardStatsModel.mock();
  }

  Future<List<AppUserModel>> listUsers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_users);
  }

  Future<AppUserModel> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = AppUserModel(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      isActive: true,
      tenant: 'yazihanem',
      createdAt: DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  Future<AppUserModel> updateUser(
    String id, {
    String? firstName,
    String? lastName,
    UserRole? role,
    bool? isActive,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) throw Exception('Kullanıcı bulunamadı');
    final updated = _users[index].copyWith(
      firstName: firstName,
      lastName: lastName,
      role: role,
      isActive: isActive,
    );
    _users[index] = updated;
    return updated;
  }

  Future<void> deleteUser(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _users.removeWhere((u) => u.id == id);
  }

  Future<List<AuditLogModel>> listAuditLogs() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_logs);
  }
}
