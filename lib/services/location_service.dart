import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campus_location.dart';
import '../utils/constants.dart';

class LocationService {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Fetch campus locations from Firestore or fallback to default constants
  Future<List<CampusLocation>> getLocations() async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snapshot = await firestore
            .collection('locations')
            .get()
            .timeout(const Duration(seconds: 3));

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            return CampusLocation.fromMap(doc.data(), doc.id);
          }).toList();
        }
      } catch (_) {
        // Fallback
      }
    }
    return campusLocations;
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
