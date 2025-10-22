import 'package:flutter/foundation.dart';

import '../models/emergency_contact.dart';
import '../services/contact_sync_service.dart';

/// Provider for managing contact sync operations
class ContactSyncProvider extends ChangeNotifier {
  final ContactSyncService _syncService = ContactSyncService.instance;

  ContactPermissionResult? _permissionStatus;
  Map<ContactType, ContactSyncResult> _lastSyncResults = {};
  ContactSyncStatus? _overallStatus;
  bool _isSyncing = false;
  bool _isCheckingPermission = false;
  String? _error;

  // ==================== Getters ====================

  ContactPermissionResult? get permissionStatus => _permissionStatus;
  Map<ContactType, ContactSyncResult> get lastSyncResults => _lastSyncResults;
  ContactSyncStatus? get overallStatus => _overallStatus;
  bool get isSyncing => _isSyncing;
  bool get isCheckingPermission => _isCheckingPermission;
  bool get isLoading => _isSyncing || _isCheckingPermission;
  String? get error => _error;

  bool get hasPermission =>
      _permissionStatus == ContactPermissionResult.granted;
  bool get needsPermission =>
      _permissionStatus == null ||
      _permissionStatus == ContactPermissionResult.denied;

  ContactSyncResult? getSyncResult(ContactType type) => _lastSyncResults[type];

  bool get allContactsSynced => _overallStatus == ContactSyncStatus.fullySynced;

  // ==================== Permission Management ====================

  /// Check current permission status
  Future<void> checkPermission() async {
    try {
      _isCheckingPermission = true;
      _error = null;
      notifyListeners();

      final hasPermission = await _syncService.hasPermission();
      _permissionStatus = hasPermission
          ? ContactPermissionResult.granted
          : ContactPermissionResult.denied;

      _isCheckingPermission = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error checking permission: $e';
      _isCheckingPermission = false;
      notifyListeners();
    }
  }

  /// Request contacts permission
  Future<bool> requestPermission() async {
    try {
      _isCheckingPermission = true;
      _error = null;
      notifyListeners();

      final result = await _syncService.requestPermission();
      _permissionStatus = result;

      _isCheckingPermission = false;
      notifyListeners();

      return result == ContactPermissionResult.granted;
    } catch (e) {
      _error = 'Error requesting permission: $e';
      _isCheckingPermission = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== Sync Operations ====================

  /// Sync a single emergency contact
  Future<bool> syncContact(EmergencyContact contact) async {
    if (!hasPermission) {
      _error = 'Contacts permission not granted';
      notifyListeners();
      return false;
    }

    try {
      _isSyncing = true;
      _error = null;
      notifyListeners();

      final result = await _syncService.syncEmergencyContact(contact);
      _lastSyncResults[contact.contactType] = result;

      _isSyncing = false;
      notifyListeners();

      return result.isSuccess;
    } catch (e) {
      _error = 'Error syncing contact: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Sync all emergency contacts
  Future<bool> syncAllContacts(List<EmergencyContact> contacts) async {
    if (!hasPermission) {
      _error = 'Contacts permission not granted';
      notifyListeners();
      return false;
    }

    try {
      _isSyncing = true;
      _error = null;
      notifyListeners();

      final results = await _syncService.syncAllEmergencyContacts(contacts);
      _lastSyncResults = results;

      // Verify sync status
      await verifySyncStatus(contacts);

      _isSyncing = false;
      notifyListeners();

      // Check if all synced successfully
      final allSuccess = results.values.every((result) => result.isSuccess);
      return allSuccess;
    } catch (e) {
      _error = 'Error syncing contacts: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify sync status
  Future<void> verifySyncStatus(List<EmergencyContact> expectedContacts) async {
    try {
      final status = await _syncService.verifySync(expectedContacts);
      _overallStatus = status;
      notifyListeners();
    } catch (e) {
      print('Error verifying sync status: $e');
    }
  }

  // ==================== Delete Operations ====================

  /// Delete a specific emergency contact
  Future<bool> deleteContact(ContactType type) async {
    if (!hasPermission) {
      _error = 'Contacts permission not granted';
      notifyListeners();
      return false;
    }

    try {
      _isSyncing = true;
      _error = null;
      notifyListeners();

      final success = await _syncService.deleteEmergencyContact(type);

      if (success) {
        _lastSyncResults.remove(type);
      }

      _isSyncing = false;
      notifyListeners();

      return success;
    } catch (e) {
      _error = 'Error deleting contact: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete all emergency contacts
  Future<int> deleteAllContacts() async {
    if (!hasPermission) {
      _error = 'Contacts permission not granted';
      notifyListeners();
      return 0;
    }

    try {
      _isSyncing = true;
      _error = null;
      notifyListeners();

      final deletedCount = await _syncService.deleteAllEmergencyContacts();

      if (deletedCount > 0) {
        _lastSyncResults.clear();
        _overallStatus = ContactSyncStatus.notSynced;
      }

      _isSyncing = false;
      notifyListeners();

      return deletedCount;
    } catch (e) {
      _error = 'Error deleting contacts: $e';
      _isSyncing = false;
      notifyListeners();
      return 0;
    }
  }

  // ==================== Query Operations ====================

  /// Check if a specific contact exists in phone
  Future<bool> contactExists(ContactType type) async {
    try {
      return await _syncService.emergencyContactExists(type);
    } catch (e) {
      print('Error checking contact existence: $e');
      return false;
    }
  }

  /// Get contact details from phone
  Future<ContactDetails?> getContactDetails(ContactType type) async {
    try {
      return await _syncService.getContactDetails(type);
    } catch (e) {
      print('Error getting contact details: $e');
      return null;
    }
  }

  /// Find all emergency contacts in phone
  Future<Map<ContactType, ContactDetails?>> getAllContactDetails() async {
    final results = <ContactType, ContactDetails?>{};

    for (final type in [
      ContactType.police,
      ContactType.hospital,
      ContactType.fireStation,
    ]) {
      results[type] = await getContactDetails(type);
    }

    return results;
  }

  // ==================== Utility Methods ====================

  /// Clear all cached data
  void clear() {
    _lastSyncResults.clear();
    _overallStatus = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get sync status message
  String getSyncStatusMessage() {
    if (_overallStatus == null) {
      return 'Sync status unknown';
    }
    return _overallStatus!.message;
  }

  /// Get individual sync result message
  String getSyncResultMessage(ContactType type) {
    final result = _lastSyncResults[type];
    if (result == null) {
      return 'Not synced';
    }
    return result.message;
  }

  /// Check if sync is needed
  bool needsSync() {
    return _overallStatus == null || _overallStatus!.needsSync;
  }
}
