class Club {
  final String id;
  final String name;
  final String category;
  final int membersCount;
  final String description;
  final String? imageUrl;
  final String createdBy;
  final String createdByName;
  final String leadEmail;

  Club({
    required this.id,
    required this.name,
    required this.category,
    required this.membersCount,
    required this.description,
    this.imageUrl,
    this.createdBy = 'seed-faculty-001',
    this.createdByName = 'Dr. Priya Sharma (Faculty Coordinator)',
    this.leadEmail = 'faculty@cb.amrita.edu',
  });
}
