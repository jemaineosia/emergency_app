import 'package:flutter/foundation.dart';

import '../models/emergency_contact.dart';
import '../services/custom_contact_service.dart';
import '../services/location_service.dart';

/// Provider for managing custom emergency contacts
class CustomContactProvider with ChangeNotifier {
  final CustomContactService _customContactService =
      CustomContactService.instance;
  final LocationService _locationService = LocationService.instance;

  List<EmergencyContact> _contacts = [];
  bool _isLoading = false;
  String? _error;
  Map<ContactType, int> _contactCounts = {};

  // Getters
  List<EmergencyContact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<ContactType, int> get contactCounts => _contactCounts;
  bool get hasContacts => _contacts.isNotEmpty;
  int get totalCount => _contacts.length;

  // ==================== Load Contacts ====================

  /// Load all custom contacts sorted by distance
  Future<void> loadContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _contacts = await _customContactService
          .getCustomContactsSortedByDistance();
      await _updateContactCounts();
      _error = null;
    } catch (e) {
      _error = 'Failed to load contacts: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh contacts list
  Future<void> refreshContacts() async {
    await loadContacts();
  }

  /// Get contacts by type
  List<EmergencyContact> getContactsByType(ContactType type) {
    return _contacts.where((c) => c.contactType == type).toList();
  }

  // ==================== Add Contact ====================

  /// Add a new custom contact
  Future<bool> addContact({
    required ContactType contactType,
    required String name,
    required String phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final contact = await _customContactService.addCustomContact(
        contactType: contactType,
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      if (contact != null) {
        await loadContacts(); // Reload to get sorted list
        return true;
      } else {
        _error = 'Failed to add contact';
        return false;
      }
    } catch (e) {
      _error = 'Error adding contact: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Update Contact ====================

  /// Update an existing custom contact
  Future<bool> updateContact({
    required String contactId,
    String? name,
    String? phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _customContactService.updateCustomContact(
        contactId: contactId,
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isActive: isActive,
      );

      if (updated != null) {
        await loadContacts(); // Reload to get updated list
        return true;
      } else {
        _error = 'Failed to update contact';
        return false;
      }
    } catch (e) {
      _error = 'Error updating contact: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Delete Contact ====================

  /// Delete a custom contact
  Future<bool> deleteContact(String contactId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _customContactService.deleteCustomContact(
        contactId,
      );

      if (success) {
        await loadContacts(); // Reload to update list
        return true;
      } else {
        _error = 'Failed to delete contact';
        return false;
      }
    } catch (e) {
      _error = 'Error deleting contact: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Helper Methods ====================

  /// Get current user location
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        return {'latitude': position.latitude, 'longitude': position.longitude};
      }
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Update contact counts by type
  Future<void> _updateContactCounts() async {
    _contactCounts = await _customContactService.getCustomContactCounts();
  }

  /// Get contact by ID
  EmergencyContact? getContactById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _contacts = [];
    _isLoading = false;
    _error = null;
    _contactCounts = {};
    notifyListeners();
  }
}
