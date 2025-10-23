import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/emergency_contact.dart';
import '../../providers/custom_contact_provider.dart';
import '../../providers/location_provider.dart';
import 'add_edit_custom_contact_screen.dart';

/// Screen showing all user's custom emergency contacts
class CustomContactsScreen extends StatefulWidget {
  const CustomContactsScreen({super.key});

  @override
  State<CustomContactsScreen> createState() => _CustomContactsScreenState();
}

class _CustomContactsScreenState extends State<CustomContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final customProvider = context.read<CustomContactProvider>();
    final locationProvider = context.read<LocationProvider>();

    await Future.wait([
      customProvider.loadContacts(),
      locationProvider.getCurrentPosition(),
    ]);
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  void _navigateToAdd() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditCustomContactScreen(),
          ),
        )
        .then((added) {
          if (added == true) {
            _refresh();
          }
        });
  }

  void _navigateToEdit(EmergencyContact contact) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditCustomContactScreen(contact: contact),
          ),
        )
        .then((updated) {
          if (updated == true) {
            _refresh();
          }
        });
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete "${contact.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final customProvider = context.read<CustomContactProvider>();
      final success = await customProvider.deleteContact(contact.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Contact deleted successfully'
                  : 'Failed to delete contact',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer2<CustomContactProvider, LocationProvider>(
        builder: (context, customProvider, locationProvider, child) {
          if (customProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (customProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    customProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!customProvider.hasContacts) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.contact_phone_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Custom Contacts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Add your own emergency contacts with accurate phone numbers and addresses',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Contact'),
                  ),
                ],
              ),
            );
          }

          final userLat = locationProvider.currentPosition?.latitude;
          final userLon = locationProvider.currentPosition?.longitude;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                // Summary Card
                _buildSummaryCard(customProvider),

                // Contacts List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: customProvider.contacts.length,
                    itemBuilder: (context, index) {
                      final contact = customProvider.contacts[index];
                      return _buildContactCard(contact, userLat, userLon);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }

  Widget _buildSummaryCard(CustomContactProvider provider) {
    final counts = provider.contactCounts;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${provider.totalCount} contacts',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTypeCount(
                  ContactType.police,
                  counts[ContactType.police] ?? 0,
                ),
                _buildTypeCount(
                  ContactType.hospital,
                  counts[ContactType.hospital] ?? 0,
                ),
                _buildTypeCount(
                  ContactType.fireStation,
                  counts[ContactType.fireStation] ?? 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCount(ContactType type, int count) {
    return Column(
      children: [
        Text(type.emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(
          type.displayName,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
    EmergencyContact contact,
    double? userLat,
    double? userLon,
  ) {
    final distanceString = contact.getDistanceString(userLat, userLon);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            contact.contactType.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(contact.phoneNumber),
              ],
            ),
            if (contact.address != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      contact.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    distanceString,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _navigateToEdit(contact);
            } else if (value == 'delete') {
              _deleteContact(contact);
            }
          },
        ),
      ),
    );
  }
}
