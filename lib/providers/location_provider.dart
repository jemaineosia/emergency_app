import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/geocoding_service.dart';
import '../services/location_service.dart';

/// Provider for managing location state
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService.instance;
  final GeocodingService _geocodingService = GeocodingService.instance;

  Position? _currentPosition;
  AddressResult? _currentAddress;
  LocationPermissionResult? _permissionStatus;
  bool _isLoadingPosition = false;
  bool _isLoadingAddress = false;
  String? _error;
  StreamSubscription<Position>? _positionSubscription;

  // ==================== Getters ====================

  Position? get currentPosition => _currentPosition;
  AddressResult? get currentAddress => _currentAddress;
  LocationPermissionResult? get permissionStatus => _permissionStatus;
  bool get isLoadingPosition => _isLoadingPosition;
  bool get isLoadingAddress => _isLoadingAddress;
  bool get isLoading => _isLoadingPosition || _isLoadingAddress;
  String? get error => _error;

  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;
  bool get hasPosition => _currentPosition != null;
  bool get hasPermission =>
      _permissionStatus == LocationPermissionResult.granted;

  // ==================== Initialization ====================

  /// Initialize location provider
  Future<void> initialize() async {
    await checkPermission();
    if (hasPermission) {
      await getCurrentPosition();
    }
  }

  // ==================== Permission Management ====================

  /// Check current permission status
  Future<void> checkPermission() async {
    try {
      final isGranted = await _locationService.isLocationPermissionGranted();
      if (isGranted) {
        _permissionStatus = LocationPermissionResult.granted;
      } else {
        _permissionStatus = LocationPermissionResult.denied;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error checking permission: $e';
      notifyListeners();
    }
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    try {
      _error = null;
      notifyListeners();

      final result = await _locationService.requestLocationPermission();
      _permissionStatus = result;
      notifyListeners();

      if (result == LocationPermissionResult.granted) {
        // Automatically get position after permission is granted
        await getCurrentPosition();
        return true;
      } else {
        _error = result.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error requesting permission: $e';
      notifyListeners();
      return false;
    }
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  // ==================== Location Operations ====================

  /// Get current position
  Future<bool> getCurrentPosition({bool forceRefresh = false}) async {
    if (!hasPermission) {
      _error = 'Location permission not granted';
      notifyListeners();
      return false;
    }

    try {
      _isLoadingPosition = true;
      _error = null;
      notifyListeners();

      final position = await _locationService.getCurrentPosition(
        forceRefresh: forceRefresh,
      );

      if (position != null) {
        _currentPosition = position;
        _isLoadingPosition = false;
        notifyListeners();

        // Automatically get address for the new position
        await getAddressForCurrentPosition();
        return true;
      } else {
        _error = 'Failed to get current position';
        _isLoadingPosition = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error getting position: $e';
      _isLoadingPosition = false;
      notifyListeners();
      return false;
    }
  }

  /// Get last known position (faster)
  Future<bool> getLastKnownPosition() async {
    try {
      _isLoadingPosition = true;
      _error = null;
      notifyListeners();

      final position = await _locationService.getLastKnownPosition();

      if (position != null) {
        _currentPosition = position;
        _isLoadingPosition = false;
        notifyListeners();

        // Get address for the position
        await getAddressForCurrentPosition();
        return true;
      } else {
        _error = 'No last known position available';
        _isLoadingPosition = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error getting last known position: $e';
      _isLoadingPosition = false;
      notifyListeners();
      return false;
    }
  }

  /// Start listening to position updates
  void startPositionUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 100,
    Function(Position)? onUpdate,
  }) {
    // Cancel existing subscription
    stopPositionUpdates();

    _positionSubscription = _locationService
        .getPositionStream(accuracy: accuracy, distanceFilter: distanceFilter)
        .listen(
          (position) {
            _currentPosition = position;
            notifyListeners();

            // Get address for new position
            getAddressForCurrentPosition();

            // Call custom callback
            onUpdate?.call(position);
          },
          onError: (error) {
            _error = 'Position stream error: $error';
            notifyListeners();
          },
        );
  }

  /// Stop listening to position updates
  void stopPositionUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // ==================== Address Operations ====================

  /// Get address for current position
  Future<void> getAddressForCurrentPosition() async {
    if (_currentPosition == null) return;

    try {
      _isLoadingAddress = true;
      notifyListeners();

      final address = await _geocodingService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      _currentAddress = address;
      _isLoadingAddress = false;
      notifyListeners();
    } catch (e) {
      print('Error getting address: $e');
      _isLoadingAddress = false;
      notifyListeners();
    }
  }

  /// Get address for specific coordinates
  Future<AddressResult?> getAddressForCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      return await _geocodingService.getAddressFromCoordinates(
        latitude,
        longitude,
      );
    } catch (e) {
      print('Error getting address for coordinates: $e');
      return null;
    }
  }

  // ==================== Distance Calculations ====================

  /// Calculate distance from current position
  double? calculateDistanceFromCurrent(double targetLat, double targetLon) {
    return _locationService.calculateDistanceFromCurrent(targetLat, targetLon);
  }

  /// Calculate distance between two points
  double calculateDistance(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return _locationService.calculateDistance(
      startLat,
      startLon,
      endLat,
      endLon,
    );
  }

  /// Format distance for display
  String formatDistance(double meters) {
    return _locationService.formatDistance(meters);
  }

  // ==================== Utility Methods ====================

  /// Clear all cached data
  void clearCache() {
    _currentPosition = null;
    _currentAddress = null;
    _error = null;
    _locationService.clearCache();
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPositionUpdates();
    super.dispose();
  }
}
