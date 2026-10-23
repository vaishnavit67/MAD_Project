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
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      title: (map['title'] ?? 'Campus Event').toString(),
      description: (map['description'] ?? '').toString(),
      startDateTime: map['startDateTime'] != null
          ? (DateTime.tryParse(map['startDateTime'].toString()) ?? DateTime.now())
          : DateTime.now(),
      endDateTime: map['endDateTime'] != null
          ? (DateTime.tryParse(map['endDateTime'].toString()) ?? DateTime.now().add(const Duration(hours: 1)))
          : DateTime.now().add(const Duration(hours: 1)),
      location: (map['location'] ?? 'Campus').toString(),
      category: (map['category'] ?? 'General').toString(),
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
