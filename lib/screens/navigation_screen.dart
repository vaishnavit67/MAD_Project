import 'package:flutter/material.dart';
import '../models/campus_location.dart';
import '../services/location_service.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController searchController = TextEditingController();

  int _selectedNavTab = 0; // 0: Explore, 1: Plan Route, 2: History

  List<CampusLocation> allLocations = campusLocations;
  List<CampusLocation> filteredLocations = [];

  String selectedCategory = 'All';
  String startLocation = 'My Current GPS Location';
  String routeDestination = 'Central Library';
  List<String> intermediateStops = [];

  final List<String> categories = [
    'All',
    'Academic Block',
    'Canteen',
    'Boys Hostel',
    'Girls Hostel',
    'Library',
    'ATM',
    'Laboratory',
    'Hall',
  ];

  @override
  void initState() {
    super.initState();
    filteredLocations = allLocations;
    searchController.addListener(_applyFilters);
    HistoryService.instance.addListener(_onHistoryUpdated);
    _fetchLocations();
  }

  @override
  void dispose() {
    HistoryService.instance.removeListener(_onHistoryUpdated);
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }

  void _onHistoryUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchLocations() async {
    final fetched = await _locationService.getLocations();
    if (mounted && fetched.isNotEmpty) {
      setState(() {
        allLocations = fetched;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    final query = searchController.text;
    setState(() {
      filteredLocations = _locationService.filterLocations(
        locations: allLocations,
        query: query,
        category: selectedCategory,
      );
    });
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
      case 'Boys Hostel':
        return Icons.boy_rounded;
      case 'Girls Hostel':
        return Icons.girl_rounded;
      case 'Sports Ground':
      case 'Sports Facility':
        return Icons.sports_soccer_outlined;
      case 'Store':
        return Icons.store_outlined;
      case 'Medical Facility':
        return Icons.local_hospital_outlined;
      case 'Hall':
        return Icons.meeting_room_outlined;
      case 'Staff Quarters':
        return Icons.home_outlined;
      case 'Park':
        return Icons.park_outlined;
      case 'Bank':
        return Icons.account_balance_outlined;
      case 'ATM':
        return Icons.credit_card_outlined;
      case 'Laboratory':
        return Icons.science_outlined;
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
      case 'Boys Hostel':
        return const Color(0xFF0284C7);
      case 'Girls Hostel':
        return const Color(0xFFDB2777);
      case 'Sports Ground':
      case 'Sports Facility':
        return const Color(0xFF7C3AED);
      case 'ATM':
      case 'Bank':
        return const Color(0xFF0891B2);
      default:
        return const Color(0xFF475569);
    }
  }

  void _toggleFavorite(CampusLocation location) {
    setState(() {
      final index = allLocations.indexWhere((loc) => loc.name == location.name);
      if (index != -1) {
        allLocations[index] = location.copyWith(isFavorite: !location.isFavorite);
        _applyFilters();
      }
    });
  }

  void _openCategoryDetailModal(String categoryName) {
    final catLocations = allLocations.where((loc) {
      if (categoryName == 'Canteen') {
        return loc.category == 'Canteen' || loc.category == 'Cafe';
      } else if (categoryName == 'Boys Hostel') {
        return loc.category == 'Boys Hostel' || loc.name.toLowerCase().contains('boys');
      } else if (categoryName == 'Girls Hostel') {
        return loc.category == 'Girls Hostel' || loc.name.toLowerCase().contains('girls');
      }
      return loc.category.toLowerCase().contains(categoryName.toLowerCase());
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(categoryName).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getCategoryIcon(categoryName), color: _getCategoryColor(categoryName)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${catLocations.length} locations on campus',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: catLocations.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final loc = catLocations[index];
                    return _buildCleanLocationTile(loc);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addIntermediateStop() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Intermediate Stop',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: allLocations.length,
                  itemBuilder: (context, index) {
                    final loc = allLocations[index];
                    return ListTile(
                      leading: Icon(_getCategoryIcon(loc.category), color: const Color(0xFF155EEF)),
                      title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(loc.category),
                      onTap: () {
                        setState(() {
                          if (!intermediateStops.contains(loc.name)) {
                            intermediateStops.add(loc.name);
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectStartPointModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Starting Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.my_location, color: Color(0xFF155EEF)),
                title: const Text('My Current GPS Location', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  setState(() => startLocation = 'My Current GPS Location');
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: allLocations.length,
                  itemBuilder: (context, index) {
                    final loc = allLocations[index];
                    return ListTile(
                      leading: Icon(_getCategoryIcon(loc.category), color: const Color(0xFF155EEF)),
                      title: Text(loc.name),
                      subtitle: Text(loc.category),
                      onTap: () {
                        setState(() => startLocation = loc.name);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectDestinationModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Final Destination',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: allLocations.length,
                  itemBuilder: (context, index) {
                    final loc = allLocations[index];
                    return ListTile(
                      leading: Icon(_getCategoryIcon(loc.category), color: const Color(0xFF155EEF)),
                      title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${loc.category} • ${loc.distance}'),
                      onTap: () {
                        setState(() => routeDestination = loc.name);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Campus Navigation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Trip History',
            icon: const Icon(Icons.history_rounded, color: Color(0xFF155EEF)),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildSelectedTabContent(),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildBottomNavTab(0, 'Explore', Icons.explore_outlined, Icons.explore_rounded),
              _buildBottomNavTab(1, 'Plan Route', Icons.alt_route_outlined, Icons.alt_route_rounded),
              _buildBottomNavTab(2, 'Recents', Icons.schedule_outlined, Icons.schedule_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavTab(int index, String label, IconData icon, IconData activeIcon) {
    final isSelected = _selectedNavTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedNavTab = index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF155EEF).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected ? const Color(0xFF155EEF) : const Color(0xFF64748B),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF155EEF) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedNavTab) {
      case 1:
        return _buildRoutePlannerPage();
      case 2:
        return _buildRecentsPage();
      case 0:
      default:
        return _buildExplorePage();
    }
  }

  // TAB 0: EXPLORE PAGE (Boys Hostel followed by Girls Hostel in Category Grid)
  Widget _buildExplorePage() {
    return SingleChildScrollView(
      key: const ValueKey('explore_tab'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEARCH INPUT FIELD
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search campus buildings, canteens, hostels...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.black54, size: 18),
                        onPressed: () => searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // CATEGORY GRID TILES (Boys Hostel followed by Girls Hostel)
          const Text(
            'Explore Categories',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildCategoryTile('Academic Block', 'Academic', Icons.school_outlined, const Color(0xFF2563EB))),
              const SizedBox(width: 10),
              Expanded(child: _buildCategoryTile('Canteen', 'Dining', Icons.restaurant_outlined, const Color(0xFFD97706))),
              const SizedBox(width: 10),
              Expanded(child: _buildCategoryTile('Boys Hostel', 'Boys Hostel', Icons.boy_rounded, const Color(0xFF0284C7))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildCategoryTile('Girls Hostel', 'Girls Hostel', Icons.girl_rounded, const Color(0xFFDB2777))),
              const SizedBox(width: 10),
              Expanded(child: _buildCategoryTile('Sports Facility', 'Sports & Gym', Icons.sports_soccer_outlined, const Color(0xFF7C3AED))),
              const SizedBox(width: 10),
              Expanded(child: _buildCategoryTile('ATM', 'ATMs & Cash', Icons.credit_card_outlined, const Color(0xFF0891B2))),
            ],
          ),

          const SizedBox(height: 20),

          // RECENTLY VISITED CAROUSEL (IF ANY)
          _buildRecentShortcutsSection(),

          // DESTINATIONS LIST HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedCategory == 'All' ? 'All Campus Destinations' : '$selectedCategory Locations',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                '${filteredLocations.length} places',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // DESTINATIONS LIST
          filteredLocations.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No locations found matching search.', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredLocations.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _buildCleanLocationTile(filteredLocations[index]);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String catKey, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _openCategoryDetailModal(catKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: DEDICATED MULTI-STOP ROUTE PLANNER PAGE
  Widget _buildRoutePlannerPage() {
    return SingleChildScrollView(
      key: const ValueKey('route_planner_tab'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.alt_route_rounded, color: Color(0xFF155EEF), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Multi-Stop Route Builder',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Plan optimal walking paths with intermediate stops',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // START LOCATION ROW
                const Text('Starting Point', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _selectStartPointModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location_rounded, color: Color(0xFF155EEF), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            startLocation,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
                      ],
                    ),
                  ),
                ),

                // INTERMEDIATE STOPS
                if (intermediateStops.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Intermediate Stops', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  ...intermediateStops.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final stop = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined, color: Color(0xFFD97706), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Stop ${idx + 1}: $stop',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => intermediateStops.removeAt(idx)),
                              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _addIntermediateStop,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF155EEF)),
                  label: const Text('+ Add Stop in Between', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF155EEF))),
                ),

                const SizedBox(height: 12),

                // DESTINATION ROW
                const Text('Final Destination', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _selectDestinationModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            routeDestination,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // LAUNCH ROUTE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155EEF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Calculate & Navigate Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () {
                      HistoryService.instance.addHistory(
                        locationName: routeDestination,
                        category: 'Campus Location',
                        origin: startLocation,
                        stops: List<String>.from(intermediateStops),
                      );
                      Navigator.pushNamed(
                        context,
                        '/destination',
                        arguments: <String, dynamic>{
                          'name': routeDestination,
                          'category': 'Campus Location',
                          'origin': startLocation,
                          'stops': List<String>.from(intermediateStops),
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: RECENTS & SAVED PAGE
  Widget _buildRecentsPage() {
    final recentItems = HistoryService.instance.items;

    return recentItems.isEmpty
        ? Center(
            key: const ValueKey('recents_empty'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_outlined, size: 40, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                const Text('No Recent Trips Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                const Text('Places you navigate to will appear here.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          )
        : ListView.separated(
            key: const ValueKey('recents_tab'),
            padding: const EdgeInsets.all(16),
            itemCount: recentItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = recentItems[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(item.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getCategoryIcon(item.category), color: _getCategoryColor(item.category), size: 20),
                  ),
                  title: Text(item.locationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${item.category} • ${item.distance} (${item.walkingTime})', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.navigation_rounded, color: Color(0xFF155EEF), size: 20),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/destination',
                      arguments: <String, dynamic>{
                        'name': item.locationName,
                        'category': item.category,
                        'origin': item.origin,
                        'stops': item.stops,
                      },
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildRecentShortcutsSection() {
    final historyItems = HistoryService.instance.items.take(5).toList();
    if (historyItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Shortcuts',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            InkWell(
              onTap: () => setState(() => _selectedNavTab = 2),
              child: const Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF155EEF))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              final item = historyItems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/destination',
                    arguments: <String, dynamic>{
                      'name': item.locationName,
                      'category': item.category,
                      'origin': startLocation,
                      'stops': List<String>.from(intermediateStops),
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(item.category), color: const Color(0xFF155EEF), size: 16),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.locationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(item.walkingTime, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildCleanLocationTile(CampusLocation location) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          HistoryService.instance.addFromLocation(
            location,
            origin: startLocation,
            stops: List<String>.from(intermediateStops),
          );
          Navigator.pushNamed(
            context,
            '/destination',
            arguments: <String, dynamic>{
              'name': location.name,
              'category': location.category,
              'origin': startLocation,
              'stops': List<String>.from(intermediateStops),
            },
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(location.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getCategoryIcon(location.category), color: _getCategoryColor(location.category), size: 20),
        ),
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
        subtitle: Text(
          '${location.category} • ${location.distance} (${location.walkingTime})',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: IconButton(
          icon: Icon(
            location.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            color: location.isFavorite ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
            size: 22,
          ),
          onPressed: () => _toggleFavorite(location),
        ),
      ),
    );
  }
}