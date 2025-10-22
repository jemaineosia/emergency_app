class UserSettings {
  final String userId;
  final int updateIntervalMinutes; // Background update frequency
  final bool autoUpdateEnabled;
  final double locationRadiusKm; // Search radius for emergency services
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.userId,
    this.updateIntervalMinutes = 60, // Default: 1 hour
    this.autoUpdateEnabled = true,
    this.locationRadiusKm = 10.0, // Default: 10km
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
    };
  }

  UserSettings copyWith({
    String? userId,
    int? updateIntervalMinutes,
    bool? autoUpdateEnabled,
    double? locationRadiusKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      updateIntervalMinutes:
          updateIntervalMinutes ?? this.updateIntervalMinutes,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      locationRadiusKm: locationRadiusKm ?? this.locationRadiusKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
