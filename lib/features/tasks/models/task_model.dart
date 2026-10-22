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
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDateTime: DateTime.parse(map['dueDateTime'] as String),
      priority: map['priority'] as String,
      category: map['category'] as String,
      completed: map['completed'] as bool,
      reminderMinutes: map['reminderMinutes'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      notificationId: map['notificationId'] as int,
    );
  }
}
