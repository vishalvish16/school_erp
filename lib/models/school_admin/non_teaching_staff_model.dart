// =============================================================================
// FILE: lib/models/school_admin/non_teaching_staff_model.dart
// PURPOSE: Non-Teaching Staff model with dual-key fromJson and snake_case toJson.
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/tokens/app_colors.dart';
import 'non_teaching_staff_role_model.dart';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

class NonTeachingStaffModel {
  final String id;
  final String schoolId;
  final String? userId;
  final String employeeNo;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final String? phone;
  final String email;
  final String? department;
  final String? designation;
  final String? qualification;
  final DateTime? joinDate;
  final String employeeType; // PERMANENT | CONTRACT | PART_TIME | DAILY_WAGE
  final String? salaryGrade;
  final String? address;
  final String? city;
  final String? state;
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? photoUrl;
  final bool isActive;
  final bool hasLogin;
  final NonTeachingStaffRoleModel? role;
  final DateTime? createdAt;

  const NonTeachingStaffModel({
    required this.id,
    required this.schoolId,
    this.userId,
    required this.employeeNo,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.phone,
    required this.email,
    this.department,
    this.designation,
    this.qualification,
    this.joinDate,
    required this.employeeType,
    this.salaryGrade,
    this.address,
    this.city,
    this.state,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.photoUrl,
    required this.isActive,
    required this.hasLogin,
    this.role,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : 'NT';
  }

  factory NonTeachingStaffModel.fromJson(Map<String, dynamic> json) {
    final userIdVal = (json['userId'] ?? json['user_id']) as String?;
    return NonTeachingStaffModel(
      id: json['id'] as String? ?? '',
      schoolId: (json['schoolId'] ?? json['school_id']) as String? ?? '',
      userId: userIdVal,
      employeeNo: (json['employeeNo'] ?? json['employee_no']) as String? ?? '',
      firstName: (json['firstName'] ?? json['first_name']) as String? ?? '',
      lastName: (json['lastName'] ?? json['last_name']) as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dateOfBirth: _parseDate(json['dateOfBirth'] ?? json['date_of_birth']),
      phone: json['phone'] as String?,
      email: json['email'] as String? ?? '',
      department: json['department'] as String?,
      designation: json['designation'] as String?,
      qualification: json['qualification'] as String?,
      joinDate: _parseDate(json['joinDate'] ?? json['join_date']),
      employeeType: (json['employeeType'] ?? json['employee_type']) as String? ?? 'PERMANENT',
      salaryGrade: (json['salaryGrade'] ?? json['salary_grade']) as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      bloodGroup: (json['bloodGroup'] ?? json['blood_group']) as String?,
      emergencyContactName:
          (json['emergencyContactName'] ?? json['emergency_contact_name']) as String?,
      emergencyContactPhone:
          (json['emergencyContactPhone'] ?? json['emergency_contact_phone']) as String?,
      photoUrl: (json['photoUrl'] ?? json['photo_url']) as String?,
      isActive: (json['isActive'] ?? json['is_active']) as bool? ?? true,
      hasLogin: (json['hasLogin'] ?? json['has_login']) as bool? ?? userIdVal != null,
      role: json['role'] is Map
          ? NonTeachingStaffRoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (role?.id != null) 'role_id': role!.id,
        'employee_no': employeeNo,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
        if (phone != null) 'phone': phone,
        'email': email,
        if (department != null) 'department': department,
        if (designation != null) 'designation': designation,
        if (qualification != null) 'qualification': qualification,
        if (joinDate != null)
          'join_date': joinDate!.toIso8601String().split('T').first,
        'employee_type': employeeType,
        if (salaryGrade != null) 'salary_grade': salaryGrade,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (bloodGroup != null) 'blood_group': bloodGroup,
        if (emergencyContactName != null)
          'emergency_contact_name': emergencyContactName,
        if (emergencyContactPhone != null)
          'emergency_contact_phone': emergencyContactPhone,
      };

  Color get employeeTypeColor {
    switch (employeeType) {
      case 'PERMANENT':
        return AppColors.secondary500;
      case 'CONTRACT':
        return AppColors.warning500;
      case 'PART_TIME':
        return AppColors.primary500;
      case 'DAILY_WAGE':
        return AppColors.neutral600;
      default:
        return AppColors.neutral400;
    }
  }

  String get employeeTypeLabel {
    switch (employeeType) {
      case 'PERMANENT':
        return 'Permanent';
      case 'CONTRACT':
        return 'Contract';
      case 'PART_TIME':
        return 'Part-Time';
      case 'DAILY_WAGE':
        return 'Daily Wage';
      default:
        return employeeType;
    }
  }
}
