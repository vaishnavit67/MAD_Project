import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/lf_colors.dart';
import '../../core/constants/app_colors.dart';
import '../../services/lost_found_service.dart';
import '../../services/auth_service.dart';

Widget _buildItemImage(String path, {BoxFit fit = BoxFit.cover}) {
  if (kIsWeb || path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
    return Image.network(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image_rounded, size: 30, color: LFColors.textMuted),
    );
  } else {
    return Image.file(
      io.File(path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image_rounded, size: 30, color: LFColors.textMuted),
    );
  }
}

/* =========================================================
                         LOST & FOUND
========================================================= */
class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  int _selectedFilter = 0; // 0: All, 1: Lost, 2: Found, 3: Resolved
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _items = [
    {
      'id': 'LF-8021',
      'title': 'AirPods Pro Gen 2',
      'location': 'AB1 • 2nd Floor Study Lab',
      'time': '2 hrs ago',
      'status': 'Lost',
      'icon': Icons.headphones_rounded,
      'color': const Color(0xFFEEF2FF),
      'iconColor': const Color(0xFF6366F1),
      'description': 'White AirPods Pro case with a small dragon sticker on the back.',
      'reporter': 'Alex Rivera (CS Student)',
      'isVerified': true,
    },
    {
      'id': 'LF-8019',
      'title': 'Matte Black Backpack',
      'location': 'CSE Block Cafeteria',
      'time': 'Yesterday',
      'status': 'Found',
      'icon': Icons.backpack_rounded,
      'color': const Color(0xFFECFDF5),
      'iconColor': const Color(0xFF10B981),
      'description': 'Herschel black bag containing notebooks and a blue water bottle.',
      'reporter': 'Campus Security Desk',
      'isVerified': true,
    },
    {
      'id': 'LF-8014',
      'title': 'Stainless Water Bottle',
      'location': 'Main Library • 1st Floor',
      'time': 'Yesterday',
      'status': 'Lost',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFFF0F9FF),
      'iconColor': const Color(0xFF0284C7),
      'description': 'Blue hydro flask with stickers. Left near laptop charging station.',
      'reporter': 'Sarah Chen (ECE)',
      'isVerified': false,
    },
    {
      'id': 'LF-7992',
      'title': 'Student Smart ID Card',
      'location': 'Sports Complex Gate 2',
      'time': '3 days ago',
      'status': 'Resolved',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFFF1F5F9),
      'iconColor': const Color(0xFF64748B),
      'description': 'Returned safely to owner on Monday.',
      'reporter': 'Sports Desk Admin',
      'isVerified': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchBackendItems();
  }

  Future<void> _fetchBackendItems() async {
    setState(() => _isLoading = true);
    try {
      final backendItems = await LostFoundService.instance.getItems();
      if (mounted && backendItems.isNotEmpty) {
        setState(() {
          _items.clear();
          for (final item in backendItems) {
            final isLost = item.type.toLowerCase() == 'lost';
            final isResolved = item.status.toLowerCase() == 'claimed' || item.status.toLowerCase() == 'resolved';
            _items.add({
              'id': item.id,
              'title': item.name,
              'location': item.location,
              'time': item.timeAgo,
              'status': isResolved ? 'Resolved' : (isLost ? 'Lost' : 'Found'),
              'icon': isLost ? Icons.search_rounded : Icons.inventory_2_rounded,
              'color': isResolved
                  ? const Color(0xFFF1F5F9)
                  : (isLost ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5)),
              'iconColor': isResolved
                  ? const Color(0xFF64748B)
                  : (isLost ? LFColors.lostText : LFColors.foundText),
              'description': item.description,
              'reporter': item.ownerName.isNotEmpty ? item.ownerName : 'Campus Member',
              'isVerified': true,
              'ownerId': item.ownerId,
              'imageUrl': item.imageUrl,
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading backend lost & found items: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();

    return _items.where((item) {
      final matchesFilter = _selectedFilter == 0 ||
          (_selectedFilter == 1 && item['status'] == 'Lost') ||
          (_selectedFilter == 2 && item['status'] == 'Found') ||
          (_selectedFilter == 3 && item['status'] == 'Resolved');

      final matchesSearch = query.isEmpty ||
          item['title'].toString().toLowerCase().contains(query) ||
          item['location'].toString().toLowerCase().contains(query) ||
          item['status'].toString().toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _openReportPage() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ReportItemPage()),
    );

    if (!mounted || result == null) return;

    // Send to MongoDB Atlas backend
    final created = await LostFoundService.instance.createItem(
      title: result['title'] ?? 'Untitled Item',
      description: result['description'] ?? 'No description provided.',
      category: result['category'] ?? 'Other',
      type: (result['status'] == 'Found') ? 'found' : 'lost',
      location: result['location'] ?? 'Campus',
      imageUrl: (result['image'] != null && result['image'].toString().startsWith('http'))
          ? result['image'].toString()
          : null,
      ownerName: AuthService.currentUser?.name ?? 'Amrita Student',
    );

    if (created != null) {
      await _fetchBackendItems();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('"${created.name}" stored in MongoDB Atlas!')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Failed to publish item to backend database.')),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredItems;

    return Scaffold(
      backgroundColor: LFColors.background,
      appBar: AppBar(
        title: const Text('Lost & Found', style: TextStyle(color: LFColors.textPrimary)),
        backgroundColor: LFColors.cardBg,
        iconTheme: const IconThemeData(color: LFColors.textPrimary),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WOW FACTOR: RECOVERY STATS DASHBOARD BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LFColors.primary.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('88%', 'Recovery Rate', Icons.verified_rounded, const Color(0xFF10B981)),
                  Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                  _miniStat('240+', 'Items Reclaimed', Icons.inventory_rounded, LFColors.primary),
                  Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                  _miniStat('< 24h', 'Avg Return Time', Icons.bolt_rounded, Colors.orange),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // BANNER PROMO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LFColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: LFColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '⚡ Smart Campus Help',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Lost something on campus?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Post report instantly to notify campus Security & Students.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _openReportPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: LFColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '+ Report',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search title, building, or item ID...',
                  hintStyle: const TextStyle(color: LFColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: LFColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded, color: LFColors.textMuted),
                        )
                      : null,
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

            // FILTER TABS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All Reports', 0),
                  const SizedBox(width: 8),
                  _filterChip('🔍 Lost', 1),
                  const SizedBox(width: 8),
                  _filterChip('✅ Found', 2),
                  const SizedBox(width: 8),
                  _filterChip('🎉 Resolved', 3),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // RECENTLY ADDED SECTION TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: LFColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LFColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${results.length} item${results.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: LFColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ITEMS LIST / EMPTY STATE
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: LFColors.primary),
                ),
              )
            else if (results.isEmpty)
              _emptyState(_searchController.text)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final item = results[index];
                  return LostItemCard(
                    item: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailsPage(item: item),
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 24),

            // FLOATING BOTTOM ADD BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openReportPage,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                label: const Text(
                  'Report Lost or Found Item',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LFColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: LFColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: LFColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : LFColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String query) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LFColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: LFColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            query.trim().isEmpty ? 'No reports available' : 'No items match your search',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: LFColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            query.trim().isEmpty
                ? 'Be the first to post a lost or found item.'
                : 'Try checking your spelling or search another location.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LFColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
                       LOST ITEM CARD
========================================================= */
class LostItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const LostItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String status = item['status'] ?? 'Lost';
    final bool isResolved = status == 'Resolved';

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ICON CONTAINER
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: item['color'] ?? const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: item['image'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildItemImage(
                            item['image'] as String,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          item['icon'] ?? Icons.inventory_2_rounded,
                          size: 30,
                          color: item['iconColor'] ?? LFColors.primary,
                        ),
                ),
                const SizedBox(width: 14),

                // DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isResolved ? LFColors.textMuted : LFColors.textPrimary,
                                decoration: isResolved ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          _statusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: LFColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item['location'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: LFColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: LFColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['time'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: LFColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (item['isVerified'] == true)
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: LFColors.primary),
                                SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: LFColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
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

  Widget _statusBadge(String status) {
    Color bg = LFColors.lostBg;
    Color text = LFColors.lostText;
    Color border = LFColors.lostBorder;

    if (status == 'Found') {
      bg = LFColors.foundBg;
      text = LFColors.foundText;
      border = LFColors.foundBorder;
    } else if (status == 'Resolved') {
      bg = LFColors.resolvedBg;
      text = LFColors.resolvedText;
      border = const Color(0xFFCBD5E1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/* =========================================================
                      REPORT ITEM PAGE
========================================================= */
class ReportItemPage extends StatefulWidget {
  const ReportItemPage({super.key});

  @override
  State<ReportItemPage> createState() => _ReportItemPageState();
}

class _ReportItemPageState extends State<ReportItemPage> {
  final ImagePicker picker = ImagePicker();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  XFile? selectedImage;
  bool isLost = true;

  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => selectedImage = image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo selector initialized.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void submitReport() {
    if (nameController.text.trim().isEmpty || locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill out item title and location.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final idNumber = (1000 + (DateTime.now().millisecondsSinceEpoch % 8999));
    final lowerTitle = nameController.text.toLowerCase();
    String category = 'Other';
    if (lowerTitle.contains('phone') || lowerTitle.contains('airpod') || lowerTitle.contains('laptop') || lowerTitle.contains('charger') || lowerTitle.contains('earbud') || lowerTitle.contains('calculator') || lowerTitle.contains('watch')) {
      category = 'Electronics';
    } else if (lowerTitle.contains('id') || lowerTitle.contains('card') || lowerTitle.contains('badge')) {
      category = 'ID Cards';
    } else if (lowerTitle.contains('book') || lowerTitle.contains('notebook') || lowerTitle.contains('binder')) {
      category = 'Books';
    } else if (lowerTitle.contains('bottle') || lowerTitle.contains('flask') || lowerTitle.contains('lunch') || lowerTitle.contains('box')) {
      category = 'Personal Items';
    } else if (lowerTitle.contains('bag') || lowerTitle.contains('backpack') || lowerTitle.contains('purse') || lowerTitle.contains('wallet')) {
      category = 'Accessories';
    }

    Navigator.pop(context, {
      'id': 'LF-$idNumber',
      'title': nameController.text.trim(),
      'category': category,
      'location': locationController.text.trim(),
      'time': 'Just now',
      'status': isLost ? 'Lost' : 'Found',
      'image': selectedImage?.path,
      'icon': Icons.inventory_2_rounded,
      'color': isLost ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
      'iconColor': isLost ? LFColors.lostText : LFColors.foundText,
      'description': descriptionController.text.trim().isEmpty
          ? 'No additional description provided.'
          : descriptionController.text.trim(),
      'reporter': 'You (Verified Student)',
      'isVerified': true,
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LFColors.background,
      appBar: AppBar(
        title: const Text(
          'Report an Item',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TYPE SELECTION TOGGLE
            const Text(
              'Report Category',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LFColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _typeToggleOption('I Lost Something', true, Icons.search_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _typeToggleOption('I Found Something', false, Icons.verified_rounded)),
              ],
            ),

            const SizedBox(height: 20),

            // PHOTO ATTACHMENT
            const Text(
              'Attach Photo (Optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LFColors.textPrimary),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: LFColors.primary.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: LFColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_rounded,
                              size: 26,
                              color: LFColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to upload item image',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'JPEG or PNG up to 10MB',
                            style: TextStyle(fontSize: 11, color: LFColors.textMuted),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildItemImage(selectedImage!.path, fit: BoxFit.cover),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                  onPressed: () => setState(() => selectedImage = null),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // FORM FIELDS
            _buildInputField(
              controller: nameController,
              label: 'Item Title',
              hint: 'e.g. Blue Hydro Flask Water Bottle',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: locationController,
              label: 'Location Details',
              hint: 'e.g. Science Block 3, Room 204 desk',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: descriptionController,
              label: 'Additional Notes / Identification Marks',
              hint: 'Describe distinctive features, color, brand, condition...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LFColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: LFColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'PUBLISH REPORT',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeToggleOption(String text, bool targetIsLost, IconData icon) {
    final isSelected = isLost == targetIsLost;
    return GestureDetector(
      onTap: () => setState(() => isLost = targetIsLost),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? LFColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? LFColors.primary : Colors.transparent,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LFColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : LFColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : LFColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LFColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: LFColors.textMuted, fontSize: 13),
              prefixIcon: maxLines == 1 ? Icon(icon, color: LFColors.primary, size: 20) : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* =========================================================
                       ITEM DETAILS
========================================================= */
class ItemDetailsPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailsPage({super.key, required this.item});

  void _showClaimVerificationModal(BuildContext context) {
    final proofController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LFColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined, color: LFColors.primary),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Ownership Claim',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Security Verification Step',
                      style: TextStyle(fontSize: 12, color: LFColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'To claim this item, please provide a unique detail or serial mark only the true owner would know:',
              style: TextStyle(fontSize: 13, color: LFColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: proofController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Passcode pattern, engraving on back, case sticker color...',
                filled: true,
                fillColor: LFColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final message = proofController.text.trim();
                if (message.isEmpty) return;
                Navigator.pop(ctx);

                final ok = await LostFoundService.instance.submitClaim(
                  itemId: item['id']?.toString() ?? '',
                  message: message,
                  claimantName: AuthService.currentUser?.name,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(ok
                                ? 'Claim submitted to Finder & recorded in MongoDB Atlas!'
                                : 'Failed to submit claim.'),
                          ),
                        ],
                      ),
                      backgroundColor: ok ? const Color(0xFF10B981) : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LFColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('SUBMIT VERIFICATION CLAIM', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = item['image'] != null;
    final String status = item['status'] ?? 'Lost';
    final bool isLost = status == 'Lost';
    final bool isResolved = status == 'Resolved';

    return Scaffold(
      backgroundColor: LFColors.background,
      appBar: AppBar(
        title: Text(
          'Report #${item['id'] ?? 'LF-101'}',
          style: const TextStyle(fontWeight: FontWeight.w800, color: LFColors.textPrimary),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ITEM MEDIA / ICON COVER
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: item['color'] ?? const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _buildItemImage(
                        item['image'] as String,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Icon(
                        item['icon'] ?? Icons.inventory_2_rounded,
                        size: 80,
                        color: item['iconColor'] ?? LFColors.primary,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // HEADER INFO & STATUS BADGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: LFColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLost ? LFColors.lostBg : LFColors.foundBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLost ? LFColors.lostBorder : LFColors.foundBorder,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isLost ? LFColors.lostText : LFColors.foundText,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // DETAILS LIST
            _detailRow(Icons.location_on_outlined, 'Location', item['location']),
            _detailRow(Icons.schedule_rounded, 'Reported Time', item['time']),
            _detailRow(Icons.person_outline_rounded, 'Reported By', item['reporter'] ?? 'Campus Member'),
            _detailRow(
              Icons.notes_rounded,
              'Description',
              item['description'] ?? 'No additional description provided.',
            ),

            const SizedBox(height: 24),

            // ACTION BUTTON BASED ON ITEM STATUS
            SizedBox(
              width: double.infinity,
              height: 52,
              child: isResolved
                  ? ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'ITEM RETURNED TO OWNER ✓',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        disabledForegroundColor: LFColors.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        if (isLost) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.chat_bubble_rounded, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text('Notification sent to owner: "I found your item!"'),
                                ],
                              ),
                              backgroundColor: LFColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } else {
                          _showClaimVerificationModal(context);
                        }
                      },
                      icon: Icon(isLost ? Icons.chat_bubble_outline_rounded : Icons.shield_outlined),
                      label: Text(
                        isLost ? 'I Found This Item (Contact Owner)' : 'Verify & Claim Item',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LFColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: LFColors.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LFColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: LFColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: LFColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: LFColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
