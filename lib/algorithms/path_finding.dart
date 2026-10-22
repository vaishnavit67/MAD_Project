import 'package:latlong2/latlong.dart';
import '../models/campus_location.dart';
import '../models/checkpoint.dart';
import '../utils/constants.dart';
import 'campus_graph.dart';
import 'dijkstra_path_finding.dart';

class PathFinding {
  static final CampusGraph campusGraph = CampusGraph.buildAmritaCampusGraph();
  static final List<List<LatLng>> campusRoadPolylines = campusGraph.getAllRoadPolylines();
  static final List<CampusNode> campusPoiNodes = campusGraph.nodes.values.where((n) => n.isPoi).toList();

  /// Computes the authentic Dijkstra shortest path result with turn maneuvers
  static DijkstraResult getDijkstraRoute({
    required String startLocation,
    required List<String> stops,
    required CampusLocation destination,
    double? startLat,
    double? startLng,
  }) {
    return DijkstraPathFinding.findMultiStopRoute(
      graph: campusGraph,
      startLocationQuery: startLocation,
      intermediateStopQueries: stops,
      destinationQuery: destination.name,
      destLat: destination.latitude,
      destLng: destination.longitude,
      startLat: startLat,
      startLng: startLng,
    );
  }

  /// Compatibility alias for turn-by-turn route generation
  static List<Checkpoint> getRoute({
    required String origin,
    required CampusLocation destination,
    List<String> stops = const [],
  }) {
    return getMultiStopRoute(
      startLocation: origin,
      stops: stops,
      destination: destination,
    );
  }

  /// Generates dynamic multi-stop route checkpoints using Dijkstra's Algorithm
  static List<Checkpoint> getMultiStopRoute({
    required String startLocation,
    required List<String> stops,
    required CampusLocation destination,
  }) {
    final dijkstraResult = getDijkstraRoute(
      startLocation: startLocation,
      stops: stops,
      destination: destination,
    );

    final maneuvers = dijkstraResult.maneuvers;
    if (maneuvers.isEmpty) {
      return [
        Checkpoint(
          label: '1',
          title: 'Campus Main Gate',
          instruction: 'Start navigation from Main Gate.',
          latitude: amritaMainGateLat,
          longitude: amritaMainGateLng,
          dx: -0.80,
          dy: 0.70,
        ),
        Checkpoint(
          label: '🏁',
          title: destination.name,
          instruction: 'Arrive at ${destination.name}.',
          latitude: destination.latitude ?? amritaCampusCenterLat,
          longitude: destination.longitude ?? amritaCampusCenterLng,
          dx: 0.70,
          dy: -0.65,
        ),
      ];
    }

    final checkpoints = <Checkpoint>[];
    int stepNum = 1;

    for (int i = 0; i < maneuvers.length; i++) {
      final m = maneuvers[i];
      final isFirst = (i == 0);
      final isLast = (i == maneuvers.length - 1);

      // Check if this node matches one of the requested intermediate stops
      final nodeTitle = dijkstraResult.nodes.length > i ? dijkstraResult.nodes[i].name : m.roadName;
      final isStop = !isFirst && !isLast && stops.any((s) => s.toLowerCase() == nodeTitle.toLowerCase());

      String label;
      if (isFirst) {
        label = '1';
      } else if (isLast) {
        label = '🏁';
      } else if (isStop) {
        final stopIdx = stops.indexWhere((s) => s.toLowerCase() == nodeTitle.toLowerCase());
        label = 'S${stopIdx + 1}';
      } else {
        label = '$stepNum';
        stepNum++;
      }

      checkpoints.add(Checkpoint(
        label: label,
        title: isLast ? destination.name : nodeTitle,
        instruction: m.instruction,
        latitude: m.point.latitude,
        longitude: m.point.longitude,
        isStop: isStop,
        dx: (m.point.longitude - amritaCampusCenterLng) * 100,
        dy: -(m.point.latitude - amritaCampusCenterLat) * 100,
      ));
    }

    return checkpoints;
  }

  /// Legacy helper fallback
  static List<Checkpoint> getRouteForDestination(
    String startPoint,
    CampusLocation destination,
  ) {
    return getMultiStopRoute(
      startLocation: startPoint,
      stops: const [],
      destination: destination,
    );
  }
}
