// =============================================================================
// FILE: lib/models/school_admin/school_notice_model.dart
// PURPOSE: School notice (notice board) model for School Admin portal.
// =============================================================================

class SchoolNoticeModel {
  final String id;
  final String schoolId;
  final String title;
  final String body;
  final String? targetRole; // all | teacher | student | parent
  final bool isPinned;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final String createdBy;
  final DateTime createdAt;

  const SchoolNoticeModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.body,
    this.targetRole,
    required this.isPinned,
    this.publishedAt,
    this.expiresAt,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory SchoolNoticeModel.fromJson(Map<String, dynamic> json) {
    return SchoolNoticeModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      targetRole: json['target_role'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        if (targetRole != null) 'target_role': targetRole,
        'is_pinned': isPinned,
        if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}
