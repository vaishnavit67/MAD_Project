import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../../notifications/services/notification_service.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  static const String _boxName = 'tasks_box';
  Box<Map<dynamic, dynamic>>? _box;
  final Map<String, Map<dynamic, dynamic>> _fallbackTasks = {};
  final NotificationService _notificationService = NotificationService();

  Future<void> init() async {
    try {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    } catch (e) {
      debugPrint('[TaskService] Hive init notice (using memory fallback): $e');
    }
  }

  List<TaskModel> getTasks() {
    final values = _box?.values ?? _fallbackTasks.values;
    return values.map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<void> addTask(TaskModel task) async {
    _fallbackTasks[task.id] = task.toMap();
    try {
      await _box?.put(task.id, task.toMap());
    } catch (_) {}
    _scheduleTaskReminders(task);
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
