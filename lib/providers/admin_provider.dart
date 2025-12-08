import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/sos_alert_model.dart';
import '../services/database_service.dart';

class AdminProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<Map<String, dynamic>> _usersWithBoats = [];
  final List<SOSAlertModel> _rescueNotifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Count properties
  int _totalUsers = 0;
  int _totalBoats = 0;
  int _totalRescued = 0;

  // Getters
  List<Map<String, dynamic>> get usersWithBoats => _usersWithBoats;
  List<UserModel> get users => _usersWithBoats.map((uwb) => UserModel.fromMap(uwb)).toList(); // For backward compatibility
  List<SOSAlertModel> get rescueNotifications => _rescueNotifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Updated getters for counts
  int get totalUsers => _totalUsers;
  int get totalBoats => _totalBoats;
  int get totalRescued => _totalRescued;
  
  // Legacy getters for backward compatibility
  int get activeUsers => _usersWithBoats.where((uwb) => uwb['is_active'] == true).length;
  int get pendingRescues => _rescueNotifications.where((alert) => alert.status == 'pending').length;

  // Load dashboard counts
  Future<void> loadDashboardCounts() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Load all counts with individual error handling
      try {
        _totalUsers = await _databaseService.getTotalUsersCount();
      } catch (e) {
        print('Error loading users count: $e');
        _totalUsers = 0;
      }

      try {
        _totalBoats = await _databaseService.getTotalBoatsCount();
      } catch (e) {
        print('Error loading boats count: $e');
        _totalBoats = 0;
      }

      try {
        _totalRescued = await _databaseService.getTotalRescuedCount();
      } catch (e) {
        print('Error loading rescued count: $e');
        _totalRescued = 0;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Call this method when AdminDashboard loads
  Future<void> initializeDashboard() async {
    await loadDashboardCounts();
  }

  // Load users with their boats
  Future<void> loadUsersWithBoats() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get users with boats
      final usersWithBoats = await _databaseService.getAllUsersWithBoats();
      _usersWithBoats = usersWithBoats;
      _isLoading = false;
      notifyListeners();
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
      final userWithBoat = _usersWithBoats.firstWhere((uwb) => uwb['user_id'] == userId);
      await updateUserStatus(userId, !(userWithBoat['is_active'] == true));
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
      final userWithBoat = _usersWithBoats.firstWhere((uwb) => uwb['user_id'] == userId);
      await deleteUserWithBoat(userId, userWithBoat['boat_id']);
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
  List<Map<String, dynamic>> searchUsersWithBoats(String query) {
    if (query.isEmpty) return _usersWithBoats;
    return _usersWithBoats.where((uwb) =>
      (uwb['full_name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
      (uwb['email'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
      (uwb['boat_number'] ?? '').toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<Map<String, dynamic>> filterUsersByStatus(bool? isActive) {
    if (isActive == null) return _usersWithBoats;
    return _usersWithBoats.where((uwb) => uwb['is_active'] == isActive).toList();
  }

  List<Map<String, dynamic>> filterUsersByBoatStatus(bool hasBoat) {
    return _usersWithBoats.where((uwb) => uwb['has_boat'] == hasBoat).toList();
  }

  // Get users who haven't been active for specified days
  List<Map<String, dynamic>> getInactiveUsers(int daysSinceLastActive) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysSinceLastActive));
    return _usersWithBoats.where((uwb) {
      final lastActive = uwb['last_active'];
      if (lastActive == null) return true;
      final lastActiveDate = DateTime.tryParse(lastActive);
      return lastActiveDate == null || lastActiveDate.isBefore(cutoffDate);
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get user with boat by ID
  Map<String, dynamic>? getUserWithBoatById(String id) {
    try {
      return _usersWithBoats.firstWhere((uwb) => uwb['user_id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Get users with boats only
  List<Map<String, dynamic>> getUsersWithBoats() {
    return _usersWithBoats.where((uwb) => uwb['has_boat'] == true).toList();
  }

  // Get active fishermen with boats
  List<Map<String, dynamic>> getActiveFishermenWithBoats() {
    return _usersWithBoats.where((uwb) => 
      uwb['user_type'] == 'fisherman' && uwb['is_active'] == true && uwb['has_boat'] == true
    ).toList();
  }
}