import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _stats = [];
  bool _loading = false;
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _taskService.dashboardStatsFull(_date);
    setState(() {
      _stats = data;
      _loading = false;
    });
  }

  Color _progressColor(int done, int total) {
    if (total == 0) return Colors.grey;
    final ratio = done / total;
    if (ratio >= 1) return Colors.green;
    if (ratio >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
                        _date = DateFormat('yyyy-MM-dd').format(picked));
                    _load();
                  }
                },
                child: Chip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_date),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.refresh), onPressed: _load),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _stats.isEmpty
                  ? const Center(child: Text('Veri yok'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _stats.length,
                      itemBuilder: (context, i) {
                        final s = _stats[i];
                        final total = s['TOPLAM'] as int;
                        final done = s['YAPILDI'] as int;
                        final dnd = s['DND'] as int;
                        final red = s['RED'] as int;
                        final bekliyor = s['BEKLIYOR'] as int;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Color(0xFF1A237E)),
                                    const SizedBox(width: 8),
                                    Text(
                                      s['name'] as String,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    Text('$done/$total',
                                        style: TextStyle(
                                            color: _progressColor(done, total),
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (total > 0)
                                  LinearProgressIndicator(
                                    value: done / total,
                                    color: _progressColor(done, total),
                                    backgroundColor: Colors.grey[200],
                                    minHeight: 8,
                                  ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _statChip('Bekliyor', bekliyor,
                                        Colors.grey),
                                    _statChip(
                                        'Yapıldı', done, Colors.green),
                                    _statChip('DND', dnd, Colors.orange),
                                    _statChip('Red', red, Colors.red),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _statChip(String label, int count, Color color) => Chip(
        label: Text('$label: $count',
            style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: color,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}
