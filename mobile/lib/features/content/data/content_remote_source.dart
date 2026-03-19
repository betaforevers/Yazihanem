import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/core/api/api_endpoints.dart';
import 'package:yazihanem_mobile/features/content/domain/models/content_list_response.dart';
import 'package:yazihanem_mobile/features/content/domain/models/content_model.dart';

/// Remote data source for content API calls.
///
/// Maps to backend content endpoints in content_handler.go.
class ContentRemoteSource {
  final ApiClient _apiClient;

  ContentRemoteSource(this._apiClient);

  /// Create new content.
  /// POST /api/v1/content
  Future<ContentModel> create({
    required String title,
    required String slug,
    required String body,
    String status = 'draft',
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.content,
      data: {
        'title': title,
        'slug': slug,
        'body': body,
        'status': status,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ContentModel.fromJson(data['content'] as Map<String, dynamic>);
  }

  /// Get content by ID.
  /// GET /api/v1/content/:id
  Future<ContentModel> getById(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.contentById(id));
    final data = response.data as Map<String, dynamic>;
    return ContentModel.fromJson(data['content'] as Map<String, dynamic>);
  }

  /// Get content by slug.
  /// GET /api/v1/content/slug/:slug
  Future<ContentModel> getBySlug(String slug) async {
    final response = await _apiClient.dio.get(ApiEndpoints.contentBySlug(slug));
    final data = response.data as Map<String, dynamic>;
    return ContentModel.fromJson(data['content'] as Map<String, dynamic>);
  }

  /// Update content.
  /// PUT /api/v1/content/:id
  Future<ContentModel> update(String id, {
    String? title,
    String? slug,
    String? body,
    String? status,
  }) async {
    final updateData = <String, dynamic>{};
    if (title != null) updateData['title'] = title;
    if (slug != null) updateData['slug'] = slug;
    if (body != null) updateData['body'] = body;
    if (status != null) updateData['status'] = status;

    final response = await _apiClient.dio.put(
      ApiEndpoints.contentById(id),
      data: updateData,
    );
    final data = response.data as Map<String, dynamic>;
    return ContentModel.fromJson(data['content'] as Map<String, dynamic>);
  }

  /// Delete content.
  /// DELETE /api/v1/content/:id
  Future<void> delete(String id) async {
    await _apiClient.dio.delete(ApiEndpoints.contentById(id));
  }

  /// List content with optional status filter and pagination.
  /// GET /api/v1/content?status=draft&page=1&page_size=20
  Future<ContentListResponse> list({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.dio.get(
      ApiEndpoints.content,
      queryParameters: queryParams,
    );
    return ContentListResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// List current user's content.
  /// GET /api/v1/content/my?page=1&page_size=20
  Future<ContentListResponse> listMy({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.contentMy,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return ContentListResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// Publish content.
  /// POST /api/v1/content/:id/publish
  Future<ContentModel> publish(String id) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.contentPublish(id),
    );
    final data = response.data as Map<String, dynamic>;
    return ContentModel.fromJson(data['content'] as Map<String, dynamic>);
  }
}
