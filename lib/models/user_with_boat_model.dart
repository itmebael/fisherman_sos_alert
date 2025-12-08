// lib/models/user_with_boat_model.dart
import 'user_model.dart';
import 'boat_model.dart';

class UserWithBoatModel {
  final UserModel user;
  final BoatModel? boat;

  UserWithBoatModel({
    required this.user,
    this.boat,
  });

  // Factory constructor to create from Map
  factory UserWithBoatModel.fromMap(Map<String, dynamic> map) {
    return UserWithBoatModel(
      user: UserModel.fromMap(map),
      boat: map['boat'] != null ? BoatModel.fromMap(map['boat']) : null,
    );
  }

  // Getters for easy access to common properties
  String get fullName => user.name ?? user.fullName;
  String get boatNumber => boat?.boatNumber ?? 'No Boat';
  bool get isActive => user.isActive ?? false;
  DateTime get registrationDate => user.registrationDate ?? DateTime.now();
  String get lastActiveDisplay => user.lastActiveDisplay;
  String get userId => user.id;
  String? get boatId => boat?.id;

  // Check if user has a boat
  bool get hasBoat => boat != null;

  // Check if both user and boat are active
  bool get isFullyActive => (user.isActive ?? false) && (boat?.isActive ?? true);

  // Get the appropriate display for the table row
  String get statusDisplay {
    if (!(user.isActive ?? false)) return 'Inactive';
    if (boat != null && !boat!.isActive) return 'Boat Inactive';
    return 'Active';
  }

  // Get color for status
  String get statusColor {
    if (!(user.isActive ?? false) || (boat != null && !boat!.isActive)) {
      return 'red';
    }
    return 'green';
  }
}