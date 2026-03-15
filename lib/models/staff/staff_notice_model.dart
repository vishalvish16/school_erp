// =============================================================================
// FILE: lib/models/staff/staff_notice_model.dart
// PURPOSE: School notice model for the Staff/Clerk portal.
// =============================================================================

class StaffNoticeModel {
  final String id;
  final String schoolId;
  final String title;
  final String content;
  final String? category;
  final bool isPinned;
  final DateTime? expiresAt;
  final String? createdByName;
  final DateTime createdAt;

  const StaffNoticeModel({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.content,
    this.category,
    this.isPinned = false,
    this.expiresAt,
    this.createdByName,
    required this.createdAt,
  });

  factory StaffNoticeModel.fromJson(Map<String, dynamic> json) {
    return StaffNoticeModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
