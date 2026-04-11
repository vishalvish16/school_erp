// =============================================================================
// FILE: lib/models/school_admin/student_notice_model.dart
// PURPOSE: Model for student-specific notices (sent by admin/staff).
// =============================================================================

class StudentNoticeModel {
  final String id;
  final String subject;
  final String message;
  final String priority;
  final bool targetStudent;
  final bool targetParent;
  final String? sentByName;
  final String? sentById;
  final DateTime createdAt;

  const StudentNoticeModel({
    required this.id,
    required this.subject,
    required this.message,
    required this.priority,
    required this.targetStudent,
    required this.targetParent,
    this.sentByName,
    this.sentById,
    required this.createdAt,
  });

  factory StudentNoticeModel.fromJson(Map<String, dynamic> json) {
    final sentBy = json['sentBy'] as Map<String, dynamic>?;
    return StudentNoticeModel(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      priority: json['priority'] as String? ?? 'NORMAL',
      targetStudent: json['targetStudent'] as bool? ?? false,
      targetParent: json['targetParent'] as bool? ?? false,
      sentByName: sentBy?['name'] as String?,
      sentById: sentBy?['id'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
