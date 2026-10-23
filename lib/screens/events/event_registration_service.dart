import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../../../features/calendar/models/event_model.dart';
import '../../../features/calendar/services/event_service.dart';
import '../../../features/notifications/services/notification_service.dart';
import '../../../features/notifications/services/in_app_notification_service.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../../../data/mock_data.dart';
import '../../../models/event.dart';
import '../../../services/auth_service.dart';
import '../../../services/mongodb_service.dart';
import 'dart:math';

/// Manages user-specific event registrations backed by MongoDB Atlas
/// with role-isolated on-device caching.
class EventRegistrationService {
  static final EventRegistrationService _instance =
      EventRegistrationService._internal();
  factory EventRegistrationService() => _instance;
  EventRegistrationService._internal();

  String get _userScope =>
      AuthService.currentUser?.id ??
      AuthService.currentUser?.email.replaceAll(RegExp(r'\W'), '_') ??
      'guest_${AuthService.currentRole.toLowerCase()}';

  String get _boxName => 'event_registrations_box_$_userScope';
  static const String _registeredKey = 'registered_ids';
  static const String _calendarKey = 'calendar_ids';

  Box<dynamic>? _box;
  final Map<String, List<dynamic>> _fallbackMemory = {};
  final EventService _calendarEventService = EventService();
  final NotificationService _notificationService = NotificationService();

  String get _baseUrl => '${MongoDbService.instance.backendUrl}/api/events';

  Map<String, String> _headers([String? token]) {
    final effectiveToken = token ?? AuthService.effectiveToken;
    return {
      'Content-Type': 'application/json',
      if (effectiveToken.isNotEmpty) 'Authorization': 'Bearer $effectiveToken',
    };
  }

  Future<void> init() async {
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
      fetchUserRegistrations();
    } catch (e) {
      debugPrint('[EventRegistrationService] Hive init notice: $e');
      fetchUserRegistrations();
    }
  }

  /// Switch active Hive box when logged in user changes
  Future<void> switchUserScope() async {
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
      await fetchUserRegistrations();
    } catch (_) {}
  }

  /// Fetch user-specific event registrations from MongoDB backend
  Future<Set<String>> fetchUserRegistrations() async {
    try {
      final uri = Uri.parse('$_baseUrl/my-registrations');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['registeredIds'] is List) {
          final Set<String> ids = (data['registeredIds'] as List)
              .map((e) => e.toString())
              .toSet();
          await _saveSet(_registeredKey, ids);
          return ids;
        }
      }
    } catch (e) {
      debugPrint('[EventRegistrationService] Notice fetching registrations ($e). Using cached IDs.');
    }
    return registeredIds;
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

  bool isRegistered(String eventId) {
    return _getSet(_registeredKey).contains(eventId);
  }

  bool isInCalendar(String eventId) => _getSet(_calendarKey).contains(eventId);

  Set<String> get registeredIds => _getSet(_registeredKey);

  /// Returns all registered [Event]s matching the user's registrations.
  List<Event> getRegisteredEvents([List<Event>? sourceList]) {
    final ids = _getSet(_registeredKey);
    final pool = sourceList ?? MockData.events;
    return pool
        .where((e) => ids.contains(e.id))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> register(Event event) async {
    final ids = _getSet(_registeredKey);
    ids.add(event.id);
    await _saveSet(_registeredKey, ids);
    _scheduleReminders(event);

    // Sync registration to MongoDB backend
    try {
      final uri = Uri.parse('$_baseUrl/${event.id}/register');
      await http.post(uri, headers: _headers());
    } catch (_) {}

    // Add in-app notification
    await InAppNotificationService().addNotification(NotificationModel(
      id: 'event_registered_${event.id}_${DateTime.now().millisecondsSinceEpoch}',
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

    // Sync unregistration to MongoDB backend
    try {
      final uri = Uri.parse('$_baseUrl/${event.id}/unregister');
      await http.post(uri, headers: _headers());
    } catch (_) {}

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
    if (isInCalendar(event.id)) return;

    final startDt = _parseDt(event.date, event.timeString);
    final endDt = event.endTimeString != null
        ? _parseDt(event.date, event.endTimeString!)
        : startDt.add(const Duration(hours: 1));

    final calEvent = EventModel(
      id: 'disc_${event.id}',
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

    final oneDayBefore = startDt.subtract(const Duration(days: 1));
    _notificationService.scheduleNotification(
      id: notifBase,
      title: '🔔 Event Tomorrow',
      body: '${event.title} starts tomorrow at ${event.timeString}. 📍 ${event.location}',
      scheduledTime: oneDayBefore,
    );

    final thirtyMinBefore = startDt.subtract(const Duration(minutes: 30));
    _notificationService.scheduleNotification(
      id: notifBase + 1,
      title: '⏰ Starting Soon',
      body: '${event.title} starts in 30 minutes. 📍 ${event.location}',
      scheduledTime: thirtyMinBefore,
    );
  }

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
