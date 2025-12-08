// Test SOS Alert Creation Flow
// This file tests the complete SOS alert creation process

import 'lib/models/sos_alert_model.dart';
import 'lib/models/user_model.dart';
import 'lib/services/location_service.dart';
import 'lib/services/database_service.dart';

void main() async {
  print('=== SOS Alert Creation Test ===\n');

  // Initialize services
  final locationService = LocationService();
  final databaseService = DatabaseService();

  try {
    // Test 1: Database Connection
    print('1. Testing database connection...');
    final connectionTest = await databaseService.testConnection();
    if (!connectionTest) {
      print('   ✗ Database connection failed');
      return;
    }
    print('   ✓ Database connection successful');

    // Test 2: Fishermen Table Access
    print('\n2. Testing fishermen table access...');
    final fishermenTest = await databaseService.testFishermenTable();
    if (!fishermenTest) {
      print('   ✗ Fishermen table access failed');
      return;
    }
    print('   ✓ Fishermen table accessible');

    // Test 3: Location Service
    print('\n3. Testing location service...');
    final position = await locationService.getLocationForSOS();
    if (position == null) {
      print('   ✗ Location service failed');
      print('   - Please enable location services');
      print('   - Ensure GPS is enabled');
      print('   - Try again in an open area');
      return;
    }
    print('   ✓ Location obtained:');
    print('   - Latitude: ${position.latitude}');
    print('   - Longitude: ${position.longitude}');
    print('   - Accuracy: ${position.accuracy} meters');

    // Test 4: Create Test User
    print('\n4. Creating test fisherman...');
    final testUser = UserModel(
      id: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      email: 'test_fisherman@example.com',
      firstName: 'Test',
      lastName: 'Fisherman',
      phone: '+1234567890',
    );

    // Test 5: Create Fisherman in Database
    print('\n5. Creating fisherman in database...');
    final fishermanId = await databaseService.createFisherman(
      email: testUser.email!,
      firstName: testUser.firstName!,
      lastName: testUser.lastName!,
      phone: testUser.phone!,
    );
    print('   ✓ Fisherman created with ID: $fishermanId');

    // Test 6: Create SOS Alert
    print('\n6. Creating SOS alert...');
    final sosAlert = SOSAlertModel(
      id: 'test_sos_${DateTime.now().millisecondsSinceEpoch}',
      fishermanId: fishermanId,
      latitude: position.latitude,
      longitude: position.longitude,
      message: 'Test SOS Alert - Emergency situation',
      status: 'active',
      createdAt: DateTime.now(),
    );

    print('   ✓ SOS Alert model created:');
    print('   - ID: ${sosAlert.id}');
    print('   - Fisherman ID: ${sosAlert.fishermanId}');
    print('   - Location: ${sosAlert.latitude}, ${sosAlert.longitude}');
    print('   - Message: ${sosAlert.message}');
    print('   - Status: ${sosAlert.status}');

    // Test 7: Save SOS Alert to Database
    print('\n7. Saving SOS alert to database...');
    final success = await databaseService.createSOSAlert(
      fishermanId: fishermanId,
      latitude: position.latitude,
      longitude: position.longitude,
      message: sosAlert.message,
    );

    if (!success) {
      print('   ✗ Failed to save SOS alert to database');
      return;
    }
    print('   ✓ SOS alert successfully saved to database!');

    // Test 8: Verify Alert in Database
    print('\n8. Verifying alert in database...');
    final alerts = await databaseService.getSOSAlerts();
    final testAlert = alerts.firstWhere(
      (alert) => alert['id'] == sosAlert.id,
      orElse: () => {},
    );

    if (testAlert.isEmpty) {
      print('   ✗ SOS alert not found in database');
      return;
    }

    print('   ✓ SOS alert found in database:');
    print('   - ID: ${testAlert['id']}');
    print('   - Fisherman UID: ${testAlert['fisherman_uid']}');
    print('   - Latitude: ${testAlert['latitude']}');
    print('   - Longitude: ${testAlert['longitude']}');
    print('   - Message: ${testAlert['message']}');
    print('   - Status: ${testAlert['status']}');
    print('   - Created At: ${testAlert['created_at']}');
    print('   - Fisherman Name: ${testAlert['fisherman_name']}');
    print('   - Fisherman Email: ${testAlert['fisherman_email']}');
    print('   - Fisherman Phone: ${testAlert['fisherman_phone']}');

    // Test 9: Update Alert Status
    print('\n9. Testing alert status update...');
    final updateSuccess = await databaseService.updateSOSAlertStatus(
      sosAlert.id,
      'resolved',
    );

    if (!updateSuccess) {
      print('   ✗ Failed to update alert status');
      return;
    }
    print('   ✓ Alert status updated to resolved');

    print('\n=== All Tests Passed ===');
    print('SOS Alert System is working correctly!');
    print('The system can:');
    print('✓ Connect to database');
    print('✓ Access fishermen table');
    print('✓ Get GPS location');
    print('✓ Create fisherman records');
    print('✓ Create SOS alerts');
    print('✓ Save alerts to database with denormalized fisherman data');
    print('✓ Update alert status');
    print('✓ Retrieve alerts from database');

  } catch (e) {
    print('\n=== Test Failed ===');
    print('Error: $e');
    print('Please check your database connection and configuration.');
  }
}























