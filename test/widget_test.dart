import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigator/main.dart';
import 'package:campus_navigator/screens/map_screen.dart';

void main() {
  testWidgets('CampusConnectApp smoke test', (WidgetTester tester) async {
    // Build CampusConnectApp and trigger a frame.
    await tester.pumpWidget(const CampusConnectApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(CampusConnectApp), findsOneWidget);
  });

  testWidgets('MapScreen renders and handles route arguments without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: const RouteSettings(
              name: '/map',
              arguments: {
                'name': 'AB3',
                'origin': 'Main Gate Entrance',
                'stops': <String>[],
              },
            ),
            builder: (context) => const MapScreen(),
          );
        },
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(MapScreen), findsOneWidget);
  });
}
