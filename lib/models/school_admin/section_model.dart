// =============================================================================
// FILE: lib/models/school_admin/section_model.dart
// PURPOSE: Section model for School Admin portal.
// =============================================================================

class SectionModel {
  final String id;
  final String schoolId;
  final String classId;
  final String name;
  final String? classTeacherId;
  final String? classTeacherName;
  final int capacity;
  final bool isActive;
  final DateTime createdAt;

  const SectionModel({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.name,
    this.classTeacherId,
    this.classTeacherName,
    required this.capacity,
    required this.isActive,
    required this.createdAt,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      classTeacherId: json['class_teacher_id'] as String?,
      classTeacherName: json['class_teacher_name'] as String?,
      capacity: (json['capacity'] as num?)?.toInt() ?? 40,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
