import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/event_model.dart';
import '../models/class_model.dart';
import '../../tasks/models/task_model.dart';
import '../services/event_service.dart';
import '../../tasks/services/task_service.dart';
import '../services/class_service.dart';
import '../../../services/auth_service.dart';

// ─── Calendar color palette ────────────────────────────────────────────────
class CalColors {
  static const Color event    = Color(0xFF7C5CFC); // Purple  – events
  static const Color task     = Color(0xFF2196F3); // Blue    – tasks
  static const Color classClr = Color(0xFF26A69A); // Green   – classes
  static const Color deadline = Color(0xFFF57C00); // Orange  – deadlines/high-prio tasks

  static const Color eventBg    = Color(0xFFEDE7FE);
  static const Color taskBg     = Color(0xFFE3F2FD);
  static const Color classBg    = Color(0xFFE0F2F1);
  static const Color deadlineBg = Color(0xFFFFF3E0);
}

// ─── CalendarScreen ────────────────────────────────────────────────────────
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventService   _eventService = EventService();
  final TaskService    _taskService  = TaskService();
  final ClassService   _classService = ClassService();

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay  = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  void initState() {
    super.initState();
    _refreshBackend();
  }

  Future<void> _refreshBackend() async {
    await Future.wait([
      _classService.fetchClassesFromBackend(),
      _taskService.fetchTasksFromBackend(),
    ]);
    if (mounted) setState(() {});
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  /// All items (events + tasks + classes) for a given date, sorted by time.
  List<_CalItem> _itemsForDay(DateTime day) {
    final items = <_CalItem>[];

    for (final e in _eventService.getEvents()) {
      if (_isSameDay(e.startDateTime, day)) {
        items.add(_CalItem.fromEvent(e));
      }
    }
    for (final t in _taskService.getTasks()) {
      if (_isSameDay(t.dueDateTime, day)) {
        items.add(_CalItem.fromTask(t));
      }
    }
    // Classes are isolated to students and faculty, never visitors
    if (!AuthService.isVisitor) {
      for (final c in _classService.getClasses()) {
        if (c.occursOn(day)) {
          items.add(_CalItem.fromClass(c, day));
        }
      }
    }

    items.sort((a, b) => a.sortTime.compareTo(b.sortTime));
    return items;
  }

  /// Distinct item types present on a day (for dot indicators).
  Set<_ItemType> _typesForDay(DateTime day) {
    return _itemsForDay(day).map((i) => i.type).toSet();
  }

  // ── month navigation ─────────────────────────────────────────────────────

  void _prevMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      });

  void _goToday() => setState(() {
        final n = DateTime.now();
        _focusedMonth = DateTime(n.year, n.month);
        _selectedDay  = DateTime(n.year, n.month, n.day);
      });

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedItems  = _itemsForDay(_selectedDay);
    final upcoming       = _buildUpcoming();
    final isSelectedToday = _isToday(_selectedDay);
    final selectedLabel  = isSelectedToday
        ? 'Today, ${DateFormat('MMM d').format(_selectedDay)}'
        : DateFormat('MMM d, yyyy').format(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(
          'Calendar',
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _goToday,
            child: const Text(
              'Today',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenu,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBackend,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (AuthService.isFaculty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school_rounded, color: Color(0xFF7C3AED), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Faculty Timetable: Teaching Schedule, Lectures & Consultation Hours (${AuthService.currentUser?.name ?? "Faculty Lead"})',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (AuthService.isVisitor)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tour_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Visitor Mode: Academic classes are not applicable. Showing campus guest tasks & public events.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // ── Monthly Calendar ──────────────────────────────────────────
              _CalendarWidget(
                focusedMonth: _focusedMonth,
                selectedDay: _selectedDay,
                onPrev: _prevMonth,
                onNext: _nextMonth,
                onDayTap: (d) => setState(() => _selectedDay = d),
                typesForDay: _typesForDay,
                isToday: _isToday,
                isSameDay: _isSameDay,
              ),

              const SizedBox(height: 20),

              // ── Daily Schedule ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  selectedLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AuthService.isVisitor
                      ? "Visitor Schedule & Activities"
                      : (AuthService.isFaculty ? "Faculty Schedule & Lectures" : "Today's Schedule"),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.subtext(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (selectedItems.isEmpty)
                _emptyState(context)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: selectedItems.length,
                  itemBuilder: (_, i) => _CalItemCard(
                    item: selectedItems[i],
                    onTap: () => _showItemDetail(selectedItems[i]),
                    onComplete: selectedItems[i].type == _ItemType.task
                        ? () => _toggleTaskComplete(selectedItems[i])
                        : null,
                    onDelete: () => _deleteItem(selectedItems[i]),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Upcoming ──────────────────────────────────────────────────
              if (upcoming.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildUpcomingWidgets(upcoming),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _emptyState(BuildContext context) {
    final isVisitor = AuthService.isVisitor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.2 : 0.04), blurRadius: 10)],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Text(isVisitor ? '🏛️' : '🎉', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              isVisitor ? 'No visitor activities today' : 'No plans for today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text(context)),
            ),
            const SizedBox(height: 6),
            Text(
              isVisitor
                  ? 'Your campus itinerary is clear. Explore open events or add a visitor task!'
                  : 'Your schedule is clear. Add something!',
              style: TextStyle(fontSize: 13, color: AppColors.subtext(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _showAddMenu,
              icon: const Icon(Icons.add, size: 18),
              label: Text(isVisitor ? 'Add Itinerary Task' : 'Add Task'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upcoming helpers ──────────────────────────────────────────────────────

  Map<DateTime, List<_CalItem>> _buildUpcoming() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <DateTime, List<_CalItem>>{};

    for (int offset = 0; offset <= 14; offset++) {
      final day = today.add(Duration(days: offset));
      final items = _itemsForDay(day);
      if (items.isNotEmpty) {
        result[day] = items;
      }
    }
    return result;
  }

  List<Widget> _buildUpcomingWidgets(Map<DateTime, List<_CalItem>> upcoming) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final widgets = <Widget>[];

    for (final entry in upcoming.entries) {
      final day = entry.key;
      String label;
      if (_isSameDay(day, today)) {
        label = 'TODAY';
      } else if (_isSameDay(day, tomorrow)) {
        label = 'TOMORROW';
      } else {
        label = DateFormat('d MMM').format(day).toUpperCase();
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
      for (final item in entry.value) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _CalItemCard(
              item: item,
              compact: true,
              onTap: () => _showItemDetail(item),
              onComplete: item.type == _ItemType.task ? () => _toggleTaskComplete(item) : null,
              onDelete: () => _deleteItem(item),
            ),
          ),
        );
      }
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  // ── CRUD actions ──────────────────────────────────────────────────────────

  Future<void> _toggleTaskComplete(_CalItem item) async {
    final tasks = _taskService.getTasks();
    final task = tasks.firstWhere((t) => t.id == item.id);
    await _taskService.updateTask(task.copyWith(
      completed: !task.completed,
      updatedAt: DateTime.now(),
    ));
    setState(() {});
  }

  Future<void> _deleteItem(_CalItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete item?'),
        content: Text('Remove "${item.title}" from your calendar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (item.type == _ItemType.event) {
      await _eventService.deleteEvent(item.id);
    } else if (item.type == _ItemType.task || item.type == _ItemType.deadline) {
      await _taskService.deleteTask(item.id);
    } else if (item.type == _ItemType.classItem) {
      await _classService.deleteClass(item.id);
    }
    setState(() {});
  }

  // ── Bottom sheets ─────────────────────────────────────────────────────────

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMenuSheet(
        isVisitor: AuthService.isVisitor,
        onAddTask: () {
          Navigator.pop(context);
          _showAddTask();
        },
        onAddEvent: () {
          Navigator.pop(context);
          _showAddEvent();
        },
        onAddClass: () {
          Navigator.pop(context);
          _showAddClass();
        },
      ),
    );
  }

  void _showAddTask() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(initialDate: _selectedDay),
    );
    if (result == null || !mounted) return;

    final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: result['title'] as String,
      description: '',
      dueDateTime: result['dueDateTime'] as DateTime,
      priority: result['priority'] as String,
      category: AuthService.isVisitor ? 'Visitor' : (AuthService.isFaculty ? 'Faculty' : 'Personal'),
      reminderMinutes: result['reminder'] == true ? 30 : 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notificationId: Random().nextInt(900000) + 100000,
    );
    await _taskService.addTask(task);
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar('✅ Task added to Calendar & Tasks', AppColors.primary),
    );
  }

  void _showAddEvent() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEventSheet(initialDate: _selectedDay),
    );
    if (result == null || !mounted) return;

    final event = EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: result['title'] as String,
      description: (result['description'] ?? '') as String,
      startDateTime: result['startDateTime'] as DateTime,
      endDateTime: result['endDateTime'] as DateTime,
      location: (result['location'] ?? '') as String,
      category: 'Campus Event',
      reminderMinutes: result['notify'] == true ? 30 : 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notificationId: Random().nextInt(900000) + 100000,
    );
    await _eventService.addEvent(event);
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar('🎉 Event added to Calendar & Events', CalColors.event),
    );
  }

  void _showAddClass() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddClassSheet(),
    );
    if (result == null || !mounted) return;

    final cls = ClassModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: result['subject'] as String,
      dayOfWeek: result['dayOfWeek'] as int,
      startTime: result['startTime'] as String,
      endTime: result['endTime'] as String,
      room: (result['room'] ?? '') as String,
      teacher: (result['teacher'] ?? '') as String,
      isWeekly: (result['isWeekly'] ?? true) as bool,
      createdAt: DateTime.now(),
    );
    await _classService.addClass(cls);
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar('🎓 Class added to Calendar', CalColors.classClr),
    );
  }

  void _showItemDetail(_CalItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(
        item: item,
        onComplete: item.type == _ItemType.task ? () {
          Navigator.pop(context);
          _toggleTaskComplete(item);
        } : null,
        onDelete: () {
          Navigator.pop(context);
          _deleteItem(item);
        },
      ),
    );
  }

  SnackBar _snackBar(String msg, Color color) => SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// CALENDAR WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _CalendarWidget extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDayTap;
  final Set<_ItemType> Function(DateTime) typesForDay;
  final bool Function(DateTime) isToday;
  final bool Function(DateTime, DateTime) isSameDay;

  const _CalendarWidget({
    required this.focusedMonth,
    required this.selectedDay,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
    required this.typesForDay,
    required this.isToday,
    required this.isSameDay,
  });

  @override
  Widget build(BuildContext context) {
    // First day of month, offset so Monday = 0
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);
    final startOffset = (firstDay.weekday - 1) % 7; // Mon=0
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.2 : 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          // ── Month header ─────────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: Icon(Icons.chevron_left_rounded, color: AppColors.text(context)),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(focusedMonth),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: Icon(Icons.chevron_right_rounded, color: AppColors.text(context)),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Day labels ───────────────────────────────────────────────────
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.subtext(context),
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 8),

          // ── Day cells ─────────────────────────────────────────────────────
          ...List.generate(rows, (rowIdx) {
            return Row(
              children: List.generate(7, (colIdx) {
                final cellIdx = rowIdx * 7 + colIdx;
                final dayNum = cellIdx - startOffset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 46));
                }
                final day = DateTime(focusedMonth.year, focusedMonth.month, dayNum);
                final types = typesForDay(day);
                final todayFlag = isToday(day);
                final selectedFlag = isSameDay(day, selectedDay);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap(day),
                    child: Container(
                      height: 46,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: selectedFlag
                            ? AppColors.primary
                            : todayFlag
                                ? (AppColors.isDark(context) ? const Color(0xFF312E81) : AppColors.featureIconBg1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: todayFlag && !selectedFlag
                            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: selectedFlag
                                  ? Colors.white
                                  : todayFlag
                                      ? AppColors.primary
                                      : AppColors.text(context),
                            ),
                          ),
                          if (types.isNotEmpty)
                            const SizedBox(height: 2),
                          if (types.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: types.take(3).map((t) {
                                return Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: selectedFlag ? Colors.white70 : _dotColor(t),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Color _dotColor(_ItemType t) {
    switch (t) {
      case _ItemType.event:     return CalColors.event;
      case _ItemType.task:      return CalColors.task;
      case _ItemType.classItem: return CalColors.classClr;
      case _ItemType.deadline:  return CalColors.deadline;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CAL ITEM (unified view model)
// ═══════════════════════════════════════════════════════════════════════════

enum _ItemType { event, task, classItem, deadline }

class _CalItem {
  final String id;
  final _ItemType type;
  final String title;
  final String subtitle;     // time/location
  final String? description;
  final DateTime sortTime;
  final String? location;
  final DateTime? endTime;
  final bool completed;
  final String? priority;

  const _CalItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.sortTime,
    this.description,
    this.location,
    this.endTime,
    this.completed = false,
    this.priority,
  });

  factory _CalItem.fromEvent(EventModel e) => _CalItem(
        id: e.id,
        type: _ItemType.event,
        title: e.title,
        subtitle: '${DateFormat.jm().format(e.startDateTime)}${e.location.isNotEmpty ? ' • ${e.location}' : ''}',
        sortTime: e.startDateTime,
        description: e.description,
        location: e.location,
        endTime: e.endDateTime,
      );

  factory _CalItem.fromTask(TaskModel t) => _CalItem(
        id: t.id,
        type: t.priority == 'High' ? _ItemType.deadline : _ItemType.task,
        title: t.title,
        subtitle: 'Due ${DateFormat.jm().format(t.dueDateTime)}',
        sortTime: t.dueDateTime,
        description: t.description,
        completed: t.completed,
        priority: t.priority,
      );

  factory _CalItem.fromClass(ClassModel c, DateTime day) => _CalItem(
        id: c.id,
        type: _ItemType.classItem,
        title: c.subject,
        subtitle: '${_fmtTime(c.startTime)} – ${_fmtTime(c.endTime)}${c.room.isNotEmpty ? ' • ${c.room}' : ''}',
        sortTime: c.startDateTimeOn(day),
        location: c.room,
        endTime: c.endDateTimeOn(day),
      );

  static String _fmtTime(String timeStr) {
    if (timeStr.contains('AM') || timeStr.contains('PM')) {
      return timeStr;
    }
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, h, m);
      return DateFormat.jm().format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  Color get color {
    switch (type) {
      case _ItemType.event:     return CalColors.event;
      case _ItemType.task:      return completed ? AppColors.textSecondary : CalColors.task;
      case _ItemType.classItem: return CalColors.classClr;
      case _ItemType.deadline:  return completed ? AppColors.textSecondary : CalColors.deadline;
    }
  }

  Color get bgColor {
    switch (type) {
      case _ItemType.event:     return CalColors.eventBg;
      case _ItemType.task:      return CalColors.taskBg;
      case _ItemType.classItem: return CalColors.classBg;
      case _ItemType.deadline:  return CalColors.deadlineBg;
    }
  }

  IconData get icon {
    switch (type) {
      case _ItemType.event:     return Icons.event_rounded;
      case _ItemType.task:      return Icons.check_circle_outline_rounded;
      case _ItemType.classItem: return Icons.school_rounded;
      case _ItemType.deadline:  return Icons.flag_rounded;
    }
  }

  String get typeLabel {
    switch (type) {
      case _ItemType.event:     return 'EVENT';
      case _ItemType.task:      return 'TASK';
      case _ItemType.classItem: return 'CLASS';
      case _ItemType.deadline:  return 'DEADLINE';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CALENDAR ITEM CARD
// ═══════════════════════════════════════════════════════════════════════════

class _CalItemCard extends StatelessWidget {
  final _CalItem item;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final VoidCallback onDelete;
  final bool compact;

  const _CalItemCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.onComplete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // color bar
                Container(
                  width: 4,
                  height: compact ? 40 : 50,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                // icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 18, color: item.color),
                ),
                const SizedBox(width: 10),
                // title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 14 : 15,
                          color: AppColors.text(context),
                          decoration: item.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                      ),
                    ],
                  ),
                ),
                // type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.typeLabel,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: item.color),
                  ),
                ),
                if (onComplete != null)
                  GestureDetector(
                    onTap: onComplete,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        item.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: item.completed ? AppColors.success : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD MENU SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _AddMenuSheet extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onAddEvent;
  final VoidCallback onAddClass;
  final bool isVisitor;

  const _AddMenuSheet({
    required this.onAddTask,
    required this.onAddEvent,
    required this.onAddClass,
    this.isVisitor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderCol(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'What do you want to add?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _AddMenuTile(
            icon: Icons.task_alt_rounded,
            label: 'Task',
            description: isVisitor ? 'Campus visit task, reminder' : 'To-do, assignment, deadline',
            color: CalColors.task,
            bgColor: CalColors.taskBg,
            onTap: onAddTask,
          ),
          const SizedBox(height: 10),
          _AddMenuTile(
            icon: Icons.event_rounded,
            label: 'Event',
            description: isVisitor ? 'Campus open event, tour' : 'Campus event, club meeting',
            color: CalColors.event,
            bgColor: CalColors.eventBg,
            onTap: onAddEvent,
          ),
          if (!isVisitor) ...[
            const SizedBox(height: 10),
            _AddMenuTile(
              icon: Icons.school_rounded,
              label: 'Class',
              description: 'Weekly recurring lecture',
              color: CalColors.classClr,
              bgColor: CalColors.classBg,
              onTap: onAddClass,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _AddMenuTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15)),
                    Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ITEM DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _ItemDetailSheet extends StatelessWidget {
  final _CalItem item;
  final VoidCallback? onComplete;
  final VoidCallback onDelete;

  const _ItemDetailSheet({
    required this.item,
    this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: item.bgColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.text(context),
                        decoration: item.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.typeLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: item.color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // Time
          _detailRow(context, Icons.schedule_rounded, item.subtitle),
          // Location
          if (item.location != null && item.location!.isNotEmpty)
            _detailRow(context, Icons.location_on_outlined, item.location!),
          // Description
          if (item.description != null && item.description!.isNotEmpty)
            _detailRow(context, Icons.notes_rounded, item.description!),
          // Priority
          if (item.priority != null)
            _detailRow(context, Icons.flag_rounded, 'Priority: ${item.priority}'),

          const SizedBox(height: 20),
          // Actions
          if (onComplete != null)
            ElevatedButton.icon(
              onPressed: onComplete,
              icon: Icon(item.completed ? Icons.replay_rounded : Icons.check_circle_outline_rounded),
              label: Text(item.completed ? 'Mark Incomplete' : 'Mark Complete',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.subtext(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: AppColors.text(context), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD TASK SHEET
// ═══════════════════════════════════════════════════════════════════════════

class AddTaskSheet extends StatefulWidget {
  final DateTime initialDate;
  const AddTaskSheet({super.key, required this.initialDate});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  late DateTime _dueDate;
  TimeOfDay _dueTime = const TimeOfDay(hour: 18, minute: 0);
  String _priority = 'Medium';
  bool _reminder = true;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _dueDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _dueTime);
    if (t != null) setState(() => _dueTime = t);
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final due = DateTime(_dueDate.year, _dueDate.month, _dueDate.day, _dueTime.hour, _dueTime.minute);
    Navigator.pop(context, {
      'title': _titleCtrl.text.trim(),
      'dueDateTime': due,
      'priority': _priority,
      'reminder': _reminder,
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Add Task',
      accentColor: CalColors.task,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetField(label: 'Task Title', child: TextField(
            controller: _titleCtrl,
            decoration: _inputDec(context, 'e.g. Complete DBMS Assignment'),
            textCapitalization: TextCapitalization.sentences,
          )),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _SheetField(label: 'Date', child: _TapField(
              text: DateFormat('d MMM yyyy').format(_dueDate),
              icon: Icons.calendar_today_rounded,
              onTap: _pickDate,
            ))),
            const SizedBox(width: 12),
            Expanded(child: _SheetField(label: 'Time', child: _TapField(
              text: _dueTime.format(context),
              icon: Icons.schedule_rounded,
              onTap: _pickTime,
            ))),
          ]),
          const SizedBox(height: 14),
          _SheetField(label: 'Priority', child: DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: _inputDec(context, null),
            items: ['Low', 'Medium', 'High']
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
          )),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Remind me 30 min before', style: TextStyle(fontSize: 14, color: AppColors.text(context)))),
            Switch(value: _reminder, onChanged: (v) => setState(() => _reminder = v), activeThumbColor: CalColors.task),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: CalColors.task,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('SAVE TASK', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD EVENT SHEET
// ═══════════════════════════════════════════════════════════════════════════

class AddEventSheet extends StatefulWidget {
  final DateTime initialDate;
  const AddEventSheet({super.key, required this.initialDate});

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime   = const TimeOfDay(hour: 17, minute: 0);
  bool _notify = true;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _startTime);
    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _endTime);
    if (t != null) setState(() => _endTime = t);
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event name'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final start = DateTime(_date.year, _date.month, _date.day, _startTime.hour, _startTime.minute);
    final end   = DateTime(_date.year, _date.month, _date.day, _endTime.hour, _endTime.minute);
    Navigator.pop(context, {
      'title': _titleCtrl.text.trim(),
      'startDateTime': start,
      'endDateTime': end.isAfter(start) ? end : start.add(const Duration(hours: 1)),
      'location': _locationCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'notify': _notify,
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Add Event',
      accentColor: CalColors.event,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetField(label: 'Event Name', child: TextField(
            controller: _titleCtrl,
            decoration: _inputDec(context, 'e.g. Hackathon 3.0'),
            textCapitalization: TextCapitalization.words,
          )),
          const SizedBox(height: 14),
          _SheetField(label: 'Date', child: _TapField(
            text: DateFormat('d MMM yyyy').format(_date),
            icon: Icons.calendar_today_rounded,
            onTap: _pickDate,
          )),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _SheetField(label: 'Start Time', child: _TapField(
              text: _startTime.format(context),
              icon: Icons.schedule_rounded,
              onTap: _pickStart,
            ))),
            const SizedBox(width: 12),
            Expanded(child: _SheetField(label: 'End Time', child: _TapField(
              text: _endTime.format(context),
              icon: Icons.schedule_rounded,
              onTap: _pickEnd,
            ))),
          ]),
          const SizedBox(height: 14),
          _SheetField(label: 'Location', child: TextField(
            controller: _locationCtrl,
            decoration: _inputDec(context, 'e.g. Main Auditorium'),
          )),
          const SizedBox(height: 14),
          _SheetField(label: 'Description (optional)', child: TextField(
            controller: _descCtrl,
            decoration: _inputDec(context, 'Brief description...'),
            maxLines: 2,
          )),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Notify me 30 min before', style: TextStyle(fontSize: 14, color: AppColors.text(context)))),
            Switch(value: _notify, onChanged: (v) => setState(() => _notify = v), activeThumbColor: CalColors.event),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: CalColors.event,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('CREATE EVENT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD CLASS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class AddClassSheet extends StatefulWidget {
  const AddClassSheet({super.key});

  @override
  State<AddClassSheet> createState() => _AddClassSheetState();
}

class _AddClassSheetState extends State<AddClassSheet> {
  final _subjectCtrl = TextEditingController();
  final _roomCtrl    = TextEditingController();
  final _teacherCtrl = TextEditingController();
  int _dayOfWeek = DateTime.now().weekday; // 1=Mon..7=Sun
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime   = const TimeOfDay(hour: 10, minute: 0);
  bool _isWeekly = true;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _roomCtrl.dispose();
    _teacherCtrl.dispose();
    super.dispose();
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _startTime);
    if (t != null) setState(() => _startTime = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _endTime);
    if (t != null) setState(() => _endTime = t);
  }

  void _save() {
    if (_subjectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    Navigator.pop(context, {
      'subject': _subjectCtrl.text.trim(),
      'dayOfWeek': _dayOfWeek,
      'startTime': '${_pad(_startTime.hour)}:${_pad(_startTime.minute)}',
      'endTime': '${_pad(_endTime.hour)}:${_pad(_endTime.minute)}',
      'room': _roomCtrl.text.trim(),
      'teacher': _teacherCtrl.text.trim(),
      'isWeekly': _isWeekly,
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Add Class',
      accentColor: CalColors.classClr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetField(label: 'Subject', child: TextField(
            controller: _subjectCtrl,
            decoration: _inputDec(context, 'e.g. Machine Learning'),
            textCapitalization: TextCapitalization.words,
          )),
          const SizedBox(height: 14),
          _SheetField(
            label: 'Day of Week',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final dayIdx = i + 1;
                final selected = _dayOfWeek == dayIdx;
                return GestureDetector(
                  onTap: () => setState(() => _dayOfWeek = dayIdx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40, height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? CalColors.classClr
                          : (AppColors.isDark(context) ? const Color(0xFF262626) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? CalColors.classClr
                            : (AppColors.isDark(context) ? const Color(0xFF404040) : AppColors.border),
                      ),
                    ),
                    child: Text(
                      _days[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.text(context),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _SheetField(label: 'Start Time', child: _TapField(
              text: _startTime.format(context),
              icon: Icons.schedule_rounded,
              onTap: _pickStart,
            ))),
            const SizedBox(width: 12),
            Expanded(child: _SheetField(label: 'End Time', child: _TapField(
              text: _endTime.format(context),
              icon: Icons.schedule_rounded,
              onTap: _pickEnd,
            ))),
          ]),
          const SizedBox(height: 14),
          _SheetField(label: 'Room / Location', child: TextField(
            controller: _roomCtrl,
            decoration: _inputDec(context, 'e.g. AB2 - 304'),
          )),
          const SizedBox(height: 14),
          _SheetField(label: 'Teacher (optional)', child: TextField(
            controller: _teacherCtrl,
            decoration: _inputDec(context, 'e.g. Dr. Sharma'),
          )),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.repeat_rounded, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Repeat every week', style: TextStyle(fontSize: 14, color: AppColors.text(context)))),
            Switch(value: _isWeekly, onChanged: (v) => setState(() => _isWeekly = v), activeThumbColor: CalColors.classClr),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: CalColors.classClr,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('SAVE CLASS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED SHEET HELPERS
// ═══════════════════════════════════════════════════════════════════════════

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;

  const _SheetScaffold({required this.title, required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accentColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final Widget child;

  const _SheetField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TapField extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _TapField({required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.isDark(context) ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.isDark(context) ? const Color(0xFF404040) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text(context),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDec(BuildContext context, String? hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.subtext(context), fontSize: 13),
      filled: true,
      fillColor: AppColors.isDark(context) ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.isDark(context) ? const Color(0xFF404040) : AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppColors.isDark(context) ? const Color(0xFF404040) : AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
