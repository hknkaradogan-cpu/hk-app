class TaskModel {
  final String id;
  final DateTime date;
  final String roomNo;
  final int floor;
  final String taskType;
  String status;
  final String? assignedTo;
  String? note;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.date,
    required this.roomNo,
    required this.floor,
    required this.taskType,
    required this.status,
    this.assignedTo,
    this.note,
    required this.updatedAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        roomNo: map['room_no'] as String,
        floor: map['floor'] as int,
        taskType: map['task_type'] as String,
        status: map['status'] as String,
        assignedTo: map['assigned_to'] as String?,
        note: map['note'] as String?,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String().substring(0, 10),
        'room_no': roomNo,
        'floor': floor,
        'task_type': taskType,
        'status': status,
        'assigned_to': assignedTo,
        'note': note,
        'updated_at': updatedAt.toIso8601String(),
      };
}
