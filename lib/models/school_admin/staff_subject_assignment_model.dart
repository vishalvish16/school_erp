// =============================================================================
// FILE: lib/models/school_admin/staff_subject_assignment_model.dart
// PURPOSE: Staff subject assignment model for School Admin portal.
// =============================================================================

class StaffSubjectAssignmentModel {
  final String id;
  final String staffId;
  final String classId;
  final String className;
  final String? sectionId;
  final String? sectionName;
  final String subject;
  final String academicYear;
  final bool isActive;

  const StaffSubjectAssignmentModel({
    required this.id,
    required this.staffId,
    required this.classId,
    required this.className,
    this.sectionId,
    this.sectionName,
    required this.subject,
    required this.academicYear,
    required this.isActive,
  });

  factory StaffSubjectAssignmentModel.fromJson(Map<String, dynamic> json) {
    // Prisma JS client returns camelCase; nested relation is 'class_' (literal).
    final classObj = json['class_'] as Map<String, dynamic>?;
    final sectionObj = json['section'] as Map<String, dynamic>?;
    return StaffSubjectAssignmentModel(
      id: json['id'] as String? ?? '',
      staffId: (json['staffId'] ?? json['staff_id']) as String? ?? '',
      classId: (json['classId'] ?? json['class_id']) as String? ?? '',
      // Prefer nested relation name, fall back to flat field
      className: classObj?['name'] as String? ??
          (json['className'] ?? json['class_name']) as String? ??
          '',
      sectionId: (json['sectionId'] ?? json['section_id']) as String?,
      sectionName: sectionObj?['name'] as String? ??
          (json['sectionName'] ?? json['section_name']) as String?,
      subject: json['subject'] as String? ?? '',
      academicYear:
          (json['academicYear'] ?? json['academic_year']) as String? ?? '',
      isActive: (json['isActive'] ?? json['is_active']) as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
        'subject': subject,
        'academicYear': academicYear,
      };

  String get classSectionLabel =>
      sectionName != null ? '$className - $sectionName' : className;
}
