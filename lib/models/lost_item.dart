class LostItem {
  final String id;
  final String title;
  final String locationFound;
  final String date;
  final String status; // 'Lost', 'Found', 'Claimed'
  final String contact;
  final String category;
  final String description;

  const LostItem({
    required this.id,
    required this.title,
    required this.locationFound,
    required this.date,
    required this.status,
    required this.contact,
    required this.category,
    required this.description,
  });
}
