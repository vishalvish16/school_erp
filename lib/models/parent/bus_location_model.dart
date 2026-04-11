// =============================================================================
// FILE: lib/models/parent/bus_location_model.dart
// PURPOSE: Model for parent child bus location API response.
// =============================================================================

class BusLocationModel {
  final bool hasBus;
  final BusVehicleInfo? vehicle;
  final String? tripStatus;
  final BusLocationCoords? location;

  const BusLocationModel({
    required this.hasBus,
    this.vehicle,
    this.tripStatus,
    this.location,
  });

  factory BusLocationModel.fromJson(Map<String, dynamic> json) {
    return BusLocationModel(
      hasBus: json['hasBus'] as bool? ?? false,
      vehicle: json['vehicle'] != null
          ? BusVehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      tripStatus: json['tripStatus'] as String?,
      location: json['location'] != null
          ? BusLocationCoords.fromJson(
              json['location'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BusVehicleInfo {
  final String id;
  final String vehicleNo;
  final String? driverName;
  final String? driverPhone;

  const BusVehicleInfo({
    required this.id,
    required this.vehicleNo,
    this.driverName,
    this.driverPhone,
  });

  factory BusVehicleInfo.fromJson(Map<String, dynamic> json) => BusVehicleInfo(
        id: json['id'] as String,
        vehicleNo: json['vehicleNo'] as String,
        driverName: json['driverName'] as String?,
        driverPhone: json['driverPhone'] as String?,
      );
}

class BusLocationCoords {
  final double lat;
  final double lng;
  final double? speed;
  final double? heading;
  final DateTime? updatedAt;

  const BusLocationCoords({
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    this.updatedAt,
  });

  factory BusLocationCoords.fromJson(Map<String, dynamic> json) =>
      BusLocationCoords(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
        heading: json['heading'] != null
            ? (json['heading'] as num).toDouble()
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}
