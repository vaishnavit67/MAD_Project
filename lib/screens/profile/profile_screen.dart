import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/mock_data.dart';
import '../../services/auth_service.dart';
import '../settings/settings_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeUser = AuthService.currentUser;
    final user = MockData.currentUser;
    final userName = activeUser?.name.isNotEmpty == true ? activeUser!.name : user.name;
    final userEmail = activeUser?.email.isNotEmpty == true ? activeUser!.email : user.email;
    final userRole = AuthService.currentRole;
    final isVisitor = AuthService.isVisitor;

    String subtitle = '${user.department} • ${user.year}';
    if (activeUser != null) {
      if (activeUser.role == 'Student') {
        subtitle = 'Student • ${activeUser.rollNumber}\n$userEmail';
      } else if (activeUser.role == 'Faculty') {
        subtitle = 'Faculty Member • Amrita Vishwa Vidyapeetham\n$userEmail';
      } else {
        subtitle = 'Campus Visitor\n$userEmail';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: isVisitor ? const Color(0xFFF59E0B) : AppColors.primary,
              child: const Icon(Icons.person, size: 50, color: AppColors.white),
            ),
            const SizedBox(height: 16),
            Text(userName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isVisitor ? const Color(0xFFFDE68A) : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                userRole,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: isVisitor ? const Color(0xFFB45309) : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (!isVisitor) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Posts', user.postsCount.toString()),
                  _buildStatColumn('Clubs', user.clubsCount.toString()),
                  _buildStatColumn('Events', user.eventsCount.toString()),
                ],
              ),
              const SizedBox(height: 24),
            ],
            _buildProfileListTile(Icons.history_rounded, 'Navigation History', () {
              Navigator.pushNamed(context, '/history');
            }),
            if (!isVisitor) ...[
              _buildProfileListTile(Icons.post_add, 'My Lost & Found Posts', () {
                Navigator.pushNamed(context, '/home');
              }),
              _buildProfileListTile(Icons.book_online, 'My Event Registrations', () {}),
            ],
            _buildProfileListTile(Icons.info_outline_rounded, 'Campus Directory', () {}),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }

  Widget _buildProfileListTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
