class AppSettings {
  final int countdownSeconds;
  final bool autoStartListening;
  final bool keepScreenOn;
  final String? porcupineAccessKey;

  AppSettings({
    this.countdownSeconds = 60, // Default 60 seconds
    this.autoStartListening = false, // Auto-start listening when app opens
    this.keepScreenOn = false, // Keep screen on while listening
    this.porcupineAccessKey, // Porcupine access key (optional)
  });

  Map<String, dynamic> toJson() {
    return {
      'countdownSeconds': countdownSeconds,
      'autoStartListening': autoStartListening,
      'keepScreenOn': keepScreenOn,
      'porcupineAccessKey': porcupineAccessKey,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      countdownSeconds: json['countdownSeconds'] ?? 60,
      autoStartListening: json['autoStartListening'] ?? false,
      keepScreenOn: json['keepScreenOn'] ?? false,
      porcupineAccessKey: json['porcupineAccessKey'],
    );
  }

  AppSettings copyWith({
    int? countdownSeconds,
    bool? autoStartListening,
    bool? keepScreenOn,
    String? porcupineAccessKey,
  }) {
    return AppSettings(
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      autoStartListening: autoStartListening ?? this.autoStartListening,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      porcupineAccessKey: porcupineAccessKey ?? this.porcupineAccessKey,
    );
  }
}
