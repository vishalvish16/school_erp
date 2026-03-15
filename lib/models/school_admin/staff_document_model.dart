// =============================================================================
// FILE: lib/models/school_admin/staff_document_model.dart
// PURPOSE: Staff document model for School Admin portal.
// =============================================================================

class StaffDocumentModel {
  final String id;
  final String staffId;
  final String documentType;
  final String documentName;
  final String fileUrl;
  final int? fileSizeKb;
  final String? mimeType;
  final bool verified;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const StaffDocumentModel({
    required this.id,
    required this.staffId,
    required this.documentType,
    required this.documentName,
    required this.fileUrl,
    this.fileSizeKb,
    this.mimeType,
    required this.verified,
    this.verifiedAt,
    required this.createdAt,
  });

  factory StaffDocumentModel.fromJson(Map<String, dynamic> json) {
    // Prisma JS client returns camelCase; accept both forms for resilience.
    final fileSizeRaw = json['fileSizeKb'] ?? json['file_size_kb'];
    final verifiedAtRaw = json['verifiedAt'] ?? json['verified_at'];
    final createdRaw = json['createdAt'] ?? json['created_at'];
    return StaffDocumentModel(
      id: json['id'] as String? ?? '',
      staffId: (json['staffId'] ?? json['staff_id']) as String? ?? '',
      documentType:
          (json['documentType'] ?? json['document_type']) as String? ?? '',
      documentName:
          (json['documentName'] ?? json['document_name']) as String? ?? '',
      fileUrl: (json['fileUrl'] ?? json['file_url']) as String? ?? '',
      fileSizeKb:
          fileSizeRaw != null ? (fileSizeRaw as num).toInt() : null,
      mimeType: (json['mimeType'] ?? json['mime_type']) as String?,
      verified: json['verified'] as bool? ?? false,
      verifiedAt: verifiedAtRaw != null
          ? DateTime.tryParse(verifiedAtRaw as String)
          : null,
      createdAt: createdRaw != null
          ? DateTime.tryParse(createdRaw as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'documentType': documentType,
        'documentName': documentName,
        'fileUrl': fileUrl,
        if (fileSizeKb != null) 'fileSizeKb': fileSizeKb,
        if (mimeType != null) 'mimeType': mimeType,
      };

  /// Returns a human-readable label for the document type.
  String get typeLabel {
    switch (documentType) {
      case 'AADHAAR':
        return 'Aadhaar Card';
      case 'PAN':
        return 'PAN Card';
      case 'DEGREE':
        return 'Degree Certificate';
      case 'EXPERIENCE':
        return 'Experience Letter';
      case 'ADDRESS_PROOF':
        return 'Address Proof';
      case 'PHOTO':
        return 'Photograph';
      case 'OTHER':
        return 'Other Document';
      default:
        return documentType;
    }
  }
}
