// =============================================================================
// FILE: lib/models/super_admin/hardware_device_model.dart
// PURPOSE: Super Admin hardware device model
// =============================================================================

class SuperAdminHardwareDeviceModel {
  final String id;
  final String deviceId;
  final String deviceType;
  final String status;
  final String? schoolId;
  final String? schoolName;
  final String? locationLabel;
  final String? firmwareVersion;
  final String? ipAddress;
  final DateTime? lastPingAt;
  final DateTime? createdAt;

  SuperAdminHardwareDeviceModel({
    required this.id,
    required this.deviceId,
    required this.deviceType,
    required this.status,
    this.schoolId,
    this.schoolName,
    this.locationLabel,
    this.firmwareVersion,
    this.ipAddress,
    this.lastPingAt,
    this.createdAt,
  });

  factory SuperAdminHardwareDeviceModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminHardwareDeviceModel(
      id: json['id']?.toString() ?? '',
      deviceId: json['device_id'] ?? json['deviceId'] ?? '',
      deviceType: json['device_type'] ?? json['deviceType'] ?? '',
      status: json['status'] ?? 'online',
      schoolId: json['school_id']?.toString() ?? json['schoolId']?.toString(),
      schoolName: json['school_name'] ?? json['schoolName'],
      locationLabel: json['location_label'] ?? json['locationLabel'],
      firmwareVersion: json['firmware_version'] ?? json['firmwareVersion'],
      ipAddress: json['ip_address']?.toString() ?? json['ipAddress']?.toString(),
      lastPingAt: json['last_ping_at'] != null
          ? DateTime.tryParse(json['last_ping_at'].toString())
          : (json['lastPingAt'] != null
              ? DateTime.tryParse(json['lastPingAt'].toString())
              : null),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'device_type': deviceType,
        'status': status,
        'school_id': schoolId,
        'location_label': locationLabel,
        'firmware_version': firmwareVersion,
        'ip_address': ipAddress,
        if (lastPingAt != null) 'last_ping_at': lastPingAt!.toIso8601String(),
      };
}
