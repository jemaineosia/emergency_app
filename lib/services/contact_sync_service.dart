import 'package:flutter_contacts/flutter_contacts.dart';

import '../models/emergency_contact.dart';

/// Service for syncing emergency contacts with phone's contact list
class ContactSyncService {
  static ContactSyncService? _instance;

  ContactSyncService._();

  /// Singleton instance
  static ContactSyncService get instance {
    _instance ??= ContactSyncService._();
    return _instance!;
  }

  // ==================== Permission Handling ====================

  /// Check if contacts permission is granted
  Future<bool> hasPermission() async {
    try {
      // Try to get contacts to check permission
      await FlutterContacts.getContacts(withProperties: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Request contacts permission
  Future<ContactPermissionResult> requestPermission() async {
    final granted = await FlutterContacts.requestPermission();

    if (granted) {
      return ContactPermissionResult.granted;
    } else {
      return ContactPermissionResult.denied;
    }
  }

  // ==================== Find Contacts ====================

  /// Find contact by display name
  Future<Contact?> findContactByName(String name) async {
    if (!await hasPermission()) {
      return null;
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Look for exact match first
      for (final contact in contacts) {
        if (contact.displayName.toUpperCase() == name.toUpperCase()) {
          return contact;
        }
      }

      return null;
    } catch (e) {
      print('Error finding contact: $e');
      return null;
    }
  }

  /// Check if emergency contact exists
  Future<bool> emergencyContactExists(ContactType type) async {
    final contact = await findContactByName(type.displayName);
    return contact != null;
  }

  /// Find all emergency contacts
  Future<Map<ContactType, Contact?>> findAllEmergencyContacts() async {
    final results = <ContactType, Contact?>{};

    for (final type in [
      ContactType.police,
      ContactType.hospital,
      ContactType.fireStation,
    ]) {
      results[type] = await findContactByName(type.displayName);
    }

    return results;
  }

  // ==================== Create/Update Contacts ====================

  /// Create or update emergency contact in phone
  Future<ContactSyncResult> syncEmergencyContact(
    EmergencyContact emergencyContact,
  ) async {
    if (!await hasPermission()) {
      return ContactSyncResult.permissionDenied;
    }

    try {
      // Find existing contact
      final existingContact = await findContactByName(
        emergencyContact.contactType.displayName,
      );

      if (existingContact != null) {
        // Update existing contact
        return await _updateContact(existingContact, emergencyContact);
      } else {
        // Create new contact
        return await _createContact(emergencyContact);
      }
    } catch (e) {
      print('Error syncing contact: $e');
      return ContactSyncResult.error;
    }
  }

  /// Create new contact
  Future<ContactSyncResult> _createContact(
    EmergencyContact emergencyContact,
  ) async {
    try {
      final contact = Contact()
        ..name = Name(first: emergencyContact.contactType.displayName)
        ..phones = [Phone(emergencyContact.phoneNumber)];

      // Add address if available
      if (emergencyContact.address != null &&
          emergencyContact.address!.isNotEmpty) {
        contact.addresses = [Address(emergencyContact.address!)];
      }

      // Add note
      contact.notes = [
        Note(
          '${emergencyContact.contactType.emoji} Emergency contact - Auto-updated by Emergency App\n'
          'Last updated: ${DateTime.now().toString().split('.')[0]}',
        ),
      ];

      await contact.insert();
      return ContactSyncResult.created;
    } catch (e) {
      print('Error creating contact: $e');
      return ContactSyncResult.error;
    }
  }

  /// Update existing contact
  Future<ContactSyncResult> _updateContact(
    Contact existingContact,
    EmergencyContact emergencyContact,
  ) async {
    try {
      // Check if phone number needs updating
      final newPhoneNumber = emergencyContact.phoneNumber;
      final hasPhoneChanged =
          existingContact.phones.isEmpty ||
          existingContact.phones.first.number != newPhoneNumber;

      if (!hasPhoneChanged) {
        return ContactSyncResult.unchanged;
      }

      // Update phone number
      existingContact.phones = [Phone(newPhoneNumber)];

      // Update address if available
      if (emergencyContact.address != null &&
          emergencyContact.address!.isNotEmpty) {
        existingContact.addresses = [Address(emergencyContact.address!)];
      }

      // Update note
      existingContact.notes = [
        Note(
          '${emergencyContact.contactType.emoji} Emergency contact - Auto-updated by Emergency App\n'
          'Last updated: ${DateTime.now().toString().split('.')[0]}',
        ),
      ];

      await existingContact.update();
      return ContactSyncResult.updated;
    } catch (e) {
      print('Error updating contact: $e');
      return ContactSyncResult.error;
    }
  }

  /// Sync all emergency contacts
  Future<Map<ContactType, ContactSyncResult>> syncAllEmergencyContacts(
    List<EmergencyContact> contacts,
  ) async {
    final results = <ContactType, ContactSyncResult>{};

    for (final contact in contacts) {
      if (contact.contactType != ContactType.custom) {
        results[contact.contactType] = await syncEmergencyContact(contact);
      }
    }

    return results;
  }

  // ==================== Delete Contacts ====================

  /// Delete emergency contact from phone
  Future<bool> deleteEmergencyContact(ContactType type) async {
    if (!await hasPermission()) {
      return false;
    }

    try {
      final contact = await findContactByName(type.displayName);
      if (contact != null) {
        await contact.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting contact: $e');
      return false;
    }
  }

  /// Delete all emergency contacts from phone
  Future<int> deleteAllEmergencyContacts() async {
    int deletedCount = 0;

    for (final type in [
      ContactType.police,
      ContactType.hospital,
      ContactType.fireStation,
    ]) {
      if (await deleteEmergencyContact(type)) {
        deletedCount++;
      }
    }

    return deletedCount;
  }

  // ==================== Utility Methods ====================

  /// Get contact details
  Future<ContactDetails?> getContactDetails(ContactType type) async {
    final contact = await findContactByName(type.displayName);
    if (contact == null) return null;

    return ContactDetails(
      displayName: contact.displayName,
      phoneNumber: contact.phones.isNotEmpty
          ? contact.phones.first.number
          : null,
      address: contact.addresses.isNotEmpty
          ? contact.addresses.first.address
          : null,
      note: contact.notes.isNotEmpty ? contact.notes.first.note : null,
    );
  }

  /// Verify all emergency contacts are synced correctly
  Future<ContactSyncStatus> verifySync(
    List<EmergencyContact> expectedContacts,
  ) async {
    if (!await hasPermission()) {
      return ContactSyncStatus.permissionDenied;
    }

    final phoneContacts = await findAllEmergencyContacts();
    int syncedCount = 0;
    int mismatchCount = 0;

    for (final expected in expectedContacts) {
      if (expected.contactType == ContactType.custom) continue;

      final phoneContact = phoneContacts[expected.contactType];

      if (phoneContact == null) {
        mismatchCount++;
        continue;
      }

      final phoneNumber = phoneContact.phones.isNotEmpty
          ? phoneContact.phones.first.number
          : null;

      if (phoneNumber == expected.phoneNumber) {
        syncedCount++;
      } else {
        mismatchCount++;
      }
    }

    if (syncedCount == 3 && mismatchCount == 0) {
      return ContactSyncStatus.fullySynced;
    } else if (syncedCount > 0) {
      return ContactSyncStatus.partiallySynced;
    } else {
      return ContactSyncStatus.notSynced;
    }
  }

  /// Format phone number for display
  String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) {
      // US format: (123) 456-7890
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      // US format with country code: +1 (123) 456-7890
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }

    return phone; // Return original if not standard format
  }
}

/// Result of contact sync operation
enum ContactSyncResult { created, updated, unchanged, permissionDenied, error }

/// Permission result
enum ContactPermissionResult { granted, denied }

/// Sync status
enum ContactSyncStatus {
  fullySynced,
  partiallySynced,
  notSynced,
  permissionDenied,
}

/// Contact details
class ContactDetails {
  final String displayName;
  final String? phoneNumber;
  final String? address;
  final String? note;

  ContactDetails({
    required this.displayName,
    this.phoneNumber,
    this.address,
    this.note,
  });

  @override
  String toString() {
    return 'ContactDetails(name: $displayName, phone: $phoneNumber)';
  }
}

/// Extension for sync result messages
extension ContactSyncResultExtension on ContactSyncResult {
  String get message {
    switch (this) {
      case ContactSyncResult.created:
        return 'Contact created successfully';
      case ContactSyncResult.updated:
        return 'Contact updated successfully';
      case ContactSyncResult.unchanged:
        return 'Contact already up to date';
      case ContactSyncResult.permissionDenied:
        return 'Contacts permission denied';
      case ContactSyncResult.error:
        return 'Error syncing contact';
    }
  }

  bool get isSuccess =>
      this == ContactSyncResult.created ||
      this == ContactSyncResult.updated ||
      this == ContactSyncResult.unchanged;
}

/// Extension for sync status messages
extension ContactSyncStatusExtension on ContactSyncStatus {
  String get message {
    switch (this) {
      case ContactSyncStatus.fullySynced:
        return 'All emergency contacts synced';
      case ContactSyncStatus.partiallySynced:
        return 'Some contacts need syncing';
      case ContactSyncStatus.notSynced:
        return 'No contacts synced';
      case ContactSyncStatus.permissionDenied:
        return 'Contacts permission denied';
    }
  }

  bool get needsSync => this != ContactSyncStatus.fullySynced;
}
