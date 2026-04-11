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
    final publishedAt = json['published_at'] ?? json['publishedAt'];
    final expiresAt = json['expires_at'] ?? json['expiresAt'];
    return StudentNoticeModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['content'] as String? ?? '',
      publishedAt: publishedAt?.toString(),
      expiresAt: expiresAt?.toString(),
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
    );
  }
}
