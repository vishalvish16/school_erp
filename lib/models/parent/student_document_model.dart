// =============================================================================
// FILE: lib/models/parent/student_document_model.dart
// PURPOSE: Student document model for Parent Portal child documents tab.
// =============================================================================

class StudentDocumentModel {
  final String id;
  final String type;
  final String name;
  final String? fileUrl;
  final int? fileSizeKb;
  final bool verified;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const StudentDocumentModel({
    required this.id,
    required this.type,
    required this.name,
    this.fileUrl,
    this.fileSizeKb,
    required this.verified,
    this.verifiedAt,
    required this.createdAt,
  });

  factory StudentDocumentModel.fromJson(Map<String, dynamic> json) =>
      StudentDocumentModel(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'DOCUMENT',
        name: json['name'] as String? ?? 'Document',
        fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String?,
        fileSizeKb: json['fileSizeKb'] as int? ?? json['file_size_kb'] as int?,
        verified: json['verified'] as bool? ?? false,
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.tryParse(json['verifiedAt'] as String)
            : json['verified_at'] != null
                ? DateTime.tryParse(json['verified_at'] as String)
                : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
                : DateTime.now(),
      );
}
