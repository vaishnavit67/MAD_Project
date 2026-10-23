import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'mongodb_service.dart';
import 'auth_service.dart';

class ClubJoinResult {
  final bool success;
  final String message;
  final bool isLead;
  final bool isPending;
  final bool isJoined;

  ClubJoinResult({
    required this.success,
    required this.message,
    this.isLead = false,
    this.isPending = false,
    this.isJoined = false,
  });
}

class ClubModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String? imageUrl;
  final int memberCount;
  final List<String> members;
  final String createdBy;
  final String createdByName;
  final String leadEmail;
  final List<Map<String, dynamic>> joinRequests;
  final DateTime? createdAt;

  ClubModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.imageUrl,
    required this.memberCount,
    required this.members,
    required this.createdBy,
    required this.createdByName,
    this.leadEmail = '',
    this.joinRequests = const [],
    this.createdAt,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    List<String> parsedMembers = [];
    if (rawMembers is List) {
      parsedMembers = rawMembers.map((e) => e.toString()).toList();
    }

    final rawRequests = json['joinRequests'];
    List<Map<String, dynamic>> parsedRequests = [];
    if (rawRequests is List) {
      parsedRequests = rawRequests
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return ClubModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Untitled Club').toString(),
      category: (json['category'] ?? 'Technical').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      memberCount: json['membersCount'] is int
          ? json['membersCount']
          : (int.tryParse(json['membersCount']?.toString() ?? '1') ?? 1),
      members: parsedMembers,
      createdBy: (json['createdBy'] ?? '').toString(),
      createdByName: (json['createdByName'] ?? 'Faculty Coordinator').toString(),
      leadEmail: (json['leadEmail'] ?? '').toString(),
      joinRequests: parsedRequests,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'memberCount': memberCount,
      'members': members,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'leadEmail': leadEmail,
      'joinRequests': joinRequests,
    };
  }
}

class ClubService {
  static final ClubService _instance = ClubService._internal();
  factory ClubService() => _instance;
  static ClubService get instance => _instance;
  ClubService._internal();

  String get _baseUrl => '${MongoDbService.instance.backendUrl}/api/clubs';

  Map<String, String> _headers([String? token]) {
    final effectiveToken = token ?? AuthService.effectiveToken;
    return {
      'Content-Type': 'application/json',
      if (effectiveToken.isNotEmpty) 'Authorization': 'Bearer $effectiveToken',
    };
  }

  /// Get list of clubs with optional category & search filter
  Future<List<ClubModel>> getClubs({String? category, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['clubs'] is List) {
          return (data['clubs'] as List)
              .map((c) => ClubModel.fromJson(c as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ClubService getClubs Error]: $e');
    }
    return [];
  }

  /// Create a new club (Faculty only)
  Future<ClubModel?> createClub({
    required String name,
    required String category,
    required String description,
    String? imageUrl,
    int initialMembersCount = 1,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final body = jsonEncode({
        'name': name.trim(),
        'category': category,
        'description': description.trim(),
        'imageUrl': imageUrl,
        'initialMembersCount': initialMembersCount,
      });

      final response = await http.post(uri, headers: _headers(), body: body);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['club'] != null) {
          return ClubModel.fromJson(data['club'] as Map<String, dynamic>);
        }
      } else {
        debugPrint('[Create Club Failed]: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[ClubService createClub Error]: $e');
    }
    return null;
  }

  /// Request to join a club (Handles Student approval requirement and Teacher Lead detection)
  Future<ClubJoinResult> joinClubWithResult(String clubId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$clubId/join');
      final response = await http.post(uri, headers: _headers());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ClubJoinResult(
          success: true,
          message: data['message'] ?? 'Action completed successfully.',
          isLead: data['isLead'] == true,
          isPending: data['isPending'] == true,
          isJoined: data['isJoined'] == true,
        );
      } else {
        return ClubJoinResult(
          success: false,
          message: data['message'] ?? 'Failed to submit request.',
        );
      }
    } catch (e) {
      debugPrint('[ClubService joinClubWithResult Error]: $e');
      return ClubJoinResult(success: false, message: 'Network error submitting request: $e');
    }
  }

  /// Compatibility wrapper for boolean join
  Future<bool> joinClub(String clubId) async {
    final res = await joinClubWithResult(clubId);
    return res.success;
  }

  /// Get student join requests for a club (Faculty Lead only)
  Future<List<Map<String, dynamic>>> getClubRequests(String clubId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$clubId/requests');
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['requests'] is List) {
          return List<Map<String, dynamic>>.from(
            (data['requests'] as List).map((r) => Map<String, dynamic>.from(r as Map)),
          );
        }
      }
    } catch (e) {
      debugPrint('[ClubService getClubRequests Error]: $e');
    }
    return [];
  }

  /// Approve or reject a student join request (Faculty Lead only)
  Future<bool> reviewClubRequest(String clubId, String requestId, String status) async {
    try {
      final uri = Uri.parse('$_baseUrl/$clubId/requests/$requestId');
      final body = jsonEncode({'status': status.toLowerCase()});
      final response = await http.patch(uri, headers: _headers(), body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ClubService reviewClubRequest Error]: $e');
      return false;
    }
  }

  /// Delete a club (Faculty only)
  Future<bool> deleteClub(String clubId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$clubId');
      final response = await http.delete(uri, headers: _headers());
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ClubService deleteClub Error]: $e');
      return false;
    }
  }
}
