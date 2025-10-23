import '../models/emergency_contact.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';

/// Service for managing user's custom emergency contacts
class CustomContactService {
  static CustomContactService? _instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final LocationService _locationService = LocationService.instance;

  CustomContactService._();

  /// Singleton instance
  static CustomContactService get instance {
    _instance ??= CustomContactService._();
    return _instance!;
  }

  // ==================== CRUD Operations ====================

  /// Get all custom contacts for current user
  Future<List<EmergencyContact>> getAllCustomContacts() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        print('No user logged in');
        return [];
      }

      final response = await _supabaseService.getCustomContacts();

      // Convert to EmergencyContact objects and filter custom ones
      return response
          .map((json) => EmergencyContact.fromJson(json))
          .where((c) => c.isCustom)
          .toList();
    } catch (e) {
      print('Error getting custom contacts: $e');
      return [];
    }
  }

  /// Get custom contacts by type
  Future<List<EmergencyContact>> getCustomContactsByType(
    ContactType type,
  ) async {
    try {
      final allCustom = await getAllCustomContacts();
      return allCustom.where((c) => c.contactType == type).toList();
    } catch (e) {
      print('Error getting custom contacts by type: $e');
      return [];
    }
  }

  /// Get custom contacts sorted by distance from current location
  Future<List<EmergencyContact>> getCustomContactsSortedByDistance() async {
    try {
      final contacts = await getAllCustomContacts();
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        print('Could not get current location');
        return contacts; // Return unsorted
      }

      // Calculate distance for each and sort
      contacts.sort((a, b) {
        final distA =
            a.distanceFrom(position.latitude, position.longitude) ??
            double.infinity;
        final distB =
            b.distanceFrom(position.latitude, position.longitude) ??
            double.infinity;
        return distA.compareTo(distB);
      });

      return contacts;
    } catch (e) {
      print('Error sorting contacts by distance: $e');
      return await getAllCustomContacts();
    }
  }

  /// Add a new custom contact
  Future<EmergencyContact?> addCustomContact({
    required ContactType contactType,
    required String name,
    required String phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        print('No user logged in');
        return null;
      }

      final contactData = {
        'user_id': userId,
        'contact_type': contactType.dbValue,
        'name': name,
        'phone_number': phoneNumber,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'place_id': null, // Custom contacts don't have Google Place IDs
        'is_ai_generated': false,
        'is_custom': true, // Mark as custom
        'is_active': true,
      };

      final response = await _supabaseService.createEmergencyContact(
        contactData,
      );
      final inserted = EmergencyContact.fromJson(response);
      print('Custom contact added: ${inserted.name}');
      return inserted;
    } catch (e) {
      print('Error adding custom contact: $e');
      return null;
    }
  }

  /// Update an existing custom contact
  Future<EmergencyContact?> updateCustomContact({
    required String contactId,
    String? name,
    String? phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        print('No user logged in');
        return null;
      }

      // Build updates map
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (isActive != null) updates['is_active'] = isActive;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabaseService.updateEmergencyContact(
        contactId,
        updates,
      );
      final updated = EmergencyContact.fromJson(response);
      print('Custom contact updated: ${updated.name}');
      return updated;
    } catch (e) {
      print('Error updating custom contact: $e');
      return null;
    }
  }

  /// Delete a custom contact
  Future<bool> deleteCustomContact(String contactId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        print('No user logged in');
        return false;
      }

      // Soft delete (set is_active = false)
      await _supabaseService.deleteEmergencyContact(contactId);
      print('Custom contact deleted: $contactId');
      return true;
    } catch (e) {
      print('Error deleting custom contact: $e');
      return false;
    }
  }

  // ==================== Smart Selection ====================

  /// Find the nearest emergency contact (Google vs Custom)
  /// Returns the closest option between Google Places and user's custom contacts
  Future<EmergencyContact?> findNearestContact({
    required ContactType type,
    required List<EmergencyContact> googleResults,
    required double userLatitude,
    required double userLongitude,
  }) async {
    try {
      // Get custom contacts of this type
      final customContacts = await getCustomContactsByType(type);

      // Combine all options
      final allOptions = [...googleResults, ...customContacts];

      if (allOptions.isEmpty) {
        print('No contacts found for type: ${type.displayName}');
        return null;
      }

      // Find the nearest one
      EmergencyContact? nearest;
      double nearestDistance = double.infinity;

      for (final contact in allOptions) {
        final distance = contact.distanceFrom(userLatitude, userLongitude);
        if (distance != null && distance < nearestDistance) {
          nearestDistance = distance;
          nearest = contact;
        }
      }

      if (nearest != null) {
        print(
          'Nearest ${type.displayName}: ${nearest.name} '
          '(${nearest.sourceBadge}, ${(nearestDistance / 1000).toStringAsFixed(1)} km)',
        );
      }

      return nearest;
    } catch (e) {
      print('Error finding nearest contact: $e');
      return null;
    }
  }

  // ==================== Statistics ====================

  /// Get count of custom contacts by type
  Future<Map<ContactType, int>> getCustomContactCounts() async {
    try {
      final contacts = await getAllCustomContacts();

      return {
        ContactType.police: contacts
            .where((c) => c.contactType == ContactType.police)
            .length,
        ContactType.hospital: contacts
            .where((c) => c.contactType == ContactType.hospital)
            .length,
        ContactType.fireStation: contacts
            .where((c) => c.contactType == ContactType.fireStation)
            .length,
      };
    } catch (e) {
      print('Error getting contact counts: $e');
      return {
        ContactType.police: 0,
        ContactType.hospital: 0,
        ContactType.fireStation: 0,
      };
    }
  }

  /// Get nearest custom contact for each type
  Future<Map<ContactType, EmergencyContact?>> getNearestCustomByType() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) return {};

      final contacts = await getAllCustomContacts();
      final result = <ContactType, EmergencyContact?>{};

      for (final type in [
        ContactType.police,
        ContactType.hospital,
        ContactType.fireStation,
      ]) {
        final typeContacts = contacts
            .where((c) => c.contactType == type)
            .toList();

        if (typeContacts.isEmpty) {
          result[type] = null;
          continue;
        }

        // Find nearest for this type
        EmergencyContact? nearest;
        double nearestDistance = double.infinity;

        for (final contact in typeContacts) {
          final distance = contact.distanceFrom(
            position.latitude,
            position.longitude,
          );
          if (distance != null && distance < nearestDistance) {
            nearestDistance = distance;
            nearest = contact;
          }
        }

        result[type] = nearest;
      }

      return result;
    } catch (e) {
      print('Error getting nearest by type: $e');
      return {};
    }
  }
}
