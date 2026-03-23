import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/admin/presentation/screens/audit_logs_screen.dart';
import 'package:yazihanem_mobile/features/admin/presentation/screens/dashboard_screen.dart';
import 'package:yazihanem_mobile/features/admin/presentation/screens/user_form_screen.dart';
import 'package:yazihanem_mobile/features/admin/presentation/screens/user_management_screen.dart';
import 'package:yazihanem_mobile/features/auth/domain/auth_state.dart';
import 'package:yazihanem_mobile/features/auth/presentation/screens/change_password_screen.dart';
import 'package:yazihanem_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:yazihanem_mobile/features/auth/presentation/screens/tenant_select_screen.dart';
import 'package:yazihanem_mobile/features/auth/providers/auth_provider.dart';
import 'package:yazihanem_mobile/features/cari/presentation/screens/cari_form_screen.dart';
import 'package:yazihanem_mobile/features/cari/presentation/screens/cari_list_screen.dart';
import 'package:yazihanem_mobile/features/fish/presentation/screens/fish_form_screen.dart';
import 'package:yazihanem_mobile/features/fish/presentation/screens/fish_list_screen.dart';
import 'package:yazihanem_mobile/features/boat/presentation/screens/boat_form_screen.dart';
import 'package:yazihanem_mobile/features/boat/presentation/screens/boat_list_screen.dart';
import 'package:yazihanem_mobile/features/auction/presentation/screens/auction_form_screen.dart';
import 'package:yazihanem_mobile/features/auction/presentation/screens/auction_list_screen.dart';
import 'package:yazihanem_mobile/features/auction/presentation/screens/fis_preview_screen.dart';
import 'package:yazihanem_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:yazihanem_mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:yazihanem_mobile/shared/providers/connectivity_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Application router using GoRouter with auth guards.
///
/// Route structure:
/// - /login            → Login screen
/// - /tenant-select    → Tenant domain selection
/// - /dashboard        → Dashboard / Ana Sayfa (bottom nav 0)
/// - /auction          → Auction slips list (bottom nav 1)
/// - /cari             → Cariler list (bottom nav 2)
/// - /tanimlar         → Tanımlar hub (bottom nav 3) — Balık & Tekne
/// - /fish             → Fish list (navigated from Tanımlar)
/// - /boat             → Boat list (navigated from Tanımlar)
/// - /profile          → Profile (bottom nav 4)
///   - /profile/settings          → Settings screen
///   - /profile/admin/users       → User management (admin)
///   - /profile/admin/audit-logs  → Audit logs (admin)
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/tenant-select';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && state.matchedLocation == '/login') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ───── Auth Routes ─────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/tenant-select',
        name: 'tenant-select',
        builder: (context, state) => const TenantSelectScreen(),
      ),

      // ───── Main Shell (Bottom Navigation) ─────
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          // Dashboard / Ana Sayfa
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // Mezat
          GoRoute(
            path: '/auction',
            name: 'auction',
            builder: (context, state) => const AuctionListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'auction-detail',
                builder: (context, state) => AuctionFormScreen(
                  auctionId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: ':id/preview',
                name: 'auction-preview',
                builder: (context, state) => FisPreviewScreen(
                  auctionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Cariler
          GoRoute(
            path: '/cari',
            name: 'cari',
            builder: (context, state) => const CariListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'cari-new',
                builder: (context, state) => const CariFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'cari-edit',
                builder: (context, state) => CariFormScreen(
                  cariId: state.pathParameters['id'],
                ),
              ),
            ],
          ),

          // Tanımlar hub (Balık + Tekne)
          GoRoute(
            path: '/tanimlar',
            name: 'tanimlar',
            builder: (context, state) => const _TanimlarScreen(),
          ),

          // Balık (accessed from Tanımlar, kept in shell for nav highlighting)
          GoRoute(
            path: '/fish',
            name: 'fish',
            builder: (context, state) => const FishListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'fish-new',
                builder: (context, state) => const FishFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'fish-edit',
                builder: (context, state) => FishFormScreen(
                  fishId: state.pathParameters['id'],
                ),
              ),
            ],
          ),

          // Tekne (accessed from Tanımlar, kept in shell for nav highlighting)
          GoRoute(
            path: '/boat',
            name: 'boat',
            builder: (context, state) => const BoatListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'boat-new',
                builder: (context, state) => const BoatFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'boat-edit',
                builder: (context, state) => BoatFormScreen(
                  boatId: state.pathParameters['id'],
                ),
              ),
            ],
          ),

          // Profil
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'change-password',
                name: 'change-password',
                builder: (context, state) => const ChangePasswordScreen(),
              ),
              GoRoute(
                path: 'admin/users',
                name: 'admin-users',
                builder: (context, state) => const UserManagementScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'admin-user-new',
                    builder: (context, state) => const UserFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: 'admin-user-edit',
                    builder: (context, state) => UserFormScreen(
                      userId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'admin/audit-logs',
                name: 'admin-audit-logs',
                builder: (context, state) => const AuditLogsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ─────────────── Tanımlar Screen ───────────────

class _TanimlarScreen extends StatelessWidget {
  const _TanimlarScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Tanımlar')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Kayıt Tanımları',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Balık türleri ve tekne kayıtlarını yönetin.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _TanimCard(
                    icon: Icons.set_meal_rounded,
                    title: 'Balık Türleri',
                    subtitle: 'Balık çeşitlerini ekle, düzenle, sil',
                    color: AppColors.primary,
                    onTap: () => context.go('/fish'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TanimCard(
                    icon: Icons.sailing_rounded,
                    title: 'Tekneler',
                    subtitle: 'Tekne kayıtlarını yönet',
                    color: AppColors.primaryLight,
                    onTap: () => context.go('/boat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TanimCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TanimCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius:
              BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(AppSpacing.borderRadius),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'Görüntüle',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: color, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Main Shell with Bottom Nav ───────────────

class _MainShell extends ConsumerWidget {
  final Widget child;
  const _MainShell({required this.child});

  static const _navItems = [
    BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded), label: 'Ana Sayfa'),
    BottomNavigationBarItem(
        icon: Icon(Icons.gavel_rounded), label: 'Mezat'),
    BottomNavigationBarItem(
        icon: Icon(Icons.store_rounded), label: 'Cariler'),
    BottomNavigationBarItem(
        icon: Icon(Icons.tune_rounded), label: 'Tanımlar'),
    BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded), label: 'Profil'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/auction')) { return 1; }
    if (location.startsWith('/cari')) { return 2; }
    if (location.startsWith('/tanimlar') ||
        location.startsWith('/fish') ||
        location.startsWith('/boat')) { return 3; }
    if (location.startsWith('/profile')) { return 4; }
    return 0; // /dashboard
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/auction');
      case 2:
        context.go('/cari');
      case 3:
        context.go('/tanimlar');
      case 4:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline) const _OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) => _onTap(context, i),
        items: _navItems,
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.error,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs, horizontal: AppSpacing.md),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'İnternet bağlantısı yok',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
