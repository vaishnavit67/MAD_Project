import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/mongodb_service.dart';

/// In-app notification inbox backed by MongoDB Atlas with role-specific
/// user-isolated caching in Hive.
class InAppNotificationService {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  String get _userScope =>
      AuthService.currentUser?.id ??
      AuthService.currentUser?.email.replaceAll(RegExp(r'\W'), '_') ??
      'guest_${AuthService.currentRole.toLowerCase()}';

  String get _boxName => 'notifications_box_$_userScope';
  Box<Map<dynamic, dynamic>>? _box;
  final Map<String, Map<dynamic, dynamic>> _fallbackMemory = {};

  String get _baseUrl => '${MongoDbService.instance.backendUrl}/api/notifications';

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
      fetchNotificationsFromBackend();
    } catch (e) {
      debugPrint('[InAppNotificationService] Hive init notice: $e');
      fetchNotificationsFromBackend();
    }
  }

  /// Switch active Hive box when logged in user changes
  Future<void> switchUserScope() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
      await fetchNotificationsFromBackend();
    } catch (_) {}
  }

  /// Fetch user-specific and role-tailored notifications from MongoDB backend
  Future<List<NotificationModel>> fetchNotificationsFromBackend() async {
    try {
      final role = AuthService.currentRole;
      final uri = Uri.parse('$_baseUrl?role=$role');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['notifications'] is List) {
          final list = (data['notifications'] as List).map((raw) {
            final m = raw as Map<String, dynamic>;
            final rawDate = m['createdAt'] ?? m['timestamp'];
            DateTime ts;
            if (rawDate != null) {
              ts = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
            } else {
              ts = DateTime.now();
            }

            final userId = AuthService.currentUser?.id ?? AuthService.currentUser?.email;
            bool readStatus = m['isRead'] == true;
            if (userId != null && m['readBy'] is List) {
              if ((m['readBy'] as List).contains(userId)) {
                readStatus = true;
              }
            }

            return NotificationModel(
              id: (m['_id'] ?? m['id'] ?? 'notif_${DateTime.now().millisecondsSinceEpoch}').toString(),
              title: (m['title'] ?? 'Campus Notification').toString(),
              message: (m['message'] ?? '').toString(),
              timestamp: ts,
              type: (m['type'] ?? 'system').toString(),
              isRead: readStatus,
              relatedEventId: m['relatedEventId']?.toString(),
              relatedTaskId: m['relatedTaskId']?.toString(),
            );
          }).toList();

          // Cache in local user-scoped box
          if (_box != null) {
            await _box!.clear();
            for (final n in list) {
              await _box!.put(n.id, n.toMap());
            }
          } else {
            _fallbackMemory.clear();
            for (final n in list) {
              _fallbackMemory[n.id] = n.toMap();
            }
          }

          return list;
        }
      }
    } catch (e) {
      debugPrint('[InAppNotificationService] Notice fetching backend notifications ($e), using local store.');
    }

    final local = getNotifications();
    if (local.isEmpty) {
      await _seedRoleSpecificFallback();
      return getNotifications();
    }
    return local;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all notifications sorted newest-first.
  List<NotificationModel> getNotifications() {
    final values = _box?.values ?? _fallbackMemory.values;
    final items = values
        .where((m) => m.containsKey('id'))
        .map((m) => NotificationModel.fromMap(m))
        .toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  int get unreadCount =>
      getNotifications().where((n) => !n.isRead).length;

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> addNotification(NotificationModel n) async {
    _fallbackMemory[n.id] = n.toMap();
    try {
      await _box?.put(n.id, n.toMap());
    } catch (_) {}

    // Post to MongoDB backend
    try {
      final uri = Uri.parse(_baseUrl);
      await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'recipientId': AuthService.currentUser?.id ?? AuthService.currentUser?.email ?? 'all',
          'recipientRole': AuthService.currentRole,
          'title': n.title,
          'message': n.message,
          'type': n.type,
          'relatedEventId': n.relatedEventId,
          'relatedTaskId': n.relatedTaskId,
        }),
      );
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final raw = _box?.get(id) ?? _fallbackMemory[id];
    if (raw != null) {
      final n = NotificationModel.fromMap(raw);
      final updated = n.copyWith(isRead: true).toMap();
      _fallbackMemory[id] = updated;
      try {
        await _box?.put(id, updated);
      } catch (_) {}
    }

    // Sync to backend
    try {
      final uri = Uri.parse('$_baseUrl/$id/read');
      await http.patch(uri, headers: _headers());
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final values = _box?.values ?? _fallbackMemory.values;
    for (final raw in values.toList()) {
      if (!raw.containsKey('id')) continue;
      final n = NotificationModel.fromMap(raw);
      if (!n.isRead) {
        final updated = n.copyWith(isRead: true).toMap();
        _fallbackMemory[n.id] = updated;
        try {
          await _box?.put(n.id, updated);
        } catch (_) {}
      }
    }

    // Sync to backend
    try {
      final uri = Uri.parse('$_baseUrl/read-all');
      await http.patch(uri, headers: _headers());
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    _fallbackMemory.remove(id);
    try {
      await _box?.delete(id);
    } catch (_) {}

    // Sync to backend
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      await http.delete(uri, headers: _headers());
    } catch (_) {}
  }

  Future<void> clearNotifications() async {
    _fallbackMemory.clear();
    try {
      await _box?.clear();
    } catch (_) {}
  }

  // ── Role-Specific Offline Fallback Seeds ────────────────────────────────────

  Future<void> _seedRoleSpecificFallback() async {
    final now = DateTime.now();
    final isFaculty = AuthService.isFaculty;
    final isVisitor = AuthService.isVisitor;

    List<NotificationModel> seeds;

    if (isFaculty) {
      seeds = [
        NotificationModel(
          id: 'faculty_notif_1',
          title: 'Club Join Request 👥',
          message: 'A student requested to join your club. Review and approve in Clubs tab.',
          timestamp: now.subtract(const Duration(minutes: 25)),
          type: 'club',
        ),
        NotificationModel(
          id: 'faculty_notif_2',
          title: 'Teaching Lecture Reminder 📚',
          message: 'CS301 Advanced Operating Systems starts at 10:00 AM at Hall 102.',
          timestamp: now.subtract(const Duration(hours: 1)),
          type: 'class',
        ),
        NotificationModel(
          id: 'faculty_notif_3',
          title: 'Faculty Council Notice 🏛️',
          message: 'Department Academic Council Meeting on Friday at 3:00 PM in Conference Room.',
          timestamp: now.subtract(const Duration(hours: 4)),
          type: 'system',
          isRead: true,
        ),
        NotificationModel(
          id: 'faculty_notif_4',
          title: 'Event Organizer Update 🚀',
          message: 'Your hosted workshop "AI and ML Workshop" has registered attendees.',
          timestamp: now.subtract(const Duration(days: 1)),
          type: 'event',
          isRead: true,
        ),
      ];
    } else if (isVisitor) {
      seeds = [
        NotificationModel(
          id: 'visitor_notif_1',
          title: 'Welcome to Amrita Campus 👋',
          message: 'Explore campus landmarks, open auditoriums, and visitor navigation from the Map screen.',
          timestamp: now.subtract(const Duration(minutes: 30)),
          type: 'system',
        ),
        NotificationModel(
          id: 'visitor_notif_2',
          title: 'Visitor Parking Available 🅿️',
          message: 'Designated guest parking spaces are located adjacent to the Main Entrance gate.',
          timestamp: now.subtract(const Duration(hours: 2)),
          type: 'reminder',
        ),
        NotificationModel(
          id: 'visitor_notif_3',
          title: 'Public Campus Event 🎪',
          message: 'Cultural Fest - Utsav 2026 welcomes outside visitors this weekend at the Main Auditorium.',
          timestamp: now.subtract(const Duration(days: 1)),
          type: 'event',
          isRead: true,
        ),
        NotificationModel(
          id: 'visitor_notif_4',
          title: 'Campus Help Desk ℹ️',
          message: 'Security and Information Desk is open 24/7 at Administrative Block reception.',
          timestamp: now.subtract(const Duration(days: 2)),
          type: 'system',
          isRead: true,
        ),
      ];
    } else {
      // Student
      seeds = [
        NotificationModel(
          id: 'student_notif_1',
          title: 'Class Reminder 🔔',
          message: 'Operating Systems lecture starting at 9:00 AM at Academic Block 2, Room 204.',
          timestamp: now.subtract(const Duration(minutes: 20)),
          type: 'class',
        ),
        NotificationModel(
          id: 'student_notif_2',
          title: 'Assignment Due ⏰',
          message: 'DBMS Laboratory Report is due today by 5:00 PM on Campus Portal.',
          timestamp: now.subtract(const Duration(hours: 1)),
          type: 'task',
        ),
        NotificationModel(
          id: 'student_notif_3',
          title: 'Event Reminder 🚀',
          message: 'Hackathon 3.0 starts tomorrow at 9:00 AM at Innovation Lab.',
          timestamp: now.subtract(const Duration(hours: 3)),
          type: 'event',
        ),
        NotificationModel(
          id: 'student_notif_4',
          title: 'Club Notice 💡',
          message: 'Coding Club weekly peer programming session this Wednesday at 4:30 PM.',
          timestamp: now.subtract(const Duration(days: 1)),
          type: 'club',
          isRead: true,
        ),
        NotificationModel(
          id: 'student_notif_5',
          title: 'Welcome to Campus Connect 👋',
          message: 'Track your personal classes, task deadlines, and club registrations in one place.',
          timestamp: now.subtract(const Duration(days: 2)),
          type: 'system',
          isRead: true,
        ),
      ];
    }

    for (final n in seeds) {
      _fallbackMemory[n.id] = n.toMap();
      try {
        await _box?.put(n.id, n.toMap());
      } catch (_) {}
    }
  }
}
