// =============================================================================
// FILE: lib/models/staff/staff_profile_model.dart
// PURPOSE: Combined User + Staff profile model for the Staff/Clerk portal.
// =============================================================================

class StaffProfileModel {
  final String userId;
  final String staffId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? photoUrl;
  final String? employeeNo;
  final String? designation;
  final String? department;
  final bool isActive;
  final DateTime? joinDate;

  const StaffProfileModel({
    required this.userId,
    required this.staffId,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.photoUrl,
    this.employeeNo,
    this.designation,
    this.department,
    this.isActive = true,
    this.joinDate,
  });

  String get fullName {
    final parts = [firstName, lastName]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return email.split('@').first;
    return parts.join(' ');
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!.substring(0, 1).toUpperCase();
    }
    final emailPart = email.split('@').first;
    return emailPart.length >= 2
        ? emailPart.substring(0, 2).toUpperCase()
        : 'ST';
  }

  factory StaffProfileModel.fromJson(Map<String, dynamic> json) {
    // Backend may return nested user object
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    return StaffProfileModel(
      userId: user['id'] as String? ?? json['user_id'] as String? ?? '',
      staffId: json['id'] as String? ?? '',
      email: user['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? user['first_name'] as String?,
      lastName: json['last_name'] as String? ?? user['last_name'] as String?,
      phone: json['phone'] as String? ?? user['phone'] as String?,
      photoUrl: json['photo_url'] as String? ?? user['photo_url'] as String?,
      employeeNo: json['employee_no'] as String?,
      designation: json['designation'] as String?,
      department: json['department'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      joinDate: json['join_date'] != null
          ? DateTime.tryParse(json['join_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photo_url': photoUrl,
      };
}
