class DeviceModel {
  final String id; // UUID primary key
  final String deviceNumber; // Required device identifier
  final String? fishermanUid; // Fisherman UUID
  final String? fishermanDisplayId; // Human-readable fisherman ID
  final String? fishermanFirstName; // Fisherman first name (denormalized)
  final String? fishermanMiddleName; // Fisherman middle name (denormalized)
  final String? fishermanLastName; // Fisherman last name (denormalized)
  final String? fishermanName; // Fisherman full name (denormalized)
  final String? fishermanEmail; // Fisherman email (denormalized)
  final String? fishermanPhone; // Fisherman phone (denormalized)
  final String? fishermanUserType; // Fisherman user type (denormalized)
  final String? fishermanAddress; // Fisherman address (denormalized)
  final String? fishermanFishingArea; // Fisherman fishing area (denormalized)
  final String? fishermanEmergencyContactPerson; // Fisherman emergency contact (denormalized)
  final String? fishermanProfilePictureUrl; // Fisherman profile picture (denormalized)
  final String? fishermanProfileImageUrl; // Fisherman profile image (denormalized)
  final bool isActive; // Device status
  final DateTime createdAt; // Creation timestamp
  final DateTime? lastUsed; // Last usage timestamp
  final String? deviceType; // Optional device type (e.g., 'SOS', 'GPS', 'Emergency')
  final String? description; // Optional device description
  final String? location; // Optional device location
  final String? status; // Device status (active, inactive, maintenance, etc.)
  final double? latitude; // Device latitude for map display
  final double? longitude; // Device longitude for map display
  final bool showOnMap; // Whether to display this device on the map
  final bool isSendingSignal; // Whether device is currently sending help signal
  final DateTime? lastSignalSent; // When the last help signal was sent
  final String? signalMessage; // Message from the device when sending signal

  DeviceModel({
    required this.id,
    required this.deviceNumber,
    this.fishermanUid,
    this.fishermanDisplayId,
    this.fishermanFirstName,
    this.fishermanMiddleName,
    this.fishermanLastName,
    this.fishermanName,
    this.fishermanEmail,
    this.fishermanPhone,
    this.fishermanUserType,
    this.fishermanAddress,
    this.fishermanFishingArea,
    this.fishermanEmergencyContactPerson,
    this.fishermanProfilePictureUrl,
    this.fishermanProfileImageUrl,
    required this.isActive,
    required this.createdAt,
    this.lastUsed,
    this.deviceType,
    this.description,
    this.location,
    this.status,
    this.latitude,
    this.longitude,
    this.showOnMap = false,
    this.isSendingSignal = false,
    this.lastSignalSent,
    this.signalMessage,
  });

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel.fromJson(map);
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    // Parse createdAt
    DateTime createdDate;
    if (json['createdAt'] is String) {
      createdDate = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    } else if (json['createdAt'] is DateTime) {
      createdDate = json['createdAt'];
    } else {
      createdDate = DateTime.now();
    }

    // Parse lastUsed
    DateTime? lastUsedDate;
    if (json['lastUsed'] is String) {
      lastUsedDate = DateTime.tryParse(json['lastUsed']);
    } else if (json['lastUsed'] is DateTime) {
      lastUsedDate = json['lastUsed'];
    }

    // Parse lastSignalSent
    DateTime? lastSignalSentDate;
    if (json['lastSignalSent'] is String) {
      lastSignalSentDate = DateTime.tryParse(json['lastSignalSent']);
    } else if (json['lastSignalSent'] is DateTime) {
      lastSignalSentDate = json['lastSignalSent'];
    }

    return DeviceModel(
      id: json['id'] ?? '',
      deviceNumber: json['deviceNumber'] ?? '',
      fishermanUid: json['fishermanUid'] ?? json['fisherman_uid'],
      fishermanDisplayId: json['fishermanDisplayId'] ?? json['fisherman_display_id'],
      fishermanFirstName: json['fishermanFirstName'] ?? json['fisherman_first_name'],
      fishermanMiddleName: json['fishermanMiddleName'] ?? json['fisherman_middle_name'],
      fishermanLastName: json['fishermanLastName'] ?? json['fisherman_last_name'],
      fishermanName: json['fishermanName'] ?? json['fisherman_name'],
      fishermanEmail: json['fishermanEmail'] ?? json['fisherman_email'],
      fishermanPhone: json['fishermanPhone'] ?? json['fisherman_phone'],
      fishermanUserType: json['fishermanUserType'] ?? json['fisherman_user_type'],
      fishermanAddress: json['fishermanAddress'] ?? json['fisherman_address'],
      fishermanFishingArea: json['fishermanFishingArea'] ?? json['fisherman_fishing_area'],
      fishermanEmergencyContactPerson: json['fishermanEmergencyContactPerson'] ?? json['fisherman_emergency_contact_person'],
      fishermanProfilePictureUrl: json['fishermanProfilePictureUrl'] ?? json['fisherman_profile_picture_url'],
      fishermanProfileImageUrl: json['fishermanProfileImageUrl'] ?? json['fisherman_profile_image_url'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: createdDate,
      lastUsed: lastUsedDate,
      deviceType: json['deviceType'] ?? json['device_type'],
      description: json['description'],
      location: json['location'],
      status: json['status'] ?? 'active',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      showOnMap: json['showOnMap'] ?? json['show_on_map'] ?? false,
      isSendingSignal: json['isSendingSignal'] ?? json['is_sending_signal'] ?? false,
      lastSignalSent: lastSignalSentDate,
      signalMessage: json['signalMessage'] ?? json['signal_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceNumber': deviceNumber,
      'fishermanUid': fishermanUid,
      'fishermanDisplayId': fishermanDisplayId,
      'fishermanFirstName': fishermanFirstName,
      'fishermanMiddleName': fishermanMiddleName,
      'fishermanLastName': fishermanLastName,
      'fishermanName': fishermanName,
      'fishermanEmail': fishermanEmail,
      'fishermanPhone': fishermanPhone,
      'fishermanUserType': fishermanUserType,
      'fishermanAddress': fishermanAddress,
      'fishermanFishingArea': fishermanFishingArea,
      'fishermanEmergencyContactPerson': fishermanEmergencyContactPerson,
      'fishermanProfilePictureUrl': fishermanProfilePictureUrl,
      'fishermanProfileImageUrl': fishermanProfileImageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'deviceType': deviceType,
      'description': description,
      'location': location,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'showOnMap': showOnMap,
      'isSendingSignal': isSendingSignal,
      'lastSignalSent': lastSignalSent?.toIso8601String(),
      'signalMessage': signalMessage,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_number': deviceNumber,
      'fisherman_uid': fishermanUid,
      'fisherman_display_id': fishermanDisplayId,
      'fisherman_first_name': fishermanFirstName,
      'fisherman_middle_name': fishermanMiddleName,
      'fisherman_last_name': fishermanLastName,
      'fisherman_name': fishermanName,
      'fisherman_email': fishermanEmail,
      'fisherman_phone': fishermanPhone,
      'fisherman_user_type': fishermanUserType,
      'fisherman_address': fishermanAddress,
      'fisherman_fishing_area': fishermanFishingArea,
      'fisherman_emergency_contact_person': fishermanEmergencyContactPerson,
      'fisherman_profile_picture_url': fishermanProfilePictureUrl,
      'fisherman_profile_image_url': fishermanProfileImageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_used': lastUsed?.toIso8601String(),
      'device_type': deviceType,
      'description': description,
      'location': location,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'show_on_map': showOnMap,
      'is_sending_signal': isSendingSignal,
      'last_signal_sent': lastSignalSent?.toIso8601String(),
      'signal_message': signalMessage,
    };
  }

  DeviceModel copyWith({
    String? id,
    String? deviceNumber,
    String? fishermanUid,
    String? fishermanDisplayId,
    String? fishermanFirstName,
    String? fishermanMiddleName,
    String? fishermanLastName,
    String? fishermanName,
    String? fishermanEmail,
    String? fishermanPhone,
    String? fishermanUserType,
    String? fishermanAddress,
    String? fishermanFishingArea,
    String? fishermanEmergencyContactPerson,
    String? fishermanProfilePictureUrl,
    String? fishermanProfileImageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUsed,
    String? deviceType,
    String? description,
    String? location,
    String? status,
    double? latitude,
    double? longitude,
    bool? showOnMap,
    bool? isSendingSignal,
    DateTime? lastSignalSent,
    String? signalMessage,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      deviceNumber: deviceNumber ?? this.deviceNumber,
      fishermanUid: fishermanUid ?? this.fishermanUid,
      fishermanDisplayId: fishermanDisplayId ?? this.fishermanDisplayId,
      fishermanFirstName: fishermanFirstName ?? this.fishermanFirstName,
      fishermanMiddleName: fishermanMiddleName ?? this.fishermanMiddleName,
      fishermanLastName: fishermanLastName ?? this.fishermanLastName,
      fishermanName: fishermanName ?? this.fishermanName,
      fishermanEmail: fishermanEmail ?? this.fishermanEmail,
      fishermanPhone: fishermanPhone ?? this.fishermanPhone,
      fishermanUserType: fishermanUserType ?? this.fishermanUserType,
      fishermanAddress: fishermanAddress ?? this.fishermanAddress,
      fishermanFishingArea: fishermanFishingArea ?? this.fishermanFishingArea,
      fishermanEmergencyContactPerson: fishermanEmergencyContactPerson ?? this.fishermanEmergencyContactPerson,
      fishermanProfilePictureUrl: fishermanProfilePictureUrl ?? this.fishermanProfilePictureUrl,
      fishermanProfileImageUrl: fishermanProfileImageUrl ?? this.fishermanProfileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      deviceType: deviceType ?? this.deviceType,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      showOnMap: showOnMap ?? this.showOnMap,
      isSendingSignal: isSendingSignal ?? this.isSendingSignal,
      lastSignalSent: lastSignalSent ?? this.lastSignalSent,
      signalMessage: signalMessage ?? this.signalMessage,
    );
  }

  @override
  String toString() {
    return 'DeviceModel(id: $id, deviceNumber: $deviceNumber, fishermanUid: $fishermanUid, isActive: $isActive, createdAt: $createdAt, lastUsed: $lastUsed, deviceType: $deviceType, description: $description, location: $location, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceModel &&
        other.id == id &&
        other.deviceNumber == deviceNumber &&
        other.fishermanUid == fishermanUid &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.lastUsed == lastUsed &&
        other.deviceType == deviceType &&
        other.description == description &&
        other.location == location &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        deviceNumber.hashCode ^
        fishermanUid.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        lastUsed.hashCode ^
        deviceType.hashCode ^
        description.hashCode ^
        location.hashCode ^
        status.hashCode;
  }
}
