// =============================================================================
// FILE: lib/models/school_admin/staff_leave_model.dart
// PURPOSE: Staff leave model for School Admin portal.
// =============================================================================

class StaffLeaveModel {
  final String id;
  final String staffId;
  final String? staffName;
  final String? employeeNo;
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final String reason;
  final String status; // PENDING | APPROVED | REJECTED | CANCELLED
  final String appliedBy;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminRemark;
  final DateTime createdAt;

  const StaffLeaveModel({
    required this.id,
    required this.staffId,
    this.staffName,
    this.employeeNo,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.appliedBy,
    this.reviewedBy,
    this.reviewedAt,
    this.adminRemark,
    required this.createdAt,
  });

  factory StaffLeaveModel.fromJson(Map<String, dynamic> json) {
    // Prisma JS client returns camelCase; accept both forms for resilience.
    final fromRaw = json['fromDate'] ?? json['from_date'];
    final toRaw = json['toDate'] ?? json['to_date'];
    final totalRaw = json['totalDays'] ?? json['total_days'];
    final reviewedAtRaw = json['reviewedAt'] ?? json['reviewed_at'];
    final createdRaw = json['createdAt'] ?? json['created_at'];
    return StaffLeaveModel(
      id: json['id'] as String? ?? '',
      staffId: (json['staffId'] ?? json['staff_id']) as String? ?? '',
      staffName: (json['staffName'] ?? json['staff_name']) as String?,
      employeeNo: (json['employeeNo'] ?? json['employee_no']) as String?,
      leaveType: (json['leaveType'] ?? json['leave_type']) as String? ?? '',
      fromDate: fromRaw != null
          ? DateTime.tryParse(fromRaw as String) ?? DateTime.now()
          : DateTime.now(),
      toDate: toRaw != null
          ? DateTime.tryParse(toRaw as String) ?? DateTime.now()
          : DateTime.now(),
      totalDays: totalRaw != null ? (totalRaw as num).toInt() : 1,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      appliedBy: (json['appliedBy'] ?? json['applied_by']) as String? ?? '',
      reviewedBy: (json['reviewedBy'] ?? json['reviewed_by']) as String?,
      reviewedAt: reviewedAtRaw != null
          ? DateTime.tryParse(reviewedAtRaw as String)
          : null,
      adminRemark: (json['adminRemark'] ?? json['admin_remark']) as String?,
      createdAt: createdRaw != null
          ? DateTime.tryParse(createdRaw as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'leaveType': leaveType,
        'fromDate': fromDate.toIso8601String().split('T').first,
        'toDate': toDate.toIso8601String().split('T').first,
        'reason': reason,
      };

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';
}
