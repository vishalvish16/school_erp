// =============================================================================
// FILE: lib/models/parent/child_detail_model.dart
// PURPOSE: Child detail model extending ChildSummary for Parent Portal.
// =============================================================================

import 'child_summary_model.dart';

class ChildDetailModel extends ChildSummaryModel {
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? address;
  final String? parentRelation;

  const ChildDetailModel({
    required super.id,
    required super.admissionNo,
    required super.firstName,
    required super.lastName,
    required super.className,
    required super.section,
    required super.rollNo,
    super.photoUrl,
    this.dateOfBirth,
    this.bloodGroup,
    this.address,
    this.parentRelation,
  });

  factory ChildDetailModel.fromJson(Map<String, dynamic> json) {
    return ChildDetailModel(
      id: json['id'] as String? ?? '',
      admissionNo: json['admissionNo'] as String? ?? json['admission_no'] as String? ?? '',
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      className: json['class'] as String? ?? json['className'] as String? ?? '',
      section: json['section'] as String? ?? '',
      rollNo: (json['rollNo'] ?? json['roll_no']) as int? ?? 0,
      photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
      dateOfBirth: json['dateOfBirth'] != null || json['date_of_birth'] != null
          ? DateTime.tryParse(
              (json['dateOfBirth'] ?? json['date_of_birth']) as String,
            )
          : null,
      bloodGroup: json['bloodGroup'] as String? ?? json['blood_group'] as String?,
      address: json['address'] as String?,
      parentRelation: json['parentRelation'] as String? ?? json['parent_relation'] as String?,
    );
  }
}
