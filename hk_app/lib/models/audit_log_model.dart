class AuditLog {
  final String id;
  final String? taskId;
  final String action;
  final String? byUserId;
  final String? note;
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    this.taskId,
    required this.action,
    this.byUserId,
    this.note,
    required this.createdAt,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) => AuditLog(
        id: map['id'] as String,
        taskId: map['task_id'] as String?,
        action: map['action'] as String,
        byUserId: map['by_user_id'] as String?,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
