// =============================================================================
// FILE: lib/models/super_admin/super_admin_user_model.dart
// PURPOSE: Super Admin user model
// =============================================================================

class SuperAdminUserModel {
  final String id;
  final String userId;
  final String role;
  final String name;
  final String email;
  final String? mobile;
  final bool isActive;
  final bool totpEnabled;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final String? lastLoginCity;

  SuperAdminUserModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.name,
    required this.email,
    this.mobile,
    this.isActive = true,
    this.totpEnabled = false,
    this.lastLoginAt,
    this.lastLoginIp,
    this.lastLoginCity,
  });

  factory SuperAdminUserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    final u = user is Map<String, dynamic> ? user : <String, dynamic>{};
    return SuperAdminUserModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      role: json['role'] ?? 'ops_admin',
      name: u['name'] ?? '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
      email: u['email'] ?? '',
      mobile: u['phone'] ?? u['mobile'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      totpEnabled: json['totp_enabled'] ?? json['totpEnabled'] ?? false,
      lastLoginAt: u['last_login'] != null
          ? DateTime.tryParse(u['last_login'].toString())
          : (u['lastLoginAt'] != null
              ? DateTime.tryParse(u['lastLoginAt'].toString())
              : null),
      lastLoginIp: u['last_login_ip'] ?? u['lastLoginIp'],
      lastLoginCity: u['last_login_city'] ?? u['lastLoginCity'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'role': role,
        'is_active': isActive,
        'totp_enabled': totpEnabled,
      };
}
