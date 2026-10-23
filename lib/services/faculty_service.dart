import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'mongodb_service.dart';
import 'auth_service.dart';

class FacultyDashboardStats {
  final int pendingClaimsCount;
  final int activeClubsCount;
  final int upcomingEventsCount;
  final int unresolvedItemsCount;

  FacultyDashboardStats({
    this.pendingClaimsCount = 0,
    this.activeClubsCount = 0,
    this.upcomingEventsCount = 0,
    this.unresolvedItemsCount = 0,
  });

  factory FacultyDashboardStats.fromJson(Map<String, dynamic> json) {
    return FacultyDashboardStats(
      pendingClaimsCount: json['pendingClaimsCount'] is int
          ? json['pendingClaimsCount']
          : (int.tryParse(json['pendingClaimsCount']?.toString() ?? '0') ?? 0),
      activeClubsCount: json['activeClubsCount'] is int
          ? json['activeClubsCount']
          : (int.tryParse(json['activeClubsCount']?.toString() ?? '0') ?? 0),
      upcomingEventsCount: json['upcomingEventsCount'] is int
          ? json['upcomingEventsCount']
          : (int.tryParse(json['upcomingEventsCount']?.toString() ?? '0') ?? 0),
      unresolvedItemsCount: json['unresolvedItemsCount'] is int
          ? json['unresolvedItemsCount']
          : (int.tryParse(json['unresolvedItemsCount']?.toString() ?? '0') ?? 0),
    );
  }
}

class FacultyPendingRequest {
  final String id;
  final String? itemId;
  final String itemTitle;
  final String itemCategory;
  final String itemLocation;
  final String? itemImageUrl;
  final String claimantName;
  final String claimantId;
  final String message;
  final String? proofImageUrl;
  final DateTime? submittedAt;
  final String status;

  FacultyPendingRequest({
    required this.id,
    this.itemId,
    required this.itemTitle,
    required this.itemCategory,
    required this.itemLocation,
    this.itemImageUrl,
    required this.claimantName,
    required this.claimantId,
    required this.message,
    this.proofImageUrl,
    this.submittedAt,
    required this.status,
  });

  factory FacultyPendingRequest.fromJson(Map<String, dynamic> json) {
    return FacultyPendingRequest(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      itemId: json['itemId']?.toString(),
      itemTitle: (json['itemTitle'] ?? 'Unknown Item').toString(),
      itemCategory: (json['itemCategory'] ?? 'General').toString(),
      itemLocation: (json['itemLocation'] ?? 'Campus').toString(),
      itemImageUrl: json['itemImageUrl']?.toString(),
      claimantName: (json['claimantName'] ?? 'Anonymous Student').toString(),
      claimantId: (json['claimantId'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      proofImageUrl: json['proofImageUrl']?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      status: (json['status'] ?? 'pending').toString(),
    );
  }
}

class FacultyService {
  static final FacultyService _instance = FacultyService._internal();
  factory FacultyService() => _instance;
  static FacultyService get instance => _instance;
  FacultyService._internal();

  String get _baseUrl => '${MongoDbService.instance.backendUrl}/api/faculty';

  Map<String, String> _headers([String? token]) {
    final effectiveToken = token ?? AuthService.effectiveToken;
    return {
      'Content-Type': 'application/json',
      if (effectiveToken.isNotEmpty) 'Authorization': 'Bearer $effectiveToken',
    };
  }

  /// Get dashboard statistics for faculty
  Future<FacultyDashboardStats?> getDashboardStats() async {
    try {
      final uri = Uri.parse('$_baseUrl/dashboard-stats');
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['stats'] != null) {
          return FacultyDashboardStats.fromJson(data['stats'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('[FacultyService getDashboardStats Error]: $e');
    }
    return null;
  }

  /// Get pending requests for verification/approval
  Future<List<FacultyPendingRequest>> getPendingRequests() async {
    try {
      final uri = Uri.parse('$_baseUrl/pending-requests');
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['requests'] is List) {
          return (data['requests'] as List)
              .map((r) => FacultyPendingRequest.fromJson(r as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[FacultyService getPendingRequests Error]: $e');
    }
    return [];
  }

  /// Approve or reject a claim
  Future<bool> updateClaimStatus(String claimId, String status) async {
    try {
      final uri = Uri.parse('$_baseUrl/claims/$claimId');
      final response = await http.patch(
        uri,
        headers: _headers(),
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[FacultyService updateClaimStatus Error]: $e');
      return false;
    }
  }
}
