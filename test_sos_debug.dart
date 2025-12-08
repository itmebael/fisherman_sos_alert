import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== SOS ALERT DEBUG TEST ===\n');
  
  final databaseService = DatabaseService();
  
  // Test 1: Check fisherman data
  print('1. Checking fisherman data for cain22@gmail.com...');
  final fisherman = await databaseService.getFishermanByEmail('cain22@gmail.com');
  
  if (fisherman == null) {
    print('   ❌ No fisherman found. Creating one...');
    try {
      final fishermanId = await databaseService.createFisherman(
        email: 'cain22@gmail.com',
        firstName: 'Cain',
        lastName: 'User',
        phone: '+1234567890',
      );
      print('   ✅ Fisherman created with ID: $fishermanId');
      
      // Now try to create SOS alert
      print('\n2. Creating SOS alert...');
      final result = await databaseService.createSOSAlert(
        fishermanId: fishermanId,
        latitude: 11.7753,
        longitude: 124.8861,
        message: 'Test SOS alert from cain22@gmail.com',
      );
      
      if (result) {
        print('   ✅ SOS alert created successfully!');
      } else {
        print('   ❌ SOS alert creation failed!');
      }
    } catch (e) {
      print('   ❌ Error: $e');
    }
  } else {
    print('   ✅ Fisherman found: ${fisherman['first_name']} ${fisherman['last_name']}');
    print('   ID: ${fisherman['id']}');
    print('   Active: ${fisherman['is_active']}');
    
    // Try to create SOS alert
    print('\n2. Creating SOS alert...');
    final result = await databaseService.createSOSAlert(
      fishermanId: fisherman['id'] as String,
      latitude: 11.7753,
      longitude: 124.8861,
      message: 'Test SOS alert from existing fisherman',
    );
    
    if (result) {
      print('   ✅ SOS alert created successfully!');
    } else {
      print('   ❌ SOS alert creation failed!');
    }
  }
  
  // Test 3: Check if alerts were saved
  print('\n3. Checking saved alerts...');
  try {
    final alerts = await databaseService.getSOSAlerts();
    print('   Total active alerts: ${alerts.length}');
    
    if (alerts.isNotEmpty) {
      print('   Recent alerts:');
      for (final alert in alerts.take(3)) {
        print('   - ${alert['id']}: ${alert['fisherman_email']} (${alert['status']})');
      }
    }
  } catch (e) {
    print('   ❌ Error checking alerts: $e');
  }
  
  print('\n=== DEBUG COMPLETE ===');
}


