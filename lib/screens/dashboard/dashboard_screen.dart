import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/background_service_provider.dart';
import '../../providers/contact_sync_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/location_provider.dart';
import '../custom_contacts/custom_contacts_screen.dart';
import '../history/update_history_screen.dart';
import '../settings/settings_screen.dart';

/// Main dashboard screen showing emergency contacts
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    final locationProvider = context.read<LocationProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();
    final contactSyncProvider = context.read<ContactSyncProvider>();
    final backgroundProvider = context.read<BackgroundServiceProvider>();
    final authProvider = context.read<AuthProvider>();

    // Initialize providers
    await locationProvider.initialize();
    await contactSyncProvider.checkPermission();
    await backgroundProvider.initialize();

    // Auto-detect location on load
    if (!locationProvider.hasPermission) {
      final granted = await locationProvider.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for this app'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      await locationProvider.getCurrentPosition(forceRefresh: true);
    }

    // Load saved contacts if user is signed in
    if (authProvider.userId != null) {
      await emergencyProvider.loadSavedContacts(authProvider.userId!);
    }

    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _refreshContacts() async {
    final authProvider = context.read<AuthProvider>();
    final locationProvider = context.read<LocationProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();
    final contactSyncProvider = context.read<ContactSyncProvider>();

    if (authProvider.userId == null) return;

    // Get current location
    final hasLocation = await locationProvider.getCurrentPosition(
      forceRefresh: true,
    );
    if (!hasLocation ||
        locationProvider.latitude == null ||
        locationProvider.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get current location')),
        );
      }
      return;
    }

    // Find emergency services
    final found = await emergencyProvider.findEmergencyServices(
      latitude: locationProvider.latitude!,
      longitude: locationProvider.longitude!,
    );

    if (!found) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              emergencyProvider.error ?? 'Failed to find emergency services',
            ),
          ),
        );
      }
      return;
    }

    // Save to database with smart selection (Google vs Custom)
    final saved = await emergencyProvider.saveEmergencyServices(
      authProvider.userId!,
      userLatitude: locationProvider.latitude!,
      userLongitude: locationProvider.longitude!,
    );
    if (!saved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emergencyProvider.error ?? 'Failed to save contacts'),
          ),
        );
      }
      return;
    }

    // Sync to phone
    final contacts = [
      if (emergencyProvider.savedPolice != null) emergencyProvider.savedPolice!,
      if (emergencyProvider.savedHospital != null)
        emergencyProvider.savedHospital!,
      if (emergencyProvider.savedFireStation != null)
        emergencyProvider.savedFireStation!,
    ];

    await contactSyncProvider.syncAllContacts(contacts);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contacts updated!')),
      );
    }
  }

  void _navigateToCustomContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomContactsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshContacts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationCard(),
                const SizedBox(height: 24),
                _buildEmergencyContactsSection(),
                const SizedBox(height: 24),
                _buildBackgroundServiceCard(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshContacts,
        icon: const Icon(Icons.refresh),
        label: const Text('Update Now'),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        // Check for permission denied
        final hasPermissionDenied =
            !locationProvider.hasPermission &&
            locationProvider.permissionStatus != null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasPermissionDenied
                          ? Icons.location_off
                          : Icons.location_on,
                      color: hasPermissionDenied
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (locationProvider.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (hasPermissionDenied) ...[
                  const Text(
                    'Location permission denied',
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await locationProvider.openAppSettings();
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Open Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else if (locationProvider.error != null) ...[
                  Text(
                    locationProvider.error!,
                    style: const TextStyle(fontSize: 14, color: Colors.orange),
                  ),
                ] else ...[
                  Text(
                    locationProvider.hasPosition
                        ? (locationProvider.currentAddress?.shortAddress ??
                              'Lat: ${locationProvider.latitude?.toStringAsFixed(4)}, '
                                  'Lon: ${locationProvider.longitude?.toStringAsFixed(4)}')
                        : 'Detecting location...',
                    style: TextStyle(
                      fontSize: 14,
                      color: locationProvider.hasPosition
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Consumer<EmergencyProvider>(
      builder: (context, emergencyProvider, _) {
        final hasContacts =
            emergencyProvider.savedPolice != null ||
            emergencyProvider.savedHospital != null ||
            emergencyProvider.savedFireStation != null;

        if (!hasContacts) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 64,
                    color: Colors.orange[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Emergency Contacts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pull down to refresh and find nearest emergency services',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshContacts,
                    icon: const Icon(Icons.search),
                    label: const Text('Find Emergency Services'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Emergency Services',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _navigateToCustomContacts,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Manage', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (emergencyProvider.savedPolice != null)
              _buildContactCard(emergencyProvider.savedPolice!),
            if (emergencyProvider.savedHospital != null)
              _buildContactCard(emergencyProvider.savedHospital!),
            if (emergencyProvider.savedFireStation != null)
              _buildContactCard(emergencyProvider.savedFireStation!),
          ],
        );
      },
    );
  }

  Widget _buildContactCard(dynamic contact) {
    final name = contact.name ?? contact.contactType.displayName;
    final phone = contact.phoneNumber ?? 'No phone number';
    final address = contact.address ?? 'No address';
    final emoji = contact.contactType.emoji;
    final isCustom = contact.isCustom ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isCustom)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Custom',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('📞 $phone'),
            const SizedBox(height: 2),
            Text('📍 $address', style: const TextStyle(fontSize: 12)),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            // TODO: Make call
          },
        ),
      ),
    );
  }

  Widget _buildBackgroundServiceCard() {
    return Consumer<BackgroundServiceProvider>(
      builder: (context, backgroundProvider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      backgroundProvider.isEnabled
                          ? Icons.sync
                          : Icons.sync_disabled,
                      color: backgroundProvider.isEnabled
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Background Updates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(backgroundProvider.getStatusMessage()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: backgroundProvider.isEnabled
                            ? () => backgroundProvider.disable()
                            : () => backgroundProvider.enable(),
                        icon: Icon(
                          backgroundProvider.isEnabled
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          backgroundProvider.isEnabled ? 'Disable' : 'Enable',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
