// =============================================================================
// FILE: lib/models/school_admin/non_teaching_leave_model.dart
// PURPOSE: Leave model for Non-Teaching Staff.
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/tokens/app_colors.dart';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

class NonTeachingLeaveModel {
  final String id;
  final String staffId;
  final String? staffName;
  final String? employeeNo;
  final String? roleName;
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final String reason;
  final String status; // PENDING | APPROVED | REJECTED | CANCELLED
  final String? adminRemark;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const NonTeachingLeaveModel({
    required this.id,
    required this.staffId,
    this.staffName,
    this.employeeNo,
    this.roleName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.adminRemark,
    this.reviewedAt,
    this.createdAt,
  });

  factory NonTeachingLeaveModel.fromJson(Map<String, dynamic> json) {
    // Support nested staff object
    final staffObj = json['staff'] as Map<String, dynamic>?;
    String? staffName;
    String? employeeNo;
    String? roleName;
    if (staffObj != null) {
      final fn = (staffObj['firstName'] ?? staffObj['first_name']) as String? ?? '';
      final ln = (staffObj['lastName'] ?? staffObj['last_name']) as String? ?? '';
      staffName = '$fn $ln'.trim();
      employeeNo = (staffObj['employeeNo'] ?? staffObj['employee_no']) as String?;
      final roleObj = staffObj['role'] as Map<String, dynamic>?;
      roleName = (roleObj?['displayName'] ?? roleObj?['display_name']) as String?;
    }
    return NonTeachingLeaveModel(
      id: json['id'] as String? ?? '',
      staffId: (json['staffId'] ?? json['staff_id']) as String? ?? '',
      staffName: staffName ?? (json['staffName'] ?? json['staff_name']) as String?,
      employeeNo: employeeNo ?? (json['employeeNo'] ?? json['employee_no']) as String?,
      roleName: roleName,
      leaveType: (json['leaveType'] ?? json['leave_type']) as String? ?? '',
      fromDate: _parseDate(json['fromDate'] ?? json['from_date']) ?? DateTime.now(),
      toDate: _parseDate(json['toDate'] ?? json['to_date']) ?? DateTime.now(),
      totalDays: ((json['totalDays'] ?? json['total_days']) as num?)?.toInt() ?? 1,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      adminRemark: (json['adminRemark'] ?? json['admin_remark']) as String?,
      reviewedAt: _parseDate(json['reviewedAt'] ?? json['reviewed_at']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'leave_type': leaveType,
        'from_date': fromDate.toIso8601String().split('T').first,
        'to_date': toDate.toIso8601String().split('T').first,
        'reason': reason,
      };

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PENDING':
        return AppColors.warning500;
      case 'APPROVED':
        return AppColors.success500;
      case 'REJECTED':
        return AppColors.error500;
      case 'CANCELLED':
        return AppColors.neutral400;
      default:
        return AppColors.neutral400;
    }
  }

  String get leaveTypeLabel {
    switch (leaveType) {
      case 'CASUAL':
        return 'Casual Leave';
      case 'SICK':
        return 'Sick Leave';
      case 'EARNED':
        return 'Earned Leave';
      case 'MATERNITY':
        return 'Maternity Leave';
      case 'PATERNITY':
        return 'Paternity Leave';
      case 'UNPAID':
        return 'Unpaid Leave';
      case 'COMPENSATORY':
        return 'Compensatory Leave';
      default:
        return leaveType;
    }
  }

  Color get leaveTypeColor {
    switch (leaveType) {
      case 'CASUAL':
        return AppColors.secondary500;
      case 'SICK':
        return AppColors.error500;
      case 'EARNED':
        return AppColors.success500;
      case 'MATERNITY':
      case 'PATERNITY':
        return AppColors.primary500;
      case 'UNPAID':
        return AppColors.neutral600;
      case 'COMPENSATORY':
        return AppColors.info500;
      default:
        return AppColors.neutral400;
    }
  }
}
