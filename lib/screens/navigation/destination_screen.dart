import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/campus_location.dart';
import '../../models/checkpoint.dart';
import '../../services/history_service.dart';
import '../../algorithms/path_finding.dart';

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
      return CampusLocation.allLocations.firstWhere(
        (l) => l.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return CampusLocation(name: name, category: 'Campus Location');
    }
  }

  Color _catColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'library':          return const Color(0xFF1565C0);
      case 'academic block':   return const Color(0xFF6A1B9A);
      case 'canteen':          return const Color(0xFFE65100);
      case 'hostel':           return const Color(0xFF00838F);
      case 'sports facility':  return const Color(0xFF2E7D32);
      case 'administrative':   return const Color(0xFF37474F);
      case 'atm':              return const Color(0xFFF57F17);
      case 'medical':          return const Color(0xFFC62828);
      case 'lab':              return const Color(0xFF283593);
      case 'parking':          return const Color(0xFF546E7A);
      case 'hall':             return const Color(0xFFAD1457);
      default:                 return AppColors.primary;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'library':          return Icons.local_library_rounded;
      case 'academic block':   return Icons.school_rounded;
      case 'canteen':          return Icons.restaurant_rounded;
      case 'hostel':           return Icons.hotel_rounded;
      case 'sports facility':  return Icons.sports_basketball_rounded;
      case 'administrative':   return Icons.business_rounded;
      case 'atm':              return Icons.atm_rounded;
      case 'medical':          return Icons.local_hospital_rounded;
      case 'lab':              return Icons.science_rounded;
      case 'parking':          return Icons.local_parking_rounded;
      case 'hall':             return Icons.theater_comedy_rounded;
      default:                 return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final name = args['name'] as String? ?? 'Unknown';
    final category = args['category'] as String? ?? 'Campus Location';
    final origin = args['origin'] as String? ?? 'My Current GPS Location';
    final stops = (args['stops'] as List?)?.cast<String>() ?? <String>[];

    final location = _findLocation(name);
    final routeCheckpoints = PathFinding.getRoute(origin: origin, destination: location, stops: stops);
    final color = _catColor(category);

    if (!_historyLogged) {
      _historyLogged = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HistoryService.instance.addFromLocation(location, origin: origin, stops: stops);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                tooltip: 'Navigation History',
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, '/history'),
              ),
              IconButton(
                tooltip: isFavorite ? 'Remove Favorite' : 'Save Favorite',
                icon: Icon(isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: Colors.white),
                onPressed: () => setState(() => isFavorite = !isFavorite),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                  ),
                  Center(child: Icon(_catIcon(category), size: 80, color: Colors.white.withValues(alpha: 0.2))),
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text(category.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                        const SizedBox(height: 8),
                        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick info row
                  Row(
                    children: [
                      _infoChip(Icons.straighten_rounded, location.distance, color),
                      const SizedBox(width: 10),
                      _infoChip(Icons.schedule_rounded, location.walkingTime, color),
                      const SizedBox(width: 10),
                      _infoChip(Icons.layers_rounded, '${location.floorCount} Floor${location.floorCount > 1 ? 's' : ''}', color),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Building code
                  if (location.buildingCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_rounded, size: 16, color: color),
                          const SizedBox(width: 6),
                          Text('Building Code: ${location.buildingCode}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Description
                  const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    location.description.isNotEmpty ? location.description : 'Campus location in $category area.',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Route info
                  const Text('Route Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  _routeRow(Icons.my_location_rounded, 'From', origin, AppColors.success),
                  if (stops.isNotEmpty)
                    _routeRow(Icons.flag_rounded, 'Via', stops.join(' → '), const Color(0xFFF57C00)),
                  _routeRow(Icons.place_rounded, 'To', name, AppColors.error),
                  const SizedBox(height: 10),

                  // Checkpoints summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.turn_right_rounded, color: color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${routeCheckpoints.length} checkpoints • ${location.distance} total',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start Live GPS Navigation button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/map', arguments: <String, dynamic>{
                          'name': name, 'category': category, 'origin': origin, 'stops': stops,
                        });
                      },
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text('Start Live GPS Navigation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Secondary action row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showGuidancePreview(context, location, routeCheckpoints),
                          icon: Icon(Icons.record_voice_over_rounded, size: 18, color: color),
                          label: Text('Step-by-Step Preview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: color),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/history'),
                          icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
                          label: const Text('History & Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _showGuidancePreview(BuildContext context, CampusLocation location, List<Checkpoint> checkpoints) {
    bool isAudioOn = true;
    final color = _catColor(location.category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.turn_right_rounded, color: color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Guidance Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              Text('${checkpoints.length} checkpoints • ${location.distance}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Toggle Voice Prompts',
                          icon: Icon(isAudioOn ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: isAudioOn ? color : AppColors.textSecondary),
                          onPressed: () => setModalState(() => isAudioOn = !isAudioOn),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: checkpoints.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final cp = checkpoints[i];
                        final isLast = i == checkpoints.length - 1;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cp.isStop ? const Color(0xFFF59E0B) : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: cp.isStop ? const Color(0xFFF59E0B) : (isLast ? AppColors.success : color),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: Text(cp.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cp.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(cp.instruction, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (isAudioOn)
                                Icon(Icons.graphic_eq_rounded, color: color, size: 18),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, '/map', arguments: <String, dynamic>{
                          'name': location.name, 'category': location.category, 'origin': location.name,
                        });
                      },
                      child: const Text('Launch Interactive Map Navigation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
