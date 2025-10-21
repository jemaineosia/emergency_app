import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_screen.dart';
import 'permission_diagnostic_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isChecking = true;
  bool _microphoneGranted = false;
  bool _speechGranted = false;
  bool _isPermanentlyDenied = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isChecking = true;
      _errorMessage = '';
    });

    try {
      // Check microphone permission
      var micStatus = await Permission.microphone.status;
      debugPrint('🎤 Microphone permission status: $micStatus');

      // Check speech recognition permission
      var speechStatus = await Permission.speech.status;
      debugPrint('🗣️  Speech recognition status: $speechStatus');

      final isPermanent =
          micStatus.isPermanentlyDenied || speechStatus.isPermanentlyDenied;

      setState(() {
        _microphoneGranted = micStatus.isGranted;
        _speechGranted = speechStatus.isGranted;
        _isPermanentlyDenied = isPermanent;
        _isChecking = false;
      });

      // If both granted, navigate to home
      if (_microphoneGranted && _speechGranted) {
        _navigateToHome();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking permissions: $e';
        _isChecking = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isChecking = true;
      _errorMessage = '';
    });

    // Wait a moment for iOS to be fully ready to show permission dialogs
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Request microphone permission
      debugPrint('🔑 Requesting microphone permission...');
      final micStatus = await Permission.microphone.request();
      debugPrint('🎤 Microphone result: $micStatus');

      // Small delay between permission requests
      await Future.delayed(const Duration(milliseconds: 300));

      // Request speech recognition permission
      debugPrint('🔑 Requesting speech recognition permission...');
      final speechStatus = await Permission.speech.request();
      debugPrint('🗣️ Speech result: $speechStatus');

      setState(() {
        _microphoneGranted = micStatus.isGranted;
        _speechGranted = speechStatus.isGranted;
        _isChecking = false;
      });

      if (_microphoneGranted && _speechGranted) {
        _navigateToHome();
      } else {
        setState(() {
          _errorMessage = _buildErrorMessage(micStatus, speechStatus);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error requesting permissions: $e';
        _isChecking = false;
      });
    }
  }

  String _buildErrorMessage(
    PermissionStatus micStatus,
    PermissionStatus speechStatus,
  ) {
    final List<String> denied = [];

    if (!micStatus.isGranted) {
      denied.add('Microphone');
    }
    if (!speechStatus.isGranted) {
      denied.add('Speech Recognition');
    }

    if (denied.isEmpty) return '';

    if (micStatus.isPermanentlyDenied || speechStatus.isPermanentlyDenied) {
      return '⚠️ PERMISSIONS PERMANENTLY DENIED ⚠️\n\n'
          'The app "${denied.join(' and ')}" will NOT appear in iPhone Settings.\n\n'
          '🔧 TO FIX THIS:\n'
          '1. DELETE this app from your iPhone:\n'
          '   • Long press app icon\n'
          '   • Tap "Remove App" → "Delete App"\n\n'
          '2. Reinstall from Xcode/Flutter\n\n'
          '3. Grant permissions when prompted\n\n'
          'This is an iOS security feature. Permissions can only be reset by deleting and reinstalling the app.';
    }

    // iOS typically shows the permission prompt only once. After the first deny,
    // calling request() again often returns `denied` without showing a dialog.
    // In that case, user must enable the toggle in iOS Settings.
    return '${denied.join(' and ')} permission denied.\n\n'
        'On iPhone, if you denied once, the system may not show the popup again.\n'
        'Please enable in Settings and come back here to recheck:\n\n'
        '• Settings → Privacy & Security → Microphone → Emergency App → ON\n'
        '• Settings → Privacy & Security → Speech Recognition → Emergency App → ON\n\n'
        'Alternatively: Settings → Emergency App → Microphone (toggle ON).';
  }

  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, size: 100, color: Colors.red),
              const SizedBox(height: 32),
              const Text(
                'Permissions Required',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This app needs microphone and speech recognition permissions to detect emergency wake words and respond to voice commands.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildPermissionRow(
                'Microphone',
                _microphoneGranted,
                'Listen for "Jarvis" wake word',
              ),
              const SizedBox(height: 16),
              _buildPermissionRow(
                'Speech Recognition',
                _speechGranted,
                'Understand voice commands',
              ),
              const SizedBox(height: 32),
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isChecking)
                const CircularProgressIndicator()
              else if (!_microphoneGranted || !_speechGranted) ...[
                if (_isPermanentlyDenied) ...[
                  // Show prominent warning for permanently denied
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 60,
                          color: Colors.orange.shade900,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'DELETE APP REQUIRED',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Permissions are locked by iOS.\nOnly deleting and reinstalling can fix this.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('How to Fix'),
                          content: const SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '1. CLOSE this app',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '2. On your iPhone Home Screen:\n'
                                  '   • Long press this app icon\n'
                                  '   • Tap "Remove App"\n'
                                  '   • Tap "Delete App"\n'
                                  '   • Tap "Delete" to confirm',
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '3. Reinstall from Xcode/Flutter',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '4. When prompted, tap "Allow" for both Microphone and Speech Recognition',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got It'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('How to Delete & Reinstall'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  // Normal permission request flow
                  ElevatedButton.icon(
                    onPressed: _requestPermissions,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Grant Permissions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Open iPhone Settings'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _checkPermissions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('I enabled it in Settings — Recheck'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PermissionDiagnosticScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Run Diagnostic Test'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    foregroundColor: Colors.blue,
                  ),
                ),
              ] else
                ElevatedButton.icon(
                  onPressed: _navigateToHome,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String title, bool granted, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: granted ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: granted ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: granted ? Colors.green : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
