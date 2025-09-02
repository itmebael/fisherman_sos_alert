import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // Firebase Auth UID, used as Firestore doc id
  final String? displayId; // Optional, for sequential/friendly IDs in UI
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String name; // Optional: full name (for display)
  final String email;
  final String phone; // Used for fishermen, empty for admin
  final String userType;
  final DateTime registrationDate;
  final bool isActive;
  final String? address;
  final String? fishingArea;
  final String? emergencyContactPerson;
  final String? boatId;
  final DateTime? lastActive; // NEW: Track last activity

  UserModel({
    required this.id,
    this.displayId,
    this.firstName,
    this.middleName,
    this.lastName,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.registrationDate,
    required this.isActive,
    this.address,
    this.fishingArea,
    this.emergencyContactPerson,
    this.boatId,
    this.lastActive, // NEW: Optional last activity
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime regDate;
    if (json['registrationDate'] is Timestamp) {
      regDate = (json['registrationDate'] as Timestamp).toDate();
    } else if (json['registrationDate'] is String) {
      regDate = DateTime.tryParse(json['registrationDate']) ?? DateTime.now();
    } else if (json['registrationDate'] is DateTime) {
      regDate = json['registrationDate'];
    } else {
      regDate = DateTime.now();
    }

    // Parse lastActive
    DateTime? lastActiveDate;
    if (json['lastActive'] is Timestamp) {
      lastActiveDate = (json['lastActive'] as Timestamp).toDate();
    } else if (json['lastActive'] is String) {
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
      boatId: json['boatId'],
      lastActive: lastActiveDate, // NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Firebase UID
      if (displayId != null) 'displayId': displayId,
      if (firstName != null) 'firstName': firstName,
      if (middleName != null) 'middleName': middleName,
      if (lastName != null) 'lastName': lastName,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'isActive': isActive,
      'address': address,
      'fishingArea': fishingArea,
      'emergencyContactPerson': emergencyContactPerson,
      'boatId': boatId,
      if (lastActive != null) 'lastActive': Timestamp.fromDate(lastActive!), // NEW
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
      boatId: boatId ?? this.boatId,
      lastActive: lastActive ?? this.lastActive, // NEW
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