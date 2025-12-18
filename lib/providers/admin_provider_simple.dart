import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/sos_alert_model.dart';
import '../models/device_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AdminProviderSimple with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<Map<String, dynamic>> _usersWithBoats = [];
  List<SOSAlertModel> _rescueNotifications = [];
  List<DeviceModel> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Count properties
  int _totalUsers = 0;
  int _totalBoats = 0;
  int _totalRescued = 0;
  int _activeSOSAlerts = 0;
  int _totalDevices = 0;

  // Getters
  List<Map<String, dynamic>> get usersWithBoats => _usersWithBoats;
  List<UserModel> get users => _usersWithBoats.map((uwb) => UserModel.fromMap(uwb)).toList();
  List<SOSAlertModel> get rescueNotifications => _rescueNotifications;
  List<DeviceModel> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Updated getters for counts
  int get totalUsers => _totalUsers;
  int get totalBoats => _totalBoats;
  int get totalRescued => _totalRescued;
  int get activeSOSAlerts => _activeSOSAlerts;
  int get totalDevices => _totalDevices;

  // Load dashboard data
  Future<void> loadDashboardData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Load all counts concurrently
      final results = await Future.wait([
        _databaseService.getTotalUsersCount(),
        _databaseService.getTotalBoatsCount(),
        _databaseService.getTotalRescuedCount(),
        _databaseService.getActiveSOSAlertsCount(),
        _getTotalDevicesCount(),
      ]);

      _totalUsers = results[0];
      _totalBoats = results[1];
      _totalRescued = results[2];
      _activeSOSAlerts = results[3];
      _totalDevices = results[4];
      // TEMP: force 1 active SOS if none to display demo data on dashboard
      if (_activeSOSAlerts == 0) {
        _activeSOSAlerts = 1;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load users with boats
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

  // Load rescue notifications
  Future<void> loadRescueNotifications() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final alerts = await _databaseService.getSOSAlerts();
      _rescueNotifications = alerts.map((alert) => SOSAlertModel.fromJson(alert)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update fisherman status
  Future<void> updateFishermanStatus(String fishermanId, bool isActive) async {
    try {
      await _databaseService.updateFishermanStatus(fishermanId, isActive);
      // Reload data
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update fisherman last active
  Future<void> updateFishermanLastActive(String fishermanId) async {
    try {
      await _databaseService.updateFishermanLastActive(fishermanId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating fisherman last active: $e');
      }
    }
  }

  // Update boat last used
  Future<void> updateBoatLastUsed(String boatId) async {
    try {
      await _databaseService.updateBoatLastUsed(boatId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating boat last used: $e');
      }
    }
  }

  // Delete fisherman
  Future<void> deleteFisherman(String fishermanId) async {
    try {
      await _databaseService.deleteFisherman(fishermanId);
      // Reload data
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete boat
  Future<void> deleteBoat(String boatId) async {
    try {
      await _databaseService.deleteBoat(boatId);
      // Reload data
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Create new user
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final authService = AuthService();
      
      // Get form data
      final firstName = userData['first_name'] ?? '';
      final middleName = userData['middle_name'] ?? '';
      final lastName = userData['last_name'] ?? '';

      // Create user using auth service (full name is built internally)
      // Extract boat information
      final boatNumber = userData['boat_number']?.toString() ?? '';
      final boatType = userData['boat_type']?.toString() ?? '';
      final boatRegistrationNumber = userData['registration_number']?.toString() ?? '';
      
      final success = await authService.registerBoatAndFisherman(
        email: userData['email'] ?? '',
        password: userData['password'] ?? '',
        firstName: firstName,
        lastName: lastName,
        middleName: middleName.toString().isNotEmpty ? middleName.toString() : null,
        phone: userData['phone'] ?? '',
        boatName: boatNumber.isNotEmpty ? boatNumber : 'Boat-${DateTime.now().millisecondsSinceEpoch}',
        boatType: boatType,
        boatRegistrationNumber: boatRegistrationNumber,
        boatCapacity: '0',
        profileImageUrl: userData['profile_image_url']?.toString(),
        address: userData['address']?.toString(),
        fishingArea: userData['fishing_area']?.toString(),
        emergencyContactPerson: userData['emergency_contact_person']?.toString(),
      );

      if (!success) {
        throw Exception('Failed to create user');
      }
      
      // Reload users to include the new one
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing user
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Build full name
      final firstName = userData['first_name'] ?? '';
      final middleName = userData['middle_name'] ?? '';
      final lastName = userData['last_name'] ?? '';
      final fullName = [
        firstName,
        if (middleName != null && middleName.toString().isNotEmpty) middleName,
        lastName,
      ].where((part) => part.toString().isNotEmpty).join(' ');

      // Prepare fisherman data including boat information (denormalized)
      final fishermanData = {
        'first_name': firstName,
        'middle_name': middleName.toString().isNotEmpty ? middleName.toString() : null,
        'last_name': lastName,
        'name': fullName,
        'email': userData['email'] ?? '',
        'phone': userData['phone'] ?? '',
        'address': userData['address']?.toString(),
        'fishing_area': userData['fishing_area']?.toString(),
        'emergency_contact_person': userData['emergency_contact_person']?.toString(),
        'is_active': userData['is_active'] ?? true,
        // Profile image URL - ensure it's saved
        'profile_image_url': userData['profile_image_url']?.toString(),
        // Boat information (denormalized to fishermen table)
        'boat_name': userData['boat_number']?.toString(),
        'boat_type': userData['boat_type']?.toString(),
        'boat_registration_number': userData['registration_number']?.toString(),
      };

      // Update fisherman (includes boat info)
      final success = await _databaseService.updateFisherman(userId, fishermanData);
      
      if (!success) {
        throw Exception('Failed to update user');
      }

      // Also update boat table to keep it in sync
      final boatNumber = userData['boat_number']?.toString();
      final boatType = userData['boat_type']?.toString();
      final boatRegistrationNumber = userData['registration_number']?.toString();
      
      if (boatNumber != null || boatType != null || boatRegistrationNumber != null) {
        final boatData = {
          'boat_number': boatNumber,
          'boat_type': boatType,
          'registration_number': boatRegistrationNumber,
        };
        
        await _databaseService.createOrUpdateBoatForFisherman(userId, boatData);
      }
      
      // Reload users to reflect changes
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle user status (activate/deactivate)
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // This would typically call a service method to toggle status
      // For now, we'll simulate the toggle
      await Future.delayed(const Duration(seconds: 1));
      
      // Reload users to reflect changes
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // This would typically call a service method to delete user
      // For now, we'll simulate the deletion
      await Future.delayed(const Duration(seconds: 1));
      
      // Reload users to reflect changes
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Device Management Methods

  // Get total devices count
  Future<int> _getTotalDevicesCount() async {
    try {
      final stats = await _databaseService.getDeviceStatistics();
      return stats['total_devices'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Load devices
  Future<void> loadDevices() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get devices from database
      final deviceData = await _databaseService.getDevices();
      _devices = deviceData.map((data) => DeviceModel.fromMap(data)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Add device
  Future<void> addDevice(DeviceModel device) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Add device to database
      final deviceData = device.toMap();
      await _databaseService.addDevice(deviceData);
      
      // Reload devices to get updated list
      await loadDevices();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update device
  Future<void> updateDevice(DeviceModel device) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Update device in database
      final deviceData = device.toMap();
      await _databaseService.updateDevice(device.id, deviceData);
      
      // Reload devices to get updated list
      await loadDevices();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete device
  Future<void> deleteDevice(String deviceId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Delete device from database
      await _databaseService.deleteDevice(deviceId);
      
      // Reload devices to get updated list
      await loadDevices();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Toggle device status
  Future<void> toggleDeviceStatus(String deviceId, bool isActive) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Toggle device status in database
      await _databaseService.toggleDeviceStatus(deviceId, isActive);
      
      // Reload devices to get updated list
      await loadDevices();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Stop device signal
  Future<void> stopDeviceSignal(String deviceId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Stop device signal in database
      await _databaseService.stopDeviceSignal(deviceId);
      
      // Reload devices to get updated list
      await loadDevices();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

}
