// =============================================================================
// FILE: lib/models/driver/driver_trip_model.dart
// PURPOSE: Model for driver trip start/end API responses.
// =============================================================================

class DriverTripModel {
  final String tripId;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const DriverTripModel({
    required this.tripId,
    required this.status,
    this.startedAt,
    this.endedAt,
  });

  factory DriverTripModel.fromJson(Map<String, dynamic> json) {
    return DriverTripModel(
      tripId: json['tripId'] as String? ?? json['trip_id'] as String? ?? '',
      status: json['status'] as String? ?? 'NOT_STARTED',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : json['started_at'] != null
              ? DateTime.tryParse(json['started_at'] as String)
              : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)
          : json['ended_at'] != null
              ? DateTime.tryParse(json['ended_at'] as String)
              : null,
    );
  }

  bool get isActive => status == 'IN_PROGRESS';
}
