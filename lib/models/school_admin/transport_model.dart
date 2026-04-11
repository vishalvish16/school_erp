// =============================================================================
// FILE: lib/models/school_admin/transport_model.dart
// PURPOSE: Models for Transport module — vehicles, drivers, assignments.
// =============================================================================

class TransportVehicleModel {
  final String id;
  final String vehicleNo;
  final String? vehicleType;
  final int capacity;
  final String? make;
  final String? model;
  final int? year;
  final String? color;
  final String? rcNumber;
  final String? insuranceExpiry;
  final String? fitnessExpiry;
  final bool isActive;
  final TransportDriverSummary? driver;
  final int studentCount;
  final VehicleLocation? lastLocation;

  const TransportVehicleModel({
    required this.id,
    required this.vehicleNo,
    this.vehicleType,
    required this.capacity,
    this.make,
    this.model,
    this.year,
    this.color,
    this.rcNumber,
    this.insuranceExpiry,
    this.fitnessExpiry,
    required this.isActive,
    this.driver,
    required this.studentCount,
    this.lastLocation,
  });

  factory TransportVehicleModel.fromJson(Map<String, dynamic> j) {
    return TransportVehicleModel(
      id: j['id'] as String,
      vehicleNo: j['vehicleNo'] as String? ?? '',
      vehicleType: j['vehicleType'] as String?,
      capacity: (j['capacity'] as num?)?.toInt() ?? 0,
      make: j['make'] as String?,
      model: j['model'] as String?,
      year: (j['year'] as num?)?.toInt(),
      color: j['color'] as String?,
      rcNumber: j['rcNumber'] as String?,
      insuranceExpiry: j['insuranceExpiry'] as String?,
      fitnessExpiry: j['fitnessExpiry'] as String?,
      isActive: j['isActive'] as bool? ?? true,
      driver: j['driver'] != null
          ? TransportDriverSummary.fromJson(j['driver'] as Map<String, dynamic>)
          : null,
      studentCount: (j['studentCount'] as num?)?.toInt() ?? 0,
      lastLocation: j['lastLocation'] != null
          ? VehicleLocation.fromJson(j['lastLocation'] as Map<String, dynamic>)
          : null,
    );
  }

  String get displayName => '$vehicleNo${make != null ? ' · $make' : ''}';
  String get typeLabel => vehicleType ?? 'Vehicle';
}

class VehicleLocation {
  final double lat;
  final double lng;
  final double? speed;
  final double? heading;
  final DateTime? updatedAt;

  const VehicleLocation({
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    this.updatedAt,
  });

  factory VehicleLocation.fromJson(Map<String, dynamic> j) {
    return VehicleLocation(
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      speed: (j['speed'] as num?)?.toDouble(),
      heading: (j['heading'] as num?)?.toDouble(),
      updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt'] as String) : null,
    );
  }
}

class TransportDriverSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;

  const TransportDriverSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  factory TransportDriverSummary.fromJson(Map<String, dynamic> j) {
    return TransportDriverSummary(
      id: j['id'] as String,
      firstName: j['firstName'] as String? ?? '',
      lastName: j['lastName'] as String? ?? '',
      phone: j['phone'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';
}

// ── Driver Model ──────────────────────────────────────────────────────────────

class TransportDriverModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? licenseNumber;
  final String? licenseExpiry;
  final bool isActive;
  final List<TransportVehicleSummary> vehicles;

  const TransportDriverModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.licenseNumber,
    this.licenseExpiry,
    required this.isActive,
    required this.vehicles,
  });

  factory TransportDriverModel.fromJson(Map<String, dynamic> j) {
    final vList = (j['vehicles'] as List<dynamic>?) ?? [];
    return TransportDriverModel(
      id: j['id'] as String,
      firstName: j['firstName'] as String? ?? '',
      lastName: j['lastName'] as String? ?? '',
      phone: j['phone'] as String?,
      email: j['email'] as String?,
      licenseNumber: j['licenseNumber'] as String?,
      licenseExpiry: j['licenseExpiry'] as String?,
      isActive: j['isActive'] as bool? ?? true,
      vehicles: vList
          .whereType<Map<String, dynamic>>()
          .map(TransportVehicleSummary.fromJson)
          .toList(),
    );
  }

  String get fullName => '$firstName $lastName';
}

class TransportVehicleSummary {
  final String id;
  final String vehicleNo;

  const TransportVehicleSummary({required this.id, required this.vehicleNo});

  factory TransportVehicleSummary.fromJson(Map<String, dynamic> j) {
    return TransportVehicleSummary(
      id: j['id'] as String,
      vehicleNo: j['vehicleNo'] as String? ?? '',
    );
  }
}

// ── Student Assignment ────────────────────────────────────────────────────────

class VehicleStudentAssignment {
  final String id;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? rollNo;
  final String? admissionNo;
  final String? className;
  final String? sectionName;
  final String? pickupStopName;
  final double? pickupLat;
  final double? pickupLng;
  final String? dropStopName;
  final double? dropLat;
  final double? dropLng;

  const VehicleStudentAssignment({
    required this.id,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.rollNo,
    this.admissionNo,
    this.className,
    this.sectionName,
    this.pickupStopName,
    this.pickupLat,
    this.pickupLng,
    this.dropStopName,
    this.dropLat,
    this.dropLng,
  });

  factory VehicleStudentAssignment.fromJson(Map<String, dynamic> j) {
    final st = j['student'] as Map<String, dynamic>? ?? j;
    final cls = st['class_'] as Map<String, dynamic>?;
    final sec = st['section'] as Map<String, dynamic>?;
    return VehicleStudentAssignment(
      id: j['id'] as String? ?? '',
      studentId: (st['id'] ?? j['studentId']) as String? ?? '',
      firstName: st['firstName'] as String? ?? '',
      lastName: st['lastName'] as String? ?? '',
      rollNo: st['rollNo'] as String?,
      admissionNo: st['admissionNo'] as String?,
      className: cls?['name'] as String?,
      sectionName: sec?['name'] as String?,
      pickupStopName: j['pickupStopName'] as String?,
      pickupLat: (j['pickupLat'] as num?)?.toDouble(),
      pickupLng: (j['pickupLng'] as num?)?.toDouble(),
      dropStopName: j['dropStopName'] as String?,
      dropLat: (j['dropLat'] as num?)?.toDouble(),
      dropLng: (j['dropLng'] as num?)?.toDouble(),
    );
  }

  String get fullName => '$firstName $lastName';
  String get classLabel => [className, sectionName].where((s) => s != null).join(' - ');
}

// ── Unassigned student (for picker) ──────────────────────────────────────────

class UnassignedStudent {
  final String id;
  final String firstName;
  final String lastName;
  final String? rollNo;
  final String? admissionNo;
  final String? className;
  final String? sectionName;

  const UnassignedStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.rollNo,
    this.admissionNo,
    this.className,
    this.sectionName,
  });

  factory UnassignedStudent.fromJson(Map<String, dynamic> j) {
    final cls = j['class_'] as Map<String, dynamic>?;
    final sec = j['section'] as Map<String, dynamic>?;
    return UnassignedStudent(
      id: j['id'] as String,
      firstName: j['firstName'] as String? ?? '',
      lastName: j['lastName'] as String? ?? '',
      rollNo: j['rollNo'] as String?,
      admissionNo: j['admissionNo'] as String?,
      className: cls?['name'] as String?,
      sectionName: sec?['name'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';
  String get classLabel => [className, sectionName].where((s) => s != null).join(' - ');
}
