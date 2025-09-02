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

  // Getters for easy access to common properties
  String get fullName => user.name;
  String get boatNumber => boat?.boatNumber ?? 'No Boat';
  bool get isActive => user.isActive;
  DateTime get registrationDate => user.registrationDate;
  String get lastActiveDisplay => user.lastActiveDisplay;
  String get userId => user.id;
  String? get boatId => boat?.id;

  // Check if user has a boat
  bool get hasBoat => boat != null;

  // Check if both user and boat are active
  bool get isFullyActive => user.isActive && (boat?.isActive ?? true);

  // Get the appropriate display for the table row
  String get statusDisplay {
    if (!user.isActive) return 'Inactive';
    if (boat != null && !boat!.isActive) return 'Boat Inactive';
    return 'Active';
  }

  // Get color for status
  String get statusColor {
    if (!user.isActive || (boat != null && !boat!.isActive)) {
      return 'red';
    }
    return 'green';
  }
}