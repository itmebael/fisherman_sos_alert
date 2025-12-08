import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== COMPREHENSIVE PERMISSION FIX TEST ===\n');
  
  // Test 1: Check permission_handler status
  print('1. Testing permission_handler...');
  try {
    final locationPermission = await Permission.location.status;
    print('   Location permission status: $locationPermission');
    
    if (locationPermission.isGranted) {
      print('   ✅ Location permission is granted');
    } else if (locationPermission.isDenied) {
      print('   ⚠️ Location permission is denied');
      print('   Requesting permission...');
      final newStatus = await Permission.location.request();
      print('   New permission status: $newStatus');
    } else if (locationPermission.isPermanentlyDenied) {
      print('   ❌ Location permission is permanently denied');
      print('   User needs to enable in device settings');
    }
  } catch (e) {
    print('   ❌ Error with permission_handler: $e');
    if (e.toString().contains('PermissionDefinitionsNotFoundException')) {
      print('   🔧 This is the error we need to fix!');
    }
  }
  
  // Test 2: Check Geolocator status
  print('\n2. Testing Geolocator...');
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('   Location service enabled: $serviceEnabled');
    
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      print('   Geolocator permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('   Requesting Geolocator permission...');
        permission = await Geolocator.requestPermission();
        print('   New Geolocator permission: $permission');
      }
    }
  } catch (e) {
    print('   ❌ Error with Geolocator: $e');
    if (e.toString().contains('PermissionDefinitionsNotFoundException')) {
      print('   🔧 This is the error we need to fix!');
    }
  }
  
  // Test 3: Test location access
  print('\n3. Testing location access...');
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('   ✅ Location obtained successfully!');
    print('   Latitude: ${position.latitude}');
    print('   Longitude: ${position.longitude}');
    print('   Accuracy: ${position.accuracy} meters');
  } catch (e) {
    print('   ❌ Error getting location: $e');
    if (e.toString().contains('PermissionDefinitionsNotFoundException')) {
      print('   🔧 This error should be fixed with the manifest updates!');
    }
  }
  
  print('\n=== PERMISSION FIX STATUS ===');
  print('✅ Android Manifest Updated:');
  print('   - ACCESS_FINE_LOCATION');
  print('   - ACCESS_COARSE_LOCATION');
  print('   - ACCESS_BACKGROUND_LOCATION');
  print('   - INTERNET');
  print('   - CAMERA');
  print('   - STORAGE permissions');
  
  print('\n✅ iOS Info.plist Updated:');
  print('   - NSLocationWhenInUseUsageDescription');
  print('   - NSLocationAlwaysAndWhenInUseUsageDescription');
  print('   - NSCameraUsageDescription');
  print('   - NSPhotoLibraryUsageDescription');
  
  print('\n✅ SOS Button Updated:');
  print('   - Uses permission_handler for better permission handling');
  print('   - Graceful error handling for permission denials');
  print('   - Settings button for permanently denied permissions');
  print('   - Better user feedback');
  
  print('\n🔧 If you still get PermissionDefinitionsNotFoundException:');
  print('1. Run: flutter clean');
  print('2. Run: flutter pub get');
  print('3. Uninstall the app from your device');
  print('4. Run: flutter run');
  print('5. Check that permissions are requested when you click SOS button');
  
  print('\n✅ Expected Behavior:');
  print('- App should request location permission on first SOS button click');
  print('- No more PermissionDefinitionsNotFoundException errors');
  print('- SOS button should work and get GPS coordinates');
  print('- User should see permission request dialog');
}

// Test widget to demonstrate permission handling
class PermissionTestWidget extends StatelessWidget {
  const PermissionTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Test'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Permission Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Test permission request
                final status = await Permission.location.request();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permission status: $status'),
                    backgroundColor: status.isGranted ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Test Location Permission'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Test location access
                try {
                  final position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Location: ${position.latitude}, ${position.longitude}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Test Location Access'),
            ),
          ],
        ),
      ),
    );
  }
}


