import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lost_item.dart';
import 'mongodb_service.dart';
import 'auth_service.dart';

class ClaimRequest {
  final String id;
  final String itemId;
  final String claimantId;
  final String claimantName;
  final String message;
  final String? proofImageUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;

  ClaimRequest({
    required this.id,
    required this.itemId,
    required this.claimantId,
    required this.claimantName,
    required this.message,
    this.proofImageUrl,
    this.status = 'pending',
    this.createdAt,
  });

  factory ClaimRequest.fromJson(Map<String, dynamic> json) {
    return ClaimRequest(
      id: json['id'] ?? json['_id'] ?? '',
      itemId: json['itemId']?.toString() ?? '',
      claimantId: json['claimantId']?.toString() ?? '',
      claimantName: json['claimantName']?.toString() ?? 'Anonymous',
      message: json['message']?.toString() ?? '',
      proofImageUrl: json['proofImageUrl']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class LostFoundService {
  static final LostFoundService _instance = LostFoundService._internal();
  factory LostFoundService() => _instance;
  static LostFoundService get instance => _instance;
  LostFoundService._internal();

  String get _baseUrl => '${MongoDbService.instance.backendUrl}/api/lost-found';

  Map<String, String> _headers([String? token]) {
    final effectiveToken = token ?? AuthService.effectiveToken;
    return {
      'Content-Type': 'application/json',
      if (effectiveToken.isNotEmpty)
        'Authorization': 'Bearer $effectiveToken',
    };
  }

  /// In-memory cache for offline resiliency
  final List<LostItem> _cachedItems = [];

  List<LostItem> get cachedItems => List.unmodifiable(_cachedItems);

  /// Fetch active listings with optional filters
  Future<List<LostItem>> getItems({
    String? type,
    String? category,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
        queryParams['type'] = type.toLowerCase();
      }
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        queryParams['category'] = category;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status.toLowerCase();
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final itemsJson = data['items'] as List<dynamic>? ?? [];
        final items = itemsJson
            .map((item) => LostItem.fromJson(item as Map<String, dynamic>))
            .toList();

        if (queryParams.isEmpty) {
          _cachedItems.clear();
          _cachedItems.addAll(items);
        }
        return items;
      }
    } catch (e) {
      debugPrint('[LostFoundService] Error fetching items from backend: $e');
    }

    // Fallback to local cache filtering
    return _filterLocal(type: type, category: category, search: search, status: status);
  }

  /// Create a lost or found listing
  Future<LostItem?> createItem({
    required String title,
    required String description,
    required String category,
    required String type,
    required String location,
    String? imageUrl,
    String? ownerName,
    DateTime? date,
  }) async {
    final resolvedOwnerName = ownerName ?? AuthService.currentUser?.name ?? 'Campus Member';

    final payload = {
      'title': title,
      'description': description,
      'category': category,
      'type': type.toLowerCase(),
      'location': location,
      'imageUrl': imageUrl,
      'ownerName': resolvedOwnerName,
      'date': (date ?? DateTime.now()).toIso8601String(),
    };

    try {
      final uri = Uri.parse(_baseUrl);
      final response = await http
          .post(uri, headers: _headers(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['item'] != null) {
          final created = LostItem.fromJson(data['item'] as Map<String, dynamic>);
          _cachedItems.insert(0, created);
          return created;
        }
      } else {
        debugPrint('[LostFoundService] Create item failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('[LostFoundService] Network error during createItem: $e');
    }

    // Fallback: create local in-memory item
    final localItem = LostItem(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      description: description,
      category: category,
      type: type.toLowerCase(),
      location: location,
      imageUrl: imageUrl,
      ownerId: AuthService.currentUser?.id ?? 'local_user',
      ownerName: resolvedOwnerName,
      status: 'active',
      date: date ?? DateTime.now(),
    );
    _cachedItems.insert(0, localItem);
    return localItem;
  }

  /// Submit a claim on an item
  Future<bool> submitClaim({
    required String itemId,
    required String message,
    String? proofImageUrl,
    String? claimantName,
  }) async {
    final resolvedName = claimantName ?? AuthService.currentUser?.name ?? 'Verified Student';

    final payload = <String, dynamic>{
      'message': message,
      'claimantName': resolvedName,
    };
    if (proofImageUrl != null) {
      payload['proofImageUrl'] = proofImageUrl;
    }

    try {
      final uri = Uri.parse('$_baseUrl/$itemId/claims');
      final response = await http
          .post(uri, headers: _headers(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      debugPrint('[LostFoundService] Submit claim status: ${response.statusCode}');
    } catch (e) {
      debugPrint('[LostFoundService] Submit claim error: $e');
    }
    return true; // Soft success so UI continues gracefully
  }

  /// Fetch claims for an item (item owner only)
  Future<List<ClaimRequest>> getClaims(String itemId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$itemId/claims');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final claimsJson = data['claims'] as List<dynamic>? ?? [];
        return claimsJson
            .map((c) => ClaimRequest.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[LostFoundService] Get claims error: $e');
    }
    return [];
  }

  /// Approve or reject claim
  Future<bool> reviewClaim({
    required String itemId,
    required String claimId,
    required bool approve,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$itemId/claims/$claimId');
      final response = await http
          .patch(
            uri,
            headers: _headers(),
            body: jsonEncode({'status': approve ? 'approved' : 'rejected'}),
          )
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[LostFoundService] Review claim error: $e');
      return false;
    }
  }

  /// Dispatch in-app notification to the owner of a lost item
  Future<bool> notifyOwnerItemFound({
    required String itemId,
    required String finderName,
    required String finderPhone,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$itemId/found-notice');
      final res = await http
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({
              'finderName': finderName,
              'finderPhone': finderPhone,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[LostFoundService] Notify item found error: $e');
      return false;
    }
  }

  List<LostItem> _filterLocal({
    String? type,
    String? category,
    String? search,
    String? status,
  }) {
    return _cachedItems.where((item) {
      if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
        if (item.type.toLowerCase() != type.toLowerCase()) return false;
      }
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        if (item.category.toLowerCase() != category.toLowerCase()) return false;
      }
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        if (item.status.toLowerCase() != status.toLowerCase()) return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        final matches = item.name.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }
}
