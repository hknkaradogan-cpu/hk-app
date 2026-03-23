import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../services/task_service.dart';

class RoomImportScreen extends StatefulWidget {
  const RoomImportScreen({super.key});

  @override
  State<RoomImportScreen> createState() => _RoomImportScreenState();
}

class _RoomImportScreenState extends State<RoomImportScreen> {
  List<Map<String, dynamic>> _preview = [];
  bool _importing = false;
  String? _message;
  final _taskService = TaskService();

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final raw = String.fromCharCodes(result.files.single.bytes!);
    final rows = const CsvToListConverter(eol: '\n').convert(raw);

    if (rows.isEmpty) {
      setState(() => _message = 'Boş CSV dosyası.');
      return;
    }

    final header = rows.first.map((e) => e.toString().trim()).toList();
    final required = ['room_no', 'floor', 'task_type'];
    for (final col in required) {
      if (!header.contains(col)) {
        setState(() => _message = 'Sütun eksik: $col');
        return;
      }
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final parsed = <Map<String, dynamic>>[];
    for (final row in rows.skip(1)) {
      if (row.length < header.length) continue;
      final map = <String, dynamic>{};
      for (var i = 0; i < header.length; i++) {
        map[header[i]] = row[i].toString().trim();
      }
      parsed.add({
        'date': today,
        'room_no': map['room_no'],
        'floor': int.tryParse(map['floor'].toString()) ?? 0,
        'task_type': map['task_type'],
        'status': 'BEKLIYOR',
      });
    }
    setState(() {
      _preview = parsed;
      _message = '${parsed.length} satır yüklendi. İçe aktarmak için onaylayın.';
    });
  }

  Future<void> _importToDb() async {
    if (_preview.isEmpty) return;
    setState(() => _importing = true);
    try {
      await _taskService.insertTasks(_preview);
      setState(() {
        _message = '${_preview.length} oda başarıyla aktarıldı!';
        _preview = [];
      });
    } catch (e) {
      setState(() => _message = 'Hata: $e');
    }
    setState(() => _importing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CSV Format: room_no, floor, task_type',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('CSV Seç'),
                onPressed: _pickCsv,
              ),
              const SizedBox(width: 12),
              if (_preview.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text('Aktar (${_preview.length})'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  onPressed: _importing ? null : _importToDb,
                ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(_message!, style: const TextStyle(color: Colors.indigo)),
          ],
          const SizedBox(height: 16),
          if (_preview.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Oda No')),
                    DataColumn(label: Text('Kat')),
                    DataColumn(label: Text('Görev Tipi')),
                  ],
                  rows: _preview
                      .map((r) => DataRow(cells: [
                            DataCell(Text(r['room_no'].toString())),
                            DataCell(Text(r['floor'].toString())),
                            DataCell(Text(r['task_type'].toString())),
                          ]))
                      .toList(),
                ),
              ),
            ),
          if (_importing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
