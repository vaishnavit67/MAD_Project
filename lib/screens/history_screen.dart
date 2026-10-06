import 'package:flutter/material.dart';
import '../models/navigation_history_item.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService.instance;
  final TextEditingController _searchController = TextEditingController();

  int _selectedTab = 0; // 0: Recents, 1: Starred, 2: Notes
  String _selectedCategory = 'All';
  String _sortBy = 'Newest';

  final List<String> _categories = [
    'All',
    'Academic Block',
    'Canteen',
    'Library',
    'Sports Facility',
    'Hall',
    'ATM',
  ];

  @override
  void initState() {
    super.initState();
    _historyService.addListener(_onHistoryChanged);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _historyService.removeListener(_onHistoryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onHistoryChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    setState(() {});
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Academic Block':
        return Icons.school_outlined;
      case 'Canteen':
      case 'Cafe':
        return Icons.restaurant_outlined;
      case 'Library':
        return Icons.local_library_outlined;
      case 'Sports Facility':
      case 'Sports Ground':
        return Icons.sports_soccer_outlined;
      case 'Hall':
        return Icons.meeting_room_outlined;
      case 'ATM':
      case 'Bank':
        return Icons.credit_card_outlined;
      case 'Girls Hostel':
      case 'Boys Hostel':
        return Icons.hotel_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Academic Block':
        return const Color(0xFF2563EB);
      case 'Canteen':
      case 'Cafe':
        return const Color(0xFFD97706);
      case 'Library':
        return const Color(0xFF059669);
      case 'Sports Facility':
        return const Color(0xFF7C3AED);
      case 'Hall':
        return const Color(0xFFDB2777);
      case 'ATM':
        return const Color(0xFF0891B2);
      default:
        return const Color(0xFF475569);
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes == 0 ? 1 : diff.inMinutes;
      return '$mins min ago';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minute $period';
    } else if (diff.inDays < 2 || (diff.inHours < 48 && dt.day == now.day - 1)) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  void _showItemOptionsModal(NavigationHistoryItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(item.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getCategoryIcon(item.category), color: _getCategoryColor(item.category)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.locationName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${item.category} • ${item.distance} (${item.walkingTime})',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Action Options List
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.navigation_rounded, color: AppTheme.primaryBlue, size: 20),
                ),
                title: const Text('Start Directions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text('Re-navigate from ${item.origin}', style: const TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToDestination(item);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                title: Text(
                  item.isFavorite ? 'Remove from Saved Places' : 'Save to Pinned Favorites',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                onTap: () {
                  _historyService.toggleFavorite(item.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF475569), size: 20),
                ),
                title: Text(
                  item.userNote.isNotEmpty ? 'Edit Note' : 'Add Note',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  item.userNote.isNotEmpty ? item.userNote : 'Add room numbers or study tips',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddNoteDialog(item);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                ),
                title: const Text('Remove from Recents', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.redAccent)),
                onTap: () {
                  _historyService.removeHistory(item.id);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showAddNoteDialog(NavigationHistoryItem item) {
    final controller = TextEditingController(text: item.userNote);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Note for ${item.locationName}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal note or room reminder:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Room 304, study table near window',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _historyService.updateNote(item.id, controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Clear Navigation History', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Clear all recently visited places from your trip history?',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _historyService.clearHistory();
                Navigator.pop(context);
              },
              child: const Text('Clear History'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToDestination(NavigationHistoryItem item) {
    Navigator.pushNamed(
      context,
      '/destination',
      arguments: {
        'name': item.locationName,
        'category': item.category,
        'origin': item.origin,
        'stops': item.stops,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesOnly = _selectedTab == 1;

    List<NavigationHistoryItem> filtered = _historyService.getFilteredHistory(
      query: _searchController.text,
      category: _selectedCategory,
      favoritesOnly: favoritesOnly,
      sortBy: _sortBy,
    );

    if (_selectedTab == 2) {
      filtered = filtered.where((item) => item.userNote.isNotEmpty).toList();
    }

    final analytics = _historyService.getAnalyticsSummary();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recent Locations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569)),
            onSelected: (val) {
              if (val == 'clear') {
                _confirmClearAll();
              } else {
                setState(() => _sortBy = val);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Newest',
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 18, color: _sortBy == 'Newest' ? AppTheme.primaryBlue : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Sort: Newest'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Most Visited',
                child: Row(
                  children: [
                    Icon(Icons.repeat_rounded, size: 18, color: _sortBy == 'Most Visited' ? AppTheme.primaryBlue : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Sort: Top Visited'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Clear History', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEGMENTED TAB BAR (Apple Maps Style)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildSegmentTab(0, 'Recents (${_historyService.items.length})'),
                        _buildSegmentTab(1, 'Saved ⭐️ (${analytics.favoriteCount})'),
                        _buildSegmentTab(2, 'Notes 📝'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // SEARCH INPUT
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search places, routes, notes...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => _searchController.clear(),
                            child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // SUBTLE STATS OVERVIEW BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_walk_rounded, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        '${analytics.totalDistanceKm} km walked',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  Text(
                    '${analytics.totalVisits} visits total',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // CATEGORY CHIPS SCROLLER
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(cat),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryBlue : const Color(0xFF475569),
                      ),
                      selectedColor: const Color(0xFFEAF2FF),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : 'All';
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // MAIN LIST AREA
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildCleanHistoryCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.primaryBlue : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanHistoryCard(NavigationHistoryItem item) {
    final catColor = _getCategoryColor(item.category);
    final catIcon = _getCategoryIcon(item.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isFavorite ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
          width: item.isFavorite ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDestination(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: catColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Location Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.locationName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(item.timestamp),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.category} • ${item.distance} • ${item.walkingTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (item.stops.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Via ${item.stops.join(', ')}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      // Personal Note Chip
                      if (item.userNote.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFD97706), size: 12),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.userNote,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Direction & Options Action Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.navigation_rounded, color: AppTheme.primaryBlue, size: 22),
                      tooltip: 'Directions',
                      onPressed: () => _navigateToDestination(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
                      onPressed: () => _showItemOptionsModal(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Places Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your search or tab filters to view recent campus destinations.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
