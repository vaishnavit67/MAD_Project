class BusScheduleItem {
  final String departureTime;
  final String shuttleName;
  final int hour;
  final int minute;
  final String? note;
  final bool isLast;

  const BusScheduleItem({
    required this.departureTime,
    required this.shuttleName,
    required this.hour,
    required this.minute,
    this.note,
    this.isLast = false,
  });
}
