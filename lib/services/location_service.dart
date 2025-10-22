import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission;

/// Service for handling location operations
class LocationService {
  static LocationService? _instance;
  Position? _currentPosition;

  LocationService._();

  /// Singleton instance
  static LocationService get instance {
    _instance ??= LocationService._();
    return _instance!;
  }

  /// Get current cached position
  Position? get currentPosition => _currentPosition;

  /// Get current latitude
  double? get latitude => _currentPosition?.latitude;

  /// Get current longitude
  double? get longitude => _currentPosition?.longitude;

  // ==================== Permission Handling ====================

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    final status = await permission.Permission.location.status;
    return status.isGranted;
  }

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermissionResult> requestLocationPermission() async {
    // Check if location service is enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionResult.serviceDisabled;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return LocationPermissionResult.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedForever;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return LocationPermissionResult.granted;
    }

    return LocationPermissionResult.denied;
  }

  /// Open app settings for permission management
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // ==================== Location Operations ====================

  /// Get current position with caching
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    // Return cached position if available and not forcing refresh
    if (!forceRefresh && _currentPosition != null) {
      // Check if cached position is recent (within 5 minutes)
      final now = DateTime.now();
      final positionTime = _currentPosition!.timestamp;
      final difference = now.difference(positionTime);

      if (difference.inMinutes < 5) {
        return _currentPosition;
      }
    }

    // Check permissions
    final permissionResult = await requestLocationPermission();
    if (permissionResult != LocationPermissionResult.granted) {
      return null;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return _currentPosition;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get last known position (faster but might be outdated)
  Future<Position?> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        _currentPosition = position;
      }
      return position;
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  /// Stream of position updates
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 100, // meters
  }) {
    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Listen to position updates and update cache
  void startPositionUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 100,
    Function(Position)? onPositionUpdate,
  }) {
    getPositionStream(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    ).listen(
      (position) {
        _currentPosition = position;
        onPositionUpdate?.call(position);
      },
      onError: (error) {
        print('Position stream error: $error');
      },
    );
  }

  // ==================== Distance Calculations ====================

  /// Calculate distance between two coordinates in meters
  double calculateDistance(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }

  /// Calculate distance from current position to target coordinates
  double? calculateDistanceFromCurrent(double targetLat, double targetLon) {
    if (_currentPosition == null) return null;

    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLon,
    );
  }

  /// Calculate bearing between two coordinates
  double calculateBearing(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return Geolocator.bearingBetween(startLat, startLon, endLat, endLon);
  }

  /// Check if position has moved significantly since last check
  bool hasMovedSignificantly(
    Position oldPosition,
    Position newPosition, {
    double thresholdMeters = 100,
  }) {
    final distance = calculateDistance(
      oldPosition.latitude,
      oldPosition.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    return distance >= thresholdMeters;
  }

  // ==================== Utility Methods ====================

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Get coordinates as a readable string
  String formatCoordinates(double lat, double lon) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(6)}°$latDir, ${lon.abs().toStringAsFixed(6)}°$lonDir';
  }

  /// Clear cached position
  void clearCache() {
    _currentPosition = null;
  }
}

/// Result of location permission request
enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Extension for permission result messages
extension LocationPermissionResultExtension on LocationPermissionResult {
  String get message {
    switch (this) {
      case LocationPermissionResult.granted:
        return 'Location permission granted';
      case LocationPermissionResult.denied:
        return 'Location permission denied. Please grant access to use this feature.';
      case LocationPermissionResult.deniedForever:
        return 'Location permission permanently denied. Please enable it in app settings.';
      case LocationPermissionResult.serviceDisabled:
        return 'Location service is disabled. Please enable it in device settings.';
    }
  }

  bool get isGranted => this == LocationPermissionResult.granted;
  bool get isPermanentlyDenied =>
      this == LocationPermissionResult.deniedForever;
  bool get isServiceDisabled =>
      this == LocationPermissionResult.serviceDisabled;
}
