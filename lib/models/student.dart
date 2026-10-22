class Student {
  final String id;
  final String name;
  final String email;
  final String department;
  final String year;
  final int postsCount;
  final int clubsCount;
  final int eventsCount;
  final String? profileImageUrl;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.year,
    this.postsCount = 0,
    this.clubsCount = 0,
    this.eventsCount = 0,
    this.profileImageUrl,
  });
}
