import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';

class CampusNode {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final bool isPoi;

  const CampusNode({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.category = 'Junction',
    this.isPoi = false,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

class CampusEdge {
  final String fromId;
  final String toId;
  final double distanceMeters;
  final String roadName;
  final bool isWalkway;

  const CampusEdge({
    required this.fromId,
    required this.toId,
    required this.distanceMeters,
    required this.roadName,
    this.isWalkway = true,
  });
}

class CampusGraph {
  final Map<String, CampusNode> nodes = {};
  final Map<String, List<CampusEdge>> adjacencyList = {};

  void addNode(CampusNode node) {
    nodes[node.id] = node;
    adjacencyList.putIfAbsent(node.id, () => []);
  }

  void addEdge(String fromId, String toId, String roadName, {bool isWalkway = true}) {
    final fromNode = nodes[fromId];
    final toNode = nodes[toId];
    if (fromNode == null || toNode == null) return;

    final dist = const Distance().as(LengthUnit.Meter, fromNode.latLng, toNode.latLng);

    // Bidirectional edges
    adjacencyList.putIfAbsent(fromId, () => []).add(CampusEdge(
      fromId: fromId,
      toId: toId,
      distanceMeters: dist,
      roadName: roadName,
      isWalkway: isWalkway,
    ));

    adjacencyList.putIfAbsent(toId, () => []).add(CampusEdge(
      fromId: toId,
      toId: fromId,
      distanceMeters: dist,
      roadName: roadName,
      isWalkway: isWalkway,
    ));
  }

  CampusNode? findNearestNode(double lat, double lng) {
    if (nodes.isEmpty) return null;
    final point = LatLng(lat, lng);
    const distance = Distance();

    CampusNode? closest;
    double minDistance = double.infinity;

    for (final node in nodes.values) {
      final d = distance.as(LengthUnit.Meter, point, node.latLng);
      if (d < minDistance) {
        minDistance = d;
        closest = node;
      }
    }
    return closest;
  }

  CampusNode? findNodeByName(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    // 1. Exact ID or name match
    if (nodes.containsKey(clean)) return nodes[clean];

    for (final node in nodes.values) {
      if (node.id.toLowerCase() == clean || node.name.toLowerCase() == clean) {
        return node;
      }
    }

    // 2. Normalized alias comparisons (handling transliteration and spelling variants)
    String normalize(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .replaceAll('dhanlaxmi', 'dhanalakshmi')
        .replaceAll('maitheyi', 'mythreyi')
        .replaceAll('adithi', 'aditi')
        .replaceAll('yagnavalkya', 'kashyapa');

    final cleanNorm = normalize(clean);

    for (final node in nodes.values) {
      final nodeNorm = normalize(node.name);
      final idNorm = normalize(node.id);
      if (nodeNorm == cleanNorm || idNorm == cleanNorm) {
        return node;
      }
    }

    // 3. Partial match
    for (final node in nodes.values) {
      final nodeLower = node.name.toLowerCase();
      if (nodeLower.contains(clean) || clean.contains(nodeLower)) {
        return node;
      }
      final nodeNorm = normalize(node.name);
      if (nodeNorm.contains(cleanNorm) || cleanNorm.contains(nodeNorm)) {
        return node;
      }
    }

    // 4. Fallback lookup in campusLocations by geographic coordinates
    try {
      final matchLoc = campusLocations.firstWhere(
        (loc) =>
            loc.name.toLowerCase() == clean ||
            loc.name.toLowerCase().contains(clean) ||
            clean.contains(loc.name.toLowerCase()) ||
            normalize(loc.name) == cleanNorm,
      );
      if (matchLoc.latitude != null && matchLoc.longitude != null) {
        final nearest = findNearestNode(matchLoc.latitude!, matchLoc.longitude!);
        if (nearest != null) return nearest;
      }
    } catch (_) {}

    return null;
  }

  /// Returns all unique road and walkway segments across the Amrita campus as LatLng pairs
  List<List<LatLng>> getAllRoadPolylines() {
    final seen = <String>{};
    final segments = <List<LatLng>>[];

    for (final entry in adjacencyList.entries) {
      final fromNode = nodes[entry.key];
      if (fromNode == null) continue;

      for (final edge in entry.value) {
        final toNode = nodes[edge.toId];
        if (toNode == null) continue;

        final key = (fromNode.id.compareTo(toNode.id) < 0)
            ? '${fromNode.id}__${toNode.id}'
            : '${toNode.id}__${fromNode.id}';

        if (!seen.contains(key)) {
          seen.add(key);
          segments.add([fromNode.latLng, toNode.latLng]);
        }
      }
    }
    return segments;
  }

  /// Builds the complete authentic road & walkway network for Amrita Vishwa Vidyapeetham, Ettimadai, Coimbatore
  static CampusGraph buildAmritaCampusGraph() {
    final graph = CampusGraph();

    // 1. GATES & SOUTH-WEST ENTRY (Centered on outdoor street, 0 building collisions)
    graph.addNode(const CampusNode(id: 'main_gate', name: 'Main Gate Entrance', latitude: 10.89926, longitude: 76.90061, category: 'Gate', isPoi: true));
    graph.addNode(const CampusNode(id: 'bank_road_fork', name: 'Main Gate Avenue West Fork', latitude: 10.89926, longitude: 76.90020, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'bank_junc', name: 'Bank Arcade Paved Walk', latitude: 10.89950, longitude: 76.90020, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'bank_curve', name: 'Central Boulevard South Bend', latitude: 10.89970, longitude: 76.90000, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'dhanalakshmi_bank', name: 'Dhanalakshmi Bank', latitude: 10.89952, longitude: 76.90018, category: 'Bank', isPoi: true));
    graph.addNode(const CampusNode(id: 'dhanlaxmi_bank', name: 'Dhanlaxmi Bank & ATM', latitude: 10.89952, longitude: 76.90018, category: 'Bank', isPoi: true));
    graph.addNode(const CampusNode(id: 'dhanalakshmi_atm_1', name: 'Dhanalakshmi ATM 1', latitude: 10.89952, longitude: 76.90018, category: 'ATM', isPoi: true));
    graph.addNode(const CampusNode(id: 'icici_atm', name: 'ICICI ATM', latitude: 10.89945, longitude: 76.90025, category: 'ATM', isPoi: true));

    // 2. SOUTH AVENUE & AB1 (ENGINEERING CORE - Clear of building geometry)
    graph.addNode(const CampusNode(id: 'south_gate_fork', name: 'Main Avenue East Fork', latitude: 10.89926, longitude: 76.90065, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'south_spine_1', name: 'Main Avenue Bend', latitude: 10.89940, longitude: 76.90150, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'south_spine_2', name: 'South Avenue Mid Junction', latitude: 10.89945, longitude: 76.90210, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'saraswati_circle', name: 'Saraswati Statue', latitude: 10.89980, longitude: 76.90215, category: 'Landmark', isPoi: true));
    graph.addNode(const CampusNode(id: 'childrens_park', name: "Children's Park", latitude: 10.89980, longitude: 76.90215, category: 'Park', isPoi: true));
    graph.addNode(const CampusNode(id: 'ab1_south_entrance', name: 'AB1 South Entrance Portico', latitude: 10.90008, longitude: 76.90215, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'ab1_portico', name: 'AB1 Portico Steps', latitude: 10.90008, longitude: 76.90215, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'ab1', name: 'Academic Block 1 (AB1)', latitude: 10.90008, longitude: 76.90215, category: 'Academic Block', isPoi: true));
    graph.addNode(const CampusNode(id: 'dhanalakshmi_atm_2', name: 'Dhanalakshmi ATM 2', latitude: 10.90008, longitude: 76.90215, category: 'ATM', isPoi: true));
    graph.addNode(const CampusNode(id: 'ab1_west_walk_1', name: 'AB1 West Walkway South', latitude: 10.90050, longitude: 76.90210, category: 'Walkway'));
    graph.addNode(const CampusNode(id: 'ab1_west_walk_2', name: 'AB1 West Walkway North', latitude: 10.90095, longitude: 76.90210, category: 'Walkway'));
    graph.addNode(const CampusNode(id: 'ab1_north_junc', name: 'AB1 North Quad Walkway', latitude: 10.90105, longitude: 76.90210, category: 'Junction'));

    // 3. MAIN CANTEEN & EAST RESIDENTIAL ZONE
    graph.addNode(const CampusNode(id: 'ab1_canteen_walk', name: 'AB1 Canteen Walkway', latitude: 10.89945, longitude: 76.90288, category: 'Walkway'));
    graph.addNode(const CampusNode(id: 'canteen_promenade', name: 'Canteen Promenade Walkway', latitude: 10.89945, longitude: 76.90350, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'main_canteen', name: 'Main Canteen', latitude: 10.89985, longitude: 76.90350, category: 'Canteen', isPoi: true));
    graph.addNode(const CampusNode(id: 'amriteshwari_hall', name: 'Amriteshwari Hall', latitude: 10.90035, longitude: 76.90350, category: 'Auditorium', isPoi: true));
    graph.addNode(const CampusNode(id: 'savitri_road_junc', name: 'South Campus Residential Lane', latitude: 10.89945, longitude: 76.90356, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'savitri_bhavanam', name: 'Savitri Bhavanam', latitude: 10.89790, longitude: 76.90490, category: 'Girls Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'east_hostel_junc', name: 'East Hostel Avenue', latitude: 10.90035, longitude: 76.90450, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'nachiketas_bhavanam', name: 'Nachiketas Bhavanam', latitude: 10.90050, longitude: 76.90455, category: 'Boys Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'nachiketas_north_corner', name: 'East Hostel Lane North', latitude: 10.90095, longitude: 76.90450, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'yagnavalkya_junc', name: 'Yagnavalkya Quad', latitude: 10.90095, longitude: 76.90480, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'yagnavalkya_bhavanam', name: 'Yagnavalkya Bhavanam', latitude: 10.90105, longitude: 76.90480, category: 'Boys Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'kashyapa_bhavanam', name: 'Kashyapa Bhavanam', latitude: 10.90105, longitude: 76.90480, category: 'Boys Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'vyasa_lane', name: 'Vyasa Approach Lane', latitude: 10.90095, longitude: 76.90535, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'vyasa_bhavanam', name: 'Vyasa Maharishi Bhavanam', latitude: 10.90165, longitude: 76.90540, category: 'Boys Hostel', isPoi: true));

    // 4. CENTRAL CAMPUS SPINE & PLAZA (MAITHEYI, KITCHEN, TEMPLE, MILLET CAFE)
    graph.addNode(const CampusNode(id: 'central_spine_1', name: 'Central Boulevard South', latitude: 10.90000, longitude: 76.89980, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'maitheyi_junc', name: 'Central Boulevard Walk', latitude: 10.90060, longitude: 76.89977, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'central_spine_2', name: 'Central Boulevard Mid', latitude: 10.90095, longitude: 76.89975, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'kitchen_junc', name: 'Central Dining Lane Fork', latitude: 10.90150, longitude: 76.89975, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'temple_circle', name: 'Campus Temple Plaza', latitude: 10.90195, longitude: 76.89977, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'temple', name: 'Campus Temple & Shrine', latitude: 10.90200, longitude: 76.90045, category: 'Place of Worship', isPoi: true));
    graph.addNode(const CampusNode(id: 'millet_cafe_junc', name: 'Millet Cafe Promenade', latitude: 10.90235, longitude: 76.89975, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'millet_cafe', name: 'Millet Cafe', latitude: 10.90240, longitude: 76.89975, category: 'Cafe', isPoi: true));
    graph.addNode(const CampusNode(id: 'central_circle', name: 'Central Academic Circle', latitude: 10.90265, longitude: 76.90045, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'central_sports_connector', name: 'Central Sports Walkway', latitude: 10.90265, longitude: 76.90260, category: 'Junction'));

    // 5. MAITHEYI & MYTHREYI ACCESS
    graph.addNode(const CampusNode(id: 'maitheyi_lane_south', name: 'Maitheyi Entrance Way', latitude: 10.89940, longitude: 76.90120, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'maitheyi_bhavanam', name: 'Maitheyi Bhavanam', latitude: 10.90040, longitude: 76.90120, category: 'Girls Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'mythreyi_bhavanam', name: 'Mythreyi Bhavanam', latitude: 10.90040, longitude: 76.90120, category: 'Girls Hostel', isPoi: true));

    // 6. CLINIC, GYM & MAIN PLAYGROUND
    graph.addNode(const CampusNode(id: 'clinic_lane', name: 'Central Service Lane', latitude: 10.90155, longitude: 76.90100, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'central_kitchen', name: 'Central Kitchen', latitude: 10.90155, longitude: 76.90100, category: 'Dining', isPoi: true));
    graph.addNode(const CampusNode(id: 'general_store', name: 'General Store', latitude: 10.90155, longitude: 76.90100, category: 'Store', isPoi: true));
    graph.addNode(const CampusNode(id: 'clinic_cross', name: 'University Clinic Cross', latitude: 10.90155, longitude: 76.90155, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'clinic', name: 'University Clinic', latitude: 10.90155, longitude: 76.90155, category: 'Medical Facility', isPoi: true));
    graph.addNode(const CampusNode(id: 'gym_junc', name: 'Boys Gym South Entrance', latitude: 10.90155, longitude: 76.90205, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'gym_boys', name: 'Amrita Boys Gym', latitude: 10.90160, longitude: 76.90205, category: 'Sports Facility', isPoi: true));
    graph.addNode(const CampusNode(id: 'playground_approach', name: 'Playground Approach', latitude: 10.90260, longitude: 76.90260, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'playground', name: 'Amrita Playground (Main Ground)', latitude: 10.90260, longitude: 76.90260, category: 'Sports Ground', isPoi: true));
    graph.addNode(const CampusNode(id: 'main_ground', name: 'Main Ground', latitude: 10.90260, longitude: 76.90260, category: 'Sports Ground', isPoi: true));

    // 7. WEST WING (GUEST HOUSE, HOSTELS, WORKSHOPS)
    graph.addNode(const CampusNode(id: 'guest_house_junc', name: 'Guest House Lane Fork', latitude: 10.90150, longitude: 76.89970, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'guest_house', name: 'Amrita Guest House', latitude: 10.90155, longitude: 76.89910, category: 'Guest House', isPoi: true));
    graph.addNode(const CampusNode(id: 'west_ring_1', name: 'West Ring Road South', latitude: 10.90220, longitude: 76.89880, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'west_ring_2', name: 'West Hostels Connector', latitude: 10.90225, longitude: 76.89740, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'vasishta_junc', name: 'Vasishta Quad Entrance', latitude: 10.90210, longitude: 76.89650, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'vasishta_bhavanam', name: 'Vasishta Bhavanam', latitude: 10.90205, longitude: 76.89640, category: 'Boys Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'west_gym_bend', name: 'West Gym Approach', latitude: 10.90210, longitude: 76.89530, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'arogya_gym', name: 'Arogya Sadhanam Gym', latitude: 10.90170, longitude: 76.89500, category: 'Sports Facility', isPoi: true));
    graph.addNode(const CampusNode(id: 'agasthya_junc', name: 'Agasthya Hostel Way', latitude: 10.90220, longitude: 76.89665, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'agasthya_bhavanam', name: 'Agasthya Bhavanam', latitude: 10.90220, longitude: 76.89635, category: 'Boys Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'agastya_mess_junc', name: 'West Mess Entrance Lane', latitude: 10.90280, longitude: 76.89665, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'agastya_mess', name: 'Agastya/Gautama Mess', latitude: 10.90300, longitude: 76.89650, category: 'Dining', isPoi: true));
    graph.addNode(const CampusNode(id: 'gauthama_junc', name: 'Gauthama Quad Way', latitude: 10.90240, longitude: 76.89775, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'gauthama_bhavanam', name: 'Gauthama Bhavanam', latitude: 10.90240, longitude: 76.89765, category: 'Boys Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'gargi_walk', name: 'Gargi Garden Walkway', latitude: 10.90225, longitude: 76.89880, category: 'Walkway'));
    graph.addNode(const CampusNode(id: 'gargi_bhavanam', name: 'Gargi Bhavanam', latitude: 10.90350, longitude: 76.90035, category: 'Girls Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'natarajar_statue', name: 'Natarajar Statue', latitude: 10.90330, longitude: 76.89843, category: 'Landmark', isPoi: true));

    // 8. CENTRAL ACADEMIC HUB (LIBRARY, AB2, ARJUNA STATUE)
    graph.addNode(const CampusNode(id: 'north_gargi_bend', name: 'North Gargi Avenue Bend', latitude: 10.90355, longitude: 76.90045, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'library_avenue_bend', name: 'Library Avenue Bend', latitude: 10.90355, longitude: 76.90035, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'arjuna_plaza', name: 'Arjuna Bronze Chariot Plaza', latitude: 10.90365, longitude: 76.89950, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'arjuna_statue', name: 'Arjuna Statue', latitude: 10.90365, longitude: 76.89950, category: 'Landmark', isPoi: true));
    graph.addNode(const CampusNode(id: 'library_garden', name: 'Amrita Library Garden', latitude: 10.90365, longitude: 76.89920, category: 'Garden', isPoi: true));
    graph.addNode(const CampusNode(id: 'library_steps', name: 'Central Library Entrance Steps', latitude: 10.90385, longitude: 76.89920, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'central_library', name: 'Central Library', latitude: 10.90385, longitude: 76.89920, category: 'Library', isPoi: true));
    graph.addNode(const CampusNode(id: 'sbi_atm', name: 'SBI ATM', latitude: 10.90385, longitude: 76.89920, category: 'ATM', isPoi: true));
    graph.addNode(const CampusNode(id: 'ab2_portico', name: 'AB2 Main Portico Steps', latitude: 10.90348, longitude: 76.89850, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'ab2', name: 'Academic Block 2 (AB2)', latitude: 10.90348, longitude: 76.89850, category: 'Academic Block', isPoi: true));
    graph.addNode(const CampusNode(id: 'library_east_walk_1', name: 'Library East Promenade South', latitude: 10.90420, longitude: 76.89955, category: 'Walkway'));
    graph.addNode(const CampusNode(id: 'library_east_walk_2', name: 'Library East Promenade North', latitude: 10.90520, longitude: 76.89955, category: 'Walkway'));
    graph.addNode(const CampusNode(id: 'west_ab2_avenue_south', name: 'West AB2 Avenue South', latitude: 10.90348, longitude: 76.89760, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'west_ab2_avenue_mid', name: 'West AB2 Avenue Mid', latitude: 10.90435, longitude: 76.89760, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'west_ab2_avenue_north', name: 'West AB2 Avenue North', latitude: 10.90520, longitude: 76.89760, category: 'Junction'));

    // 9. NORTH ACADEMIC, LAW SCHOOL & CYBER LAB
    graph.addNode(const CampusNode(id: 'north_academic_cross', name: 'North Academic Cross', latitude: 10.90520, longitude: 76.89860, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'cyber_lab', name: 'Cyber Lab', latitude: 10.90520, longitude: 76.89860, category: 'Laboratory', isPoi: true));
    graph.addNode(const CampusNode(id: 'ab4', name: 'Academic Block 4 (AB4)', latitude: 10.90520, longitude: 76.89860, category: 'Academic Block', isPoi: true));
    graph.addNode(const CampusNode(id: 'it_canteen', name: 'IT Canteen', latitude: 10.90480, longitude: 76.89785, category: 'Canteen', isPoi: true));
    graph.addNode(const CampusNode(id: 'ab3_approach', name: 'Law School Promenade', latitude: 10.90550, longitude: 76.89750, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'ab3_junc', name: 'AB3 Portico Circle', latitude: 10.90585, longitude: 76.89750, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'ab3', name: 'Academic Block 3 (AB3)', latitude: 10.90585, longitude: 76.89750, category: 'Academic Block', isPoi: true));

    // 10. WORKSHOPS & LABS
    graph.addNode(const CampusNode(id: 'workshop_lane', name: 'Industrial Labs Lane', latitude: 10.90435, longitude: 76.89720, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'workshop_junc', name: 'Mechanical Quad', latitude: 10.90435, longitude: 76.89620, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'fab_workshop', name: 'Fabrication Workshop', latitude: 10.90480, longitude: 76.89570, category: 'Laboratory', isPoi: true));
    graph.addNode(const CampusNode(id: 'mechanical_labs', name: 'Mechanical Labs', latitude: 10.90480, longitude: 76.89570, category: 'Laboratory', isPoi: true));
    graph.addNode(const CampusNode(id: 'aartc_lane', name: 'Automotive Research Lane', latitude: 10.90360, longitude: 76.89620, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'aartc', name: 'Automotive Research Centre', latitude: 10.90360, longitude: 76.89600, category: 'Laboratory', isPoi: true));
    graph.addNode(const CampusNode(id: 'electrical_labs', name: 'Electrical Labs', latitude: 10.90360, longitude: 76.89600, category: 'Laboratory', isPoi: true));

    // 11. MANAGEMENT & AUDITORIUM ZONE
    graph.addNode(const CampusNode(id: 'mgmt_fork', name: 'Management Avenue Fork', latitude: 10.90365, longitude: 76.90080, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'mgmt_avenue', name: 'School of Business Avenue', latitude: 10.90400, longitude: 76.90150, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'mba_block', name: 'Amrita School of Business (MBA)', latitude: 10.90410, longitude: 76.90180, category: 'Academic Block', isPoi: true));
    graph.addNode(const CampusNode(id: 'auditorium_junc', name: 'Auditorium Plaza', latitude: 10.90415, longitude: 76.90220, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'mba_canteen', name: 'MBA Canteen', latitude: 10.90440, longitude: 76.90215, category: 'Canteen', isPoi: true));
    graph.addNode(const CampusNode(id: 'auditorium', name: 'Main Auditorium', latitude: 10.90425, longitude: 76.90240, category: 'Auditorium', isPoi: true));
    graph.addNode(const CampusNode(id: 'sudhamani_hall', name: 'Sudhamani Hall', latitude: 10.90425, longitude: 76.90240, category: 'Hall', isPoi: true));
    graph.addNode(const CampusNode(id: 'cir_junc', name: 'Corporate Relations Drive', latitude: 10.90490, longitude: 76.90144, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'cir_block', name: 'Corporate & Industry Relations (CIR)', latitude: 10.90510, longitude: 76.90165, category: 'Administrative Block', isPoi: true));

    // 12. NORTH RESIDENTIAL & SWIMMING POOL (Bypassing pool along authentic paved roadways)
    graph.addNode(const CampusNode(id: 'pool_south_west_junc', name: 'West Pool Approach', latitude: 10.90591, longitude: 76.89845, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'pool_west_avenue', name: 'West Pool Promenade', latitude: 10.90611, longitude: 76.89827, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'pool_north_west_junc', name: 'North West Pool Bend', latitude: 10.90683, longitude: 76.89801, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'north_residence_cross', name: 'North Residence Cross', latitude: 10.90730, longitude: 76.89840, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'aditi_bhavanam', name: 'Aditi Bhavanam', latitude: 10.90733, longitude: 76.89880, category: 'Girls Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'adithi_bhavanam', name: 'Adithi Bhavanam', latitude: 10.90733, longitude: 76.89880, category: 'Girls Hostel', isPoi: true));

    // East Pool bypass avenue & Aquatic Center entrance
    graph.addNode(const CampusNode(id: 'east_pool_south', name: 'East Pool Avenue South', latitude: 10.90600, longitude: 76.89958, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'east_pool_junc', name: 'Aquatic Center Fork', latitude: 10.90622, longitude: 76.89935, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'east_pool_north', name: 'East Pool Avenue North', latitude: 10.90729, longitude: 76.89973, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'pool_entrance_approach', name: 'Aquatic Center Access Road', latitude: 10.90592, longitude: 76.89921, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'pool_deck_entrance', name: 'Aquatic Center Concourse', latitude: 10.90587, longitude: 76.89881, category: 'Junction'));
    graph.addNode(const CampusNode(id: 'swimming_pool', name: 'Amrita Swimming Pool', latitude: 10.90598, longitude: 76.89882, category: 'Sports Facility', isPoi: true));

    // 13. ADDITIONAL REAL CAMPUS LANDMARKS & EXTENDED FACILITIES
    graph.addNode(const CampusNode(id: 'admin_block', name: 'University Administrative Block', latitude: 10.90380, longitude: 76.90020, category: 'Administrative Block', isPoi: true));
    graph.addNode(const CampusNode(id: 'agri_farm', name: 'School of Agriculture Farm', latitude: 10.90709, longitude: 76.90194, category: 'Field', isPoi: true));
    graph.addNode(const CampusNode(id: 'yagnavalkya_annexe', name: 'Yagnavalkya Bhavanam Annexe', latitude: 10.90285, longitude: 76.90503, category: 'Boys Hostel', isPoi: true));
    graph.addNode(const CampusNode(id: 'ettimadai_station', name: 'Ettimadai Railway Station', latitude: 10.89848, longitude: 76.89597, category: 'Transit', isPoi: true));
    graph.addNode(const CampusNode(id: 'west_sports_ground', name: 'West Sports Ground', latitude: 10.90129, longitude: 76.89432, category: 'Sports Facility', isPoi: true));

    // AUTHENTIC ROAD NETWORK EDGES & PEDESTRIAN PATHWAYS (100% building collision-free)

    // 1. Entrance & Banking
    graph.addEdge('main_gate', 'bank_road_fork', 'Main Gate Entrance Drive');
    graph.addEdge('bank_road_fork', 'bank_junc', 'Bank Arcade Approach');
    graph.addEdge('bank_junc', 'bank_curve', 'Arcade Walkway');
    graph.addEdge('bank_junc', 'dhanalakshmi_bank', 'Bank Portico Steps');
    graph.addEdge('bank_junc', 'dhanlaxmi_bank', 'Bank Portico Steps');
    graph.addEdge('bank_junc', 'dhanalakshmi_atm_1', 'Bank ATM Steps');
    graph.addEdge('bank_junc', 'icici_atm', 'ICICI ATM Steps');

    // 2. South Boulevard & AB1 Walkway
    graph.addEdge('main_gate', 'south_gate_fork', 'Main Gate East Drive');
    graph.addEdge('south_gate_fork', 'south_spine_1', 'Amrita Main Avenue');
    graph.addEdge('south_spine_1', 'south_spine_2', 'Amrita Main Avenue Boulevard');
    graph.addEdge('south_spine_2', 'saraswati_circle', 'Amrita Main Avenue Boulevard');
    graph.addEdge('saraswati_circle', 'childrens_park', 'Childrens Park Walkway');
    graph.addEdge('saraswati_circle', 'ab1_south_entrance', 'AB1 Engineering Walkway');
    graph.addEdge('ab1_south_entrance', 'ab1_west_walk_1', 'AB1 Covered West Walkway');
    graph.addEdge('ab1_west_walk_1', 'ab1_west_walk_2', 'AB1 Covered West Walkway');
    graph.addEdge('ab1_west_walk_2', 'ab1_north_junc', 'AB1 North Quad Walkway');
    graph.addEdge('ab1_south_entrance', 'ab1_portico', 'AB1 Entrance Portico');
    graph.addEdge('ab1_south_entrance', 'ab1', 'AB1 Entrance Portico');
    graph.addEdge('ab1_south_entrance', 'dhanalakshmi_atm_2', 'AB1 ATM Steps');

    // 3. Maitheyi / Mythreyi Bhavanam access
    graph.addEdge('south_spine_1', 'maitheyi_lane_south', 'Maitheyi Access Way');
    graph.addEdge('maitheyi_lane_south', 'maitheyi_bhavanam', 'Maitheyi Entrance Portico');
    graph.addEdge('maitheyi_lane_south', 'mythreyi_bhavanam', 'Mythreyi Entrance Portico');

    // 4. Canteen & East Hostels
    graph.addEdge('saraswati_circle', 'ab1_canteen_walk', 'Canteen Access Walkway');
    graph.addEdge('ab1_canteen_walk', 'canteen_promenade', 'Canteen Promenade Walkway');
    graph.addEdge('canteen_promenade', 'main_canteen', 'Main Canteen Courtyard');
    graph.addEdge('main_canteen', 'amriteshwari_hall', 'Amriteshwari Hall Walkway');
    graph.addEdge('saraswati_circle', 'savitri_road_junc', 'South Campus Drive');
    graph.addEdge('savitri_road_junc', 'savitri_bhavanam', 'Savitri Bhavanam Approach');
    graph.addEdge('amriteshwari_hall', 'east_hostel_junc', 'East Hostel Road');
    graph.addEdge('east_hostel_junc', 'nachiketas_bhavanam', 'Nachiketas Access Walk');
    graph.addEdge('east_hostel_junc', 'nachiketas_north_corner', 'East Hostel Lane');
    graph.addEdge('nachiketas_north_corner', 'yagnavalkya_junc', 'Hostel Quad Road');
    graph.addEdge('yagnavalkya_junc', 'yagnavalkya_bhavanam', 'Yagnavalkya Quad Walk');
    graph.addEdge('yagnavalkya_junc', 'kashyapa_bhavanam', 'Kashyapa Quad Walk');
    graph.addEdge('yagnavalkya_junc', 'vyasa_lane', 'Vyasa Approach Lane');
    graph.addEdge('vyasa_lane', 'vyasa_bhavanam', 'Vyasa Bhavanam Drive');

    // 5. Central Boulevard Spine
    graph.addEdge('bank_curve', 'central_spine_1', 'Central Boulevard South');
    graph.addEdge('central_spine_1', 'maitheyi_junc', 'Central Boulevard');
    graph.addEdge('maitheyi_junc', 'central_spine_2', 'Central Boulevard');
    graph.addEdge('central_spine_2', 'kitchen_junc', 'Central Dining Avenue');
    graph.addEdge('kitchen_junc', 'temple_circle', 'Temple Garden Boulevard');
    graph.addEdge('temple_circle', 'temple', 'Temple Sacred Way');
    graph.addEdge('temple_circle', 'millet_cafe_junc', 'Temple North Walkway');
    graph.addEdge('millet_cafe_junc', 'millet_cafe', 'Millet Cafe Promenade');
    graph.addEdge('millet_cafe_junc', 'central_circle', 'Central Academic Boulevard');
    graph.addEdge('central_circle', 'central_sports_connector', 'Academic Sports Connector');
    graph.addEdge('central_sports_connector', 'playground_approach', 'Sports Ground Approach');

    // 6. Clinic & Gym Connector
    graph.addEdge('kitchen_junc', 'clinic_lane', 'Central Clinic Paved Way');
    graph.addEdge('clinic_lane', 'central_kitchen', 'Central Kitchen Counter');
    graph.addEdge('clinic_lane', 'general_store', 'General Store Front');
    graph.addEdge('clinic_lane', 'clinic_cross', 'Clinic Crossroad');
    graph.addEdge('clinic_cross', 'clinic', 'Clinic Patient Drive');
    graph.addEdge('clinic_cross', 'gym_junc', 'Clinic-Gym Walkway');
    graph.addEdge('gym_junc', 'gym_boys', 'Boys Gym Portico');
    graph.addEdge('ab1_north_junc', 'gym_junc', 'AB1 North Quad to Gym');

    // 7. Playground Approach
    graph.addEdge('playground_approach', 'playground', 'Main Ground Pavilion Gate');
    graph.addEdge('playground_approach', 'main_ground', 'Main Ground Pavilion Gate');

    // 8. West Hostels Ring
    graph.addEdge('kitchen_junc', 'guest_house_junc', 'Guest House VIP Drive');
    graph.addEdge('guest_house_junc', 'guest_house', 'Guest House VIP Approach');
    graph.addEdge('guest_house_junc', 'west_ring_1', 'West Ring Road South');
    graph.addEdge('west_ring_1', 'west_ring_2', 'West Ring Road');
    graph.addEdge('west_ring_2', 'vasishta_junc', 'West Hostels Ring Road');
    graph.addEdge('vasishta_junc', 'vasishta_bhavanam', 'Vasishta Quad Walk');
    graph.addEdge('vasishta_junc', 'west_gym_bend', 'Arogya Gym Approach');
    graph.addEdge('west_gym_bend', 'arogya_gym', 'Arogya Sadhanam Pathway');
    graph.addEdge('vasishta_junc', 'agasthya_junc', 'West Hostels Avenue');
    graph.addEdge('agasthya_junc', 'agasthya_bhavanam', 'Agasthya Hostel Path');
    graph.addEdge('agasthya_junc', 'agastya_mess_junc', 'West Mess Dining Walk');
    graph.addEdge('agastya_mess_junc', 'agastya_mess', 'West Mess Entrance');
    graph.addEdge('west_ring_2', 'gauthama_junc', 'Hostel Quad Walk');
    graph.addEdge('gauthama_junc', 'gauthama_bhavanam', 'Gauthama Bhavanam Gate');
    graph.addEdge('ab2_portico', 'natarajar_statue', 'Natarajar Garden Walk');

    // 9. Central Academic Quad & Library
    graph.addEdge('central_circle', 'north_gargi_bend', 'North Gargi Avenue');
    graph.addEdge('north_gargi_bend', 'library_avenue_bend', 'Library Avenue');
    graph.addEdge('north_gargi_bend', 'gargi_bhavanam', 'Gargi Bhavanam Gate');
    graph.addEdge('library_avenue_bend', 'arjuna_plaza', 'Library Garden Avenue');
    graph.addEdge('arjuna_plaza', 'arjuna_statue', 'Arjuna Bronze Chariot Plaza');
    graph.addEdge('arjuna_plaza', 'library_garden', 'Library Garden Walkway');
    graph.addEdge('library_garden', 'library_steps', 'Central Library Entrance Terrace');
    graph.addEdge('library_steps', 'central_library', 'Central Library Portico');
    graph.addEdge('library_steps', 'sbi_atm', 'Library ATM Kiosk');
    graph.addEdge('library_garden', 'ab2_portico', 'Library Garden Plaza');
    graph.addEdge('ab2_portico', 'ab2', 'AB2 Main Portico Steps');

    // 10. Library East Walkway to North Campus
    graph.addEdge('arjuna_plaza', 'library_east_walk_1', 'Library East Promenade');
    graph.addEdge('library_east_walk_1', 'library_east_walk_2', 'Library East Promenade');
    graph.addEdge('library_east_walk_2', 'north_academic_cross', 'North Academic Cross');
    graph.addEdge('library_east_walk_2', 'east_pool_south', 'East Campus Avenue');

    // 11. West Academic Walkway around AB2
    graph.addEdge('ab2_portico', 'west_ab2_avenue_south', 'AB2 West Covered Walkway');
    graph.addEdge('west_ab2_avenue_south', 'west_ab2_avenue_mid', 'West Academic Avenue');
    graph.addEdge('west_ab2_avenue_mid', 'west_ab2_avenue_north', 'West Academic Avenue North');
    graph.addEdge('west_ab2_avenue_north', 'north_academic_cross', 'North Academic Crosswalk');

    // 12. North Academic & Law School
    graph.addEdge('north_academic_cross', 'cyber_lab', 'Cyber Lab Portico');
    graph.addEdge('north_academic_cross', 'ab4', 'Academic Block 4 Steps');
    graph.addEdge('west_ab2_avenue_north', 'it_canteen', 'IT Canteen Deck Walk');
    graph.addEdge('west_ab2_avenue_north', 'ab3_approach', 'Law School Promenade');
    graph.addEdge('ab3_approach', 'ab3_junc', 'AB3 Approach Drive');
    graph.addEdge('ab3_junc', 'ab3', 'AB3 Main Portico Steps');

    // 13. Industrial Workshops
    graph.addEdge('west_ab2_avenue_mid', 'workshop_lane', 'Industrial Labs Lane');
    graph.addEdge('workshop_lane', 'workshop_junc', 'Mechanical Workshop Drive');
    graph.addEdge('workshop_junc', 'fab_workshop', 'Fabrication Workshop Entrance');
    graph.addEdge('workshop_junc', 'mechanical_labs', 'Mechanical Labs Drive');
    graph.addEdge('workshop_junc', 'aartc_lane', 'Automotive Research Centre Lane');
    graph.addEdge('aartc_lane', 'aartc', 'Automotive Research Centre');
    graph.addEdge('aartc_lane', 'electrical_labs', 'Electrical Labs Approach');

    // 14. Management & Auditorium Zone
    graph.addEdge('library_avenue_bend', 'mgmt_fork', 'Management Avenue Fork');
    graph.addEdge('mgmt_fork', 'mgmt_avenue', 'Management Avenue');
    graph.addEdge('mgmt_avenue', 'mba_block', 'Business School Archway');
    graph.addEdge('mba_block', 'auditorium_junc', 'MBA Plaza Walkway');
    graph.addEdge('auditorium_junc', 'mba_canteen', 'MBA Food Court Walk');
    graph.addEdge('auditorium_junc', 'auditorium', 'Auditorium Promenade');
    graph.addEdge('auditorium_junc', 'sudhamani_hall', 'Sudhamani Hall Promenade');
    graph.addEdge('mgmt_avenue', 'cir_junc', 'Corporate Drive');
    graph.addEdge('cir_junc', 'cir_block', 'CIR Placements Entrance');

    // 15. Authentic Roadways Around Swimming Pool (Zero Water Overlap)
    // A. West Roadway bypassing the pool completely
    graph.addEdge('ab3_junc', 'pool_south_west_junc', 'Law School West Drive');
    graph.addEdge('north_academic_cross', 'pool_south_west_junc', 'North Academic Pool Road');
    graph.addEdge('pool_south_west_junc', 'pool_west_avenue', 'West Pool Promenade');
    graph.addEdge('pool_west_avenue', 'pool_north_west_junc', 'West Pool Promenade North');
    graph.addEdge('pool_north_west_junc', 'north_residence_cross', 'North Residence Avenue');
    graph.addEdge('north_residence_cross', 'aditi_bhavanam', 'Aditi Bhavanam Portico Drive');
    graph.addEdge('north_residence_cross', 'adithi_bhavanam', 'Aditi Bhavanam Portico Drive');

    // B. East Roadway bypassing the pool completely
    graph.addEdge('east_pool_south', 'east_pool_junc', 'East Campus Avenue');
    graph.addEdge('east_pool_junc', 'east_pool_north', 'East Campus Boulevard North');
    graph.addEdge('east_pool_north', 'aditi_bhavanam', 'North Residence East Approach');

    // C. Paved Concourse to Swimming Pool Entrance (South Gate & Pavilion - Solid Ground)
    graph.addEdge('pool_south_west_junc', 'pool_deck_entrance', 'Aquatic Center South Walkway');
    graph.addEdge('east_pool_junc', 'pool_entrance_approach', 'Aquatic Center Drive');
    graph.addEdge('pool_entrance_approach', 'pool_deck_entrance', 'Aquatic Center Concourse');
    graph.addEdge('pool_deck_entrance', 'swimming_pool', 'Aquatic Center Entrance Pavilion');

    // 16. Additional Real Landmarks & Extended Connections
    graph.addEdge('north_gargi_bend', 'admin_block', 'Admin Block Walkway');
    graph.addEdge('cir_junc', 'agri_farm', 'Agriculture Farm Road');
    graph.addEdge('vyasa_lane', 'yagnavalkya_annexe', 'Annexe Approach Walk');
    graph.addEdge('west_gym_bend', 'ettimadai_station', 'Ettimadai Station Road');
    graph.addEdge('west_gym_bend', 'west_sports_ground', 'West Sports Ground Pathway');

    return graph;
  }

}
