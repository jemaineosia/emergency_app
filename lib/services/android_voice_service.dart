import 'dart:io';

import 'package:flutter/services.dart';

/// Android-specific service for background voice listening and lock screen activation
class AndroidVoiceService {
  static const platform = MethodChannel(
    'com.skilla.emergencyApp/voice_service',
  );

  /// Start the foreground service for background voice listening
  /// Returns true if service started successfully
  static Future<bool> startVoiceService() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await platform.invokeMethod('startVoiceService');
      print('✅ Android voice service started');
      return result ?? false;
    } catch (e) {
      print('❌ Failed to start voice service: $e');
      return false;
    }
  }

  /// Stop the foreground service
  /// Returns true if service stopped successfully
  static Future<bool> stopVoiceService() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await platform.invokeMethod('stopVoiceService');
      print('✅ Android voice service stopped');
      return result ?? false;
    } catch (e) {
      print('❌ Failed to stop voice service: $e');
      return false;
    }
  }

  /// Allow app to show on lock screen and turn screen on
  /// Returns true if settings applied successfully
  static Future<bool> showOnLockScreen() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await platform.invokeMethod('showOnLockScreen');
      print('✅ Lock screen display enabled');
      return result ?? false;
    } catch (e) {
      print('❌ Failed to enable lock screen display: $e');
      return false;
    }
  }
}
