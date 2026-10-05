class Checkpoint {
  final String label;
  final String title;
  final String instruction;
  final double dx;
  final double dy;
  final bool isStop; // Indicates intermediate stop

  const Checkpoint({
    required this.label,
    required this.title,
    required this.instruction,
    this.dx = 0.5,
    this.dy = 0.5,
    this.isStop = false,
  });

  factory Checkpoint.fromMap(Map<String, dynamic> map) {
    return Checkpoint(
      label: map['label']?.toString() ?? '1',
      title: map['title']?.toString() ?? '',
      instruction: map['instruction']?.toString() ?? '',
      dx: (map['dx'] ?? 0.5).toDouble(),
      dy: (map['dy'] ?? 0.5).toDouble(),
      isStop: map['isStop'] ?? false,
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
    };
  }
}
