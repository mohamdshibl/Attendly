class AuditLogModel {
  final int? id;
  final int? actorId; // Employee ID or null if system/unauthenticated
  final String action; // e.g., 'EMPLOYEE_CREATED', 'CHECK_IN'
  final String entityType; // e.g., 'employee', 'attendance', 'leave_request'
  final int? entityId;
  final DateTime timestamp;
  final String? metadata; // JSON string

  AuditLogModel({
    this.id,
    this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'action': action,
      'entityType': entityType,
      'timestamp': timestamp.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    if (actorId != null) map['actorId'] = actorId;
    if (entityId != null) map['entityId'] = entityId;
    if (metadata != null) map['metadata'] = metadata;
    return map;
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as int?,
      actorId: map['actorId'] as int?,
      action: map['action'] as String,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      metadata: map['metadata'] as String?,
    );
  }
}
