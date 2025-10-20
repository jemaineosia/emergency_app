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

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    _countdownSeconds = provider.settings.countdownSeconds;
  }

  void _saveSettings() {
    final provider = Provider.of<EmergencyProvider>(context, listen: false);
    provider.updateSettings(AppSettings(countdownSeconds: _countdownSeconds));
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
