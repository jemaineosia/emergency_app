import 'package:geocoding/geocoding.dart';

/// Service for converting between coordinates and addresses
class GeocodingService {
  static GeocodingService? _instance;

  GeocodingService._();

  /// Singleton instance
  static GeocodingService get instance {
    _instance ??= GeocodingService._();
    return _instance!;
  }

  // ==================== Address from Coordinates ====================

  /// Get address from coordinates (reverse geocoding)
  Future<AddressResult?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return null;
      }

      final placemark = placemarks.first;
      return AddressResult.fromPlacemark(placemark, latitude, longitude);
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Get multiple addresses from coordinates
  Future<List<AddressResult>> getAddressesFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      return placemarks
          .map((p) => AddressResult.fromPlacemark(p, latitude, longitude))
          .toList();
    } catch (e) {
      print('Error getting addresses from coordinates: $e');
      return [];
    }
  }

  // ==================== Coordinates from Address ====================

  /// Get coordinates from address (forward geocoding)
  Future<LocationResult?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        return null;
      }

      final location = locations.first;
      return LocationResult.fromLocation(location);
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Get multiple possible coordinates from address
  Future<List<LocationResult>> getMultipleCoordinatesFromAddress(
    String address,
  ) async {
    try {
      final locations = await locationFromAddress(address);

      return locations.map((l) => LocationResult.fromLocation(l)).toList();
    } catch (e) {
      print('Error getting multiple coordinates from address: $e');
      return [];
    }
  }

  // ==================== Utility Methods ====================

  /// Format full address from placemark
  static String formatFullAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.name != null && placemark.name!.isNotEmpty) {
      parts.add(placemark.name!);
    }
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      parts.add(placemark.postalCode!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }

    return parts.join(', ');
  }

  /// Format short address (street and locality only)
  static String formatShortAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }

    return parts.join(', ');
  }

  /// Format city, state, country
  static String formatCityState(Placemark placemark) {
    final parts = <String>[];

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }

    return parts.join(', ');
  }
}

/// Result of address lookup
class AddressResult {
  final double latitude;
  final double longitude;
  final String fullAddress;
  final String shortAddress;
  final String? street;
  final String? locality;
  final String? subLocality;
  final String? administrativeArea;
  final String? subAdministrativeArea;
  final String? postalCode;
  final String? country;
  final String? isoCountryCode;

  AddressResult({
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    required this.shortAddress,
    this.street,
    this.locality,
    this.subLocality,
    this.administrativeArea,
    this.subAdministrativeArea,
    this.postalCode,
    this.country,
    this.isoCountryCode,
  });

  factory AddressResult.fromPlacemark(
    Placemark placemark,
    double latitude,
    double longitude,
  ) {
    return AddressResult(
      latitude: latitude,
      longitude: longitude,
      fullAddress: GeocodingService.formatFullAddress(placemark),
      shortAddress: GeocodingService.formatShortAddress(placemark),
      street: placemark.street,
      locality: placemark.locality,
      subLocality: placemark.subLocality,
      administrativeArea: placemark.administrativeArea,
      subAdministrativeArea: placemark.subAdministrativeArea,
      postalCode: placemark.postalCode,
      country: placemark.country,
      isoCountryCode: placemark.isoCountryCode,
    );
  }

  @override
  String toString() => fullAddress;
}

/// Result of location lookup
class LocationResult {
  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });

  factory LocationResult.fromLocation(Location location) {
    return LocationResult(
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: location.timestamp,
    );
  }

  @override
  String toString() =>
      'LocationResult(lat: $latitude, lon: $longitude, time: $timestamp)';
}
