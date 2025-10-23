import 'dart:math';

enum ContactType {
  police,
  hospital,
  fireStation,
  custom;

  String get displayName {
    switch (this) {
      case ContactType.police:
        return 'POLICE';
      case ContactType.hospital:
        return 'HOSPITAL';
      case ContactType.fireStation:
        return 'FIRE STATION';
      case ContactType.custom:
        return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case ContactType.police:
        return '🚓';
      case ContactType.hospital:
        return '🏥';
      case ContactType.fireStation:
        return '🚒';
      case ContactType.custom:
        return '📞';
    }
  }

  String get dbValue {
    switch (this) {
      case ContactType.police:
        return 'POLICE';
      case ContactType.hospital:
        return 'HOSPITAL';
      case ContactType.fireStation:
        return 'FIRE_STATION';
      case ContactType.custom:
        return 'CUSTOM';
    }
  }

  static ContactType fromDbValue(String value) {
    switch (value.toUpperCase()) {
      case 'POLICE':
        return ContactType.police;
      case 'HOSPITAL':
        return ContactType.hospital;
      case 'FIRE_STATION':
        return ContactType.fireStation;
      case 'CUSTOM':
        return ContactType.custom;
      default:
        return ContactType.custom;
    }
  }
}

class EmergencyContact {
  final String id;
  final String userId;
  final ContactType contactType;
  final String name;
  final String phoneNumber;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? placeId; // Google Places ID
  final bool isAiGenerated;
  final bool isCustom; // User-added manual contact
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    required this.id,
    required this.userId,
    required this.contactType,
    required this.name,
    required this.phoneNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.placeId,
    required this.isAiGenerated,
    this.isCustom = false,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contactType: ContactType.fromDbValue(json['contact_type'] as String),
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      address: json['address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      placeId: json['place_id'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool,
      isCustom: json['is_custom'] as bool? ?? false,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contact_type': contactType.dbValue,
      'name': name,
      'phone_number': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'place_id': placeId,
      'is_ai_generated': isAiGenerated,
      'is_custom': isCustom,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'contact_type': contactType.dbValue,
      'name': name,
      'phone_number': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'place_id': placeId,
      'is_ai_generated': isAiGenerated,
      'is_custom': isCustom,
      'is_active': isActive,
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? userId,
    ContactType? contactType,
    String? name,
    String? phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
    bool? isAiGenerated,
    bool? isCustom,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactType: contactType ?? this.contactType,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      isCustom: isCustom ?? this.isCustom,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate distance from given coordinates (in meters)
  double? distanceFrom(double? userLat, double? userLon) {
    if (userLat == null ||
        userLon == null ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    // Using Haversine formula
    const R = 6371000; // Earth's radius in meters
    final lat1 = userLat * (pi / 180);
    final lat2 = latitude! * (pi / 180);
    final dLat = (latitude! - userLat) * (pi / 180);
    final dLon = (longitude! - userLon) * (pi / 180);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));

    return R * c;
  }

  /// Get formatted distance string (e.g., "1.2 km", "850 m")
  String getDistanceString(double? userLat, double? userLon) {
    final distance = distanceFrom(userLat, userLon);
    if (distance == null) return 'Unknown distance';

    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Get source badge text
  String get sourceBadge =>
      isCustom ? 'Custom' : (isAiGenerated ? 'Google' : 'Manual');
}
