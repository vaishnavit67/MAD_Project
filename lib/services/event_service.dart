import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import 'mongodb_service.dart';
import 'auth_service.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  static EventService get instance => _instance;
  EventService._internal();

  String get _baseUrl => '${MongoDbService.instance.backendUrl}/api/events';

  Map<String, String> _headers([String? token]) {
    final effectiveToken = token ?? AuthService.effectiveToken;
    return {
      'Content-Type': 'application/json',
      if (effectiveToken.isNotEmpty) 'Authorization': 'Bearer $effectiveToken',
    };
  }

  /// Get list of events from MongoDB Atlas with optional filters
  Future<List<Event>> getEvents({String? category, String? time, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }
      if (time != null && time.isNotEmpty && time != 'All') {
        queryParams['time'] = time;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (AuthService.currentRole.isNotEmpty) {
        queryParams['role'] = AuthService.currentRole;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['events'] is List) {
          return (data['events'] as List)
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[EventService getEvents Error]: $e');
    }
    return [];
  }

  /// Create a new campus event (Faculty only)
  Future<Event?> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String timeString,
    String? endTimeString,
    required String location,
    String? organizer,
    String category = 'Other',
    int capacity = 100,
    int? availableSeats,
    String? imageUrl,
    bool featured = false,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final body = jsonEncode({
        'title': title.trim(),
        'description': description.trim(),
        'date': date.toIso8601String(),
        'timeString': timeString.trim(),
        'endTimeString': endTimeString?.trim(),
        'location': location.trim(),
        'organizer': organizer?.trim(),
        'category': category,
        'capacity': capacity,
        'availableSeats': availableSeats ?? capacity,
        'imageUrl': imageUrl,
        'featured': featured,
      });

      final response = await http.post(uri, headers: _headers(), body: body);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['event'] != null) {
          return Event.fromJson(data['event'] as Map<String, dynamic>);
        }
      } else {
        debugPrint('[Create Event Failed]: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[EventService createEvent Error]: $e');
    }
    return null;
  }

  /// Register for an event
  Future<bool> registerForEvent(String eventId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$eventId/register');
      final response = await http.post(uri, headers: _headers());
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[EventService registerForEvent Error]: $e');
      return false;
    }
  }

  /// Delete an event (Faculty only)
  Future<bool> deleteEvent(String eventId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$eventId');
      final response = await http.delete(uri, headers: _headers());
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[EventService deleteEvent Error]: $e');
      return false;
    }
  }
}
