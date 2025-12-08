import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'database_service.dart';
import '../models/user_model.dart';
import '../data/local/shared_preferences_helper.dart';

/// Service for tracking and updating live GPS locations of fishermen
class LiveLocationService {
  static final LiveLocationService _instance = LiveLocationService._internal();
  factory LiveLocationService() => _instance;
  LiveLocationService._internal();

  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  
  StreamSubscription<Position>? _locationSubscription;
  Timer? _updateTimer;
  bool _isTracking = false;
  
  // Update interval (30 seconds)
  static const Duration _updateInterval = Duration(seconds: 30);
  
  // Distance filter (10 meters - only update if moved significantly)
  static const double _distanceFilter = 10.0;
  
  Position? _lastPosition;
  DateTime? _lastUpdateTime;

  /// Start tracking and updating live location
  Future<void> startTracking() async {
    if (_isTracking) {
      print('Live location tracking already started');
      return;
    }

    try {
      // Check if user is logged in
      final userData = await SharedPreferencesHelper.getUserData();
      if (userData == null) {
        print('No user logged in, cannot start location tracking');
        return;
      }

      print('Starting live location tracking...');
      _isTracking = true;

      // Get initial location and update
      final initialPosition = await _locationService.getCurrentLocation();
      if (initialPosition != null) {
        await _updateLocationToDatabase(initialPosition, userData);
        _lastPosition = initialPosition;
        _lastUpdateTime = DateTime.now();
      }

      // Listen to location stream
      _locationSubscription?.cancel();
      _locationSubscription = _locationService.getLocationStream().listen(
        (position) async {
          if (!_isTracking) return;

          // Check if position has changed significantly or enough time has passed
          final shouldUpdate = _shouldUpdateLocation(position);
          
          if (shouldUpdate) {
            await _updateLocationToDatabase(position, userData);
            _lastPosition = position;
            _lastUpdateTime = DateTime.now();
          }
        },
        onError: (error) {
          print('Error in location stream: $error');
          // Don't stop tracking on error, just log it
        },
      );

      // Also set up periodic update timer (as backup)
      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(_updateInterval, (timer) async {
        if (!_isTracking) {
          timer.cancel();
          return;
        }

        try {
          final position = await _locationService.getCurrentLocation();
          if (position != null) {
            final user = await SharedPreferencesHelper.getUserData();
            if (user != null) {
              await _updateLocationToDatabase(position, user);
              _lastPosition = position;
              _lastUpdateTime = DateTime.now();
            }
          }
        } catch (e) {
          print('Error in periodic location update: $e');
        }
      });

      print('Live location tracking started successfully');
    } catch (e) {
      print('Error starting live location tracking: $e');
      _isTracking = false;
      rethrow;
    }
  }

  /// Stop tracking live location
  void stopTracking() {
    if (!_isTracking) {
      return;
    }

    print('Stopping live location tracking...');
    _isTracking = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    _lastPosition = null;
    _lastUpdateTime = null;
    
    print('Live location tracking stopped');
  }

  /// Check if should update location based on distance and time
  bool _shouldUpdateLocation(Position newPosition) {
    if (_lastPosition == null || _lastUpdateTime == null) {
      return true;
    }

    // Check if enough time has passed
    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
    if (timeSinceLastUpdate >= _updateInterval) {
      return true;
    }

    // Check if moved significantly
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    return distance >= _distanceFilter;
  }

  /// Update location to database
  Future<void> _updateLocationToDatabase(Position position, UserModel user) async {
    try {
      await _databaseService.updateLiveLocation(
        fishermanUid: user.id,
        fishermanEmail: user.email,
        fishermanDisplayId: user.id, // Use ID as display ID if not available
        fishermanName: user.name,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
      );
    } catch (e) {
      print('Error updating location to database: $e');
      // Don't throw - just log error to avoid breaking location stream
    }
  }

  /// Get current tracking status
  bool get isTracking => _isTracking;

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}

