// =============================================================================
// FILE: lib/models/parent/parent_notification_model.dart
// PURPOSE: Notification model for the Parent portal.
// =============================================================================

class ParentNotificationModel {
  final String id;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final String? link;
  final String? entityType;
  final String? entityId;
  final DateTime createdAt;

  const ParentNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.isRead = false,
    this.link,
    this.entityType,
    this.entityId,
    required this.createdAt,
  });

  ParentNotificationModel copyWith({bool? isRead}) {
    return ParentNotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      link: link,
      entityType: entityType,
      entityId: entityId,
      createdAt: createdAt,
    );
  }

  factory ParentNotificationModel.fromJson(Map<String, dynamic> json) {
    return ParentNotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      link: json['link'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
