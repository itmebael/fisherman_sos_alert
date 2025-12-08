import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'lib/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== DEBUG: Supabase Connection and Data Storage ===\n');
  
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
  print('\n1. Checking authentication...');
  final user = supabase.auth.currentUser;
  if (user == null) {
    print('   ❌ No authenticated user found!');
    print('   Please log in first before testing SOS button.\n');
    
    // Try to sign in with a test user (you'll need to create this)
    print('   Attempting to sign in with test user...');
    try {
      final response = await supabase.auth.signInWithPassword(
        email: 'cain22@gmail.com',
        password: 'password123', // You'll need to set this password
      );
      
      if (response.user != null) {
        print('   ✅ Test user signed in successfully');
      } else {
        print('   ❌ Failed to sign in test user');
        print('   Please create a user account first or sign in manually');
        return;
      }
    } catch (e) {
      print('   ❌ Error signing in: $e');
      print('   Please sign in manually in the app first');
      return;
    }
  } else {
    print('   ✅ User authenticated: ${user.email}');
    print('   User ID: ${user.id}');
  }
  
  // Test 2: Check if sos_alerts table exists
  print('\n2. Checking if sos_alerts table exists...');
  try {
    await supabase
        .from('sos_alerts')
        .select('id')
        .limit(1);
    
    print('   ✅ sos_alerts table exists and is accessible');
  } catch (e) {
    print('   ❌ Error accessing sos_alerts table: $e');
    print('   Table might not exist or RLS is blocking access');
    return;
  }
  
  // Test 3: Check RLS policies
  print('\n3. Testing RLS policies...');
  try {
    // Try to insert a test record
    final testData = {
      'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'latitude': 11.7753,
      'longitude': 124.8861,
      'message': 'Test RLS policy',
      'status': 'active',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'fisherman_uid': supabase.auth.currentUser?.id,
      'fisherman_email': supabase.auth.currentUser?.email,
    };
    
    try {
      await supabase.from('sos_alerts').insert(testData);
      
      print('   ✅ RLS policies are working correctly');
      
      // Clean up test record
      await supabase
          .from('sos_alerts')
          .delete()
          .eq('id', testData['id'] as String);
      print('   ✅ Test record cleaned up');
    } catch (e) {
      print('   ❌ RLS policy test failed: $e');
      final errorMsg = e.toString();
      
      if (errorMsg.contains('permission') || 
          errorMsg.contains('policy')) {
        print('   ⚠️ This is likely an RLS policy issue');
        print('   Run the RLS setup SQL in your Supabase dashboard');
      }
    }
  } catch (e) {
    print('   ❌ Exception testing RLS: $e');
  }
  
  // Test 4: Test location permissions
  print('\n4. Testing location permissions...');
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
    
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('   ✅ Location obtained: ${position.latitude}, ${position.longitude}');
  } catch (e) {
    print('   ❌ Error with location: $e');
    return;
  }
  
  // Test 5: Test complete SOS alert creation
  print('\n5. Testing complete SOS alert creation...');
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    final alertId = const Uuid().v4();
    final currentUser = supabase.auth.currentUser!;
    
    final sosAlertData = {
      'id': alertId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'message': 'Debug test SOS alert',
      'status': 'active',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'fisherman_uid': currentUser.id,
      'fisherman_display_id': currentUser.userMetadata?['display_id'],
      'fisherman_first_name': currentUser.userMetadata?['first_name'],
      'fisherman_middle_name': currentUser.userMetadata?['middle_name'],
      'fisherman_last_name': currentUser.userMetadata?['last_name'],
      'fisherman_name': '${currentUser.userMetadata?['first_name'] ?? ''} ${currentUser.userMetadata?['last_name'] ?? ''}',
      'fisherman_email': currentUser.email,
      'fisherman_phone': currentUser.userMetadata?['phone'],
      'fisherman_user_type': 'fisherman',
      'fisherman_address': currentUser.userMetadata?['address'],
      'fisherman_fishing_area': currentUser.userMetadata?['fishing_area'],
      'fisherman_emergency_contact_person': currentUser.userMetadata?['emergency_contact'],
      'fisherman_profile_picture_url': currentUser.userMetadata?['profile_picture_url'],
      'fisherman_profile_image_url': currentUser.userMetadata?['profile_image_url'],
    };
    
    print('   Alert data prepared:');
    print('   - ID: $alertId');
    print('   - Email: ${currentUser.email}');
    print('   - Location: ${position.latitude}, ${position.longitude}');
    print('   - Fields: ${sosAlertData.length}');
    
    try {
      await supabase.from('sos_alerts').insert(sosAlertData);
      print('   ✅ SOS alert saved successfully!');
      print('   Alert ID: $alertId');
    } catch (e) {
      print('   ❌ Error saving SOS alert: $e');
      print('   Error details: ${e.toString()}');
    }
  } catch (e) {
    print('   ❌ Exception while creating SOS alert: $e');
  }
  
  // Test 6: Verify data was saved
  print('\n6. Verifying data was saved...');
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
        print('     Location: ${alert['latitude']}, ${alert['longitude']}');
        print('     Status: ${alert['status']}');
        print('     Created: ${alert['created_at']}');
        print('');
      }
    } else {
      print('   ❌ No alerts found in database!');
    }
  } catch (e) {
    print('   ❌ Error verifying alerts: $e');
  }
  
  print('\n=== DEBUG COMPLETE ===');
  print('Next steps:');
  print('1. If RLS policy errors: Run the RLS setup SQL');
  print('2. If authentication errors: Sign in to the app first');
  print('3. If table errors: Create the sos_alerts table');
  print('4. Check your Supabase dashboard for the data');
}

// Helper function to run the debug
Future<void> runSupabaseDebug() async {
  main();
}


