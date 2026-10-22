import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/notification_model.dart';

/// In-app notification inbox backed by Hive with memory fallback.
/// Handles the notification feed displayed in the app.
class InAppNotificationService {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  static const String _boxName = 'in_app_notifications_box';
  static const String _seededKey = '_seeded_v1';

  Box<Map<dynamic, dynamic>>? _box;
  final Map<String, Map<dynamic, dynamic>> _fallbackMemory = {};

  Future<void> init() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
      await _seedIfNeeded();
    } catch (e) {
      debugPrint('[InAppNotificationService] Hive init notice (using memory fallback): $e');
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

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all notifications sorted newest-first.
  List<NotificationModel> getNotifications() {
    final values = _box?.values ?? _fallbackMemory.values;
    final items = values
        .where((m) => m.containsKey('id') && m['id'] != _seededKey) // skip control keys
        .map((m) => NotificationModel.fromMap(m))
        .toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  int get unreadCount =>
      getNotifications().where((n) => !n.isRead).length;

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Add a notification. Prevents duplicates by checking [id].
  Future<void> addNotification(NotificationModel n) async {
    if (_getRecord(n.id) != null) return; // duplicate prevention
    await _putRecord(n.id, n.toMap());
  }

  Future<void> markAsRead(String id) async {
    final raw = _getRecord(id);
    if (raw == null) return;
    final n = NotificationModel.fromMap(raw);
    await _putRecord(id, n.copyWith(isRead: true).toMap());
  }

  Future<void> markAllAsRead() async {
    final values = _box?.values ?? _fallbackMemory.values;
    for (final raw in values.toList()) {
      if (!raw.containsKey('id') || raw['id'] == _seededKey) continue;
      final n = NotificationModel.fromMap(raw);
      if (!n.isRead) {
        await _putRecord(n.id, n.copyWith(isRead: true).toMap());
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    await _deleteRecord(id);
  }

  Future<void> clearNotifications() async {
    final seeded = _getRecord(_seededKey);
    _fallbackMemory.clear();
    try {
      await _box?.clear();
    } catch (_) {}
    if (seeded != null) await _putRecord(_seededKey, seeded);
  }

  // ── Seed (runs once) ──────────────────────────────────────────────────────

  Future<void> _seedIfNeeded() async {
    if (_getRecord(_seededKey) != null) return;

    final now = DateTime.now();

    final seeds = <NotificationModel>[
      // ── TODAY ──
      NotificationModel(
        id: 'seed_task_completed_1',
        title: 'Task Completed ✅',
        message: 'You completed your DBMS Assignment.',
        timestamp: now.subtract(const Duration(minutes: 35)),
        type: 'task',
        relatedTaskId: null,
      ),
      NotificationModel(
        id: 'seed_event_reminder_1',
        title: 'Event Reminder 🔔',
        message: 'Hackathon 3.0 starts tomorrow at 9:00 AM.\n📍 Innovation Lab, Main Block',
        timestamp: now.subtract(const Duration(hours: 1)),
        type: 'event',
        relatedEventId: 'e2',
      ),
      NotificationModel(
        id: 'seed_event_registered_1',
        title: 'Event Registered 🎉',
        message: 'You successfully registered for AI and ML Workshop.',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: 'event',
        relatedEventId: 'e4',
      ),
      NotificationModel(
        id: 'seed_task_reminder_1',
        title: 'Task Reminder ⏰',
        message: 'Probability Assignment is due today at 6:00 PM.',
        timestamp: now.subtract(const Duration(hours: 3)),
        type: 'reminder',
      ),

      // ── YESTERDAY ──
      NotificationModel(
        id: 'seed_event_completed_1',
        title: 'Event Completed',
        message: 'Tech Talk 2026 has ended. Thanks for attending!',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        type: 'event',
        isRead: true,
        relatedEventId: 'e1',
      ),
      NotificationModel(
        id: 'seed_system_1',
        title: 'Welcome to Campus Connect 👋',
        message: 'Stay on top of events, tasks, and campus life. Explore all features from the home screen.',
        timestamp: now.subtract(const Duration(days: 1, hours: 6)),
        type: 'system',
        isRead: true,
      ),

      // ── EARLIER ──
      NotificationModel(
        id: 'seed_task_completed_2',
        title: 'Task Completed ✅',
        message: 'You completed ML Regression Practice.',
        timestamp: now.subtract(const Duration(days: 3)),
        type: 'task',
        isRead: true,
      ),
      NotificationModel(
        id: 'seed_event_reminder_2',
        title: 'Event Reminder 🔔',
        message: 'Cultural Fest - Utsav 2026 is coming up on ${_fmtDate(now.add(const Duration(days: 10)))}.\n📍 Main Auditorium',
        timestamp: now.subtract(const Duration(days: 4)),
        type: 'event',
        isRead: true,
        relatedEventId: 'e3',
      ),
    ];

    for (final n in seeds) {
      await _putRecord(n.id, n.toMap());
    }
    await _putRecord(_seededKey, {'seeded': true});
  }

  static String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
