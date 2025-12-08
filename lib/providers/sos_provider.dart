import 'package:flutter/foundation.dart';
import '../models/sos_alert_model.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class SOSProvider with ChangeNotifier {
  SOSAlertModel? _currentAlert;
  bool _isLoading = false;
  String? _errorMessage;

  SOSAlertModel? get currentAlert => _currentAlert;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  Future<void> sendSOSAlert({String? description}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final position = await _locationService.getLocationForSOS();
      if (position == null) {
        throw Exception('Unable to get location. Please enable location services and try again.');
      }

      // Ensure fisherman exists in database
      String fishermanId = await _ensureFishermanExists(currentUser);

      final sosAlert = SOSAlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fishermanId: fishermanId,
        latitude: position.latitude,
        longitude: position.longitude,
        message: description,
        status: 'active',
        createdAt: DateTime.now(),
      );

      _currentAlert = sosAlert;

      // Test database connection first
      final connectionTest = await _databaseService.testConnection();
      if (!connectionTest) {
        throw Exception('Database connection failed. Please check your internet connection.');
      }

      // Test fishermen table
      final fishermenTest = await _databaseService.testFishermenTable();
      if (!fishermenTest) {
        throw Exception('Fishermen table not accessible. Please check database setup.');
      }

      // Persist to Supabase for admin visibility/notifications
      print('Creating SOS alert in database...');
      print('Fisherman ID: $fishermanId');
      print('Location: ${position.latitude}, ${position.longitude}');
      
      final success = await _databaseService.createSOSAlert(
        fishermanId: fishermanId,
        latitude: position.latitude,
        longitude: position.longitude,
        message: description ?? 'Emergency SOS Alert',
      );
      
      if (!success) {
        throw Exception('Failed to save SOS alert to database. Please check your connection and try again.');
      }
      
      print('SOS alert successfully saved to database!');

      await _sendToCoastGuard(sosAlert);

      await _notificationService.showNotification(
        title: 'SOS Alert Sent',
        body: 'Your emergency alert has been sent to Salbar_Mangirisda Coast Guard.',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();

      // Suppress failure notification to fisherman; keep error in logs/UI if needed
    }
  }

  Future<void> _sendToCoastGuard(SOSAlertModel alert) async {
    await Future.delayed(const Duration(seconds: 2));
    
    print('SOS Alert sent to Salbar_Mangirisda Coast Guard:');
    print('Fisherman ID: ${alert.fishermanId}');
    print('Location: ${alert.latitude}, ${alert.longitude}');
    print('Time: ${alert.createdAt}');
    print('Message: ${alert.message ?? 'Emergency SOS Alert'}');
  }

  void clearAlert() {
    _currentAlert = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Ensure fisherman exists in database, return fisherman ID
  Future<String> _ensureFishermanExists(UserModel user) async {
    try {
      print('=== ENSURING FISHERMAN EXISTS ===');
      print('User email: ${user.email}');
      print('User ID: ${user.id}');
      
      // First check if fisherman already exists
      final existingFisherman = await _databaseService.getFishermanByEmail(user.email ?? '');
      if (existingFisherman != null) {
        print('✅ Existing fisherman found: ${existingFisherman['first_name']} ${existingFisherman['last_name']}');
        print('Fisherman ID: ${existingFisherman['id']}');
        return existingFisherman['id'] as String;
      }

      print('⚠️ No fisherman found, creating new fisherman record...');
      // If not found, create a new fisherman record
      final fishermanId = await _databaseService.createFisherman(
        email: user.email ?? '',
        firstName: user.firstName ?? 'Unknown',
        lastName: user.lastName ?? 'User',
        phone: user.phone ?? '',
      );

      print('✅ New fisherman created with ID: $fishermanId');
      return fishermanId;
    } catch (e) {
      print('❌ Error ensuring fisherman exists: $e');
      print('Error details: ${e.toString()}');
      // Fallback to using user ID if database operations fail
      print('⚠️ Using user ID as fallback: ${user.id}');
      return user.id;
    }
  }
}