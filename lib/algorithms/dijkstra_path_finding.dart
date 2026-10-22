import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
import 'campus_graph.dart';

class NavigationManeuver {
  final String instruction;
  final String shortAction;
  final String roadName;
  final double distanceMeters;
  final LatLng point;
  final IconData icon;
  final double cumulativeDistanceMeters;
  final bool isShortcut;

  const NavigationManeuver({
    required this.instruction,
    required this.shortAction,
    required this.roadName,
    required this.distanceMeters,
    required this.point,
    required this.icon,
    required this.cumulativeDistanceMeters,
    this.isShortcut = false,
  });
}

class DijkstraResult {
  final List<CampusNode> nodes;
  final List<LatLng> polylinePoints;
  final double totalDistanceMeters;
  final String walkingTime;
  final List<NavigationManeuver> maneuvers;

  const DijkstraResult({
    required this.nodes,
    required this.polylinePoints,
    required this.totalDistanceMeters,
    required this.walkingTime,
    required this.maneuvers,
  });
}

class DijkstraPathFinding {
  /// Computes shortest path between single source and destination using Dijkstra's Algorithm
  static List<CampusNode> computeDijkstra(
    CampusGraph graph,
    String startNodeId,
    String destinationNodeId,
  ) {
    if (!graph.nodes.containsKey(startNodeId) || !graph.nodes.containsKey(destinationNodeId)) {
      return [];
    }

    if (startNodeId == destinationNodeId) {
      return [graph.nodes[startNodeId]!];
    }

    final distances = <String, double>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};

    for (final nodeId in graph.nodes.keys) {
      distances[nodeId] = double.infinity;
      previous[nodeId] = null;
      unvisited.add(nodeId);
    }

    distances[startNodeId] = 0.0;

    while (unvisited.isNotEmpty) {
      // Extract node with minimum distance
      String? currentId;
      double minDistance = double.infinity;

      for (final nodeId in unvisited) {
        final dist = distances[nodeId]!;
        if (dist < minDistance) {
          minDistance = dist;
          currentId = nodeId;
        }
      }

      if (currentId == null || minDistance == double.infinity) {
        break; // Remaining nodes are unreachable
      }

      if (currentId == destinationNodeId) {
        break; // Target reached
      }

      unvisited.remove(currentId);

      final edges = graph.adjacencyList[currentId] ?? [];
      for (final edge in edges) {
        if (!unvisited.contains(edge.toId)) continue;

        final alt = distances[currentId]! + edge.distanceMeters;
        if (alt < distances[edge.toId]!) {
          distances[edge.toId] = alt;
          previous[edge.toId] = currentId;
        }
      }
    }

    // Reconstruct path backwards
    final path = <CampusNode>[];
    String? curr = destinationNodeId;

    while (curr != null) {
      final node = graph.nodes[curr];
      if (node != null) {
        path.insert(0, node);
      }
      curr = previous[curr];
    }

    // If start is not first element, destination was unreachable
    if (path.isEmpty || path.first.id != startNodeId) {
      return [];
    }

    return path;
  }

  /// Calculates bearing between two LatLng points in degrees (0 to 360)
  static double calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180.0;
    final lat2 = to.latitude * math.pi / 180.0;
    final dLon = (to.longitude - from.longitude) * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final rad = math.atan2(y, x);
    return (rad * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Generates Google Maps style turn-by-turn navigation maneuvers along the Dijkstra path
  static List<NavigationManeuver> generateTurnByTurnManeuvers(
    CampusGraph graph,
    List<CampusNode> pathNodes,
  ) {
    if (pathNodes.isEmpty) return [];
    if (pathNodes.length == 1) {
      return [
        NavigationManeuver(
          instruction: 'Arrive at ${pathNodes.first.name}',
          shortAction: 'Arrive',
          roadName: pathNodes.first.name,
          distanceMeters: 0,
          point: pathNodes.first.latLng,
          icon: Icons.flag_rounded,
          cumulativeDistanceMeters: 0,
        ),
      ];
    }

    final maneuvers = <NavigationManeuver>[];
    const distance = Distance();
    double cumulative = 0.0;

    // Helper to find road name between two adjacent nodes
    String getRoadName(String fromId, String toId) {
      final edges = graph.adjacencyList[fromId] ?? [];
      for (final e in edges) {
        if (e.toId == toId) return e.roadName;
      }
      return 'Campus Pathway';
    }

    // Initial step: Depart from start
    final firstSegDist = distance.as(LengthUnit.Meter, pathNodes[0].latLng, pathNodes[1].latLng);
    final firstRoad = getRoadName(pathNodes[0].id, pathNodes[1].id);

    maneuvers.add(NavigationManeuver(
      instruction: 'Start walking along $firstRoad towards ${pathNodes[1].name}',
      shortAction: 'Head out',
      roadName: firstRoad,
      distanceMeters: firstSegDist,
      point: pathNodes[0].latLng,
      icon: Icons.directions_walk_rounded,
      cumulativeDistanceMeters: 0,
    ));
    cumulative += firstSegDist;

    // Intermediate junctions
    for (int i = 1; i < pathNodes.length - 1; i++) {
      final prev = pathNodes[i - 1];
      final curr = pathNodes[i];
      final next = pathNodes[i + 1];

      final incomingBearing = calculateBearing(prev.latLng, curr.latLng);
      final outgoingBearing = calculateBearing(curr.latLng, next.latLng);

      // Angle difference: positive is turn right, negative is turn left
      double deltaAngle = outgoingBearing - incomingBearing;
      while (deltaAngle > 180.0) {
        deltaAngle -= 360.0;
      }
      while (deltaAngle < -180.0) {
        deltaAngle += 360.0;
      }

      final nextRoad = getRoadName(curr.id, next.id);
      final segDist = distance.as(LengthUnit.Meter, curr.latLng, next.latLng);
      final isShortcut = nextRoad.toLowerCase().contains('shortcut') ||
          nextRoad.toLowerCase().contains('corridor') ||
          nextRoad.toLowerCase().contains('link') ||
          nextRoad.toLowerCase().contains('colonnade') ||
          nextRoad.toLowerCase().contains('walkway');

      IconData icon;
      String shortAction;
      String instruction;

      if (isShortcut && deltaAngle.abs() < 45.0) {
        icon = Icons.bolt_rounded;
        shortAction = 'Shortcut';
        instruction = 'Take pedestrian shortcut: $nextRoad past ${curr.name}';
      } else if (deltaAngle > 120.0) {
        icon = Icons.u_turn_right_rounded;
        shortAction = 'Sharp Right';
        instruction = 'Make a sharp right onto $nextRoad at ${curr.name}';
      } else if (deltaAngle > 45.0) {
        icon = Icons.turn_right_rounded;
        shortAction = 'Turn Right';
        instruction = 'Turn right onto $nextRoad at ${curr.name}';
      } else if (deltaAngle > 15.0) {
        icon = Icons.turn_slight_right_rounded;
        shortAction = 'Slight Right';
        instruction = 'Take slight right onto $nextRoad';
      } else if (deltaAngle < -120.0) {
        icon = Icons.u_turn_left_rounded;
        shortAction = 'Sharp Left';
        instruction = 'Make a sharp left onto $nextRoad at ${curr.name}';
      } else if (deltaAngle < -45.0) {
        icon = Icons.turn_left_rounded;
        shortAction = 'Turn Left';
        instruction = 'Turn left onto $nextRoad at ${curr.name}';
      } else if (deltaAngle < -15.0) {
        icon = Icons.turn_slight_left_rounded;
        shortAction = 'Slight Left';
        instruction = 'Take slight left onto $nextRoad';
      } else {
        icon = isShortcut ? Icons.bolt_rounded : Icons.straight_rounded;
        shortAction = isShortcut ? 'Shortcut' : 'Continue';
        instruction = isShortcut
            ? 'Continue on shortcut: $nextRoad'
            : 'Continue straight on $nextRoad past ${curr.name}';
      }

      maneuvers.add(NavigationManeuver(
        instruction: instruction,
        shortAction: shortAction,
        roadName: nextRoad,
        distanceMeters: segDist,
        point: curr.latLng,
        icon: icon,
        cumulativeDistanceMeters: cumulative,
        isShortcut: isShortcut,
      ));

      cumulative += segDist;
    }

    // Final arrival step
    final lastNode = pathNodes.last;
    maneuvers.add(NavigationManeuver(
      instruction: 'Arrive at destination: ${lastNode.name}',
      shortAction: 'Arrived',
      roadName: lastNode.name,
      distanceMeters: 0,
      point: lastNode.latLng,
      icon: Icons.flag_rounded,
      cumulativeDistanceMeters: cumulative,
    ));

    return maneuvers;
  }

  /// Finds complete multi-stop shortest route using Dijkstra on the campus road graph
  static DijkstraResult findMultiStopRoute({
    required CampusGraph graph,
    required String startLocationQuery,
    required List<String> intermediateStopQueries,
    required String destinationQuery,
    double? destLat,
    double? destLng,
    double? startLat,
    double? startLng,
  }) {
    CampusNode resolveNode(String query, {double? lat, double? lng, required String defaultId}) {
      CampusNode? node;
      final clean = query.trim().toLowerCase();
      final isGenericGps = clean.isEmpty || clean.contains('gps') || clean.contains('current');

      // 1. If an explicit named location is requested, always prioritize the POI on the road network
      if (!isGenericGps) {
        node = graph.findNodeByName(query);
      }

      // 2. If it is live GPS mode or name matching didn't yield a node, check GPS proximity
      if (node == null && lat != null && lng != null) {
        const campusCenter = LatLng(amritaCampusCenterLat, amritaCampusCenterLng);
        final distM = const Distance().as(LengthUnit.Meter, LatLng(lat, lng), campusCenter);
        // Only snap to nearest road node if coordinates are within campus vicinity (~3500m)
        if (distM <= 3500) {
          node = graph.findNearestNode(lat, lng);
        }
      }

      // 3. Fallback to name search or default anchor (e.g. main_gate)
      node ??= graph.findNodeByName(query);
      return node ?? graph.nodes[defaultId] ?? graph.nodes.values.first;
    }

    // 1. Resolve start node
    final startNode = resolveNode(
      startLocationQuery,
      lat: startLat,
      lng: startLng,
      defaultId: 'main_gate',
    );

    // 2. Resolve destination node
    final destNode = resolveNode(
      destinationQuery,
      lat: destLat,
      lng: destLng,
      defaultId: 'central_library',
    );

    // 3. Chain intermediate stops
    final stopNodes = <CampusNode>[];
    for (final stopName in intermediateStopQueries) {
      final sNode = graph.findNodeByName(stopName);
      if (sNode != null && sNode.id != startNode.id && sNode.id != destNode.id) {
        stopNodes.add(sNode);
      }
    }

    final sequence = [startNode, ...stopNodes, destNode];
    final combinedNodes = <CampusNode>[];

    for (int i = 0; i < sequence.length - 1; i++) {
      final subPath = computeDijkstra(graph, sequence[i].id, sequence[i + 1].id);
      if (subPath.isNotEmpty) {
        if (combinedNodes.isEmpty) {
          combinedNodes.addAll(subPath);
        } else {
          // Avoid duplicate pivot node
          combinedNodes.addAll(subPath.skip(1));
        }
      }
    }

    // Fallback if no path found
    if (combinedNodes.isEmpty) {
      combinedNodes.add(startNode);
      combinedNodes.add(destNode);
    }

    // Calculate total geodesic distance along the Dijkstra path
    const distance = Distance();
    double totalMeters = 0.0;
    final polylinePoints = <LatLng>[];

    for (int i = 0; i < combinedNodes.length; i++) {
      polylinePoints.add(combinedNodes[i].latLng);
      if (i > 0) {
        totalMeters += distance.as(
          LengthUnit.Meter,
          combinedNodes[i - 1].latLng,
          combinedNodes[i].latLng,
        );
      }
    }

    // Walking speed: ~1.2 m/s -> ~72 m/min
    final walkingMinutes = (totalMeters / 72.0).ceil().clamp(1, 120);
    final walkingTimeStr = '~$walkingMinutes min';

    // Generate real-world turn-by-turn maneuvers
    final maneuvers = generateTurnByTurnManeuvers(graph, combinedNodes);

    return DijkstraResult(
      nodes: combinedNodes,
      polylinePoints: polylinePoints,
      totalDistanceMeters: totalMeters,
      walkingTime: walkingTimeStr,
      maneuvers: maneuvers,
    );
  }
}
