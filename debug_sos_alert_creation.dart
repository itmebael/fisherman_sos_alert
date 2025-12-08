import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== DEBUG: SOS Alert Creation Process ===\n');
  
  final databaseService = DatabaseService();
  
  // Step 1: Test database connection
  print('1. Testing database connection...');
  final connectionTest = await databaseService.testConnection();
  print('   Connection test result: $connectionTest');
  if (!connectionTest) {
    print('   ❌ Database connection failed!');
    return;
  }
  print('   ✅ Database connection successful\n');
  
  // Step 2: Test fishermen table
  print('2. Testing fishermen table...');
  final fishermenTest = await databaseService.testFishermenTable();
  print('   Fishermen table test result: $fishermenTest');
  if (!fishermenTest) {
    print('   ❌ Fishermen table test failed!');
    return;
  }
  print('   ✅ Fishermen table accessible\n');
  
  // Step 3: Check if fisherman exists for cain22@gmail.com
  print('3. Checking fisherman data for cain22@gmail.com...');
  try {
    final fisherman = await databaseService.getFishermanByEmail('cain22@gmail.com');
    if (fisherman != null) {
      print('   ✅ Fisherman found:');
      print('   ID: ${fisherman['id']}');
      print('   Name: ${fisherman['first_name']} ${fisherman['last_name']}');
      print('   Email: ${fisherman['email']}');
      print('   Phone: ${fisherman['phone']}');
      print('   Active: ${fisherman['is_active']}\n');
    } else {
      print('   ❌ No fisherman found for cain22@gmail.com');
      print('   This might be why SOS alerts are not being saved.\n');
    }
  } catch (e) {
    print('   ❌ Error checking fisherman: $e\n');
  }
  
  // Step 4: Test SOS alert creation with sample data
  print('4. Testing SOS alert creation...');
  try {
    // First, let's try to create a fisherman if one doesn't exist
    String fishermanId;
    final existingFisherman = await databaseService.getFishermanByEmail('cain22@gmail.com');
    
    if (existingFisherman != null) {
      fishermanId = existingFisherman['id'] as String;
      print('   Using existing fisherman ID: $fishermanId');
    } else {
      print('   Creating new fisherman for cain22@gmail.com...');
      fishermanId = await databaseService.createFisherman(
        email: 'cain22@gmail.com',
        firstName: 'Cain',
        lastName: 'User',
        phone: '+1234567890',
      );
      print('   ✅ New fisherman created with ID: $fishermanId');
    }
    
    // Now test SOS alert creation
    print('   Creating SOS alert...');
    final sosResult = await databaseService.createSOSAlert(
      fishermanId: fishermanId,
      latitude: 11.7753, // Catbalogan coordinates
      longitude: 124.8861,
      message: 'Debug test SOS alert from cain22@gmail.com',
    );
    
    if (sosResult) {
      print('   ✅ SOS alert created successfully!');
    } else {
      print('   ❌ SOS alert creation failed!');
    }
  } catch (e) {
    print('   ❌ Error in SOS alert creation: $e');
    print('   Error details: ${e.toString()}');
  }
  
  // Step 5: Check if the alert was actually saved
  print('\n5. Verifying SOS alert was saved...');
  try {
    final alerts = await databaseService.getSOSAlerts();
    print('   Total active SOS alerts: ${alerts.length}');
    
    if (alerts.isNotEmpty) {
      print('   Recent alerts:');
      for (int i = 0; i < alerts.length && i < 3; i++) {
        final alert = alerts[i];
        print('   - ID: ${alert['id']}');
        print('     Fisherman: ${alert['fisherman_first_name']} ${alert['fisherman_last_name']}');
        print('     Email: ${alert['fisherman_email']}');
        print('     Status: ${alert['status']}');
        print('     Created: ${alert['created_at']}');
        print('     Message: ${alert['message']}');
        print('');
      }
    } else {
      print('   ❌ No SOS alerts found in database!');
    }
  } catch (e) {
    print('   ❌ Error checking SOS alerts: $e');
  }
  
  print('=== DEBUG COMPLETE ===');
}

// Helper function to run the debug
Future<void> runSOSDebug() async {
  main();
}


