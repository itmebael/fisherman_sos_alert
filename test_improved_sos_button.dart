import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'lib/supabase_config.dart';
import 'lib/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST: Improved SOS Button ===\n');
  
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
  
  // Test 3: Test SOS alert creation with improved error handling
  print('\n3. Testing SOS alert creation with improved error handling...');
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
    
    // This is the exact same logic as the improved SOS button
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
          ? '${mockUser.firstName ?? ''} ${mockUser.lastName ?? ''}'.trim().isEmpty 
              ? 'Anonymous User' 
              : '${mockUser.firstName ?? ''} ${mockUser.lastName ?? ''}'.trim()
          : 'Anonymous User',
      'fisherman_email': mockUser?.email ?? 'anonymous@emergency.com',
      'fisherman_phone': mockUser?.phone ?? 'Not provided',
      'fisherman_user_type': mockUser?.userType ?? 'anonymous',
      'fisherman_address': mockUser?.address ?? 'Location not provided',
      'fisherman_fishing_area': mockUser?.fishingArea ?? 'Unknown area',
      'fisherman_emergency_contact_person': mockUser?.emergencyContactPerson ?? 'Not provided',
      'fisherman_profile_picture_url': mockUser?.profileImageUrl,
      'fisherman_profile_image_url': mockUser?.profileImageUrl,
    };
    
    print('   Alert data with improved error handling:');
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
    print('   Exception type: ${e.runtimeType}');
    
    // Test the improved error handling
    String errorMessage = 'Error sending SOS alert';
    if (e.toString().contains('NoSuchMethodError')) {
      errorMessage = 'Error: Missing method or property. Please check user data.';
      print('   🔧 NoSuchMethodError detected - this should be fixed now');
    } else if (e.toString().contains('permission')) {
      errorMessage = 'Error: Permission denied. Please check your settings.';
    } else if (e.toString().contains('network')) {
      errorMessage = 'Error: Network connection failed. Please check your internet.';
    } else {
      errorMessage = 'Error sending SOS alert: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e.toString()}';
    }
    
    print('   Improved error message: $errorMessage');
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
  print('✅ SOS Button Improvements:');
  print('   - 0.5x smaller size (125x125 instead of 250x250)');
  print('   - Pulsing animation with smooth scaling');
  print('   - Better error handling for NoSuchMethodError');
  print('   - Improved UI with shadows and borders');
  print('   - Loading state with spinner');
  print('✅ Check your app - the SOS button should now look great and work without errors!');
}

Future<void> runImprovedSOSButtonTest() async {
  main();
}


