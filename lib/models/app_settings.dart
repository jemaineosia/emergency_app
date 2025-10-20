class AppSettings {
  final int countdownSeconds;

  AppSettings({
    this.countdownSeconds = 60, // Default 60 seconds
  });

  Map<String, dynamic> toJson() {
    return {'countdownSeconds': countdownSeconds};
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(countdownSeconds: json['countdownSeconds'] ?? 60);
  }

  AppSettings copyWith({int? countdownSeconds}) {
    return AppSettings(
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    );
  }
}
