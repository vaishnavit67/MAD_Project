import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../../notifications/services/notification_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/mongodb_service.dart';

/// Service managing user-specific academic and campus tasks
/// with full backend sync to MongoDB and role-isolated on-device caching.
class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  String get _userScope =>
      AuthService.currentUser?.id ??
      AuthService.currentUser?.email.replaceAll(RegExp(r'\W'), '_') ??
      'guest_${AuthService.currentRole.toLowerCase()}';

  String get _boxName => 'tasks_box_$_userScope';
  Box<Map<dynamic, dynamic>>? _box;
  final Map<String, Map<dynamic, dynamic>> _fallbackTasks = {};
  final NotificationService _notificationService = NotificationService();

  String get _baseUrl => '${MongoDbService.instance.backendUrl}/api/calendar/tasks';

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
      fetchTasksFromBackend();
    } catch (e) {
      debugPrint('[TaskService] Hive init notice (using memory fallback): $e');
      fetchTasksFromBackend();
    }
  }

  /// Switch active Hive box when logged in user changes
  Future<void> switchUserScope() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
      await fetchTasksFromBackend();
    } catch (_) {}
  }

  /// Fetch tasks from Node.js / MongoDB backend according to user and role
  Future<List<TaskModel>> fetchTasksFromBackend() async {
    try {
      final uri = Uri.parse('$_baseUrl?role=${AuthService.currentRole}');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['tasks'] is List) {
          final list = (data['tasks'] as List).map((raw) {
            final m = raw as Map<String, dynamic>;
            final rawDate = m['date'];
            DateTime dueDate;
            if (rawDate != null) {
              dueDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now().add(const Duration(hours: 4));
            } else {
              dueDate = DateTime.now().add(const Duration(hours: 4));
            }

            return TaskModel(
              id: (m['_id'] ?? m['id'] ?? 'tsk_${DateTime.now().millisecondsSinceEpoch}').toString(),
              title: (m['title'] ?? 'Campus Task').toString(),
              description: (m['description'] ?? '').toString(),
              dueDateTime: dueDate,
              priority: (m['priority'] ?? 'medium').toString(),
              category: (m['category'] ?? 'General').toString(),
              completed: m['completed'] == true,
              reminderMinutes: NumberFormatParser.toInt(m['reminderMinutes'], 15),
              createdAt: m['createdAt'] != null
                  ? (DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now())
                  : DateTime.now(),
              updatedAt: m['updatedAt'] != null
                  ? (DateTime.tryParse(m['updatedAt'].toString()) ?? DateTime.now())
                  : DateTime.now(),
              notificationId: (m['_id'] ?? m['id'] ?? '').toString().hashCode.abs() % 100000,
            );
          }).toList();

          // Cache in local user-scoped box
          if (_box != null) {
            await _box!.clear();
            for (final t in list) {
              await _box!.put(t.id, t.toMap());
            }
          } else {
            _fallbackTasks.clear();
            for (final t in list) {
              _fallbackTasks[t.id] = t.toMap();
            }
          }

          return list;
        }
      }
    } catch (e) {
      debugPrint('[TaskService] Notice fetching backend tasks ($e), using cached tasks.');
    }

    return getTasks();
  }

  List<TaskModel> getTasks() {
    final values = _box?.values ?? _fallbackTasks.values;
    if (values.isEmpty) {
      _seedDefaultTasks();
    }
    final effectiveValues = _box?.values ?? _fallbackTasks.values;
    final results = <TaskModel>[];
    for (final map in effectiveValues) {
      try {
        results.add(TaskModel.fromMap(map));
      } catch (e) {
        debugPrint('[TaskService] Corrupted task skipped: $e');
      }
    }
    return results;
  }

  void _seedDefaultTasks() {
    final now = DateTime.now();
    final isFaculty = AuthService.isFaculty;

    final defaultList = isFaculty
        ? [
            TaskModel(
              id: 'seed_fac_tsk_1',
              title: 'Review Club Membership Applications',
              description: 'Review and approve/decline student join requests in the Faculty Portal.',
              dueDateTime: DateTime(now.year, now.month, now.day, 17, 0),
              priority: 'High',
              category: 'Faculty',
              completed: false,
              reminderMinutes: 30,
              createdAt: now,
              updatedAt: now,
              notificationId: 9001,
            ),
            TaskModel(
              id: 'seed_fac_tsk_2',
              title: 'Upload End-Semester Attendance & Grades',
              description: 'Submit internal marks and lecture attendance to the AIMS portal.',
              dueDateTime: now.add(const Duration(days: 2)),
              priority: 'High',
              category: 'Academic',
              completed: false,
              reminderMinutes: 60,
              createdAt: now,
              updatedAt: now,
              notificationId: 9002,
            ),
            TaskModel(
              id: 'seed_fac_tsk_3',
              title: 'Faculty Academic Council Monthly Review',
              description: 'Departmental curriculum review meeting at Main Boardroom.',
              dueDateTime: now.add(const Duration(days: 3)),
              priority: 'Medium',
              category: 'Meeting',
              completed: false,
              reminderMinutes: 15,
              createdAt: now,
              updatedAt: now,
              notificationId: 9003,
            ),
          ]
        : [
            TaskModel(
              id: 'seed_std_tsk_1',
              title: 'Submit MAD Project Checkpoint',
              description: 'Upload project repository link and progress documentation.',
              dueDateTime: DateTime(now.year, now.month, now.day, 23, 59),
              priority: 'High',
              category: 'Assignment',
              completed: false,
              reminderMinutes: 30,
              createdAt: now,
              updatedAt: now,
              notificationId: 9101,
            ),
            TaskModel(
              id: 'seed_std_tsk_2',
              title: 'Computer Networks Lab Record',
              description: 'Complete packet tracer topology and submit printed record.',
              dueDateTime: now.add(const Duration(days: 1)),
              priority: 'Medium',
              category: 'Lab',
              completed: false,
              reminderMinutes: 45,
              createdAt: now,
              updatedAt: now,
              notificationId: 9102,
            ),
            TaskModel(
              id: 'seed_std_tsk_3',
              title: 'Register for Anokha Campus Fest',
              description: 'Register team for annual campus hackathon and tech workshops.',
              dueDateTime: now.add(const Duration(days: 4)),
              priority: 'Low',
              category: 'Club',
              completed: false,
              reminderMinutes: 15,
              createdAt: now,
              updatedAt: now,
              notificationId: 9103,
            ),
          ];

    for (final t in defaultList) {
      _fallbackTasks[t.id] = t.toMap();
      try {
        _box?.put(t.id, t.toMap());
      } catch (_) {}
    }
  }

  Future<void> addTask(TaskModel task) async {
    _fallbackTasks[task.id] = task.toMap();
    try {
      await _box?.put(task.id, task.toMap());
    } catch (_) {}
    _scheduleTaskReminders(task);

    // Sync to MongoDB backend
    try {
      final uri = Uri.parse(_baseUrl);
      await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'title': task.title,
          'description': task.description,
          'date': task.dueDateTime.toIso8601String(),
          'priority': task.priority,
          'reminderMinutes': task.reminderMinutes,
        }),
      );
    } catch (_) {}
  }

  Future<void> updateTask(TaskModel task) async {
    _fallbackTasks[task.id] = task.toMap();
    try {
      await _box?.put(task.id, task.toMap());
    } catch (_) {}
    await _notificationService.cancelNotification(task.notificationId);
    if (!task.completed) {
      _scheduleTaskReminders(task);
    }

    // Sync to MongoDB backend
    try {
      final uri = Uri.parse('$_baseUrl/${task.id}');
      await http.put(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'title': task.title,
          'description': task.description,
          'date': task.dueDateTime.toIso8601String(),
          'completed': task.completed,
          'priority': task.priority,
        }),
      );
    } catch (_) {}
  }

  Future<void> deleteTask(String id) async {
    final map = _box?.get(id) ?? _fallbackTasks[id];
    if (map != null) {
      final task = TaskModel.fromMap(map);
      await _notificationService.cancelNotification(task.notificationId);
    }
    _fallbackTasks.remove(id);
    try {
      await _box?.delete(id);
    } catch (_) {}

    // Sync deletion to MongoDB backend
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      await http.delete(uri, headers: _headers());
    } catch (_) {}
  }

  void _scheduleTaskReminders(TaskModel task) {
    if (task.completed) return;
    if (task.reminderMinutes > 0) {
      final reminderTime = task.dueDateTime.subtract(Duration(minutes: task.reminderMinutes));
      _notificationService.scheduleNotification(
        id: task.notificationId,
        title: 'Task Reminder: ${task.title}',
        body: 'Due in ${task.reminderMinutes} minutes',
        scheduledTime: reminderTime,
      );
    }
  }
}

class NumberFormatParser {
  static int toInt(dynamic val, int defaultVal) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultVal;
    return defaultVal;
  }
}
