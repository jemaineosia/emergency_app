import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/emergency_contact.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: ${error.errorMsg}'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );

    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(EmergencyContact?) onWakeWordDetected,
    required List<EmergencyContact> contacts,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        onResult(text);

        // Check for wake word
        if (text.isNotEmpty) {
          final contact = _findContactByWakeWord(text, contacts);
          if (contact != null) {
            onWakeWordDetected(contact);
          }
        }
      },
      listenMode: stt.ListenMode.confirmation,
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: false,
      listenFor: const Duration(seconds: 30),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;

  EmergencyContact? _findContactByWakeWord(
    String text,
    List<EmergencyContact> contacts,
  ) {
    final lowerText = text.toLowerCase();

    // Check for "help emergency" followed by wake word
    if (lowerText.contains('help emergency')) {
      for (var contact in contacts) {
        if (lowerText.contains(contact.wakeWord.toLowerCase())) {
          return contact;
        }
      }
    }

    return null;
  }

  void dispose() {
    _speech.stop();
  }
}
