class ClassModel {
  final String id;
  final String subject;
  final int dayOfWeek; // 1=Mon, 2=Tue, ... 7=Sun (ISO weekday)
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final String room;
  final String teacher;
  final bool isWeekly;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.teacher = '',
    this.isWeekly = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'teacher': teacher,
        'isWeekly': isWeekly,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ClassModel.fromMap(Map<dynamic, dynamic> map) => ClassModel(
        id: map['id'] as String,
        subject: map['subject'] as String,
        dayOfWeek: map['dayOfWeek'] as int,
        startTime: map['startTime'] as String,
        endTime: map['endTime'] as String,
        room: map['room'] as String,
        teacher: (map['teacher'] ?? '') as String,
        isWeekly: (map['isWeekly'] ?? true) as bool,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  /// Returns true if this class falls on the given [date].
  bool occursOn(DateTime date) {
    return isWeekly && date.weekday == dayOfWeek;
  }

  /// Convert "HH:mm" string to a DateTime on [date].
  DateTime startDateTimeOn(DateTime date) {
    final parts = startTime.split(':');
    return DateTime(date.year, date.month, date.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  DateTime endDateTimeOn(DateTime date) {
    final parts = endTime.split(':');
    return DateTime(date.year, date.month, date.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }
}
