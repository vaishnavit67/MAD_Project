import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/event_model.dart';
import '../../notifications/services/notification_service.dart';
import '../../../../services/auth_service.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  String get _userScope =>
      AuthService.currentUser?.id ??
      AuthService.currentUser?.email.replaceAll(RegExp(r'\W'), '_') ??
      'guest_${AuthService.currentRole.toLowerCase()}';

  String get _boxName => 'calendar_events_box_$_userScope';
  Box<Map<dynamic, dynamic>>? _box;
  final Map<String, Map<dynamic, dynamic>> _fallbackEvents = {};
  final NotificationService _notificationService = NotificationService();

  Future<void> init() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    } catch (e) {
      debugPrint('[EventService] Hive init notice (using memory fallback): $e');
    }
  }

  /// Switch active Hive box when logged in user changes
  Future<void> switchUserScope() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    } catch (_) {}
  }

  List<EventModel> getEvents() {
    final values = _box?.values ?? _fallbackEvents.values;
    final results = <EventModel>[];
    for (final map in values) {
      try {
        results.add(EventModel.fromMap(map));
      } catch (e) {
        debugPrint('[EventService] Corrupted event skipped: $e');
      }
    }
    return results;
  }

  Future<void> addEvent(EventModel event) async {
    _fallbackEvents[event.id] = event.toMap();
    try {
      await _box?.put(event.id, event.toMap());
    } catch (_) {}
    _scheduleEventReminders(event);
  }

  Future<void> updateEvent(EventModel event) async {
    _fallbackEvents[event.id] = event.toMap();
    try {
      await _box?.put(event.id, event.toMap());
    } catch (_) {}
    await _notificationService.cancelNotification(event.notificationId);
    _scheduleEventReminders(event);
  }

  Future<void> deleteEvent(String id) async {
    final map = _box?.get(id) ?? _fallbackEvents[id];
    if (map != null) {
      final event = EventModel.fromMap(map);
      await _notificationService.cancelNotification(event.notificationId);
    }
    _fallbackEvents.remove(id);
    try {
      await _box?.delete(id);
    } catch (_) {}
  }

  void _scheduleEventReminders(EventModel event) {
    if (event.reminderMinutes > 0) {
      final reminderTime = event.startDateTime.subtract(Duration(minutes: event.reminderMinutes));
      _notificationService.scheduleNotification(
        id: event.notificationId,
        title: 'Reminder: ${event.title}',
        body: 'Starts in ${event.reminderMinutes} minutes at ${event.location}',
        scheduledTime: reminderTime,
      );
    }
    // Also schedule exact time
    _notificationService.scheduleNotification(
      id: event.notificationId + 10000, // Offset for exact time
      title: '🚀 ${event.title} is starting now',
      body: 'Location: ${event.location}',
      scheduledTime: event.startDateTime,
    );
  }
}
