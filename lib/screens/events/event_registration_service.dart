import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../features/calendar/models/event_model.dart';
import '../../../features/calendar/services/event_service.dart';
import '../../../features/notifications/services/notification_service.dart';
import '../../../features/notifications/services/in_app_notification_service.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../../../data/mock_data.dart';
import '../../../models/event.dart';
import 'dart:math';

/// Manages student event registration state locally using Hive with memory fallback.
/// Designed so the local implementation can be replaced by Firebase later
/// without changing the UI layer.
class EventRegistrationService {
  static final EventRegistrationService _instance =
      EventRegistrationService._internal();
  factory EventRegistrationService() => _instance;
  EventRegistrationService._internal();

  static const String _boxName = 'event_registrations_box';
  static const String _registeredKey = 'registered_ids';
  static const String _calendarKey = 'calendar_ids';

  Box<dynamic>? _box;
  final Map<String, List<dynamic>> _fallbackMemory = {};
  final EventService _calendarEventService = EventService();
  final NotificationService _notificationService = NotificationService();

  Future<void> init() async {
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
    } catch (e) {
      debugPrint('[EventRegistrationService] Hive init notice (using memory fallback): $e');
    }
  }

  // ── Registration state ────────────────────────────────────────────────────

  Set<String> _getSet(String key) {
    try {
      final raw = _box?.get(key) ?? _fallbackMemory[key];
      if (raw == null) return {};
      if (raw is List) return Set<String>.from(raw.cast<String>());
      return {};
    } catch (_) {
      final raw = _fallbackMemory[key];
      if (raw is List) return Set<String>.from(raw.cast<String>());
      return {};
    }
  }

  Future<void> _saveSet(String key, Set<String> ids) async {
    _fallbackMemory[key] = ids.toList();
    try {
      await _box?.put(key, ids.toList());
    } catch (_) {}
  }

  bool isRegistered(String eventId) => _getSet(_registeredKey).contains(eventId);

  bool isInCalendar(String eventId) => _getSet(_calendarKey).contains(eventId);

  Set<String> get registeredIds => _getSet(_registeredKey);

  /// Returns all registered [Event]s from MockData sorted by date.
  List<Event> getRegisteredEvents() {
    final ids = _getSet(_registeredKey);
    return MockData.events
        .where((e) => ids.contains(e.id))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> register(Event event) async {
    final ids = _getSet(_registeredKey);
    if (ids.contains(event.id)) return; // already registered
    ids.add(event.id);
    await _saveSet(_registeredKey, ids);
    _scheduleReminders(event);

    final index = MockData.events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      final current = MockData.events[index];
      MockData.events[index] = current.copyWith(
        participantCount: current.participantCount + 1,
        availableSeats: current.availableSeats > 0 ? current.availableSeats - 1 : 0,
      );
    }

    // Create in-app notification
    await InAppNotificationService().addNotification(NotificationModel(
      id: 'event_registered_${event.id}',
      title: 'Event Registered 🎉',
      message: 'You successfully registered for ${event.title}.',
      timestamp: DateTime.now(),
      type: 'event',
      relatedEventId: event.id,
    ));
  }

  // ── Unregister ────────────────────────────────────────────────────────────

  Future<void> unregister(Event event) async {
    final regIds = _getSet(_registeredKey);
    regIds.remove(event.id);
    await _saveSet(_registeredKey, regIds);

    final index = MockData.events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      final current = MockData.events[index];
      MockData.events[index] = current.copyWith(
        participantCount: current.participantCount > 0 ? current.participantCount - 1 : 0,
        availableSeats: current.availableSeats + 1,
      );
    }

    // Also remove from calendar
    if (isInCalendar(event.id)) {
      await removeFromCalendar(event);
    }

    // Cancel notifications
    final notifBase = event.id.hashCode.abs() % 900000 + 100000;
    await _notificationService.cancelNotification(notifBase);
    await _notificationService.cancelNotification(notifBase + 1);
  }

  // ── Calendar integration ──────────────────────────────────────────────────

  Future<void> addToCalendar(Event event) async {
    if (isInCalendar(event.id)) return; // prevent duplicates

    // Parse time strings to build DateTime
    final startDt = _parseDt(event.date, event.timeString);
    final endDt = event.endTimeString != null
        ? _parseDt(event.date, event.endTimeString!)
        : startDt.add(const Duration(hours: 1));

    final calEvent = EventModel(
      id: 'disc_${event.id}', // prefix to avoid collision with user-created events
      title: event.title,
      description: event.description,
      startDateTime: startDt,
      endDateTime: endDt.isBefore(startDt)
          ? startDt.add(const Duration(hours: 1))
          : endDt,
      location: event.location,
      category: event.category,
      reminderMinutes: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notificationId: Random().nextInt(800000) + 200000,
    );

    await _calendarEventService.addEvent(calEvent);

    final calIds = _getSet(_calendarKey);
    calIds.add(event.id);
    await _saveSet(_calendarKey, calIds);
  }

  Future<void> removeFromCalendar(Event event) async {
    await _calendarEventService.deleteEvent('disc_${event.id}');
    final calIds = _getSet(_calendarKey);
    calIds.remove(event.id);
    await _saveSet(_calendarKey, calIds);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  void _scheduleReminders(Event event) {
    final startDt = _parseDt(event.date, event.timeString);
    final notifBase = event.id.hashCode.abs() % 900000 + 100000;

    // 1-day reminder
    final oneDayBefore = startDt.subtract(const Duration(days: 1));
    _notificationService.scheduleNotification(
      id: notifBase,
      title: '🔔 Event Tomorrow',
      body: '${event.title} starts tomorrow at ${event.timeString}. 📍 ${event.location}',
      scheduledTime: oneDayBefore,
    );

    // 30-min reminder
    final thirtyMinBefore = startDt.subtract(const Duration(minutes: 30));
    _notificationService.scheduleNotification(
      id: notifBase + 1,
      title: '⏰ Starting Soon',
      body: '${event.title} starts in 30 minutes. 📍 ${event.location}',
      scheduledTime: thirtyMinBefore,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Parse a 12-hr time string like "10:00 AM" into a DateTime on [date].
  static DateTime _parseDt(DateTime date, String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPM = clean.endsWith('PM');
      final timePart = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = timePart.split(':');
      int h = int.parse(parts[0]);
      final m = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPM && h != 12) h += 12;
      if (!isPM && h == 12) h = 0;
      return DateTime(date.year, date.month, date.day, h, m);
    } catch (_) {
      return DateTime(date.year, date.month, date.day, 10, 0);
    }
  }
}
