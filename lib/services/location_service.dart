import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position with high accuracy and timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Location error: $e');
      return null;
    }
  }

  // Get location with retry mechanism for SOS alerts
  Future<Position?> getLocationForSOS() async {
    int retries = 3;
    Position? position;
    
    while (retries > 0 && position == null) {
      try {
        position = await getCurrentLocation();
        if (position != null) {
          print('GPS location obtained: ${position.latitude}, ${position.longitude}');
          print('Accuracy: ${position.accuracy} meters');
          print('Timestamp: ${position.timestamp}');
          break;
        }
      } catch (e) {
        print('Location attempt failed: $e');
        retries--;
        if (retries > 0) {
          print('Retrying location request... ($retries attempts left)');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    
    return position;
  }

  Future<double> getDistanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  Stream<Position> getLocationStream() {
    try {
      // Use a controller to ensure stream is properly managed
      // This helps avoid threading issues
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(seconds: 30),
        ),
      ).handleError((error) {
        print('Location stream error: $error');
        // Don't crash the app on location errors
      });
    } catch (e) {
      print('Error creating location stream: $e');
      // Return an empty stream if location service fails
      return Stream<Position>.empty();
    }
  }
}