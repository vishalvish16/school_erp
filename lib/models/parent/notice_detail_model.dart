// =============================================================================
// FILE: lib/models/parent/notice_detail_model.dart
// PURPOSE: Notice detail model for Parent Portal.
// =============================================================================

class NoticeDetailModel {
  final String id;
  final String title;
  final String body;
  final bool isPinned;
  final DateTime? publishedAt;
  final DateTime? expiresAt;

  const NoticeDetailModel({
    required this.id,
    required this.title,
    required this.body,
    this.isPinned = false,
    this.publishedAt,
    this.expiresAt,
  });

  factory NoticeDetailModel.fromJson(Map<String, dynamic> json) {
    final pub = json['publishedAt'] ?? json['published_at'];
    final exp = json['expiresAt'] ?? json['expires_at'];
    return NoticeDetailModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? json['is_pinned'] as bool? ?? false,
      publishedAt: pub != null ? DateTime.tryParse(pub as String) : null,
      expiresAt: exp != null ? DateTime.tryParse(exp as String) : null,
    );
  }
}
