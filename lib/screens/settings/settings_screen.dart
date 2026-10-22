import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Appearance ──────────────────────────────────────────────
          _sectionHeader('APPEARANCE'),
          _switchTile(
            icon: Icons.dark_mode_rounded,
            iconColor: const Color(0xFF5C6BC0),
            title: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            value: _settings.isDarkMode,
            onChanged: (v) async {
              await _settings.setDarkMode(v);
              CampusConnectApp.themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
              setState(() {});
            },
          ),

          const SizedBox(height: 16),

          // ── Notifications ───────────────────────────────────────────
          _sectionHeader('NOTIFICATIONS'),
          _switchTile(
            icon: Icons.notifications_rounded,
            iconColor: AppColors.primary,
            title: 'Notifications',
            subtitle: 'Enable push notifications',
            value: _settings.notificationsEnabled,
            onChanged: (v) async {
              await _settings.setNotificationsEnabled(v);
              setState(() {});
            },
          ),
          _switchTile(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            title: 'Task Reminders',
            subtitle: 'Remind before task deadlines',
            value: _settings.taskRemindersEnabled,
            onChanged: _settings.notificationsEnabled
                ? (v) async {
                    await _settings.setTaskReminders(v);
                    setState(() {});
                  }
                : null,
          ),
          _switchTile(
            icon: Icons.event_rounded,
            iconColor: const Color(0xFFF57C00),
            title: 'Event Reminders',
            subtitle: 'Remind before events start',
            value: _settings.eventRemindersEnabled,
            onChanged: _settings.notificationsEnabled
                ? (v) async {
                    await _settings.setEventReminders(v);
                    setState(() {});
                  }
                : null,
          ),

          const SizedBox(height: 16),

          // ── General ─────────────────────────────────────────────────
          _sectionHeader('GENERAL'),
          _switchTile(
            icon: Icons.volume_up_rounded,
            iconColor: const Color(0xFF00897B),
            title: 'Sound',
            subtitle: 'Enable notification sounds',
            value: _settings.soundEnabled,
            onChanged: (v) async {
              await _settings.setSoundEnabled(v);
              setState(() {});
            },
          ),
          _switchTile(
            icon: Icons.vibration_rounded,
            iconColor: const Color(0xFF8E24AA),
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on interactions',
            value: _settings.hapticEnabled,
            onChanged: (v) async {
              await _settings.setHapticEnabled(v);
              setState(() {});
            },
          ),

          const SizedBox(height: 16),

          // ── About ───────────────────────────────────────────────────
          _sectionHeader('ABOUT'),
          _actionTile(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF546E7A),
            title: 'About Campus Connect',
            onTap: () => _showAbout(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
          ),

          const SizedBox(height: 16),

          // ── Account ─────────────────────────────────────────────────
          _sectionHeader('ACCOUNT'),
          _actionTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Logout',
            titleColor: AppColors.error,
            onTap: () => _confirmLogout(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyMedium?.color, letterSpacing: 1)),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final enabled = onChanged != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: enabled ? iconColor : Theme.of(context).disabledColor, size: 20),
        ),
        title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: enabled ? null : Theme.of(context).disabledColor)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Switch.adaptive(
          value: value,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: titleColor)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.school_rounded, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Campus Connect', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: TextStyle(fontSize: 13, color: Theme.of(ctx).textTheme.bodyMedium?.color)),
            const SizedBox(height: 12),
            Text(
              'Campus Connect is a unified campus companion for students. Discover events, track tasks, navigate campus, and stay connected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Theme.of(ctx).textTheme.bodyMedium?.color, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
