import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';
import 'lib/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== DEBUG: Fisherman Data Not Stored Issue ===\n');
  
  final databaseService = DatabaseService();
  final authService = AuthService();
  
  // Step 1: Check current authenticated user
  print('1. Checking current authenticated user...');
  final currentUser = authService.currentUser;
  if (currentUser != null) {
    print('   ✅ Current user found:');
    print('   ID: ${currentUser.id}');
    print('   Name: ${currentUser.name}');
    print('   Email: ${currentUser.email}');
    print('   Phone: ${currentUser.phone}');
    print('   User Type: ${currentUser.userType}\n');
  } else {
    print('   ❌ No authenticated user found!');
    print('   This is likely why fisherman data is not being stored.\n');
    return;
  }
  
  // Step 2: Check if fisherman exists in database
  print('2. Checking if fisherman exists in database...');
  final fisherman = await databaseService.getFishermanByEmail(currentUser.email ?? '');
  
  if (fisherman != null) {
    print('   ✅ Fisherman found in database:');
    print('   ID: ${fisherman['id']}');
    print('   Name: ${fisherman['first_name']} ${fisherman['last_name']}');
    print('   Email: ${fisherman['email']}');
    print('   Phone: ${fisherman['phone']}');
    print('   Active: ${fisherman['is_active']}');
    print('   All fields: $fisherman\n');
  } else {
    print('   ❌ No fisherman found in database for email: ${currentUser.email}');
    print('   This is why fisherman data is not being stored!\n');
    
    // Step 3: Create fisherman if not found
    print('3. Creating fisherman record...');
    try {
      final fishermanId = await databaseService.createFisherman(
        email: currentUser.email ?? '',
        firstName: currentUser.firstName ?? 'Unknown',
        lastName: currentUser.lastName ?? 'User',
        phone: currentUser.phone ?? '',
      );
      print('   ✅ Fisherman created with ID: $fishermanId\n');
    } catch (e) {
      print('   ❌ Error creating fisherman: $e\n');
    }
  }
  
  // Step 4: Test SOS alert creation with detailed logging
  print('4. Testing SOS alert creation with fisherman data...');
  try {
    // Get fisherman data again (in case we just created it)
    final fishermanData = await databaseService.getFishermanByEmail(currentUser.email ?? '');
    
    if (fishermanData != null) {
      print('   Creating SOS alert with fisherman data...');
      final result = await databaseService.createSOSAlert(
        fishermanId: fishermanData['id'] as String,
        latitude: 11.7753, // Catbalogan coordinates
        longitude: 124.8861,
        message: 'Debug test SOS alert with fisherman data',
      );
      
      if (result) {
        print('   ✅ SOS alert created successfully!');
      } else {
        print('   ❌ SOS alert creation failed!');
      }
    } else {
      print('   ❌ Still no fisherman data found!');
    }
  } catch (e) {
    print('   ❌ Error creating SOS alert: $e');
  }
  
  // Step 5: Check what was actually saved
  print('\n5. Checking what was actually saved in database...');
  try {
    final alerts = await databaseService.getSOSAlerts();
    print('   Total active SOS alerts: ${alerts.length}');
    
    if (alerts.isNotEmpty) {
      print('   Recent alerts:');
      for (int i = 0; i < alerts.length && i < 3; i++) {
        final alert = alerts[i];
        print('   - ID: ${alert['id']}');
        print('     Fisherman UID: ${alert['fisherman_uid']}');
        print('     Fisherman Name: ${alert['fisherman_first_name']} ${alert['fisherman_last_name']}');
        print('     Fisherman Email: ${alert['fisherman_email']}');
        print('     Fisherman Phone: ${alert['fisherman_phone']}');
        print('     Status: ${alert['status']}');
        print('     Location: ${alert['latitude']}, ${alert['longitude']}');
        print('     Message: ${alert['message']}');
        print('     Created: ${alert['created_at']}');
        print('');
      }
      
      // Check if any alerts have fisherman data
      final alertsWithData = alerts.where((alert) => 
        alert['fisherman_email'] != null && alert['fisherman_email'].toString().isNotEmpty
      ).toList();
      
      print('   Alerts with fisherman data: ${alertsWithData.length}');
      print('   Alerts without fisherman data: ${alerts.length - alertsWithData.length}');
    } else {
      print('   ❌ No SOS alerts found in database!');
    }
  } catch (e) {
    print('   ❌ Error checking alerts: $e');
  }
  
  // Step 6: Test direct fisherman lookup by ID
  print('\n6. Testing direct fisherman lookup by ID...');
  try {
    if (currentUser.id.isNotEmpty && currentUser.email != null) {
      final fishermanById = await databaseService.getFishermanByEmail(currentUser.email!);
      
      if (fishermanById != null) {
        print('   ✅ Fisherman found by ID: ${fishermanById['first_name']} ${fishermanById['last_name']}');
      } else {
        print('   ❌ No fisherman found by ID: ${currentUser.id}');
      }
    }
  } catch (e) {
    print('   ❌ Error looking up fisherman by ID: $e');
  }
  
  print('\n=== DEBUG COMPLETE ===');
  print('Summary:');
  print('- Check if user is authenticated');
  print('- Check if fisherman exists in database');
  print('- Create fisherman if missing');
  print('- Verify SOS alert includes fisherman data');
}

// Helper function to run the debug
Future<void> runFishermanDataDebug() async {
  main();
}


