class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDateTime;
  final String priority; // Low, Medium, High
  final String category;
  final bool completed;
  final int reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int notificationId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDateTime,
    required this.priority,
    required this.category,
    this.completed = false,
    required this.reminderMinutes,
    required this.createdAt,
    required this.updatedAt,
    required this.notificationId,
  });

  TaskModel copyWith({bool? completed, DateTime? updatedAt}) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      dueDateTime: dueDateTime,
      priority: priority,
      category: category,
      completed: completed ?? this.completed,
      reminderMinutes: reminderMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationId: notificationId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDateTime': dueDateTime.toIso8601String(),
      'priority': priority,
      'category': category,
      'completed': completed,
      'reminderMinutes': reminderMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notificationId': notificationId,
    };
  }

  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    return TaskModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      title: (map['title'] ?? 'Campus Task').toString(),
      description: (map['description'] ?? '').toString(),
      dueDateTime: map['dueDateTime'] != null
          ? (DateTime.tryParse(map['dueDateTime'].toString()) ?? DateTime.now())
          : DateTime.now(),
      priority: (map['priority'] ?? 'Medium').toString(),
      category: (map['category'] ?? 'General').toString(),
      completed: map['completed'] == true,
      reminderMinutes: map['reminderMinutes'] is int
          ? (map['reminderMinutes'] as int)
          : (int.tryParse(map['reminderMinutes']?.toString() ?? '15') ?? 15),
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      notificationId: map['notificationId'] is int
          ? (map['notificationId'] as int)
          : (int.tryParse(map['notificationId']?.toString() ?? '0') ?? 0),
    );
  }
}
