// Debug script to test database connection and table structure
import 'lib/services/database_service.dart';
import 'lib/supabase_config.dart';

void main() async {
  print('=== Database Debug Script ===\n');

  // Initialize Supabase
  await SupabaseConfig.initialize();
  print('✓ Supabase initialized\n');

  final databaseService = DatabaseService();

  // Test 1: Database connection
  print('1. Testing database connection...');
  final connectionTest = await databaseService.testConnection();
  if (connectionTest) {
    print('   ✓ Database connection successful\n');
  } else {
    print('   ✗ Database connection failed\n');
    return;
  }

  // Test 2: Fishermen table
  print('2. Testing fishermen table...');
  final fishermenTest = await databaseService.testFishermenTable();
  if (fishermenTest) {
    print('   ✓ Fishermen table accessible\n');
  } else {
    print('   ✗ Fishermen table not accessible\n');
  }

  // Test 3: Create a test fisherman
  print('3. Creating test fisherman...');
  try {
    final fishermanId = await databaseService.createFisherman(
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'Fisherman',
      phone: '1234567890',
    );
    print('   ✓ Test fisherman created with ID: $fishermanId\n');

    // Test 4: Create SOS alert with the test fisherman
    print('4. Creating test SOS alert...');
    final sosSuccess = await databaseService.createSOSAlert(
      fishermanId: fishermanId,
      latitude: 11.7753,
      longitude: 124.8861,
      message: 'Debug test SOS alert',
    );

    if (sosSuccess) {
      print('   ✓ Test SOS alert created successfully\n');
    } else {
      print('   ✗ Test SOS alert creation failed\n');
    }

    // Test 5: Retrieve SOS alerts
    print('5. Retrieving SOS alerts...');
    final alerts = await databaseService.getSOSAlerts();
    print('   ✓ Found ${alerts.length} SOS alerts');
    for (var alert in alerts) {
      print('   - ID: ${alert['id']}');
      print('   - Fisherman ID: ${alert['fisherman_id']}');
      print('   - Location: ${alert['latitude']}, ${alert['longitude']}');
      print('   - Status: ${alert['status']}');
      print('   - Created: ${alert['created_at']}\n');
    }

  } catch (e) {
    print('   ✗ Error: $e\n');
  }

  print('=== Debug Complete ===');
}

































