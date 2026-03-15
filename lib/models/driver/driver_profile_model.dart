// =============================================================================
// FILE: lib/models/driver/driver_profile_model.dart
// PURPOSE: Driver profile response model.
// =============================================================================

import 'driver_dashboard_model.dart';

class DriverDetail {
  const DriverDetail({
    required this.id,
    required this.employeeNo,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.phone,
    required this.email,
    this.licenseNumber,
    this.licenseExpiry,
    this.photoUrl,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.isActive = true,
  });

  final String id;
  final String employeeNo;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final String? phone;
  final String email;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final String? photoUrl;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool isActive;

  String get fullName => '$firstName $lastName';

  factory DriverDetail.fromJson(Map<String, dynamic> json) {
    return DriverDetail(
      id: json['id'] as String? ?? '',
      employeeNo: json['employee_no'] as String? ?? json['employeeNo'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : json['dateOfBirth'] != null
              ? DateTime.tryParse(json['dateOfBirth'] as String)
              : null,
      phone: json['phone'] as String?,
      email: json['email'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? json['licenseNumber'] as String?,
      licenseExpiry: json['license_expiry'] != null
          ? DateTime.tryParse(json['license_expiry'] as String)
          : json['licenseExpiry'] != null
              ? DateTime.tryParse(json['licenseExpiry'] as String)
              : null,
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String?,
      address: json['address'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String? ??
          json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String? ??
          json['emergencyContactPhone'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }
}

class DriverUserInfo {
  const DriverUserInfo({
    required this.userId,
    required this.email,
    this.lastLogin,
  });

  final String userId;
  final String email;
  final DateTime? lastLogin;

  factory DriverUserInfo.fromJson(Map<String, dynamic> json) {
    return DriverUserInfo(
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'] as String)
          : json['lastLogin'] != null
              ? DateTime.tryParse(json['lastLogin'] as String)
              : null,
    );
  }
}

class DriverProfileModel {
  const DriverProfileModel({
    required this.driver,
    this.vehicle,
    this.route,
    this.user,
  });

  final DriverDetail driver;
  final VehicleSummary? vehicle;
  final RouteSummary? route;
  final DriverUserInfo? user;

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      driver: DriverDetail.fromJson(
        (json['driver'] as Map<String, dynamic>?) ?? {},
      ),
      vehicle: json['vehicle'] != null
          ? VehicleSummary.fromJson(
              json['vehicle'] as Map<String, dynamic>,
            )
          : null,
      route: json['route'] != null
          ? RouteSummary.fromJson(
              json['route'] as Map<String, dynamic>,
            )
          : null,
      user: json['user'] != null
          ? DriverUserInfo.fromJson(
              json['user'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
