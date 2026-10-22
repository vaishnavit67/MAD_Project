import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/mock_data.dart';
import '../auth/login_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;

    return Drawer(
      child: Container(
        color: AppColors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 64, bottom: 32, left: 24, right: 24),
              color: AppColors.primary,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.white,
                    child: Icon(Icons.person, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.department} • ${user.year}',
                    style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildMenuItem(Icons.person_outline, 'My Profile', () {}),
                  _buildMenuItem(Icons.local_activity_outlined, 'My Activity', () {}),
                  _buildMenuItem(Icons.book_online_outlined, 'My Bookings', () {}),
                  _buildMenuItem(Icons.post_add_outlined, 'My Posts', () {}),
                  _buildMenuItem(Icons.favorite_outline, 'Favorites', () {}),
                  const Divider(),
                  _buildMenuItem(Icons.help_outline, 'Help & Support', () {}),
                  _buildMenuItem(Icons.info_outline, 'About App', () {}),
                  _buildMenuItem(Icons.settings_outlined, 'Settings', () {}),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Logout', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
