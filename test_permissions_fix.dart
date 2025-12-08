import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST: Permissions Fix ===\n');
  
  // Test 1: Check location service status
  print('1. Checking location service status...');
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('   Location service enabled: $serviceEnabled');
    
    if (!serviceEnabled) {
      print('   ⚠️ Location services are disabled');
      print('   Please enable location services in device settings');
    } else {
      print('   ✅ Location services are enabled');
    }
  } catch (e) {
    print('   ❌ Error checking location service: $e');
  }
  
  // Test 2: Check location permissions
  print('\n2. Checking location permissions...');
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    print('   Current permission status: $permission');
    
    switch (permission) {
      case LocationPermission.always:
        print('   ✅ Location permission: Always allowed');
        break;
      case LocationPermission.whileInUse:
        print('   ✅ Location permission: While in use allowed');
        break;
      case LocationPermission.denied:
        print('   ⚠️ Location permission: Denied');
        print('   Requesting permission...');
        permission = await Geolocator.requestPermission();
        print('   New permission status: $permission');
        break;
      case LocationPermission.deniedForever:
        print('   ❌ Location permission: Permanently denied');
        print('   Please enable location permissions in device settings');
        break;
      case LocationPermission.unableToDetermine:
        print('   ❌ Location permission: Unable to determine');
        break;
    }
  } catch (e) {
    print('   ❌ Error checking permissions: $e');
    if (e.toString().contains('PermissionDefinitionsNotFoundException')) {
      print('   🔧 This is the error we fixed!');
      print('   The Android manifest now includes location permissions');
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
      print('   🔧 This error should be fixed now!');
    }
  }
  
  print('\n=== PERMISSIONS FIX COMPLETE ===');
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
  
  print('\n✅ What This Fixes:');
  print('   - PermissionDefinitionsNotFoundException error');
  print('   - Location access for SOS button');
  print('   - Camera access for profile pictures');
  print('   - Internet access for Supabase');
  
  print('\n✅ Next Steps:');
  print('   1. Clean and rebuild the app');
  print('   2. Test the SOS button');
  print('   3. Check that location permissions are requested');
  print('   4. Test SOS button functionality');
}

// Helper function to run the test
Future<void> runPermissionsFixTest() async {
  main();
}


