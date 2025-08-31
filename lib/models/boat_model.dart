import 'package:cloud_firestore/cloud_firestore.dart';

class BoatModel {
  final String id; // Required by Firestore rules
  final String boatNumber; // Required by Firestore rules
  final String ownerUid; // Required by Firestore rules
  final bool isActive; // Required by Firestore rules
  final Timestamp createdAt; // Required by Firestore rules
  final String? name; // Optional field
  final String? registrationNumber; // Optional field

  BoatModel({
    required this.id,
    required this.boatNumber,
    required this.ownerUid,
    required this.isActive,
    required this.createdAt,
    this.name,
    this.registrationNumber,
  });

  factory BoatModel.fromJson(Map<String, dynamic> json) {
    return BoatModel(
      id: json['id'] ?? '',
      boatNumber: json['boatNumber'] ?? '',
      ownerUid: json['ownerUid'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? Timestamp.now(),
      name: json['name'],
      registrationNumber: json['registrationNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boatNumber': boatNumber,
      'ownerUid': ownerUid,
      'isActive': isActive,
      'createdAt': createdAt,
      if (name != null) 'name': name,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
    };
  }

  BoatModel copyWith({
    String? id,
    String? boatNumber,
    String? ownerUid,
    bool? isActive,
    Timestamp? createdAt,
    String? name,
    String? registrationNumber,
  }) {
    return BoatModel(
      id: id ?? this.id,
      boatNumber: boatNumber ?? this.boatNumber,
      ownerUid: ownerUid ?? this.ownerUid,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
    );
  }
}