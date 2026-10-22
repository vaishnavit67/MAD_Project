class Club {
  final String id;
  final String name;
  final String category;
  final int membersCount;
  final String description;
  final String? imageUrl;

  Club({
    required this.id,
    required this.name,
    required this.category,
    required this.membersCount,
    required this.description,
    this.imageUrl,
  });
}
