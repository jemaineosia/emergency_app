import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/emergency_contact.dart';
import '../providers/emergency_provider.dart';

class AddEditContactScreen extends StatefulWidget {
  final EmergencyContact? contact;

  const AddEditContactScreen({super.key, this.contact});

  @override
  State<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactNumberController;
  late TextEditingController _wakeWordController;
  String _selectedType = 'police';

  final List<String> _types = ['police', 'ambulance', 'fire station'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _addressController = TextEditingController(
      text: widget.contact?.address ?? '',
    );
    _contactNumberController = TextEditingController(
      text: widget.contact?.contactNumber ?? '',
    );
    _wakeWordController = TextEditingController(
      text: widget.contact?.wakeWord ?? '',
    );
    _selectedType = widget.contact?.type ?? 'police';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _wakeWordController.dispose();
    super.dispose();
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<EmergencyProvider>(context, listen: false);

      final contact = EmergencyContact(
        id:
            widget.contact?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _selectedType,
        wakeWord: _wakeWordController.text,
        address: _addressController.text,
        contactNumber: _contactNumberController.text,
      );

      if (widget.contact == null) {
        provider.addContact(contact);
      } else {
        provider.updateContact(contact);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _wakeWordController,
              decoration: const InputDecoration(
                labelText: 'Wake Word',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.mic),
                helperText: 'e.g., "police", "ambulance", "fire"',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a wake word';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactNumberController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a contact number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveContact,
              icon: const Icon(Icons.save),
              label: const Text('Save Contact'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
