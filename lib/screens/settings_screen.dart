import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/emergency_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _countdownSeconds;
  late bool _autoStartListening;
  late bool _keepScreenOn;
  late TextEditingController _accessKeyController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    _countdownSeconds = provider.settings.countdownSeconds;
    _autoStartListening = provider.settings.autoStartListening;
    _keepScreenOn = provider.settings.keepScreenOn;
    _accessKeyController = TextEditingController(
      text: provider.settings.porcupineAccessKey ?? '',
    );
  }

  @override
  void dispose() {
    _accessKeyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    provider.updateSettings(
      AppSettings(
        countdownSeconds: _countdownSeconds,
        autoStartListening: _autoStartListening,
        keepScreenOn: _keepScreenOn,
        porcupineAccessKey: _accessKeyController.text.isEmpty
            ? null
            : _accessKeyController.text,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Countdown Timer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Time before emergency call is placed',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 30, label: Text('30 sec')),
                      ButtonSegment(value: 60, label: Text('60 sec')),
                    ],
                    selected: {_countdownSeconds},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _countdownSeconds = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current: $_countdownSeconds seconds',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Listening Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Auto-Start Listening'),
                    subtitle: const Text(
                      'Automatically start listening when app opens',
                    ),
                    value: _autoStartListening,
                    onChanged: (value) {
                      setState(() {
                        _autoStartListening = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Keep Screen On'),
                    subtitle: const Text(
                      'Prevent screen from turning off while listening',
                    ),
                    value: _keepScreenOn,
                    onChanged: (value) {
                      setState(() {
                        _keepScreenOn = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Porcupine Wake Word',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Chip(
                        label: Text('Optional', style: TextStyle(fontSize: 10)),
                        backgroundColor: Colors.orange,
                        labelStyle: TextStyle(color: Colors.white),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable always-on wake word detection (requires free access key)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accessKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Porcupine Access Key',
                      hintText: 'Get free key from picovoice.ai/console',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                      helperText: 'Sign up at console.picovoice.ai',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      // Open Picovoice console in browser
                      // This would require url_launcher which is already in dependencies
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Get Access Key'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to Use',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    '1.',
                    'Add emergency contacts with wake words',
                  ),
                  _buildInstructionItem(
                    '2.',
                    'Tap the microphone button to start listening',
                  ),
                  _buildInstructionItem(
                    '3.',
                    'Say "help emergency" followed by the wake word',
                  ),
                  _buildInstructionItem(
                    '4.',
                    'Example: "help emergency police"',
                  ),
                  _buildInstructionItem(
                    '5.',
                    'Cancel the call during countdown if needed',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
