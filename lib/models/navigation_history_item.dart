class NavigationHistoryItem {
  final String id;
  final String locationName;
  final String category;
  final String origin;
  final List<String> stops;
  final DateTime timestamp;
  final String distance;
  final String walkingTime;
  final String buildingCode;
  final int floorCount;
  final bool isFavorite;
  final int visitCount;
  final String userNote;

  const NavigationHistoryItem({
    required this.id,
    required this.locationName,
    required this.category,
    this.origin = 'My Current GPS Location',
    this.stops = const [],
    required this.timestamp,
    this.distance = '850 m',
    this.walkingTime = '~10 min',
    this.buildingCode = '',
    this.floorCount = 1,
    this.isFavorite = false,
    this.visitCount = 1,
    this.userNote = '',
  });

  NavigationHistoryItem copyWith({
    String? id,
    String? locationName,
    String? category,
    String? origin,
    List<String>? stops,
    DateTime? timestamp,
    String? distance,
    String? walkingTime,
    String? buildingCode,
    int? floorCount,
    bool? isFavorite,
    int? visitCount,
    String? userNote,
  }) {
    return NavigationHistoryItem(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      category: category ?? this.category,
      origin: origin ?? this.origin,
      stops: stops ?? this.stops,
      timestamp: timestamp ?? this.timestamp,
      distance: distance ?? this.distance,
      walkingTime: walkingTime ?? this.walkingTime,
      buildingCode: buildingCode ?? this.buildingCode,
      floorCount: floorCount ?? this.floorCount,
      isFavorite: isFavorite ?? this.isFavorite,
      visitCount: visitCount ?? this.visitCount,
      userNote: userNote ?? this.userNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'locationName': locationName,
      'category': category,
      'origin': origin,
      'stops': stops,
      'timestamp': timestamp.toIso8601String(),
      'distance': distance,
      'walkingTime': walkingTime,
      'buildingCode': buildingCode,
      'floorCount': floorCount,
      'isFavorite': isFavorite,
      'visitCount': visitCount,
      'userNote': userNote,
    };
  }

  factory NavigationHistoryItem.fromMap(Map<String, dynamic> map) {
    return NavigationHistoryItem(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      locationName: map['locationName'] ?? '',
      category: map['category'] ?? 'Campus Location',
      origin: map['origin'] ?? 'My Current GPS Location',
      stops: List<String>.from(map['stops'] ?? []),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      distance: map['distance'] ?? '850 m',
      walkingTime: map['walkingTime'] ?? '~10 min',
      buildingCode: map['buildingCode'] ?? '',
      floorCount: map['floorCount'] ?? 1,
      isFavorite: map['isFavorite'] ?? false,
      visitCount: map['visitCount'] ?? 1,
      userNote: map['userNote'] ?? '',
    );
  }
}
