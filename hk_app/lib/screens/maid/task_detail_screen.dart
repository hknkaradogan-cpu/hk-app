import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../services/audit_service.dart';
import '../../services/auth_provider.dart';
import '../../services/task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskModel _task;
  bool _saving = false;
  final _taskService = TaskService();
  final _auditService = AuditService();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _updateStatus(String newStatus) async {
    String? note;

    if (newStatus == 'RED') {
      note = await _showNoteDialog();
      if (note == null) return;
    }

    setState(() => _saving = true);
    final userId = context.read<AuthProvider>().user!.id;
    await _taskService.updateTaskStatus(_task.id, newStatus, note);
    await _auditService.log(
      taskId: _task.id,
      action: newStatus,
      byUserId: userId,
      note: note,
    );
    setState(() {
      _task.status = newStatus;
      if (note != null) _task.note = note;
      _saving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellendi: $newStatus'),
          backgroundColor: _statusColor(newStatus),
        ),
      );
    }
  }

  Future<String?> _showNoteDialog() async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Red Nedeni'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Red nedenini açıklayın...',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Not zorunlu' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Onayla',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final isDone = _task.status != 'BEKLIYOR';

    return Scaffold(
      appBar: AppBar(
        title: Text('Oda ${_task.roomNo}'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Oda No', _task.roomNo),
                    _infoRow('Kat', _task.floor.toString()),
                    _infoRow('Görev Tipi', _task.taskType.toUpperCase()),
                    _infoRow('Durum', _task.status),
                    if (_task.note != null && _task.note!.isNotEmpty)
                      _infoRow('Not', _task.note!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isDone)
              Center(
                child: Chip(
                  label: Text('Durum: ${_task.status}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16)),
                  backgroundColor: _statusColor(_task.status),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                ),
              )
            else ...[
              const Text('Durum Güncelle:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(
                    'YAPILDI',
                    Icons.check_circle,
                    Colors.green,
                    () => _updateStatus('YAPILDI'),
                  ),
                  _actionButton(
                    'DND',
                    Icons.do_not_disturb,
                    Colors.orange,
                    () => _updateStatus('DND'),
                  ),
                  _actionButton(
                    'RED',
                    Icons.cancel,
                    Colors.red,
                    () => _updateStatus('RED'),
                  ),
                ],
              ),
            ],
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      );

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label:
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
    );
  }
}
