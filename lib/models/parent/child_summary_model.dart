// =============================================================================
// FILE: lib/models/parent/child_summary_model.dart
// PURPOSE: Child summary model for Parent Portal children list.
// =============================================================================

class ChildSummaryModel {
  final String id;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final String className;
  final String section;
  final int rollNo;
  final String? photoUrl;

  const ChildSummaryModel({
    required this.id,
    required this.admissionNo,
    required this.firstName,
    required this.lastName,
    required this.className,
    required this.section,
    required this.rollNo,
    this.photoUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get classSection => '$className - $section';

  factory ChildSummaryModel.fromJson(Map<String, dynamic> json) {
    return ChildSummaryModel(
      id: json['id'] as String? ?? '',
      admissionNo: json['admissionNo'] as String? ?? json['admission_no'] as String? ?? '',
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      className: json['class'] as String? ?? json['className'] as String? ?? '',
      section: json['section'] as String? ?? '',
      rollNo: (json['rollNo'] ?? json['roll_no']) as int? ?? 0,
      photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'admission_no': admissionNo,
        'first_name': firstName,
        'last_name': lastName,
        'class': className,
        'section': section,
        'roll_no': rollNo,
        'photo_url': photoUrl,
      };
}
