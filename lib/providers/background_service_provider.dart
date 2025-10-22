import 'package:flutter/foundation.dart';

import '../services/background_service.dart';

/// Provider for managing background service
class BackgroundServiceProvider extends ChangeNotifier {
  final BackgroundService _backgroundService = BackgroundService.instance;

  bool _isEnabled = false;
  int _updateIntervalMinutes = 60;
  bool _isScheduling = false;
  String? _error;

  // ==================== Getters ====================

  bool get isEnabled => _isEnabled;
  int get updateIntervalMinutes => _updateIntervalMinutes;
  bool get isScheduling => _isScheduling;
  String? get error => _error;

  // ==================== Initialize ====================

  /// Initialize and check status
  Future<void> initialize() async {
    try {
      _isEnabled = await _backgroundService.isEnabled();
      notifyListeners();
    } catch (e) {
      _error = 'Error initializing background service: $e';
      notifyListeners();
    }
  }

  // ==================== Control Background Service ====================

  /// Enable background updates
  Future<bool> enable({int? intervalMinutes}) async {
    try {
      _isScheduling = true;
      _error = null;
      notifyListeners();

      final interval = intervalMinutes ?? _updateIntervalMinutes;

      await _backgroundService.schedulePeriodicUpdate(
        intervalMinutes: interval,
      );

      _isEnabled = true;
      _updateIntervalMinutes = interval;
      _isScheduling = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Error enabling background service: $e';
      _isScheduling = false;
      notifyListeners();
      return false;
    }
  }

  /// Disable background updates
  Future<bool> disable() async {
    try {
      _isScheduling = true;
      _error = null;
      notifyListeners();

      await _backgroundService.cancelPeriodicUpdate();

      _isEnabled = false;
      _isScheduling = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Error disabling background service: $e';
      _isScheduling = false;
      notifyListeners();
      return false;
    }
  }

  /// Update schedule with new interval
  Future<bool> updateInterval(int minutes) async {
    if (minutes < 15) {
      _error = 'Interval must be at least 15 minutes';
      notifyListeners();
      return false;
    }

    try {
      _isScheduling = true;
      _error = null;
      notifyListeners();

      if (_isEnabled) {
        await _backgroundService.schedulePeriodicUpdate(
          intervalMinutes: minutes,
        );
      }

      _updateIntervalMinutes = minutes;
      _isScheduling = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Error updating interval: $e';
      _isScheduling = false;
      notifyListeners();
      return false;
    }
  }

  /// Trigger immediate update
  Future<bool> triggerImmediateUpdate() async {
    try {
      _isScheduling = true;
      _error = null;
      notifyListeners();

      await _backgroundService.scheduleImmediateUpdate();

      _isScheduling = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Error triggering immediate update: $e';
      _isScheduling = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel all background tasks
  Future<bool> cancelAll() async {
    try {
      _isScheduling = true;
      _error = null;
      notifyListeners();

      await _backgroundService.cancelAllTasks();

      _isEnabled = false;
      _isScheduling = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Error cancelling tasks: $e';
      _isScheduling = false;
      notifyListeners();
      return false;
    }
  }

  /// Update schedule from user settings
  Future<bool> updateFromSettings() async {
    try {
      _isScheduling = true;
      _error = null;
      notifyListeners();

      await _backgroundService.updateSchedule();

      // Refresh status
      _isEnabled = await _backgroundService.isEnabled();

      _isScheduling = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Error updating from settings: $e';
      _isScheduling = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== Utility Methods ====================

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get status message
  String getStatusMessage() {
    if (_isEnabled) {
      return 'Background updates every $_updateIntervalMinutes minutes';
    } else {
      return 'Background updates disabled';
    }
  }

  /// Format interval for display
  String formatInterval(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes == 60) {
      return '1 hour';
    } else {
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hours';
    }
  }
}
