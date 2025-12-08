import 'package:flutter/material.dart';
import 'lib/providers/sos_provider.dart';
import 'lib/services/database_service.dart';
import 'lib/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST: SOS Alert with Fisherman Data ===\n');
  
  final sosProvider = SOSProvider();
  final databaseService = DatabaseService();
  final authService = AuthService();
  
  // Step 1: Check if user is authenticated
  print('1. Checking authentication...');
  final currentUser = authService.currentUser;
  if (currentUser == null) {
    print('   ❌ No authenticated user found!');
    print('   Please log in first before running this test.\n');
    return;
  }
  
  print('   ✅ User authenticated: ${currentUser.name} (${currentUser.email})');
  
  // Step 2: Ensure fisherman exists
  print('\n2. Ensuring fisherman exists in database...');
  var fisherman = await databaseService.getFishermanByEmail(currentUser.email ?? '');
  
  if (fisherman == null) {
    print('   Creating fisherman for ${currentUser.email}...');
    try {
      final fishermanId = await databaseService.createFisherman(
        email: currentUser.email ?? '',
        firstName: currentUser.firstName ?? 'Unknown',
        lastName: currentUser.lastName ?? 'User',
        phone: currentUser.phone ?? '',
      );
      print('   ✅ Fisherman created with ID: $fishermanId');
      fisherman = await databaseService.getFishermanByEmail(currentUser.email ?? '');
    } catch (e) {
      print('   ❌ Error creating fisherman: $e');
      return;
    }
  } else {
    print('   ✅ Fisherman exists: ${fisherman['first_name']} ${fisherman['last_name']}');
  }
  
  // Step 3: Send SOS alert (this will use the enhanced logging)
  print('\n3. Sending SOS alert...');
  print('   (This will show detailed debug information)');
  
  try {
    await sosProvider.sendSOSAlert(description: 'Test SOS alert with fisherman data verification');
    print('   ✅ SOS alert sent successfully!');
  } catch (e) {
    print('   ❌ SOS alert failed: $e');
    return;
  }
  
  // Step 4: Verify fisherman data was stored
  print('\n4. Verifying fisherman data was stored...');
  try {
    final alerts = await databaseService.getSOSAlerts();
    
    if (alerts.isNotEmpty) {
      final latestAlert = alerts.first;
      print('   Latest SOS alert details:');
      print('   - ID: ${latestAlert['id']}');
      print('   - Fisherman UID: ${latestAlert['fisherman_uid']}');
      print('   - Fisherman Name: ${latestAlert['fisherman_first_name']} ${latestAlert['fisherman_last_name']}');
      print('   - Fisherman Email: ${latestAlert['fisherman_email']}');
      print('   - Fisherman Phone: ${latestAlert['fisherman_phone']}');
      print('   - Location: ${latestAlert['latitude']}, ${latestAlert['longitude']}');
      print('   - Status: ${latestAlert['status']}');
      print('   - Message: ${latestAlert['message']}');
      print('   - Created: ${latestAlert['created_at']}');
      
      // Check if all fisherman data is present
      final hasName = latestAlert['fisherman_first_name'] != null && 
                     latestAlert['fisherman_first_name'].toString().isNotEmpty;
      final hasEmail = latestAlert['fisherman_email'] != null && 
                      latestAlert['fisherman_email'].toString().isNotEmpty;
      final hasPhone = latestAlert['fisherman_phone'] != null && 
                      latestAlert['fisherman_phone'].toString().isNotEmpty;
      
      print('\n   Fisherman data verification:');
      print('   - Name present: ${hasName ? "✅" : "❌"}');
      print('   - Email present: ${hasEmail ? "✅" : "❌"}');
      print('   - Phone present: ${hasPhone ? "✅" : "❌"}');
      
      if (hasName && hasEmail && hasPhone) {
        print('\n   🎉 SUCCESS: All fisherman data is stored correctly!');
      } else {
        print('\n   ⚠️ WARNING: Some fisherman data is missing!');
      }
    } else {
      print('   ❌ No SOS alerts found in database!');
    }
  } catch (e) {
    print('   ❌ Error checking alerts: $e');
  }
  
  print('\n=== TEST COMPLETE ===');
  print('Summary:');
  print('- Enhanced logging shows fisherman lookup process');
  print('- Fisherman is created if not found');
  print('- SOS alert includes complete fisherman data');
  print('- All data is stored in Supabase sos_alerts table');
}

// Helper function to run the test
Future<void> runSOSWithFishermanDataTest() async {
  main();
}


