/// Shuttle stop names used by Bus Tracker.
/// Kept separate from [CampusLocation] so Navigation is not affected.
class BusTrackerLocations {
  static const List<String> all = [
    'AB1',
    'AB2',
    'AB3',
    'AB4',
    'MBA Block',
    'Main Canteen',
    'MBA Canteen',
    'IT Canteen',
    'Millet Cafe',
    'Central Library',
    'Main Ground',
    'General Store',
    'Clinic',
    "Children's Park",
    'Guest House',
    'Swimming Pool',
    'Amriteshwari Hall',
    'Sudhamani Hall',
    'Mythreyi Bhavanam',
    'Gargi Bhavanam',
    'Aditi Bhavanam',
    'Savitri Bhavanam',
    'Kashyapa Bhavanam',
    'Vasishta Bhavanam',
    'Agasthya Bhavanam',
    'Dhanalakshmi Bank',
    'Dhanalakshmi ATM 1',
    'Dhanalakshmi ATM 2',
    'ICICI ATM',
    'SBI ATM',
    'Mechanical Labs',
    'Electrical Labs',
    'Staff Quarters 1',
    'Staff Quarters 2',
    'Staff Quarters 3',
    'CIR Block',
  ];

  static List<String> selectable() {
    final set = <String>{};
    for (final name in all) {
      if (!name.toLowerCase().contains('main canteen')) {
        set.add(name);
      }
    }
    set.addAll(['AB1', 'AB2', 'AB3', 'AB4', 'MBA Block', 'Central Library']);
    final list = set.toList()..sort();
    return list;
  }
}
