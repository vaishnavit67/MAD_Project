import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../../../features/notifications/services/in_app_notification_service.dart';
import '../../../features/notifications/models/notification_model.dart';
import 'dart:math';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  final InAppNotificationService _notifService = InAppNotificationService();

  void _addMockTask() async {
    final newTask = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'DBMS Assignment ${Random().nextInt(100)}',
      description: 'Complete SQL queries',
      dueDateTime: DateTime.now().add(const Duration(hours: 5)),
      priority: 'High',
      category: 'Assignment',
      reminderMinutes: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notificationId: Random().nextInt(100000),
    );
    await _taskService.addTask(newTask);
    setState(() {}); // refresh UI
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _taskService.getTasks();
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: tasks.isEmpty 
          ? const Center(child: Text("✨ No tasks\nYou're all caught up!"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final t = tasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Checkbox(
                      value: t.completed,
                      activeColor: AppColors.success,
                      onChanged: (val) async {
                        await _taskService.updateTask(t.copyWith(completed: val));
                        // Create in-app notification when completing a task
                        if (val == true) {
                          await _notifService.addNotification(NotificationModel(
                            id: 'task_completed_${t.id}',
                            title: 'Task Completed ✅',
                            message: '${t.title} was completed.',
                            timestamp: DateTime.now(),
                            type: 'task',
                            relatedTaskId: t.id,
                          ));
                        }
                        setState(() {});
                      },
                    ),
                    title: Text(
                      t.title, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: t.completed ? TextDecoration.lineThrough : null,
                        color: t.completed ? AppColors.textSecondary : AppColors.textPrimary,
                      )
                    ),
                    subtitle: Text('Due: ${DateFormat.yMMMd().add_jm().format(t.dueDateTime)} • ${t.priority}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () async {
                        await _taskService.deleteTask(t.id);
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMockTask,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
