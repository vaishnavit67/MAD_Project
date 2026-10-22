import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigator/algorithms/campus_graph.dart';
import 'package:campus_navigator/algorithms/dijkstra_path_finding.dart';

void main() {
  test('Verify all campus POI locations are reachable from Main Gate', () {
    final graph = CampusGraph.buildAmritaCampusGraph();
    expect(graph.nodes.isNotEmpty, isTrue);

    final mainGate = graph.nodes['main_gate']!;
    int reachablePois = 0;
    int totalPois = 0;

    for (final node in graph.nodes.values) {
      if (node.isPoi && node.id != 'main_gate') {
        totalPois++;
        final path = DijkstraPathFinding.computeDijkstra(
          graph,
          mainGate.id,
          node.id,
        );
        if (path.isNotEmpty) {
          reachablePois++;
        }
      }
    }

    expect(reachablePois, equals(totalPois));
    expect(reachablePois, greaterThanOrEqualTo(50));
  });
}
