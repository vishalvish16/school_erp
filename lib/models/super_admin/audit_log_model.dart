// =============================================================================
// FILE: lib/models/super_admin/audit_log_model.dart
// PURPOSE: Super Admin audit log model (all audit types)
// =============================================================================

class SuperAdminAuditLogModel {
  final String id;
  final String action;
  final String? actorName;
  final String? actorIp;
  final String? entityName;
  final String? entityType;
  final String? description;
  final String? status;
  final DateTime createdAt;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;

  SuperAdminAuditLogModel({
    required this.id,
    required this.action,
    this.actorName,
    this.actorIp,
    this.entityName,
    this.entityType,
    this.description,
    this.status,
    required this.createdAt,
    this.oldData,
    this.newData,
  });

  factory SuperAdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminAuditLogModel(
      id: json['id']?.toString() ?? '',
      action: json['action'] ?? '',
      actorName: json['actor_name'] ?? json['actorName'],
      actorIp: json['actor_ip']?.toString() ?? json['actorIp']?.toString(),
      entityName: json['entity_name'] ?? json['entityName'],
      entityType: json['entity_type'] ?? json['entityType'],
      description: json['description'],
      status: json['status'] ?? json['event_status'],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      oldData: json['old_data'] ?? json['oldData'] is Map
          ? Map<String, dynamic>.from(json['old_data'] ?? json['oldData'] ?? {})
          : null,
      newData: json['new_data'] ?? json['newData'] is Map
          ? Map<String, dynamic>.from(json['new_data'] ?? json['newData'] ?? {})
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'actor_name': actorName,
        'actor_ip': actorIp,
        'entity_name': entityName,
        'entity_type': entityType,
        'description': description,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
