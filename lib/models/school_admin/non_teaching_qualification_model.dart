// =============================================================================
// FILE: lib/models/school_admin/non_teaching_qualification_model.dart
// PURPOSE: Qualification model for Non-Teaching Staff.
// =============================================================================

class NonTeachingQualificationModel {
  final String id;
  final String staffId;
  final String degree;
  final String institution;
  final String? boardOrUniversity;
  final int? yearOfPassing;
  final String? gradeOrPercentage;
  final bool isHighest;
  final DateTime? createdAt;

  const NonTeachingQualificationModel({
    required this.id,
    required this.staffId,
    required this.degree,
    required this.institution,
    this.boardOrUniversity,
    this.yearOfPassing,
    this.gradeOrPercentage,
    required this.isHighest,
    this.createdAt,
  });

  factory NonTeachingQualificationModel.fromJson(Map<String, dynamic> json) {
    final passingRaw =
        json['yearOfPassing'] ?? json['year_of_passing'];
    final gradeRaw =
        json['gradeOrPercentage'] ?? json['grade_or_percentage'];
    final boardRaw =
        json['boardOrUniversity'] ?? json['board_or_university'];
    final createdRaw = json['createdAt'] ?? json['created_at'];
    return NonTeachingQualificationModel(
      id: json['id'] as String? ?? '',
      staffId: (json['staffId'] ?? json['staff_id']) as String? ?? '',
      degree: json['degree'] as String? ?? '',
      institution: json['institution'] as String? ?? '',
      boardOrUniversity: boardRaw as String?,
      yearOfPassing:
          passingRaw != null ? (passingRaw as num).toInt() : null,
      gradeOrPercentage: gradeRaw as String?,
      isHighest:
          (json['isHighest'] ?? json['is_highest']) as bool? ?? false,
      createdAt: createdRaw != null
          ? DateTime.tryParse(createdRaw.toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'institution': institution,
        if (boardOrUniversity != null)
          'board_or_university': boardOrUniversity,
        if (yearOfPassing != null) 'year_of_passing': yearOfPassing,
        if (gradeOrPercentage != null)
          'grade_or_percentage': gradeOrPercentage,
        'is_highest': isHighest,
      };
}
