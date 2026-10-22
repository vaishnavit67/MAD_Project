import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/campus_location.dart';
import '../utils/constants.dart';
import 'mongodb_service.dart';

enum LocationPermissionStatus {
  granted,
  serviceDisabled,
  denied,
  deniedForever,
  error,
}

class LocationService {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Check detailed location permission and service status
  Future<LocationPermissionStatus> checkLocationPermissionStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationPermissionStatus.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionStatus.deniedForever;
      }

      return LocationPermissionStatus.granted;
    } catch (_) {
      return LocationPermissionStatus.error;
    }
  }

  /// Open device system location settings (to turn GPS toggle ON)
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Open application settings (for permanently denied permissions)
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Request device location permissions (legacy boolean helper)
  Future<bool> handleLocationPermission() async {
    final status = await checkLocationPermissionStatus();
    return status == LocationPermissionStatus.granted;
  }

  /// Get current device GPS position with cached instant fix + fused location
  Future<Position?> getCurrentDevicePosition() async {
    try {
      final status = await checkLocationPermissionStatus();
      if (status != LocationPermissionStatus.granted) return null;

      // 1. Instant cached position from Android OS (< 50ms)
      Position? cachedPosition;
      try {
        cachedPosition = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // 2. Fresh high-accuracy fix via Google Play Services Fused Location Provider
      try {
        final freshPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        return freshPosition;
      } catch (_) {
        // If fresh lock timed out or failed, fallback to cached location
        if (cachedPosition != null) {
          return cachedPosition;
        }
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Real-time live GPS stream using high accuracy fused location provider
  Stream<Position>? getLivePositionStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Responsive updates every 1 meter
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Calculate real distance between two GPS coordinates in meters
  double calculateDistanceMeters(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculate initial bearing between two coordinates in degrees
  double calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  // Fetch campus locations from Backend REST API (MongoDB) or fallback to default constants
  Future<List<CampusLocation>> getLocations() async {
    // 1. Try fetching from Node.js Express & MongoDB backend
    try {
      final backendUrl = MongoDbService.instance.backendUrl;
      final uri = Uri.parse('$backendUrl/api/locations');
      final response = await http.get(uri).timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList = data['locations'] as List<dynamic>?;
        if (rawList != null && rawList.isNotEmpty) {
          return rawList.map((item) {
            final map = item as Map<String, dynamic>;
            return CampusLocation.fromMap(map, map['id']?.toString() ?? '');
          }).toList();
        }
      }
    } catch (_) {
      // Backend not running or timeout; fallback
    }

    // 2. Direct Firestore fallback (legacy)
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snapshot = await firestore
            .collection('locations')
            .get()
            .timeout(const Duration(seconds: 2));

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            return CampusLocation.fromMap(doc.data(), doc.id);
          }).toList();
        }
      } catch (_) {}
    }

    // 3. Constant fallback
    return campusLocations;
  }

  /// Add a new campus location to MongoDB via backend REST API
  Future<bool> addLocation(CampusLocation location) async {
    try {
      final backendUrl = MongoDbService.instance.backendUrl;
      final uri = Uri.parse('$backendUrl/api/locations');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(location.toMap()),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // Filter locations with smart alias and keyword matching
  List<CampusLocation> filterLocations({
    required List<CampusLocation> locations,
    String query = '',
    String category = 'All',
  }) {
    final cleanQuery = query.trim().toLowerCase();

    return locations.where((loc) {
      // Flexible Category Filtering
      bool matchesCategory = (category == 'All');
      if (!matchesCategory) {
        final catLower = category.toLowerCase();
        final locCatLower = loc.category.toLowerCase();

        if (catLower.contains('food') || catLower.contains('canteen')) {
          matchesCategory = locCatLower.contains('canteen') || locCatLower.contains('cafe');
        } else if (catLower.contains('academic')) {
          matchesCategory = locCatLower.contains('academic') || locCatLower.contains('library');
        } else if (catLower.contains('hostel')) {
          matchesCategory = locCatLower.contains('hostel');
        } else if (catLower.contains('atm') || catLower.contains('bank') || catLower.contains('cash')) {
          matchesCategory = locCatLower.contains('atm') || locCatLower.contains('bank');
        } else if (catLower.contains('sports')) {
          matchesCategory = locCatLower.contains('sports');
        } else {
          matchesCategory = locCatLower == catLower;
        }
      }

      if (cleanQuery.isEmpty) return matchesCategory;

      final matchesName = loc.name.toLowerCase().contains(cleanQuery);
      final matchesCategoryName = loc.category.toLowerCase().contains(cleanQuery);
      final matchesBuildingCode = loc.buildingCode.toLowerCase().contains(cleanQuery);
      final matchesKeywords = loc.keywords.any((kw) => kw.toLowerCase().contains(cleanQuery));

      // Smart synonym alias maps
      bool matchesAlias = false;
      if (cleanQuery.contains('food') ||
          cleanQuery.contains('eat') ||
          cleanQuery.contains('hungry') ||
          cleanQuery.contains('lunch') ||
          cleanQuery.contains('dinner') ||
          cleanQuery.contains('breakfast') ||
          cleanQuery.contains('coffee') ||
          cleanQuery.contains('snack') ||
          cleanQuery.contains('tea')) {
        matchesAlias = loc.category == 'Canteen' || loc.category == 'Cafe';
      } else if (cleanQuery.contains('academic') ||
          cleanQuery.contains('study') ||
          cleanQuery.contains('class') ||
          cleanQuery.contains('lecture') ||
          cleanQuery.contains('book') ||
          cleanQuery.contains('library')) {
        matchesAlias = loc.category == 'Academic Block' || loc.category == 'Library';
      } else if (cleanQuery.contains('cash') ||
          cleanQuery.contains('money') ||
          cleanQuery.contains('bank') ||
          cleanQuery.contains('atm') ||
          cleanQuery.contains('pay') ||
          cleanQuery.contains('withdraw')) {
        matchesAlias = loc.category == 'ATM' || loc.category == 'Bank';
      } else if (cleanQuery.contains('stay') ||
          cleanQuery.contains('hostel') ||
          cleanQuery.contains('room') ||
          cleanQuery.contains('bhavanam') ||
          cleanQuery.contains('residence')) {
        matchesAlias = loc.category == 'Girls Hostel' || loc.category == 'Boys Hostel';
      } else if (cleanQuery.contains('play') ||
          cleanQuery.contains('sports') ||
          cleanQuery.contains('game') ||
          cleanQuery.contains('gym') ||
          cleanQuery.contains('swim')) {
        matchesAlias = loc.category == 'Sports Ground' || loc.category == 'Sports Facility';
      } else if (cleanQuery.contains('health') ||
          cleanQuery.contains('doctor') ||
          cleanQuery.contains('clinic') ||
          cleanQuery.contains('medicine')) {
        matchesAlias = loc.category == 'Medical Facility';
      } else if (cleanQuery.contains('lab') ||
          cleanQuery.contains('workshop') ||
          cleanQuery.contains('mechanical') ||
          cleanQuery.contains('electrical')) {
        matchesAlias = loc.category == 'Laboratory';
      }

      return matchesCategory &&
          (matchesName || matchesCategoryName || matchesBuildingCode || matchesKeywords || matchesAlias);
    }).toList();
  }
}
