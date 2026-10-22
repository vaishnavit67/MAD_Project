import 'package:flutter/material.dart';
import '../../core/theme/lf_colors.dart';
import '../../services/auth_service.dart';

/* =========================================================
                          CLUBS
========================================================= */
class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';

  final List<Map<String, dynamic>> clubs = [
    {
      'name': 'DevTech Coding Club',
      'category': 'Technical',
      'memberCount': 142,
      'members': <String>[],
      'icon': Icons.code_rounded,
      'color': const Color(0xFFEEF2FF),
      'iconColor': const Color(0xFF6366F1),
      'description': 'Building real-world web, mobile apps & AI solutions. Join hackathons and tech talks!',
    },
    {
      'name': 'Creative UI/UX Design',
      'category': 'Creative',
      'memberCount': 98,
      'members': <String>[],
      'icon': Icons.palette_rounded,
      'color': const Color(0xFFFDF2F8),
      'iconColor': const Color(0xFFEC4899),
      'description': 'Master Figma, graphic design, animation, and digital brand storytelling.',
    },
    {
      'name': 'Acoustics Music Society',
      'category': 'Cultural',
      'memberCount': 115,
      'members': <String>[],
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFFFFF7ED),
      'iconColor': const Color(0xFFF97316),
      'description': 'Jamming sessions, vocal coaching, band performances & annual music fests.',
    },
    {
      'name': 'Campus Varsity Sports',
      'category': 'Sports',
      'memberCount': 180,
      'members': <String>[],
      'icon': Icons.sports_soccer_rounded,
      'color': const Color(0xFFECFDF5),
      'iconColor': const Color(0xFF10B981),
      'description': 'Cricket, Football, Basketball and Badminton tournaments and regular practice sessions.',
    },
  ];

  List<Map<String, dynamic>> get visibleClubs {
    return clubs.where((club) {
      final matchesCategory = selectedCategory == 'All' || club['category'] == selectedCategory;
      final matchesSearch = searchQuery.trim().isEmpty ||
          club['name'].toString().toLowerCase().contains(searchQuery.trim().toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleClubs;

    return Scaffold(
      backgroundColor: LFColors.background,
      appBar: AppBar(
        title: const Text('Campus Clubs', style: TextStyle(color: LFColors.textPrimary)),
        backgroundColor: LFColors.cardBg,
        iconTheme: const IconThemeData(color: LFColors.textPrimary),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SEARCH INPUT
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search club name or keyword...',
                  hintStyle: const TextStyle(color: LFColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: LFColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CATEGORIES HORIZONTAL SCROLL
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryPill('All'),
                  _categoryPill('Technical'),
                  _categoryPill('Creative'),
                  _categoryPill('Cultural'),
                  _categoryPill('Sports'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended Clubs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: LFColors.textPrimary,
                  ),
                ),
                Text(
                  '${visible.length} available',
                  style: const TextStyle(
                    color: LFColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (visible.isEmpty)
              _emptyClubsView()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final club = visible[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _clubCard(club),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryPill(String title) {
    final isSelected = selectedCategory == title;

    return GestureDetector(
      onTap: () => setState(() => selectedCategory = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? LFColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LFColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                  )
                ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : LFColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _clubCard(Map<String, dynamic> club) {
    final List<String> members = List<String>.from(club['members'] as List<dynamic>);
    final bool isJoined = members.contains('You');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClubDetailsPage(club: club),
              ),
            );
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // CLUB LOGO ICON
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: club['color'] ?? LFColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    club['icon'],
                    size: 30,
                    color: club['iconColor'] ?? LFColors.primary,
                  ),
                ),
                const SizedBox(width: 14),

                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: LFColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${club['category']} • ${club['memberCount']} Active Members',
                        style: const TextStyle(
                          fontSize: 12,
                          color: LFColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isJoined) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: LFColors.foundBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✓ Member',
                            style: TextStyle(
                              fontSize: 10,
                              color: LFColors.foundText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: LFColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyClubsView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_3_outlined, size: 44, color: LFColors.textMuted),
          SizedBox(height: 10),
          Text(
            'No matching clubs found',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Try adjusting your search query or category filter.',
            style: TextStyle(fontSize: 12, color: LFColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
                       CLUB DETAILS
========================================================= */
class ClubDetailsPage extends StatefulWidget {
  final Map<String, dynamic> club;

  const ClubDetailsPage({super.key, required this.club});

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubDetailsPageState extends State<ClubDetailsPage> {
  String selectedSport = 'Cricket';

  final List<Map<String, dynamic>> sports = [
    {'name': 'Cricket', 'icon': Icons.sports_cricket_rounded},
    {'name': 'Football', 'icon': Icons.sports_soccer_rounded},
    {'name': 'Basketball', 'icon': Icons.sports_basketball_rounded},
    {'name': 'Badminton', 'icon': Icons.sports_tennis_rounded},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball_rounded},
  ];

  bool get isJoined {
    final members = List<String>.from(widget.club['members'] as List<dynamic>);
    return members.contains('You');
  }

  void joinClub() {
    if (AuthService.isVisitor) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Visitor Restriction', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            'Campus club membership is reserved for enrolled students and faculty. As a registered visitor, you are welcome to attend open campus events and explore campus navigation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    final members = List<String>.from(widget.club['members'] as List<dynamic>);

    if (members.contains('You')) return;

    setState(() {
      members.add('You');
      widget.club['members'] = members;
      widget.club['memberCount'] = widget.club['memberCount'] + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text('Welcome to ${widget.club['name']}! 🎉'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDigitalPassModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LFColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 50, color: LFColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Campus Event Pass',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Pass ID: EVT-9042 • ${widget.club['name']}',
                style: const TextStyle(fontSize: 12, color: LFColors.textMuted),
              ),
              const SizedBox(height: 16),
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_rounded, size: 110, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Show this QR code at Innovation Hub entry.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: LFColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LFColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('CLOSE PASS', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSports = widget.club['category'] == 'Sports';

    return Scaffold(
      backgroundColor: LFColors.background,
      appBar: AppBar(
        title: const Text(
          'Club Profile',
          style: TextStyle(fontWeight: FontWeight.w800, color: LFColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: LFColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // COVER HERO
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.club['color'] ?? LFColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Icon(
                  widget.club['icon'],
                  size: 72,
                  color: widget.club['iconColor'] ?? LFColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              widget.club['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: LFColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.club['category']} Student Association',
              style: const TextStyle(
                color: LFColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // STATS ROW
            Row(
              children: [
                _statCard(
                  Icons.groups_rounded,
                  '${widget.club['memberCount']}',
                  'Active Members',
                ),
                const SizedBox(width: 10),
                _statCard(
                  Icons.star_rounded,
                  '4.9 ⭐',
                  'Rating',
                ),
                const SizedBox(width: 10),
                _statCard(
                  Icons.event_available_rounded,
                  '12+',
                  'Events / Yr',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ABOUT SECTION
            _cardSection(
              'About the Club',
              widget.club['description'],
              Icons.info_outline_rounded,
            ),

            // SPORTS INTERACTIVE SECTION
            if (isSports) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Sport Discipline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: LFColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 85,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sports.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final sport = sports[index];
                    final selected = selectedSport == sport['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSport = sport['name'];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 90,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selected ? LFColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: LFColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                  )
                                ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              sport['icon'],
                              size: 26,
                              color: selected ? Colors.white : LFColors.primary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sport['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : LFColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _cardSection(
                'Upcoming Schedule ($selectedSport)',
                'Practice Session & Selection Trials\n📅 Friday • 4:00 PM - 6:00 PM\n📍 Campus Athletic Complex',
                Icons.calendar_today_rounded,
                actionWidget: TextButton.icon(
                  onPressed: () => _showDigitalPassModal(context),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Get Event Pass'),
                ),
              ),
            ] else
              _cardSection(
                'Next Community Event',
                'Annual Interactive Workshop & Meetup\n📅 Friday • 4:00 PM\n📍 Innovation Hub Auditorium',
                Icons.event_rounded,
                actionWidget: TextButton.icon(
                  onPressed: () => _showDigitalPassModal(context),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Get Digital Pass'),
                ),
              ),

            const SizedBox(height: 16),

            // JOIN STATUS BANNER
            if (isJoined)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: LFColors.foundBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LFColors.foundBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: LFColors.foundText),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You are an active member of this club.',
                        style: TextStyle(
                          color: LFColors.foundText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // JOIN BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isJoined ? null : joinClub,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LFColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: LFColors.textMuted,
                  elevation: isJoined ? 0 : 4,
                  shadowColor: LFColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isJoined ? 'ALREADY JOINED ✓' : 'JOIN CLUB COMMUNITY',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: LFColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: LFColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: LFColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardSection(String title, String text, IconData icon, {Widget? actionWidget}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: LFColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: LFColors.textPrimary,
                    ),
                  ),
                ],
              ),
              ?actionWidget,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: LFColors.textSecondary,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
