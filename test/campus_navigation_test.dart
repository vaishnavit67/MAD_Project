import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigator/utils/constants.dart';
import 'package:campus_navigator/algorithms/campus_graph.dart';
import 'package:campus_navigator/algorithms/dijkstra_path_finding.dart';
import 'package:campus_navigator/services/map_config_service.dart';

void main() {
  group('Amrita Vishwa Vidyapeetham Campus Coordinates & Anchors Tests', () {
    test('Campus center and main gate coordinates are accurate Ettimadai anchors', () {
      expect(amritaCampusCenterLat, closeTo(10.9036, 0.005));
      expect(amritaCampusCenterLng, closeTo(76.8997, 0.005));
      expect(amritaMainGateLat, closeTo(10.9002, 0.005));
      expect(amritaMainGateLng, closeTo(76.9031, 0.005));
    });

    test('All campus locations have valid Amrita geographic coordinates within campus boundary', () {
      for (final loc in campusLocations) {
        expect(loc.latitude, isNotNull, reason: '${loc.name} must have latitude');
        expect(loc.longitude, isNotNull, reason: '${loc.name} must have longitude');

        // Check bounds within Amrita Ettimadai perimeter (approx 10.895 - 10.912 N, 76.890 - 76.910 E)
        expect(loc.latitude!, greaterThanOrEqualTo(10.895), reason: '${loc.name} lat >= 10.895');
        expect(loc.latitude!, lessThanOrEqualTo(10.912), reason: '${loc.name} lat <= 10.912');
        expect(loc.longitude!, greaterThanOrEqualTo(76.890), reason: '${loc.name} lng >= 76.890');
        expect(loc.longitude!, lessThanOrEqualTo(76.910), reason: '${loc.name} lng <= 76.910');
      }
    });

    test('All checkpoint nodes contain non-null geographic coordinates', () {
      for (final loc in campusLocations) {
        for (final cp in loc.checkpoints) {
          expect(cp.latitude, isNotNull, reason: '${loc.name} -> ${cp.title} lat');
          expect(cp.longitude, isNotNull, reason: '${loc.name} -> ${cp.title} lng');
        }
      }
    });
  });

  group('Campus Road Network & Dijkstra Shortest Path Tests', () {
    test('CampusGraph has nodes and bidirectional road edges connected', () {
      final graph = CampusGraph.buildAmritaCampusGraph();
      expect(graph.nodes.length, greaterThanOrEqualTo(35));
      expect(graph.nodes.containsKey('main_gate'), isTrue);
      expect(graph.nodes.containsKey('ab1'), isTrue);
      expect(graph.nodes.containsKey('central_library'), isTrue);

      final mainGateEdges = graph.adjacencyList['main_gate'];
      expect(mainGateEdges, isNotNull);
      expect(mainGateEdges!.isNotEmpty, isTrue);
    });

    test("Dijkstra's Algorithm finds valid shortest path from Main Gate to Central Library", () {
      final graph = CampusGraph.buildAmritaCampusGraph();
      final path = DijkstraPathFinding.computeDijkstra(graph, 'main_gate', 'central_library');

      expect(path.isNotEmpty, isTrue);
      expect(path.first.id, equals('main_gate'));
      expect(path.last.id, equals('central_library'));
      expect(path.length, greaterThanOrEqualTo(3));
    });

    test('Dijkstra produces real-world turn-by-turn maneuvers with road names', () {
      final graph = CampusGraph.buildAmritaCampusGraph();
      final result = DijkstraPathFinding.findMultiStopRoute(
        graph: graph,
        startLocationQuery: 'Main Gate Entrance',
        intermediateStopQueries: const [],
        destinationQuery: 'AB1',
      );

      expect(result.nodes.isNotEmpty, isTrue);
      expect(result.totalDistanceMeters, greaterThan(200));
      expect(result.maneuvers.isNotEmpty, isTrue);

      // Verify maneuvers have real road instructions and valid coordinates
      for (final m in result.maneuvers) {
        expect(m.instruction, isNotEmpty);
        expect(m.roadName, isNotEmpty);
        expect(m.point.latitude, greaterThan(10.89));
        expect(m.point.longitude, greaterThan(76.89));
      }
    });

    test('Dijkstra multi-stop route passes through requested intermediate stop', () {
      final graph = CampusGraph.buildAmritaCampusGraph();
      final result = DijkstraPathFinding.findMultiStopRoute(
        graph: graph,
        startLocationQuery: 'Main Gate Entrance',
        intermediateStopQueries: ['Main Canteen'],
        destinationQuery: 'Central Library',
      );

      expect(result.nodes.any((n) => n.id == 'main_canteen'), isTrue);
      expect(result.nodes.first.id, equals('main_gate'));
      expect(result.nodes.last.id, equals('central_library'));
    });

    test('CampusGraph.getAllRoadPolylines extracts road segments with valid coordinates', () {
      final graph = CampusGraph.buildAmritaCampusGraph();
      final polylines = graph.getAllRoadPolylines();
      expect(polylines.length, greaterThanOrEqualTo(25));

      for (final segment in polylines) {
        expect(segment.length, equals(2));
        for (final pt in segment) {
          expect(pt.latitude, greaterThan(10.89));
          expect(pt.latitude, lessThan(10.92));
          expect(pt.longitude, greaterThan(76.89));
          expect(pt.longitude, lessThan(76.92));
        }
      }
    });

    test('Every campus location in campusLocations resolves to a valid node in CampusGraph', () {
      final graph = CampusGraph.buildAmritaCampusGraph();
      for (final loc in campusLocations) {
        final node = graph.findNodeByName(loc.name);
        expect(node, isNotNull, reason: 'Failed to resolve graph node for "${loc.name}"');
        expect(node!.latitude, isNotNull);
        expect(node.longitude, isNotNull);
      }
    });
  });

  group('MapConfigService & API Key Architecture Tests', () {
    test('MapConfigService initializes with default styles and CORS-safe ESRI Satellite', () {
      final service = MapConfigService.instance;
      expect(service.availableStyles.isNotEmpty, isTrue);
      expect(service.currentStyle.id, equals('esri_imagery'));
      expect(service.currentStyle.urlTemplate.contains('arcgisonline.com'), isTrue);
      expect(service.currentStyle.isCorsSafe, isTrue);
    });

    test('MapConfigService handles custom API key injection and template substitution', () {
      final service = MapConfigService.instance;
      service.setApiKey('TEST_MOCK_API_KEY_12345');
      expect(service.hasCustomApiKey, isTrue);
      expect(service.apiKey, equals('TEST_MOCK_API_KEY_12345'));

      // Find Google Maps style
      final googleStyle = service.availableStyles.firstWhere(
        (s) => s.provider == MapProvider.googleMaps,
      );
      final resolvedGoogleUrl = service.getEffectiveTileUrl(googleStyle);
      expect(resolvedGoogleUrl.contains('TEST_MOCK_API_KEY_12345'), isTrue);
      expect(resolvedGoogleUrl.contains('&key=TEST_MOCK_API_KEY_12345'), isTrue);

      // Find MapTiler style
      final maptilerStyle = service.availableStyles.firstWhere(
        (s) => s.provider == MapProvider.mapTiler,
      );
      final resolvedMaptilerUrl = service.getEffectiveTileUrl(maptilerStyle);
      expect(resolvedMaptilerUrl.contains('TEST_MOCK_API_KEY_12345'), isTrue);

      // Clean up
      service.resetToDefaultKey();
      expect(service.hasCustomApiKey, isFalse);
    });

    test('MapConfigService correctly toggles between available styles', () {
      final service = MapConfigService.instance;
      final initialIndex = service.selectedStyleIndex;
      service.selectStyle(1);
      expect(service.selectedStyleIndex, equals(1));
      expect(service.currentStyle.id, equals(service.availableStyles[1].id));

      // Reset back
      service.selectStyle(initialIndex);
      expect(service.selectedStyleIndex, equals(initialIndex));
    });
  });

  group('Pedestrian Road Network & Authentic Shortcut Routing Tests', () {
    test('Dijkstra route from AB1 to Central Library walks along authentic roads without air diagonals', () {
      final graph = CampusGraph.buildAmritaCampusGraph();
      final result = DijkstraPathFinding.findMultiStopRoute(
        graph: graph,
        startLocationQuery: 'AB1',
        intermediateStopQueries: const [],
        destinationQuery: 'Central Library',
      );

      final nodeIds = result.nodes.map((n) => n.id).toList();
      // Ensure the path traverses real road and corridor junctions
      expect(nodeIds.first, equals('ab1'));
      expect(nodeIds.last, equals('central_library'));
      expect(nodeIds.length, greaterThanOrEqualTo(6));

      // Must NOT contain direct air diagonal jump from ab1 to central_circle
      for (int i = 0; i < nodeIds.length - 1; i++) {
        expect(
          nodeIds[i] == 'ab1' && nodeIds[i + 1] == 'central_circle',
          isFalse,
          reason: 'Route must not cut diagonally across campus from AB1 to Central Circle',
        );
      }

      // Validates realistic pedestrian walking distance (approx 450 - 900m via real roads)
      expect(result.totalDistanceMeters, greaterThanOrEqualTo(400));
      expect(result.totalDistanceMeters, lessThanOrEqualTo(900));
    });

    test('Dijkstra route from Main Gate to Central Library hugs the Central Boulevard', () {
      final graph = CampusGraph.buildAmritaCampusGraph();
      final result = DijkstraPathFinding.findMultiStopRoute(
        graph: graph,
        startLocationQuery: 'Main Gate Entrance',
        intermediateStopQueries: const [],
        destinationQuery: 'Central Library',
      );

      final nodeIds = result.nodes.map((n) => n.id).toList();
      expect(nodeIds.first, equals('main_gate'));
      expect(nodeIds.last, equals('central_library'));
      expect(nodeIds.contains('bank_junc'), isTrue);
      expect(nodeIds.contains('central_circle'), isTrue);
      expect(nodeIds.length, greaterThanOrEqualTo(8));
    });

    test('Pedestrian shortcuts like AB1 corridor and Library garden walk are flagged in maneuvers', () {
      final graph = CampusGraph.buildAmritaCampusGraph();
      final result = DijkstraPathFinding.findMultiStopRoute(
        graph: graph,
        startLocationQuery: 'AB1',
        intermediateStopQueries: const [],
        destinationQuery: 'Central Library',
      );

      // Verify that at least one maneuver utilizes a campus corridor or paved shortcut
      final hasShortcut = result.maneuvers.any((m) => m.isShortcut);
      expect(hasShortcut, isTrue, reason: 'Route should utilize authentic campus shortcuts or covered corridors');
    });
  });
}
