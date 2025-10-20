class EmergencyContact {
  final String id;
  final String name;
  final String type; // police, ambulance, fire station
  final String wakeWord; // e.g., "police", "ambulance", "fire"
  final String address;
  final String contactNumber;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.type,
    required this.wakeWord,
    required this.address,
    required this.contactNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'wakeWord': wakeWord,
      'address': address,
      'contactNumber': contactNumber,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      wakeWord: json['wakeWord'],
      address: json['address'],
      contactNumber: json['contactNumber'],
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? type,
    String? wakeWord,
    String? address,
    String? contactNumber,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      wakeWord: wakeWord ?? this.wakeWord,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
    );
  }
}
