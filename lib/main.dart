import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'services/mongodb_service.dart';
import 'services/history_service.dart';
import 'services/settings_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/services/in_app_notification_service.dart';
import 'features/calendar/services/event_service.dart';
import 'features/calendar/services/class_service.dart';
import 'features/tasks/services/task_service.dart';
import 'screens/events/event_registration_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/navigation/navigation_screen.dart';
import 'screens/navigation/destination_screen.dart';
import 'screens/navigation/map_screen.dart';
import 'screens/navigation/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER_ERROR_STACK: ${details.exceptionAsString()}\n${details.stack}');
  };

  // 1. Initialize Hive storage (bypass path_provider on Web)
  try {
    if (kIsWeb) {
      Hive.init(null);
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocDir.path);
    }
  } catch (e) {
    debugPrint('Hive init notice: $e');
  }

  // 2. Initialize independent services with individual fail-safes
  if (!kIsWeb) {
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('NotificationService init notice: $e');
    }
  }

  try {
    await EventService().init();
  } catch (e) {
    debugPrint('EventService init notice: $e');
  }

  try {
    await TaskService().init();
  } catch (e) {
    debugPrint('TaskService init notice: $e');
  }

  try {
    await ClassService().init();
  } catch (e) {
    debugPrint('ClassService init notice: $e');
  }

  try {
    await EventRegistrationService().init();
  } catch (e) {
    debugPrint('EventRegistrationService init notice: $e');
  }

  try {
    await InAppNotificationService().init();
  } catch (e) {
    debugPrint('InAppNotificationService init notice: $e');
  }

  try {
    await HistoryService().init();
  } catch (e) {
    debugPrint('HistoryService init notice: $e');
  }

  try {
    await SettingsService().init();
  } catch (e) {
    debugPrint('SettingsService init notice: $e');
  }

  // 3. Firebase initialization with timeout guard
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // 4. MongoDB service initialization with timeout guard
  try {
    await MongoDbService.instance.initialize(timeout: const Duration(seconds: 2));
  } catch (e) {
    debugPrint('MongoDB initialization notice: $e');
  }

  // 5. Determine initial theme safely
  ThemeMode initialMode = ThemeMode.light;
  try {
    initialMode = SettingsService().isDarkMode ? ThemeMode.dark : ThemeMode.light;
  } catch (e) {
    debugPrint('Theme mode evaluation notice: $e');
  }

  // 6. Mount application unconditionally
  runApp(CampusConnectApp(initialThemeMode: initialMode));
}

class CampusConnectApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const CampusConnectApp({super.key, this.initialThemeMode = ThemeMode.light});

  /// Global key so Settings can toggle theme mode
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  @override
  State<CampusConnectApp> createState() => _CampusConnectAppState();
}

class _CampusConnectAppState extends State<CampusConnectApp> {
  @override
  void initState() {
    super.initState();
    CampusConnectApp.themeNotifier.value = widget.initialThemeMode;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: CampusConnectApp.themeNotifier,
      builder: (_, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const MainShell(),
            '/navigation': (context) => const NavigationScreen(),
            '/destination': (context) => const DestinationScreen(),
            '/map': (context) => const MapScreen(),
            '/history': (context) => const HistoryScreen(),
          },
        );
      },
    );
  }
}