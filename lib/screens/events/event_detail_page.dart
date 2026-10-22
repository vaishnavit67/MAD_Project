import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/event.dart';
import '../../data/mock_data.dart';
import 'event_registration_service.dart';
import 'events_screen.dart' show eventCategoryColor, eventCategoryIcon;

class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final EventRegistrationService _regService = EventRegistrationService();
  bool _isRegistering = false;

  Event get event {
    try {
      return MockData.events.firstWhere((e) => e.id == widget.event.id);
    } catch (_) {
      return widget.event;
    }
  }

  bool get isRegistered => _regService.isRegistered(event.id);
  bool get isInCalendar => _regService.isInCalendar(event.id);

  Future<void> _register() async {
    if (isRegistered || event.isPast) return;
    setState(() => _isRegistering = true);

    final confirm = await _showRegistrationDialog();
    if (!mounted) return;

    if (confirm == true) {
      await _regService.register(event);
      if (!mounted) return;
      setState(() => _isRegistering = false);
      _showSuccessSheet();
    } else {
      setState(() => _isRegistering = false);
    }
  }

  Future<void> _unregister() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unregister?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove your registration for "${event.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unregister', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _regService.unregister(event);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('You have been unregistered.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool?> _showRegistrationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Registration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("You're registering for:", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(DateFormat('d MMM yyyy').format(event.date), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(event.timeString, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm Registration', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegistrationSuccessSheet(
        event: event,
        onAddToCalendar: () async {
          await _regService.addToCalendar(event);
          if (!mounted) return;
          setState(() {});
          if (context.mounted) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(_snackBar('✅ Added to Calendar', AppColors.success));
        },
        onViewMyEvents: () {
          Navigator.pop(context);   // close sheet
          Navigator.pop(context);   // close detail page
          // The caller (EventsScreen) will switch to My Events tab
        },
      ),
    );
    setState(() {});
  }

  Future<void> _addToCalendar() async {
    if (isInCalendar) return;
    await _regService.addToCalendar(event);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(_snackBar('✅ Added to Calendar', AppColors.success));
  }

  SnackBar _snackBar(String msg, Color color) => SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    final catColor = eventCategoryColor(event.category);
    final fillPct = event.capacity > 0 ? (event.participantCount / event.capacity).clamp(0.0, 1.0) : 0.0;
    final isFull = event.availableSeats == 0 && !isRegistered;
    final canRegister = !event.isPast && !isRegistered && !isFull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar + hero image ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: catColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [catColor, catColor.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      eventCategoryIcon(event.category),
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  // badges
                  Positioned(
                    top: 90,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.featured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('⭐ FEATURED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black87)),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.category.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Date + Time
                  _infoRow(
                    Icons.calendar_today_rounded,
                    DateFormat('EEEE, d MMMM yyyy').format(event.date),
                    catColor,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.schedule_rounded,
                    event.endTimeString != null
                        ? '${event.timeString} – ${event.endTimeString}'
                        : event.timeString,
                    catColor,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(Icons.location_on_rounded, event.location, catColor),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // About
                  const Text('About Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(event.description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Organizer
                  const Text('Organized By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.groups_rounded, color: catColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.organizer,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Participants
                  const Text('Participants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.people_rounded, color: catColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${event.participantCount} students registered',
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Fill bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fillPct,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isFull ? 'Capacity full' : '${event.availableSeats} seats left',
                        style: TextStyle(
                          fontSize: 12,
                          color: isFull ? AppColors.error : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${event.capacity} total',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      // ── Bottom action bar ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add to Calendar button
            if (isRegistered)
              OutlinedButton.icon(
                onPressed: isInCalendar ? null : _addToCalendar,
                icon: Icon(
                  isInCalendar ? Icons.event_available_rounded : Icons.calendar_today_rounded,
                  size: 18,
                ),
                label: Text(
                  isInCalendar ? '✓ Added to Calendar' : 'Add to Calendar',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isInCalendar ? AppColors.success : AppColors.primary,
                  side: BorderSide(color: isInCalendar ? AppColors.success : AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            if (isRegistered) const SizedBox(height: 10),

            // Main register / unregister button
            if (event.isPast)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Event Completed',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              )
            else if (isRegistered)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                          SizedBox(width: 8),
                          Text('REGISTERED', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _unregister,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Unregister', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              )
            else if (isFull)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Registration Closed — Full',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error),
                ),
              )
            else
              ElevatedButton(
                onPressed: _isRegistering ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRegister ? catColor : AppColors.textSecondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isRegistering
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('REGISTER NOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REGISTRATION SUCCESS SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _RegistrationSuccessSheet extends StatelessWidget {
  final Event event;
  final VoidCallback onAddToCalendar;
  final VoidCallback onViewMyEvents;

  const _RegistrationSuccessSheet({
    required this.event,
    required this.onAddToCalendar,
    required this.onViewMyEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24, MediaQuery.of(context).padding.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "You're Registered! 🎉",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            '${DateFormat('d MMM yyyy').format(event.date)} • ${event.timeString}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            event.location,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddToCalendar,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: const Text('Add to Calendar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onViewMyEvents,
            icon: const Icon(Icons.event_note_rounded, size: 18),
            label: const Text('View My Events', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
