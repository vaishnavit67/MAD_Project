import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/bus_schedule_item.dart';
import 'bus_tracker_locations.dart';

class BusTrackerScreen extends StatefulWidget {
  const BusTrackerScreen({super.key});

  @override
  State<BusTrackerScreen> createState() => _BusTrackerScreenState();
}

class _BaseBusInfo {
  final int hour;
  final int minute;
  final String shuttleName;
  final String? note;
  final bool isLast;

  const _BaseBusInfo(this.hour, this.minute, this.shuttleName, this.note, this.isLast);
}

class _BusTrackerScreenState extends State<BusTrackerScreen> {
  final TextEditingController _fromController = TextEditingController(text: 'AB1');
  final TextEditingController _toController = TextEditingController(text: 'AB3');
  String _selectedFilter = 'All';
  late final List<String> _places;

  @override
  void initState() {
    super.initState();
    _places = BusTrackerLocations.selectable();
    _fromController.addListener(_onRouteChanged);
    _toController.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fromController.removeListener(_onRouteChanged);
    _toController.removeListener(_onRouteChanged);
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  bool get _isFromAB1 {
    final from = _fromController.text.trim().toLowerCase();
    return from == 'ab1' || from == 'ab 1' || from == 'academic block 1';
  }

  List<BusScheduleItem> get _currentSchedules {
    const baseShuttles = [
      _BaseBusInfo(8, 50, 'Campus Shuttle #1', 'First Trip of the Day', false),
      _BaseBusInfo(9, 40, 'Campus Shuttle #2', null, false),
      _BaseBusInfo(10, 30, 'Campus Shuttle #3', null, false),
      _BaseBusInfo(11, 20, 'Campus Shuttle #1', null, false),
      _BaseBusInfo(12, 10, 'Campus Shuttle #2', null, false),
      _BaseBusInfo(13, 0, 'Campus Shuttle #3', 'Lunch Hour Express', false),
      _BaseBusInfo(13, 50, 'Campus Shuttle #1', null, false),
      _BaseBusInfo(14, 40, 'Campus Shuttle #2', null, false),
      _BaseBusInfo(15, 30, 'Campus Shuttle #3', null, false),
      _BaseBusInfo(16, 20, 'Campus Shuttle #1', null, false),
      _BaseBusInfo(16, 35, 'Campus Express', 'Final Trip of the Day', true),
    ];

    final isAb1 = _isFromAB1;

    return baseShuttles.map((b) {
      var totalMinutes = b.hour * 60 + b.minute;
      if (isAb1) {
        totalMinutes -= 5;
      }
      final adjustedHour = totalMinutes ~/ 60;
      final adjustedMinute = totalMinutes % 60;

      final period = adjustedHour >= 12 ? 'PM' : 'AM';
      final displayHour = adjustedHour > 12
          ? adjustedHour - 12
          : (adjustedHour == 0 ? 12 : adjustedHour);
      final hourStr = displayHour.toString().padLeft(2, '0');
      final minStr = adjustedMinute.toString().padLeft(2, '0');
      final formattedTime = '$hourStr:$minStr $period';

      return BusScheduleItem(
        departureTime: formattedTime,
        shuttleName: b.shuttleName,
        hour: adjustedHour,
        minute: adjustedMinute,
        note: isAb1
            ? (b.isLast ? 'AB1 Final Departure (5m before)' : 'Departs AB1 5m before AB2/AB3')
            : b.note,
        isLast: b.isLast,
      );
    }).toList();
  }

  List<BusScheduleItem> get _filteredSchedules {
    final list = _currentSchedules;
    if (_selectedFilter == 'Morning') {
      return list.where((s) => s.hour < 12).toList();
    }
    if (_selectedFilter == 'Afternoon') {
      return list.where((s) => s.hour >= 12).toList();
    }
    return list;
  }

  BusScheduleItem? _getNextBus() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    for (final bus in _currentSchedules) {
      final busMinutes = bus.hour * 60 + bus.minute;
      if (busMinutes >= currentMinutes) {
        return bus;
      }
    }
    return null;
  }

  void _openPlacesPicker(TextEditingController targetController, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final filtered = _places
                .where((p) => p.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
            final sheetBg = isDark ? const Color(0xFF1E1B2E) : AppColors.white;
            final textColor = isDark ? Colors.white : AppColors.textPrimary;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select $title Place',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        hintText: 'Search campus location...',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF12101C) : AppColors.background,
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No locations found',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: isDark ? const Color(0xFF3A3450) : AppColors.border,
                              ),
                              itemBuilder: (context, index) {
                                final place = filtered[index];
                                final isSelected = targetController.text == place;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : (isDark ? const Color(0xFF3A3450) : AppColors.featureIconBg1),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      size: 18,
                                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                  title: Text(
                                    place,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.primary : textColor,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      targetController.text = place;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextBus = _getNextBus();
    final isAb1 = _isFromAB1;

    final bgColor = isDark ? const Color(0xFF12101C) : AppColors.background;
    final cardColor = isDark ? const Color(0xFF1E1B2E) : AppColors.white;
    final borderColor = isDark ? const Color(0xFF3A3450) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark ? const Color(0xFFB0A9C9) : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Bus Tracker'),
        backgroundColor: bgColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Campus shuttle timetable for today. Times are local — this is not live GPS tracking.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildCleanInput(
                              controller: _fromController,
                              label: 'From',
                              icon: Icons.my_location_rounded,
                              iconColor: AppColors.primary,
                              isDark: isDark,
                              onDropdownTap: () => _openPlacesPicker(_fromController, 'Starting'),
                            ),
                            const SizedBox(height: 12),
                            _buildCleanInput(
                              controller: _toController,
                              label: 'To',
                              icon: Icons.location_on_rounded,
                              iconColor: AppColors.error,
                              isDark: isDark,
                              onDropdownTap: () => _openPlacesPicker(_toController, 'Destination'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: isDark ? const Color(0xFF3A3450) : AppColors.featureIconBg1,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _swapLocations,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.swap_vert_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          'Quick:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...['AB1', 'AB2', 'AB3', 'Central Library'].map((place) {
                          final isCurrentFrom = _fromController.text == place;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _toController.text = place;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isCurrentFrom
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : (isDark ? const Color(0xFF12101C) : AppColors.background),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrentFrom ? AppColors.primary : borderColor,
                                  ),
                                ),
                                child: Text(
                                  place,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrentFrom ? AppColors.primary : textColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Showing timings from ${_fromController.text} (every 50 min)',
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search_rounded, size: 20),
                      label: const Text(
                        'Search Bus',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B2E) : AppColors.featureIconBg1,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? borderColor : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  isAb1 ? 'AB1 Timings (5m Earlier)' : 'Standard Bus Timings',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _fromController.text.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isAb1
                                  ? 'Departs every 50 mins: 08:45 AM to 04:30 PM'
                                  : 'Departs every 50 mins: 08:50 AM to 04:35 PM (AB2, AB3, Library)',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? subtitleColor : AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF12101C) : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'AB1 (5m earlier)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isAb1 ? FontWeight.w800 : FontWeight.w600,
                            color: isAb1 ? AppColors.primary : subtitleColor,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                        ),
                        Text(
                          'AB2 • AB3 • Central Library',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: !isAb1 ? FontWeight.w800 : FontWeight.w600,
                            color: !isAb1 ? AppColors.primary : subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Next bus',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            if (nextBus == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'No more buses today.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              )
            else
              _buildBusTimingCard(
                item: nextBus,
                isNext: true,
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bus Timings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1B2E) : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_filteredSchedules.length} departures',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: subtitleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('All', isDark),
                _buildFilterChip('Morning', isDark),
                _buildFilterChip('Afternoon', isDark),
              ],
            ),
            const SizedBox(height: 16),
            if (_filteredSchedules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No buses match this filter.',
                  style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w600),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredSchedules.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _filteredSchedules[index];
                  final isNext = nextBus != null &&
                      nextBus.hour == item.hour &&
                      nextBus.minute == item.minute;
                  return _buildBusTimingCard(
                    item: item,
                    isNext: isNext,
                    isDark: isDark,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  );
                },
              ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onDropdownTap,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12101C) : AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        border: Border.all(color: isDark ? const Color(0xFF3A3450) : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFB0A9C9) : AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintText: 'Type location...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_drop_down_circle_outlined,
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Choose from list',
            onPressed: onDropdownTap,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? const Color(0xFF1E1B2E) : AppColors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : AppColors.textPrimary),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF3A3450) : AppColors.border),
        ),
      ),
    );
  }

  Widget _buildBusTimingCard({
    required BusScheduleItem item,
    required bool isNext,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final parts = item.departureTime.split(' ');
    final timePart = parts.isNotEmpty ? parts[0] : item.departureTime;
    final periodPart = parts.length > 1 ? parts[1] : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isNext ? AppColors.primary : borderColor,
          width: isNext ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isNext
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isNext
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF12101C) : AppColors.background),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  timePart,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isNext ? Colors.white : textColor,
                  ),
                ),
                Text(
                  periodPart,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isNext ? Colors.white70 : subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.shuttleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFABEFC6)),
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            color: Color(0xFF067647),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fromController.text} → ${_toController.text}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.isLast ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF12101C) : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.repeat_rounded, size: 12, color: subtitleColor),
                        const SizedBox(width: 4),
                        Text(
                          '50m',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
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
