class Event {
  final String id;
  final String title;
  final DateTime date;
  final String timeString;
  final String? endTimeString;
  final String location;
  final String description;
  final String organizer;
  final int availableSeats;
  final String status; // upcoming, ongoing, past
  final String category;  // Hackathon, Technology, Workshop, Cultural, Sports, Club, Career, Academic, Other
  final int participantCount;
  final int capacity;
  final bool featured;
  final String? imageUrl;
  final String? createdBy;
  final String? createdByName;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.timeString,
    this.endTimeString,
    required this.location,
    required this.description,
    required this.organizer,
    required this.availableSeats,
    this.status = 'upcoming',
    this.category = 'Other',
    this.participantCount = 0,
    this.capacity = 100,
    this.featured = false,
    this.imageUrl,
    this.createdBy,
    this.createdByName,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['date'] is DateTime) {
      parsedDate = json['date'] as DateTime;
    } else if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Event(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled Event').toString(),
      date: parsedDate,
      timeString: (json['timeString'] ?? '10:00 AM').toString(),
      endTimeString: json['endTimeString']?.toString(),
      location: (json['location'] ?? 'Campus').toString(),
      description: (json['description'] ?? '').toString(),
      organizer: (json['organizer'] ?? 'Faculty Coordinator').toString(),
      availableSeats: json['availableSeats'] is int
          ? json['availableSeats']
          : (int.tryParse(json['availableSeats']?.toString() ?? '100') ?? 100),
      status: (json['status'] ?? 'upcoming').toString(),
      category: (json['category'] ?? 'Other').toString(),
      participantCount: json['participantCount'] is int
          ? json['participantCount']
          : (int.tryParse(json['participantCount']?.toString() ?? '0') ?? 0),
      capacity: json['capacity'] is int
          ? json['capacity']
          : (int.tryParse(json['capacity']?.toString() ?? '100') ?? 100),
      featured: json['featured'] == true,
      imageUrl: json['imageUrl']?.toString(),
      createdBy: json['createdBy']?.toString(),
      createdByName: json['createdByName']?.toString(),
    );
  }

  /// True if event date is in the past.
  bool get isPast => date.isBefore(DateTime.now().subtract(const Duration(hours: 1)));

  /// True if event falls within current week (Mon–Sun).
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd   = weekStart.add(const Duration(days: 7));
    return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) && date.isBefore(weekEnd);
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Event copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? timeString,
    String? endTimeString,
    String? location,
    String? description,
    String? organizer,
    int? availableSeats,
    String? status,
    String? category,
    int? participantCount,
    int? capacity,
    bool? featured,
    String? imageUrl,
    String? createdBy,
    String? createdByName,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      timeString: timeString ?? this.timeString,
      endTimeString: endTimeString ?? this.endTimeString,
      location: location ?? this.location,
      description: description ?? this.description,
      organizer: organizer ?? this.organizer,
      availableSeats: availableSeats ?? this.availableSeats,
      status: status ?? this.status,
      category: category ?? this.category,
      participantCount: participantCount ?? this.participantCount,
      capacity: capacity ?? this.capacity,
      featured: featured ?? this.featured,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}
