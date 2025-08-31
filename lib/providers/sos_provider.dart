import 'package:flutter/foundation.dart';
import '../models/sos_alert_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

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

  Future<void> sendSOSAlert({String? description}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Unable to get location. Please enable location services.');
      }

      final sosAlert = SOSAlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fishermanId: currentUser.id,
        fishermanName: currentUser.name,
        latitude: position.latitude,
        longitude: position.longitude,
        alertTime: DateTime.now(),
        description: description,
        status: 'pending',
      );

      _currentAlert = sosAlert;

      await _sendToCoastGuard(sosAlert);

      await _notificationService.showNotification(
        title: 'SOS Alert Sent',
        body: 'Your emergency alert has been sent to BantayDagat Coast Guard.',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      
      await _notificationService.showNotification(
        title: 'SOS Alert Failed',
        body: 'Failed to send emergency alert. Please try again.',
      );
    }
  }

  Future<void> _sendToCoastGuard(SOSAlertModel alert) async {
    await Future.delayed(const Duration(seconds: 2));
    
    print('SOS Alert sent to BantayDagat Coast Guard:');
    print('Fisherman: ${alert.fishermanName}');
    print('Location: ${alert.latitude}, ${alert.longitude}');
    print('Time: ${alert.alertTime}');
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
}