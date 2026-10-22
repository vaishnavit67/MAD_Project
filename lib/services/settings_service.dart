import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Persists user preferences using Hive with in-memory fallback.
/// Firebase-ready: swap implementation without changing UI.
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _boxName = 'settings_box';
  Box<dynamic>? _box;
  final Map<String, dynamic> _fallbackMemory = {};

  Future<void> init() async {
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
    } catch (e) {
      debugPrint('[SettingsService] Hive init notice (using memory fallback): $e');
    }
  }

  // ── Getters ─────────────────────────────────────────────────────────────

  bool get isDarkMode {
    try {
      return (_box?.get('dark_mode', defaultValue: false) ?? _fallbackMemory['dark_mode'] ?? false) as bool;
    } catch (_) {
      return false;
    }
  }

  bool get notificationsEnabled {
    try {
      return (_box?.get('notifications_enabled', defaultValue: true) ?? _fallbackMemory['notifications_enabled'] ?? true) as bool;
    } catch (_) {
      return true;
    }
  }

  bool get taskRemindersEnabled {
    try {
      return (_box?.get('task_reminders', defaultValue: true) ?? _fallbackMemory['task_reminders'] ?? true) as bool;
    } catch (_) {
      return true;
    }
  }

  bool get eventRemindersEnabled {
    try {
      return (_box?.get('event_reminders', defaultValue: true) ?? _fallbackMemory['event_reminders'] ?? true) as bool;
    } catch (_) {
      return true;
    }
  }

  bool get soundEnabled {
    try {
      return (_box?.get('sound_enabled', defaultValue: true) ?? _fallbackMemory['sound_enabled'] ?? true) as bool;
    } catch (_) {
      return true;
    }
  }

  bool get hapticEnabled {
    try {
      return (_box?.get('haptic_enabled', defaultValue: true) ?? _fallbackMemory['haptic_enabled'] ?? true) as bool;
    } catch (_) {
      return true;
    }
  }

  // ── Setters ─────────────────────────────────────────────────────────────

  Future<void> setDarkMode(bool v) async {
    _fallbackMemory['dark_mode'] = v;
    try {
      await _box?.put('dark_mode', v);
    } catch (_) {}
  }

  Future<void> setNotificationsEnabled(bool v) async {
    _fallbackMemory['notifications_enabled'] = v;
    try {
      await _box?.put('notifications_enabled', v);
    } catch (_) {}
  }

  Future<void> setTaskReminders(bool v) async {
    _fallbackMemory['task_reminders'] = v;
    try {
      await _box?.put('task_reminders', v);
    } catch (_) {}
  }

  Future<void> setEventReminders(bool v) async {
    _fallbackMemory['event_reminders'] = v;
    try {
      await _box?.put('event_reminders', v);
    } catch (_) {}
  }

  Future<void> setSoundEnabled(bool v) async {
    _fallbackMemory['sound_enabled'] = v;
    try {
      await _box?.put('sound_enabled', v);
    } catch (_) {}
  }

  Future<void> setHapticEnabled(bool v) async {
    _fallbackMemory['haptic_enabled'] = v;
    try {
      await _box?.put('haptic_enabled', v);
    } catch (_) {}
  }
}
