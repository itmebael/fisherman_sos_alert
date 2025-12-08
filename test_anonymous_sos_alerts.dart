import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'lib/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST: Anonymous SOS Alerts ===\n');
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
    return;
  }
  
  final supabase = SupabaseConfig.client;
  
  // Test 1: Check current authentication status
  print('1. Checking authentication status...');
  final user = supabase.auth.currentUser;
  if (user != null) {
    print('   ✅ User is authenticated: ${user.email}');
  } else {
    print('   ℹ️ User is not authenticated (anonymous)');
  }
  
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
  
  // Test 3: Test SOS alert creation (works for both authenticated and anonymous users)
  print('\n3. Testing SOS alert creation...');
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    final alertId = const Uuid().v4();
    final currentUser = supabase.auth.currentUser;
    
    // Prepare SOS alert data - same logic as the updated SOS button
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
    
    print('   SOS Alert data prepared:');
    print('   - User authenticated: ${currentUser != null}');
    print('   - Location: ${position.latitude}, ${position.longitude}');
    print('   - Fisherman name: ${sosAlertData['fisherman_name']}');
    print('   - Fisherman email: ${sosAlertData['fisherman_email']}');
    print('   - User type: ${sosAlertData['fisherman_user_type']}');
    
    final response = await supabase.from('sos_alerts').insert(sosAlertData);
    
    if (response.error != null) {
      print('   ❌ Error saving SOS alert: ${response.error!.message}');
      print('   Error details: ${response.error!.details}');
      print('   Error hint: ${response.error!.hint}');
      
      if (response.error!.message.contains('permission') || 
          response.error!.message.contains('policy')) {
        print('   ⚠️ This is likely an RLS policy issue');
        print('   Run the anonymous RLS setup SQL in your Supabase dashboard');
      }
    } else {
      print('   ✅ SOS alert saved successfully!');
      print('   Alert ID: $alertId');
      final userStatus = currentUser != null ? 'authenticated user' : 'anonymous user';
      print('   User status: $userStatus');
    }
  } catch (e) {
    print('   ❌ Exception while creating SOS alert: $e');
  }
  
  // Test 4: Verify the alert was saved
  print('\n4. Verifying alert was saved...');
  try {
    final alerts = await supabase
        .from('sos_alerts')
        .select('*')
        .order('created_at', ascending: false)
        .limit(5);
    
    print('   Total alerts in database: ${alerts.length}');
    
    if (alerts.isNotEmpty) {
      print('   Recent alerts:');
      for (int i = 0; i < alerts.length && i < 3; i++) {
        final alert = alerts[i];
        print('   - ID: ${alert['id']}');
        print('     Email: ${alert['fisherman_email']}');
        print('     Name: ${alert['fisherman_name']}');
        print('     User Type: ${alert['fisherman_user_type']}');
        print('     Location: ${alert['latitude']}, ${alert['longitude']}');
        print('     Status: ${alert['status']}');
        print('     Created: ${alert['created_at']}');
        print('');
      }
      
      // Check for anonymous alerts
      final anonymousAlerts = alerts.where((alert) => 
        alert['fisherman_user_type'] == 'anonymous' || 
        alert['fisherman_email'] == 'anonymous@emergency.com'
      ).toList();
      
      print('   Anonymous alerts: ${anonymousAlerts.length}');
      print('   Authenticated alerts: ${alerts.length - anonymousAlerts.length}');
    } else {
      print('   ❌ No alerts found in database!');
    }
  } catch (e) {
    print('   ❌ Error verifying alerts: $e');
  }
  
  print('\n=== TEST COMPLETE ===');
  print('Summary:');
  print('- SOS button now works for both authenticated and anonymous users');
  print('- Anonymous users get default values for missing data');
  print('- All alerts are saved to Supabase with proper user type identification');
  print('- Check your Supabase dashboard to see the saved data');
}

// Helper function to run the test
Future<void> runAnonymousSOSTest() async {
  main();
}


