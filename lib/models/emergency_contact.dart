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
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
