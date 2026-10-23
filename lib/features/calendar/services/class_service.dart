import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/class_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/mongodb_service.dart';

/// Service managing user-specific academic classes and timetable schedule
/// with full backend sync to MongoDB and role-isolated on-device caching.
class ClassService {
  static final ClassService _instance = ClassService._internal();
  factory ClassService() => _instance;
  ClassService._internal();

  String get _userScope =>
      AuthService.currentUser?.id ??
      AuthService.currentUser?.email.replaceAll(RegExp(r'\W'), '_') ??
      'guest_${AuthService.currentRole.toLowerCase()}';

  String get _boxName => 'classes_box_$_userScope';
  Box<Map<dynamic, dynamic>>? _box;
  final Map<String, Map<dynamic, dynamic>> _fallbackClasses = {};

  String get _baseUrl => '${MongoDbService.instance.backendUrl}/api/calendar/classes';

  Map<String, String> _headers([String? token]) {
    final effectiveToken = token ?? AuthService.effectiveToken;
    return {
      'Content-Type': 'application/json',
      if (effectiveToken.isNotEmpty) 'Authorization': 'Bearer $effectiveToken',
    };
  }

  Future<void> init() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
      // Fetch fresh classes from MongoDB backend in background
      fetchClassesFromBackend();
    } catch (e) {
      debugPrint('[ClassService] Hive init notice (using memory fallback): $e');
      fetchClassesFromBackend();
    }
  }

  /// Switch active Hive box when logged in user changes
  Future<void> switchUserScope() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
      await fetchClassesFromBackend();
    } catch (_) {}
  }

  /// Fetch classes from Node.js / MongoDB backend according to user and role
  Future<List<ClassModel>> fetchClassesFromBackend() async {
    // Visitors do not take academic classes
    if (AuthService.isVisitor) {
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl?role=${AuthService.currentRole}');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['classes'] is List) {
          final list = (data['classes'] as List).expand((raw) {
            final m = raw as Map<String, dynamic>;
            final days = m['daysOfWeek'] as List<dynamic>? ?? [1];
            final baseId = (m['_id'] ?? m['id'] ?? 'cls_${DateTime.now().millisecondsSinceEpoch}').toString();
            return days.map((d) {
              final dayInt = d is int ? d : (int.tryParse(d.toString()) ?? 1);
              return ClassModel(
                id: '${baseId}_$dayInt',
                subject: (m['title'] ?? m['subject'] ?? 'Academic Course').toString(),
                dayOfWeek: dayInt,
                startTime: (m['startTime'] ?? '09:00 AM').toString(),
                endTime: (m['endTime'] ?? '10:00 AM').toString(),
                room: (m['location'] ?? 'Room 101').toString(),
                teacher: (m['instructor'] ?? '').toString(),
                isWeekly: true,
                createdAt: m['createdAt'] != null
                    ? (DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now())
                    : DateTime.now(),
              );
            });
          }).toList();

          // Cache in local user-scoped box
          if (_box != null) {
            await _box!.clear();
            for (final cls in list) {
              await _box!.put(cls.id, cls.toMap());
            }
          } else {
            _fallbackClasses.clear();
            for (final cls in list) {
              _fallbackClasses[cls.id] = cls.toMap();
            }
          }

          return list;
        }
      }
    } catch (e) {
      debugPrint('[ClassService] Notice fetching backend classes ($e), using cached timetable.');
    }

    return getClasses();
  }

  List<ClassModel> getClasses() {
    if (AuthService.isVisitor) {
      return []; // Visitors have no academic timetable
    }
    final values = _box?.values ?? _fallbackClasses.values;
    if (values.isEmpty) {
      _seedDefaultClasses();
    }
    final effectiveValues = _box?.values ?? _fallbackClasses.values;
    final results = <ClassModel>[];
    for (final map in effectiveValues) {
      try {
        results.add(ClassModel.fromMap(map));
      } catch (e) {
        debugPrint('[ClassService] Corrupted class skipped: $e');
      }
    }
    return results;
  }

  void _seedDefaultClasses() {
    final now = DateTime.now();
    final isFaculty = AuthService.isFaculty;
    final currentUserName = AuthService.currentUser?.name ?? (isFaculty ? 'Dr. Priya Sharma' : 'Student');

    final List<ClassModel> defaultList = [];

    if (isFaculty) {
      // Teaching Schedule for Faculty
      // Mon (1), Wed (3), Fri (5)
      for (final d in [1, 3, 5]) {
        defaultList.add(ClassModel(
          id: 'seed_fac_cls_1_$d',
          subject: 'Advanced Database Systems (CS401)',
          dayOfWeek: d,
          startTime: '09:00 AM',
          endTime: '10:30 AM',
          room: 'Lab 302',
          teacher: currentUserName,
          isWeekly: true,
          createdAt: now,
        ));
      }
      // Tue (2), Thu (4)
      for (final d in [2, 4]) {
        defaultList.add(ClassModel(
          id: 'seed_fac_cls_2_$d',
          subject: 'Mobile Application Development (CS305)',
          dayOfWeek: d,
          startTime: '11:00 AM',
          endTime: '12:30 PM',
          room: 'CS Hall 104',
          teacher: currentUserName,
          isWeekly: true,
          createdAt: now,
        ));
      }
      // Consultation hours Wed (3), Fri (5)
      for (final d in [3, 5]) {
        defaultList.add(ClassModel(
          id: 'seed_fac_cls_3_$d',
          subject: 'Faculty Office Hours & Research Mentorship',
          dayOfWeek: d,
          startTime: '02:00 PM',
          endTime: '04:00 PM',
          room: 'Faculty Cabin 204',
          teacher: currentUserName,
          isWeekly: true,
          createdAt: now,
        ));
      }
    } else {
      // Student Schedule
      for (final d in [1, 3, 5]) {
        defaultList.add(ClassModel(
          id: 'seed_std_cls_1_$d',
          subject: 'Mobile App Development',
          dayOfWeek: d,
          startTime: '09:00 AM',
          endTime: '10:00 AM',
          room: 'Hall 201',
          teacher: 'Dr. Priya Sharma',
          isWeekly: true,
          createdAt: now,
        ));
      }
      for (final d in [2, 4]) {
        defaultList.add(ClassModel(
          id: 'seed_std_cls_2_$d',
          subject: 'Computer Networks',
          dayOfWeek: d,
          startTime: '11:00 AM',
          endTime: '12:30 PM',
          room: 'Lab 304',
          teacher: 'Prof. Rajesh Kumar',
          isWeekly: true,
          createdAt: now,
        ));
      }
      for (final d in [3, 5]) {
        defaultList.add(ClassModel(
          id: 'seed_std_cls_3_$d',
          subject: 'Cloud Computing & Distributed Systems',
          dayOfWeek: d,
          startTime: '02:00 PM',
          endTime: '03:30 PM',
          room: 'CS 105',
          teacher: 'Dr. Roopa',
          isWeekly: true,
          createdAt: now,
        ));
      }
    }

    for (final cls in defaultList) {
      _fallbackClasses[cls.id] = cls.toMap();
      try {
        _box?.put(cls.id, cls.toMap());
      } catch (_) {}
    }
  }

  Future<void> addClass(ClassModel cls) async {
    _fallbackClasses[cls.id] = cls.toMap();
    try {
      await _box?.put(cls.id, cls.toMap());
    } catch (_) {}

    // Sync to MongoDB backend
    try {
      final uri = Uri.parse(_baseUrl);
      await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'title': cls.subject,
          'subject': cls.subject,
          'location': cls.room,
          'instructor': cls.teacher,
          'startTime': cls.startTime,
          'endTime': cls.endTime,
          'daysOfWeek': [cls.dayOfWeek],
        }),
      );
    } catch (_) {}
  }

  Future<void> deleteClass(String id) async {
    _fallbackClasses.remove(id);
    try {
      await _box?.delete(id);
    } catch (_) {}

    // Sync deletion to MongoDB backend
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      await http.delete(uri, headers: _headers());
    } catch (_) {}
  }

  /// Returns all classes that occur on [date].
  List<ClassModel> getClassesForDate(DateTime date) {
    return getClasses().where((cls) => cls.occursOn(date)).toList();
  }
}
