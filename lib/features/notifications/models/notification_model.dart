class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // event_reminder, task_due, etc.
  final bool isRead;
  final String? relatedEventId;
  final String? relatedTaskId;
  final String? relatedClubId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedEventId,
    this.relatedTaskId,
    this.relatedClubId,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
      relatedEventId: relatedEventId,
      relatedTaskId: relatedTaskId,
      relatedClubId: relatedClubId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
      'relatedEventId': relatedEventId,
      'relatedTaskId': relatedTaskId,
      'relatedClubId': relatedClubId,
    };
  }

  factory NotificationModel.fromMap(Map<dynamic, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: map['type'] as String,
      isRead: map['isRead'] as bool,
      relatedEventId: map['relatedEventId'] as String?,
      relatedTaskId: map['relatedTaskId'] as String?,
      relatedClubId: map['relatedClubId'] as String?,
    );
  }
}
