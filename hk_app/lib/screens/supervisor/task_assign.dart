import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/audit_service.dart';
import '../../services/fcm_service.dart';
import '../../core/supabase_client.dart';

class TaskAssignScreen extends StatefulWidget {
  const TaskAssignScreen({super.key});

  @override
  State<TaskAssignScreen> createState() => _TaskAssignScreenState();
}

class _TaskAssignScreenState extends State<TaskAssignScreen> {
  List<TaskModel> _tasks = [];
  List<UserModel> _maids = [];
  bool _loading = false;

  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  int? _filterFloor;
  String? _filterType;

  final Set<String> _selected = {};
  final _taskService = TaskService();
  final _auditService = AuditService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tasks = await _taskService.fetchAllTasksForSupervisor(
      date: _selectedDate,
      floor: _filterFloor,
      taskType: _filterType,
    );
    final maids = await _taskService.fetchActiveMaids();
    setState(() {
      _tasks = tasks;
      _maids = maids;
      _loading = false;
      _selected.clear();
    });
  }

  Future<void> _bulkAssign(UserModel maid) async {
    if (_selected.isEmpty) return;
    final ids = _selected.toList();
    await _taskService.bulkAssign(ids, maid.id);

    final supervisorId = supabase.auth.currentUser!.id;
    for (final id in ids) {
      await _auditService.log(
        taskId: id,
        action: 'ASSIGN',
        byUserId: supervisorId,
        note: 'Atanan: ${maid.name}',
      );
    }

    await FcmService.sendPushToUser(
      userId: maid.id,
      title: 'Yeni Görev Ataması',
      body: '${ids.length} oda size atandı.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${ids.length} görev ${maid.name} atandı'),
            backgroundColor: Colors.green),
      );
    }
    _load();
  }

  String _maidName(String? uid) {
    if (uid == null) return '-';
    return _maids.firstWhere((m) => m.id == uid,
            orElse: () => UserModel(
                id: '', name: uid, email: '', role: '', active: false))
        .name;
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
    final floors = _tasks.map((t) => t.floor).toSet().toList()..sort();

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() =>
                        _selectedDate = DateFormat('yyyy-MM-dd').format(picked));
                    _load();
                  }
                },
                child: Chip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_selectedDate),
                ),
              ),
              DropdownButton<int?>(
                hint: const Text('Kat'),
                value: _filterFloor,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tüm Katlar')),
                  ...floors.map((f) =>
                      DropdownMenuItem(value: f, child: Text('Kat $f'))),
                ],
                onChanged: (v) {
                  setState(() => _filterFloor = v);
                  _load();
                },
              ),
              DropdownButton<String?>(
                hint: const Text('Tip'),
                value: _filterType,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tüm Tipler')),
                  DropdownMenuItem(value: 'checkout', child: Text('Checkout')),
                  DropdownMenuItem(value: 'stayover', child: Text('Stayover')),
                  DropdownMenuItem(value: 'arrival', child: Text('Arrival')),
                ],
                onChanged: (v) {
                  setState(() => _filterType = v);
                  _load();
                },
              ),
              if (_selected.isNotEmpty)
                DropdownButton<UserModel>(
                  hint: Text('Toplu Ata (${_selected.length})'),
                  items: _maids
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(m.name)))
                      .toList(),
                  onChanged: (m) {
                    if (m != null) _bulkAssign(m);
                  },
                ),
            ],
          ),
        ),
        const Divider(),
        // Table
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _tasks.isEmpty
                  ? const Center(child: Text('Görev bulunamadı'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: true,
                        columns: const [
                          DataColumn(label: Text('Oda')),
                          DataColumn(label: Text('Kat')),
                          DataColumn(label: Text('Tip')),
                          DataColumn(label: Text('Durum')),
                          DataColumn(label: Text('Atanan')),
                        ],
                        rows: _tasks
                            .map((t) => DataRow(
                                  selected: _selected.contains(t.id),
                                  onSelectChanged: (v) => setState(() {
                                    if (v == true) {
                                      _selected.add(t.id);
                                    } else {
                                      _selected.remove(t.id);
                                    }
                                  }),
                                  cells: [
                                    DataCell(Text(t.roomNo)),
                                    DataCell(Text(t.floor.toString())),
                                    DataCell(Text(t.taskType)),
                                    DataCell(Chip(
                                      label: Text(t.status,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                      backgroundColor: _statusColor(t.status),
                                    )),
                                    DataCell(Text(_maidName(t.assignedTo))),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
        ),
      ],
    );
  }
}
