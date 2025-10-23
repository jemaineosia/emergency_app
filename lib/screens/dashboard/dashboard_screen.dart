import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/emergency_contact.dart';
import '../../providers/auth_provider.dart';
import '../../providers/background_service_provider.dart';
import '../../providers/contact_sync_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/supabase_service.dart';
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
          return FutureBuilder<String>(
            future: _getFallbackNumber(),
            builder: (context, snapshot) {
              final fallbackNumber = snapshot.data ?? '911';

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
                        'No Emergency Contacts Found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pull down to refresh and find nearest emergency services',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.emergency, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Emergency Fallback Number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fallbackNumber,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Universal emergency number',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _makePhoneCall(fallbackNumber),
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('CALL'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _refreshContacts,
                        icon: const Icon(Icons.search),
                        label: const Text('Find Emergency Services'),
                      ),
                    ],
                  ),
                ),
              );
            },
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
            // Show Police contacts
            if (emergencyProvider
                    .allContactOptions[ContactType.police]
                    ?.isNotEmpty ==
                true)
              _buildContactOptionsCard(
                ContactType.police,
                emergencyProvider.allContactOptions[ContactType.police]!,
              )
            else if (emergencyProvider.savedPolice != null)
              _buildContactCard(emergencyProvider.savedPolice!),

            // Show Hospital contacts
            if (emergencyProvider
                    .allContactOptions[ContactType.hospital]
                    ?.isNotEmpty ==
                true)
              _buildContactOptionsCard(
                ContactType.hospital,
                emergencyProvider.allContactOptions[ContactType.hospital]!,
              )
            else if (emergencyProvider.savedHospital != null)
              _buildContactCard(emergencyProvider.savedHospital!),

            // Show Fire Station contacts
            if (emergencyProvider
                    .allContactOptions[ContactType.fireStation]
                    ?.isNotEmpty ==
                true)
              _buildContactOptionsCard(
                ContactType.fireStation,
                emergencyProvider.allContactOptions[ContactType.fireStation]!,
              )
            else if (emergencyProvider.savedFireStation != null)
              _buildContactCard(emergencyProvider.savedFireStation!),
          ],
        );
      },
    );
  }

  /// Build a card showing multiple contact options for a type
  Widget _buildContactOptionsCard(ContactType type, List<dynamic> contacts) {
    if (contacts.isEmpty) return const SizedBox.shrink();

    // If only one contact, show regular card
    if (contacts.length == 1) {
      return _buildContactCard(contacts.first);
    }

    // Multiple contacts - show primary (nearest) + alternatives
    final nearestContact = contacts.first;
    final alternatives = contacts.skip(1).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // NEAREST contact - always visible in main view
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      'NEAREST ${type.displayName.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              _buildContactTile(
                nearestContact,
                isPrimary: true,
                showDistance: true,
              ),
            ],
          ),

          // ALTERNATIVE contacts - in expandable section
          if (alternatives.isNotEmpty) ...[
            const Divider(height: 1),
            ExpansionTile(
              title: Row(
                children: [
                  Icon(Icons.list_alt, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${alternatives.length} Alternative${alternatives.length > 1 ? 's' : ''} Available',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'Tap to see other nearby options',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: EdgeInsets.zero,
              children: alternatives.asMap().entries.map((entry) {
                final index = entry.key;
                final contact = entry.value;
                return Column(
                  children: [
                    const Divider(height: 1),
                    _buildContactTile(
                      contact,
                      isPrimary: false,
                      showDistance: true,
                      alternativeNumber:
                          index + 2, // 2nd nearest, 3rd nearest, etc.
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Build a contact tile (used within cards)
  Widget _buildContactTile(
    dynamic contact, {
    required bool isPrimary,
    bool showDistance = false,
    int? alternativeNumber,
  }) {
    final name = contact.name ?? contact.contactType.displayName;
    final phone = contact.phoneNumber ?? 'No phone number';
    final address = contact.address ?? 'No address';
    final emoji = contact.contactType.emoji;
    final isCustom = contact.isCustom ?? false;
    final sourceBadge = contact.sourceBadge ?? (isCustom ? 'Custom' : 'Google');

    // Simple validation: just check if not empty or placeholder
    final hasValidPhone =
        phone.isNotEmpty &&
        phone != 'No phone number' &&
        phone != 'N/A' &&
        phone != '-';

    // Debug: Log validation for each contact
    print(
      '🔍 Dashboard checking ${contact.name}: phone="$phone", hasValidPhone=$hasValidPhone',
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPrimary
            ? Theme.of(context).primaryColor
            : Colors.grey[300],
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          if (alternativeNumber != null) ...[
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$alternativeNumber${_getOrdinalSuffix(alternativeNumber)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCustom ? Colors.purple[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCustom ? Colors.purple[200]! : Colors.blue[200]!,
              ),
            ),
            child: Text(
              sourceBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCustom ? Colors.purple[700] : Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone, size: 16),
              const SizedBox(width: 4),
              Text(phone, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.phone,
          color: hasValidPhone ? Colors.green : Colors.grey,
        ),
        onPressed: hasValidPhone ? () => _makePhoneCall(phone) : null,
        tooltip: hasValidPhone ? 'Call $phone' : 'No phone number available',
      ),
      onTap: () => _showContactDetails(contact),
    );
  }

  /// Get ordinal suffix for numbers (1st, 2nd, 3rd, etc.)
  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildContactCard(dynamic contact) {
    final name = contact.name ?? contact.contactType.displayName;
    final phone = contact.phoneNumber ?? 'No phone number';
    final address = contact.address ?? 'No address';
    final emoji = contact.contactType.emoji;
    final isCustom = contact.isCustom ?? false;

    // Simple validation: just check if not empty or placeholder
    final hasValidPhone =
        phone.isNotEmpty &&
        phone != 'No phone number' &&
        phone != 'N/A' &&
        phone != '-';

    // Debug: Log validation for single contact card
    print(
      '🔍 Dashboard (single card) checking $name: phone="$phone", hasValidPhone=$hasValidPhone',
    );

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
          icon: Icon(
            Icons.phone,
            color: hasValidPhone ? Colors.green : Colors.grey,
          ),
          onPressed: hasValidPhone ? () {
            print('📞 Calling $phone from single card');
            _makePhoneCall(phone);
          } : null,
          tooltip: hasValidPhone ? 'Call $phone' : 'No phone number available',
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

  /// Get fallback emergency number from settings
  Future<String> _getFallbackNumber() async {
    try {
      final settings = await SupabaseService.instance.getUserSettings();
      return settings?['fallback_number'] as String? ?? '911';
    } catch (e) {
      print('Error getting fallback number: $e');
      return '911';
    }
  }

  /// Make a phone call to the given number
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not call $phoneNumber')));
      }
    }
  }

  /// Show contact details in a dialog
  void _showContactDetails(dynamic contact) {
    final name = contact.name ?? contact.contactType.displayName;
    final phone = contact.phoneNumber ?? 'No phone number';
    final address = contact.address ?? 'No address';
    final emoji = contact.contactType.emoji;
    final isCustom = contact.isCustom ?? false;
    final sourceBadge = contact.sourceBadge ?? (isCustom ? 'Custom' : 'Google');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Text(name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.label),
              title: const Text('Source'),
              subtitle: Text(sourceBadge),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: Text(phone),
              trailing: IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () => _makePhoneCall(phone),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on),
              title: const Text('Address'),
              subtitle: Text(address),
            ),
            if (contact.latitude != null && contact.longitude != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.map),
                title: const Text('Coordinates'),
                subtitle: Text(
                  '${contact.latitude?.toStringAsFixed(6)}, '
                  '${contact.longitude?.toStringAsFixed(6)}',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _makePhoneCall(phone);
            },
            icon: const Icon(Icons.phone),
            label: const Text('Call'),
          ),
        ],
      ),
    );
  }
}
