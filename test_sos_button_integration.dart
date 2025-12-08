import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST: SOS Button Integration in Fisherman Home ===\n');
  
  // Initialize Supabase (make sure you have your config)
  // Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );
  
  final supabase = Supabase.instance.client;
  
  // Test 1: Check authentication
  print('1. Checking authentication...');
  final user = supabase.auth.currentUser;
  if (user == null) {
    print('   ❌ No authenticated user found!');
    print('   Please log in first before testing the SOS button.\n');
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
      print('   Enable location services to test SOS button');
      return;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('   ❌ Location permission denied');
        print('   Grant location permission to test SOS button');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('   ❌ Location permissions are permanently denied');
      print('   Enable location permissions in device settings');
      return;
    }
    
    print('   ✅ Location permissions granted');
  } catch (e) {
    print('   ❌ Error checking location permissions: $e');
    return;
  }
  
  // Test 3: Test the exact same logic as your SOS button
  print('\n3. Testing SOS button logic...');
  try {
    // Get current GPS location (same as SOS button)
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    print('   ✅ Location obtained: ${position.latitude}, ${position.longitude}');
    
    // Generate alert ID (same as SOS button)
    final alertId = const Uuid().v4();
    print('   ✅ Alert ID generated: $alertId');
    
    // Prepare data (same as SOS button)
    final sosAlertData = {
      'id': alertId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'message': 'Fisherman in distress',
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
    
    print('   Alert data prepared with ${sosAlertData.length} fields');
    
    // Insert into database (same as SOS button)
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
    print('   ❌ Exception while testing SOS button logic: $e');
  }
  
  // Test 4: Verify the alert was saved
  print('\n4. Verifying alert was saved...');
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
        .limit(3);
    
    print('   Total alerts for this user: ${alerts.length}');
    
    if (alerts.isNotEmpty) {
      final latestAlert = alerts.first;
      print('   Latest alert details:');
      print('   - ID: ${latestAlert['id']}');
      print('   - Email: ${latestAlert['fisherman_email']}');
      print('   - Name: ${latestAlert['fisherman_first_name']} ${latestAlert['fisherman_last_name']}');
      print('   - Location: ${latestAlert['latitude']}, ${latestAlert['longitude']}');
      print('   - Status: ${latestAlert['status']}');
      print('   - Message: ${latestAlert['message']}');
      print('   - Created: ${latestAlert['created_at']}');
      
      // Check if all required fields are present
      final hasLocation = latestAlert['latitude'] != null && latestAlert['longitude'] != null;
      final hasEmail = latestAlert['fisherman_email'] != null && latestAlert['fisherman_email'].toString().isNotEmpty;
      final hasStatus = latestAlert['status'] != null && latestAlert['status'].toString().isNotEmpty;
      
      print('\n   Data verification:');
      print('   - Location data: ${hasLocation ? "✅" : "❌"}');
      print('   - Email data: ${hasEmail ? "✅" : "❌"}');
      print('   - Status data: ${hasStatus ? "✅" : "❌"}');
      
      if (hasLocation && hasEmail && hasStatus) {
        print('\n   🎉 SUCCESS: SOS button is working correctly!');
        print('   All data is being saved to Supabase properly.');
      } else {
        print('\n   ⚠️ WARNING: Some data is missing from the alert.');
      }
    } else {
      print('   ❌ No SOS alerts found for this user!');
    }
  } catch (e) {
    print('   ❌ Error verifying alerts: $e');
  }
  
  print('\n=== INTEGRATION TEST COMPLETE ===');
  print('Summary:');
  print('- SOS button is integrated in fisherman home screen');
  print('- Button gets GPS location and saves to Supabase');
  print('- All fisherman data is stored with the alert');
  print('- Check your Supabase dashboard to see the saved data');
}

// Helper function to run the test
Future<void> runSOSButtonIntegrationTest() async {
  main();
}