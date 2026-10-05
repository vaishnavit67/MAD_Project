class CampusEvent {
  final String id;
  final String title;
  final String location;
  final String time;
  final String date;
  final String category;
  final String organizer;
  final String description;
  final String tag;

  const CampusEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.time,
    required this.date,
    required this.category,
    required this.organizer,
    required this.description,
    this.tag = 'Featured',
  });
}
