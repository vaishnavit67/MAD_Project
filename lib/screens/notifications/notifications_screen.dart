import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../../../features/notifications/services/in_app_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final InAppNotificationService _service = InAppNotificationService();

  @override
  void initState() {
    super.initState();
    _refreshBackend();
  }

  Future<void> _refreshBackend() async {
    await _service.fetchNotificationsFromBackend();
    if (mounted) setState(() {});
  }

  void _markAllAsRead() async {
    await _service.markAllAsRead();
    setState(() {});
  }

  void _markRead(NotificationModel n) async {
    if (!n.isRead) {
      await _service.markAsRead(n.id);
      setState(() {});
    }
  }

  void _delete(NotificationModel n) async {
    await _service.deleteNotification(n.id);
    setState(() {});
  }

  // ── Grouping ──────────────────────────────────────────────────────────────

  Map<String, List<NotificationModel>> _groupByDate(List<NotificationModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<NotificationModel>>{};
    for (final n in items) {
      final d = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      String label;
      if (d.isAtSameMomentAs(today)) {
        label = 'TODAY';
      } else if (d.isAtSameMomentAs(yesterday)) {
        label = 'YESTERDAY';
      } else {
        label = 'EARLIER';
      }
      groups.putIfAbsent(label, () => []).add(n);
    }
    return groups;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final notifications = _service.getNotifications();
    final groups = _groupByDate(notifications);
    final unreadCount = _service.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBackend,
        child: notifications.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _emptyState(),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: _buildItemCount(groups),
                itemBuilder: (_, i) => _buildItem(groups, i),
              ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.featureIconBg1,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you have reminders, event updates,\nor task activity, they\'ll appear here.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── List building ─────────────────────────────────────────────────────────

  // We flatten groups into a single list with section headers interleaved.
  static const _sectionOrder = ['TODAY', 'YESTERDAY', 'EARLIER'];

  int _buildItemCount(Map<String, List<NotificationModel>> groups) {
    int count = 0;
    for (final section in _sectionOrder) {
      final items = groups[section];
      if (items != null && items.isNotEmpty) {
        count += 1 + items.length; // header + items
      }
    }
    return count;
  }

  Widget _buildItem(Map<String, List<NotificationModel>> groups, int index) {
    int offset = 0;
    for (final section in _sectionOrder) {
      final items = groups[section];
      if (items == null || items.isEmpty) continue;
      if (index == offset) {
        // Section header
        return _sectionHeader(section);
      }
      if (index <= offset + items.length) {
        final n = items[index - offset - 1];
        return _notificationTile(n);
      }
      offset += 1 + items.length;
    }
    return const SizedBox.shrink();
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Notification tile ─────────────────────────────────────────────────────

  Widget _notificationTile(NotificationModel n) {
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _delete(n),
      child: GestureDetector(
        onTap: () => _markRead(n),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : AppColors.featureIconBg1.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: !n.isRead
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.15))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconBgColor(n.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconData(n.type), size: 20, color: _iconColor(n.type)),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(n.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: n.isRead ? AppColors.textSecondary : AppColors.primary,
                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: n.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (!n.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Type-based helpers ────────────────────────────────────────────────────

  IconData _iconData(String type) {
    switch (type) {
      case 'task':     return Icons.check_circle_rounded;
      case 'event':    return Icons.event_rounded;
      case 'reminder': return Icons.alarm_rounded;
      case 'message':  return Icons.message_rounded;
      case 'system':   return Icons.notifications_rounded;
      default:         return Icons.notifications_rounded;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'task':     return const Color(0xFF2196F3);
      case 'event':    return AppColors.primary;
      case 'reminder': return const Color(0xFFF57C00);
      case 'message':  return const Color(0xFF26A69A);
      case 'system':   return AppColors.textSecondary;
      default:         return AppColors.primary;
    }
  }

  Color _iconBgColor(String type) {
    switch (type) {
      case 'task':     return const Color(0xFFE3F2FD);
      case 'event':    return AppColors.featureIconBg1;
      case 'reminder': return const Color(0xFFFFF3E0);
      case 'message':  return const Color(0xFFE0F2F1);
      case 'system':   return AppColors.featureIconBg1;
      default:         return AppColors.featureIconBg1;
    }
  }

  String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(ts);
  }
}
