// =============================================================================
// FILE: lib/models/staff/staff_notification_model.dart
// PURPOSE: Notification model for the Staff/Clerk portal.
// =============================================================================

class StaffNotificationModel {
  final String id;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  const StaffNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.isRead = false,
    required this.createdAt,
  });

  StaffNotificationModel copyWith({bool? isRead}) {
    return StaffNotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory StaffNotificationModel.fromJson(Map<String, dynamic> json) {
    return StaffNotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
