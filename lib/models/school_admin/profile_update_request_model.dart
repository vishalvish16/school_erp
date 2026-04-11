// =============================================================================
// FILE: lib/models/school_admin/profile_update_request_model.dart
// PURPOSE: Model for student profile update requests (parent -> school admin).
// =============================================================================

class ProfileUpdateRequest {
  final String id;
  final String studentId;
  final Map<String, dynamic>? student;
  final Map<String, dynamic>? requestedByParent;
  final String status;
  final Map<String, dynamic> requestedChanges;
  final Map<String, dynamic> currentValues;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const ProfileUpdateRequest({
    required this.id,
    required this.studentId,
    this.student,
    this.requestedByParent,
    required this.status,
    required this.requestedChanges,
    required this.currentValues,
    this.reviewNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory ProfileUpdateRequest.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateRequest(
      id: json['id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? json['student_id'] as String? ?? '',
      student: json['student'] is Map<String, dynamic>
          ? json['student'] as Map<String, dynamic>
          : null,
      requestedByParent: json['requestedByParent'] is Map<String, dynamic>
          ? json['requestedByParent'] as Map<String, dynamic>
          : json['requested_by_parent'] is Map<String, dynamic>
              ? json['requested_by_parent'] as Map<String, dynamic>
              : null,
      status: json['status'] as String? ?? 'PENDING',
      requestedChanges: json['requestedChanges'] is Map<String, dynamic>
          ? json['requestedChanges'] as Map<String, dynamic>
          : json['requested_changes'] is Map<String, dynamic>
              ? json['requested_changes'] as Map<String, dynamic>
              : {},
      currentValues: json['currentValues'] is Map<String, dynamic>
          ? json['currentValues'] as Map<String, dynamic>
          : json['current_values'] is Map<String, dynamic>
              ? json['current_values'] as Map<String, dynamic>
              : {},
      reviewNote: json['reviewNote'] as String? ?? json['review_note'] as String?,
      createdAt: DateTime.tryParse(
              json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: json['reviewedAt'] != null || json['reviewed_at'] != null
          ? DateTime.tryParse(
              (json['reviewedAt'] ?? json['reviewed_at']) as String)
          : null,
    );
  }

  String get studentName {
    if (student == null) return '';
    final first = student!['firstName'] ?? student!['first_name'] ?? '';
    final last = student!['lastName'] ?? student!['last_name'] ?? '';
    return '$first $last'.trim();
  }

  String get studentAdmissionNo {
    if (student == null) return '';
    return student!['admissionNo'] as String? ??
        student!['admission_no'] as String? ??
        '';
  }

  String get parentName {
    if (requestedByParent == null) return '';
    final first = requestedByParent!['firstName'] ??
        requestedByParent!['first_name'] ?? '';
    final last = requestedByParent!['lastName'] ??
        requestedByParent!['last_name'] ?? '';
    return '$first $last'.trim();
  }

  String get parentPhone {
    if (requestedByParent == null) return '';
    return requestedByParent!['phone'] as String? ?? '';
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}
