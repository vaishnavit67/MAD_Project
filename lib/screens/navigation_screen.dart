import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> get destinations {
  return campusLocations.map((location) {
    return {
        'name': location.name,
        'category': location.category,
        'icon': _getIcon(location.category),
      };
    }).toList();
  }

  List<Map<String, dynamic>> filteredDestinations = [];

  IconData _getIcon(String category) {
    switch (category) {
      case 'Academic Block':
        return Icons.school_outlined;

      case 'Canteen':
        return Icons.restaurant_outlined;

      case 'Cafe':
        return Icons.local_cafe_outlined;

      case 'Library':
        return Icons.local_library_outlined;

      case 'Sports Ground':
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

      case 'Sports Facility':
        return Icons.pool_outlined;

      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  void initState() {
    super.initState();

    // Initially show all destinations.
    filteredDestinations = destinations;

    searchController.addListener(_searchDestinations);
  }

  void _searchDestinations() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredDestinations = destinations;
      } else {
        filteredDestinations = destinations.where((destination) {
          final name = destination['name'].toString().toLowerCase();
          final category =
              destination['category'].toString().toLowerCase();

          return name.contains(query) || category.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_searchDestinations);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Campus Navigation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SEARCH
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Where do you want to go?',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF155EEF),
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                            },
                          )
                        : const Icon(Icons.tune),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 17,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // CURRENT LOCATION
              const Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: Color(0xFF155EEF),
                      child: Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Current Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'GPS location',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.gps_fixed,
                      color: Color(0xFF155EEF),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Text(
                searchController.text.isEmpty
                    ? 'Popular Destinations'
                    : 'Search Results',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: filteredDestinations.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No destinations found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Try searching for another location',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredDestinations.length,
                        itemBuilder: (context, index) {
                          final destination =
                              filteredDestinations[index];

                          return _destinationCard(
                            name: destination['name'],
                            category: destination['category'],
                            icon: destination['icon'],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _destinationCard({
    required String name,
    required String category,
    required IconData icon,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/destination',
            arguments: {
              'name': name,
              'category': category,
            },
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF155EEF),
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}