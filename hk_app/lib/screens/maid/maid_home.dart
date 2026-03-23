import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../services/auth_provider.dart';
import '../../services/task_service.dart';
import 'task_detail_screen.dart';

class MaidHomeScreen extends StatefulWidget {
  const MaidHomeScreen({super.key});

  @override
  State<MaidHomeScreen> createState() => _MaidHomeScreenState();
}

class _MaidHomeScreenState extends State<MaidHomeScreen> {
  List<TaskModel> _tasks = [];
  bool _loading = false;
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = context.read<AuthProvider>().user!.id;
    final tasks = await _taskService.fetchTodayTasksForMaid(uid);
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'YAPILDI':
        return Colors.green;
      case 'DND':
        return Colors.orange;
      case 'RED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'checkout':
        return Icons.exit_to_app;
      case 'arrival':
        return Icons.meeting_room;
      default:
        return Icons.cleaning_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: Text('Görevlerim – ${user?.name ?? ''}'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green),
                      SizedBox(height: 12),
                      Text('Bugün için göreviniz yok',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final t = _tasks[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1A237E),
                            child: Icon(_typeIcon(t.taskType),
                                color: Colors.white, size: 20),
                          ),
                          title: Text('Oda ${t.roomNo}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Kat ${t.floor}  •  ${t.taskType.toUpperCase()}'),
                          trailing: Chip(
                            label: Text(t.status,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                            backgroundColor: _statusColor(t.status),
                            padding: EdgeInsets.zero,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TaskDetailScreen(task: t),
                              ),
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
