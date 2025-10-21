import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// MicProbeService
///
/// Starts a very short audio recording to ensure iOS registers the app
/// under Settings > Privacy & Security > Microphone. This often forces the
/// permission toggle to appear if it wasn't listed yet.
class MicProbeService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Attempts to trigger the iOS microphone permission and registration.
  /// Returns a human-readable result string for diagnostics UI.
  Future<String> runProbe() async {
    try {
      // Ensure we request permissions explicitly first
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        return 'Microphone permission not granted (status: $mic).';
      }

      // Prepare and start a very short recording
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        return 'Recorder reports no permission (post-grant).';
      }

      // No direct isRecording() in v6 until start; just ensure stopped

      // Build a temporary file path for the short recording
      final tempPath =
          '${Directory.systemTemp.path}/mic_probe_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: tempPath,
      );

      // Let it run very briefly to initialize AVAudioSession
      await Future.delayed(const Duration(milliseconds: 500));

      final path = await _recorder.stop();
      debugPrint('MicProbeService: recorded to $path');

      return 'Probe completed. App should now appear under Microphone settings.';
    } catch (e) {
      debugPrint('MicProbeService error: $e');
      try {
        await _recorder.stop();
      } catch (_) {}
      return 'Probe failed: $e';
    }
  }
}
