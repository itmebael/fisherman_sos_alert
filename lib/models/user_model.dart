class UserModel {
  final String id; // UUID primary key
  final String? displayId; // Optional, for sequential/friendly IDs in UI
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? name; // Optional: full name (for display)
  final String? email;
  final String? phone; // Used for fishermen, empty for admin
  final String userType;
  final DateTime? registrationDate;
  final bool? isActive;
  final String? address;
  final String? fishingArea;
  final String? emergencyContactPerson;
  final DateTime? lastActive; // Track last activity
  final String? profileImageUrl; // Profile image URL
  final DateTime? createdAt; // Creation timestamp

  // Getter for full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (name != null && name!.isNotEmpty) {
      return name!;
    } else {
      return 'Unknown User';
    }
  }

  UserModel({
    required this.id,
    this.displayId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.name,
    this.email,
    this.phone,
    this.userType = 'fisherman',
    this.registrationDate,
    this.isActive,
    this.address,
    this.fishingArea,
    this.emergencyContactPerson,
    this.lastActive,
    this.profileImageUrl,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? regDate;
    if (map['registration_date'] is String) {
      regDate = DateTime.tryParse(map['registration_date']);
    } else if (map['registration_date'] is DateTime) {
      regDate = map['registration_date'];
    }

    // Parse lastActive
    DateTime? lastActiveDate;
    if (map['last_active'] is String) {
      lastActiveDate = DateTime.tryParse(map['last_active']);
    } else if (map['last_active'] is DateTime) {
      lastActiveDate = map['last_active'];
    }

    // Parse createdAt
    DateTime? createdDate;
    if (map['created_at'] is String) {
      createdDate = DateTime.tryParse(map['created_at']);
    } else if (map['created_at'] is DateTime) {
      createdDate = map['created_at'];
    }

    return UserModel(
      id: map['id'] ?? '',
      displayId: map['display_id'],
      firstName: map['first_name'],
      middleName: map['middle_name'],
      lastName: map['last_name'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      userType: map['user_type'] ?? 'fisherman',
      registrationDate: regDate,
      isActive: map['is_active'],
      address: map['address'],
      fishingArea: map['fishing_area'],
      emergencyContactPerson: map['emergency_contact_person'],
      lastActive: lastActiveDate,
      profileImageUrl: map['profile_image_url'] ?? map['profile_picture_url'],
      createdAt: createdDate,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime regDate;
    if (json['registrationDate'] is String) {
      regDate = DateTime.tryParse(json['registrationDate']) ?? DateTime.now();
    } else if (json['registrationDate'] is DateTime) {
      regDate = json['registrationDate'];
    } else {
      regDate = DateTime.now();
    }

    // Parse lastActive
    DateTime? lastActiveDate;
    if (json['lastActive'] is String) {
      lastActiveDate = DateTime.tryParse(json['lastActive']);
    } else if (json['lastActive'] is DateTime) {
      lastActiveDate = json['lastActive'];
    }

    return UserModel(
      id: json['id'] ?? '',
      displayId: json['displayId'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['userType'] ?? 'fisherman',
      registrationDate: regDate,
      isActive: json['isActive'] ?? true,
      address: json['address'],
      fishingArea: json['fishingArea'],
      emergencyContactPerson: json['emergencyContactPerson'],
      lastActive: lastActiveDate, // NEW
      profileImageUrl: json['profileImageUrl'], // NEW
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Supabase UID
      if (displayId != null) 'displayId': displayId,
      if (firstName != null) 'firstName': firstName,
      if (middleName != null) 'middleName': middleName,
      if (lastName != null) 'lastName': lastName,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'registrationDate': registrationDate?.toIso8601String(),
      'isActive': isActive,
      'address': address,
      'fishingArea': fishingArea,
      'emergencyContactPerson': emergencyContactPerson,
      if (lastActive != null) 'lastActive': lastActive!.toIso8601String(), // NEW
      'profileImageUrl': profileImageUrl, // NEW
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? displayId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? name,
    String? email,
    String? phone,
    String? userType,
    DateTime? registrationDate,
    bool? isActive,
    String? address,
    String? fishingArea,
    String? emergencyContactPerson,
    String? boatId,
    DateTime? lastActive, // NEW
    String? profileImageUrl, // NEW
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayId: displayId ?? this.displayId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      registrationDate: registrationDate ?? this.registrationDate,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      fishingArea: fishingArea ?? this.fishingArea,
      emergencyContactPerson: emergencyContactPerson ?? this.emergencyContactPerson,
      lastActive: lastActive ?? this.lastActive, // NEW
      profileImageUrl: profileImageUrl ?? this.profileImageUrl, // NEW
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // NEW: Helper method to get formatted last active display
  String get lastActiveDisplay {
    if (lastActive == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastActive!);
    
    if (difference.inMinutes < 1) {
      return 'Active Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} Minutes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} Hours Ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} Days Ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'Month' : 'Months'} Ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'Year' : 'Years'} Ago';
    }
  }
}