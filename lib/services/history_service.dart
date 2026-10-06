import 'package:flutter/foundation.dart';
import '../models/navigation_history_item.dart';
import '../models/campus_location.dart';

class HistoryAnalytics {
  final int totalVisits;
  final double totalDistanceKm;
  final String topCategory;
  final int activeStreakDays;
  final int favoriteCount;

  const HistoryAnalytics({
    required this.totalVisits,
    required this.totalDistanceKm,
    required this.topCategory,
    required this.activeStreakDays,
    required this.favoriteCount,
  });
}

class HistoryService extends ChangeNotifier {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  static HistoryService get instance => _instance;

  HistoryService._internal() {
    _loadInitialHistory();
  }

  final List<NavigationHistoryItem> _items = [];
  bool _initialized = false;

  List<NavigationHistoryItem> get items => List.unmodifiable(_items);

  void _loadInitialHistory() {
    if (_initialized) return;
    _initialized = true;

    // Seed realistic campus history items
    final now = DateTime.now();
    _items.addAll([
      NavigationHistoryItem(
        id: 'hist_1',
        locationName: 'Central Library',
        category: 'Library',
        origin: 'My Current GPS Location',
        stops: ['Admin Block'],
        timestamp: now.subtract(const Duration(minutes: 42)),
        distance: '450 m',
        walkingTime: '~6 min',
        buildingCode: 'LIB-101',
        floorCount: 3,
        isFavorite: true,
        visitCount: 14,
        userNote: 'Quiet reading room on 2nd floor',
      ),
      NavigationHistoryItem(
        id: 'hist_2',
        locationName: 'North Campus Canteen',
        category: 'Canteen',
        origin: 'Computer Science Lab',
        stops: [],
        timestamp: now.subtract(const Duration(hours: 3, minutes: 15)),
        distance: '620 m',
        walkingTime: '~8 min',
        buildingCode: 'CNT-02',
        floorCount: 1,
        isFavorite: true,
        visitCount: 9,
        userNote: 'Best cold coffee & fresh snacks',
      ),
      NavigationHistoryItem(
        id: 'hist_3',
        locationName: 'Computer Science Block',
        category: 'Academic Block',
        origin: 'Boys Hostel 1',
        stops: ['Central Library'],
        timestamp: now.subtract(const Duration(hours: 22)),
        distance: '1.1 km',
        walkingTime: '~14 min',
        buildingCode: 'CS-302',
        floorCount: 4,
        isFavorite: false,
        visitCount: 18,
        userNote: 'MAD Lab Room #304',
      ),
      NavigationHistoryItem(
        id: 'hist_4',
        locationName: 'Main Sports Complex',
        category: 'Sports Facility',
        origin: 'My Current GPS Location',
        stops: [],
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        distance: '950 m',
        walkingTime: '~12 min',
        buildingCode: 'SPT-01',
        floorCount: 2,
        isFavorite: true,
        visitCount: 6,
        userNote: 'Badminton court booking at 5 PM',
      ),
      NavigationHistoryItem(
        id: 'hist_5',
        locationName: 'Main Auditorium',
        category: 'Hall',
        origin: 'Academic Block B',
        stops: [],
        timestamp: now.subtract(const Duration(days: 2, hours: 3)),
        distance: '800 m',
        walkingTime: '~10 min',
        buildingCode: 'AUD-01',
        floorCount: 2,
        isFavorite: false,
        visitCount: 3,
        userNote: 'Campus Tech Fest Seminar',
      ),
      NavigationHistoryItem(
        id: 'hist_6',
        locationName: 'State Bank ATM & Branch',
        category: 'ATM',
        origin: 'My Current GPS Location',
        stops: [],
        timestamp: now.subtract(const Duration(days: 3, hours: 8)),
        distance: '350 m',
        walkingTime: '~4 min',
        buildingCode: 'BNK-01',
        floorCount: 1,
        isFavorite: false,
        visitCount: 5,
        userNote: '24/7 ATM operational',
      ),
    ]);

    notifyListeners();
  }

  // Record a visited destination or navigation route
  void addHistory({
    required String locationName,
    required String category,
    String origin = 'My Current GPS Location',
    List<String> stops = const [],
    String distance = '850 m',
    String walkingTime = '~10 min',
    String buildingCode = '',
    int floorCount = 1,
    String note = '',
  }) {
    // Check if duplicate entry exists within last 5 minutes
    final recentIndex = _items.indexWhere((item) =>
        item.locationName.toLowerCase() == locationName.toLowerCase() &&
        DateTime.now().difference(item.timestamp).inMinutes < 5);

    if (recentIndex != -1) {
      final existing = _items[recentIndex];
      _items[recentIndex] = existing.copyWith(
        timestamp: DateTime.now(),
        visitCount: existing.visitCount + 1,
        origin: origin,
        stops: stops.isNotEmpty ? stops : existing.stops,
        userNote: note.isNotEmpty ? note : existing.userNote,
      );
    } else {
      // Check if location visited previously
      final prevMatch = _items.firstWhere(
        (item) => item.locationName.toLowerCase() == locationName.toLowerCase(),
        orElse: () => NavigationHistoryItem(
          id: '',
          locationName: '',
          category: '',
          timestamp: DateTime.now(),
        ),
      );

      final newItem = NavigationHistoryItem(
        id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
        locationName: locationName,
        category: category,
        origin: origin,
        stops: stops,
        timestamp: DateTime.now(),
        distance: distance,
        walkingTime: walkingTime,
        buildingCode: buildingCode,
        floorCount: floorCount,
        isFavorite: prevMatch.id.isNotEmpty ? prevMatch.isFavorite : false,
        visitCount: prevMatch.id.isNotEmpty ? prevMatch.visitCount + 1 : 1,
        userNote: note.isNotEmpty
            ? note
            : (prevMatch.id.isNotEmpty ? prevMatch.userNote : ''),
      );

      _items.insert(0, newItem);
    }

    notifyListeners();
  }

  // Record from CampusLocation object
  void addFromLocation(
    CampusLocation location, {
    String origin = 'My Current GPS Location',
    List<String> stops = const [],
  }) {
    addHistory(
      locationName: location.name,
      category: location.category,
      origin: origin,
      stops: stops,
      distance: location.distance,
      walkingTime: location.walkingTime,
      buildingCode: location.buildingCode,
      floorCount: location.floorCount,
    );
  }

  void removeHistory(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearHistory() {
    _items.clear();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      _items[index] = item.copyWith(isFavorite: !item.isFavorite);
      notifyListeners();
    }
  }

  void updateNote(String id, String note) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(userNote: note);
      notifyListeners();
    }
  }

  // Smart Search & Filter History
  List<NavigationHistoryItem> getFilteredHistory({
    String query = '',
    String category = 'All',
    bool favoritesOnly = false,
    String sortBy = 'Newest', // 'Newest', 'Most Visited', 'Distance'
  }) {
    final q = query.trim().toLowerCase();

    List<NavigationHistoryItem> result = _items.where((item) {
      final matchesFav = !favoritesOnly || item.isFavorite;

      bool matchesCat = (category == 'All');
      if (!matchesCat) {
        matchesCat = item.category.toLowerCase().contains(category.toLowerCase());
      }

      if (q.isEmpty) return matchesFav && matchesCat;

      final matchesName = item.locationName.toLowerCase().contains(q);
      final matchesCatName = item.category.toLowerCase().contains(q);
      final matchesOrigin = item.origin.toLowerCase().contains(q);
      final matchesStops = item.stops.any((s) => s.toLowerCase().contains(q));
      final matchesNote = item.userNote.toLowerCase().contains(q);
      final matchesCode = item.buildingCode.toLowerCase().contains(q);

      return matchesFav &&
          matchesCat &&
          (matchesName ||
              matchesCatName ||
              matchesOrigin ||
              matchesStops ||
              matchesNote ||
              matchesCode);
    }).toList();

    // Sort
    if (sortBy == 'Most Visited') {
      result.sort((a, b) => b.visitCount.compareTo(a.visitCount));
    } else if (sortBy == 'Distance') {
      result.sort((a, b) => _parseDistanceMeters(a.distance)
          .compareTo(_parseDistanceMeters(b.distance)));
    } else {
      // Newest first
      result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    return result;
  }

  // Get Analytics Summary
  HistoryAnalytics getAnalyticsSummary() {
    if (_items.isEmpty) {
      return const HistoryAnalytics(
        totalVisits: 0,
        totalDistanceKm: 0.0,
        topCategory: 'None',
        activeStreakDays: 0,
        favoriteCount: 0,
      );
    }

    int totalVisits = _items.fold(0, (sum, item) => sum + item.visitCount);

    double totalDistanceKm = 0.0;
    final Map<String, int> categoryCounts = {};
    int favCount = 0;

    for (final item in _items) {
      final meters = _parseDistanceMeters(item.distance);
      totalDistanceKm += (meters / 1000.0) * item.visitCount;

      categoryCounts[item.category] =
          (categoryCounts[item.category] ?? 0) + item.visitCount;

      if (item.isFavorite) favCount++;
    }

    String topCategory = 'Academic Block';
    int maxCount = 0;
    categoryCounts.forEach((cat, count) {
      if (count > maxCount) {
        maxCount = count;
        topCategory = cat;
      }
    });

    return HistoryAnalytics(
      totalVisits: totalVisits,
      totalDistanceKm: double.parse(totalDistanceKm.toStringAsFixed(1)),
      topCategory: topCategory,
      activeStreakDays: 5, // Active campus navigation streak
      favoriteCount: favCount,
    );
  }

  double _parseDistanceMeters(String distStr) {
    try {
      final clean = distStr.toLowerCase().replaceAll('~', '').trim();
      if (clean.contains('km')) {
        final val = double.tryParse(clean.replaceAll('km', '').trim()) ?? 1.0;
        return val * 1000.0;
      } else if (clean.contains('m')) {
        final val = double.tryParse(clean.replaceAll('m', '').trim()) ?? 500.0;
        return val;
      }
    } catch (_) {}
    return 500.0;
  }
}
