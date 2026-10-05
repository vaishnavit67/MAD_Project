import 'package:flutter/material.dart';
import '../models/campus_location.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final LocationService _locationService = LocationService();
  final TextEditingController searchController = TextEditingController();

  List<CampusLocation> allLocations = campusLocations;
  List<CampusLocation> filteredLocations = [];

  String selectedCategory = 'All';
  String startLocation = 'My Current GPS Location';
  List<String> intermediateStops = [];

  final List<String> categories = [
    'All',
    'Academic Block',
    'Canteen',
    'Library',
    'Girls Hostel',
    'Boys Hostel',
    'ATM',
    'Laboratory',
    'Hall',
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Academic Block':
        return Icons.school_outlined;
      case 'Canteen':
      case 'Cafe':
        return Icons.restaurant_outlined;
      case 'Library':
        return Icons.local_library_outlined;
      case 'Sports Ground':
      case 'Sports Facility':
        return Icons.sports_soccer_outlined;
      case 'Store':
        return Icons.store_outlined;
      case 'Medical Facility':
        return Icons.local_hospital_outlined;
      case 'Hall':
        return Icons.meeting_room_outlined;
      case 'Girls Hostel':
      case 'Boys Hostel':
      case 'Staff Quarters':
        return Icons.home_outlined;
      case 'Park':
        return Icons.park_outlined;
      case 'Bank':
        return Icons.account_balance_outlined;
      case 'ATM':
        return Icons.atm_outlined;
      case 'Laboratory':
        return Icons.science_outlined;
      case 'Guest House':
        return Icons.hotel_outlined;
      case 'Administrative Block':
        return Icons.business_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    filteredLocations = allLocations;
    searchController.addListener(_applyFilters);
    _fetchLocations();
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

  void _quickSearch(String keyword) {
    setState(() {
      selectedCategory = 'All';
      searchController.text = keyword;
    });
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

  void _removeStop(int index) {
    setState(() {
      intermediateStops.removeAt(index);
    });
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

  @override
  void dispose() {
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteLocations = allLocations.where((loc) => loc.isFavorite).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF101828)),
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
            color: Color(0xFF101828),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GMAPS-STYLE ROUTE PLANNER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Start Point Dropdown
                        Row(
                          children: [
                            const Icon(Icons.my_location, color: Color(0xFF155EEF), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _selectStartPointModal,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF2FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          startLocation,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF101828),
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF155EEF)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Intermediate Stops List
                        if (intermediateStops.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...intermediateStops.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final stop = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Stop ${idx + 1}: $stop',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () => _removeStop(idx),
                                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 10),

                        // Add Stop Button Row
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _addIntermediateStop,
                              icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF155EEF)),
                              label: const Text(
                                'Add Stop in between',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF155EEF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // NEAREST CAMPUS SPOTS RADAR SHORTCUTS (WOW FEATURE)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _nearestSpotChip('⚡ Nearest ATM (180m)', 'ICICI ATM', 'ATM'),
                        _nearestSpotChip('🍔 Main Canteen (280m)', 'Main Canteen', 'Canteen'),
                        _nearestSpotChip('🏥 Campus Clinic (420m)', 'Clinic', 'Medical Facility'),
                        _nearestSpotChip('📚 Library (850m)', 'Central Library', 'Library'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search food, academic, cash, hostels...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF155EEF),
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.black54),
                                onPressed: () {
                                  searchController.clear();
                                },
                              )
                            : const Icon(Icons.tune, color: Colors.black45),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Quick Keyword Synonym Chips (Food, Academic, Cash, Hostels, Sports)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _quickKeywordChip('🍔 Food', 'food'),
                        _quickKeywordChip('📚 Academic', 'academic'),
                        _quickKeywordChip('💳 Cash/ATM', 'cash'),
                        _quickKeywordChip('🏡 Hostels', 'hostel'),
                        _quickKeywordChip('⚽ Sports', 'sports'),
                        _quickKeywordChip('🏥 Health', 'health'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category Filter Pills Bar
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat == selectedCategory;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = cat;
                              _applyFilters();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF155EEF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF155EEF) : const Color(0xFFE4E7EC),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Pinned Favorites Horizontal Bar
            if (favoriteLocations.isNotEmpty && searchController.text.isEmpty && selectedCategory == 'All') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_outline, size: 18, color: Color(0xFF155EEF)),
                    const SizedBox(width: 6),
                    const Text(
                      'Pinned Favorites',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${favoriteLocations.length} places',
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: favoriteLocations.length,
                  itemBuilder: (context, index) {
                    final fav = favoriteLocations[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/destination',
                          arguments: <String, dynamic>{
                            'name': fav.name,
                            'category': fav.category,
                            'origin': startLocation,
                            'stops': List<String>.from(intermediateStops),
                          },
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE4E7EC)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getCategoryIcon(fav.category),
                                color: const Color(0xFF155EEF),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fav.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  fav.distance,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Destinations List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    searchController.text.isEmpty && selectedCategory == 'All'
                        ? 'All Campus Destinations'
                        : 'Found Destinations',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${filteredLocations.length} locations',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Destinations ListView
            Expanded(
              child: filteredLocations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No campus locations found', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Try typing food, academic, cash, or hostel', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = filteredLocations[index];

                        return _destinationCard(
                          location: location,
                          icon: _getCategoryIcon(location.category),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nearestSpotChip(String label, String destName, String category) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/destination',
          arguments: <String, dynamic>{
            'name': destName,
            'category': category,
            'origin': startLocation,
            'stops': List<String>.from(intermediateStops),
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF166534),
          ),
        ),
      ),
    );
  }

  Widget _quickKeywordChip(String label, String keyword) {
    final isSelected = searchController.text.toLowerCase() == keyword;

    return GestureDetector(
      onTap: () => _quickSearch(keyword),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF155EEF) : const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF155EEF),
          ),
        ),
      ),
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

  Widget _destinationCard({
    required CampusLocation location,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () {
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF155EEF),
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                location.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            if (location.buildingCode.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  location.buildingCode,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                location.category,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.black38)),
              const SizedBox(width: 8),
              Icon(Icons.directions_walk, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 3),
              Text(
                location.distance,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            location.isFavorite ? Icons.bookmark : Icons.bookmark_border,
            color: location.isFavorite ? const Color(0xFF155EEF) : Colors.black38,
            size: 20,
          ),
          onPressed: () => _toggleFavorite(location),
        ),
      ),
    );
  }
}