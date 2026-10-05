class BusRoute {
  final String id;
  final String routeName;
  final String busNumber;
  final String currentStop;
  final String nextStop;
  final String arrivalTime;
  final String status; // 'On Time', 'Delayed', 'Arriving'
  final List<String> stops;

  const BusRoute({
    required this.id,
    required this.routeName,
    required this.busNumber,
    required this.currentStop,
    required this.nextStop,
    required this.arrivalTime,
    required this.status,
    required this.stops,
  });
}
