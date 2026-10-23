import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../data/mock_data.dart';
import '../../models/event.dart';
import 'event_detail_page.dart';
import 'event_registration_service.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/image_upload_service.dart';

// ── Category helpers (also imported by EventDetailPage) ─────────────────────

Color eventCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'hackathon':  return const Color(0xFFE65100);
    case 'technology': return const Color(0xFF1565C0);
    case 'workshop':   return const Color(0xFF6A1B9A);
    case 'cultural':   return const Color(0xFFAD1457);
    case 'sports':     return const Color(0xFF2E7D32);
    case 'club':       return const Color(0xFF00838F);
    case 'career':     return const Color(0xFFF57F17);
    case 'academic':   return const Color(0xFF283593);
    default:           return AppColors.primary;
  }
}

IconData eventCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'hackathon':  return Icons.code_rounded;
    case 'technology': return Icons.computer_rounded;
    case 'workshop':   return Icons.build_circle_rounded;
    case 'cultural':   return Icons.music_note_rounded;
    case 'sports':     return Icons.sports_cricket_rounded;
    case 'club':       return Icons.groups_rounded;
    case 'career':     return Icons.work_outline_rounded;
    case 'academic':   return Icons.school_rounded;
    default:           return Icons.event_rounded;
  }
}

String _eventStatusLabel(Event e, bool isRegistered) {
  final isOrg = AuthService.isFaculty &&
      (e.createdBy == AuthService.currentUser?.id ||
       e.createdByName == AuthService.currentUser?.name ||
       (AuthService.currentUser?.name.isNotEmpty == true && e.organizer.toLowerCase().contains(AuthService.currentUser!.name.toLowerCase())) ||
       e.organizer.toLowerCase().contains('faculty') ||
       e.organizer.toLowerCase().contains('coordinator'));
  if (isOrg) return 'Host / Org';
  if (e.isPast) return 'Completed';
  if (isRegistered) return 'Registered';
  if (e.availableSeats == 0) return 'Full';
  if (e.availableSeats <= 20) return 'Filling Fast';
  return 'Open';
}

Color _eventStatusColor(Event e, bool isRegistered) {
  final isOrg = AuthService.isFaculty &&
      (e.createdBy == AuthService.currentUser?.id ||
       e.createdByName == AuthService.currentUser?.name ||
       (AuthService.currentUser?.name.isNotEmpty == true && e.organizer.toLowerCase().contains(AuthService.currentUser!.name.toLowerCase())) ||
       e.organizer.toLowerCase().contains('faculty') ||
       e.organizer.toLowerCase().contains('coordinator'));
  if (isOrg) return const Color(0xFF7C3AED);
  if (e.isPast) return AppColors.textSecondary;
  if (isRegistered) return AppColors.success;
  if (e.availableSeats == 0) return AppColors.error;
  if (e.availableSeats <= 20) return const Color(0xFFF57C00);
  return AppColors.success;
}

// ═══════════════════════════════════════════════════════════════════════════
// EVENTS SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventRegistrationService _regService = EventRegistrationService();
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedTime = 'All';
  List<Event> _eventsList = List.from(MockData.events);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
    _fetchBackendEvents();
    _regService.fetchUserRegistrations().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchBackendEvents() async {
    try {
      final backendEvents = await EventService.instance.getEvents();
      if (mounted && backendEvents.isNotEmpty) {
        setState(() {
          _eventsList = backendEvents;
        });
      }
    } catch (e) {
      debugPrint('[EventsScreen] Error loading events: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<Event> get _filteredEvents {
    return _eventsList.where((e) {
      // Role-specific filtering: Visitors should only see public/open events, not internal faculty/academic sessions
      if (AuthService.isVisitor) {
        final cat = e.category.toLowerCase();
        if (cat == 'academic' || cat == 'faculty') {
          return false;
        }
      }
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final match = e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.organizer.toLowerCase().contains(q) ||
            e.location.toLowerCase().contains(q);
        if (!match) return false;
      }
      // Category
      if (_selectedCategory != 'All' && e.category != _selectedCategory) return false;
      // Time
      switch (_selectedTime) {
        case 'Today':
          if (!e.isToday) return false;
          break;
        case 'This Week':
          if (!e.isThisWeek) return false;
          break;
        case 'Upcoming':
          if (e.isPast) return false;
          break;
        case 'Past':
          if (!e.isPast) return false;
          break;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.isPast != b.isPast) return a.isPast ? 1 : -1;
        return a.date.compareTo(b.date);
      });
  }

  void _clearFilters() => setState(() {
        _searchQuery = '';
        _searchCtrl.clear();
        _selectedCategory = 'All';
        _selectedTime = 'All';
      });

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedTime != 'All';

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openEvent(Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
    );
    setState(() {}); // refresh registration state after returning
  }

  void _showScanOrJoinDialog(BuildContext context) {
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.card(sheetCtx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan & Join Campus Event',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text(context),
                        ),
                      ),
                      Text(
                        'Scan QR from Teacher screen or paste link',
                        style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: codeCtrl,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                hintText: 'Paste event link or code (campusconnect://...)',
                hintStyle: TextStyle(color: AppColors.subtext(context), fontSize: 13),
                filled: true,
                fillColor: AppColors.bg(context),
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primary),
                suffixIcon: IconButton(
                  tooltip: 'Paste from clipboard',
                  icon: const Icon(Icons.content_paste_rounded, color: AppColors.primary),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text?.isNotEmpty == true) {
                      codeCtrl.text = data!.text!.trim();
                    }
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final text = codeCtrl.text.trim();
                Event? match;
                if (text.isNotEmpty) {
                  final uri = Uri.tryParse(text);
                  final idFromQuery = uri?.queryParameters['id'] ?? text;
                  match = _eventsList.firstWhere(
                    (e) => e.id.toLowerCase() == idFromQuery.toLowerCase() ||
                           e.title.toLowerCase().contains(text.toLowerCase()),
                    orElse: () => _eventsList.first,
                  );
                } else if (_eventsList.isNotEmpty) {
                  match = _eventsList.first;
                }

                if (match != null) {
                  Navigator.pop(sheetCtx);
                  _openEvent(match);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No matching campus event found for this code.')),
                  );
                }
              },
              icon: const Icon(Icons.event_available_rounded, size: 18),
              label: const Text('VIEW & JOIN EVENT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateEventDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final organizerCtrl = TextEditingController(text: AuthService.currentUser?.name ?? 'Faculty Coordinator');
    final timeCtrl = TextEditingController(text: '10:00 AM');
    final capacityCtrl = TextEditingController(text: '100');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    String selectedCategory = 'Workshop';
    XFile? pickedImage;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.event_available_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Create Campus Event',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Text(
                  'Faculty Event Management & Scheduling',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // EVENT IMAGE ATTACHMENT
                const Text('Event Poster / Banner (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final file = await ImageUploadService.instance.pickImageWithSourceSelection(context);
                    if (file != null) {
                      setModalState(() => pickedImage = file);
                    }
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: pickedImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                              SizedBox(height: 6),
                              Text('Take photo with camera or choose from gallery', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                kIsWeb
                                    ? Image.network(pickedImage!.path, fit: BoxFit.cover)
                                    : Image.file(io.File(pickedImage!.path), fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                      onPressed: () => setModalState(() => pickedImage = null),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // TITLE
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Event Title *',
                    hintText: 'e.g. Generative AI Hands-on Workshop',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // CATEGORY
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Workshop', child: Text('Workshop')),
                    DropdownMenuItem(value: 'Technology', child: Text('Technology')),
                    DropdownMenuItem(value: 'Hackathon', child: Text('Hackathon')),
                    DropdownMenuItem(value: 'Cultural', child: Text('Cultural')),
                    DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                    DropdownMenuItem(value: 'Club', child: Text('Club')),
                    DropdownMenuItem(value: 'Career', child: Text('Career')),
                    DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),

                // DATE SELECTOR
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: const Color(0xFFF8FAFC),
                  leading: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  title: const Text('Event Date', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  subtitle: Text(DateFormat('EEEE, d MMMM yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // TIME & CAPACITY
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Time (e.g. 10:00 AM)',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: capacityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Capacity',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // LOCATION
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Venue / Location *',
                    hintText: 'e.g. AB2 Seminar Hall 1st Floor',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // DESCRIPTION
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe agenda, prerequisites, learning outcomes...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                // SUBMIT BUTTON
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            final desc = descCtrl.text.trim();
                            final loc = locationCtrl.text.trim();
                            if (title.isEmpty || desc.isEmpty || loc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill out title, location, and description.')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);

                            String? uploadedPosterUrl;
                            if (pickedImage != null) {
                              final uploadRes = await ImageUploadService.instance.uploadImage(pickedImage!);
                              if (uploadRes.success) {
                                uploadedPosterUrl = uploadRes.url;
                              }
                            }

                            final cap = int.tryParse(capacityCtrl.text.trim()) ?? 100;
                            final newEvent = await EventService.instance.createEvent(
                              title: title,
                              description: desc,
                              date: selectedDate,
                              timeString: timeCtrl.text.trim(),
                              location: loc,
                              organizer: organizerCtrl.text.trim(),
                              category: selectedCategory,
                              capacity: cap,
                              availableSeats: cap,
                              imageUrl: uploadedPosterUrl,
                            );

                            if (ctx.mounted) Navigator.pop(ctx);

                            if (newEvent != null) {
                              await _fetchBackendEvents();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Event "${newEvent.title}" published and saved to MongoDB!'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to publish event. Faculty privileges required.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('CREATE & PUBLISH EVENT', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Event?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to cancel and remove "${event.title}" from campus listings?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && event.id.isNotEmpty) {
      final ok = await EventService.instance.deleteEvent(event.id);
      if (ok) {
        await _fetchBackendEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${event.title}" deleted from database.')),
          );
        }
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isFaculty = AuthService.isFaculty;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text(
          'Events',
          style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            tooltip: 'Scan / Join Event with QR Code',
            onPressed: () => _showScanOrJoinDialog(context),
          ),
          if (isFaculty)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              tooltip: 'Create New Event (Faculty)',
              onPressed: () => _showCreateEventDialog(context),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Discover'),
              Tab(text: 'My Events'),
            ],
          ),
        ),
      ),
      floatingActionButton: isFaculty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateEventDialog(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('CREATE EVENT', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _fetchBackendEvents(),
                _regService.fetchUserRegistrations(),
              ]);
            },
            child: _DiscoverTab(
              filteredEvents: _filteredEvents,
              searchCtrl: _searchCtrl,
              selectedCategory: _selectedCategory,
              selectedTime: _selectedTime,
              hasActiveFilters: _hasActiveFilters,
              onCategorySelected: (c) => setState(() => _selectedCategory = c),
              onTimeSelected: (t) => setState(() => _selectedTime = t),
              onClearFilters: _clearFilters,
              onOpenEvent: _openEvent,
              onDeleteEvent: isFaculty ? _confirmDeleteEvent : null,
              regService: _regService,
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _fetchBackendEvents(),
                _regService.fetchUserRegistrations(),
              ]);
            },
            child: _MyEventsTab(
              regService: _regService,
              eventsList: _eventsList,
              onOpenEvent: _openEvent,
              onExplore: () => _tabController.animateTo(0),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DISCOVER TAB
// ═══════════════════════════════════════════════════════════════════════════

class _DiscoverTab extends StatelessWidget {
  final List<Event> filteredEvents;
  final TextEditingController searchCtrl;
  final String selectedCategory;
  final String selectedTime;
  final bool hasActiveFilters;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onTimeSelected;
  final VoidCallback onClearFilters;
  final ValueChanged<Event> onOpenEvent;
  final ValueChanged<Event>? onDeleteEvent;
  final EventRegistrationService regService;

  static const _categories = [
    'All', 'Academic', 'Technology', 'Hackathon',
    'Workshop', 'Cultural', 'Sports', 'Club', 'Career', 'Other',
  ];
  static const _timeFilters = ['All', 'Today', 'This Week', 'Upcoming', 'Past'];

  const _DiscoverTab({
    required this.filteredEvents,
    required this.searchCtrl,
    required this.selectedCategory,
    required this.selectedTime,
    required this.hasActiveFilters,
    required this.onCategorySelected,
    required this.onTimeSelected,
    required this.onClearFilters,
    required this.onOpenEvent,
    this.onDeleteEvent,
    required this.regService,
  });

  @override
  Widget build(BuildContext context) {
    final featured = filteredEvents.where((e) => e.featured && !e.isPast).firstOrNull ??
        filteredEvents.where((e) => !e.isPast).firstOrNull;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tagline
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: Text(
                  'Discover what\'s happening on campus',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  style: TextStyle(color: AppColors.text(context)),
                  decoration: InputDecoration(
                    hintText: 'Search events, organizers, locations...',
                    hintStyle: TextStyle(color: AppColors.subtext(context), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.subtext(context)),
                    suffixIcon: searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: AppColors.subtext(context)),
                            onPressed: () { searchCtrl.clear(); },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.card(context),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.borderCol(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.borderCol(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Category chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => onCategorySelected(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.card(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.borderCol(context),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.subtext(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Time filters
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _timeFilters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final tf = _timeFilters[i];
                    final selected = selectedTime == tf;
                    return GestureDetector(
                      onTap: () => onTimeSelected(tf),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.featureIconBg1 : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          tf,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Clear filters button
              if (hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: TextButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Featured card (only in non-filtered state)
              if (featured != null && !hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _FeaturedEventCard(event: featured, onTap: () => onOpenEvent(featured)),
                ),
            ],
          ),
        ),

        // ── Events list ───────────────────────────────────────────────────
        if (filteredEvents.isEmpty)
          SliverFillRemaining(
            child: _EmptyState(
              emoji: '🎉',
              title: 'No events found',
              subtitle: 'Try adjusting your search or filters.',
              actionLabel: hasActiveFilters ? 'Clear Filters' : null,
              onAction: hasActiveFilters ? onClearFilters : null,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _EventCard(
                  event: filteredEvents[i],
                  isRegistered: regService.isRegistered(filteredEvents[i].id),
                  onTap: () => onOpenEvent(filteredEvents[i]),
                  onDelete: onDeleteEvent != null ? () => onDeleteEvent!(filteredEvents[i]) : null,
                ),
              ),
              childCount: filteredEvents.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MY EVENTS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _MyEventsTab extends StatelessWidget {
  final EventRegistrationService regService;
  final List<Event> eventsList;
  final ValueChanged<Event> onOpenEvent;
  final VoidCallback onExplore;

  const _MyEventsTab({
    required this.regService,
    required this.eventsList,
    required this.onOpenEvent,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final all = regService.getRegisteredEvents(eventsList);
    final upcoming = all.where((e) => !e.isPast).toList();
    final past = all.where((e) => e.isPast).toList();

    if (all.isEmpty) {
      return _EmptyState(
        emoji: '📅',
        title: 'No events registered',
        subtitle: 'Explore campus events and register for something interesting.',
        actionLabel: 'Explore Events',
        onAction: onExplore,
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (upcoming.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Upcoming', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _MyEventCard(event: upcoming[i], onTap: () => onOpenEvent(upcoming[i])),
              ),
              childCount: upcoming.length,
            ),
          ),
        ],
        if (past.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Past', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _MyEventCard(event: past[i], onTap: () => onOpenEvent(past[i]), dimmed: true),
              ),
              childCount: past.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FEATURED EVENT CARD
// ═══════════════════════════════════════════════════════════════════════════

class _FeaturedEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _FeaturedEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = eventCategoryColor(event.category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('⭐ FEATURED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black87)),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 12),
            Text(
              event.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('d MMM').format(event.date)} • ${event.timeString}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_rounded, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text('${event.participantCount} students going', style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View Event', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EVENT CARD (Discover list)
// ═══════════════════════════════════════════════════════════════════════════

class _EventCard extends StatelessWidget {
  final Event event;
  final bool isRegistered;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _EventCard({
    required this.event,
    required this.isRegistered,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = eventCategoryColor(event.category);
    final statusLabel = _eventStatusLabel(event, isRegistered);
    final statusColor = _eventStatusColor(event, isRegistered);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color banner + icon or image
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        event.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const SizedBox(),
                      ),
                    ),
                  if (event.imageUrl == null || event.imageUrl!.isEmpty)
                    Center(
                      child: Icon(eventCategoryIcon(event.category), size: 40, color: Colors.white.withValues(alpha: 0.25)),
                    ),
                  Positioned(
                    top: 10, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (event.featured)
                    const Positioned(
                      bottom: 8, left: 12,
                      child: Text('⭐ Featured', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.subtext(context)),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('d MMM').format(event.date)} • ${event.timeString}',
                        style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: AppColors.subtext(context)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people_rounded, size: 13, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '${event.participantCount} going',
                            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'By ${event.organizer}',
                                style: TextStyle(fontSize: 11, color: AppColors.subtext(context)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MY EVENT CARD
// ═══════════════════════════════════════════════════════════════════════════

class _MyEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final bool dimmed;

  const _MyEventCard({required this.event, required this.onTap, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? AppColors.textSecondary : eventCategoryColor(event.category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.2 : 0.03), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Left color dot
            Container(
              width: 5,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(eventCategoryIcon(event.category), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: dimmed ? AppColors.subtext(context) : AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormat('d MMM yyyy').format(event.date)} • ${event.timeString}',
                    style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: AppColors.subtext(context)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dimmed ? AppColors.border : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dimmed ? 'Past' : '✓ Registered',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: dimmed ? AppColors.textSecondary : AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
