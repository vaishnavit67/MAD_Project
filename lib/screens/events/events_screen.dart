import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/mock_data.dart';
import '../../models/event.dart';
import 'event_detail_page.dart';
import 'event_registration_service.dart';

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
  if (e.isPast) return 'Completed';
  if (isRegistered) return 'Registered';
  if (e.availableSeats == 0) return 'Full';
  if (e.availableSeats <= 20) return 'Filling Fast';
  return 'Open';
}

Color _eventStatusColor(Event e, bool isRegistered) {
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<Event> get _filteredEvents {
    return MockData.events.where((e) {
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Events',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22),
        ),

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
      body: TabBarView(
        controller: _tabController,
        children: [
          _DiscoverTab(
            filteredEvents: _filteredEvents,
            searchCtrl: _searchCtrl,
            selectedCategory: _selectedCategory,
            selectedTime: _selectedTime,
            hasActiveFilters: _hasActiveFilters,
            onCategorySelected: (c) => setState(() => _selectedCategory = c),
            onTimeSelected: (t) => setState(() => _selectedTime = t),
            onClearFilters: _clearFilters,
            onOpenEvent: _openEvent,
            regService: _regService,
          ),
          _MyEventsTab(
            regService: _regService,
            onOpenEvent: _openEvent,
            onExplore: () => _tabController.animateTo(0),
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
    required this.regService,
  });

  @override
  Widget build(BuildContext context) {
    final featured = MockData.events.where((e) => e.featured && !e.isPast).firstOrNull;

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
                  decoration: InputDecoration(
                    hintText: 'Search events, organizers, locations...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    suffixIcon: searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                            onPressed: () { searchCtrl.clear(); },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
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
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.textSecondary,
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
  final ValueChanged<Event> onOpenEvent;
  final VoidCallback onExplore;

  const _MyEventsTab({
    required this.regService,
    required this.onOpenEvent,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final all = regService.getRegisteredEvents();
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

  const _EventCard({required this.event, required this.isRegistered, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = eventCategoryColor(event.category);
    final statusLabel = _eventStatusLabel(event, isRegistered);
    final statusColor = _eventStatusColor(event, isRegistered);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color banner + icon
            Container(
              height: 80,
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
                  Center(
                    child: Icon(eventCategoryIcon(event.category), size: 40, color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  Positioned(
                    top: 10, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, right: 12,
                    child: Container(
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('d MMM').format(event.date)} • ${event.timeString}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                      Row(
                        children: [
                          Text(
                            'By ${event.organizer}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
                        ],
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
          color: dimmed ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
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
                      color: dimmed ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormat('d MMM yyyy').format(event.date)} • ${event.timeString}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
