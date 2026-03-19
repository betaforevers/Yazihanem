import 'package:yazihanem_mobile/features/content/domain/models/content_model.dart';

/// Paginated content list response from backend.
///
/// Backend returns: `{contents: [...], page: 1, page_size: 20}`
class ContentListResponse {
  final List<ContentModel> contents;
  final int page;
  final int pageSize;

  const ContentListResponse({
    required this.contents,
    required this.page,
    required this.pageSize,
  });

  factory ContentListResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['contents'] as List<dynamic>?)
            ?.map((e) => ContentModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ContentListResponse(
      contents: items,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
    );
  }

  bool get hasMore => contents.length >= pageSize;
  bool get isEmpty => contents.isEmpty;
}
