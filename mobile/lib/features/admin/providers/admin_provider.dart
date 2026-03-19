import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/features/admin/data/admin_repository.dart';
import 'package:yazihanem_mobile/features/admin/domain/models/app_user_model.dart';
import 'package:yazihanem_mobile/features/admin/domain/models/audit_log_model.dart';
import 'package:yazihanem_mobile/features/admin/domain/models/dashboard_stats_model.dart';
import 'package:yazihanem_mobile/features/auth/domain/models/user_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final dashboardStatsProvider =
    FutureProvider<DashboardStatsModel>((ref) async {
  return ref.watch(adminRepositoryProvider).getDashboardStats();
});

final userListProvider = FutureProvider<List<AppUserModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).listUsers();
});

final auditLogsProvider =
    FutureProvider<List<AuditLogModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).listAuditLogs();
});

// User management notifier
class UserManagementNotifier
    extends StateNotifier<AsyncValue<List<AppUserModel>>> {
  final AdminRepository _repo;
  final Ref _ref;

  UserManagementNotifier(this._repo, this._ref)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await _repo.listUsers();
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    await _repo.createUser(
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
    );
    _ref.invalidate(userListProvider);
    await _load();
  }

  Future<void> updateUser(
    String id, {
    String? firstName,
    String? lastName,
    UserRole? role,
    bool? isActive,
  }) async {
    await _repo.updateUser(
      id,
      firstName: firstName,
      lastName: lastName,
      role: role,
      isActive: isActive,
    );
    _ref.invalidate(userListProvider);
    await _load();
  }

  Future<void> deleteUser(String id) async {
    await _repo.deleteUser(id);
    _ref.invalidate(userListProvider);
    await _load();
  }
}

final userManagementProvider = StateNotifierProvider<UserManagementNotifier,
    AsyncValue<List<AppUserModel>>>(
  (ref) => UserManagementNotifier(ref.watch(adminRepositoryProvider), ref),
);
