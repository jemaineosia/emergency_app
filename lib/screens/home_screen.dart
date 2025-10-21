import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/emergency_contact.dart';
import '../providers/emergency_provider.dart';
import '../services/android_voice_service.dart';
import '../services/speech_service.dart';
import 'add_edit_contact_screen.dart';
import 'countdown_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndInitialize();

    // Start Android foreground service if on Android
    if (Platform.isAndroid) {
      _startAndroidBackgroundService();
    }
  }

  Future<void> _startAndroidBackgroundService() async {
    final started = await AndroidVoiceService.startVoiceService();
    if (started) {
      await AndroidVoiceService.showOnLockScreen();
      debugPrint('✅ Android background voice service active');
      debugPrint('✅ App can now work on lock screen');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Voice listening active on lock screen'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _requestPermissionsAndInitialize() async {
    // Request permissions on first load
    await _requestPermissions();

    // Wait for the first frame to render
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      final provider = Provider.of<EmergencyProvider>(context, listen: false);

      // Auto-start listening if enabled in settings
      // Note: Always start listening for emergency readiness, even without contacts
      if (provider.settings.autoStartListening) {
        await _startListening();
      }

      // Keep screen on if enabled
      if (provider.settings.keepScreenOn) {
        WakelockPlus.enable();
      }
    }
  }

  Future<void> _requestPermissions() async {
    // Request microphone permission
    final micStatus = await Permission.microphone.request();
    debugPrint('🎤 Microphone permission: $micStatus');

    // Request speech recognition permission
    final speechStatus = await Permission.speech.request();
    debugPrint('🗣️ Speech recognition permission: $speechStatus');

    if (!micStatus.isGranted || !speechStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Microphone and speech permissions are required for voice commands',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final provider = Provider.of<EmergencyProvider>(context, listen: false);

    if (state == AppLifecycleState.resumed) {
      // App came to foreground
      if (provider.settings.autoStartListening && !_isListening) {
        _startListening();
      }
      if (provider.settings.keepScreenOn) {
        WakelockPlus.enable();
      }
    } else if (state == AppLifecycleState.paused) {
      // App went to background
      if (provider.settings.keepScreenOn) {
        WakelockPlus.disable();
      }
    }
  }

  @override
  void dispose() {
    // Stop Android service when app closes
    if (Platform.isAndroid) {
      AndroidVoiceService.stopVoiceService();
    }

    WidgetsBinding.instance.removeObserver(this);
    _speechService.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _startListening() async {
    final provider = Provider.of<EmergencyProvider>(context, listen: false);

    final initialized = await _speechService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
    });
    provider.setListening(true);

    await _speechService.startListening(
      contacts: provider.contacts,
      onResult: (text) {
        setState(() {
          _lastWords = text;
        });
        provider.setLastRecognizedText(text);
      },
      onWakeWordDetected: (contact) {
        if (contact != null) {
          _handleWakeWordDetected(contact);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    final provider = Provider.of<EmergencyProvider>(context, listen: false);

    await _speechService.stopListening();
    setState(() {
      _isListening = false;
      _lastWords = '';
    });
    provider.setListening(false);
    provider.setLastRecognizedText('');
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  void _handleWakeWordDetected(EmergencyContact contact) async {
    await _speechService.stopListening();
    setState(() {
      _isListening = false;
      _lastWords = '';
    });

    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    provider.setListening(false);
    provider.setLastRecognizedText('');

    if (mounted) {
      // Navigate to countdown screen and wait for it to complete
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CountdownScreen(
            contact: contact,
            countdownSeconds: provider.settings.countdownSeconds,
          ),
        ),
      );

      // After countdown screen closes, automatically resume listening if auto-start is enabled
      if (mounted && provider.settings.autoStartListening) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _startListening();
      }
    }
  }

  void _navigateToAddContact() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditContactScreen()),
    );
  }

  void _navigateToEditContact(EmergencyContact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(contact: contact),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _deleteContact(String id) {
    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteContact(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Voice Control Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Voice Control',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _toggleListening,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? Colors.red : Colors.blue,
                          boxShadow: _isListening
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isListening ? 'Listening...' : 'Tap to activate',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_lastWords.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '"$_lastWords"',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Say: "help emergency [wake word]"',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // Contacts List Section
              Expanded(
                child: provider.contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contacts,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No emergency contacts',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add a contact',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: provider.contacts.length,
                        itemBuilder: (context, index) {
                          final contact = provider.contacts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTypeColor(contact.type),
                                child: Icon(
                                  _getTypeIcon(contact.type),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                contact.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type: ${contact.type.toUpperCase()}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Wake word: "${contact.wakeWord}"',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  Text(
                                    'Phone: ${contact.contactNumber}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _navigateToEditContact(contact);
                                  } else if (value == 'delete') {
                                    _deleteContact(contact.id);
                                  }
                                },
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddContact,
        tooltip: 'Add Contact',
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'police':
        return Colors.blue;
      case 'ambulance':
        return Colors.red;
      case 'fire station':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'police':
        return Icons.local_police;
      case 'ambulance':
        return Icons.local_hospital;
      case 'fire station':
        return Icons.local_fire_department;
      default:
        return Icons.emergency;
    }
  }
}
