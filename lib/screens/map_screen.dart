import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/campus_location.dart';
import '../models/checkpoint.dart';
import '../utils/constants.dart';
import '../algorithms/path_finding.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  bool _isNavigating = false;
  int _activeStepIndex = 0;
  double _navProgress = 0.0;
  double _simSpeed = 1.0; // 1.0x, 1.5x, 2.0x
  bool _isAudioGuidanceOn = true;
  Timer? _navTimer;

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  void _toggleLiveRoute(List<Checkpoint> checkpoints, CampusLocation location, String origin) {
    if (_isNavigating) {
      _stopRoute();
    } else {
      _startRoute(checkpoints, location, origin);
    }
  }

  void _startRoute(List<Checkpoint> checkpoints, CampusLocation location, String origin) {
    setState(() {
      _isNavigating = true;
    });

    _navTimer?.cancel();
    _navTimer = Timer.periodic(Duration(milliseconds: (300 / _simSpeed).round()), (timer) {
      if (!mounted) return;
      setState(() {
        _navProgress += 0.03;
        if (_navProgress >= 1.0) {
          _navProgress = 1.0;
          _stopRoute();
          _showRouteCompletedDialog(location, origin);
        } else {
          final totalSegs = (checkpoints.length - 1).clamp(1, 9999);
          _activeStepIndex = (_navProgress * totalSegs).floor();
        }
      });
    });
  }

  void _stopRoute() {
    _navTimer?.cancel();
    setState(() {
      _isNavigating = false;
    });
  }

  void _nextCheckpoint(List<Checkpoint> checkpoints) {
    if (checkpoints.isEmpty) return;
    if (_activeStepIndex < checkpoints.length - 1) {
      setState(() {
        _activeStepIndex++;
        final totalSegs = (checkpoints.length - 1).clamp(1, 9999);
        _navProgress = (_activeStepIndex / totalSegs).clamp(0.0, 1.0);
      });
    }
  }

  void _previousCheckpoint(List<Checkpoint> checkpoints) {
    if (checkpoints.isEmpty) return;
    if (_activeStepIndex > 0) {
      setState(() {
        _activeStepIndex--;
        final totalSegs = (checkpoints.length - 1).clamp(1, 9999);
        _navProgress = (_activeStepIndex / totalSegs).clamp(0.0, 1.0);
      });
    }
  }

  void _cycleSimSpeed() {
    setState(() {
      if (_simSpeed == 1.0) {
        _simSpeed = 1.5;
      } else if (_simSpeed == 1.5) {
        _simSpeed = 2.0;
      } else {
        _simSpeed = 1.0;
      }
    });
  }

  int _parseDistanceMeters(String distStr) {
    final clean = distStr.replaceAll(RegExp(r'[^0-9.]'), '');
    final val = double.tryParse(clean) ?? 850;
    if (distStr.contains('km')) {
      return (val * 1000).round();
    }
    return val.round();
  }

  void _showRouteCompletedDialog(CampusLocation location, String origin) {
    final distMeters = _parseDistanceMeters(location.distance);
    final distKmStr = distMeters >= 1000
        ? '${(distMeters / 1000).toStringAsFixed(2)} km'
        : '$distMeters m (${(distMeters / 1000).toStringAsFixed(2)} km)';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF155EEF),
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Route Completed! 🎉',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Successfully arrived at ${location.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE4E7EC)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.straighten, color: Color(0xFF155EEF), size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                    distKmStr,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Text('Distance Covered', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                ],
                              ),
                              Container(width: 1, height: 35, color: const Color(0xFFE4E7EC)),
                              Column(
                                children: [
                                  const Icon(Icons.timer_outlined, color: Color(0xFF10B981), size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                    location.walkingTime,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Text('Walking Time', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Text(
                            'Route: $origin ➔ ${location.name}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF155EEF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Animated Confetti Particles Overlay
              const Positioned.fill(
                child: ConfettiCelebrationWidget(),
              ),
            ],
          ),
        );
      },
    );
  }

  CampusLocation _findLocation(String name) {
    try {
      return campusLocations.firstWhere(
        (loc) => loc.name.toLowerCase() == name.toLowerCase(),
        orElse: () => CampusLocation(
          name: name,
          category: 'Campus Location',
          distance: '850 m',
          walkingTime: '~10 min',
        ),
      );
    } catch (_) {
      return CampusLocation(
        name: name,
        category: 'Campus Location',
        distance: '850 m',
        walkingTime: '~10 min',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> arguments =
        rawArgs is Map<String, dynamic> ? rawArgs : <String, dynamic>{};

    final String destinationName = (arguments['name'] ?? 'Central Library').toString();
    final String origin = (arguments['origin'] ?? 'My Current GPS Location').toString();

    final rawStops = arguments['stops'];
    final List<String> stops =
        rawStops is List ? rawStops.map((e) => e.toString()).toList() : <String>[];

    final location = _findLocation(destinationName);
    final checkpoints = PathFinding.getMultiStopRoute(
      startLocation: origin,
      stops: stops,
      destination: location,
    );

    final safeStepIndex = _activeStepIndex.clamp(0, (checkpoints.length - 1).clamp(0, 9999));
    final currentStep = checkpoints.isNotEmpty ? checkpoints[safeStepIndex] : null;

    final double safeSliderValue =
        (_navProgress.isNaN || _navProgress.isInfinite) ? 0.0 : _navProgress.clamp(0.0, 1.0);

    final totalMeters = _parseDistanceMeters(location.distance);
    final remainingMeters = ((1.0 - safeSliderValue) * totalMeters).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campus Navigation Map',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black,
              ),
            ),
            Text(
              'Route to ${location.name} (${checkpoints.length} checkpoints)',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isAudioGuidanceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _isAudioGuidanceOn ? const Color(0xFF155EEF) : Colors.grey,
              size: 22,
            ),
            tooltip: 'Toggle Audio Guidance',
            onPressed: () {
              setState(() {
                _isAudioGuidanceOn = !_isAudioGuidanceOn;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isAudioGuidanceOn
                      ? '🔊 Voice Navigation Guidance Enabled'
                      : '🔇 Voice Navigation Guidance Muted'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          TextButton.icon(
            onPressed: _cycleSimSpeed,
            icon: const Icon(Icons.speed, size: 16, color: Color(0xFF155EEF)),
            label: Text(
              '${_simSpeed}x',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF155EEF),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Voice & Step Navigation Instruction Banner
          if (currentStep != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4E7EC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: currentStep.isStop
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFEAF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        currentStep.label,
                        style: TextStyle(
                          color: currentStep.isStop
                              ? const Color(0xFFD97706)
                              : const Color(0xFF155EEF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              currentStep.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF101828),
                              ),
                            ),
                            if (_isAudioGuidanceOn) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.graphic_eq, size: 14, color: Color(0xFF155EEF)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentStep.instruction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$remainingMeters m left',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF155EEF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // GOOGLE MAPS VECTOR MAP CANVAS AREA
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDADCE0)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

                  // Calculate walking avatar position along canvas path
                  final walkerOffset = _calculatePointOnPath(
                    checkpoints,
                    safeSliderValue,
                    canvasSize,
                  );

                  return Stack(
                    children: [
                      // Dynamic GMaps Vector Map & Route Line Painter
                      CustomPaint(
                        size: canvasSize,
                        painter: DynamicCampusMapPainter(checkpoints: checkpoints),
                      ),

                      // Checkpoint Node Markers with Tap Interaction
                      ...checkpoints.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final cp = entry.value;

                        final nodeX = (cp.dx + 1.0) / 2.0 * canvasSize.width;
                        final nodeY = (cp.dy + 1.0) / 2.0 * canvasSize.height;

                        return Positioned(
                          left: nodeX - 16,
                          top: nodeY - 16,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeStepIndex = idx;
                                final totalSegs = (checkpoints.length - 1).clamp(1, 9999);
                                _navProgress = (idx / totalSegs).clamp(0.0, 1.0);
                              });
                            },
                            child: _CheckpointNode(
                              label: cp.label,
                              title: cp.title,
                              isSelected: _activeStepIndex == idx,
                              isStop: cp.isStop,
                            ),
                          ),
                        );
                      }),

                      // ANIMATED WALKING PERSON AVATAR MARKER
                      Positioned(
                        left: (walkerOffset.dx - 18).clamp(0.0, canvasSize.width - 36),
                        top: (walkerOffset.dy - 18).clamp(0.0, canvasSize.height - 36),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF155EEF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_walk,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                      // GMaps Mode Badge (Top Left)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDADCE0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.place, color: Color(0xFFEA4335), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Campus GMaps Mode',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3C4043),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Live Compass Radar Indicator (Top Right)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDADCE0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.explore, color: Color(0xFF155EEF), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'NW 315° • Campus North',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3C4043),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Live Weather Banner (Bottom Left Canvas)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDADCE0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.wb_sunny_outlined, color: Color(0xFFF59E0B), size: 14),
                              SizedBox(width: 6),
                              Text(
                                '☀️ 27°C • Clear Walkway',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3C4043),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // BACK & FORTH INTERACTIVE SIMULATION SCRUBBER CONTROLS
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Color(0xFF155EEF)),
                      onPressed: () => _previousCheckpoint(checkpoints),
                    ),
                    Expanded(
                      child: Slider(
                        value: safeSliderValue,
                        activeColor: const Color(0xFF155EEF),
                        inactiveColor: const Color(0xFFEAF2FF),
                        onChanged: (val) {
                          setState(() {
                            _navProgress = val.clamp(0.0, 1.0);
                            final totalSegs = (checkpoints.length - 1).clamp(1, 9999);
                            _activeStepIndex = (_navProgress * totalSegs).floor();
                            if (_navProgress >= 1.0) {
                              _showRouteCompletedDialog(location, origin);
                            }
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Color(0xFF155EEF)),
                      onPressed: () => _nextCheckpoint(checkpoints),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Start: $origin',
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                      Text(
                        '${(safeSliderValue * 100).round()}% Completed • $remainingMeters m left',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF155EEF),
                        ),
                      ),
                      Text(
                        'Destination: ${location.name}',
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // BOTTOM CONTROL PANEL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.category,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          Text(
                            destinationName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.directions_walk, color: Color(0xFF155EEF), size: 16),
                        const SizedBox(width: 4),
                        Text(location.distance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, color: Color(0xFF155EEF), size: 16),
                        const SizedBox(width: 4),
                        Text(location.walkingTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Start / Pause Simulation Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleLiveRoute(checkpoints, location, origin),
                    icon: Icon(_isNavigating ? Icons.pause : Icons.navigation),
                    label: Text(
                      _isNavigating ? 'Pause Simulation' : 'Start Live Walk Simulation',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155EEF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Offset _calculatePointOnPath(List<Checkpoint> checkpoints, double progress, Size canvasSize) {
    if (checkpoints.length < 2) return Offset(canvasSize.width / 2, canvasSize.height / 2);

    final totalSegments = (checkpoints.length - 1).clamp(1, 9999);
    final scaledProgress = progress * totalSegments;
    final index = scaledProgress.floor().clamp(0, totalSegments - 1);
    final t = scaledProgress - index;

    final p1 = checkpoints[index];
    final p2 = checkpoints[index + 1];

    final x1 = (p1.dx + 1.0) / 2.0 * canvasSize.width;
    final y1 = (p1.dy + 1.0) / 2.0 * canvasSize.height;

    final x2 = (p2.dx + 1.0) / 2.0 * canvasSize.width;
    final y2 = (p2.dy + 1.0) / 2.0 * canvasSize.height;

    final curX = x1 + (x2 - x1) * t;
    final curY = y1 + (y2 - y1) * t;

    return Offset(curX, curY);
  }
}

// ANIMATED CONFETTI CELEBRATION OVERLAY
class ConfettiCelebrationWidget extends StatefulWidget {
  const ConfettiCelebrationWidget({super.key});

  @override
  State<ConfettiCelebrationWidget> createState() => _ConfettiCelebrationWidgetState();
}

class _ConfettiCelebrationWidgetState extends State<ConfettiCelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    final colors = [
      const Color(0xFF155EEF),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    for (int i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle(
        x: random.nextDouble(),
        y: -random.nextDouble() * 0.4,
        size: random.nextDouble() * 8 + 5,
        color: colors[random.nextInt(colors.length)],
        vx: (random.nextDouble() - 0.5) * 0.5,
        vy: random.nextDouble() * 0.7 + 0.4,
        rotation: random.nextDouble() * 2 * math.pi,
        vRot: (random.nextDouble() - 0.5) * 0.25,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        if (mounted) {
          setState(() {
            for (var p in _particles) {
              p.x += p.vx * 0.02;
              p.y += p.vy * 0.02;
              p.rotation += p.vRot;
            }
          });
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_particles),
      ),
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double size;
  Color color;
  double vx;
  double vy;
  double rotation;
  double vRot;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.vRot,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final px = p.x * size.width;
      final py = p.y * size.height;

      if (py > size.height + 20) continue;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      final paint = Paint()..color = p.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Checkpoint Node Widget
class _CheckpointNode extends StatelessWidget {
  final String label;
  final String title;
  final bool isSelected;
  final bool isStop;

  const _CheckpointNode({
    required this.label,
    required this.title,
    this.isSelected = false,
    this.isStop = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isStop
        ? const Color(0xFFF59E0B)
        : (isSelected ? const Color(0xFF155EEF) : Colors.white);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 34 : 28,
          height: isSelected ? 34 : 28,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isStop ? const Color(0xFFD97706) : const Color(0xFF155EEF),
              width: isSelected ? 3.5 : 2.5,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF155EEF).withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected || isStop ? Colors.white : const Color(0xFF155EEF),
                fontWeight: FontWeight.bold,
                fontSize: isSelected ? 12 : 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// DYNAMIC VECTOR GMAPS STYLE PAINTER
class DynamicCampusMapPainter extends CustomPainter {
  final List<Checkpoint> checkpoints;

  DynamicCampusMapPainter({required this.checkpoints});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw GMaps Base Background (Parks + Terrain)
    _drawGMapsBase(canvas, size);

    // 2. Draw GMaps Small Realistic Buildings & Tiny Locations
    _drawGMapsSmallBuildings(canvas, size);

    // 3. Draw GMaps Tiny POI Pins (Icon + Title)
    _drawGMapsTinyPOIPins(canvas, size);

    // 4. Draw GMaps Navigation Route Line connecting Checkpoints
    if (checkpoints.length >= 2) {
      final routeBorderPaint = Paint()
        ..color = const Color(0xFF155EEF).withValues(alpha: 0.3)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final routePaint = Paint()
        ..color = const Color(0xFF1A73E8) // Google Maps Primary Blue
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();

      for (int i = 0; i < checkpoints.length; i++) {
        final cp = checkpoints[i];
        final x = (cp.dx + 1.0) / 2.0 * size.width;
        final y = (cp.dy + 1.0) / 2.0 * size.height;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, routeBorderPaint);
      canvas.drawPath(path, routePaint);
    }
  }

  void _drawGMapsBase(Canvas canvas, Size size) {
    // GMaps Canvas Background (#F1F3F4)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFF1F3F4));

    // Green Park Grounds (#E6F4EA)
    final parkPaint = Paint()..color = const Color(0xFFE6F4EA);

    // Central Lawn & Garden Park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.32, size.height * 0.40, size.width * 0.25, size.height * 0.22),
        const Radius.circular(20),
      ),
      parkPaint,
    );

    // Athletic Field Ground
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.68, size.height * 0.08, size.width * 0.26, size.height * 0.20),
        const Radius.circular(35),
      ),
      parkPaint,
    );

    // Main Campus Road Network (#FFFFFF with #DADCE0 casing)
    final roadCasing = Paint()
      ..color = const Color(0xFFDADCE0)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final roadFill = Paint()
      ..color = Colors.white
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final roadPath = Path()
      ..moveTo(size.width * 0.05, size.height * 0.85)
      ..lineTo(size.width * 0.25, size.height * 0.65)
      ..lineTo(size.width * 0.50, size.height * 0.45)
      ..lineTo(size.width * 0.75, size.height * 0.25)
      ..lineTo(size.width * 0.95, size.height * 0.10);

    canvas.drawPath(roadPath, roadCasing);
    canvas.drawPath(roadPath, roadFill);

    // Secondary Walkway Corridors (Thin white paths)
    final walkwayPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final walkwayPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.65)
      ..lineTo(size.width * 0.15, size.height * 0.25)
      ..moveTo(size.width * 0.50, size.height * 0.45)
      ..lineTo(size.width * 0.80, size.height * 0.55);

    canvas.drawPath(walkwayPath, walkwayPaint);
  }

  void _drawGMapsSmallBuildings(Canvas canvas, Size size) {
    // Soft GMaps Building Fill (#E8EAED) & Border (#BDC1C6)
    final buildingFill = Paint()..color = const Color(0xFFE8EAED);
    final buildingBorder = Paint()
      ..color = const Color(0xFFBDC1C6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    void drawSmallBuilding(Rect rect) {
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, buildingFill);
      canvas.drawRRect(rrect, buildingBorder);
    }

    // Academic Buildings (Tiny L-shaped & Rectangular Footprints)
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.08, size.height * 0.12, size.width * 0.10, size.height * 0.09));
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.08, size.height * 0.26, size.width * 0.10, size.height * 0.09));
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.08, size.height * 0.40, size.width * 0.10, size.height * 0.09));
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.24, size.height * 0.12, size.width * 0.08, size.height * 0.08));
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.24, size.height * 0.24, size.width * 0.08, size.height * 0.08));

    // Library Building Footprint
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.52, size.height * 0.12, size.width * 0.12, size.height * 0.10));

    // Main Canteen Kiosk & Outdoor Deck
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.26, size.height * 0.68, size.width * 0.10, size.height * 0.08));

    // Hostels Blocks (Small repeating residential footprints)
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.78, size.height * 0.35, size.width * 0.08, size.height * 0.07));
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.88, size.height * 0.35, size.width * 0.08, size.height * 0.07));
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.78, size.height * 0.46, size.width * 0.08, size.height * 0.07));
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.88, size.height * 0.46, size.width * 0.08, size.height * 0.07));

    // Clinic & General Store Small Structures
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.52, size.height * 0.42, size.width * 0.06, size.height * 0.06));
    drawSmallBuilding(Rect.fromLTWH(size.width * 0.38, size.height * 0.55, size.width * 0.06, size.height * 0.05));
  }

  void _drawGMapsTinyPOIPins(Canvas canvas, Size size) {
    // Draw tiny GMaps-style POI badges (Round Icon Pin + Label)
    void drawPOIPin(Offset pos, String text, Color color) {
      // Pin background circle
      final bgPaint = Paint()..color = color;
      canvas.drawCircle(pos, 8, bgPaint);
      canvas.drawCircle(pos, 8, Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke);

      // Icon Text
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3C4043),
        ),
      );
      textPainter.layout();

      // Draw label pill next to pin
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx + 10, pos.dy - 7, textPainter.width + 8, 14),
        const Radius.circular(6),
      );
      canvas.drawRRect(labelRect, Paint()..color = Colors.white.withValues(alpha: 0.95));
      canvas.drawRRect(labelRect, Paint()..color = const Color(0xFFDADCE0)..strokeWidth = 1.0..style = PaintingStyle.stroke);

      textPainter.paint(canvas, Offset(pos.dx + 14, pos.dy - 6));
    }

    // Tiny GMaps POI Badges across campus
    drawPOIPin(Offset(size.width * 0.13, size.height * 0.165), 'AB1', const Color(0xFF1A73E8));
    drawPOIPin(Offset(size.width * 0.13, size.height * 0.305), 'AB2', const Color(0xFF1A73E8));
    drawPOIPin(Offset(size.width * 0.58, size.height * 0.170), 'Library', const Color(0xFF1A73E8));
    drawPOIPin(Offset(size.width * 0.31, size.height * 0.720), 'Main Canteen', const Color(0xFFE37400));
    drawPOIPin(Offset(size.width * 0.82, size.height * 0.385), 'Girls Hostel', const Color(0xFF137333));
    drawPOIPin(Offset(size.width * 0.82, size.height * 0.495), 'Boys Hostel', const Color(0xFF137333));
    drawPOIPin(Offset(size.width * 0.81, size.height * 0.180), 'Main Ground', const Color(0xFF137333));
  }

  @override
  bool shouldRepaint(covariant DynamicCampusMapPainter oldDelegate) {
    return oldDelegate.checkpoints != checkpoints;
  }
}