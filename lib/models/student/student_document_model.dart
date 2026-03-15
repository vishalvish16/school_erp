// =============================================================================
// FILE: lib/models/student/student_document_model.dart
// PURPOSE: Document model for the Student portal.
// =============================================================================

class StudentDocumentModel {
  final String id;
  final String documentType;
  final String documentName;
  final String fileUrl;
  final int? fileSizeKb;
  final bool verified;
  final String? verifiedAt;

  const StudentDocumentModel({
    required this.id,
    required this.documentType,
    required this.documentName,
    required this.fileUrl,
    this.fileSizeKb,
    this.verified = false,
    this.verifiedAt,
  });

  factory StudentDocumentModel.fromJson(Map<String, dynamic> json) {
    return StudentDocumentModel(
      id: json['id'] as String? ?? '',
      documentType: json['document_type'] as String? ?? '',
      documentName: json['document_name'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      fileSizeKb: (json['file_size_kb'] as num?)?.toInt(),
      verified: json['verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] as String?,
    );
  }
}
