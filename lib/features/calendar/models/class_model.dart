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
        id: (map['id'] ?? map['_id'] ?? '').toString(),
        subject: (map['subject'] ?? map['title'] ?? 'Class').toString(),
        dayOfWeek: map['dayOfWeek'] is int
            ? (map['dayOfWeek'] as int)
            : (int.tryParse(map['dayOfWeek']?.toString() ?? '1') ?? 1),
        startTime: (map['startTime'] ?? '09:00 AM').toString(),
        endTime: (map['endTime'] ?? '10:00 AM').toString(),
        room: (map['room'] ?? map['location'] ?? '').toString(),
        teacher: (map['teacher'] ?? map['instructor'] ?? '').toString(),
        isWeekly: map['isWeekly'] == true || map['isWeekly'] == null,
        createdAt: map['createdAt'] != null
            ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
            : DateTime.now(),
      );

  /// Returns true if this class falls on the given [date].
  bool occursOn(DateTime date) {
    return isWeekly && date.weekday == dayOfWeek;
  }

  /// Convert any time format ("09:00 AM", "2:30 PM", "14:30") to a DateTime on [date] safely.
  static DateTime parseTimeOn(DateTime date, String timeStr) {
    int hour = 9;
    int minute = 0;
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final stripped = clean.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = stripped.split(':');
      if (parts.isNotEmpty) {
        hour = int.tryParse(parts[0]) ?? 9;
      }
      if (parts.length > 1) {
        minute = int.tryParse(parts[1]) ?? 0;
      }
      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
    } catch (_) {}
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime startDateTimeOn(DateTime date) => parseTimeOn(date, startTime);

  DateTime endDateTimeOn(DateTime date) => parseTimeOn(date, endTime);
}
