import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/user_with_boat_model.dart';
import '../models/sos_alert_model.dart';
import '../services/database_service.dart';

class AdminProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<UserWithBoatModel> _usersWithBoats = [];
  List<SOSAlertModel> _rescueNotifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<UserWithBoatModel> get usersWithBoats => _usersWithBoats;
  List<UserModel> get users => _usersWithBoats.map((uwb) => uwb.user).toList(); // For backward compatibility
  List<SOSAlertModel> get rescueNotifications => _rescueNotifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Statistics
  int get totalUsers => _usersWithBoats.length;
  int get totalBoats => _usersWithBoats.where((uwb) => uwb.hasBoat).length;
  int get activeUsers => _usersWithBoats.where((uwb) => uwb.isActive).length;
  int get pendingRescues => _rescueNotifications.where((alert) => alert.status == 'pending').length;

  // Load users with their boats
  Future<void> loadUsersWithBoats() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get stream of users with boats
      _databaseService.getAllUsersWithBoats().listen(
        (usersWithBoats) {
          _usersWithBoats = usersWithBoats;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Legacy method for backward compatibility
  Future<void> loadUsers() async {
    await loadUsersWithBoats();
  }

  // Update user status
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _databaseService.updateFishermanStatus(userId, isActive);
      // The stream will automatically update the UI
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Toggle user status (for backward compatibility)
  Future<void> toggleUserStatus(String userId) async {
    try {
      final userWithBoat = _usersWithBoats.firstWhere((uwb) => uwb.userId == userId);
      await updateUserStatus(userId, !userWithBoat.isActive);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update fisherman last active
  Future<void> updateFishermanActivity(String userId) async {
    try {
      await _databaseService.updateFishermanLastActive(userId);
    } catch (e) {
      print('Failed to update fisherman activity: $e');
    }
  }

  // Update boat last used
  Future<void> updateBoatActivity(String boatId) async {
    try {
      await _databaseService.updateBoatLastUsed(boatId);
    } catch (e) {
      print('Failed to update boat activity: $e');
    }
  }

  // Delete user and their boat
  Future<void> deleteUserWithBoat(String userId, String? boatId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.deleteFisherman(userId);
      
      if (boatId != null) {
        await _databaseService.deleteBoat(boatId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<void> deleteUser(String userId) async {
    try {
      final userWithBoat = _usersWithBoats.firstWhere((uwb) => uwb.userId == userId);
      await deleteUserWithBoat(userId, userWithBoat.boatId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadRescueNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Remove all mock data. You should load rescue notifications from Firestore if needed.
      _rescueNotifications.clear();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> respondToAlert(String alertId, String coastguardId) async {
    try {
      final alertIndex = _rescueNotifications.indexWhere((alert) => alert.id == alertId);
      if (alertIndex != -1) {
        final alert = _rescueNotifications[alertIndex];
        final updatedAlert = alert.copyWith(status: 'responded');
        _rescueNotifications[alertIndex] = updatedAlert;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Search and filter methods
  List<UserWithBoatModel> searchUsersWithBoats(String query) {
    if (query.isEmpty) return _usersWithBoats;
    return _usersWithBoats.where((uwb) =>
      uwb.fullName.toLowerCase().contains(query.toLowerCase()) ||
      uwb.user.email.toLowerCase().contains(query.toLowerCase()) ||
      uwb.boatNumber.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<UserWithBoatModel> filterUsersByStatus(bool? isActive) {
    if (isActive == null) return _usersWithBoats;
    return _usersWithBoats.where((uwb) => uwb.isActive == isActive).toList();
  }

  List<UserWithBoatModel> filterUsersByBoatStatus(bool hasBoat) {
    return _usersWithBoats.where((uwb) => uwb.hasBoat == hasBoat).toList();
  }

  // Get users who haven't been active for specified days
  List<UserWithBoatModel> getInactiveUsers(int daysSinceLastActive) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysSinceLastActive));
    return _usersWithBoats.where((uwb) => 
      uwb.user.lastActive == null || uwb.user.lastActive!.isBefore(cutoffDate)
    ).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get user with boat by ID
  UserWithBoatModel? getUserWithBoatById(String id) {
    try {
      return _usersWithBoats.firstWhere((uwb) => uwb.userId == id);
    } catch (e) {
      return null;
    }
  }

  // Get users with boats only
  List<UserWithBoatModel> getUsersWithBoats() {
    return _usersWithBoats.where((uwb) => uwb.hasBoat).toList();
  }

  // Get active fishermen with boats
  List<UserWithBoatModel> getActiveFishermenWithBoats() {
    return _usersWithBoats.where((uwb) => 
      uwb.user.userType == 'fisherman' && uwb.isActive && uwb.hasBoat
    ).toList();
  }

  /// Returns the total number of successful rescues.
  /// This counts SOS alerts with status "rescued".
  int get totalRescued =>
      _rescueNotifications.where((alert) => alert.status?.toLowerCase() == 'rescued').length;
}