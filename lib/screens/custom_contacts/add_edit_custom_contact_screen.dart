import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/emergency_contact.dart';
import '../../providers/custom_contact_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/geocoding_service.dart';

/// Screen for adding or editing a custom emergency contact
/// Supports 3 input methods: text, map picker, and current location
class AddEditCustomContactScreen extends StatefulWidget {
  final EmergencyContact? contact; // null = add mode, non-null = edit mode

  const AddEditCustomContactScreen({super.key, this.contact});

  @override
  State<AddEditCustomContactScreen> createState() =>
      _AddEditCustomContactScreenState();
}

class _AddEditCustomContactScreenState
    extends State<AddEditCustomContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  ContactType _selectedType = ContactType.police;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  String _locationInputMethod = 'none'; // none, text, map, current

  bool get isEditMode => widget.contact != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadExistingContact();
    }
  }

  void _loadExistingContact() {
    final contact = widget.contact!;
    _nameController.text = contact.name;
    _phoneController.text = contact.phoneNumber;
    _addressController.text = contact.address ?? '';
    _selectedType = contact.contactType;
    _latitude = contact.latitude;
    _longitude = contact.longitude;

    if (_latitude != null && _longitude != null) {
      _locationInputMethod = 'set';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ==================== Input Methods ====================

  /// Method 1: Use current GPS location
  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final locationProvider = context.read<LocationProvider>();

      // Check and request permission if needed
      if (!locationProvider.hasPermission) {
        final granted = await locationProvider.requestPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Get current position
      await locationProvider.getCurrentPosition(forceRefresh: true);

      final position = locationProvider.currentPosition;
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get current location'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Reverse geocode to get address
      final addressResult = await GeocodingService.instance
          .getAddressFromCoordinates(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _addressController.text =
              addressResult?.fullAddress ?? 'Current Location';
          _locationInputMethod = 'current_location';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Method 2: Pick location on map
  Future<void> _pickLocationOnMap() async {
    final locationProvider = context.read<LocationProvider>();
    final currentPos = locationProvider.currentPosition;

    final LatLng initialPosition = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : const LatLng(14.5995, 120.9842); // Manila, Philippines

    final LatLng? picked = await showDialog<LatLng>(
      context: context,
      builder: (context) => _MapPickerDialog(initialPosition: initialPosition),
    );

    if (picked != null) {
      setState(() => _isLoading = true);

      try {
        _latitude = picked.latitude;
        _longitude = picked.longitude;

        // Reverse geocode to get address
        final addressResult = await GeocodingService.instance
            .getAddressFromCoordinates(_latitude!, _longitude!);

        setState(() {
          _addressController.text =
              addressResult?.fullAddress ?? 'Selected Location';
          _locationInputMethod = 'map';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Location picked on map'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error geocoding location: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Method 3: Geocode text address
  Future<void> _geocodeTextAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an address first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final coordinates = await GeocodingService.instance
          .getCoordinatesFromAddress(address);

      if (coordinates != null) {
        setState(() {
          _latitude = coordinates.latitude;
          _longitude = coordinates.longitude;
          _locationInputMethod = 'text';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Address geocoded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find location for this address'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error geocoding address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== Save ====================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate location
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a location using one of the 3 methods'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customProvider = context.read<CustomContactProvider>();
      bool success;

      if (isEditMode) {
        // Update existing contact
        success = await customProvider.updateContact(
          contactId: widget.contact!.id,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );
      } else {
        // Add new contact
        success = await customProvider.addContact(
          contactType: _selectedType,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Contact updated successfully'
                    : 'Contact added successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true = success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                customProvider.error ??
                    (isEditMode
                        ? 'Failed to update contact'
                        : 'Failed to add contact'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Contact' : 'Add Custom Contact'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type Selector (only in add mode)
                    if (!isEditMode) _buildTypeSelector(),

                    const SizedBox(height: 24),

                    // Name Input
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        hintText: 'e.g., Barangay Police Station',
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Phone Input
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: '+63 912 345 6789',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Address Input
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address *',
                        hintText: 'Street, City, Province',
                        prefixIcon: const Icon(Icons.location_on),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _geocodeTextAddress,
                          tooltip: 'Geocode this address',
                        ),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Location Input Methods
                    _buildLocationInputSection(),

                    const SizedBox(height: 24),

                    // Location Status
                    if (_locationInputMethod != 'none') _buildLocationStatus(),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEditMode ? 'Update Contact' : 'Add Contact',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Type *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTypeButton(ContactType.police)),
            const SizedBox(width: 12),
            Expanded(child: _buildTypeButton(ContactType.hospital)),
            const SizedBox(width: 12),
            Expanded(child: _buildTypeButton(ContactType.fireStation)),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(ContactType type) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Set Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Method 1: Current GPS Location
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current GPS Location'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 12),

            // Method 2: Map Picker
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickLocationOnMap,
              icon: const Icon(Icons.map),
              label: const Text('Pick Location on Map'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 12),

            // Method 3: Text Address (already has button in TextField)
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Or enter address above and tap search icon',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatus() {
    String methodText;
    IconData methodIcon;
    Color methodColor;

    switch (_locationInputMethod) {
      case 'current_location':
        methodText = 'Using current GPS location';
        methodIcon = Icons.my_location;
        methodColor = Colors.green;
        break;
      case 'map':
        methodText = 'Location picked on map';
        methodIcon = Icons.map;
        methodColor = Colors.blue;
        break;
      case 'text':
        methodText = 'Address geocoded from text';
        methodIcon = Icons.search;
        methodColor = Colors.orange;
        break;
      default:
        methodText = 'Location set';
        methodIcon = Icons.check_circle;
        methodColor = Colors.green;
    }

    return Card(
      color: methodColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(methodIcon, color: methodColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    methodText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: methodColor,
                    ),
                  ),
                  if (_latitude != null && _longitude != null)
                    Text(
                      'Lat: ${_latitude!.toStringAsFixed(6)}, '
                      'Lng: ${_longitude!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Map Picker Dialog ====================

class _MapPickerDialog extends StatefulWidget {
  final LatLng initialPosition;

  const _MapPickerDialog({required this.initialPosition});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  late LatLng _selectedPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Pick Location on Map',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Map
          SizedBox(
            height: 400,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (position) {
                setState(() => _selectedPosition = position);
              },
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selectedPosition,
                  draggable: true,
                  onDragEnd: (position) {
                    setState(() => _selectedPosition = position);
                  },
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Lat: ${_selectedPosition.latitude.toStringAsFixed(6)}, '
                  'Lng: ${_selectedPosition.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, _selectedPosition),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
