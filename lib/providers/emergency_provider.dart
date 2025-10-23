import 'package:flutter/foundation.dart';

import '../models/emergency_contact.dart';
import '../services/custom_contact_service.dart';
import '../services/places_service.dart';
import '../services/supabase_service.dart';

/// Provider for managing emergency services
class EmergencyProvider extends ChangeNotifier {
  final PlacesService _placesService = PlacesService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final CustomContactService _customContactService =
      CustomContactService.instance;

  Map<ContactType, EmergencyPlaceResult?> _emergencyServices = {};
  final Map<ContactType, EmergencyContact?> _savedContacts = {};
  bool _isSearching = false;
  bool _isSaving = false;
  String? _error;
  DateTime? _lastUpdate;

  // ==================== Getters ====================

  Map<ContactType, EmergencyPlaceResult?> get emergencyServices =>
      _emergencyServices;
  Map<ContactType, EmergencyContact?> get savedContacts => _savedContacts;
  bool get isSearching => _isSearching;
  bool get isSaving => _isSaving;
  bool get isLoading => _isSearching || _isSaving;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;

  EmergencyPlaceResult? get nearestPolice =>
      _emergencyServices[ContactType.police];
  EmergencyPlaceResult? get nearestHospital =>
      _emergencyServices[ContactType.hospital];
  EmergencyPlaceResult? get nearestFireStation =>
      _emergencyServices[ContactType.fireStation];

  EmergencyContact? get savedPolice => _savedContacts[ContactType.police];
  EmergencyContact? get savedHospital => _savedContacts[ContactType.hospital];
  EmergencyContact? get savedFireStation =>
      _savedContacts[ContactType.fireStation];

  bool get hasAllServices =>
      nearestPolice != null &&
      nearestHospital != null &&
      nearestFireStation != null;

  bool get hasAllPhoneNumbers =>
      nearestPolice?.hasPhoneNumber == true &&
      nearestHospital?.hasPhoneNumber == true &&
      nearestFireStation?.hasPhoneNumber == true;

  // ==================== Search Emergency Services ====================

  /// Find all emergency services near a location
  Future<bool> findEmergencyServices({
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    try {
      _isSearching = true;
      _error = null;
      notifyListeners();

      // Search for all emergency services
      final results = await _placesService.findAllEmergencyServices(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );

      _emergencyServices = results;
      _lastUpdate = DateTime.now();
      _isSearching = false;
      notifyListeners();

      // Check if we found all services
      if (!hasAllServices) {
        _error = 'Could not find all emergency services nearby';
        return false;
      }

      // Check if all services have phone numbers
      if (!hasAllPhoneNumbers) {
        _error = 'Some emergency services do not have phone numbers';
        return false;
      }

      return true;
    } catch (e) {
      _error = 'Error finding emergency services: $e';
      _isSearching = false;
      notifyListeners();
      return false;
    }
  }

  /// Find a specific emergency service
  Future<EmergencyPlaceResult?> findSpecificService({
    required ContactType type,
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    try {
      EmergencyPlaceResult? result;

      switch (type) {
        case ContactType.police:
          result = await _placesService.findNearestPolice(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
          );
          break;
        case ContactType.hospital:
          result = await _placesService.findNearestHospital(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
          );
          break;
        case ContactType.fireStation:
          result = await _placesService.findNearestFireStation(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
          );
          break;
        case ContactType.custom:
          return null;
      }

      if (result != null) {
        _emergencyServices[type] = result;
        notifyListeners();
      }

      return result;
    } catch (e) {
      print('Error finding $type: $e');
      return null;
    }
  }

  // ==================== Save to Database ====================

  /// Save emergency services to Supabase
  /// Uses smart selection to compare Google Places results vs custom contacts
  Future<bool> saveEmergencyServices(
    String userId, {
    required double userLatitude,
    required double userLongitude,
  }) async {
    if (!hasAllServices) {
      _error = 'No emergency services to save';
      notifyListeners();
      return false;
    }

    try {
      _isSaving = true;
      _error = null;
      notifyListeners();

      // Convert Google Places results to EmergencyContact models
      final googleContacts = <EmergencyContact>[];

      if (nearestPolice != null) {
        googleContacts.add(
          nearestPolice!.toEmergencyContact(
            userId: userId,
            contactType: ContactType.police,
          ),
        );
      }

      if (nearestHospital != null) {
        googleContacts.add(
          nearestHospital!.toEmergencyContact(
            userId: userId,
            contactType: ContactType.hospital,
          ),
        );
      }

      if (nearestFireStation != null) {
        googleContacts.add(
          nearestFireStation!.toEmergencyContact(
            userId: userId,
            contactType: ContactType.fireStation,
          ),
        );
      }

      // Smart Selection: Compare Google vs Custom for each type
      final contactsToSave = <EmergencyContact>[];

      for (final type in [
        ContactType.police,
        ContactType.hospital,
        ContactType.fireStation,
      ]) {
        // Get Google result for this type
        final googleResults = googleContacts
            .where((c) => c.contactType == type)
            .toList();

        // Find nearest (Google or Custom)
        final nearest = await _customContactService.findNearestContact(
          type: type,
          googleResults: googleResults,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        );

        if (nearest != null) {
          contactsToSave.add(nearest);
          print(
            '✓ Selected ${type.displayName}: ${nearest.name} '
            '(${nearest.sourceBadge})',
          );
        }
      }

      // Save to database (will insert or update based on user_id + contact_type)
      for (final contact in contactsToSave) {
        await _supabaseService.upsertEmergencyContact(contact.toInsertJson());
      }

      // Load saved contacts
      await loadSavedContacts(userId);

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error saving emergency services: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Update a specific contact in database
  Future<bool> updateContact({
    required String userId,
    required ContactType type,
    required EmergencyPlaceResult placeResult,
  }) async {
    try {
      final contact = placeResult.toEmergencyContact(
        userId: userId,
        contactType: type,
      );

      await _supabaseService.upsertEmergencyContact(contact.toInsertJson());
      await loadSavedContacts(userId);

      return true;
    } catch (e) {
      _error = 'Error updating contact: $e';
      notifyListeners();
      return false;
    }
  }

  // ==================== Load from Database ====================

  /// Load saved emergency contacts from Supabase
  Future<void> loadSavedContacts(String userId) async {
    try {
      final contactsData = await _supabaseService.getAiGeneratedContacts();

      _savedContacts.clear();
      for (final data in contactsData) {
        final contact = EmergencyContact.fromJson(data);
        _savedContacts[contact.contactType] = contact;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading saved contacts: $e');
    }
  }

  /// Refresh contacts from current location
  Future<bool> refreshContacts({
    required String userId,
    required double latitude,
    required double longitude,
    double radiusMeters = 10000,
  }) async {
    // Find new emergency services
    final found = await findEmergencyServices(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );

    if (!found) {
      return false;
    }

    // Save to database with smart selection
    return await saveEmergencyServices(
      userId,
      userLatitude: latitude,
      userLongitude: longitude,
    );
  }

  // ==================== Check for Updates ====================

  /// Check if contacts need updating based on location change
  Future<bool> shouldUpdateContacts({
    required double currentLat,
    required double currentLon,
    double thresholdMeters = 5000, // 5km
  }) async {
    // If no saved contacts, definitely need to update
    if (_savedContacts.isEmpty) {
      return true;
    }

    // Check distance from saved police station (as reference point)
    final savedPolice = _savedContacts[ContactType.police];
    if (savedPolice == null) {
      return true;
    }

    final distance = _placesService.calculateDistance(
      currentLat,
      currentLon,
      savedPolice.latitude ?? 0,
      savedPolice.longitude ?? 0,
    );

    return distance > thresholdMeters;
  }

  // ==================== Utility Methods ====================

  /// Clear all data
  void clear() {
    _emergencyServices.clear();
    _savedContacts.clear();
    _error = null;
    _lastUpdate = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if API key is configured
  bool isApiKeyConfigured() {
    return _placesService.isApiKeyConfigured();
  }
}
