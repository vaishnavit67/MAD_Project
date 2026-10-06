import 'package:flutter/material.dart';
import '../models/campus_location.dart';
import '../models/checkpoint.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';
import '../algorithms/path_finding.dart';

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  bool isFavorite = false;
  bool _historyLogged = false;

  CampusLocation _findLocation(String name) {
    try {
      return campusLocations.firstWhere(
        (loc) => loc.name.toLowerCase() == name.toLowerCase(),
        orElse: () => CampusLocation(
          name: name,
          category: 'Campus Location',
          description: '$name is a campus location available for smart navigation.',
        ),
      );
    } catch (_) {
      return CampusLocation(
        name: name,
        category: 'Campus Location',
        description: '$name is a campus location available for smart navigation.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> arguments =
        rawArgs is Map<String, dynamic> ? rawArgs : <String, dynamic>{};

    final String name = (arguments['name'] ?? 'Central Library').toString();
    final String category = (arguments['category'] ?? 'Campus Location').toString();
    final String origin = (arguments['origin'] ?? 'My Current GPS Location').toString();

    final rawStops = arguments['stops'];
    final List<String> stops =
        rawStops is List ? rawStops.map((e) => e.toString()).toList() : <String>[];

    final location = _findLocation(name);
    final routeCheckpoints = PathFinding.getMultiStopRoute(
      startLocation: origin,
      stops: stops,
      destination: location,
    );

    if (!_historyLogged) {
      _historyLogged = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HistoryService.instance.addFromLocation(
          location,
          origin: origin,
          stops: stops,
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Destination Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Navigation History',
            icon: const Icon(Icons.history_rounded, color: Color(0xFF155EEF)),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            tooltip: 'Save Favorite',
            icon: Icon(
              isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: isFavorite ? const Color(0xFF155EEF) : Colors.black54,
            ),
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite
                        ? '$name saved to Pinned Favorites'
                        : '$name removed from Pinned Favorites',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner Container
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 64,
                            color: Color(0xFF155EEF),
                          ),
                          if (location.buildingCode.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Code: ${location.buildingCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF155EEF),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stops.isEmpty
                              ? 'Route from: $origin'
                              : 'Route from: $origin (${stops.length} stop${stops.length > 1 ? 's' : ''} in between)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Location Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.directions_walk,
                      title: location.distance,
                      subtitle: 'Distance',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      icon: Icons.access_time,
                      title: location.walkingTime,
                      subtitle: 'Walking time',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // About Section
              const Text(
                'About this location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                location.description.isNotEmpty
                    ? location.description
                    : '$name is a key campus building accessible via main pedestrian pathways.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 25),

              // Step-by-step Route Timeline
              const Text(
                'Multi-Stop Route Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              Column(
                children: List.generate(routeCheckpoints.length, (index) {
                  final Checkpoint cp = routeCheckpoints[index];
                  final bool isLast = index == routeCheckpoints.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circle Badge & Connecting Line
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cp.isStop
                                  ? const Color(0xFFF59E0B)
                                  : (isLast ? const Color(0xFF10B981) : const Color(0xFF155EEF)),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                cp.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 40,
                              color: const Color(0xFF155EEF).withValues(alpha: 0.3),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Instruction Card
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cp.isStop ? const Color(0xFFF59E0B) : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cp.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (cp.isStop)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'INTERMEDIATE STOP',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  cp.instruction,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 25),

              // Action Buttons Row (Start Navigation & Guidance Preview)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/map',
                          arguments: <String, dynamic>{
                            'name': name,
                            'category': category,
                            'origin': origin,
                            'stops': stops,
                          },
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text(
                        'Start Live GPS Navigation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF155EEF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showGuidancePreviewModal(
                            context,
                            location,
                            routeCheckpoints,
                          ),
                          icon: const Icon(Icons.record_voice_over_rounded, size: 18, color: Color(0xFF155EEF)),
                          label: const Text(
                            'Step-by-Step Preview',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF155EEF)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF155EEF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/history'),
                          icon: const Icon(Icons.history_rounded, size: 18, color: Color(0xFF475569)),
                          label: const Text(
                            'History & Notes',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF155EEF),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGuidancePreviewModal(
    BuildContext context,
    CampusLocation location,
    List<Checkpoint> checkpoints,
  ) {
    bool isAudioOn = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // MODAL HANDLE BAR
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // HEADER WITH AUDIO TOGGLE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.turn_right_rounded, color: Color(0xFF155EEF), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guidance Preview',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${checkpoints.length} turn checkpoints • ${location.distance}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Toggle Voice Prompts',
                          icon: Icon(
                            isAudioOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: isAudioOn ? const Color(0xFF155EEF) : Colors.grey,
                          ),
                          onPressed: () {
                            setModalState(() => isAudioOn = !isAudioOn);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // TURN BY TURN STEPS LIST
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: checkpoints.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final cp = checkpoints[index];
                        final isLast = index == checkpoints.length - 1;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cp.isStop ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cp.isStop
                                      ? const Color(0xFFF59E0B)
                                      : (isLast ? const Color(0xFF10B981) : const Color(0xFF155EEF)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    cp.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cp.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cp.instruction,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAudioOn)
                                const Icon(Icons.graphic_eq_rounded, color: Color(0xFF155EEF), size: 18),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // FOOTER CLOSE & NAVIGATE BUTTON
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF155EEF),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/map',
                          arguments: <String, dynamic>{
                            'name': location.name,
                            'category': location.category,
                            'origin': location.name,
                          },
                        );
                      },
                      child: const Text(
                        'Launch Interactive Map Navigation',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}