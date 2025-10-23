import 'package:flutter/foundation.dart';

import '../models/emergency_contact.dart';
import '../services/custom_contact_service.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/supabase_service.dart';

/// Provider for managing emergency services
class EmergencyProvider extends ChangeNotifier {
  final PlacesService _placesService = PlacesService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final LocationService _locationService = LocationService.instance;
  final CustomContactService _customContactService =
      CustomContactService.instance;

  Map<ContactType, EmergencyPlaceResult?> _emergencyServices = {};
  final Map<ContactType, EmergencyContact?> _savedContacts = {};
  // Store both Google and Custom contacts for each type
  final Map<ContactType, List<EmergencyContact>> _allContactOptions = {};
  bool _isSearching = false;
  bool _isSaving = false;
  String? _error;
  DateTime? _lastUpdate;

  // ==================== Getters ====================

  Map<ContactType, EmergencyPlaceResult?> get emergencyServices =>
      _emergencyServices;
  Map<ContactType, EmergencyContact?> get savedContacts => _savedContacts;

  /// Get all contact options (both Google and Custom) for each type
  Map<ContactType, List<EmergencyContact>> get allContactOptions =>
      _allContactOptions;
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

      // Note: We no longer treat missing phone numbers as an error
      // The fallback number will be used instead
      if (!hasAllPhoneNumbers) {
        print(
          '⚠️ Some emergency services missing phone numbers - fallback will be used',
        );
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
  /// Saves the NEAREST contact to database (Google or Custom)
  /// But stores ALL options in _allContactOptions for UI display
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

      // Get fallback number from settings
      final settings = await _supabaseService.getUserSettings();
      final fallbackNumber = settings?['fallback_number'] as String? ?? '911';

      // Convert Google Places results to EmergencyContact models
      final googleContacts = <EmergencyContact>[];

      if (nearestPolice != null) {
        var contact = nearestPolice!.toEmergencyContact(
          userId: userId,
          contactType: ContactType.police,
        );

        // Use fallback if no phone number or placeholder text
        if (contact.phoneNumber.isEmpty ||
            contact.phoneNumber == 'No phone number' ||
            contact.phoneNumber == 'N/A' ||
            contact.phoneNumber == '-') {
          contact = contact.copyWith(phoneNumber: fallbackNumber);
          print(
            '⚠️ Police has no phone number - using fallback: $fallbackNumber',
          );
        } else {
          // Clean phone number (remove spaces, dashes, parentheses)
          final cleaned = contact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
          contact = contact.copyWith(phoneNumber: cleaned);
        }
        googleContacts.add(contact);
      }

      if (nearestHospital != null) {
        var contact = nearestHospital!.toEmergencyContact(
          userId: userId,
          contactType: ContactType.hospital,
        );
        print('🏥 Hospital phone number from Google: "${contact.phoneNumber}"');

        // Use fallback if no phone number or placeholder text
        if (contact.phoneNumber.isEmpty ||
            contact.phoneNumber == 'No phone number' ||
            contact.phoneNumber == 'N/A' ||
            contact.phoneNumber == '-') {
          contact = contact.copyWith(phoneNumber: fallbackNumber);
          print(
            '⚠️ Hospital has no phone number - using fallback: $fallbackNumber',
          );
        } else {
          // Clean phone number (remove spaces, dashes, parentheses)
          final cleaned = contact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
          contact = contact.copyWith(phoneNumber: cleaned);
        }
        googleContacts.add(contact);
      }

      if (nearestFireStation != null) {
        var contact = nearestFireStation!.toEmergencyContact(
          userId: userId,
          contactType: ContactType.fireStation,
        );
        print(
          '🚒 Fire Station phone number from Google: "${contact.phoneNumber}"',
        );

        // Use fallback if no phone number or placeholder text
        if (contact.phoneNumber.isEmpty ||
            contact.phoneNumber == 'No phone number' ||
            contact.phoneNumber == 'N/A' ||
            contact.phoneNumber == '-') {
          contact = contact.copyWith(phoneNumber: fallbackNumber);
          print(
            '⚠️ Fire Station has no phone number - using fallback: $fallbackNumber',
          );
        } else {
          // Clean phone number (remove spaces, dashes, parentheses)
          final cleaned = contact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
          contact = contact.copyWith(phoneNumber: cleaned);
        }
        googleContacts.add(contact);
      }

      // Build all contact options and save nearest one to DB
      final contactsToSave = <EmergencyContact>[];
      _allContactOptions.clear();

      for (final type in [
        ContactType.police,
        ContactType.hospital,
        ContactType.fireStation,
      ]) {
        final typeContacts = <EmergencyContact>[];

        // Get Google result for this type
        final googleResults = googleContacts
            .where((c) => c.contactType == type)
            .toList();

        if (googleResults.isNotEmpty) {
          typeContacts.addAll(googleResults);
        }

        // Get custom contacts for this type
        final customContacts = await _customContactService
            .getCustomContactsByType(type);

        if (customContacts.isNotEmpty) {
          typeContacts.addAll(customContacts);
        }

        // Sort by distance from user
        if (typeContacts.isNotEmpty) {
          typeContacts.sort((a, b) {
            final distA = _placesService.calculateDistance(
              userLatitude,
              userLongitude,
              a.latitude ?? 0,
              a.longitude ?? 0,
            );
            final distB = _placesService.calculateDistance(
              userLatitude,
              userLongitude,
              b.latitude ?? 0,
              b.longitude ?? 0,
            );
            return distA.compareTo(distB);
          });

          // Store ALL options for this type (for UI display)
          _allContactOptions[type] = typeContacts;

          // Save only the NEAREST one to database (for phone sync)
          contactsToSave.add(typeContacts.first);

          print(
            '✓ Found ${typeContacts.length} ${type.displayName} option(s): '
            '${typeContacts.map((c) => '${c.name} (${c.sourceBadge})').join(', ')}',
          );
        }
      }

      // Save nearest contacts to database (will insert or update based on user_id + contact_type)
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
  /// Also populates allContactOptions with both Google and Custom contacts
  /// Sorts contacts by distance from current location
  Future<void> loadSavedContacts(String userId) async {
    try {
      // Get all active contacts (both AI-generated and custom)
      final contactsData = await _supabaseService.getAllEmergencyContacts();

      _savedContacts.clear();
      _allContactOptions.clear();

      // Get current location for distance sorting
      final position = await _locationService.getCurrentPosition();
      final userLat = position?.latitude;
      final userLon = position?.longitude;

      // Group contacts by type
      final contactsByType = <ContactType, List<EmergencyContact>>{};

      for (final data in contactsData) {
        final contact = EmergencyContact.fromJson(data);

        // Debug: Log loaded phone numbers
        print(
          '📱 Loaded ${contact.contactType.displayName}: phone="${contact.phoneNumber}"',
        );

        // Add to savedContacts (only keeps one per type - the one in DB)
        _savedContacts[contact.contactType] = contact;

        // Add to grouped list
        contactsByType.putIfAbsent(contact.contactType, () => []);
        contactsByType[contact.contactType]!.add(contact);
      }

      // Populate allContactOptions with both Google (AI-generated) and Custom
      for (final type in ContactType.values) {
        if (type == ContactType.custom) continue;

        final typeContacts = <EmergencyContact>[];

        // Get all contacts for this type from database
        final dbContacts = contactsByType[type] ?? [];
        typeContacts.addAll(dbContacts);

        // Get custom contacts for this type
        final customContacts = await _customContactService
            .getCustomContactsByType(type);

        // Add custom contacts that aren't already in the list
        for (final custom in customContacts) {
          final exists = typeContacts.any(
            (c) =>
                c.id == custom.id ||
                (c.phoneNumber == custom.phoneNumber && c.name == custom.name),
          );
          if (!exists) {
            typeContacts.add(custom);
          }
        }

        // Sort by distance from user's current location
        if (typeContacts.isNotEmpty && userLat != null && userLon != null) {
          typeContacts.sort((a, b) {
            final distA = _placesService.calculateDistance(
              userLat,
              userLon,
              a.latitude ?? 0,
              a.longitude ?? 0,
            );
            final distB = _placesService.calculateDistance(
              userLat,
              userLon,
              b.latitude ?? 0,
              b.longitude ?? 0,
            );
            return distA.compareTo(distB);
          });

          print(
            '✓ Sorted ${type.displayName} contacts by distance: '
            '${typeContacts.map((c) => '${c.name} (${c.sourceBadge})').join(', ')}',
          );
        }

        if (typeContacts.isNotEmpty) {
          _allContactOptions[type] = typeContacts;
        }
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
