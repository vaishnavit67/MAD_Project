import 'checkpoint.dart';

class CampusLocation {
  final String id;
  final String name;
  final String category;
  final String description;
  final String distance;
  final String walkingTime;
  final String buildingCode;
  final int floorCount;
  final bool isFavorite;
  final List<String> keywords;
  final List<Checkpoint> checkpoints;

  const CampusLocation({
    this.id = '',
    required this.name,
    required this.category,
    this.description = '',
    this.distance = '850 m',
    this.walkingTime = '~10 min',
    this.buildingCode = '',
    this.floorCount = 1,
    this.isFavorite = false,
    this.keywords = const [],
    this.checkpoints = const [],
  });

  CampusLocation copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? distance,
    String? walkingTime,
    String? buildingCode,
    int? floorCount,
    bool? isFavorite,
    List<String>? keywords,
    List<Checkpoint>? checkpoints,
  }) {
    return CampusLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      distance: distance ?? this.distance,
      walkingTime: walkingTime ?? this.walkingTime,
      buildingCode: buildingCode ?? this.buildingCode,
      floorCount: floorCount ?? this.floorCount,
      isFavorite: isFavorite ?? this.isFavorite,
      keywords: keywords ?? this.keywords,
      checkpoints: checkpoints ?? this.checkpoints,
    );
  }

  factory CampusLocation.fromMap(Map<String, dynamic> map, [String docId = '']) {
    return CampusLocation(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      distance: map['distance'] ?? '850 m',
      walkingTime: map['walkingTime'] ?? '~10 min',
      buildingCode: map['buildingCode'] ?? '',
      floorCount: map['floorCount'] ?? 1,
      isFavorite: map['isFavorite'] ?? false,
      keywords: List<String>.from(map['keywords'] ?? []),
      checkpoints: (map['checkpoints'] as List<dynamic>?)
              ?.map((c) => Checkpoint.fromMap(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'distance': distance,
      'walkingTime': walkingTime,
      'buildingCode': buildingCode,
      'floorCount': floorCount,
      'isFavorite': isFavorite,
      'keywords': keywords,
      'checkpoints': checkpoints.map((c) => c.toMap()).toList(),
    };
  }
}
