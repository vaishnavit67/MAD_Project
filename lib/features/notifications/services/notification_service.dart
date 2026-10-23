import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_model.dart';
import 'in_app_notification_service.dart';
import '../../../../services/auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('[NotificationService] Web environment detected; skipping native local notifications.');
      return;
    }

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {},
      );

      _requestPermissions();
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  void _requestPermissions() {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('[NotificationService] Request permissions error: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (scheduledTime.isBefore(DateTime.now())) return;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'campus_connect_channel',
            'Campus Connect Notifications',
            channelDescription: 'Reminders for events and tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleNotification error: $e');
    }
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String type = 'announcement',
    String? payload,
    String? targetRecipientRole,
    String? targetRecipientId,
    String? relatedClubId,
  }) async {
    final currentUserId = AuthService.currentUser?.id;
    final currentUserEmail = AuthService.currentUser?.email;
    final currentRole = AuthService.currentRole;

    final roleMatches = targetRecipientRole == null ||
        targetRecipientRole.toLowerCase() == 'all' ||
        targetRecipientRole.toLowerCase() == currentRole.toLowerCase();

    final idMatches = (targetRecipientId == null || targetRecipientId == 'all')
        ? roleMatches
        : ((currentUserId != null && targetRecipientId == currentUserId) ||
           (currentUserEmail != null && targetRecipientId.toLowerCase() == currentUserEmail.toLowerCase()));

    final isForCurrentUser = roleMatches && idMatches;

    // 1. Add to In-App Notification Feed for intended recipient
    try {
      await InAppNotificationService().addNotification(
        NotificationModel(
          id: 'push_${DateTime.now().millisecondsSinceEpoch}_$id',
          title: title,
          message: body,
          timestamp: DateTime.now(),
          type: type,
          isRead: false,
          relatedClubId: relatedClubId,
        ),
        recipientRole: targetRecipientRole,
        recipientId: targetRecipientId,
        relatedClubId: relatedClubId,
      );
    } catch (e) {
      debugPrint('[NotificationService] InApp inbox error: $e');
    }

    // 2. Dispatch Native Device Push/Local Notification ONLY if meant for the active user on this phone
    if (kIsWeb || !isForCurrentUser) return;
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'campus_connect_channel',
        'Campus Connect Notifications',
        channelDescription: 'Instant alerts for clubs, events, and lost items',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showInstantNotification error: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('[NotificationService] cancelNotification error: $e');
    }
  }
}
