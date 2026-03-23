import '../core/supabase_client.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class TaskService {
  Future<List<TaskModel>> fetchTodayTasksForMaid(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await supabase
        .from('tasks')
        .select()
        .eq('date', today)
        .eq('assigned_to', userId)
        .order('floor')
        .order('room_no');
    return (data as List).map((e) => TaskModel.fromMap(e)).toList();
  }

  Future<List<TaskModel>> fetchAllTasksForSupervisor({
    String? date,
    int? floor,
    String? taskType,
  }) async {
    var query = supabase.from('tasks').select();
    if (date != null) query = query.eq('date', date);
    if (floor != null) query = query.eq('floor', floor);
    if (taskType != null) query = query.eq('task_type', taskType);
    final data = await query.order('floor').order('room_no');
    return (data as List).map((e) => TaskModel.fromMap(e)).toList();
  }

  Future<void> updateTaskStatus(
      String taskId, String status, String? note) async {
    final update = <String, dynamic>{'status': status};
    if (note != null) update['note'] = note;
    await supabase.from('tasks').update(update).eq('id', taskId);
  }

  Future<void> bulkAssign(List<String> taskIds, String userId) async {
    for (final id in taskIds) {
      await supabase
          .from('tasks')
          .update({'assigned_to': userId})
          .eq('id', id);
    }
  }

  Future<void> insertTasks(List<Map<String, dynamic>> rows) async {
    await supabase.from('tasks').insert(rows);
  }

  Future<Map<String, Map<String, int>>> dashboardStats(String date) async {
    final data = await supabase
        .from('tasks')
        .select('assigned_to, status, users(name)')
        .eq('date', date);

    final Map<String, Map<String, int>> result = {};
    for (final row in data as List) {
      final uid = row['assigned_to'] as String? ?? 'unassigned';
      final name =
          (row['users'] as Map<String, dynamic>?)?['name'] as String? ?? 'Atanmamış';
      final status = row['status'] as String;
      result.putIfAbsent(uid, () => {'name': 0, 'TOPLAM': 0, 'YAPILDI': 0, 'DND': 0, 'RED': 0, 'BEKLIYOR': 0});
      result[uid]!['TOPLAM'] = (result[uid]!['TOPLAM'] ?? 0) + 1;
      result[uid]![status] = (result[uid]![status] ?? 0) + 1;
      result[uid]!['_name'] = 0;
      result[uid]!['__name_str__'] = 0;
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> dashboardStatsFull(String date) async {
    final data = await supabase
        .from('tasks')
        .select('assigned_to, status, users!assigned_to(name)')
        .eq('date', date);

    final Map<String, Map<String, dynamic>> agg = {};
    for (final row in data as List) {
      final uid = row['assigned_to'] as String? ?? 'unassigned';
      final nameMap = row['users'] as Map<String, dynamic>?;
      final name = nameMap?['name'] as String? ?? 'Atanmamış';
      final status = row['status'] as String;

      if (!agg.containsKey(uid)) {
        agg[uid] = {
          'uid': uid,
          'name': name,
          'TOPLAM': 0,
          'YAPILDI': 0,
          'DND': 0,
          'RED': 0,
          'BEKLIYOR': 0,
        };
      }
      agg[uid]!['TOPLAM'] = (agg[uid]!['TOPLAM'] as int) + 1;
      agg[uid]![status] = ((agg[uid]![status] as int?) ?? 0) + 1;
    }
    return agg.values.toList();
  }

  Future<List<UserModel>> fetchActiveMaids() async {
    final data = await supabase
        .from('users')
        .select()
        .eq('role', 'maid')
        .eq('active', true)
        .order('name');
    return (data as List).map((e) => UserModel.fromMap(e)).toList();
  }
}
