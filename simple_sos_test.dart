import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';
import 'lib/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== SIMPLE SOS ALERT TEST ===\n');
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    print('❌ Error initializing Supabase: $e\n');
    return;
  }
  
  final supabase = SupabaseConfig.client;
  final databaseService = DatabaseService();
  
  // Test 1: Check if fisherman exists (without is_active filter)
  print('1. Checking fisherman data for cain22@gmail.com (without is_active filter)...');
  try {
    final response = await supabase
        .from('fishermen')
        .select()
        .eq('email', 'cain22@gmail.com')
        .maybeSingle();
    
    if (response != null) {
      print('   ✅ Fisherman found:');
      print('   ID: ${response['id']}');
      print('   Name: ${response['first_name']} ${response['last_name']}');
      print('   Email: ${response['email']}');
      print('   Active: ${response['is_active']}');
      print('   All fields: $response\n');
    } else {
      print('   ❌ No fisherman found for cain22@gmail.com\n');
    }
  } catch (e) {
    print('   ❌ Error checking fisherman: $e\n');
  }
  
  // Test 2: Try to create a simple SOS alert directly
  print('2. Testing direct SOS alert creation...');
  try {
    final alertData = {
      'id': 'test_sos_${DateTime.now().millisecondsSinceEpoch}',
      'fisherman_uid': 'test_fisherman_id',
      'latitude': 11.7753,
      'longitude': 124.8861,
      'message': 'Direct test SOS alert',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'resolved_at': null,
      'fisherman_email': 'cain22@gmail.com',
      'fisherman_first_name': 'Cain',
      'fisherman_last_name': 'Test',
    };
    
    print('   Alert data: $alertData');
    
    final response = await supabase
        .from('sos_alerts')
        .insert(alertData)
        .select();
    
    print('   ✅ Direct SOS alert created successfully: $response\n');
  } catch (e) {
    print('   ❌ Error creating direct SOS alert: $e');
    print('   Error details: ${e.toString()}\n');
  }
  
  // Test 3: Check if the alert was saved
  print('3. Checking if alert was saved...');
  try {
    final alerts = await databaseService.getSOSAlerts();
    
    print('   Recent SOS alerts:');
    for (int i = 0; i < alerts.length && i < 5; i++) {
      final alert = alerts[i];
      print('   - ID: ${alert['id']}');
      print('     Email: ${alert['fisherman_email']}');
      print('     Status: ${alert['status']}');
      print('     Created: ${alert['created_at']}');
      print('');
    }
  } catch (e) {
    print('   ❌ Error checking alerts: $e\n');
  }
  
  print('=== TEST COMPLETE ===');
}


