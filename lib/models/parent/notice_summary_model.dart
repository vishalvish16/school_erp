// =============================================================================
// FILE: lib/models/parent/notice_summary_model.dart
// PURPOSE: Notice summary model for Parent Portal.
// =============================================================================

class NoticeSummaryModel {
  final String id;
  final String title;
  final String body;
  final bool isPinned;
  final DateTime? publishedAt;
  final DateTime? expiresAt;

  const NoticeSummaryModel({
    required this.id,
    required this.title,
    required this.body,
    this.isPinned = false,
    this.publishedAt,
    this.expiresAt,
  });

  factory NoticeSummaryModel.fromJson(Map<String, dynamic> json) {
    final pub = json['publishedAt'] ?? json['published_at'];
    final exp = json['expiresAt'] ?? json['expires_at'];
    return NoticeSummaryModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? json['is_pinned'] as bool? ?? false,
      publishedAt: pub != null ? DateTime.tryParse(pub as String) : null,
      expiresAt: exp != null ? DateTime.tryParse(exp as String) : null,
    );
  }
}
