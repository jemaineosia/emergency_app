import 'package:emergency_app/services/mic_probe_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Diagnostic screen to show detailed permission status
class PermissionDiagnosticScreen extends StatefulWidget {
  const PermissionDiagnosticScreen({super.key});

  @override
  State<PermissionDiagnosticScreen> createState() =>
      _PermissionDiagnosticScreenState();
}

class _PermissionDiagnosticScreenState
    extends State<PermissionDiagnosticScreen> {
  Map<String, String> _permissionStatus = {};
  String _testResult = '';
  bool _runningProbe = false;
  final _probe = MicProbeService();

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    final statuses = <String, String>{};

    // Check microphone
    final micStatus = await Permission.microphone.status;
    statuses['Microphone'] = _statusToString(micStatus);

    // Check speech
    final speechStatus = await Permission.speech.status;
    statuses['Speech Recognition'] = _statusToString(speechStatus);

    setState(() {
      _permissionStatus = statuses;
    });
  }

  String _statusToString(PermissionStatus status) {
    if (status.isGranted) return '✅ GRANTED';
    if (status.isDenied) return '❌ DENIED';
    if (status.isPermanentlyDenied) return '🔒 PERMANENTLY DENIED';
    if (status.isRestricted) return '⛔ RESTRICTED';
    if (status.isLimited) return '⚠️ LIMITED';
    return '❓ UNKNOWN';
  }

  Future<void> _testMicrophoneRequest() async {
    setState(() {
      _testResult = 'Requesting microphone permission...';
    });

    debugPrint('🔍 Testing microphone permission request...');
    final status = await Permission.microphone.request();
    debugPrint('🔍 Result: $status');

    setState(() {
      if (status.isGranted) {
        _testResult = '✅ SUCCESS! Microphone permission granted.';
      } else if (status.isPermanentlyDenied) {
        _testResult =
            '🔒 PERMANENTLY DENIED!\n\n'
            'iOS will NOT show permission dialog.\n'
            'The only fix is to DELETE the app and reinstall.\n\n'
            'This proves the issue is iOS security, not the permission_handler package.';
      } else if (status.isDenied) {
        _testResult =
            '❌ DENIED!\n\n'
            'User tapped "Don\'t Allow".\n'
            'You can try requesting again.';
      } else {
        _testResult = '❓ Unexpected status: $status';
      }
    });

    // Recheck all permissions
    await _checkAllPermissions();
  }

  Future<void> _testSpeechRequest() async {
    setState(() {
      _testResult = 'Requesting speech recognition permission...';
    });

    debugPrint('🔍 Testing speech recognition permission request...');
    final status = await Permission.speech.request();
    debugPrint('🔍 Result: $status');

    setState(() {
      if (status.isGranted) {
        _testResult = '✅ SUCCESS! Speech recognition permission granted.';
      } else if (status.isPermanentlyDenied) {
        _testResult =
            '🔒 PERMANENTLY DENIED!\n\n'
            'iOS will NOT show permission dialog.\n'
            'The only fix is to DELETE the app and reinstall.';
      } else if (status.isDenied) {
        _testResult =
            '❌ DENIED!\n\n'
            'User tapped "Don\'t Allow".\n'
            'You can try requesting again.';
      } else {
        _testResult = '❓ Unexpected status: $status';
      }
    });

    // Recheck all permissions
    await _checkAllPermissions();
  }

  Future<void> _runMicProbe() async {
    setState(() {
      _runningProbe = true;
      _testResult = 'Running microphone probe...';
    });

    final result = await _probe.runProbe();
    setState(() {
      _testResult = result;
      _runningProbe = false;
    });

    // Recheck statuses after probe
    await _checkAllPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Diagnostics'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🔍 PERMISSION DIAGNOSTIC TOOL',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This proves whether permissions are blocked by iOS',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Permission status cards
            const Text(
              'Current Permission Status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._permissionStatus.entries.map(
              (entry) => Card(
                color: entry.value.contains('PERMANENTLY')
                    ? Colors.red.shade50
                    : entry.value.contains('GRANTED')
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    entry.value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test buttons
            const Text(
              'Test Permission Requests:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _testMicrophoneRequest,
              icon: const Icon(Icons.mic),
              label: const Text('Test Microphone Request'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _runningProbe ? null : _runMicProbe,
              icon: const Icon(Icons.build_circle),
              label: Text(
                _runningProbe
                    ? 'Running probe...'
                    : 'Force iOS to Register Microphone',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _testSpeechRequest,
              icon: const Icon(Icons.record_voice_over),
              label: const Text('Test Speech Recognition Request'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Test result
            if (_testResult.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _testResult.contains('SUCCESS')
                      ? Colors.green.shade100
                      : _testResult.contains('PERMANENTLY')
                      ? Colors.red.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResult.contains('SUCCESS')
                        ? Colors.green
                        : _testResult.contains('PERMANENTLY')
                        ? Colors.red
                        : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Text(
                  _testResult,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What This Proves:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• If status is "🔒 PERMANENTLY DENIED":\n'
                    '  → permission_handler IS working correctly\n'
                    '  → iOS is blocking permission dialogs\n'
                    '  → No popup will appear when you tap test buttons\n'
                    '  → ONLY fix: Delete app from iPhone and reinstall\n\n'
                    '• If status is "❌ DENIED":\n'
                    '  → You can request again\n'
                    '  → Popup WILL appear\n\n'
                    '• If status is "✅ GRANTED":\n'
                    '  → Everything working!\n'
                    '  → No need to request again',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open iPhone Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
