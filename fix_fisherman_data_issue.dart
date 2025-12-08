import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';
import 'lib/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== FIX: Fisherman Data Not Stored Issue ===\n');
  
  final databaseService = DatabaseService();
  final authService = AuthService();
  
  // Step 1: Check current user
  print('1. Checking current authenticated user...');
  final currentUser = authService.currentUser;
  if (currentUser == null) {
    print('   ❌ No authenticated user found!');
    print('   Please log in first before sending SOS alerts.\n');
    return;
  }
  
  print('   ✅ Current user: ${currentUser.name} (${currentUser.email})');
  
  // Step 2: Check if fisherman exists
  print('\n2. Checking if fisherman exists in database...');
  var fisherman = await databaseService.getFishermanByEmail(currentUser.email ?? '');
  
  if (fisherman == null) {
    print('   ❌ No fisherman found for email: ${currentUser.email}');
    print('   Creating fisherman record...');
    
    try {
      final fishermanId = await databaseService.createFisherman(
        email: currentUser.email ?? '',
        firstName: currentUser.firstName ?? 'Unknown',
        lastName: currentUser.lastName ?? 'User',
        phone: currentUser.phone ?? '',
      );
      print('   ✅ Fisherman created with ID: $fishermanId');
      
      // Get the created fisherman
      fisherman = await databaseService.getFishermanByEmail(currentUser.email ?? '');
    } catch (e) {
      print('   ❌ Error creating fisherman: $e');
      return;
    }
  } else {
    print('   ✅ Fisherman found: ${fisherman['first_name']} ${fisherman['last_name']}');
  }
  
  // Step 3: Test SOS alert creation
  print('\n3. Testing SOS alert creation with fisherman data...');
  try {
    final result = await databaseService.createSOSAlert(
      fishermanId: fisherman!['id'] as String,
      latitude: 11.7753,
      longitude: 124.8861,
      message: 'Test SOS alert with complete fisherman data',
    );
    
    if (result) {
      print('   ✅ SOS alert created successfully!');
    } else {
      print('   ❌ SOS alert creation failed!');
    }
  } catch (e) {
    print('   ❌ Error creating SOS alert: $e');
  }
  
  // Step 4: Verify the data was saved
  print('\n4. Verifying fisherman data was saved...');
  try {
    final alerts = await databaseService.getSOSAlerts();
    
    if (alerts.isNotEmpty) {
      final latestAlert = alerts.first;
      print('   Latest alert details:');
      print('   - ID: ${latestAlert['id']}');
      print('   - Fisherman UID: ${latestAlert['fisherman_uid']}');
      print('   - Fisherman Name: ${latestAlert['fisherman_first_name']} ${latestAlert['fisherman_last_name']}');
      print('   - Fisherman Email: ${latestAlert['fisherman_email']}');
      print('   - Fisherman Phone: ${latestAlert['fisherman_phone']}');
      print('   - Location: ${latestAlert['latitude']}, ${latestAlert['longitude']}');
      print('   - Status: ${latestAlert['status']}');
      
      // Check if fisherman data is present
      final hasFishermanData = latestAlert['fisherman_email'] != null && 
                              latestAlert['fisherman_email'].toString().isNotEmpty;
      
      if (hasFishermanData) {
        print('   ✅ Fisherman data is present in SOS alert!');
      } else {
        print('   ❌ Fisherman data is missing from SOS alert!');
      }
    } else {
      print('   ❌ No SOS alerts found!');
    }
  } catch (e) {
    print('   ❌ Error checking alerts: $e');
  }
  
  print('\n=== FIX COMPLETE ===');
}

// Helper function to run the fix
Future<void> runFishermanDataFix() async {
  main();
}


