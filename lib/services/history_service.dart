import 'package:hive/hive.dart';
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
  HistoryService._internal();

  static const String _boxName = 'navigation_history_box';
  static const String _seededKey = '_history_seeded_v1';
  Box<Map<dynamic, dynamic>>? _box;
  final Map<String, Map<dynamic, dynamic>> _fallbackMemory = {};

  Future<void> init() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
      await _seedIfNeeded();
    } catch (e) {
      debugPrint('[HistoryService] Hive init notice (using memory fallback): $e');
      await _seedIfNeeded();
    }
  }

  Future<void> _putRecord(String id, Map<dynamic, dynamic> map) async {
    _fallbackMemory[id] = map;
    try {
      await _box?.put(id, map);
    } catch (_) {}
  }

  Map<dynamic, dynamic>? _getRecord(String id) {
    try {
      return _box?.get(id) ?? _fallbackMemory[id];
    } catch (_) {
      return _fallbackMemory[id];
    }
  }

  Future<void> _deleteRecord(String id) async {
    _fallbackMemory.remove(id);
    try {
      await _box?.delete(id);
    } catch (_) {}
  }

  List<NavigationHistoryItem> get items {
    final values = _box?.values ?? _fallbackMemory.values;
    return values
        .where((m) => m.containsKey('id') && m['id'] != _seededKey)
        .map((m) => NavigationHistoryItem.fromMap(m))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // addHistory: Check for duplicates within 5 min, increment visitCount for same location
  Future<void> addHistory({
    required String locationName,
    required String category,
    String origin = 'My Current GPS Location',
    List<String> stops = const [],
    String distance = '850 m',
    String walkingTime = '~10 min',
    String buildingCode = '',
    int floorCount = 1,
    String note = '',
  }) async {
    // Check recent duplicate
    final allItems = items;
    final recentIdx = allItems.indexWhere((item) =>
        item.locationName.toLowerCase() == locationName.toLowerCase() &&
        DateTime.now().difference(item.timestamp).inMinutes < 5);

    if (recentIdx != -1) {
      final existing = allItems[recentIdx];
      final updated = existing.copyWith(
        timestamp: DateTime.now(),
        visitCount: existing.visitCount + 1,
        origin: origin,
        stops: stops.isNotEmpty ? stops : null,
        userNote: note.isNotEmpty ? note : null,
      );
      await _putRecord(existing.id, updated.toMap());
      return;
    }

    // Check previous visits to same location
    final prevMatch = allItems.where(
      (item) => item.locationName.toLowerCase() == locationName.toLowerCase(),
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
      isFavorite: prevMatch.isNotEmpty ? prevMatch.first.isFavorite : false,
      visitCount: prevMatch.isNotEmpty ? prevMatch.first.visitCount + 1 : 1,
      userNote: note.isNotEmpty ? note : (prevMatch.isNotEmpty ? prevMatch.first.userNote : ''),
    );
    await _putRecord(newItem.id, newItem.toMap());
  }

  Future<void> addFromLocation(
    CampusLocation location, {
    String origin = 'My Current GPS Location',
    List<String> stops = const [],
  }) async {
    await addHistory(
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

  Future<void> removeHistory(String id) async {
    await _deleteRecord(id);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final seeded = _getRecord(_seededKey);
    _fallbackMemory.clear();
    try {
      await _box?.clear();
    } catch (_) {}
    notifyListeners();
    if (seeded != null) await _putRecord(_seededKey, seeded);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final raw = _getRecord(id);
    if (raw == null) return;
    final item = NavigationHistoryItem.fromMap(raw);
    await _putRecord(id, item.copyWith(isFavorite: !item.isFavorite).toMap());
  }

  Future<void> updateNote(String id, String note) async {
    final raw = _getRecord(id);
    if (raw == null) return;
    final item = NavigationHistoryItem.fromMap(raw);
    await _putRecord(id, item.copyWith(userNote: note).toMap());
  }

  List<NavigationHistoryItem> getFilteredHistory({
    String query = '',
    String category = 'All',
    bool favoritesOnly = false,
    String sortBy = 'Newest',
  }) {
    final q = query.trim().toLowerCase();
    var result = items.where((item) {
      if (favoritesOnly && !item.isFavorite) return false;
      if (category != 'All' && !item.category.toLowerCase().contains(category.toLowerCase())) return false;
      if (q.isEmpty) return true;
      return item.locationName.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.origin.toLowerCase().contains(q) ||
          item.stops.any((s) => s.toLowerCase().contains(q)) ||
          item.userNote.toLowerCase().contains(q) ||
          item.buildingCode.toLowerCase().contains(q);
    }).toList();

    if (sortBy == 'Most Visited') {
      result.sort((a, b) => b.visitCount.compareTo(a.visitCount));
    } else if (sortBy == 'Distance') {
      result.sort((a, b) => _parseDistanceMeters(a.distance).compareTo(_parseDistanceMeters(b.distance)));
    } else {
      result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return result;
  }

  HistoryAnalytics getAnalyticsSummary() {
    final all = items;
    if (all.isEmpty) {
      return const HistoryAnalytics(
        totalVisits: 0,
        totalDistanceKm: 0.0,
        topCategory: 'None',
        activeStreakDays: 0,
        favoriteCount: 0,
      );
    }
    int totalVisits = all.fold(0, (sum, i) => sum + i.visitCount);
    double totalDist = 0;
    final catCounts = <String, int>{};
    int favCount = 0;
    for (final item in all) {
      totalDist += (_parseDistanceMeters(item.distance) / 1000.0) * item.visitCount;
      catCounts[item.category] = (catCounts[item.category] ?? 0) + item.visitCount;
      if (item.isFavorite) favCount++;
    }
    String topCat = 'None';
    int maxC = 0;
    catCounts.forEach((c, n) {
      if (n > maxC) {
        maxC = n;
        topCat = c;
      }
    });
    return HistoryAnalytics(
      totalVisits: totalVisits,
      totalDistanceKm: double.parse(totalDist.toStringAsFixed(1)),
      topCategory: topCat,
      activeStreakDays: 5,
      favoriteCount: favCount,
    );
  }

  double _parseDistanceMeters(String d) {
    try {
      final c = d.toLowerCase().replaceAll('~', '').trim();
      if (c.contains('km')) return (double.tryParse(c.replaceAll('km', '').trim()) ?? 1.0) * 1000;
      if (c.contains('m')) return double.tryParse(c.replaceAll('m', '').trim()) ?? 500;
    } catch (_) {}
    return 500;
  }

  Future<void> _seedIfNeeded() async {
    if (_getRecord(_seededKey) != null) return;
    final now = DateTime.now();
    final seeds = [
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
        visitCount: 5,
        userNote: '24/7 ATM operational',
      ),
    ];
    for (final s in seeds) {
      await _putRecord(s.id, s.toMap());
    }
    await _putRecord(_seededKey, {'seeded': true});
    notifyListeners();
  }
}
