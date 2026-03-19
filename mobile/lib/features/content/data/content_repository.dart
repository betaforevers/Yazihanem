import 'package:yazihanem_mobile/features/content/data/content_remote_source.dart';
import 'package:yazihanem_mobile/features/content/domain/models/content_list_response.dart';
import 'package:yazihanem_mobile/features/content/domain/models/content_model.dart';

/// Coordinates content remote source with local caching.
///
/// In mock mode (dev), returns sample data for UI testing.
class ContentRepository {
  final ContentRemoteSource _remoteSource;
  final bool useMock;

  ContentRepository({
    required ContentRemoteSource remoteSource,
    this.useMock = false,
  }) : _remoteSource = remoteSource;

  // ─── Mock Data ───

  static final _mockContents = [
    ContentModel(
      id: 'mock-1',
      tenantId: 'dev',
      title: 'Flutter ile Modern Uygulama Geliştirme',
      slug: 'flutter-ile-modern-uygulama-gelistirme',
      body: 'Flutter, Google tarafından geliştirilen açık kaynaklı bir UI toolkit\'tir. '
          'Tek bir kod tabanından iOS, Android, web ve masaüstü uygulamaları oluşturmanıza olanak tanır. '
          'Bu yazıda Flutter\'ın temel kavramlarını ve en iyi uygulamalarını inceliyoruz.',
      status: ContentStatus.published,
      authorId: 'dev-mock-user-001',
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ContentModel(
      id: 'mock-2',
      tenantId: 'dev',
      title: 'Riverpod State Management Rehberi',
      slug: 'riverpod-state-management-rehberi',
      body: 'Riverpod, Flutter için modern ve güvenli bir state management çözümüdür. '
          'Provider pattern\'inin evrimleşmiş hali olan Riverpod, compile-time güvenliği, '
          'bağımsız test edilebilirlik ve provider override desteği sunar.',
      status: ContentStatus.draft,
      authorId: 'dev-mock-user-001',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    ContentModel(
      id: 'mock-3',
      tenantId: 'dev',
      title: 'Clean Architecture ile Proje Yapılandırma',
      slug: 'clean-architecture-ile-proje-yapilandirma',
      body: 'Clean Architecture, yazılım projelerinde katmanlı bir yapı oluşturarak '
          'kodun test edilebilirliğini ve bakımını kolaylaştırır. Domain, Data ve '
          'Presentation katmanları arasında net sınırlar çizer.',
      status: ContentStatus.published,
      authorId: 'dev-mock-user-001',
      publishedAt: DateTime.now().subtract(const Duration(days: 7)),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ContentModel(
      id: 'mock-4',
      tenantId: 'dev',
      title: 'Go Fiber Backend API Tasarımı',
      slug: 'go-fiber-backend-api-tasarimi',
      body: 'Go Fiber, Express.js\'ten ilham alan yüksek performanslı bir web framework\'tür. '
          'Bu yazıda Fiber ile RESTful API tasarımı, middleware kullanımı ve '
          'veritabanı entegrasyonu konularını ele alıyoruz.',
      status: ContentStatus.archived,
      authorId: 'dev-mock-user-001',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    ContentModel(
      id: 'mock-5',
      tenantId: 'dev',
      title: 'Multi-Tenant SaaS Mimarisi',
      slug: 'multi-tenant-saas-mimarisi',
      body: 'Multi-tenant mimari, aynı uygulama kodunun birden fazla müşteriye hizmet vermesini sağlar. '
          'Bu rehberde tenant izolasyonu, veritabanı stratejileri ve güvenlik önerilerini inceliyoruz.',
      status: ContentStatus.draft,
      authorId: 'dev-mock-user-001',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  int _mockIdCounter = 100;

  // ─── API Methods ───

  /// List content with optional status filter and pagination.
  Future<ContentListResponse> listContent({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      var items = List<ContentModel>.from(_mockContents);
      if (status != null && status.isNotEmpty) {
        items = items.where((c) => c.status.value == status).toList();
      }
      return ContentListResponse(
        contents: items,
        page: page,
        pageSize: pageSize,
      );
    }
    return _remoteSource.list(status: status, page: page, pageSize: pageSize);
  }

  /// Get content by ID.
  Future<ContentModel> getContent(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockContents.firstWhere((c) => c.id == id);
    }
    return _remoteSource.getById(id);
  }

  /// Create new content.
  Future<ContentModel> createContent({
    required String title,
    required String slug,
    required String body,
    String status = 'draft',
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      _mockIdCounter++;
      final content = ContentModel(
        id: 'mock-$_mockIdCounter',
        tenantId: 'dev',
        title: title,
        slug: slug,
        body: body,
        status: ContentStatus.fromString(status),
        authorId: 'dev-mock-user-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockContents.insert(0, content);
      return content;
    }
    return _remoteSource.create(
        title: title, slug: slug, body: body, status: status);
  }

  /// Update content.
  Future<ContentModel> updateContent(String id, {
    String? title,
    String? slug,
    String? body,
    String? status,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _mockContents.indexWhere((c) => c.id == id);
      if (index == -1) throw Exception('İçerik bulunamadı');
      final updated = _mockContents[index].copyWith(
        title: title,
        slug: slug,
        body: body,
        status: status != null ? ContentStatus.fromString(status) : null,
        updatedAt: DateTime.now(),
      );
      _mockContents[index] = updated;
      return updated;
    }
    return _remoteSource.update(id,
        title: title, slug: slug, body: body, status: status);
  }

  /// Delete content.
  Future<void> deleteContent(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockContents.removeWhere((c) => c.id == id);
      return;
    }
    return _remoteSource.delete(id);
  }

  /// Publish content.
  Future<ContentModel> publishContent(String id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _mockContents.indexWhere((c) => c.id == id);
      if (index == -1) throw Exception('İçerik bulunamadı');
      final published = _mockContents[index].copyWith(
        status: ContentStatus.published,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockContents[index] = published;
      return published;
    }
    return _remoteSource.publish(id);
  }
}
