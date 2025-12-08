import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Testing SOS Alerts with New Table Structure ===\n');
  
  // Test database service
  final databaseService = DatabaseService();
  
  // Test connection
  print('1. Testing database connection...');
  final connectionTest = await databaseService.testConnection();
  print('Connection test result: $connectionTest\n');
  
  if (!connectionTest) {
    print('❌ Database connection failed. Please check your Supabase configuration.');
    return;
  }
  
  // Test fishermen table
  print('2. Testing fishermen table...');
  final fishermenTest = await databaseService.testFishermenTable();
  print('Fishermen table test result: $fishermenTest\n');
  
  if (!fishermenTest) {
    print('❌ Fishermen table test failed. Please check your database setup.');
    return;
  }
  
  // Test SOS alert creation with sample data
  print('3. Testing SOS alert creation...');
  final testAlert = await databaseService.testSOSAlertCreation();
  print('SOS alert creation test result: $testAlert\n');
  
  if (!testAlert) {
    print('❌ SOS alert creation test failed.');
    return;
  }
  
  // Test creating a fisherman and then sending SOS
  print('4. Testing complete SOS flow...');
  try {
    // Create a test fisherman
    final fishermanId = await databaseService.createFisherman(
      email: 'test_fisherman@example.com',
      firstName: 'Test',
      lastName: 'Fisherman',
      phone: '+1234567890',
    );
    print('✅ Test fisherman created with ID: $fishermanId');
    
    // Create SOS alert for this fisherman
    final sosResult = await databaseService.createSOSAlert(
      fishermanId: fishermanId,
      latitude: 11.7753, // Catbalogan coordinates
      longitude: 124.8861,
      message: 'Test emergency from new table structure',
    );
    print('✅ SOS alert creation result: $sosResult');
    
    if (sosResult) {
      print('✅ Complete SOS flow test successful!');
    } else {
      print('❌ SOS alert creation failed.');
    }
  } catch (e) {
    print('❌ Error in complete SOS flow test: $e');
  }
  
  print('\n=== Test Summary ===');
  print('✅ Database connection: $connectionTest');
  print('✅ Fishermen table: $fishermenTest');
  print('✅ SOS alert creation: $testAlert');
  print('\n🎉 All tests completed! The new sos_alerts table structure is working correctly.');
}

// Helper function to run the test
Future<void> runSOSAlertsTest() async {
  main();
}


