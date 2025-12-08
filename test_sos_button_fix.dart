import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'lib/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST: SOS Button Fix ===\n');
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
    return;
  }
  
  final supabase = SupabaseConfig.client;
  
  // Test 1: Check authentication
  print('1. Checking authentication...');
  final user = supabase.auth.currentUser;
  if (user != null) {
    print('   ✅ User authenticated: ${user.email}');
  } else {
    print('   ℹ️ User not authenticated (will use anonymous data)');
  }
  
  // Test 2: Test location
  print('\n2. Testing location...');
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('   ❌ Location services disabled');
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
    
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('   ✅ Location obtained: ${position.latitude}, ${position.longitude}');
  } catch (e) {
    print('   ❌ Location error: $e');
    return;
  }
  
  // Test 3: Test SOS alert creation (same logic as the fixed SOS button)
  print('\n3. Testing SOS alert creation...');
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    final alertId = const Uuid().v4();
    final currentUser = supabase.auth.currentUser;
    
    // This is the exact same logic as the fixed SOS button
    final sosAlertData = {
      'id': alertId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'message': 'Emergency SOS Alert - Fisherman in distress',
      'status': 'active',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'fisherman_uid': currentUser?.id,
      'fisherman_display_id': currentUser?.userMetadata?['display_id'],
      'fisherman_first_name': currentUser?.userMetadata?['first_name'] ?? 'Unknown',
      'fisherman_middle_name': currentUser?.userMetadata?['middle_name'],
      'fisherman_last_name': currentUser?.userMetadata?['last_name'] ?? 'User',
      'fisherman_name': currentUser != null 
          ? '${currentUser.userMetadata?['first_name'] ?? ''} ${currentUser.userMetadata?['last_name'] ?? ''}'.trim()
          : 'Anonymous User',
      'fisherman_email': currentUser?.email ?? 'anonymous@emergency.com',
      'fisherman_phone': currentUser?.userMetadata?['phone'] ?? 'Not provided',
      'fisherman_user_type': currentUser?.userMetadata?['user_type'] ?? 'anonymous',
      'fisherman_address': currentUser?.userMetadata?['address'] ?? 'Location not provided',
      'fisherman_fishing_area': currentUser?.userMetadata?['fishing_area'] ?? 'Unknown area',
      'fisherman_emergency_contact_person': currentUser?.userMetadata?['emergency_contact'] ?? 'Not provided',
      'fisherman_profile_picture_url': currentUser?.userMetadata?['profile_picture_url'],
      'fisherman_profile_image_url': currentUser?.userMetadata?['profile_image_url'],
    };
    
    print('   Alert data:');
    print('   - ID: $alertId');
    print('   - User: ${currentUser != null ? "authenticated" : "anonymous"}');
    print('   - Name: ${sosAlertData['fisherman_name']}');
    print('   - Email: ${sosAlertData['fisherman_email']}');
    print('   - Location: ${position.latitude}, ${position.longitude}');
    
    final response = await supabase.from('sos_alerts').insert(sosAlertData);
    
    if (response.error != null) {
      print('   ❌ Error: ${response.error!.message}');
      print('   Details: ${response.error!.details}');
    } else {
      print('   ✅ SOS alert saved successfully!');
      print('   Alert ID: $alertId');
    }
  } catch (e) {
    print('   ❌ Exception: $e');
  }
  
  // Test 4: Verify data was saved
  print('\n4. Checking saved data...');
  try {
    final alerts = await supabase
        .from('sos_alerts')
        .select('*')
        .order('created_at', ascending: false)
        .limit(3);
    
    print('   Total alerts: ${alerts.length}');
    
    if (alerts.isNotEmpty) {
      print('   Recent alerts:');
      for (final alert in alerts) {
        print('   - ${alert['id']}: ${alert['fisherman_name']} (${alert['fisherman_email']})');
        print('     Location: ${alert['latitude']}, ${alert['longitude']}');
        print('     Status: ${alert['status']}');
        print('     Created: ${alert['created_at']}');
        print('');
      }
    }
  } catch (e) {
    print('   ❌ Error checking alerts: $e');
  }
  
  print('=== TEST COMPLETE ===');
  print('The SOS button should now work correctly!');
  print('Check your Supabase dashboard to see the saved data.');
}

Future<void> runSOSButtonFixTest() async {
  main();
}


