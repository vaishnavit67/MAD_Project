import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/mock_data.dart';
import '../../services/auth_service.dart';
import '../../services/faculty_service.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FacultyDashboardStats? _facultyStats;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    if (AuthService.isFaculty) {
      _loadFacultyStats();
    }
  }

  Future<void> _loadFacultyStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);
    final stats = await FacultyService.instance.getDashboardStats();
    if (mounted) {
      setState(() {
        _facultyStats = stats;
        _isLoadingStats = false;
      });
    }
  }

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
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 22),
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

  void _openClaimsModerationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          height: MediaQuery.of(sheetCtx).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Claims & Verification Moderation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('Review proof and approve ownership transfers', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<FacultyPendingRequest>>(
                  future: FacultyService.instance.getPendingRequests(),
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final requests = snapshot.data ?? [];
                    if (requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.task_alt_rounded, size: 40, color: Color(0xFF7C3AED)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'All Clear!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'No pending item claims or verification requests.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        final req = requests[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      req.itemCategory.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.shade200),
                                    ),
                                    child: Text(
                                      req.status.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                req.itemTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Claimant: ${req.claimantName}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      req.itemLocation,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (req.message.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    req.message,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                              if (req.proofImageUrl != null && req.proofImageUrl!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    req.proofImageUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const SizedBox(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final navigator = Navigator.of(sheetCtx);
                                        final success = await FacultyService.instance.updateClaimStatus(req.id, 'rejected');
                                        if (success && mounted) {
                                          messenger.showSnackBar(
                                            const SnackBar(content: Text('Claim rejected')),
                                          );
                                          navigator.pop();
                                          _loadFacultyStats();
                                        }
                                      },
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.redAccent),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final navigator = Navigator.of(sheetCtx);
                                        final success = await FacultyService.instance.updateClaimStatus(req.id, 'approved');
                                        if (success && mounted) {
                                          messenger.showSnackBar(
                                            const SnackBar(content: Text('Claim approved successfully')),
                                          );
                                          navigator.pop();
                                          _loadFacultyStats();
                                        }
                                      },
                                      icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      'Hello, $userName 👋',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.text(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                const SizedBox(height: 2),
                Text(
                  isVisitor ? 'Welcome to Amrita Campus • Visitor Access' : 'Welcome back to Campus Connect',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.subtext(context)),
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
            child: RefreshIndicator(
              onRefresh: () async {
                if (isFaculty) {
                  await _loadFacultyStats();
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FEATURE CARDS GRID (ROLE-AWARE)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.15,
                      children: [
                        FeatureCard(
                          title: 'Navigation',
                          subtitle: 'Campus routes & maps',
                          icon: Icons.navigation_rounded,
                          iconBgColor: AppColors.featureIconBg2,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NavigationScreen())),
                        ),
                        FeatureCard(
                          title: 'Lost & Found',
                          subtitle: isFaculty ? 'Moderation & resolve' : 'Find or report items',
                          icon: Icons.inventory_2,
                          iconBgColor: AppColors.featureIconBg1,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LostFoundScreen())),
                        ),
                        FeatureCard(
                          title: 'Events',
                          subtitle: isFaculty ? 'Manage events' : 'Upcoming activities',
                          icon: Icons.event,
                          iconBgColor: AppColors.featureIconBg4,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
                        ),
                        FeatureCard(
                          title: 'Clubs',
                          subtitle: isVisitor ? 'Members only' : (isFaculty ? 'Faculty oversight' : 'Explore & join'),
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    FeatureCard(
                      title: 'Bus Tracker',
                      subtitle: 'Live campus transit tracking & route schedule',
                      icon: Icons.directions_bus,
                      iconBgColor: AppColors.featureIconBg5,
                      isFullWidth: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusTrackerScreen())),
                    ),

                    // FACULTY MODERATION & OVERSIGHT CARD
                    if (isFaculty) ...[
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      const Flexible(
                                        child: Text(
                                          'Faculty Moderation Center',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isLoadingStats)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_facultyStats?.pendingClaimsCount ?? 0} Pending',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _statPill(
                                    label: 'Pending Claims',
                                    value: '${_facultyStats?.pendingClaimsCount ?? 0}',
                                    icon: Icons.verified_user_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _statPill(
                                    label: 'Active Clubs',
                                    value: '${_facultyStats?.activeClubsCount ?? 0}',
                                    icon: Icons.groups_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _statPill(
                                    label: 'Events',
                                    value: '${_facultyStats?.upcomingEventsCount ?? 0}',
                                    icon: Icons.event_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openClaimsModerationSheet(context),
                                icon: const Icon(Icons.rate_review_rounded, size: 16, color: Color(0xFF7C3AED)),
                                label: const Text(
                                  'Review Pending Claims',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED)),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                          color: AppColors.card(context),
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
                            title: Text(
                              event.title,
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context)),
                            ),
                            subtitle: Text(
                              '${event.timeString} • ${event.location}',
                              style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                            ),
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
          ),
        ],
      ),
    );
  }

  Widget _statPill({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
