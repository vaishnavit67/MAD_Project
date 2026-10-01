import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/destination_screen.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const CampusConnectApp());
}

class CampusConnectApp extends StatelessWidget {
  const CampusConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Connect',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/destination': (context) => const DestinationScreen(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}