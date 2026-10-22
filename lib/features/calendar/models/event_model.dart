class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String location;
  final String category;
  final int reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int notificationId;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.location,
    required this.category,
    required this.reminderMinutes,
    required this.createdAt,
    required this.updatedAt,
    required this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'location': location,
      'category': category,
      'reminderMinutes': reminderMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notificationId': notificationId,
    };
  }

  factory EventModel.fromMap(Map<dynamic, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      startDateTime: DateTime.parse(map['startDateTime'] as String),
      endDateTime: DateTime.parse(map['endDateTime'] as String),
      location: map['location'] as String,
      category: map['category'] as String,
      reminderMinutes: map['reminderMinutes'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      notificationId: map['notificationId'] as int,
    );
  }
}
