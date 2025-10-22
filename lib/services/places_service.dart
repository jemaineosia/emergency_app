import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../core/constants/google_config.dart';
import '../models/emergency_contact.dart';

/// Service for interacting with Google Places API
class PlacesService {
  static PlacesService? _instance;
  final String _apiKey = GoogleConfig.placesApiKey;

  PlacesService._();

  /// Singleton instance
  static PlacesService get instance {
    _instance ??= PlacesService._();
    return _instance!;
  }

  // ==================== Find Emergency Services ====================

  /// Find nearest police station
  Future<EmergencyPlaceResult?> findNearestPolice({
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    return await _findNearestPlace(
      latitude: latitude,
      longitude: longitude,
      type: 'police',
      keyword: 'police station',
      radiusMeters: radiusMeters,
    );
  }

  /// Find nearest hospital
  Future<EmergencyPlaceResult?> findNearestHospital({
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    return await _findNearestPlace(
      latitude: latitude,
      longitude: longitude,
      type: 'hospital',
      keyword: 'hospital emergency',
      radiusMeters: radiusMeters,
    );
  }

  /// Find nearest fire station
  Future<EmergencyPlaceResult?> findNearestFireStation({
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    return await _findNearestPlace(
      latitude: latitude,
      longitude: longitude,
      type: 'fire_station',
      keyword: 'fire station',
      radiusMeters: radiusMeters,
    );
  }

  /// Find all emergency services at once
  Future<Map<ContactType, EmergencyPlaceResult?>> findAllEmergencyServices({
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    final results = await Future.wait([
      findNearestPolice(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      ),
      findNearestHospital(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      ),
      findNearestFireStation(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      ),
    ]);

    return {
      ContactType.police: results[0],
      ContactType.hospital: results[1],
      ContactType.fireStation: results[2],
    };
  }

  // ==================== Core Search Logic ====================

  /// Find nearest place by type
  Future<EmergencyPlaceResult?> _findNearestPlace({
    required double latitude,
    required double longitude,
    required String type,
    required String keyword,
    double radiusMeters = 10000,
  }) async {
    try {
      // Build the URL
      final url =
          Uri.parse(
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
          ).replace(
            queryParameters: {
              'location': '$latitude,$longitude',
              'radius': radiusMeters.toString(),
              'type': type,
              'keyword': keyword,
              'key': _apiKey,
              'rankby': 'distance',
            },
          );

      // Make the request
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('Places API error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = json.decode(response.body);

      // Check for API errors
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        print('Places API status: ${data['status']}');
        if (data['error_message'] != null) {
          print('Error message: ${data['error_message']}');
        }
        return null;
      }

      // Check if any results
      if (data['results'] == null || (data['results'] as List).isEmpty) {
        print('No results found for $type near ($latitude, $longitude)');
        return null;
      }

      // Get the first (nearest) result
      final place = data['results'][0];

      // Get detailed information including phone number
      final placeId = place['place_id'] as String;
      final details = await _getPlaceDetails(placeId);

      return EmergencyPlaceResult(
        placeId: placeId,
        name: place['name'] as String,
        address: place['vicinity'] as String? ?? '',
        latitude: place['geometry']['location']['lat'] as double,
        longitude: place['geometry']['location']['lng'] as double,
        phoneNumber: details?['formatted_phone_number'] as String?,
        internationalPhoneNumber:
            details?['international_phone_number'] as String?,
        rating: place['rating'] as double?,
        isOpen: place['opening_hours']?['open_now'] as bool?,
        types: (place['types'] as List?)?.cast<String>() ?? [],
      );
    } catch (e) {
      print('Error finding nearest $type: $e');
      return null;
    }
  }

  /// Get detailed place information
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    try {
      final url =
          Uri.parse(
            'https://maps.googleapis.com/maps/api/place/details/json',
          ).replace(
            queryParameters: {
              'place_id': placeId,
              'fields':
                  'formatted_phone_number,international_phone_number,website,opening_hours',
              'key': _apiKey,
            },
          );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('Place Details API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        print('Place Details API status: ${data['status']}');
        return null;
      }

      return data['result'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  // ==================== Search Alternatives ====================

  /// Search for places by text query
  Future<List<EmergencyPlaceResult>> searchByText({
    required String query,
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    try {
      final url =
          Uri.parse(
            'https://maps.googleapis.com/maps/api/place/textsearch/json',
          ).replace(
            queryParameters: {
              'query': query,
              'location': '$latitude,$longitude',
              'radius': radiusMeters.toString(),
              'key': _apiKey,
            },
          );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('Text Search API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        print('Text Search API status: ${data['status']}');
        return [];
      }

      if (data['results'] == null) {
        return [];
      }

      final results = <EmergencyPlaceResult>[];
      for (final place in data['results']) {
        final placeId = place['place_id'] as String;
        final details = await _getPlaceDetails(placeId);

        results.add(
          EmergencyPlaceResult(
            placeId: placeId,
            name: place['name'] as String,
            address: place['formatted_address'] as String? ?? '',
            latitude: place['geometry']['location']['lat'] as double,
            longitude: place['geometry']['location']['lng'] as double,
            phoneNumber: details?['formatted_phone_number'] as String?,
            internationalPhoneNumber:
                details?['international_phone_number'] as String?,
            rating: place['rating'] as double?,
            isOpen: place['opening_hours']?['open_now'] as bool?,
            types: (place['types'] as List?)?.cast<String>() ?? [],
          ),
        );
      }

      return results;
    } catch (e) {
      print('Error searching by text: $e');
      return [];
    }
  }

  // ==================== Utility Methods ====================

  /// Validate API key is configured
  bool isApiKeyConfigured() {
    return _apiKey.isNotEmpty && _apiKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE';
  }

  /// Calculate distance from user's location
  double calculateDistance(
    double userLat,
    double userLon,
    double placeLat,
    double placeLon,
  ) {
    // Using Haversine formula
    const R = 6371000; // Earth's radius in meters
    final lat1 = userLat * (pi / 180);
    final lat2 = placeLat * (pi / 180);
    final dLat = (placeLat - userLat) * (pi / 180);
    final dLon = (placeLon - userLon) * (pi / 180);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));

    return R * c;
  }
}

/// Result from Google Places API
class EmergencyPlaceResult {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? internationalPhoneNumber;
  final double? rating;
  final bool? isOpen;
  final List<String> types;

  EmergencyPlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.internationalPhoneNumber,
    this.rating,
    this.isOpen,
    this.types = const [],
  });

  /// Get the best phone number available
  String? get bestPhoneNumber => phoneNumber ?? internationalPhoneNumber;

  /// Check if phone number is available
  bool get hasPhoneNumber =>
      phoneNumber != null || internationalPhoneNumber != null;

  @override
  String toString() {
    return 'EmergencyPlaceResult(name: $name, address: $address, phone: $bestPhoneNumber)';
  }

  /// Convert to EmergencyContact model
  EmergencyContact toEmergencyContact({
    required String userId,
    required ContactType contactType,
  }) {
    return EmergencyContact(
      id: '', // Will be generated by Supabase
      userId: userId,
      contactType: contactType,
      name: contactType.displayName,
      phoneNumber: bestPhoneNumber ?? '',
      address: address,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      isAiGenerated: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'internationalPhoneNumber': internationalPhoneNumber,
      'rating': rating,
      'isOpen': isOpen,
      'types': types,
    };
  }

  factory EmergencyPlaceResult.fromJson(Map<String, dynamic> json) {
    return EmergencyPlaceResult(
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      phoneNumber: json['phoneNumber'] as String?,
      internationalPhoneNumber: json['internationalPhoneNumber'] as String?,
      rating: json['rating'] as double?,
      isOpen: json['isOpen'] as bool?,
      types: (json['types'] as List?)?.cast<String>() ?? [],
    );
  }
}
