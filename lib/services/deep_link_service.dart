import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event.dart';
import '../data/mock_data.dart';
import '../screens/events/event_detail_page.dart';
import 'event_service.dart';

/// Service managing deep linking for Campus Connect events.
/// Handles external QR scans via system camera / Google Lens,
/// in-app QR scanner detections, and custom URI schemes:
/// - `https://campusconnect.amrita.edu/event?id=...`
/// - `campusconnect://event?id=...`
///
/// Automatically copies the event link to the user's clipboard
/// and navigates directly to that particular event page,
/// allowing guest viewing with an option to log in if desired.
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  static DeepLinkService get instance => _instance;

  static const MethodChannel _channel = MethodChannel('com.campusconnect.app/deeplink');

  DeepLinkService._internal();

  bool _initialized = false;
  Event? _pendingEvent;
  String? _pendingEventId;

  Event? get pendingEvent => _pendingEvent;
  String? get pendingEventId => _pendingEventId;

  GlobalKey<NavigatorState>? navigatorKey;
  GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  /// Initialize deep link listener and check for cold-start initial links
  Future<void> init({
    required GlobalKey<NavigatorState> navKey,
    GlobalKey<ScaffoldMessengerState>? messengerKey,
  }) async {
    navigatorKey = navKey;
    scaffoldMessengerKey = messengerKey;

    if (_initialized) return;
    _initialized = true;

    // 1. Listen for new incoming deep links while app is running in background/foreground
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final uriString = call.arguments as String?;
        if (uriString != null && uriString.isNotEmpty) {
          debugPrint('[DeepLinkService] Received onDeepLink: $uriString');
          await handleLink(uriString);
        }
      }
    });

    // 2. Check for cold-start initial deep link (e.g. app launched directly by camera scan)
    try {
      final initialLink = await _channel.invokeMethod<String>('getInitialLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        debugPrint('[DeepLinkService] Cold start deep link detected: $initialLink');
        // Give the UI time to build first frame, then handle
        Future.delayed(const Duration(milliseconds: 600), () {
          handleLink(initialLink);
        });
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Cold start link notice: $e');
    }
  }

  /// Process any scanned or received event link
  Future<bool> handleLink(String rawInput, {BuildContext? context}) async {
    final cleanInput = rawInput.trim();
    if (cleanInput.isEmpty) return false;

    // 1. Extract Event ID and optional metadata from URI query parameters
    String? eventId;
    String? titleParam;
    String? locParam;
    String? dateParam;
    String? timeParam;
    String? endTimeParam;
    String? catParam;
    String? orgParam;
    int? capacityParam;
    int? seatsParam;
    String? imgParam;

    final uri = Uri.tryParse(cleanInput);

    if (uri != null) {
      if (uri.queryParameters.containsKey('id')) {
        eventId = uri.queryParameters['id'];
      } else if (uri.pathSegments.isNotEmpty) {
        final lastSeg = uri.pathSegments.last;
        if (lastSeg != 'event' && lastSeg != 'events') {
          eventId = lastSeg;
        }
      }

      titleParam = uri.queryParameters['title'];
      locParam = uri.queryParameters['loc'] ?? uri.queryParameters['location'];
      dateParam = uri.queryParameters['date'];
      timeParam = uri.queryParameters['time'];
      endTimeParam = uri.queryParameters['endTime'];
      catParam = uri.queryParameters['cat'] ?? uri.queryParameters['category'];
      orgParam = uri.queryParameters['org'] ?? uri.queryParameters['organizer'];
      capacityParam = int.tryParse(uri.queryParameters['cap'] ?? uri.queryParameters['capacity'] ?? '');
      seatsParam = int.tryParse(uri.queryParameters['seats'] ?? '');
      imgParam = uri.queryParameters['img'];
    }

    eventId ??= cleanInput;
    if (eventId.isEmpty) return false;

    // 2. Always copy the event link to the user's clipboard
    final String shareableLink;
    if (cleanInput.startsWith('http://') || cleanInput.startsWith('https://')) {
      if (cleanInput.contains('?')) {
        shareableLink = cleanInput;
      } else {
        shareableLink = 'https://campusconnect.amrita.edu/event?id=$eventId';
      }
    } else {
      shareableLink = 'https://campusconnect.amrita.edu/event?id=$eventId';
    }
    try {
      await Clipboard.setData(ClipboardData(text: shareableLink));
      debugPrint('[DeepLinkService] Successfully copied event link to clipboard: $shareableLink');
    } catch (e) {
      debugPrint('[DeepLinkService] Clipboard error: $e');
    }

    // 3. Resolve the target Event model (never null - has resilient fallbacks)
    final targetEvent = await _resolveEvent(
      eventId,
      titleParam: titleParam,
      locParam: locParam,
      dateParam: dateParam,
      timeParam: timeParam,
      endTimeParam: endTimeParam,
      catParam: catParam,
      orgParam: orgParam,
      capacityParam: capacityParam,
      seatsParam: seatsParam,
      imgParam: imgParam,
    );

    _pendingEvent = targetEvent;
    _pendingEventId = targetEvent.id;

    // Show copy feedback SnackBar
    _showCopyNotification(targetEvent.title, shareableLink);

    // 4. Navigate directly to that particular event page
    _navigateToEvent(targetEvent);
    return true;
  }

  /// Check and open any pending event that was queued during app startup / splash
  Future<void> checkAndOpenPendingEvent() async {
    if (_pendingEvent != null) {
      final event = _pendingEvent!;
      _pendingEvent = null;
      _pendingEventId = null;
      _navigateToEvent(event);
      return;
    }

    if (_pendingEventId != null) {
      final id = _pendingEventId!;
      _pendingEventId = null;
      final event = await _resolveEvent(id);
      _navigateToEvent(event);
    }
  }

  Future<Event> _resolveEvent(
    String eventId, {
    String? titleParam,
    String? locParam,
    String? dateParam,
    String? timeParam,
    String? endTimeParam,
    String? catParam,
    String? orgParam,
    int? capacityParam,
    int? seatsParam,
    String? imgParam,
  }) async {
    final lowerId = eventId.toLowerCase();

    // 1. Check MockData.events by exact or lower-case id
    try {
      final mock = MockData.events.where((e) => e.id.toLowerCase() == lowerId);
      if (mock.isNotEmpty) return mock.first;
    } catch (_) {}

    // 2. Check MockData.events by title keyword
    try {
      final mockByTitle = MockData.events.where((e) => e.title.toLowerCase().contains(lowerId));
      if (mockByTitle.isNotEmpty) return mockByTitle.first;
    } catch (_) {}

    // 3. Query MongoDB backend directly via getEventById with 2-second timeout
    try {
      final backendEvent = await EventService.instance.getEventById(eventId).timeout(const Duration(seconds: 2));
      if (backendEvent != null) return backendEvent;
    } catch (_) {}

    // 4. Query live events list with 2-second timeout
    try {
      final liveEvents = await EventService.instance.getEvents().timeout(const Duration(seconds: 2));
      final match = liveEvents.where((e) => e.id.toLowerCase() == lowerId);
      if (match.isNotEmpty) return match.first;
    } catch (_) {}

    // 5. Build event from QR query parameters if available
    DateTime parsedDate = DateTime.now().add(const Duration(days: 1));
    if (dateParam != null) {
      parsedDate = DateTime.tryParse(dateParam) ?? parsedDate;
    }

    final resolvedTitle = titleParam?.trim().isNotEmpty == true
        ? titleParam!.trim()
        : (eventId.length < 20 ? 'Campus Event: ${eventId.toUpperCase()}' : 'Featured Campus Event');

    return Event(
      id: eventId,
      title: resolvedTitle,
      description: 'Campus event shared via Campus Connect. View details and register to attend.',
      date: parsedDate,
      timeString: timeParam?.trim().isNotEmpty == true ? timeParam!.trim() : '10:00 AM',
      endTimeString: endTimeParam?.trim(),
      location: locParam?.trim().isNotEmpty == true ? locParam!.trim() : 'Campus Main Block / Auditorium',
      organizer: orgParam?.trim().isNotEmpty == true ? orgParam!.trim() : 'Event Coordinator',
      category: catParam?.trim().isNotEmpty == true ? catParam!.trim() : 'Technology',
      capacity: capacityParam ?? 100,
      availableSeats: seatsParam ?? 60,
      imageUrl: imgParam,
    );
  }

  void _navigateToEvent(Event event) {
    void pushRoute() {
      final nav = navigatorKey?.currentState;
      if (nav == null) {
        debugPrint('[DeepLinkService] NavigatorState not yet available, cached in _pendingEvent');
        _pendingEvent = event;
        return;
      }

      _pendingEvent = null;
      _pendingEventId = null;

      nav.push(
        MaterialPageRoute(
          builder: (_) => EventDetailPage(event: event),
        ),
      );
    }

    if (WidgetsBinding.instance.isRootWidgetAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pushRoute());
    } else {
      Future.delayed(const Duration(milliseconds: 300), pushRoute);
    }
  }

  void _showCopyNotification(String eventTitle, String link) {
    final messenger = scaffoldMessengerKey?.currentState;
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event link copied to clipboard!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                Text(
                  eventTitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    if (messenger != null) {
      messenger.showSnackBar(snackBar);
    }
  }
}
