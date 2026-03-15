// =============================================================================
// FILE: lib/models/student/student_notice_model.dart
// PURPOSE: Notice model for the Student portal.
// =============================================================================

class StudentNoticeModel {
  final String id;
  final String title;
  final String body;
  final String? publishedAt;
  final String? expiresAt;
  final bool isPinned;

  const StudentNoticeModel({
    required this.id,
    required this.title,
    required this.body,
    this.publishedAt,
    this.expiresAt,
    this.isPinned = false,
  });

  factory StudentNoticeModel.fromJson(Map<String, dynamic> json) {
    return StudentNoticeModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['content'] as String? ?? '',
      publishedAt: json['published_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }
}
