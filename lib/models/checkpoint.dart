class Checkpoint {
  final String label;
  final String title;
  final String instruction;
  final double dx;
  final double dy;
  final bool isStop; // Indicates intermediate stop
  final double? latitude;
  final double? longitude;

  const Checkpoint({
    required this.label,
    required this.title,
    required this.instruction,
    this.dx = 0.5,
    this.dy = 0.5,
    this.isStop = false,
    this.latitude,
    this.longitude,
  });

  factory Checkpoint.fromMap(Map<String, dynamic> map) {
    return Checkpoint(
      label: map['label']?.toString() ?? '1',
      title: map['title']?.toString() ?? '',
      instruction: map['instruction']?.toString() ?? '',
      dx: (map['dx'] ?? 0.5).toDouble(),
      dy: (map['dy'] ?? 0.5).toDouble(),
      isStop: map['isStop'] ?? false,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'title': title,
      'instruction': instruction,
      'dx': dx,
      'dy': dy,
      'isStop': isStop,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
