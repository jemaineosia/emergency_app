class UserSettings {
  final String userId;
  final int updateIntervalMinutes; // Background update frequency
  final bool autoUpdateEnabled;
  final double locationRadiusKm; // Search radius for emergency services
  final String fallbackNumber; // Fallback emergency number (e.g., 911, 999)
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.userId,
    this.updateIntervalMinutes = 60, // Default: 1 hour
    this.autoUpdateEnabled = true,
    this.locationRadiusKm = 10.0, // Default: 10km
    this.fallbackNumber = '911', // Default: 911
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'] as String,
      updateIntervalMinutes: json['update_interval_minutes'] as int? ?? 60,
      autoUpdateEnabled: json['auto_update_enabled'] as bool? ?? true,
      locationRadiusKm:
          (json['location_radius_km'] as num?)?.toDouble() ?? 10.0,
      fallbackNumber: json['fallback_number'] as String? ?? '911',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'update_interval_minutes': updateIntervalMinutes,
      'auto_update_enabled': autoUpdateEnabled,
      'location_radius_km': locationRadiusKm,
      'fallback_number': fallbackNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'update_interval_minutes': updateIntervalMinutes,
      'auto_update_enabled': autoUpdateEnabled,
      'location_radius_km': locationRadiusKm,
      'fallback_number': fallbackNumber,
    };
  }

  UserSettings copyWith({
    String? userId,
    int? updateIntervalMinutes,
    bool? autoUpdateEnabled,
    double? locationRadiusKm,
    String? fallbackNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      updateIntervalMinutes:
          updateIntervalMinutes ?? this.updateIntervalMinutes,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      locationRadiusKm: locationRadiusKm ?? this.locationRadiusKm,
      fallbackNumber: fallbackNumber ?? this.fallbackNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
