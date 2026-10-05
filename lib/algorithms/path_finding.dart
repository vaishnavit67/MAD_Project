import '../models/campus_location.dart';
import '../models/checkpoint.dart';
import '../utils/constants.dart';

class PathFinding {
  /// Known start points preset coordinates
  static Checkpoint _getOriginCheckpoint(String startName) {
    final lower = startName.toLowerCase();
    if (lower.contains('fountain')) {
      return const Checkpoint(
        label: '1',
        title: 'Central Fountain',
        instruction: 'Start navigation from Central Fountain Plaza.',
        dx: -0.50,
        dy: 0.35,
      );
    } else if (lower.contains('ab1')) {
      return const Checkpoint(
        label: '1',
        title: 'AB1 Portico',
        instruction: 'Start navigation from AB1 Portico steps.',
        dx: -0.40,
        dy: -0.35,
      );
    } else if (lower.contains('canteen')) {
      return const Checkpoint(
        label: '1',
        title: 'Main Canteen Plaza',
        instruction: 'Start navigation from Main Canteen Plaza.',
        dx: -0.45,
        dy: 0.35,
      );
    } else if (lower.contains('library')) {
      return const Checkpoint(
        label: '1',
        title: 'Library Quad',
        instruction: 'Start navigation from Library Quad.',
        dx: 0.15,
        dy: -0.70,
      );
    }

    // Try finding matching campus location
    try {
      final loc = campusLocations.firstWhere((l) => l.name.toLowerCase() == lower);
      if (loc.checkpoints.isNotEmpty) {
        final firstCp = loc.checkpoints.first;
        return Checkpoint(
          label: '1',
          title: loc.name,
          instruction: 'Start navigation from ${loc.name}.',
          dx: firstCp.dx,
          dy: firstCp.dy,
        );
      }
    } catch (_) {}

    // Default: Campus Main Entrance
    return const Checkpoint(
      label: '1',
      title: 'Main Gate Entrance',
      instruction: 'Start navigation from Campus Main Entrance Archway.',
      dx: -0.80,
      dy: 0.70,
    );
  }

  /// Generates dynamic multi-stop route checkpoints for any Start, Intermediate Stops, and Destination
  static List<Checkpoint> getMultiStopRoute({
    required String startLocation,
    required List<String> stops,
    required CampusLocation destination,
  }) {
    final List<Checkpoint> route = [];

    // 1. Origin Checkpoint
    final originCp = _getOriginCheckpoint(startLocation);
    route.add(originCp);

    // 2. Intermediate Stops
    if (stops.isNotEmpty) {
      for (int i = 0; i < stops.length; i++) {
        final stopName = stops[i];
        Checkpoint? stopCp;
        try {
          final matchedLoc = campusLocations.firstWhere(
            (l) => l.name.toLowerCase() == stopName.toLowerCase(),
          );
          if (matchedLoc.checkpoints.isNotEmpty) {
            stopCp = matchedLoc.checkpoints.last;
          }
        } catch (_) {}

        final double dx = stopCp?.dx ?? (-0.40 + i * 0.30);
        final double dy = stopCp?.dy ?? (0.20 - i * 0.25);

        route.add(Checkpoint(
          label: 'S${i + 1}',
          title: 'Stop ${i + 1}: $stopName',
          instruction: 'Proceed to intermediate stop at $stopName.',
          dx: dx,
          dy: dy,
          isStop: true,
        ));
      }
    }

    // 3. Destination Checkpoints
    if (destination.checkpoints.isNotEmpty) {
      final destCps = destination.checkpoints;
      // Append destination's checkpoints starting from index 1 (or 0 if start is different)
      final startIndex = destCps.length > 1 ? 1 : 0;
      for (int i = startIndex; i < destCps.length; i++) {
        final cp = destCps[i];
        final isLast = (i == destCps.length - 1);
        route.add(Checkpoint(
          label: isLast ? '🏁' : '${route.length + 1}',
          title: cp.title,
          instruction: cp.instruction,
          dx: cp.dx,
          dy: cp.dy,
          isStop: false,
        ));
      }
    } else {
      // Fallback destination points
      route.add(Checkpoint(
        label: '${route.length + 1}',
        title: '${destination.name} Walkway',
        instruction: 'Walk towards ${destination.name} main courtyard.',
        dx: 0.20,
        dy: -0.30,
      ));
      route.add(Checkpoint(
        label: '🏁',
        title: destination.name,
        instruction: 'Arrive at ${destination.name}.',
        dx: 0.70,
        dy: -0.65,
      ));
    }

    // Standardize labels sequentially
    int stepNum = 1;
    final List<Checkpoint> finalRoute = [];
    for (int i = 0; i < route.length; i++) {
      final cp = route[i];
      if (i == 0) {
        finalRoute.add(Checkpoint(
          label: '1',
          title: cp.title,
          instruction: cp.instruction,
          dx: cp.dx,
          dy: cp.dy,
          isStop: false,
        ));
        stepNum++;
      } else if (i == route.length - 1) {
        finalRoute.add(Checkpoint(
          label: '🏁',
          title: cp.title,
          instruction: cp.instruction,
          dx: cp.dx,
          dy: cp.dy,
          isStop: false,
        ));
      } else if (cp.isStop) {
        finalRoute.add(cp);
      } else {
        finalRoute.add(Checkpoint(
          label: '$stepNum',
          title: cp.title,
          instruction: cp.instruction,
          dx: cp.dx,
          dy: cp.dy,
          isStop: false,
        ));
        stepNum++;
      }
    }

    return finalRoute;
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
