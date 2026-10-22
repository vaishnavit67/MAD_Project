import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigator/utils/constants.dart';
import 'package:campus_navigator/algorithms/path_finding.dart';

void main() {
  group('Shortest Multi-Stop Path Tests', () {
    test('Route to Central Library starts at origin and reaches library', () {
      final library = campusLocations.firstWhere((l) => l.name == 'Central Library');
      final route = PathFinding.getRouteForDestination('Main Gate Entrance', library);

      expect(route.isNotEmpty, isTrue);
      expect(route.first.title, contains('Main Gate'));
      expect(route.last.title, contains('Library'));
    });
  });
}
