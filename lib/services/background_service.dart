import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

import '../models/emergency_contact.dart';
import '../models/update_history.dart';
import '../services/contact_sync_service.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/supabase_service.dart';

/// Service for managing background tasks
class BackgroundService {
  static BackgroundService? _instance;
  static const String taskName = 'emergencyContactUpdate';
  static const String uniqueTaskName = 'emergencyContactUpdateTask';

  BackgroundService._();

  /// Singleton instance
  static BackgroundService get instance {
    _instance ??= BackgroundService._();
    return _instance!;
  }

  // ==================== Initialize ====================

  /// Initialize background service
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );
  }

  // ==================== Schedule Tasks ====================

  /// Schedule periodic update task
  Future<void> schedulePeriodicUpdate({int intervalMinutes = 60}) async {
    await Workmanager().registerPeriodicTask(
      uniqueTaskName,
      taskName,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: Duration(minutes: 15),
    );
  }

  /// Schedule one-time immediate update
  Future<void> scheduleImmediateUpdate() async {
    await Workmanager().registerOneOffTask(
      'emergencyContactUpdateImmediate',
      taskName,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Cancel all scheduled tasks
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }

  /// Cancel periodic update task
  Future<void> cancelPeriodicUpdate() async {
    await Workmanager().cancelByUniqueName(uniqueTaskName);
  }

  // ==================== Task Status ====================

  /// Check if background updates are enabled (by checking user settings)
  Future<bool> isEnabled() async {
    try {
      final supabase = SupabaseService.instance;
      if (supabase.currentUserId == null) return false;

      final settings = await supabase.getUserSettings();
      if (settings == null) return true; // Default to enabled

      return settings['auto_update_enabled'] == true;
    } catch (e) {
      print('Error checking background service status: $e');
      return false;
    }
  }

  /// Update schedule based on user settings
  Future<void> updateSchedule() async {
    try {
      final supabase = SupabaseService.instance;
      if (supabase.currentUserId == null) return;

      final settings = await supabase.getUserSettings();
      if (settings == null) return;

      final enabled = settings['auto_update_enabled'] == true;
      final intervalMinutes = settings['update_interval_minutes'] as int? ?? 60;

      if (enabled) {
        await schedulePeriodicUpdate(intervalMinutes: intervalMinutes);
      } else {
        await cancelPeriodicUpdate();
      }
    } catch (e) {
      print('Error updating schedule: $e');
    }
  }
}

/// Callback dispatcher for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Background task started: $task');

    try {
      // Execute the update task
      final success = await _executeUpdateTask();

      print('Background task completed: $success');
      return success;
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

/// Execute the background update task
Future<bool> _executeUpdateTask() async {
  try {
    print('Starting emergency contact update task...');

    // Initialize services
    await SupabaseService.initialize();
    final supabase = SupabaseService.instance;

    // Check if user is signed in
    if (supabase.currentUserId == null) {
      print('User not signed in, skipping update');
      return true; // Not an error, just skip
    }

    // Get user settings
    final settings = await supabase.getUserSettings();
    if (settings == null) {
      print('No user settings found');
      return false;
    }

    // Check if auto-update is enabled
    final autoUpdateEnabled = settings['auto_update_enabled'] == true;
    if (!autoUpdateEnabled) {
      print('Auto-update disabled, skipping');
      return true;
    }

    final radiusKm = settings['location_radius_km'] as double? ?? 10.0;
    final radiusMeters = radiusKm * 1000;

    // Get current location
    final locationService = LocationService.instance;
    final currentPosition = await locationService.getCurrentPosition(
      forceRefresh: true,
    );

    if (currentPosition == null) {
      print('Could not get current location');
      return false;
    }

    print(
      'Current location: ${currentPosition.latitude}, ${currentPosition.longitude}',
    );

    // Get saved emergency contacts
    final savedContactsData = await supabase.getAiGeneratedContacts();
    if (savedContactsData.isEmpty) {
      print('No saved contacts, performing initial sync');
      return await _performInitialSync(currentPosition, radiusMeters, supabase);
    }

    // Check if location has changed significantly
    final savedPoliceData = savedContactsData.firstWhere(
      (c) => c['contact_type'] == 'police',
      orElse: () => <String, dynamic>{},
    );

    if (savedPoliceData.isEmpty) {
      print('No police contact found, performing initial sync');
      return await _performInitialSync(currentPosition, radiusMeters, supabase);
    }

    final savedLat = savedPoliceData['latitude'] as double?;
    final savedLon = savedPoliceData['longitude'] as double?;

    if (savedLat == null || savedLon == null) {
      print('Invalid saved coordinates, performing initial sync');
      return await _performInitialSync(currentPosition, radiusMeters, supabase);
    }

    // Calculate distance from saved location
    final distance = locationService.calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      savedLat,
      savedLon,
    );

    print('Distance from saved location: ${distance}m');

    // Only update if moved more than 5km
    if (distance < 5000) {
      print('Location change too small, skipping update');
      return true;
    }

    print('Significant location change detected, updating contacts...');

    // Perform update
    return await _performContactUpdate(
      currentPosition,
      radiusMeters,
      supabase,
      savedContactsData,
    );
  } catch (e) {
    print('Error in background task: $e');
    return false;
  }
}

/// Perform initial sync of emergency contacts
Future<bool> _performInitialSync(
  Position position,
  double radiusMeters,
  SupabaseService supabase,
) async {
  try {
    print('Performing initial sync...');

    // Find emergency services
    final placesService = PlacesService.instance;
    final emergencyServices = await placesService.findAllEmergencyServices(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: radiusMeters,
    );

    // Check if all services found
    if (emergencyServices[ContactType.police] == null ||
        emergencyServices[ContactType.hospital] == null ||
        emergencyServices[ContactType.fireStation] == null) {
      print('Could not find all emergency services');
      return false;
    }

    // Save to database
    for (final entry in emergencyServices.entries) {
      if (entry.value == null) continue;

      final contact = entry.value!.toEmergencyContact(
        userId: supabase.currentUserId!,
        contactType: entry.key,
      );

      await supabase.upsertEmergencyContact(contact.toInsertJson());
    }

    // Sync to phone contacts
    final contactSyncService = ContactSyncService.instance;
    final hasPermission = await contactSyncService.hasPermission();

    if (hasPermission) {
      for (final entry in emergencyServices.entries) {
        if (entry.value == null) continue;

        final contact = entry.value!.toEmergencyContact(
          userId: supabase.currentUserId!,
          contactType: entry.key,
        );

        await contactSyncService.syncEmergencyContact(contact);
      }
    }

    print('Initial sync completed successfully');
    return true;
  } catch (e) {
    print('Error in initial sync: $e');
    return false;
  }
}

/// Perform contact update
Future<bool> _performContactUpdate(
  Position position,
  double radiusMeters,
  SupabaseService supabase,
  List<Map<String, dynamic>> savedContactsData,
) async {
  try {
    print('Performing contact update...');

    // Find new emergency services
    final placesService = PlacesService.instance;
    final newServices = await placesService.findAllEmergencyServices(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: radiusMeters,
    );

    // Check if all services found
    if (newServices[ContactType.police] == null ||
        newServices[ContactType.hospital] == null ||
        newServices[ContactType.fireStation] == null) {
      print('Could not find all emergency services');
      return false;
    }

    // Update each contact
    for (final entry in newServices.entries) {
      if (entry.value == null) continue;

      final newContact = entry.value!.toEmergencyContact(
        userId: supabase.currentUserId!,
        contactType: entry.key,
      );

      // Find old contact
      final oldContactData = savedContactsData.firstWhere(
        (c) => c['contact_type'] == entry.key.dbValue,
        orElse: () => <String, dynamic>{},
      );

      final oldPhoneNumber = oldContactData['phone_number'] as String?;

      // Update database
      await supabase.upsertEmergencyContact(newContact.toInsertJson());

      // Log update history if phone number changed
      if (oldPhoneNumber != null && oldPhoneNumber != newContact.phoneNumber) {
        final history = UpdateHistory(
          id: '',
          userId: supabase.currentUserId!,
          contactId: oldContactData['id'] as String? ?? '',
          oldPhoneNumber: oldPhoneNumber,
          newPhoneNumber: newContact.phoneNumber,
          oldAddress: oldContactData['address'] as String?,
          newAddress: newContact.address,
          latitude: position.latitude,
          longitude: position.longitude,
          updateReason: 'Location changed - automatic update',
          createdAt: DateTime.now(),
        );

        await supabase.createUpdateHistory(history.toInsertJson());

        print(
          'Updated ${entry.key.displayName}: $oldPhoneNumber -> ${newContact.phoneNumber}',
        );
      }

      // Update phone contact
      final contactSyncService = ContactSyncService.instance;
      final hasPermission = await contactSyncService.hasPermission();

      if (hasPermission) {
        await contactSyncService.syncEmergencyContact(newContact);
      }
    }

    print('Contact update completed successfully');
    return true;
  } catch (e) {
    print('Error in contact update: $e');
    return false;
  }
}
