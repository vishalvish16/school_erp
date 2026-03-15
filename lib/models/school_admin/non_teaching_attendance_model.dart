// =============================================================================
// FILE: lib/models/school_admin/non_teaching_attendance_model.dart
// PURPOSE: Attendance record for Non-Teaching Staff.
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/tokens/app_colors.dart';

class NonTeachingAttendanceModel {
  final String? id;
  final String staffId;
  final DateTime date;
  final String status; // PRESENT | ABSENT | HALF_DAY | ON_LEAVE | HOLIDAY | LATE
  final String? checkInTime;
  final String? checkOutTime;
  final String? remarks;

  const NonTeachingAttendanceModel({
    this.id,
    required this.staffId,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.remarks,
  });

  factory NonTeachingAttendanceModel.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'] as String?;
    return NonTeachingAttendanceModel(
      id: json['id'] as String?,
      staffId: (json['staffId'] ?? json['staff_id']) as String? ?? '',
      date: dateRaw != null
          ? DateTime.tryParse(dateRaw) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'ABSENT',
      checkInTime: (json['checkInTime'] ?? json['check_in_time']) as String?,
      checkOutTime: (json['checkOutTime'] ?? json['check_out_time']) as String?,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'staff_id': staffId,
        'date': date.toIso8601String().split('T').first,
        'status': status,
        if (checkInTime != null) 'check_in_time': checkInTime,
        if (checkOutTime != null) 'check_out_time': checkOutTime,
        if (remarks != null) 'remarks': remarks,
      };

  Color get statusColor {
    switch (status) {
      case 'PRESENT':
        return AppColors.success500;
      case 'ABSENT':
        return AppColors.error500;
      case 'HALF_DAY':
        return AppColors.warning500;
      case 'ON_LEAVE':
        return AppColors.secondary400;
      case 'HOLIDAY':
        return AppColors.info500;
      case 'LATE':
        return AppColors.warning300;
      default:
        return AppColors.neutral400;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'PRESENT':
        return 'Present';
      case 'ABSENT':
        return 'Absent';
      case 'HALF_DAY':
        return 'Half Day';
      case 'ON_LEAVE':
        return 'On Leave';
      case 'HOLIDAY':
        return 'Holiday';
      case 'LATE':
        return 'Late';
      default:
        return status;
    }
  }

  static Color colorForStatus(String status) {
    switch (status) {
      case 'PRESENT':
        return AppColors.success500;
      case 'ABSENT':
        return AppColors.error500;
      case 'HALF_DAY':
        return AppColors.warning500;
      case 'ON_LEAVE':
        return AppColors.secondary400;
      case 'HOLIDAY':
        return AppColors.info500;
      case 'LATE':
        return AppColors.warning300;
      default:
        return AppColors.neutral400;
    }
  }

  static String labelForStatus(String status) {
    switch (status) {
      case 'PRESENT':
        return 'Present';
      case 'ABSENT':
        return 'Absent';
      case 'HALF_DAY':
        return 'Half Day';
      case 'ON_LEAVE':
        return 'On Leave';
      case 'HOLIDAY':
        return 'Holiday';
      case 'LATE':
        return 'Late';
      default:
        return status;
    }
  }
}
