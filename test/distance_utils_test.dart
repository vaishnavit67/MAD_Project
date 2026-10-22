import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:campus_navigator/utils/constants.dart';

void main() {
  group('Campus Geodesic Distance Calculations Tests', () {
    test('Distance between Main Gate and Central Fountain is roughly 250 - 350 meters', () {
      const p1 = LatLng(amritaMainGateLat, amritaMainGateLng);
      const p2 = LatLng(10.90220, 76.90150);
      const distance = Distance();
      final meters = distance.as(LengthUnit.Meter, p1, p2);

      expect(meters, greaterThan(200));
      expect(meters, lessThan(400));
    });

    test('Distance between Main Gate and AB1 is within realistic pedestrian bounds', () {
      final ab1 = campusLocations.firstWhere((l) => l.name == 'AB1');
      const p1 = LatLng(amritaMainGateLat, amritaMainGateLng);
      final p2 = LatLng(ab1.latitude!, ab1.longitude!);
      const distance = Distance();
      final meters = distance.as(LengthUnit.Meter, p1, p2);

      expect(meters, greaterThan(180));
      expect(meters, lessThan(450));
    });
  });
}
