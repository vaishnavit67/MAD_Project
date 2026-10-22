class LostItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final String type; // 'lost' or 'found'
  final String location;
  final String timeAgo;
  final String? imageUrl;
  final String ownerId;
  final String ownerName;
  final String status; // 'active', 'claimed', 'resolved', 'Lost', 'Found'
  final DateTime? date;

  LostItem({
    required this.id,
    required this.name,
    required this.location,
    this.timeAgo = 'Recently',
    this.type = 'lost',
    this.imageUrl,
    required this.description,
    this.category = 'Other',
    this.ownerId = '',
    this.ownerName = '',
    this.status = 'active',
    this.date,
  });

  // Backward-compatibility aliases
  String get title => name;
  String get locationFound => location;
  String get contact => ownerName.isNotEmpty ? ownerName : 'Campus Security';

  factory LostItem.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] ?? json['createdAt'];
    DateTime? parsedDate;
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString());
    }

    String timeStr = 'Recently';
    if (parsedDate != null) {
      final diff = DateTime.now().difference(parsedDate);
      if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours}h ago';
      } else {
        timeStr = '${diff.inDays}d ago';
      }
    }

    return LostItem(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      type: (json['type'] ?? 'lost').toString().toLowerCase(),
      location: json['location'] ?? '',
      timeAgo: timeStr,
      imageUrl: json['imageUrl'],
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      status: json['status'] ?? 'active',
      date: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,
      'description': description,
      'category': category,
      'type': type,
      'location': location,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'status': status,
      'date': date?.toIso8601String(),
    };
  }
}
