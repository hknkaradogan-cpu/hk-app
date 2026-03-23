import '../core/supabase_client.dart';

class AuditService {
  Future<void> log({
    required String taskId,
    required String action,
    required String byUserId,
    String? note,
  }) async {
    await supabase.from('audit_logs').insert({
      'task_id': taskId,
      'action': action,
      'by_user_id': byUserId,
      'note': note,
    });
  }
}
