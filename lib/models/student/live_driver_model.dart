// =============================================================================
// FILE: lib/models/student/live_driver_model.dart
// PURPOSE: Model for live driver location data shown in student transport map.
// =============================================================================

class LiveDriverModel {
  const LiveDriverModel({
    required this.driverId,
    required this.driverName,
    this.vehicleNo,
    required this.lat,
    required this.lng,
    this.updatedAt,
  });

  final String driverId;
  final String driverName;
  final String? vehicleNo;
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  factory LiveDriverModel.fromJson(Map<String, dynamic> json) {
    return LiveDriverModel(
      driverId: json['driver_id'] as String? ??
          json['driverId'] as String? ??
          '',
      driverName: json['driver_name'] as String? ??
          json['driverName'] as String? ??
          '',
      vehicleNo: json['vehicle_no'] as String? ??
          json['vehicleNo'] as String?,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'] as String)
              : null,
    );
  }

  LiveDriverModel copyWith({
    String? driverId,
    String? driverName,
    String? vehicleNo,
    double? lat,
    double? lng,
    DateTime? updatedAt,
  }) {
    return LiveDriverModel(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
