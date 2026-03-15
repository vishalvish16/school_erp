// =============================================================================
// FILE: lib/models/school_admin/school_class_model.dart
// PURPOSE: School class and section models for School Admin portal.
// =============================================================================

class SectionSummary {
  final String id;
  final String name;
  final int studentCount;
  final bool isActive;

  const SectionSummary({
    required this.id,
    required this.name,
    required this.studentCount,
    required this.isActive,
  });

  factory SectionSummary.fromJson(Map<String, dynamic> json) {
    return SectionSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      studentCount: (json['student_count'] as num?)?.toInt() ??
          (json['studentCount'] as num?)?.toInt() ??
          0,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }
}

class SchoolClassModel {
  final String id;
  final String schoolId;
  final String name;
  final int? numeric;
  final bool isActive;
  final List<SectionSummary> sections;
  final DateTime createdAt;

  const SchoolClassModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.numeric,
    required this.isActive,
    required this.sections,
    required this.createdAt,
  });

  factory SchoolClassModel.fromJson(Map<String, dynamic> json) {
    final sectionsList = json['sections'];
    final sections = sectionsList is List
        ? sectionsList
            .map((e) => SectionSummary.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ))
            .toList()
        : <SectionSummary>[];

    return SchoolClassModel(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      numeric: (json['numeric'] as num?)?.toInt(),
      isActive: json['is_active'] as bool? ?? true,
      sections: sections,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
