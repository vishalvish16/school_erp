// =============================================================================
// FILE: lib/models/driver/driver_dashboard_model.dart
// PURPOSE: Driver dashboard stats response model.
// =============================================================================

class DriverSummary {
  const DriverSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? photoUrl;

  String get fullName => '$firstName $lastName';

  factory DriverSummary.fromJson(Map<String, dynamic> json) {
    return DriverSummary(
      id: json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class SchoolSummary {
  const SchoolSummary({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? logoUrl;

  factory SchoolSummary.fromJson(Map<String, dynamic> json) {
    return SchoolSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
    );
  }
}

class VehicleSummary {
  const VehicleSummary({
    required this.id,
    required this.vehicleNo,
    required this.capacity,
  });

  final String id;
  final String vehicleNo;
  final int capacity;

  factory VehicleSummary.fromJson(Map<String, dynamic> json) {
    return VehicleSummary(
      id: json['id'] as String? ?? '',
      vehicleNo: json['vehicle_no'] as String? ?? json['vehicleNo'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    );
  }
}

class RouteSummary {
  const RouteSummary({
    required this.id,
    required this.name,
    required this.stopCount,
  });

  final String id;
  final String name;
  final int stopCount;

  factory RouteSummary.fromJson(Map<String, dynamic> json) {
    return RouteSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      stopCount: (json['stop_count'] as num?)?.toInt() ??
          (json['stopCount'] as num?)?.toInt() ??
          0,
    );
  }
}

class DriverDashboardModel {
  const DriverDashboardModel({
    required this.driver,
    required this.school,
    this.vehicle,
    this.route,
    this.studentCount = 0,
    this.tripStatus = 'NOT_STARTED',
  });

  final DriverSummary driver;
  final SchoolSummary school;
  final VehicleSummary? vehicle;
  final RouteSummary? route;
  final int studentCount;
  final String tripStatus;

  factory DriverDashboardModel.fromJson(Map<String, dynamic> json) {
    return DriverDashboardModel(
      driver: DriverSummary.fromJson(
        (json['driver'] as Map<String, dynamic>?) ?? {},
      ),
      school: SchoolSummary.fromJson(
        (json['school'] as Map<String, dynamic>?) ?? {},
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
      studentCount: (json['student_count'] as num?)?.toInt() ??
          (json['studentCount'] as num?)?.toInt() ??
          0,
      tripStatus: json['trip_status'] as String? ??
          json['tripStatus'] as String? ??
          'NOT_STARTED',
    );
  }
}
