// =============================================================================
// FILE: lib/models/school_admin/staff_qualification_model.dart
// PURPOSE: Staff qualification model for School Admin portal.
// =============================================================================

class StaffQualificationModel {
  final String id;
  final String staffId;
  final String degree;
  final String institution;
  final String? boardOrUniversity;
  final int? yearOfPassing;
  final String? gradeOrPercentage;
  final bool isHighest;
  final DateTime createdAt;

  const StaffQualificationModel({
    required this.id,
    required this.staffId,
    required this.degree,
    required this.institution,
    this.boardOrUniversity,
    this.yearOfPassing,
    this.gradeOrPercentage,
    required this.isHighest,
    required this.createdAt,
  });

  factory StaffQualificationModel.fromJson(Map<String, dynamic> json) {
    // Prisma JS client returns camelCase; accept both forms for resilience.
    final yop = json['yearOfPassing'] ?? json['year_of_passing'];
    final createdRaw = json['createdAt'] ?? json['created_at'];
    return StaffQualificationModel(
      id: json['id'] as String? ?? '',
      staffId: (json['staffId'] ?? json['staff_id']) as String? ?? '',
      degree: json['degree'] as String? ?? '',
      institution: json['institution'] as String? ?? '',
      boardOrUniversity:
          (json['boardOrUniversity'] ?? json['board_or_university']) as String?,
      yearOfPassing: yop != null ? (yop as num).toInt() : null,
      gradeOrPercentage:
          (json['gradeOrPercentage'] ?? json['grade_or_percentage']) as String?,
      isHighest: (json['isHighest'] ?? json['is_highest']) as bool? ?? false,
      createdAt: createdRaw != null
          ? DateTime.tryParse(createdRaw as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'institution': institution,
        if (boardOrUniversity != null) 'boardOrUniversity': boardOrUniversity,
        if (yearOfPassing != null) 'yearOfPassing': yearOfPassing,
        if (gradeOrPercentage != null) 'gradeOrPercentage': gradeOrPercentage,
        'isHighest': isHighest,
      };
}
