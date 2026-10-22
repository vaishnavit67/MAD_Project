import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import '../models/campus_location.dart';
import '../utils/constants.dart';
import '../algorithms/path_finding.dart';
import '../algorithms/dijkstra_path_finding.dart';
import '../services/location_service.dart';
import '../services/history_service.dart';
import '../services/map_config_service.dart';

class _PathPose {
  final LatLng position;
  final double bearing;
  const _PathPose(this.position, this.bearing);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  // Lifecycle guards
  bool _isMapReady = false;
  bool _hasShownCorsNotice = false;

  // Cached routing data to prevent recomputing Dijkstra on every frame
  DijkstraResult? _cachedDijkstraResult;
  String? _cachedOrigin;
  String? _cachedDestinationName;
  List<String>? _cachedStops;
  CampusLocation? _cachedLocation;

  // Navigation mode: Simulated walk vs Live device GPS
  bool _isLiveGpsMode = false;
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentDevicePosition;
  bool _isGpsLoading = false;
  bool _isOffCampus = false;
  bool _followUser = true;
  bool _isHeadingUp = true; // Google Maps default: rotate map in direction of travel
  double _currentMapRotation = 0.0;

  // Simulation controls
  bool _isNavigating = false;
  int _activeManeuverIndex = 0;
  double _navProgress = 0.0;
  double _simSpeed = 1.0; // 1.0x, 2.0x, 3.0x
  bool _isAudioGuidanceOn = true;
  Timer? _navTimer;

  // Campus POI presentation controls
  bool _showPoiMarkers = true;
  String _selectedCategoryFilter = 'All';

  void _showStepsModal(DijkstraResult dijkstraResult, CampusLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, -4))],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.turn_right_rounded, color: Color(0xFF0F9D58), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Directions to ${location.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: dijkstraResult.maneuvers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final m = dijkstraResult.maneuvers[idx];
                    final isCurrent = idx == _activeManeuverIndex;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrent ? const Color(0xFF0F9D58) : const Color(0xFFF1F5F9),
                        child: Icon(m.icon, color: isCurrent ? Colors.white : const Color(0xFF475569), size: 20),
                      ),
                      title: Text(
                        m.instruction,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent ? const Color(0xFF0F9D58) : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        m.roadName,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      trailing: Text(
                        '${m.distanceMeters.round()} m',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _activeManeuverIndex = idx;
                          _navProgress = (m.cumulativeDistanceMeters / dijkstraResult.totalDistanceMeters).clamp(0.0, 1.0);
                        });
                        _safeMoveCamera(m.point, 18.0);
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

  void _showPoiFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            const filterOptions = [
              'All',
              'Academic',
              'Dining',
              'Hostels',
              'Sports',
              'Landmarks',
              'Facilities',
              'Transit',
            ];

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.place_rounded, color: Color(0xFF38BDF8), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Campus Places & POIs',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Toggle Switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Show Campus Places on Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: _showPoiMarkers,
                          activeThumbColor: const Color(0xFF38BDF8),
                          onChanged: (val) {
                            setState(() => _showPoiMarkers = val);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Filter Category',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filterOptions.map((cat) {
                      final isSelected = _selectedCategoryFilter == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2563EB),
                        backgroundColor: Colors.white10,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF38BDF8) : Colors.white24,
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategoryFilter = cat;
                              _showPoiMarkers = true;
                            });
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    MapConfigService.instance.addListener(_onMapConfigChanged);
  }

  void _onMapConfigChanged() {
    if (mounted) setState(() {});
  }

  bool _hasAutoStartedGps = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureRouteComputed(context);

    if (!_hasAutoStartedGps) {
      final rawArgs = ModalRoute.of(context)?.settings.arguments;
      final Map<String, dynamic> arguments =
          rawArgs is Map<String, dynamic> ? rawArgs : <String, dynamic>{};
      final bool startLiveGps = arguments['startLiveGps'] == true;
      final String origin = (arguments['origin'] ?? '').toString();
      final bool isGpsOrigin = origin.toLowerCase().contains('gps') || origin.toLowerCase().contains('current');

      if (startLiveGps || isGpsOrigin) {
        _hasAutoStartedGps = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _cachedDijkstraResult != null && _cachedLocation != null) {
            _startLiveGpsTracking(_cachedDijkstraResult!, _cachedLocation!, _cachedOrigin ?? origin);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    MapConfigService.instance.removeListener(_onMapConfigChanged);
    _navTimer?.cancel();
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _safeMoveCamera(LatLng center, double zoom, {double? rotation}) {
    if (!_isMapReady || !mounted) return;
    try {
      _mapController.move(center, zoom);
      if (rotation != null) {
        _mapController.rotate(rotation);
        _currentMapRotation = rotation;
      }
    } catch (_) {}
  }

  void _toggleCompassMode(double userHeading) {
    setState(() {
      _isHeadingUp = !_isHeadingUp;
    });
    if (_isHeadingUp) {
      _safeMoveCamera(_mapController.camera.center, _mapController.camera.zoom, rotation: -userHeading);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🧭 Heading-Up Mode (Follow Travel Direction)'), duration: Duration(seconds: 1)),
      );
    } else {
      _safeMoveCamera(_mapController.camera.center, _mapController.camera.zoom, rotation: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🧭 North-Up Mode'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _fitRouteBounds(List<LatLng> points) {
    if (!_isMapReady || !mounted || points.isEmpty) return;
    try {
      if (points.length == 1) {
        _safeMoveCamera(points.first, 17.5);
        return;
      }
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        ),
      );
    } catch (_) {}
  }

  void _recenterOnCampus() {
    _safeMoveCamera(const LatLng(amritaCampusCenterLat, amritaCampusCenterLng), 16.8);
    try {
      _mapController.rotate(0.0);
    } catch (_) {}
  }

  void _zoomIn() {
    if (!_isMapReady || !mounted) return;
    try {
      setState(() => _followUser = false);
      final activeStyle = MapConfigService.instance.currentStyle;
      final currentZoom = _mapController.camera.zoom;
      final targetZoom = (currentZoom + 0.8).clamp(activeStyle.minZoom, activeStyle.maxZoom);
      _mapController.move(_mapController.camera.center, targetZoom);
    } catch (_) {}
  }

  void _zoomOut() {
    if (!_isMapReady || !mounted) return;
    try {
      setState(() => _followUser = false);
      final activeStyle = MapConfigService.instance.currentStyle;
      final currentZoom = _mapController.camera.zoom;
      final targetZoom = (currentZoom - 0.8).clamp(activeStyle.minZoom, activeStyle.maxZoom);
      _mapController.move(_mapController.camera.center, targetZoom);
    } catch (_) {}
  }

  void _ensureRouteComputed(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> arguments =
        rawArgs is Map<String, dynamic> ? rawArgs : <String, dynamic>{};

    final String destinationName = (arguments['name'] ?? 'Central Library').toString();
    final String origin = (arguments['origin'] ?? 'Main Gate Entrance').toString();

    final rawStops = arguments['stops'];
    final List<String> stops =
        rawStops is List ? rawStops.map((e) => e.toString()).toList() : <String>[];

    final bool needsRecompute = _cachedDijkstraResult == null ||
        _cachedOrigin != origin ||
        _cachedDestinationName != destinationName ||
        _cachedStops?.length != stops.length;

    if (needsRecompute) {
      _cachedOrigin = origin;
      _cachedDestinationName = destinationName;
      _cachedStops = List<String>.from(stops);
      _cachedLocation = _findLocation(destinationName);
      _cachedDijkstraResult = PathFinding.getDijkstraRoute(
        startLocation: origin,
        stops: stops,
        destination: _cachedLocation!,
        startLat: _currentDevicePosition?.latitude,
        startLng: _currentDevicePosition?.longitude,
      );
    }
  }

  double get _distanceToCampusKm {
    if (_currentDevicePosition == null) return 0.0;
    const campusCenter = LatLng(amritaCampusCenterLat, amritaCampusCenterLng);
    final userPos = LatLng(_currentDevicePosition!.latitude, _currentDevicePosition!.longitude);
    return const Distance().as(LengthUnit.Meter, userPos, campusCenter) / 1000.0;
  }

  void _checkIfOffCampus(Position pos) {
    const campusCenter = LatLng(amritaCampusCenterLat, amritaCampusCenterLng);
    final userPos = LatLng(pos.latitude, pos.longitude);
    final distMeters = const Distance().as(LengthUnit.Meter, userPos, campusCenter);
    _isOffCampus = distMeters > 3500;
  }

  void _recomputeRouteFromGpsIfAppropriate(
    Position pos,
    CampusLocation location,
    String origin,
  ) {
    if (!_isLiveGpsMode) return;

    final isGpsOrigin = origin.toLowerCase().contains('gps') || origin.toLowerCase().contains('current');
    const campusCenter = LatLng(amritaCampusCenterLat, amritaCampusCenterLng);
    final userPos = LatLng(pos.latitude, pos.longitude);
    final distMeters = const Distance().as(LengthUnit.Meter, userPos, campusCenter);

    // If within campus boundary (~3.5km), calculate live Dijkstra path from user's coordinates
    if (distMeters <= 3500) {
      final updatedResult = PathFinding.getDijkstraRoute(
        startLocation: isGpsOrigin ? 'My Current GPS Location' : origin,
        stops: _cachedStops ?? const [],
        destination: location,
        startLat: pos.latitude,
        startLng: pos.longitude,
      );

      if (mounted && updatedResult.polylinePoints.isNotEmpty) {
        setState(() {
          _cachedDijkstraResult = updatedResult;
        });
      }
    }
  }

  void _toggleLiveGpsMode(DijkstraResult dijkstraResult, CampusLocation location, String origin) {
    if (_isLiveGpsMode) {
      _positionSubscription?.cancel();
      setState(() {
        _isLiveGpsMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚶 Switched to Campus Walk Simulation Mode'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      _stopSimulation();
      _startLiveGpsTracking(dijkstraResult, location, origin);
    }
  }

  Future<void> _startLiveGpsTracking(
    DijkstraResult dijkstraResult,
    CampusLocation location,
    String origin,
  ) async {
    setState(() {
      _isGpsLoading = true;
    });

    try {
      final status = await _locationService.checkLocationPermissionStatus();

      if (status == LocationPermissionStatus.serviceDisabled) {
        if (mounted) {
          setState(() {
            _isGpsLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('📍 Device Location (GPS) is turned off.'),
              action: SnackBarAction(
                label: 'Turn On',
                textColor: const Color(0xFF38BDF8),
                onPressed: () => _locationService.openLocationSettings(),
              ),
              backgroundColor: const Color(0xFFD92D20),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (status == LocationPermissionStatus.deniedForever) {
        if (mounted) {
          setState(() {
            _isGpsLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Location permission is permanently denied. Please allow it in App Settings.'),
              action: SnackBarAction(
                label: 'Settings',
                textColor: const Color(0xFF38BDF8),
                onPressed: () => _locationService.openAppSettings(),
              ),
              backgroundColor: const Color(0xFFD92D20),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (status != LocationPermissionStatus.granted) {
        if (mounted) {
          setState(() {
            _isGpsLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Location permission is required for live GPS navigation. Switched to Simulation Mode.'),
              backgroundColor: Color(0xFFD92D20),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Permissions granted: activate live GPS mode & navigation
      if (mounted) {
        setState(() {
          _isLiveGpsMode = true;
          _isNavigating = true;
        });
      }

      // Fetch initial position (with cached instant fix)
      final pos = await _locationService.getCurrentDevicePosition();
      if (pos != null && mounted) {
        setState(() {
          _currentDevicePosition = pos;
          _checkIfOffCampus(pos);
          _isGpsLoading = false;
        });

        _recomputeRouteFromGpsIfAppropriate(pos, location, origin);

        if (_followUser) {
          _safeMoveCamera(
            LatLng(pos.latitude, pos.longitude),
            18.0,
            rotation: _isHeadingUp ? -pos.heading : 0.0,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isOffCampus
                ? '📡 Live GPS Connected (${pos.latitude.toStringAsFixed(3)}°, ${pos.longitude.toStringAsFixed(3)}°) • Live Walking Active'
                : '📡 Live GPS Connected on Amrita Campus (Accuracy: ±${pos.accuracy.toStringAsFixed(0)}m)'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Stream updates
      _positionSubscription?.cancel();
      final stream = _locationService.getLivePositionStream();
      if (stream != null) {
        _positionSubscription = stream.listen((Position newPos) {
          if (!mounted) return;
          setState(() {
            _currentDevicePosition = newPos;
            _checkIfOffCampus(newPos);
            _isGpsLoading = false;
          });

          _recomputeRouteFromGpsIfAppropriate(newPos, location, origin);

          if (_followUser) {
            _safeMoveCamera(
              LatLng(newPos.latitude, newPos.longitude),
              18.0,
              rotation: _isHeadingUp ? -newPos.heading : 0.0,
            );
            _checkManeuverProximity(newPos, _cachedDijkstraResult ?? dijkstraResult, location, origin);
          }
        }, onError: (_) {
          if (mounted) setState(() => _isGpsLoading = false);
        });
      }

      if (mounted) {
        setState(() {
          _isGpsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isGpsLoading = false;
        });
      }
    }
  }

  void _checkManeuverProximity(
    Position userPos,
    DijkstraResult dijkstraResult,
    CampusLocation location,
    String origin,
  ) {
    final maneuvers = dijkstraResult.maneuvers;
    if (maneuvers.isEmpty) return;

    final targetManeuver = maneuvers[_activeManeuverIndex];
    final userPoint = LatLng(userPos.latitude, userPos.longitude);
    final distanceMeters = const Distance().as(LengthUnit.Meter, userPoint, targetManeuver.point);

    if (distanceMeters <= 15) {
      if (_activeManeuverIndex < maneuvers.length - 1) {
        setState(() {
          _activeManeuverIndex++;
        });
        if (_isAudioGuidanceOn) {
          HapticFeedback.mediumImpact();
          SystemSound.play(SystemSoundType.click);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔊 ${maneuvers[_activeManeuverIndex].instruction}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        _positionSubscription?.cancel();
        _showRouteCompletedDialog(location, origin, dijkstraResult.totalDistanceMeters);
      }
    }
  }

  void _toggleSimulation(DijkstraResult dijkstraResult, CampusLocation location, String origin) {
    if (_isNavigating) {
      _stopSimulation();
    } else {
      _startSimulation(dijkstraResult, location, origin);
    }
  }

  void _startSimulation(DijkstraResult dijkstraResult, CampusLocation location, String origin) {
    setState(() {
      _isNavigating = true;
    });

    _navTimer?.cancel();

    _navTimer = Timer.periodic(Duration(milliseconds: (120 / _simSpeed).round()), (timer) {
      if (!mounted) return;

      LatLng? walkerPosToMove;
      double? walkerBearing;
      bool completed = false;

      setState(() {
        _navProgress += 0.005 * _simSpeed;
        if (_navProgress >= 1.0) {
          _navProgress = 1.0;
          completed = true;
          _isNavigating = false;
        } else {
          final totalMeters = dijkstraResult.totalDistanceMeters;
          final currentMeters = _navProgress * totalMeters;

          for (int i = 0; i < dijkstraResult.maneuvers.length; i++) {
            if (currentMeters <= dijkstraResult.maneuvers[i].cumulativeDistanceMeters) {
              if (_activeManeuverIndex != i) {
                _activeManeuverIndex = i;
                if (_isAudioGuidanceOn) {
                  HapticFeedback.mediumImpact();
                  SystemSound.play(SystemSoundType.click);
                }
              }
              break;
            }
          }

          if (_followUser) {
            final pose = _calculatePathPose(dijkstraResult.polylinePoints, _navProgress);
            walkerPosToMove = pose.position;
            walkerBearing = pose.bearing;
          }
        }
      });

      if (completed) {
        _navTimer?.cancel();
        _showRouteCompletedDialog(location, origin, dijkstraResult.totalDistanceMeters);
      } else if (walkerPosToMove != null && _isMapReady && _followUser) {
        final double rot = _isHeadingUp && walkerBearing != null ? -walkerBearing! : 0.0;
        _safeMoveCamera(walkerPosToMove!, 18.0, rotation: rot);
      }
    });
  }

  void _stopSimulation() {
    _navTimer?.cancel();
    setState(() {
      _isNavigating = false;
    });
  }

  void _nextManeuver(DijkstraResult dijkstraResult) {
    final maneuvers = dijkstraResult.maneuvers;
    if (maneuvers.isEmpty) return;
    if (_activeManeuverIndex < maneuvers.length - 1) {
      setState(() {
        _activeManeuverIndex++;
        if (dijkstraResult.totalDistanceMeters > 0) {
          _navProgress = (maneuvers[_activeManeuverIndex].cumulativeDistanceMeters / dijkstraResult.totalDistanceMeters).clamp(0.0, 1.0);
        }
      });
      _safeMoveCamera(maneuvers[_activeManeuverIndex].point, 17.5);
    }
  }

  void _previousManeuver(DijkstraResult dijkstraResult) {
    final maneuvers = dijkstraResult.maneuvers;
    if (maneuvers.isEmpty) return;
    if (_activeManeuverIndex > 0) {
      setState(() {
        _activeManeuverIndex--;
        if (dijkstraResult.totalDistanceMeters > 0) {
          _navProgress = (maneuvers[_activeManeuverIndex].cumulativeDistanceMeters / dijkstraResult.totalDistanceMeters).clamp(0.0, 1.0);
        }
      });
      _safeMoveCamera(maneuvers[_activeManeuverIndex].point, 17.5);
    }
  }

  void _cycleSimSpeed() {
    setState(() {
      if (_simSpeed == 1.0) {
        _simSpeed = 2.0;
      } else if (_simSpeed == 2.0) {
        _simSpeed = 3.0;
      } else {
        _simSpeed = 1.0;
      }
    });
  }


  void _handleTileError(MapStyleOption style) {
    if (style.provider == MapProvider.googleMaps) {
      if (!_hasShownCorsNotice && mounted) {
        _hasShownCorsNotice = true;
        // Gracefully fall back to High-Res Satellite Map (esri_imagery)
        MapConfigService.instance.selectStyle(0);
      }
    }
  }

  void _showLayerSelectionModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Map Cartography & Layers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: MapConfigService.instance.availableStyles.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
                    itemBuilder: (context, idx) {
                      final style = MapConfigService.instance.availableStyles[idx];
                      final isSelected = MapConfigService.instance.selectedStyleIndex == idx;

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF155EEF).withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            style.icon,
                            color: isSelected ? const Color(0xFF155EEF) : const Color(0xFF64748B),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          style.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? const Color(0xFF155EEF) : const Color(0xFF1E293B),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          style.subtitle,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF155EEF), size: 20)
                            : null,
                        onTap: () {
                          MapConfigService.instance.selectStyle(idx);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🗺️ Active Layer: ${style.name}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRouteCompletedDialog(CampusLocation location, String origin, double distanceMeters) {
    final distKmStr = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(2)} km'
        : '${distanceMeters.round()} m (${(distanceMeters / 1000).toStringAsFixed(2)} km)';

    HistoryService.instance.addHistory(
      locationName: location.name,
      category: location.category,
      origin: origin,
      stops: const [],
      distance: '${distanceMeters.round()} m',
      walkingTime: location.walkingTime,
      buildingCode: location.buildingCode,
      floorCount: location.floorCount,
      note: 'Dijkstra route to ${location.name} completed successfully',
    );

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
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF16A34A),
                        size: 46,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Destination Reached! 🎓',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You have arrived at ${location.name}\nAmrita Vishwa Vidyapeetham, Coimbatore',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
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
                                  const Text('Dijkstra Distance', style: TextStyle(fontSize: 11, color: Colors.black54)),
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
                          if (location.latitude != null && location.longitude != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'GPS: ${location.latitude!.toStringAsFixed(5)}° N, ${location.longitude!.toStringAsFixed(5)}° E',
                              style: const TextStyle(fontSize: 10, color: Colors.black45),
                            ),
                          ],
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned.fill(child: ConfettiCelebrationWidget()),
            ],
          ),
        );
      },
    );
  }

  CampusLocation _findLocation(String name) {
    try {
      final clean = name.trim().toLowerCase();
      return campusLocations.firstWhere(
        (loc) =>
            loc.name.toLowerCase() == clean ||
            loc.name.toLowerCase().contains(clean) ||
            clean.contains(loc.name.toLowerCase()),
        orElse: () => CampusLocation(
          name: name,
          category: 'Campus Location',
          distance: '480 m',
          walkingTime: '~6 min',
          latitude: amritaCampusCenterLat,
          longitude: amritaCampusCenterLng,
        ),
      );
    } catch (_) {
      return CampusLocation(
        name: name,
        category: 'Campus Location',
        distance: '480 m',
        walkingTime: '~6 min',
        latitude: amritaCampusCenterLat,
        longitude: amritaCampusCenterLng,
      );
    }
  }

  _PathPose _calculatePathPose(List<LatLng> points, double progress) {
    if (points.isEmpty) {
      return const _PathPose(LatLng(amritaCampusCenterLat, amritaCampusCenterLng), 0.0);
    }
    if (points.length == 1) {
      return _PathPose(points.first, 0.0);
    }
    if (progress <= 0.0) {
      final initialBearing = DijkstraPathFinding.calculateBearing(points[0], points[1]);
      return _PathPose(points.first, initialBearing);
    }
    if (progress >= 1.0) {
      final finalBearing = DijkstraPathFinding.calculateBearing(points[points.length - 2], points.last);
      return _PathPose(points.last, finalBearing);
    }

    const distance = Distance();
    final segmentDistances = <double>[];
    double totalDistance = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      final d = distance.as(LengthUnit.Meter, points[i], points[i + 1]);
      segmentDistances.add(d);
      totalDistance += d;
    }

    if (totalDistance == 0) {
      return _PathPose(points.first, 0.0);
    }

    final targetDist = progress * totalDistance;
    double accumulated = 0.0;

    for (int i = 0; i < segmentDistances.length; i++) {
      final segLen = segmentDistances[i];
      if (accumulated + segLen >= targetDist) {
        final segFraction = segLen > 0 ? ((targetDist - accumulated) / segLen).clamp(0.0, 1.0) : 0.0;
        final p1 = points[i];
        final p2 = points[i + 1];
        final lat = p1.latitude + (p2.latitude - p1.latitude) * segFraction;
        final lng = p1.longitude + (p2.longitude - p1.longitude) * segFraction;
        final bearing = DijkstraPathFinding.calculateBearing(p1, p2);
        return _PathPose(LatLng(lat, lng), bearing);
      }
      accumulated += segLen;
    }

    final lastBearing = DijkstraPathFinding.calculateBearing(points[points.length - 2], points.last);
    return _PathPose(points.last, lastBearing);
  }


  /// Category badge colors for all campus POIs (Curated, mature, cohesive palette)
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Academic Block':
        return const Color(0xFF1E3A8A); // Refined Navy
      case 'Library':
        return const Color(0xFF4338CA); // Royal Indigo
      case 'Canteen':
        return const Color(0xFFD97706); // Warm Amber
      case 'Girls Hostel':
        return const Color(0xFFBE185D); // Rosewood
      case 'Boys Hostel':
        return const Color(0xFF6D28D9); // Rich Plum
      case 'Sports Facility':
        return const Color(0xFF047857); // Forest Emerald
      case 'Place of Worship':
        return const Color(0xFFB45309); // Bronze Ochre
      case 'Landmark':
        return const Color(0xFF0D9488); // Dark Teal
      case 'ATM':
      case 'Store':
        return const Color(0xFF0284C7); // Cerulean
      case 'Medical Facility':
        return const Color(0xFFDC2626); // Crimson
      case 'Auditorium':
        return const Color(0xFF7C3AED); // Classic Violet
      case 'Administrative Block':
        return const Color(0xFF475569); // Slate Steel
      case 'Laboratory':
        return const Color(0xFF2563EB); // Pure Blue
      case 'Transit':
        return const Color(0xFFC2410C); // Terracotta
      default:
        return const Color(0xFF1E3A8A);
    }
  }

  /// Category icons for all campus POIs
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Academic Block':
        return Icons.school_rounded;
      case 'Library':
        return Icons.auto_stories_rounded;
      case 'Canteen':
        return Icons.restaurant_rounded;
      case 'Girls Hostel':
        return Icons.home_work_rounded;
      case 'Boys Hostel':
        return Icons.hotel_rounded;
      case 'Sports Facility':
        return Icons.fitness_center_rounded;
      case 'Place of Worship':
        return Icons.temple_hindu_rounded;
      case 'Landmark':
        return Icons.place_rounded;
      case 'ATM':
        return Icons.atm_rounded;
      case 'Store':
        return Icons.storefront_rounded;
      case 'Medical Facility':
        return Icons.local_hospital_rounded;
      case 'Auditorium':
        return Icons.theater_comedy_rounded;
      case 'Administrative Block':
        return Icons.account_balance_rounded;
      case 'Laboratory':
        return Icons.biotech_rounded;
      case 'Transit':
        return Icons.directions_railway_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  /// Builds clean, compact circular POI pins for campus places from OpenStreetMap
  List<Marker> _buildCampusPoiMarkers(CampusLocation activeLocation, String activeOrigin) {
    if (!_showPoiMarkers) return [];

    final markers = <Marker>[];
    final activeDestLower = activeLocation.name.toLowerCase().trim();
    final activeOrigLower = activeOrigin.toLowerCase().trim();

    for (final loc in campusLocations) {
      if (loc.latitude == null || loc.longitude == null) continue;
      final locLower = loc.name.toLowerCase().trim();
      // Skip current destination and start origin as they have prominent dedicated pins
      if (locLower == activeDestLower || locLower == activeOrigLower) continue;

      // Category filter check
      if (_selectedCategoryFilter != 'All') {
        if (_selectedCategoryFilter == 'Academic' && loc.category != 'Academic Block' && loc.category != 'Laboratory') continue;
        if (_selectedCategoryFilter == 'Dining' && loc.category != 'Canteen') continue;
        if (_selectedCategoryFilter == 'Hostels' && loc.category != 'Boys Hostel' && loc.category != 'Girls Hostel') continue;
        if (_selectedCategoryFilter == 'Sports' && loc.category != 'Sports Facility') continue;
        if (_selectedCategoryFilter == 'Landmarks' && loc.category != 'Landmark' && loc.category != 'Place of Worship') continue;
        if (_selectedCategoryFilter == 'Facilities' && loc.category != 'ATM' && loc.category != 'Medical Facility' && loc.category != 'Store' && loc.category != 'Auditorium' && loc.category != 'Administrative Block') continue;
        if (_selectedCategoryFilter == 'Transit' && loc.category != 'Transit') continue;
      }

      final color = _getCategoryColor(loc.category);
      final icon = _getCategoryIcon(loc.category);

      // Compact circular pin (26x26) with category border and crisp icon - Never clutters roads
      markers.add(
        Marker(
          point: LatLng(loc.latitude!, loc.longitude!),
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _showLocationInfoBottomSheet(loc),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1.5)),
                ],
              ),
              child: Center(
                child: Icon(icon, size: 13, color: color),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  /// Generates clean, spaced forward-pointing directional chevrons along the Dijkstra route
  List<Marker> _buildRouteDirectionArrows(List<LatLng> points) {
    if (points.length < 2) return [];
    final arrows = <Marker>[];
    const distance = Distance();

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final segDist = distance.as(LengthUnit.Meter, p1, p2);
      if (segDist < 25.0) continue;

      final bearing = DijkstraPathFinding.calculateBearing(p1, p2);
      // Clean spacing (~45m apart) so route stays legible and unobstructed
      final numArrows = (segDist / 45.0).floor().clamp(1, 4);
      final step = 1.0 / (numArrows + 1);

      for (int k = 1; k <= numArrows; k++) {
        final frac = k * step;
        final lat = p1.latitude + (p2.latitude - p1.latitude) * frac;
        final lng = p1.longitude + (p2.longitude - p1.longitude) * frac;

        arrows.add(
          Marker(
            point: LatLng(lat, lng),
            width: 18,
            height: 18,
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: bearing * math.pi / 180.0,
              child: const _RouteChevronArrow(),
            ),
          ),
        );
      }
    }
    return arrows;
  }

  /// Shows quick info modal when user taps any place on the map
  void _showLocationInfoBottomSheet(CampusLocation loc) {
    final color = _getCategoryColor(loc.category);
    final icon = _getCategoryIcon(loc.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, -4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                loc.category,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (loc.buildingCode.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                loc.buildingCode,
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                loc.description,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _selectNewDestination(loc);
                      },
                      icon: const Icon(Icons.directions_rounded, size: 20),
                      label: const Text('Route Here', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF155EEF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectNewDestination(CampusLocation loc) {
    setState(() {
      _stopSimulation();
      _cachedDestinationName = loc.name;
      _cachedLocation = loc;
      _navProgress = 0.0;
      _activeManeuverIndex = 0;
      _cachedDijkstraResult = PathFinding.getDijkstraRoute(
        startLocation: _cachedOrigin ?? 'Main Gate Entrance',
        stops: _cachedStops ?? const [],
        destination: loc,
        startLat: _currentDevicePosition?.latitude,
        startLng: _currentDevicePosition?.longitude,
      );
      if (_cachedDijkstraResult != null && _cachedDijkstraResult!.polylinePoints.isNotEmpty) {
        _fitRouteBounds(_cachedDijkstraResult!.polylinePoints);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureRouteComputed(context);

    final dijkstraResult = _cachedDijkstraResult ??
        PathFinding.getDijkstraRoute(
          startLocation: 'Main Gate Entrance',
          stops: const [],
          destination: _findLocation('Central Library'),
        );

    final location = _cachedLocation ?? _findLocation('Central Library');
    final origin = _cachedOrigin ?? 'Main Gate Entrance';

    final routePoints = dijkstraResult.polylinePoints;
    final maneuvers = dijkstraResult.maneuvers;

    final safeManeuverIndex = _activeManeuverIndex.clamp(0, (maneuvers.length - 1).clamp(0, 9999));
    final currentManeuver = maneuvers.isNotEmpty ? maneuvers[safeManeuverIndex] : null;
    final nextManeuver = (safeManeuverIndex + 1 < maneuvers.length) ? maneuvers[safeManeuverIndex + 1] : null;

    final double safeSliderValue =
        (_navProgress.isNaN || _navProgress.isInfinite) ? 0.0 : _navProgress.clamp(0.0, 1.0);

    // Dynamic distance calculation
    int remainingMeters = 0;
    int distanceToNextTurn = 0;

    LatLng userMarkerPosition;
    double userHeading = 0.0;

    if (_isLiveGpsMode && _currentDevicePosition != null) {
      userMarkerPosition = LatLng(_currentDevicePosition!.latitude, _currentDevicePosition!.longitude);
      userHeading = _currentDevicePosition!.heading;
      if (currentManeuver != null) {
        distanceToNextTurn = const Distance().as(LengthUnit.Meter, userMarkerPosition, currentManeuver.point).round();
      }
      if (routePoints.isNotEmpty) {
        remainingMeters = const Distance().as(LengthUnit.Meter, userMarkerPosition, routePoints.last).round();
      }
    } else {
      final pose = _calculatePathPose(routePoints, safeSliderValue);
      userMarkerPosition = pose.position;
      userHeading = pose.bearing;
      remainingMeters = ((1.0 - safeSliderValue) * dijkstraResult.totalDistanceMeters).round();
      if (currentManeuver != null) {
        final currentMeters = safeSliderValue * dijkstraResult.totalDistanceMeters;
        final turnDist = (currentManeuver.cumulativeDistanceMeters - currentMeters).round();
        distanceToNextTurn = turnDist > 0 ? turnDist : (currentManeuver.distanceMeters * (1.0 - safeSliderValue)).round().clamp(0, 500);
      }
    }

    final activeStyle = MapConfigService.instance.currentStyle;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // GOOGLE MAPS EMERALD GREEN NAVIGATION HUD
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F9D58), // Google Maps Navigation Emerald Green
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top Status & Navigation Controls Row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                        tooltip: 'Exit Navigation',
                        onPressed: () {
                          _stopSimulation();
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/navigation');
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiveGpsMode
                                    ? (_isOffCampus ? Icons.satellite_alt_rounded : Icons.gps_fixed_rounded)
                                    : Icons.directions_walk_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _isLiveGpsMode
                                      ? (_isOffCampus ? 'GPS (Outside Campus)' : 'Live Campus GPS')
                                      : 'Navigation Preview',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Voice Guidance Toggle
                      IconButton(
                        icon: Icon(
                          _isAudioGuidanceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: _isAudioGuidanceOn ? 'Mute Voice Guidance' : 'Unmute Voice Guidance',
                        onPressed: () {
                          setState(() => _isAudioGuidanceOn = !_isAudioGuidanceOn);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isAudioGuidanceOn ? '🔊 Voice Guidance On' : '🔇 Voice Guidance Muted'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      ),
                      // Layer Switcher
                      IconButton(
                        icon: const Icon(Icons.layers_rounded, color: Colors.white, size: 20),
                        tooltip: 'Switch Map Layer (${activeStyle.name})',
                        onPressed: _showLayerSelectionModal,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Maneuver Highlight Card
                  if (currentManeuver != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Icon(
                            currentManeuver.icon,
                            color: const Color(0xFF0F9D58),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                children: [
                                  Text(
                                    distanceToNextTurn <= 10 ? 'Turn now' : 'In $distanceToNextTurn m',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (currentManeuver.isShortcut)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Shortcut',
                                        style: TextStyle(
                                          color: Color(0xFF92400E),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                currentManeuver.shortAction == 'Arrived'
                                    ? 'Arrive at ${location.name}'
                                    : '${currentManeuver.shortAction} onto ${currentManeuver.roadName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (nextManeuver != null)
                                Text(
                                  'Then ${nextManeuver.instruction}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // OFF-CAMPUS NOTICE
            if (_isLiveGpsMode && _isOffCampus)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  border: Border(bottom: BorderSide(color: Color(0xFF334155))),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.satellite_alt_rounded, size: 16, color: Color(0xFFFBBF24)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Live GPS Connected',
                                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _currentDevicePosition != null
                                      ? '±${_currentDevicePosition!.accuracy.toStringAsFixed(0)}m'
                                      : 'Active',
                                  style: const TextStyle(fontSize: 9, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _currentDevicePosition != null
                                ? '${_currentDevicePosition!.latitude.toStringAsFixed(4)}° N, ${_currentDevicePosition!.longitude.toStringAsFixed(4)}° E • ${_distanceToCampusKm.toStringAsFixed(1)} km to Ettimadai'
                                : 'Device is outside Amrita campus',
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        InkWell(
                          onTap: () {
                            if (_currentDevicePosition != null) {
                              _safeMoveCamera(LatLng(_currentDevicePosition!.latitude, _currentDevicePosition!.longitude), 17.0);
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.my_location, size: 12, color: Color(0xFF38BDF8)),
                                SizedBox(width: 4),
                                Text('My GPS', style: TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _recenterOnCampus,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Campus Route', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // REAL INTERACTIVE MAP CANVAS (FULL HEIGHT, FULL CORS SUPPORT)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFF0F172A), // Dark base matching satellite imagery
                      child: RepaintBoundary(
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: const LatLng(amritaCampusCenterLat, amritaCampusCenterLng),
                            initialZoom: 16.8,
                            minZoom: activeStyle.minZoom,
                            maxZoom: activeStyle.maxZoom,
                            initialCameraFit: routePoints.length > 1
                                ? CameraFit.bounds(
                                    bounds: LatLngBounds.fromPoints(routePoints),
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                                  )
                                : null,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                            onPositionChanged: (camera, hasGesture) {
                              if (hasGesture && _followUser) {
                                setState(() {
                                  _followUser = false;
                                });
                              }
                            },
                            onMapReady: () {
                              if (!mounted) return;
                              setState(() {
                                _isMapReady = true;
                              });
                            },
                          ),
                        children: [
                          // 1. REAL BASE MAP TILE LAYER (ESRI Satellite / Google Maps / CartoDB)
                          TileLayer(
                            urlTemplate: MapConfigService.instance.getEffectiveTileUrl(activeStyle),
                            subdomains: activeStyle.subdomains,
                            userAgentPackageName: 'com.amrita.campus_navigator',
                            maxZoom: activeStyle.maxZoom,
                            minZoom: activeStyle.minZoom,
                            maxNativeZoom: activeStyle.maxNativeZoom, // Smooth overscaling above native resolution
                            panBuffer: 1,
                            errorTileCallback: (tile, error, stackTrace) {
                              _handleTileError(activeStyle);
                            },
                          ),

                          // 1b. HIGH-CONTRAST SATELLITE ROAD & PLACE LABELS OVERLAY (When on ESRI Satellite)
                          if (activeStyle.id == 'esri_imagery')
                            TileLayer(
                              urlTemplate: 'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                              subdomains: const [],
                              userAgentPackageName: 'com.amrita.campus_navigator',
                              maxZoom: activeStyle.maxZoom,
                              minZoom: activeStyle.minZoom,
                              maxNativeZoom: 18,
                              panBuffer: 1,
                            ),

                          // 2. VERY SUBTLE PEDESTRIAN PATHWAYS (Whisper overlay so satellite roads remain clean)
                          PolylineLayer(
                            polylines: [
                              for (final road in PathFinding.campusRoadPolylines)
                                Polyline(
                                  points: road,
                                  strokeWidth: 1.0,
                                  color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
                                  strokeCap: StrokeCap.round,
                                  strokeJoin: StrokeJoin.round,
                                ),
                            ],
                          ),

                          // 4. DIJKSTRA SHORTEST PATH ROAD POLYLINE (Clean professional dual-tone navigation path)
                          if (routePoints.length >= 2) ...[
                            PolylineLayer(
                              polylines: [
                                // Royal Navy contrast casing border
                                Polyline(
                                  points: routePoints,
                                  strokeWidth: 7.0,
                                  color: const Color(0xFF1E3A8A),
                                  strokeCap: StrokeCap.round,
                                  strokeJoin: StrokeJoin.round,
                                ),
                                // Vibrant solid navigation path
                                Polyline(
                                  points: routePoints,
                                  strokeWidth: 4.8,
                                  color: const Color(0xFF2563EB),
                                  strokeCap: StrokeCap.round,
                                  strokeJoin: StrokeJoin.round,
                                ),
                              ],
                            ),
                          ],

                          // 5. GEOFENCE / ACCURACY CIRCLE AROUND WALKER (Subtle, non-neon)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: userMarkerPosition,
                                radius: (_isLiveGpsMode && _currentDevicePosition != null)
                                    ? _currentDevicePosition!.accuracy.clamp(6.0, 45.0)
                                    : 14,
                                useRadiusInMeter: true,
                                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                borderColor: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                borderStrokeWidth: 1.2,
                              ),
                            ],
                          ),

                          // 6. MARKERS (Campus POIs, Direction Chevrons, Start, Destination, Active Turn, Walker Avatar)
                          MarkerLayer(
                            markers: [
                              // ALL ACTUAL CAMPUS PLACES FROM OPENSTREETMAP (Clean compact circular pins)
                              ..._buildCampusPoiMarkers(location, origin),

                              // DIRECTIONAL FLOW ARROW CHEVRONS ALONG ROUTE
                              ..._buildRouteDirectionArrows(routePoints),

                              // Start Location Marker (Origin)
                              if (routePoints.isNotEmpty)
                                Marker(
                                  point: routePoints.first,
                                  width: 120,
                                  height: 46,
                                  alignment: Alignment.topCenter,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF047857),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.white, width: 1.2),
                                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                                        ),
                                        child: Text(
                                          'Start: $origin',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Icon(Icons.location_on, color: Color(0xFF047857), size: 24),
                                    ],
                                  ),
                                ),

                              // Destination Building Marker
                              if (location.latitude != null && location.longitude != null)
                                Marker(
                                  point: LatLng(location.latitude!, location.longitude!),
                                  width: 130,
                                  height: 50,
                                  alignment: Alignment.topCenter,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.white, width: 1.2),
                                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                                        ),
                                        child: Text(
                                          location.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.location_on, color: Color(0xFFDC2626), size: 26),
                                    ],
                                  ),
                                ),

                              // Active Next Turn Indicator (Only indicates the upcoming turn, never cluttering the whole route)
                              if (currentManeuver != null && safeManeuverIndex < maneuvers.length - 1)
                                Marker(
                                  point: currentManeuver.point,
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF155EEF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.0),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        currentManeuver.icon,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),

                              // REAL DEVICE GPS MARKER (When outside campus boundary)
                              if (_isLiveGpsMode && _isOffCampus && _currentDevicePosition != null)
                                Marker(
                                  point: LatLng(_currentDevicePosition!.latitude, _currentDevicePosition!.longitude),
                                  width: 140,
                                  height: 48,
                                  alignment: Alignment.topCenter,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                                          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                                        ),
                                        child: Text(
                                          'Your Real GPS (${_distanceToCampusKm.toStringAsFixed(1)} km)',
                                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Icon(Icons.my_location, color: Color(0xFF0284C7), size: 22),
                                    ],
                                  ),
                                ),

                              // ANIMATED WALKING AVATAR WITH DIRECTIONAL POINTER
                              Marker(
                                point: userMarkerPosition,
                                width: 56,
                                height: 56,
                                child: _WalkerAvatar(
                                  heading: userHeading,
                                  isLiveGps: _isLiveGpsMode,
                                  isHeadingUp: _isHeadingUp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                  // FLOATING CAMERA CONTROLS
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Column(
                      children: [
                        // Dynamic Rotating Compass Button
                        Transform.rotate(
                          angle: _currentMapRotation * math.pi / 180.0,
                          child: _MapFloatingButton(
                            icon: Icons.explore_rounded,
                            tooltip: _isHeadingUp ? 'Heading-Up (Tap for North-Up)' : 'North-Up (Tap for Heading-Up)',
                            color: _isHeadingUp ? const Color(0xFFEA4335) : const Color(0xFF155EEF),
                            onPressed: () => _toggleCompassMode(userHeading),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MapFloatingButton(
                          icon: _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                          tooltip: _followUser ? 'Camera Following' : 'Follow Camera',
                          color: _followUser ? const Color(0xFF0F9D58) : Colors.black54,
                          onPressed: () {
                            setState(() => _followUser = !_followUser);
                            if (_followUser) {
                              _safeMoveCamera(userMarkerPosition, 18.0, rotation: _isHeadingUp ? -userHeading : 0.0);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapFloatingButton(
                          icon: Icons.crop_free,
                          tooltip: 'Fit Dijkstra Route',
                          onPressed: () => _fitRouteBounds(routePoints),
                        ),
                        const SizedBox(height: 8),
                        _MapFloatingButton(
                          icon: Icons.home_outlined,
                          tooltip: 'Amrita Campus Center',
                          onPressed: _recenterOnCampus,
                        ),
                        const SizedBox(height: 8),
                        // Dedicated Zoom Controls (+ and -)
                        _MapFloatingButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Zoom In (+)',
                          onPressed: _zoomIn,
                        ),
                        const SizedBox(height: 8),
                        _MapFloatingButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Zoom Out (-)',
                          onPressed: _zoomOut,
                        ),
                      ],
                    ),
                  ),

                  // ACTIVE MAP STYLE & POI FILTER BADGES
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Style Switcher Pill
                        InkWell(
                          onTap: _showLayerSelectionModal,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFDADCE0)),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(activeStyle.icon, size: 14, color: const Color(0xFF155EEF)),
                                const SizedBox(width: 6),
                                Text(
                                  activeStyle.name,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),

                        // Places Filter / Visibility Pill
                        InkWell(
                          onTap: _showPoiFilterModal,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _showPoiMarkers ? const Color(0xFF2563EB) : const Color(0xFFDADCE0),
                              ),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showPoiMarkers ? Icons.place_rounded : Icons.place_outlined,
                                  size: 13,
                                  color: _showPoiMarkers ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _showPoiMarkers ? 'Places: $_selectedCategoryFilter' : 'Places: Off',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _showPoiMarkers ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // FLOATING RE-CENTER BUTTON (Google Maps Style)
                  if (!_followUser)
                    Positioned(
                      bottom: 48,
                      right: 14,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          setState(() => _followUser = true);
                          _safeMoveCamera(
                            userMarkerPosition,
                            18.0,
                            rotation: _isHeadingUp ? -userHeading : 0.0,
                          );
                        },
                        backgroundColor: const Color(0xFF0F9D58),
                        foregroundColor: Colors.white,
                        elevation: 5,
                        icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                        label: const Text('Re-center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),

            // GOOGLE MAPS NAVIGATION BOTTOM SHEET
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -3)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pull indicator
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 1. CLEAR MODE SELECTOR TABS (Simulated Walk vs Live Device GPS)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (_isLiveGpsMode) _toggleLiveGpsMode(dijkstraResult, location, origin);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isLiveGpsMode ? const Color(0xFF0F9D58) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_walk_rounded, size: 16, color: !_isLiveGpsMode ? Colors.white : Colors.black54),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Simulated Walk',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: !_isLiveGpsMode ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (!_isLiveGpsMode) _toggleLiveGpsMode(dijkstraResult, location, origin);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isLiveGpsMode ? const Color(0xFF0F9D58) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isGpsLoading)
                                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                else
                                  Icon(Icons.gps_fixed_rounded, size: 16, color: _isLiveGpsMode ? Colors.white : Colors.black54),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Live Device GPS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isLiveGpsMode ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2. TOP METRICS ROW (Green ETA, remaining meters, arrival time, Red Exit Button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dijkstraResult.walkingTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    color: Color(0xFF0F9D58),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '• $remainingMeters m • ${_calculateEta(dijkstraResult.totalDistanceMeters)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF5F6368),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'To ${location.name} • ${_isLiveGpsMode ? "Live GPS" : "Simulation"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF70757A), fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Google Maps Red Circular Exit Button
                      InkWell(
                        onTap: () {
                          _stopSimulation();
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/navigation');
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEA4335), // Google Maps Red
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 3. ACTION CONTROLS ROW ACCORDING TO MODE
                  if (!_isLiveGpsMode) ...[
                    // SIMULATION CONTROLS
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _toggleSimulation(dijkstraResult, location, origin),
                          icon: Icon(_isNavigating ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                          label: Text(_isNavigating ? 'Pause' : 'Start Walk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isNavigating ? const Color(0xFF475569) : const Color(0xFF0F9D58),
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: const Size(100, 36),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _cycleSimSpeed,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: const Size(44, 36),
                          ),
                          child: Text(
                            '${_simSpeed}x',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () => _showStepsModal(dijkstraResult, location),
                          icon: const Icon(Icons.format_list_bulleted_rounded, size: 16),
                          label: const Text('Steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3C4043),
                            side: const BorderSide(color: Color(0xFFDADCE0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(70, 36),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Scrubber slider
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _previousManeuver(dijkstraResult),
                          icon: const Icon(Icons.skip_previous_rounded, color: Color(0xFF0F9D58), size: 22),
                          tooltip: 'Previous Turn',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              activeTrackColor: const Color(0xFF0F9D58),
                              inactiveTrackColor: const Color(0xFFE2E8F0),
                              thumbColor: const Color(0xFF0F9D58),
                            ),
                            child: Slider(
                              value: safeSliderValue,
                              onChanged: (val) {
                                setState(() {
                                  _navProgress = val;
                                  final currentMeters = val * dijkstraResult.totalDistanceMeters;
                                  for (int i = 0; i < maneuvers.length; i++) {
                                    if (currentMeters <= maneuvers[i].cumulativeDistanceMeters) {
                                      _activeManeuverIndex = i;
                                      break;
                                    }
                                  }
                                });
                                if (_followUser && _isMapReady) {
                                  final pose = _calculatePathPose(routePoints, val);
                                  _safeMoveCamera(
                                    pose.position,
                                    _mapController.camera.zoom,
                                    rotation: _isHeadingUp ? -pose.bearing : 0.0,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _nextManeuver(dijkstraResult),
                          icon: const Icon(Icons.skip_next_rounded, color: Color(0xFF0F9D58), size: 22),
                          tooltip: 'Next Turn',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ] else ...[
                    // LIVE GPS CONTROLS
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_currentDevicePosition != null) {
                              setState(() => _followUser = true);
                              _safeMoveCamera(
                                LatLng(_currentDevicePosition!.latitude, _currentDevicePosition!.longitude),
                                18.0,
                                rotation: _isHeadingUp ? -_currentDevicePosition!.heading : 0.0,
                              );
                            } else {
                              _startLiveGpsTracking(dijkstraResult, location, origin);
                            }
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 18),
                          label: const Text('Center on Me'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9D58),
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: const Size(120, 36),
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () => _showStepsModal(dijkstraResult, location),
                          icon: const Icon(Icons.format_list_bulleted_rounded, size: 16),
                          label: const Text('Steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3C4043),
                            side: const BorderSide(color: Color(0xFFDADCE0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(70, 36),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentDevicePosition != null
                                  ? 'Live GPS • ${_currentDevicePosition!.latitude.toStringAsFixed(4)}°, ${_currentDevicePosition!.longitude.toStringAsFixed(4)}° (±${_currentDevicePosition!.accuracy.toStringAsFixed(0)}m)'
                                  : 'Connecting to GPS Satellites...',
                              style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isGpsLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F9D58)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateEta(double distanceMeters) {
    final minutes = (distanceMeters / 72.0).ceil();
    final arrival = DateTime.now().add(Duration(minutes: minutes));
    final hour = arrival.hour > 12 ? arrival.hour - 12 : (arrival.hour == 0 ? 12 : arrival.hour);
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = arrival.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _MapFloatingButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _MapFloatingButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDADCE0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? const Color(0xFF155EEF), size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _WalkerAvatar extends StatelessWidget {
  final double heading;
  final bool isLiveGps;
  final bool isHeadingUp;

  const _WalkerAvatar({
    required this.heading,
    required this.isLiveGps,
    this.isHeadingUp = false,
  });

  @override
  Widget build(BuildContext context) {
    final safeHeading = heading.isNaN ? 0.0 : heading;
    final primaryColor = isLiveGps ? const Color(0xFF10B981) : const Color(0xFF155EEF);
    final displayAngle = isHeadingUp ? 0.0 : (safeHeading * math.pi / 180.0);

    return Transform.rotate(
      angle: displayAngle,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Direction Beam Cone (Soft, non-neon light field of view)
            CustomPaint(
              size: const Size(56, 56),
              painter: _VisionConePainter(color: primaryColor),
            ),

            // 2. High-precision clean GPS core dot with white rim and shadow
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 5,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(12, 12),
                  painter: const _PrecisionNavigationArrowPainter(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that renders a subtle, clean directional beam cone
class _VisionConePainter extends CustomPainter {
  final Color color;
  const _VisionConePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 26.0;
    const startAngle = -math.pi / 2 - 0.40; // ~23 degrees left of North
    const sweepAngle = 0.80; // ~46-degree beam

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, startAngle, sweepAngle, false)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VisionConePainter oldDelegate) => oldDelegate.color != color;
}

/// Custom painter for a sharp, mathematically centered navigation pointer arrowhead
class _PrecisionNavigationArrowPainter extends CustomPainter {
  final Color color;
  const _PrecisionNavigationArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final arrowPath = Path()
      ..moveTo(cx, cy - 5.5)
      ..lineTo(cx + 4.0, cy + 4.5)
      ..lineTo(cx, cy + 2.0)
      ..lineTo(cx - 4.0, cy + 4.5)
      ..close();
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant _PrecisionNavigationArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Clean minimalist route chevron arrow rendered along the Dijkstra polyline path
class _RouteChevronArrow extends StatelessWidget {
  const _RouteChevronArrow();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.keyboard_arrow_up_rounded,
      size: 18,
      color: Colors.white,
      shadows: [
        Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
      ],
    );
  }
}

// Confetti particle celebration animation widget
class ConfettiCelebrationWidget extends StatefulWidget {
  const ConfettiCelebrationWidget({super.key});

  @override
  State<ConfettiCelebrationWidget> createState() => _ConfettiCelebrationWidgetState();
}

class _ConfettiCelebrationWidgetState extends State<ConfettiCelebrationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  final List<Color> _colors = const [
    Color(0xFF155EEF),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 45; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          y: -0.1 - _random.nextDouble() * 0.5,
          size: _random.nextDouble() * 7 + 4,
          color: _colors[_random.nextInt(_colors.length)],
          vx: (_random.nextDouble() - 0.5) * 1.5,
          vy: _random.nextDouble() * 2.0 + 1.2,
          rotation: _random.nextDouble() * 2 * math.pi,
          vRot: (_random.nextDouble() - 0.5) * 0.2,
        ),
      );
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