class UpdateHistory {
  final String id;
  final String userId;
  final String contactId;
  final String? oldPhoneNumber;
  final String? newPhoneNumber;
  final String? oldAddress;
  final String? newAddress;
  final double? latitude;
  final double? longitude;
  final String
  updateReason; // 'location_change', 'manual_update', 'scheduled_update'
  final DateTime createdAt;

  UpdateHistory({
    required this.id,
    required this.userId,
    required this.contactId,
    this.oldPhoneNumber,
    this.newPhoneNumber,
    this.oldAddress,
    this.newAddress,
    this.latitude,
    this.longitude,
    required this.updateReason,
    required this.createdAt,
  });

  factory UpdateHistory.fromJson(Map<String, dynamic> json) {
    return UpdateHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contactId: json['contact_id'] as String,
      oldPhoneNumber: json['old_phone_number'] as String?,
      newPhoneNumber: json['new_phone_number'] as String?,
      oldAddress: json['old_address'] as String?,
      newAddress: json['new_address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      updateReason: json['update_reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contact_id': contactId,
      'old_phone_number': oldPhoneNumber,
      'new_phone_number': newPhoneNumber,
      'old_address': oldAddress,
      'new_address': newAddress,
      'latitude': latitude,
      'longitude': longitude,
      'update_reason': updateReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'contact_id': contactId,
      'old_phone_number': oldPhoneNumber,
      'new_phone_number': newPhoneNumber,
      'old_address': oldAddress,
      'new_address': newAddress,
      'latitude': latitude,
      'longitude': longitude,
      'update_reason': updateReason,
    };
  }
}
