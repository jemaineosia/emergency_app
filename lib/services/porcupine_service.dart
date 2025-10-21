import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

/// Porcupine Wake Word Detection Service
///
/// Provides offline, always-on wake word detection
/// Current wake word: "JARVIS"
class PorcupineService {
  PorcupineManager? _porcupineManager;
  bool _isListening = false;

  bool get isListening => _isListening;

  /// Initialize Porcupine with built-in keyword "jarvis"
  Future<bool> initialize({
    required Function(int) onWakeWordDetected,
    required String accessKey,
  }) async {
    if (accessKey.isEmpty) {
      debugPrint('⚠️  Access key is empty');
      return false;
    }

    // Request microphone permission
    debugPrint('🔑 Requesting microphone permission...');
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('❌ Microphone permission denied');
      return false;
    }
    debugPrint('✅ Microphone permission granted');

    // Request speech recognition permission (for iOS)
    final speechStatus = await Permission.speech.request();
    if (!speechStatus.isGranted) {
      debugPrint('⚠️  Speech recognition permission denied');
      // Don't return false - Porcupine might still work without it
    }

    try {
      debugPrint('🎤 Initializing Porcupine...');

      _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
        accessKey,
        [BuiltInKeyword.JARVIS],
        (keywordIndex) {
          debugPrint('🚨 Wake word "Jarvis" detected!');
          onWakeWordDetected(keywordIndex);
        },
        errorCallback: (error) {
          debugPrint('❌ Error: $error');
        },
      );

      debugPrint('✅ Porcupine ready! Say "Jarvis" to activate');
      return true;
    } catch (e) {
      debugPrint('❌ Init error: $e');
      return false;
    }
  }

  Future<bool> startListening() async {
    if (_porcupineManager == null) {
      debugPrint('⚠️  Not initialized');
      return false;
    }

    try {
      await _porcupineManager!.start();
      _isListening = true;
      debugPrint('🎤 Listening for "Jarvis"...');
      return true;
    } catch (e) {
      debugPrint('❌ Start error: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_porcupineManager == null) return;

    try {
      await _porcupineManager!.stop();
      _isListening = false;
      debugPrint('🛑 Stopped');
    } catch (e) {
      debugPrint('⚠️  Stop error: $e');
    }
  }

  Future<void> dispose() async {
    await stopListening();
    _porcupineManager?.delete();
    _porcupineManager = null;
  }
}
