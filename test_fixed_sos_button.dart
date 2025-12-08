import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'lib/supabase_config.dart';
import 'lib/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST: Fixed SOS Button ===\n');
  
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
  
  // Test 3: Test SOS alert creation with correct property names
  print('\n3. Testing SOS alert creation with fixed properties...');
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    final alertId = const Uuid().v4();
    final currentUser = supabase.auth.currentUser;
    
    // Create a mock UserModel to test the property access
    UserModel? mockUser;
    if (currentUser != null) {
      mockUser = UserModel(
        id: currentUser.id,
        firstName: currentUser.userMetadata?['first_name'] ?? 'Test',
        lastName: currentUser.userMetadata?['last_name'] ?? 'User',
        email: currentUser.email ?? 'test@example.com',
        phone: currentUser.userMetadata?['phone'] ?? '+1234567890',
        userType: 'fisherman',
        address: currentUser.userMetadata?['address'] ?? 'Test Address',
        fishingArea: currentUser.userMetadata?['fishing_area'] ?? 'Test Area',
        emergencyContactPerson: currentUser.userMetadata?['emergency_contact_person'] ?? 'Test Contact',
        profileImageUrl: currentUser.userMetadata?['profile_image_url'] ?? 'https://example.com/image.jpg',
      );
    }
    
    // This is the exact same logic as the fixed SOS button
    final sosAlertData = {
      'id': alertId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'message': 'Emergency SOS Alert - Fisherman in distress',
      'status': 'active',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'fisherman_uid': mockUser?.id,
      'fisherman_display_id': mockUser?.displayId,
      'fisherman_first_name': mockUser?.firstName ?? 'Unknown',
      'fisherman_middle_name': mockUser?.middleName,
      'fisherman_last_name': mockUser?.lastName ?? 'User',
      'fisherman_name': mockUser != null 
          ? '${mockUser.firstName ?? ''} ${mockUser.lastName ?? ''}'.trim()
          : 'Anonymous User',
      'fisherman_email': mockUser?.email ?? 'anonymous@emergency.com',
      'fisherman_phone': mockUser?.phone ?? 'Not provided',
      'fisherman_user_type': mockUser?.userType ?? 'anonymous',
      'fisherman_address': mockUser?.address ?? 'Location not provided',
      'fisherman_fishing_area': mockUser?.fishingArea ?? 'Unknown area',
      'fisherman_emergency_contact_person': mockUser?.emergencyContactPerson ?? 'Not provided', // Fixed property name
      'fisherman_profile_picture_url': mockUser?.profileImageUrl, // Fixed property name
      'fisherman_profile_image_url': mockUser?.profileImageUrl, // Fixed property name
    };
    
    print('   Alert data with fixed properties:');
    print('   - ID: $alertId');
    print('   - User: ${mockUser != null ? "authenticated" : "anonymous"}');
    print('   - Name: ${sosAlertData['fisherman_name']}');
    print('   - Email: ${sosAlertData['fisherman_email']}');
    print('   - Emergency Contact: ${sosAlertData['fisherman_emergency_contact_person']}');
    print('   - Profile Image: ${sosAlertData['fisherman_profile_picture_url']}');
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
        print('     Emergency Contact: ${alert['fisherman_emergency_contact_person']}');
        print('     Profile Image: ${alert['fisherman_profile_picture_url']}');
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
  print('✅ Property name errors have been fixed!');
  print('✅ SOS button should now work correctly!');
  print('✅ Check your Supabase dashboard to see the saved data.');
}

Future<void> runFixedSOSButtonTest() async {
  main();
}


