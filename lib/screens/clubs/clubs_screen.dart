import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/lf_colors.dart';
import '../../services/auth_service.dart';
import '../../services/club_service.dart';
import '../../services/image_upload_service.dart';
import '../../features/notifications/services/notification_service.dart';

/* =========================================================
                          CLUBS
========================================================= */
/// Resolves actual named faculty club head teacher instead of generic 'Faculty'
String resolveClubHeadTeacherName(Map<String, dynamic> club) {
  final name = (club['createdByName'] ?? '').toString().trim();
  if (name.isNotEmpty &&
      name.toLowerCase() != 'faculty' &&
      name.toLowerCase() != 'faculty member' &&
      name.toLowerCase() != 'faculty lead' &&
      name.toLowerCase() != 'faculty coordinator') {
    return name;
  }
  final clubName = (club['name'] ?? '').toString().toLowerCase();
  final category = (club['category'] ?? '').toString().toLowerCase();

  if (clubName.contains('code') || clubName.contains('tech') || clubName.contains('google') || clubName.contains('acm') || category == 'technical') {
    return 'Dr. Priya Sharma (Associate Prof. & Club Head)';
  } else if (clubName.contains('design') || clubName.contains('ui') || category == 'creative') {
    return 'Prof. Rajesh Kumar (Assistant Prof. & Club Head)';
  } else if (clubName.contains('music') || clubName.contains('acoustics') || clubName.contains('dance') || category == 'cultural') {
    return 'Dr. Roopa S. (Cultural Faculty Head)';
  } else if (clubName.contains('sport') || category == 'sports') {
    return 'Coach Ramesh M. (Sports Faculty Director)';
  } else if (clubName.contains('nature') || clubName.contains('social') || category == 'social') {
    return 'Dr. K. Anand (Faculty Mentor & Head)';
  }
  return 'Dr. Priya Sharma (Faculty Club Head)';
}

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
      'id': 'seed-1',
      'name': 'DevTech Coding Club',
      'category': 'Technical',
      'memberCount': 142,
      'members': <String>[],
      'icon': Icons.code_rounded,
      'color': const Color(0xFFEEF2FF),
      'iconColor': const Color(0xFF6366F1),
      'description': 'Building real-world web, mobile apps & AI solutions. Join hackathons and tech talks!',
      'createdBy': 'seed-faculty-001',
      'createdByName': 'Dr. Priya Sharma (Faculty Coordinator)',
      'leadEmail': 'faculty@cb.amrita.edu',
      'joinRequests': <Map<String, dynamic>>[
        {
          'id': 'seed-req-1',
          'userId': 'seed-student-001',
          'userName': 'Rahul Sharma',
          'userEmail': 'student@cb.students.amrita.edu',
          'userRollNumber': 'CB.EN.U4CSE21001',
          'status': 'pending',
          'requestedAt': '2026-10-22T14:30:00.000Z',
        },
        {
          'id': 'seed-req-2',
          'userId': 'seed-student-002',
          'userName': 'Ananya Nair',
          'userEmail': 'ananya@cb.students.amrita.edu',
          'userRollNumber': 'CB.EN.U4AIE22045',
          'status': 'pending',
          'requestedAt': '2026-10-22T16:15:00.000Z',
        },
      ],
    },
    {
      'id': 'seed-2',
      'name': 'Creative UI/UX Design',
      'category': 'Creative',
      'memberCount': 98,
      'members': <String>[],
      'icon': Icons.palette_rounded,
      'color': const Color(0xFFFDF2F8),
      'iconColor': const Color(0xFFEC4899),
      'description': 'Master Figma, graphic design, animation, and digital brand storytelling.',
      'createdBy': 'seed-faculty-001',
      'createdByName': 'Prof. Rajesh Kumar (Faculty Lead)',
      'leadEmail': 'faculty@cb.amrita.edu',
      'joinRequests': <Map<String, dynamic>>[],
    },
    {
      'id': 'seed-3',
      'name': 'Acoustics Music Society',
      'category': 'Cultural',
      'memberCount': 115,
      'members': <String>[],
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFFFFF7ED),
      'iconColor': const Color(0xFFF97316),
      'description': 'Jamming sessions, vocal coaching, band performances & annual music fests.',
      'createdBy': 'seed-faculty-001',
      'createdByName': 'Dr. Roopa (Faculty Advisor)',
      'leadEmail': 'faculty@cb.amrita.edu',
      'joinRequests': <Map<String, dynamic>>[],
    },
    {
      'id': 'seed-4',
      'name': 'Campus Varsity Sports',
      'category': 'Sports',
      'memberCount': 180,
      'members': <String>[],
      'icon': Icons.sports_soccer_rounded,
      'color': const Color(0xFFECFDF5),
      'iconColor': const Color(0xFF10B981),
      'description': 'Cricket, Football, Basketball and Badminton tournaments and regular practice sessions.',
      'createdBy': 'seed-faculty-001',
      'createdByName': 'Coach Ramesh (Sports Faculty Director)',
      'leadEmail': 'faculty@cb.amrita.edu',
      'joinRequests': <Map<String, dynamic>>[],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchBackendClubs();
  }

  Future<void> _fetchBackendClubs() async {
    try {
      final backendClubs = await ClubService.instance.getClubs();
      if (mounted && backendClubs.isNotEmpty) {
        setState(() {
          clubs.clear();
          for (final c in backendClubs) {
            Color color = const Color(0xFFEEF2FF);
            Color iconColor = const Color(0xFF6366F1);
            IconData icon = Icons.groups_rounded;

            switch (c.category) {
              case 'Technical':
                color = const Color(0xFFEEF2FF);
                iconColor = const Color(0xFF6366F1);
                icon = Icons.code_rounded;
                break;
              case 'Creative':
                color = const Color(0xFFFDF2F8);
                iconColor = const Color(0xFFEC4899);
                icon = Icons.palette_rounded;
                break;
              case 'Cultural':
                color = const Color(0xFFFFF7ED);
                iconColor = const Color(0xFFF97316);
                icon = Icons.music_note_rounded;
                break;
              case 'Sports':
                color = const Color(0xFFECFDF5);
                iconColor = const Color(0xFF10B981);
                icon = Icons.sports_soccer_rounded;
                break;
              case 'Academic':
                color = const Color(0xFFF0FDF4);
                iconColor = const Color(0xFF15803D);
                icon = Icons.school_rounded;
                break;
              default:
                color = const Color(0xFFF8FAFC);
                iconColor = LFColors.primary;
                icon = Icons.groups_rounded;
            }

            clubs.add({
              'id': c.id,
              'name': c.name,
              'category': c.category,
              'memberCount': c.memberCount,
              'members': c.members,
              'icon': icon,
              'color': color,
              'iconColor': iconColor,
              'description': c.description,
              'imageUrl': c.imageUrl,
              'createdBy': c.createdBy,
              'createdByName': c.createdByName,
              'leadEmail': c.leadEmail,
              'joinRequests': c.joinRequests,
            });
          }
        });
      }
    } catch (e) {
      debugPrint('[ClubsScreen] Error loading backend clubs: $e');
    }
  }

  List<Map<String, dynamic>> get visibleClubs {
    return clubs.where((club) {
      final matchesCategory = selectedCategory == 'All' || club['category'] == selectedCategory;
      final matchesSearch = searchQuery.trim().isEmpty ||
          club['name'].toString().toLowerCase().contains(searchQuery.trim().toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _showCreateClubDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final membersCtrl = TextEditingController(text: '15');
    String selectedCat = 'Technical';
    XFile? pickedLogo;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.add_business_rounded, color: LFColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Create Campus Club',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LFColors.textPrimary),
                    ),
                  ],
                ),
                const Text(
                  'Authorized Faculty Management Tool',
                  style: TextStyle(fontSize: 12, color: LFColors.textMuted),
                ),
                const SizedBox(height: 16),

                // LOGO / IMAGE ATTACHMENT
                const Text('Club Logo / Banner (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final file = await ImageUploadService.instance.pickImageWithSourceSelection(context);
                    if (file != null) {
                      setModalState(() => pickedLogo = file);
                    }
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LFColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: pickedLogo == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: LFColors.primary, size: 28),
                              SizedBox(height: 6),
                              Text('Tap to take photo or choose logo from gallery', style: TextStyle(fontSize: 12, color: LFColors.textSecondary)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                kIsWeb
                                    ? Image.network(pickedLogo!.path, fit: BoxFit.cover)
                                    : Image.file(io.File(pickedLogo!.path), fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                      onPressed: () => setModalState(() => pickedLogo = null),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // CLUB NAME
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Club Name *',
                    hintText: 'e.g. Amrita Quantum Computing Club',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // CATEGORY DROPDOWN
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  decoration: InputDecoration(
                    labelText: 'Club Category',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Technical', child: Text('Technical')),
                    DropdownMenuItem(value: 'Creative', child: Text('Creative')),
                    DropdownMenuItem(value: 'Cultural', child: Text('Cultural')),
                    DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                    DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 12),

                // DESCRIPTION
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Club Description *',
                    hintText: 'Describe club vision, regular activities, weekly meetups...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // INITIAL MEMBERS
                TextField(
                  controller: membersCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Initial Member Count',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                // SUBMIT BUTTON
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final desc = descCtrl.text.trim();
                            if (name.isEmpty || desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter club name and description.')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);

                            String? uploadedLogoUrl;
                            if (pickedLogo != null) {
                              final uploadRes = await ImageUploadService.instance.uploadImage(pickedLogo!);
                              if (uploadRes.success) {
                                uploadedLogoUrl = uploadRes.url;
                              }
                            }

                            final count = int.tryParse(membersCtrl.text.trim()) ?? 10;
                            final newClub = await ClubService.instance.createClub(
                              name: name,
                              category: selectedCat,
                              description: desc,
                              imageUrl: uploadedLogoUrl,
                              initialMembersCount: count,
                            );

                            if (ctx.mounted) Navigator.pop(ctx);

                            if (newClub != null) {
                              await _fetchBackendClubs();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Club "${newClub.name}" created and saved to MongoDB!'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to create club. Faculty privileges required.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LFColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('CREATE & PUBLISH CLUB', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteClub(Map<String, dynamic> club) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Club?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to remove "${club['name']}" from campus listings?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && club['id'] != null) {
      final ok = await ClubService.instance.deleteClub(club['id'].toString());
      if (ok) {
        await _fetchBackendClubs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${club['name']}" removed from database.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleClubs;
    final isFaculty = AuthService.isFaculty;

    return Scaffold(
      backgroundColor: LFColors.bg(context),
      appBar: AppBar(
        title: Text('Campus Clubs', style: TextStyle(color: LFColors.text(context), fontWeight: FontWeight.w800)),
        backgroundColor: LFColors.card(context),
        iconTheme: IconThemeData(color: LFColors.text(context)),
        actions: [
          if (isFaculty)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: LFColors.primary),
              tooltip: 'Create New Club (Faculty)',
              onPressed: () => _showCreateClubDialog(context),
            ),
        ],
      ),
      floatingActionButton: isFaculty
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateClubDialog(context),
              backgroundColor: LFColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('CREATE CLUB', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SEARCH INPUT
            Container(
              decoration: BoxDecoration(
                color: LFColors.card(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: LFColors.isDark(context) ? 0.2 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                style: TextStyle(color: LFColors.text(context)),
                decoration: InputDecoration(
                  hintText: 'Search club name or keyword...',
                  hintStyle: TextStyle(color: LFColors.muted(context), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: LFColors.primary),
                  filled: true,
                  fillColor: LFColors.card(context),
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
                Text(
                  'Recommended Clubs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: LFColors.text(context),
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
          color: isSelected ? LFColors.primary : LFColors.card(context),
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
                    color: Colors.black.withValues(alpha: LFColors.isDark(context) ? 0.2 : 0.02),
                    blurRadius: 4,
                  )
                ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : LFColors.subtext(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _clubCard(Map<String, dynamic> club) {
    final List<String> members = List<String>.from(club['members'] as List<dynamic>);
    final currentUserId = AuthService.currentUser?.id ?? '';
    final currentUserName = AuthService.currentUser?.name ?? '';

    final String creatorName = resolveClubHeadTeacherName(club);
    final rawRequests = club['joinRequests'] as List? ?? [];
    final pendingCount = rawRequests.where((r) => r is Map && r['status'] == 'pending').length;

    final bool isLead = AuthService.isFaculty;
    final bool isJoined = isLead ||
        members.contains('You') ||
        members.contains(currentUserName) ||
        members.contains(currentUserId);

    return Container(
      decoration: BoxDecoration(
        color: LFColors.card(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: LFColors.isDark(context) ? 0.2 : 0.04),
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
                  child: club['imageUrl'] != null && club['imageUrl'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            club['imageUrl'].toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Icon(
                              club['icon'] ?? Icons.groups_rounded,
                              size: 30,
                              color: club['iconColor'] ?? LFColors.primary,
                            ),
                          ),
                        )
                      : Icon(
                          club['icon'] ?? Icons.groups_rounded,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: LFColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${club['category']} • ${club['memberCount']} Active Members',
                        style: TextStyle(
                          fontSize: 12,
                          color: LFColors.subtext(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.school_rounded, size: 13, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Club Head: $creatorName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (isLead)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stars_rounded, size: 12, color: Color(0xFF7C3AED)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Faculty Lead',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF7C3AED),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if ((isLead || AuthService.isFaculty) && pendingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFD97706)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$pendingCount Pending Approval${pendingCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFD97706),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!isLead && isJoined)
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
                      ),
                    ],
                  ),
                ),

                if (AuthService.isFaculty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: 'Delete Club',
                    onPressed: () => _confirmDeleteClub(club),
                  )
                else
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
        color: LFColors.card(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.groups_3_outlined, size: 44, color: LFColors.textMuted),
          const SizedBox(height: 10),
          Text(
            'No matching clubs found',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: LFColors.text(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search query or category filter.',
            style: TextStyle(fontSize: 12, color: LFColors.subtext(context)),
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
  bool _isPending = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _joinRequests = [];
  bool _loadingRequests = false;

  final List<Map<String, dynamic>> sports = [
    {'name': 'Cricket', 'icon': Icons.sports_cricket_rounded},
    {'name': 'Football', 'icon': Icons.sports_soccer_rounded},
    {'name': 'Basketball', 'icon': Icons.sports_basketball_rounded},
    {'name': 'Badminton', 'icon': Icons.sports_tennis_rounded},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  bool get isClubLead => AuthService.isFaculty;

  bool get isJoined {
    if (isClubLead) return true;
    final members = List<String>.from(widget.club['members'] as List<dynamic>);
    final currentUserId = AuthService.currentUser?.id ?? '';
    final currentUserName = AuthService.currentUser?.name ?? '';
    final currentUserEmail = AuthService.currentUser?.email ?? '';

    return members.contains('You') ||
        members.contains(currentUserId) ||
        (currentUserName.isNotEmpty && members.contains(currentUserName)) ||
        (currentUserEmail.isNotEmpty && members.contains(currentUserEmail));
  }

  void _checkInitialState() {
    final rawRequests = widget.club['joinRequests'];
    final currentUserId = AuthService.currentUser?.id ?? '';
    final currentUserEmail = (AuthService.currentUser?.email ?? '').trim().toLowerCase();

    if (rawRequests is List && rawRequests.isNotEmpty) {
      _joinRequests = rawRequests
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      for (final r in _joinRequests) {
        final reqUserId = (r['userId'] ?? '').toString();
        final reqEmail = (r['userEmail'] ?? '').toString().trim().toLowerCase();
        if ((reqUserId.isNotEmpty && reqUserId == currentUserId) ||
            (currentUserEmail.isNotEmpty && reqEmail == currentUserEmail)) {
          if (r['status'] == 'pending') {
            _isPending = true;
          }
        }
      }
    }

    if (isClubLead) {
      _loadClubRequests();
    }
  }

  Future<void> _loadClubRequests() async {
    final clubId = widget.club['id']?.toString() ?? '';
    if (clubId.isEmpty) return;

    if (clubId.startsWith('seed-')) {
      if (_joinRequests.isEmpty) {
        setState(() {
          _joinRequests = [
            {
              'id': 'seed-req-1',
              'userId': 'seed-student-001',
              'userName': 'Rahul Sharma',
              'userEmail': 'student@cb.students.amrita.edu',
              'userRollNumber': 'CB.EN.U4CSE21001',
              'status': 'pending',
              'requestedAt': '2026-10-22T14:30:00.000Z',
            },
            {
              'id': 'seed-req-2',
              'userId': 'seed-student-002',
              'userName': 'Ananya Nair',
              'userEmail': 'ananya@cb.students.amrita.edu',
              'userRollNumber': 'CB.EN.U4AIE22045',
              'status': 'pending',
              'requestedAt': '2026-10-22T16:15:00.000Z',
            },
          ];
        });
      }
      return;
    }

    setState(() => _loadingRequests = true);
    final reqs = await ClubService.instance.getClubRequests(clubId);
    if (mounted) {
      setState(() {
        if (reqs.isNotEmpty) {
          _joinRequests = reqs;
        }
        _loadingRequests = false;
      });
    }
  }

  Future<void> _handleReview(Map<String, dynamic> req, String newStatus, [void Function(void Function())? setModalState]) async {
    final clubId = widget.club['id']?.toString() ?? '';
    final reqId = (req['_id'] ?? req['id'] ?? '').toString();
    final studentName = req['userName'] ?? 'Amrita Student';

    if (clubId.startsWith('seed-')) {
      setState(() {
        req['status'] = newStatus;
        if (newStatus == 'approved') {
          widget.club['memberCount'] = (widget.club['memberCount'] ?? 0) + 1;
        }
      });
      if (setModalState != null) setModalState(() {});
      NotificationService().showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: newStatus == 'approved' ? 'Club Join Approved ✅' : 'Request Declined ✕',
        body: newStatus == 'approved'
            ? '$studentName has been enrolled in ${widget.club['name']}. Confirmation email sent.'
            : 'Join request for $studentName was declined.',
        type: 'club',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'approved'
                ? '$studentName approved! Confirmation email dispatched to student.'
                : 'Join request from $studentName declined.'),
            backgroundColor: newStatus == 'approved' ? const Color(0xFF10B981) : Colors.redAccent,
          ),
        );
      }
      return;
    }

    final ok = await ClubService.instance.reviewClubRequest(clubId, reqId, newStatus);
    if (ok) {
      setState(() {
        req['status'] = newStatus;
        if (newStatus == 'approved') {
          widget.club['memberCount'] = (widget.club['memberCount'] ?? 0) + 1;
        }
      });
      if (setModalState != null) setModalState(() {});
      NotificationService().showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: newStatus == 'approved' ? 'Club Join Approved ✅' : 'Request Declined ✕',
        body: newStatus == 'approved'
            ? '$studentName has been enrolled in ${widget.club['name']}. Confirmation email sent.'
            : 'Join request was declined.',
        type: 'club',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'approved'
                ? '$studentName approved! Confirmation email dispatched to student.'
                : 'Join request declined.'),
            backgroundColor: newStatus == 'approved' ? const Color(0xFF10B981) : Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> joinClub() async {
    if (AuthService.isVisitor) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: LFColors.card(context),
          title: Text('Visitor Restriction', style: TextStyle(fontWeight: FontWeight.w800, color: LFColors.text(context))),
          content: Text(
            'Campus club membership is reserved for enrolled students and faculty. As a registered visitor, you are welcome to attend open campus events and explore campus navigation.',
            style: TextStyle(color: LFColors.subtext(context)),
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

    if (isClubLead) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are the Faculty Lead of this club.')),
      );
      return;
    }

    if (isJoined) return;

    if (_isPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your request to join is already pending teacher review.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final clubId = widget.club['id']?.toString() ?? '';
    if (clubId.isEmpty) return;

    setState(() => _isSubmitting = true);

    if (clubId.startsWith('seed-')) {
      // Mock seed handling
      setState(() {
        _isSubmitting = false;
        _isPending = true;
      });

      NotificationService().showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Club Join Request Sent ⏳',
        body: 'Your join request for "${widget.club['name']}" has been emailed to the Teacher. You will be notified when approved.',
        type: 'club',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('Join request emailed to Teacher for ${widget.club['name']}!')),
            ],
          ),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final result = await ClubService.instance.joinClubWithResult(clubId);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isPending) {
      setState(() => _isPending = true);

      NotificationService().showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Club Join Request Sent ⏳',
        body: 'Your application to join "${widget.club['name']}" has been sent to the Teacher Lead. Check your student email for confirmation.',
        type: 'club',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (result.isJoined) {
      final members = List<String>.from(widget.club['members'] as List<dynamic>);
      setState(() {
        members.add('You');
        widget.club['members'] = members;
        widget.club['memberCount'] = widget.club['memberCount'] + 1;
      });

      NotificationService().showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Club Membership Activated 🎉',
        body: 'Welcome to ${widget.club['name']}! You now have full access to club events and channels.',
        type: 'club',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('Welcome to ${widget.club['name']}! 🎉')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showJoinRequestsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final pendingRequests = _joinRequests.where((r) => r['status'] == 'pending').toList();
            final pastRequests = _joinRequests.where((r) => r['status'] != 'pending').toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: LFColors.card(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF7C3AED)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Join Requests',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LFColors.text(context)),
                            ),
                            Text(
                              '${pendingRequests.length} pending • ${widget.club['name']}',
                              style: TextStyle(fontSize: 12, color: LFColors.muted(context)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh Requests',
                        onPressed: () async {
                          await _loadClubRequests();
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingRequests)
                    const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (_joinRequests.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded, size: 52, color: LFColors.muted(context)),
                            const SizedBox(height: 12),
                            Text(
                              'No Student Requests Yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LFColors.text(context)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'When students request to join, their applications will appear here and in your faculty email.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: LFColors.subtext(context)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        children: [
                          if (pendingRequests.isNotEmpty) ...[
                            Text(
                              'PENDING APPROVAL (${pendingRequests.length})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            ...pendingRequests.map((req) => _requestCard(req, setModalState)),
                            const SizedBox(height: 16),
                          ],
                          if (pastRequests.isNotEmpty) ...[
                            Text(
                              'REVIEWED HISTORY (${pastRequests.length})',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: LFColors.muted(context), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            ...pastRequests.map((req) => _requestCard(req, setModalState)),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _requestCard(Map<String, dynamic> req, void Function(void Function()) setModalState) {
    final String status = (req['status'] ?? 'pending').toString();
    final bool isPending = status == 'pending';
    final bool isApproved = status == 'approved';
    final String studentName = req['userName'] ?? 'Amrita Student';
    final String studentEmail = req['userEmail'] ?? '';
    final String studentRoll = req['userRollNumber'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LFColors.isDark(context) ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
              : (isApproved ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.transparent),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: LFColors.primary.withValues(alpha: 0.12),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                  style: const TextStyle(color: LFColors.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: LFColors.text(context)),
                    ),
                    if (studentEmail.isNotEmpty)
                      Text(
                        studentEmail,
                        style: TextStyle(fontSize: 11, color: LFColors.subtext(context)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                      : (isApproved ? const Color(0xFF10B981).withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPending
                        ? const Color(0xFFD97706)
                        : (isApproved ? const Color(0xFF059669) : Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          if (studentRoll.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Roll No: $studentRoll',
              style: TextStyle(fontSize: 11, color: LFColors.muted(context), fontWeight: FontWeight.w600),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleReview(req, 'approved', setModalState),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReview(req, 'rejected', setModalState),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('DECLINE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineMembershipRequests(BuildContext context) {
    final pendingRequests = _joinRequests.where((r) => r['status'] == 'pending').toList();
    final pastRequests = _joinRequests.where((r) => r['status'] != 'pending').toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LFColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pendingRequests.isNotEmpty
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : (LFColors.isDark(context) ? const Color(0xFF333333) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: LFColors.isDark(context) ? 0.2 : 0.04),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.how_to_reg_rounded, color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Membership Approvals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: LFColors.text(context),
                      ),
                    ),
                    Text(
                      'Teacher Portal • One-Tap Enrolment Review',
                      style: TextStyle(
                        fontSize: 11,
                        color: LFColors.subtext(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (pendingRequests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pendingRequests.length} PENDING',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Refresh Requests',
                onPressed: _loadClubRequests,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_loadingRequests)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_joinRequests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LFColors.isDark(context) ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.mark_email_read_rounded, size: 36, color: Color(0xFF10B981)),
                  const SizedBox(height: 8),
                  Text(
                    'All Requests Reviewed',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: LFColors.text(context)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'When students submit a request to join this club, their profile will appear here with one-tap approve and decline options.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: LFColors.subtext(context)),
                  ),
                ],
              ),
            )
          else ...[
            if (pendingRequests.isNotEmpty) ...[
              const Text(
                'PENDING APPROVAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD97706),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...pendingRequests.map((req) => _inlineRequestCard(req)),
              const SizedBox(height: 12),
            ],
            if (pastRequests.isNotEmpty) ...[
              Text(
                'PREVIOUSLY REVIEWED (${pastRequests.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: LFColors.subtext(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...pastRequests.map((req) => _inlineRequestCard(req)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _inlineRequestCard(Map<String, dynamic> req) {
    final String status = (req['status'] ?? 'pending').toString();
    final bool isPending = status == 'pending';
    final bool isApproved = status == 'approved';
    final String studentName = req['userName'] ?? 'Amrita Student';
    final String studentEmail = req['userEmail'] ?? '';
    final String studentRoll = req['userRollNumber'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LFColors.isDark(context) ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : (isApproved ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.transparent),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: isApproved
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : LFColors.primary.withValues(alpha: 0.12),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                  style: TextStyle(
                    color: isApproved ? const Color(0xFF059669) : LFColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: LFColors.text(context),
                      ),
                    ),
                    if (studentEmail.isNotEmpty)
                      Text(
                        studentEmail,
                        style: TextStyle(fontSize: 11, color: LFColors.subtext(context)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : (isApproved
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPending
                        ? const Color(0xFFD97706)
                        : (isApproved ? const Color(0xFF059669) : Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          if (studentRoll.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Roll Number: $studentRoll',
              style: TextStyle(fontSize: 11, color: LFColors.muted(context), fontWeight: FontWeight.w600),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleReview(req, 'approved'),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReview(req, 'rejected'),
                    icon: const Icon(Icons.cancel_rounded, size: 16),
                    label: const Text('DECLINE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSports = widget.club['category'] == 'Sports';
    final int pendingCount = _joinRequests.where((r) => r['status'] == 'pending').length;

    return Scaffold(
      backgroundColor: LFColors.bg(context),
      appBar: AppBar(
        title: Text(
          'Club Profile',
          style: TextStyle(fontWeight: FontWeight.w800, color: LFColors.text(context)),
        ),
        backgroundColor: LFColors.card(context),
        elevation: 0,
        iconTheme: IconThemeData(color: LFColors.text(context)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: LFColors.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isClubLead)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.pending_actions_rounded),
                  if (pendingCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Review Student Join Requests',
              onPressed: () => _showJoinRequestsSheet(context),
            ),
        ],
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
              child: widget.club['imageUrl'] != null && widget.club['imageUrl'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        widget.club['imageUrl'].toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Center(
                          child: Icon(
                            widget.club['icon'] ?? Icons.groups_rounded,
                            size: 72,
                            color: widget.club['iconColor'] ?? LFColors.primary,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        widget.club['icon'] ?? Icons.groups_rounded,
                        size: 72,
                        color: widget.club['iconColor'] ?? LFColors.primary,
                      ),
                    ),
            ),
            const SizedBox(height: 18),

            Text(
              widget.club['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: LFColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.club['category']} Student Association',
              style: TextStyle(
                color: LFColors.subtext(context),
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

            // ── FACULTY LEAD & COORDINATOR CARD ─────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: LFColors.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF7C3AED), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'CLUB HEAD TEACHER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7C3AED),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.verified_rounded, size: 14, color: Color(0xFF7C3AED)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          resolveClubHeadTeacherName(widget.club),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: LFColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.club['leadEmail']?.toString().isNotEmpty == true
                              ? widget.club['leadEmail'].toString()
                              : 'faculty@cb.amrita.edu • Amrita Vishwa Vidyapeetham',
                          style: TextStyle(
                            fontSize: 12,
                            color: LFColors.subtext(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (isClubLead || AuthService.isFaculty) ...[
              _buildInlineMembershipRequests(context),
            ],

            // ABOUT SECTION
            _cardSection(
              'About the Club',
              widget.club['description'],
              Icons.info_outline_rounded,
            ),

            // SPORTS INTERACTIVE SECTION
            if (isSports) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Sport Discipline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: LFColors.text(context),
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
                          color: selected ? LFColors.primary : LFColors.card(context),
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
                                    color: Colors.black.withValues(alpha: LFColors.isDark(context) ? 0.2 : 0.02),
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
                                color: selected ? Colors.white : LFColors.subtext(context),
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
              ),
            ] else
              _cardSection(
                'Next Community Event',
                'Annual Interactive Workshop & Meetup\n📅 Friday • 4:00 PM\n📍 Innovation Hub Auditorium',
                Icons.event_rounded,
              ),

            const SizedBox(height: 16),

            // STATUS BANNER
            if (isClubLead)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You are the Faculty Coordinator / Lead for this club. You can approve student membership requests.',
                        style: TextStyle(
                          color: LFColors.isDark(context) ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isJoined)
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
                        'You are an active member of this club community.',
                        style: TextStyle(
                          color: LFColors.foundText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Join request submitted. Awaiting approval from the Faculty Lead.',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ACTION BUTTON
            if (isClubLead)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showJoinRequestsSheet(context),
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: Text(
                    pendingCount > 0
                        ? 'REVIEW JOIN REQUESTS ($pendingCount PENDING)'
                        : 'MANAGE CLUB • VIEW REQUESTS',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (isJoined || _isPending || _isSubmitting) ? null : joinClub,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LFColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: LFColors.isDark(context) ? const Color(0xFF262626) : const Color(0xFFE2E8F0),
                    disabledForegroundColor: LFColors.muted(context),
                    elevation: (isJoined || _isPending) ? 0 : 4,
                    shadowColor: LFColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          isJoined
                              ? 'ALREADY JOINED ✓'
                              : (_isPending ? 'REQUEST PENDING TEACHER APPROVAL ⏳' : 'REQUEST TO JOIN CLUB'),
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
          color: LFColors.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: LFColors.isDark(context) ? 0.2 : 0.02),
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
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: LFColors.text(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: LFColors.muted(context),
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
        color: LFColors.card(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: LFColors.isDark(context) ? 0.2 : 0.03),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: LFColors.text(context),
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
            style: TextStyle(
              color: LFColors.subtext(context),
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
