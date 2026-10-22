import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/mock_data.dart';
import '../../services/auth_service.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/section_title.dart';
import '../lost_found/lost_found_screen.dart';
import '../navigation/navigation_screen.dart';
import '../clubs/clubs_screen.dart';
import '../events/events_screen.dart';
import '../events/event_detail_page.dart';
import '../bus/bus_tracker_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../features/notifications/services/in_app_notification_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showVisitorRestrictedDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Visitor Access Restricted', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
        content: Text(
          '$feature is reserved for enrolled Students and University Faculty. As a registered Campus Visitor, you have full access to Campus Navigation, Public Events, and Lost & Found assistance.',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = AuthService.currentUser;
    final userName = activeUser?.name.isNotEmpty == true ? activeUser!.name : MockData.currentUser.name;
    final userRole = AuthService.currentRole;
    final isVisitor = AuthService.isVisitor;
    final isFaculty = AuthService.isFaculty;

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Hello, $userName 👋', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isVisitor
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : (isFaculty ? const Color(0xFF8B5CF6).withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userRole,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isVisitor
                              ? const Color(0xFFD97706)
                              : (isFaculty ? const Color(0xFF7C3AED) : AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  isVisitor ? 'Welcome to Amrita Campus • Visitor Access' : 'Welcome back to Campus Connect',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              Builder(
                builder: (ctx) {
                  final unread = InAppNotificationService().unreadCount;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FEATURE CARDS GRID (ROLE-AWARE)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                    children: [
                      FeatureCard(
                        title: 'Navigation',
                        subtitle: 'Find locations',
                        icon: Icons.navigation_rounded,
                        iconBgColor: AppColors.featureIconBg2,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NavigationScreen())),
                      ),
                      FeatureCard(
                        title: 'Lost & Found',
                        subtitle: isFaculty ? 'Resolve items' : 'Find items',
                        icon: Icons.inventory_2,
                        iconBgColor: AppColors.featureIconBg1,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LostFoundScreen())),
                      ),
                      FeatureCard(
                        title: 'Events',
                        subtitle: isFaculty ? 'Manage events' : 'Upcoming',
                        icon: Icons.event,
                        iconBgColor: AppColors.featureIconBg4,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
                      ),
                      FeatureCard(
                        title: 'Clubs',
                        subtitle: isVisitor ? 'Restricted' : (isFaculty ? 'Club Oversight' : 'Join clubs'),
                        icon: isVisitor ? Icons.lock_outline_rounded : Icons.groups,
                        iconBgColor: isVisitor ? const Color(0xFFE2E8F0) : AppColors.featureIconBg3,
                        onTap: () {
                          if (isVisitor) {
                            _showVisitorRestrictedDialog(context, 'Campus Clubs');
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubsScreen()));
                          }
                        },
                      ),
                      FeatureCard(
                        title: 'Bus Tracker',
                        subtitle: 'Track buses',
                        icon: Icons.directions_bus,
                        iconBgColor: AppColors.featureIconBg5,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusTrackerScreen())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  SectionTitle(
                    title: isVisitor ? 'Campus Public Events' : 'Upcoming Events',
                    actionText: 'View All',
                    onActionPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
                    },
                  ),
                  const SizedBox(height: 16),
                  ...MockData.events.take(2).map((event) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.event_note_rounded, color: AppColors.primary),
                          ),
                          title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${event.timeString} • ${event.location}', style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: event)));
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
