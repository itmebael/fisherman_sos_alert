import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST: Direct SOS Button Implementation ===\n');
  
  // Initialize Supabase (make sure you have your config)
  // Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );
  
  final supabase = Supabase.instance.client;
  
  // Test 1: Check if user is authenticated
  print('1. Checking authentication...');
  final user = supabase.auth.currentUser;
  if (user == null) {
    print('   ❌ No authenticated user found!');
    print('   Please log in first before running this test.\n');
    return;
  }
  
  print('   ✅ User authenticated: ${user.email}');
  print('   User ID: ${user.id}');
  
  // Test 2: Check location permissions
  print('\n2. Checking location permissions...');
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('   ❌ Location services are disabled');
      return;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('   ❌ Location permission denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('   ❌ Location permissions are permanently denied');
      return;
    }
    
    print('   ✅ Location permissions granted');
  } catch (e) {
    print('   ❌ Error checking location permissions: $e');
    return;
  }
  
  // Test 3: Get current location
  print('\n3. Getting current location...');
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('   ✅ Location obtained: ${position.latitude}, ${position.longitude}');
  } catch (e) {
    print('   ❌ Error getting location: $e');
    return;
  }
  
  // Test 4: Test direct insert to sos_alerts table
  print('\n4. Testing direct insert to sos_alerts table...');
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    final alertId = const Uuid().v4();
    
    final sosAlertData = {
      'id': alertId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'message': 'Test SOS alert from direct implementation',
      'status': 'active',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'fisherman_uid': user.id,
      'fisherman_display_id': user.userMetadata?['display_id'],
      'fisherman_first_name': user.userMetadata?['first_name'],
      'fisherman_middle_name': user.userMetadata?['middle_name'],
      'fisherman_last_name': user.userMetadata?['last_name'],
      'fisherman_name': '${user.userMetadata?['first_name'] ?? ''} ${user.userMetadata?['last_name'] ?? ''}',
      'fisherman_email': user.email,
      'fisherman_phone': user.userMetadata?['phone'],
      'fisherman_user_type': 'fisherman',
      'fisherman_address': user.userMetadata?['address'],
      'fisherman_fishing_area': user.userMetadata?['fishing_area'],
      'fisherman_emergency_contact_person': user.userMetadata?['emergency_contact'],
      'fisherman_profile_picture_url': user.userMetadata?['profile_picture_url'],
      'fisherman_profile_image_url': user.userMetadata?['profile_image_url'],
    };
    
    print('   Alert data: $sosAlertData');
    
    final response = await supabase.from('sos_alerts').insert(sosAlertData);
    
    if (response.error != null) {
      print('   ❌ Error saving SOS alert: ${response.error!.message}');
      print('   Error details: ${response.error!.details}');
      print('   Error hint: ${response.error!.hint}');
    } else {
      print('   ✅ SOS alert saved successfully!');
      print('   Alert ID: $alertId');
    }
  } catch (e) {
    print('   ❌ Exception while saving SOS alert: $e');
  }
  
  // Test 5: Verify the alert was saved
  print('\n5. Verifying alert was saved...');
  try {
    if (user.email == null) {
      print('   ❌ User email is null, cannot verify alerts');
      return;
    }
    final alerts = await supabase
        .from('sos_alerts')
        .select('*')
        .eq('fisherman_email', user.email!)
        .order('created_at', ascending: false)
        .limit(5);
    
    print('   Total alerts for this user: ${alerts.length}');
    
    if (alerts.isNotEmpty) {
      final latestAlert = alerts.first;
      print('   Latest alert:');
      print('   - ID: ${latestAlert['id']}');
      print('   - Email: ${latestAlert['fisherman_email']}');
      print('   - Name: ${latestAlert['fisherman_first_name']} ${latestAlert['fisherman_last_name']}');
      print('   - Location: ${latestAlert['latitude']}, ${latestAlert['longitude']}');
      print('   - Status: ${latestAlert['status']}');
      print('   - Created: ${latestAlert['created_at']}');
    }
  } catch (e) {
    print('   ❌ Error verifying alerts: $e');
  }
  
  print('\n=== TEST COMPLETE ===');
}

// Helper function to run the test
Future<void> runSOSButtonDirectTest() async {
  main();
}


