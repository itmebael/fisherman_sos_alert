import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/sos_alert_model.dart';

class AdminProvider with ChangeNotifier {
  List<UserModel> _users = [];
  List<SOSAlertModel> _rescueNotifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  List<SOSAlertModel> get rescueNotifications => _rescueNotifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalUsers => _users.length;
  int get totalBoats => _users.where((user) => user.boatId != null).length;
  int get activeUsers => _users.where((user) => user.isActive).length;
  int get pendingRescues => _rescueNotifications.where((alert) => alert.status == 'pending').length;

  Future<void> loadUsers() async {
    try {
      _isLoading = true;
      notifyListeners();
      // Remove all mock data. You should load users from Firestore here if needed.
      _users.clear();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addUser(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();

      // In Firebase integration, this will add via Firestore and the registration page.
      _users.add(user);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();

      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _users.removeWhere((user) => user.id == userId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleUserStatus(String userId) async {
    try {
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        final user = _users[userIndex];
        final updatedUser = user.copyWith(isActive: !user.isActive);
        _users[userIndex] = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
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
  List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return _users;
    return _users.where((user) =>
      user.name.toLowerCase().contains(query.toLowerCase()) ||
      user.email.toLowerCase().contains(query.toLowerCase()) ||
      (user.boatId?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  List<UserModel> filterUsersByStatus(bool? isActive) {
    if (isActive == null) return _users;
    return _users.where((user) => user.isActive == isActive).toList();
  }

  List<UserModel> filterUsersByType(String? userType) {
    if (userType == null || userType.isEmpty) return _users;
    return _users.where((user) => user.userType == userType).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get user by ID
  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get users with boats
  List<UserModel> getUsersWithBoats() {
    return _users.where((user) => user.boatId != null).toList();
  }

  // Get active fishermen
  List<UserModel> getActiveFishermen() {
    return _users.where((user) => 
      user.userType == 'fisherman' && user.isActive
    ).toList();
  }
}