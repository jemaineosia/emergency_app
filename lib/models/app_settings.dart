class AppSettings {
  final int countdownSeconds;
  final bool autoStartListening;
  final bool keepScreenOn;
  final String? porcupineAccessKey;

  AppSettings({
    this.countdownSeconds = 5, // Default 5 seconds
    this.autoStartListening =
        true, // Auto-start listening when app opens (hands-free mode)
    this.keepScreenOn = true, // Keep screen on while listening (emergency app)
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
      countdownSeconds: json['countdownSeconds'] ?? 5,
      autoStartListening: json['autoStartListening'] ?? true,
      keepScreenOn: json['keepScreenOn'] ?? true,
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
