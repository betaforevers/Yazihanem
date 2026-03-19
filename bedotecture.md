# Yazıhanem Flutter Mobil Uygulama - Mimari Planı (Bedotecture)

**Tarih**: 2026-03-05  
**Platform**: Flutter 3.x (iOS + Android)  
**Mimari**: Clean Architecture + Feature-First  
**State Management**: Riverpod  
**Durum**: 📋 Planlama Aşaması

---

## 📋 İÇİNDEKİLER

1. [Genel Bakış](#genel-bakış)
2. [Proje Yapısı](#proje-yapısı)
3. [Katman Mimarisi](#katman-mimarisi)
4. [Veri Modelleri](#veri-modelleri)
5. [API Entegrasyonu](#api-entegrasyonu)
6. [State Management](#state-management)
7. [Ekran ve Navigasyon Yapısı](#ekran-ve-navigasyon-yapısı)
8. [Offline-First Strateji](#offline-first-strateji)
9. [Güvenlik](#güvenlik)
10. [Bağımlılıklar](#bağımlılıklar)
11. [İmplementasyon Roadmap](#implementasyon-roadmap)

---

## 🎯 GENEL BAKIŞ

Yazıhanem mobil uygulaması, mevcut Go + Fiber backend API'sine (58 endpoint) bağlanan, multi-tenant içerik yönetim sistemidir. Uygulama **editör/yazar** odaklıdır; içerik oluşturma, düzenleme, yayınlama ve medya yönetimi yapılabilir.

### Hedef Kullanıcı Profilleri

| Rol | Yetkiler | Kullanım Senaryosu |
|-----|----------|-------------------|
| **Admin** | Tam erişim, kullanıcı yönetimi | Tenant yönetimi, kullanıcı CRUD |
| **Editor** | İçerik CRUD + yayınlama | Yazı yazma, düzenleme, yayın |
| **Viewer** | Sadece okuma | İçerik görüntüleme |

### Platform Hedefleri

- **Android**: API 24+ (Android 7.0+)
- **iOS**: iOS 13+
- **Min Flutter SDK**: 3.19+

---

## 📁 PROJE YAPISI

```
mobile/
├── lib/
│   ├── main.dart                        # Uygulama giriş noktası
│   ├── app.dart                         # MaterialApp + GoRouter + ProviderScope
│   │
│   ├── core/                            # Çekirdek altyapı (feature-bağımsız)
│   │   ├── api/
│   │   │   ├── api_client.dart          # Dio HTTP client (interceptors)
│   │   │   ├── api_endpoints.dart       # Tüm endpoint sabitleri
│   │   │   ├── api_exceptions.dart      # API hata sınıfları
│   │   │   └── api_interceptors.dart    # Auth, tenant, logging interceptors
│   │   ├── config/
│   │   │   ├── app_config.dart          # Environment config (dev/staging/prod)
│   │   │   └── theme_config.dart        # Tema tanımları (renk, tipografi)
│   │   ├── di/
│   │   │   └── providers.dart           # Global Riverpod provider'lar
│   │   ├── routing/
│   │   │   ├── app_router.dart          # GoRouter tanımları
│   │   │   └── route_guards.dart        # Auth guard, role guard
│   │   ├── storage/
│   │   │   ├── secure_storage.dart      # flutter_secure_storage (JWT)
│   │   │   └── local_db.dart            # Hive/Isar offline cache
│   │   └── utils/
│   │       ├── extensions.dart          # Dart extension'lar
│   │       ├── validators.dart          # Form validasyonları
│   │       └── constants.dart           # Sabitler
│   │
│   ├── features/                        # Feature-first modüller
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   └── auth_remote_source.dart
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── user_model.dart
│   │   │   │   │   └── auth_token.dart
│   │   │   │   └── auth_state.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   ├── tenant_select_screen.dart
│   │   │       │   └── change_password_screen.dart
│   │   │       └── widgets/
│   │   │           └── login_form.dart
│   │   │
│   │   ├── content/
│   │   │   ├── data/
│   │   │   │   ├── content_repository.dart
│   │   │   │   ├── content_remote_source.dart
│   │   │   │   └── content_local_source.dart
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       └── content_model.dart
│   │   │   ├── providers/
│   │   │   │   ├── content_list_provider.dart
│   │   │   │   └── content_detail_provider.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── content_list_screen.dart
│   │   │       │   ├── content_detail_screen.dart
│   │   │       │   └── content_editor_screen.dart
│   │   │       └── widgets/
│   │   │           ├── content_card.dart
│   │   │           ├── rich_text_editor.dart
│   │   │           └── status_badge.dart
│   │   │
│   │   ├── media/
│   │   │   ├── data/
│   │   │   │   ├── media_repository.dart
│   │   │   │   └── media_remote_source.dart
│   │   │   ├── domain/
│   │   │   │   └── models/
│   │   │   │       └── media_model.dart
│   │   │   ├── providers/
│   │   │   │   └── media_provider.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── media_gallery_screen.dart
│   │   │       └── widgets/
│   │   │           ├── media_picker.dart
│   │   │           ├── upload_progress.dart
│   │   │           └── media_thumbnail.dart
│   │   │
│   │   ├── admin/
│   │   │   ├── data/
│   │   │   │   └── admin_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── admin_provider.dart
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           ├── user_management_screen.dart
│   │   │           ├── audit_logs_screen.dart
│   │   │           └── dashboard_screen.dart
│   │   │
│   │   ├── profile/
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           └── profile_screen.dart
│   │   │
│   │   └── settings/
│   │       └── presentation/
│   │           └── screens/
│   │               └── settings_screen.dart
│   │
│   └── shared/                          # Paylaşılan UI bileşenleri
│       ├── widgets/
│       │   ├── app_scaffold.dart
│       │   ├── loading_indicator.dart
│       │   ├── error_widget.dart
│       │   ├── empty_state.dart
│       │   ├── pagination_list.dart
│       │   └── confirm_dialog.dart
│       └── theme/
│           ├── app_colors.dart
│           ├── app_text_styles.dart
│           └── app_spacing.dart
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 🏗️ KATMAN MİMARİSİ

Clean Architecture ile 4 katmanlı yapı kullanılır. Her feature kendi içinde bu katmanları barındırır.

```
┌──────────────────────────────────────────────┐
│             Presentation Layer               │
│   (Screens, Widgets, GoRouter)               │
└──────────────┬───────────────────────────────┘
               │ Riverpod Providers
               ▼
┌──────────────────────────────────────────────┐
│             Providers Layer                  │
│   (StateNotifier, AsyncNotifier, Provider)   │
└──────────────┬───────────────────────────────┘
               │ Repository Interface
               ▼
┌──────────────────────────────────────────────┐
│               Data Layer                     │
│   (Repository Impl, Remote/Local Sources)    │
└──────────────┬───────────────────────────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
┌──────────────┐ ┌──────────────┐
│  Remote API  │ │  Local Cache │
│  (Dio HTTP)  │ │  (Hive/Isar) │
└──────────────┘ └──────────────┘
```

### Bağımlılık Kuralı

- **Presentation** → Providers → Data → Core
- İç katmanlar dış katmanlara **asla** bağımlı olamaz
- Domain modelleri hiçbir framework'e bağımlı değildir

---

## 📊 VERİ MODELLERİ

Backend entity'leri ile birebir eşleşen Dart model sınıfları:

### UserModel (Backend: `entity/user.go`)

```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String tenantId,
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,        // admin | editor | viewer
    required bool isActive,
    DateTime? lastLoginAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

enum UserRole { admin, editor, viewer }
```

### ContentModel (Backend: `entity/content.go`)

```dart
@freezed
class ContentModel with _$ContentModel {
  const factory ContentModel({
    required String id,
    required String tenantId,
    required String title,
    required String slug,
    required String body,
    required ContentStatus status,  // draft | published | archived
    required String authorId,
    DateTime? publishedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ContentModel;

  factory ContentModel.fromJson(Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);
}

enum ContentStatus { draft, published, archived }
```

### MediaModel (Backend: `entity/media.go`)

```dart
@freezed
class MediaModel with _$MediaModel {
  const factory MediaModel({
    required String id,
    required String tenantId,
    required String filename,
    required String originalFilename,
    required String mimeType,
    required int sizeBytes,
    required String storagePath,
    required String uploadedBy,
    required DateTime createdAt,
  }) = _MediaModel;

  factory MediaModel.fromJson(Map<String, dynamic> json) =>
      _$MediaModelFromJson(json);
}
```

### AuthToken

```dart
@freezed
class AuthToken with _$AuthToken {
  const factory AuthToken({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required UserModel user,
  }) = _AuthToken;
}
```

---

## 🌐 API ENTEGRASYONU

### Dio HTTP Client Yapısı

```dart
// core/api/api_client.dart
class ApiClient {
  late final Dio _dio;

  ApiClient({required AppConfig config}) {
    _dio = Dio(BaseOptions(
      baseUrl: config.apiBaseUrl,  // https://api.yazihanem.com
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 30),
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(secureStorage),     // JWT ekleme
      TenantInterceptor(),                // X-Tenant-Domain header
      LoggingInterceptor(),               // Debug logging
      RetryInterceptor(retries: 3),       // Retry on 5xx
    ]);
  }
}
```

### Backend API Eşleştirmesi

| Feature | Backend Endpoint | Mobil Metot |
|---------|-----------------|-------------|
| **Auth** | `POST /api/v1/auth/login` | `login(email, password)` |
| | `POST /api/v1/auth/logout` | `logout()` |
| | `POST /api/v1/auth/refresh` | `refreshToken()` |
| | `GET /api/v1/auth/me` | `getCurrentUser()` |
| | `POST /api/v1/auth/change-password` | `changePassword()` |
| **Content** | `GET /api/v1/content` | `listContent(status, page)` |
| | `GET /api/v1/content/my` | `listMyContent(page)` |
| | `GET /api/v1/content/:id` | `getContent(id)` |
| | `GET /api/v1/content/slug/:slug` | `getContentBySlug(slug)` |
| | `POST /api/v1/content` | `createContent(data)` |
| | `PUT /api/v1/content/:id` | `updateContent(id, data)` |
| | `DELETE /api/v1/content/:id` | `deleteContent(id)` |
| | `PATCH /api/v1/content/:id/publish` | `publishContent(id)` |
| **Media** | `POST /api/v1/media/upload` | `uploadMedia(file)` |
| | `GET /api/v1/media` | `listMedia(page)` |
| | `GET /api/v1/media/:id` | `getMedia(id)` |
| | `DELETE /api/v1/media/:id` | `deleteMedia(id)` |
| **Admin** | `GET /api/v1/admin/users` | `listUsers(page)` |
| | `POST /api/v1/admin/users` | `createUser(data)` |
| | `PUT /api/v1/admin/users/:id` | `updateUser(id, data)` |
| | `DELETE /api/v1/admin/users/:id` | `deleteUser(id)` |
| | `GET /api/v1/admin/audit-logs` | `getAuditLogs(filters)` |

---

## 🔄 STATE MANAGEMENT (Riverpod)

### Provider Hiyerarşisi

```
appConfigProvider (Provider)
    │
    ├── apiClientProvider (Provider)
    │       │
    │       ├── authRepositoryProvider (Provider)
    │       │       └── authStateProvider (StateNotifierProvider)
    │       │
    │       ├── contentRepositoryProvider (Provider)
    │       │       ├── contentListProvider (AsyncNotifierProvider)
    │       │       └── contentDetailProvider (FamilyAsyncNotifierProvider)
    │       │
    │       ├── mediaRepositoryProvider (Provider)
    │       │       └── mediaListProvider (AsyncNotifierProvider)
    │       │
    │       └── adminRepositoryProvider (Provider)
    │               └── userListProvider (AsyncNotifierProvider)
    │
    └── localDbProvider (Provider)
            └── offlineCacheProvider (Provider)
```

### Auth State Örneği

```dart
// features/auth/providers/auth_provider.dart

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<AuthState> build() => const AsyncValue.data(AuthState.initial());

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final token = await repo.login(email, password);
      await ref.read(secureStorageProvider).saveToken(token);
      state = AsyncValue.data(AuthState.authenticated(token.user));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(secureStorageProvider).clearToken();
    state = const AsyncValue.data(AuthState.initial());
  }
}
```

---

## 🧭 EKRAN VE NAVİGASYON YAPISI

### GoRouter Navigasyon Ağacı

```
/login                           → LoginScreen
/tenant-select                   → TenantSelectScreen

/  (ShellRoute - ana scaffold + BottomNavBar)
├── /dashboard                   → DashboardScreen (Home tab)
├── /content                     → ContentListScreen (İçerik tab)
│   ├── /content/new             → ContentEditorScreen (yeni)
│   ├── /content/:id             → ContentDetailScreen
│   └── /content/:id/edit        → ContentEditorScreen (düzenleme)
├── /media                       → MediaGalleryScreen (Medya tab)
└── /profile                     → ProfileScreen (Profil tab)
    ├── /profile/settings        → SettingsScreen
    ├── /profile/change-password → ChangePasswordScreen
    └── /profile/admin           → (Admin-only routes)
        ├── /profile/admin/users         → UserManagementScreen
        └── /profile/admin/audit-logs    → AuditLogsScreen
```

### BottomNavigationBar Yapısı

| Tab | İkon | Ekran | Roller |
|-----|------|-------|--------|
| Ana Sayfa | `Icons.dashboard` | Dashboard | Tümü |
| İçerik | `Icons.article` | Content List | Tümü |
| Medya | `Icons.photo_library` | Media Gallery | Editor+ |
| Profil | `Icons.person` | Profile | Tümü |

### Route Guard Mantığı

```dart
GoRouter(
  redirect: (context, state) {
    final auth = ref.read(authStateProvider);
    final isLoggedIn = auth.isAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) return '/dashboard';
    return null;
  },
);
```

---

## 💾 OFFLINE-FIRST STRATEJİ

### Hive ile Yerel Önbellek

```yaml
Cache Stratejisi:
  Content List:    Cache-first, 5 dk TTL, arka planda güncelle
  Content Detail:  Cache-first, 1 saat TTL
  Media List:      Network-first (medya sık değişir)
  User Profile:    Cache-first, 24 saat TTL
  Tenant Metadata: Cache-first, 1 saat TTL

Offline Modda:
  - Taslak içerik oluşturma (yerel kayıt)
  - Mevcut içerikleri okuma (cache'den)
  - Online olunca otomatik sync (queue-based)
```

### Offline Sync Akışı

```
[Kullanıcı işlem yapar]
    │
    ├── Online? → API'ye gönder → Başarılı → Cache güncelle
    │
    └── Offline? → Hive'a kaydet (pending_operations)
                      │
                      └── Bağlantı geldiğinde → SyncManager
                            ├── Sırayla API'ye gönder
                            ├── Conflict resolution (son yazma kazanır)
                            └── Pending temizle
```

---

## 🔐 GÜVENLİK

### Token Yönetimi

```yaml
JWT Saklama:
  Araç: flutter_secure_storage
  Access Token TTL:  15 dakika (backend'den)
  Refresh Token TTL: 7 gün (backend'den)

Otomatik Yenileme:
  - Dio interceptor ile 401 yakalanır
  - Refresh token ile yeni access token alınır
  - Refresh da başarısızsa → login ekranına yönlendir

Güvenlik Kuralları:
  ❌ Token'ı SharedPreferences'a KAYDETME
  ❌ Token'ı log'a YAZMA
  ✅ flutter_secure_storage (Keychain/Keystore)
  ✅ Certificate pinning (production)
  ✅ Root/Jailbreak detection (opsiyonel)
```

### Tenant İzolasyonu (Mobil Tarafta)

```dart
// Her API isteğine tenant bilgisi eklenir
class TenantInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, handler) {
    final tenantDomain = ref.read(currentTenantProvider)?.domain;
    if (tenantDomain != null) {
      options.headers['X-Tenant-Domain'] = tenantDomain;
    }
    handler.next(options);
  }
}
```

---

## 📦 BAĞIMLILIKLAR (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Networking
  dio: ^5.4.0
  retrofit: ^4.1.0           # Type-safe API client (code generation)
  connectivity_plus: ^6.0.0  # Bağlantı durumu takibi

  # Routing
  go_router: ^14.0.0

  # Local Storage
  hive_flutter: ^1.1.0       # Offline cache
  flutter_secure_storage: ^9.0.0  # JWT token saklama

  # UI & UX
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0             # Loading skeleton
  flutter_quill: ^9.0.0       # Rich text editor
  image_picker: ^1.0.0        # Medya seçimi
  file_picker: ^8.0.0         # Dosya seçimi

  # Utility
  intl: ^0.19.0               # Tarih/saat formatlama
  logger: ^2.0.0              # Logging
  url_launcher: ^6.2.0

  # Push Notifications
  firebase_core: ^2.27.0
  firebase_messaging: ^14.7.0

dev_dependencies:
  # Code Generation
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  retrofit_generator: ^8.1.0
  riverpod_generator: ^2.4.0

  # Testing
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  mocktail: ^1.0.0
```

---

## 🗓️ İMPLEMENTASYON ROADMAP

### Faz 1: Proje Altyapısı (2-3 gün)

```yaml
Görevler:
  1. Flutter projesi oluştur (flutter create)
  2. Klasör yapısını kur (core/, features/, shared/)
  3. pubspec.yaml bağımlılıkları ekle
  4. AppConfig (dev/staging/prod) ayarla
  5. Tema sistemi kur (renkler, tipografi, spacing)
  6. Dio API client + interceptors oluştur
  7. flutter_secure_storage entegrasyonu
  8. GoRouter base routing

Çıktı: Boş ama çalışan iskelet uygulama
```

### Faz 2: Authentication (3-4 gün)

```yaml
Görevler:
  1. AuthRepository (login, logout, refresh, me)
  2. AuthNotifier (Riverpod state)
  3. Token otomatik yenileme interceptor
  4. Login ekranı UI
  5. Tenant seçme ekranı
  6. Route guard (auth kontrolü)
  7. Şifre değiştirme ekranı

Bağımlılık: Backend auth endpoints (/api/v1/auth/*)
```

### Faz 3: İçerik Yönetimi (5-6 gün)

```yaml
Görevler:
  1. ContentModel + ContentRepository
  2. İçerik listesi ekranı (filtreleme, pagination)
  3. İçerik detay ekranı
  4. Rich text editör (flutter_quill)
  5. İçerik oluşturma/düzenleme
  6. Yayınlama workflow (draft → published)
  7. Slug-based preview

Bağımlılık: Backend content endpoints (/api/v1/content/*)
```

### Faz 4: Medya Yönetimi (3-4 gün)

```yaml
Görevler:
  1. MediaModel + MediaRepository
  2. Medya galerisi ekranı (grid görünüm)
  3. Fotoğraf/dosya seçme ve yükleme
  4. Upload progress gösterimi
  5. Medya silme (owner/admin)
  6. İçeriğe medya ekleme

Bağımlılık: Backend media endpoints (/api/v1/media/*)
```

### Faz 5: Admin Paneli (3-4 gün)

```yaml
Görevler:
  1. Kullanıcı yönetimi ekranı (CRUD)
  2. Rol atama (admin/editor/viewer)
  3. Kullanıcı aktif/pasif yapma
  4. Dashboard (istatistikler)
  5. Audit log görüntüleme

Sadece: admin rolündeki kullanıcılara görünür
Bağımlılık: Backend admin endpoints (/api/v1/admin/*)
```

### Faz 6: Offline & Polish (3-4 gün)

```yaml
Görevler:
  1. Hive offline cache entegrasyonu
  2. Offline taslak oluşturma
  3. Otomatik sync mekanizması
  4. Pull-to-refresh tüm listelere
  5. Skeleton loading (shimmer)
  6. Error handling & retry UI
  7. Empty state tasarımları
```

### Faz 7: Push & Yayınlama (3-4 gün)

```yaml
Görevler:
  1. Firebase Cloud Messaging entegrasyonu
  2. Deep linking (go_router + Universal Links)
  3. App icon ve splash screen
  4. Android Play Store hazırlık
  5. iOS App Store hazırlık
  6. CI/CD pipeline (Codemagic/GitHub Actions)
```

---

### 📊 Toplam Süre Tahmini

| Faz | Süre | Öncelik |
|-----|------|---------|
| Proje Altyapısı | 2-3 gün | 🔴 Kritik |
| Authentication | 3-4 gün | 🔴 Kritik |
| İçerik Yönetimi | 5-6 gün | 🔴 Kritik |
| Medya Yönetimi | 3-4 gün | 🟡 Yüksek |
| Admin Paneli | 3-4 gün | 🟡 Yüksek |
| Offline & Polish | 3-4 gün | 🟢 Orta |
| Push & Yayınlama | 3-4 gün | 🟢 Orta |
| **TOPLAM** | **22-29 gün** | |

---

## ⚠️ KRİTİK KURALLAR

```yaml
❌ YASAKLAR:
  - Token'ı plain text'e kaydetme (SharedPreferences YASAK)
  - API URL'yi hardcode etme (AppConfig kullan)
  - Widget içinde doğrudan HTTP çağrısı (Repository pattern)
  - setState() kullanımı (Riverpod kullan)
  - print() debug logging (Logger sınıfı kullan)

✅ ZORUNLULAR:
  - Her model freezed + json_serializable ile
  - Her API çağrısı try-catch error handling
  - Her ekranda loading, error, empty state
  - Formlar için validasyon (validators.dart)
  - Tüm string'ler l10n ile (çoklu dil desteği)
```
