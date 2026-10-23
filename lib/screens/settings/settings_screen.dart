import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../services/mongodb_service.dart';
import '../../features/calendar/services/class_service.dart';
import '../../features/tasks/services/task_service.dart';
import '../../services/club_service.dart';
import '../../features/notifications/services/in_app_notification_service.dart';
import '../../main.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  bool _checkingServer = false;
  bool _syncingData = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    setState(() => _checkingServer = true);
    await MongoDbService.instance.checkBackendAvailable();
    if (mounted) setState(() => _checkingServer = false);
  }

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

          // ── Server Connection & Cloud Sync ──────────────────────────
          _sectionHeader('SERVER CONNECTION & CLOUD SYNC'),
          _buildServerStatusCard(),
          _actionTile(
            icon: Icons.dns_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Configure Server Address',
            subtitle: MongoDbService.instance.backendUrl,
            onTap: () => _showServerConfigDialog(context),
          ),
          _actionTile(
            icon: Icons.sync_rounded,
            iconColor: const Color(0xFF10B981),
            title: _syncingData ? 'Synchronizing...' : 'Sync Cloud & Local Database',
            subtitle: 'Sync timetable, clubs, tasks & notifications',
            trailing: _syncingData
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: _syncingData ? () {} : () => _syncAllData(),
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

  Widget _buildServerStatusCard() {
    final isOnline = MongoDbService.instance.isBackendAvailable;
    final currentUrl = MongoDbService.instance.backendUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOnline
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'Online • Server Connected' : 'Standalone Mode • Local DB',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isOnline ? const Color(0xFF059669) : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentUrl,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Test Connection',
                  icon: _checkingServer
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded),
                  onPressed: _checkingServer
                      ? null
                      : () async {
                          setState(() => _checkingServer = true);
                          final ok = await MongoDbService.instance.probeAndSelectBackendUrl(force: true);
                          if (mounted) {
                            setState(() => _checkingServer = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Connected to server: ${MongoDbService.instance.backendUrl}'
                                    : 'Server not reachable. App is running in resilient Offline Mode.'),
                                backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
    String? subtitle,
    Widget? trailing,
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
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  // ── Dialogs & Sync ─────────────────────────────────────────────────────────────

  void _showServerConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: MongoDbService.instance.backendUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Configure Backend Server', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend URL or select a preset to sync with your laptop over Wi-Fi or USB:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://10.12.252.91:5000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            const Text('QUICK PRESETS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Wi-Fi (10.12.252.91)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.12.252.91:5000',
                ),
                ActionChip(
                  label: const Text('USB adb (127.0.0.1)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://127.0.0.1:5000',
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.0.2.2:5000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                MongoDbService.instance.configureBackend(url: newUrl);
                Navigator.pop(ctx);
                await _checkServer();
              }
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncAllData() async {
    setState(() => _syncingData = true);
    try {
      await Future.wait([
        ClassService().fetchClassesFromBackend(),
        TaskService().fetchTasksFromBackend(),
        ClubService.instance.getClubs(),
        InAppNotificationService().fetchNotificationsFromBackend(),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Cloud & local synchronization completed successfully!')),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync finished with local database active ($e)'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncingData = false);
      }
    }
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
