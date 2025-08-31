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
    );
  }
}