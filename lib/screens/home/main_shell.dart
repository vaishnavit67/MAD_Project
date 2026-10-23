import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../settings/settings_screen.dart';
import '../navigation/navigation_screen.dart';
import '../events/events_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/tasks/screens/tasks_screen.dart';
import '../../services/auth_service.dart';
import '../../services/deep_link_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.checkAndOpenPendingEvent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVisitor = AuthService.isVisitor;

    final List<Widget> screens = isVisitor
        ? [
            const HomeScreen(),
            const NavigationScreen(),
            const EventsScreen(),
            const SettingsScreen(),
          ]
        : [
            const HomeScreen(),
            const TasksScreen(),
            const CalendarScreen(),
            const SettingsScreen(),
          ];

    final List<BottomNavigationBarItem> items = isVisitor
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.navigation_rounded), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.event_rounded), label: 'Events'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ];

    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

    return Scaffold(
      body: screens[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: items,
      ),
    );
  }
}
