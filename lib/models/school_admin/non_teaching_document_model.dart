// =============================================================================
// FILE: lib/models/school_admin/non_teaching_document_model.dart
// PURPOSE: Document model for Non-Teaching Staff.
// =============================================================================

import 'package:flutter/material.dart';

class NonTeachingDocumentModel {
  final String id;
  final String staffId;
  final String documentType;
  final String documentName;
  final String? fileUrl;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime? createdAt;

  const NonTeachingDocumentModel({
    required this.id,
    required this.staffId,
    required this.documentType,
    required this.documentName,
    this.fileUrl,
    required this.isVerified,
    this.verifiedAt,
    this.createdAt,
  });

  factory NonTeachingDocumentModel.fromJson(Map<String, dynamic> json) {
    final verifiedAtRaw = json['verifiedAt'] ?? json['verified_at'];
    final createdRaw = json['createdAt'] ?? json['created_at'];
    return NonTeachingDocumentModel(
      id: json['id'] as String? ?? '',
      staffId: (json['staffId'] ?? json['staff_id'] ??
          json['nonTeachingStaffId'] ?? json['non_teaching_staff_id']) as String? ?? '',
      documentType: (json['documentType'] ?? json['document_type']) as String? ?? '',
      documentName: (json['documentName'] ?? json['document_name']) as String? ?? '',
      fileUrl: (json['fileUrl'] ?? json['file_url']) as String?,
      isVerified: (json['verified'] ?? json['isVerified'] ?? json['is_verified']) as bool? ?? false,
      verifiedAt: verifiedAtRaw != null
          ? DateTime.tryParse(verifiedAtRaw.toString())
          : null,
      createdAt: createdRaw != null
          ? DateTime.tryParse(createdRaw.toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'document_type': documentType,
        'document_name': documentName,
        if (fileUrl != null) 'file_url': fileUrl,
      };

  IconData get documentIcon {
    switch (documentType) {
      case 'AADHAR':
        return Icons.credit_card;
      case 'PAN':
        return Icons.account_balance;
      case 'DEGREE':
        return Icons.school;
      case 'EXPERIENCE':
        return Icons.work;
      case 'APPOINTMENT_LETTER':
        return Icons.description;
      case 'POLICE_VERIFICATION':
        return Icons.security;
      default:
        return Icons.attach_file;
    }
  }

  String get documentTypeLabel {
    switch (documentType) {
      case 'AADHAR':
        return 'Aadhar Card';
      case 'PAN':
        return 'PAN Card';
      case 'DEGREE':
        return 'Degree Certificate';
      case 'EXPERIENCE':
        return 'Experience Certificate';
      case 'APPOINTMENT_LETTER':
        return 'Appointment Letter';
      case 'POLICE_VERIFICATION':
        return 'Police Verification';
      default:
        return documentType;
    }
  }
}
