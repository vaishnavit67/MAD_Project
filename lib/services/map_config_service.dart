import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum MapProvider {
  cartoDb,
  googleMaps,
  mapTiler,
  openStreetMap,
  esri,
  mapbox,
}

class MapStyleOption {
  final String id;
  final String name;
  final String subtitle;
  final MapProvider provider;
  final String urlTemplate;
  final List<String> subdomains;
  final IconData icon;
  final bool requiresApiKey;
  final bool isCorsSafe;
  final double maxZoom;
  final double minZoom;
  final int maxNativeZoom;

  const MapStyleOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.provider,
    required this.urlTemplate,
    this.subdomains = const ['a', 'b', 'c', 'd'],
    required this.icon,
    this.requiresApiKey = false,
    this.isCorsSafe = true,
    this.maxZoom = 20.5,
    this.minZoom = 12.0,
    this.maxNativeZoom = 18,
  });
}

class MapConfigService extends ChangeNotifier {
  static final MapConfigService _instance = MapConfigService._internal();
  factory MapConfigService() => _instance;
  static MapConfigService get instance => _instance;

  MapConfigService._internal() {
    _apiKey = mapApiKeyEnv;
  }

  String _apiKey = defaultGoogleMapsApiKey;
  int _selectedStyleIndex = 0; // Default to High-Res Satellite Imagery as requested

  String get apiKey => _apiKey;
  bool get hasCustomApiKey => _apiKey.isNotEmpty && _apiKey != defaultGoogleMapsApiKey;

  int get selectedStyleIndex => _selectedStyleIndex;
  MapStyleOption get currentStyle => availableStyles[_selectedStyleIndex];

  final List<MapStyleOption> availableStyles = const [
    MapStyleOption(
      id: 'esri_imagery',
      name: 'Satellite Map (High-Res Aerial)',
      subtitle: 'Photorealistic satellite photography • 100% CORS-safe on Web & Mobile',
      provider: MapProvider.esri,
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      icon: Icons.satellite_alt_rounded,
      requiresApiKey: false,
      isCorsSafe: true,
      maxZoom: 20.5,
      minZoom: 12.0,
      maxNativeZoom: 18, // Max native resolution in Ettimadai; zooms > 18 are smoothly overscaled
    ),
    MapStyleOption(
      id: 'google_hybrid',
      name: 'Google Maps (Satellite Hybrid)',
      subtitle: 'Real satellite aerial photography with road label overlays',
      provider: MapProvider.googleMaps,
      urlTemplate: 'https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}{keyParam}',
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
      icon: Icons.satellite_outlined,
      requiresApiKey: true,
      isCorsSafe: false,
      maxZoom: 20.0,
      minZoom: 12.0,
      maxNativeZoom: 20,
    ),
    MapStyleOption(
      id: 'carto_voyager',
      name: 'Campus Streets (HD Voyager)',
      subtitle: 'Fast, high-contrast streets • 100% CORS-safe on Web & Mobile',
      provider: MapProvider.cartoDb,
      urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
      subdomains: ['a', 'b', 'c', 'd'],
      icon: Icons.map_rounded,
      requiresApiKey: false,
      isCorsSafe: true,
      maxZoom: 20.5,
      minZoom: 12.0,
      maxNativeZoom: 19,
    ),
    MapStyleOption(
      id: 'google_streets',
      name: 'Google Maps (Streets)',
      subtitle: 'Official Google Maps street road network & building outlines',
      provider: MapProvider.googleMaps,
      urlTemplate: 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}{keyParam}',
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
      icon: Icons.explore_rounded,
      requiresApiKey: true,
      isCorsSafe: false,
      maxZoom: 20.0,
      minZoom: 12.0,
      maxNativeZoom: 20,
    ),
    MapStyleOption(
      id: 'google_terrain',
      name: 'Google Maps (Terrain)',
      subtitle: 'Topographical terrain elevation with Ettimadai hills',
      provider: MapProvider.googleMaps,
      urlTemplate: 'https://{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}{keyParam}',
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
      icon: Icons.terrain_rounded,
      requiresApiKey: true,
      isCorsSafe: false,
      maxZoom: 19.5,
      minZoom: 12.0,
      maxNativeZoom: 16,
    ),
    MapStyleOption(
      id: 'osm_standard',
      name: 'OpenStreetMap (Standard)',
      subtitle: 'Community-driven global street cartography',
      provider: MapProvider.openStreetMap,
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: [],
      icon: Icons.public_rounded,
      requiresApiKey: false,
      isCorsSafe: true,
      maxZoom: 19.0,
      minZoom: 12.0,
      maxNativeZoom: 19,
    ),
    MapStyleOption(
      id: 'carto_positron',
      name: 'CartoDB Positron (Clean Light)',
      subtitle: 'Minimalist light gray background for high route visibility',
      provider: MapProvider.cartoDb,
      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
      subdomains: ['a', 'b', 'c', 'd'],
      icon: Icons.wb_sunny_outlined,
      requiresApiKey: false,
      isCorsSafe: true,
      maxZoom: 20.5,
      minZoom: 12.0,
      maxNativeZoom: 19,
    ),
    MapStyleOption(
      id: 'maptiler_streets',
      name: 'MapTiler Streets (Vector HD)',
      subtitle: 'High precision vector rasterized street tiles',
      provider: MapProvider.mapTiler,
      urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key={key}',
      subdomains: [],
      icon: Icons.alt_route_rounded,
      requiresApiKey: true,
      isCorsSafe: true,
      maxZoom: 20.0,
      minZoom: 12.0,
      maxNativeZoom: 19,
    ),
    MapStyleOption(
      id: 'esri_streets',
      name: 'ESRI World Street Map',
      subtitle: 'ArcGIS enterprise street cartography & landmarks',
      provider: MapProvider.esri,
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      icon: Icons.streetview_outlined,
      requiresApiKey: false,
      isCorsSafe: true,
      maxZoom: 19.0,
      minZoom: 12.0,
      maxNativeZoom: 18,
    ),
    MapStyleOption(
      id: 'carto_dark',
      name: 'Dark Matter (Night Mode)',
      subtitle: 'Sleek dark theme for night navigation • 100% CORS-safe',
      provider: MapProvider.cartoDb,
      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
      subdomains: ['a', 'b', 'c', 'd'],
      icon: Icons.dark_mode_rounded,
      requiresApiKey: false,
      isCorsSafe: true,
      maxZoom: 20.5,
      minZoom: 12.0,
      maxNativeZoom: 19,
    ),
  ];

  void setApiKey(String key) {
    _apiKey = key.trim();
    notifyListeners();
  }

  void resetToDefaultKey() {
    _apiKey = defaultGoogleMapsApiKey;
    notifyListeners();
  }

  void selectStyle(int index) {
    if (index >= 0 && index < availableStyles.length) {
      _selectedStyleIndex = index;
      notifyListeners();
    }
  }

  void cycleNextStyle() {
    _selectedStyleIndex = (_selectedStyleIndex + 1) % availableStyles.length;
    notifyListeners();
  }

  /// Builds the parameterized tile URL substituting `{key}`, `{apiKey}`, or `{keyParam}`
  String getEffectiveTileUrl(MapStyleOption style) {
    String url = style.urlTemplate;

    if (style.provider == MapProvider.googleMaps) {
      // If an API key is provided and valid, attach it as &key=
      final keyParam = _apiKey.isNotEmpty ? '&key=$_apiKey' : '';
      url = url.replaceAll('{keyParam}', keyParam);
    } else if (style.provider == MapProvider.mapTiler) {
      final keyToUse = _apiKey.isNotEmpty ? _apiKey : defaultMapTilerApiKey;
      url = url.replaceAll('{key}', keyToUse);
    } else if (style.provider == MapProvider.mapbox) {
      url = url.replaceAll('{key}', _apiKey);
    }

    return url;
  }
}
