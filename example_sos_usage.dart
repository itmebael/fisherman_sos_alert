// Example usage of the SOS Alert System
// This file demonstrates how the SOS alert functionality works

import 'lib/models/sos_alert_model.dart';
import 'lib/services/location_service.dart';
import 'lib/services/database_service.dart';

void main() async {
  print('=== SOS Alert System Demo ===\n');
  
  // Generate dynamic demo data
  final demoStartTime = DateTime.now();
  final randomSeed = demoStartTime.millisecondsSinceEpoch % 1000;
  
  print('Demo started at: ${demoStartTime.toIso8601String()}');
  print('Random seed: $randomSeed\n');

  // Initialize services
  final locationService = LocationService();
  final databaseService = DatabaseService();

  // Simulate getting GPS location
  print('1. Getting GPS location...');
  final position = await locationService.getLocationForSOS();
  
  if (position != null) {
    print('   ✓ GPS Location obtained:');
    print('   - Latitude: ${position.latitude}');
    print('   - Longitude: ${position.longitude}');
    print('   - Accuracy: ${position.accuracy} meters');
    print('   - Timestamp: ${position.timestamp}\n');

    // Create SOS alert model
    print('2. Creating SOS Alert...');
    
    // Dynamic emergency scenarios
    final emergencyScenarios = [
      'Engine failure - vessel adrift',
      'Medical emergency on board',
      'Vessel taking on water',
      'Navigation equipment failure',
      'Weather emergency - severe storm',
      'Collision with debris',
      'Fire on board',
      'Crew member overboard'
    ];
    
    final selectedScenario = emergencyScenarios[randomSeed % emergencyScenarios.length];
    final emergencyMessage = 'SOS: $selectedScenario - ${DateTime.now().toIso8601String()}';
    
    final sosAlert = SOSAlertModel(
      id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
      fishermanId: 'fisherman_${randomSeed.toString().padLeft(6, '0')}', // Dynamic fisherman ID with padding
      latitude: position.latitude,
      longitude: position.longitude,
      message: emergencyMessage, // Dynamic emergency message
      status: 'active',
      createdAt: DateTime.now(),
    );

    print('   ✓ SOS Alert created:');
    print('   - ID: ${sosAlert.id}');
    print('   - Fisherman ID: ${sosAlert.fishermanId}');
    print('   - Location: ${sosAlert.latitude}, ${sosAlert.longitude}');
    print('   - Message: ${sosAlert.message}');
    print('   - Status: ${sosAlert.status}');
    print('   - Created: ${sosAlert.createdAt}\n');

    // Convert to JSON (as it would be sent to database)
    print('3. Converting to database format...');
    final jsonData = sosAlert.toJson();
    print('   ✓ JSON data ready for database:');
    print('   - id: ${jsonData['id']}');
    print('   - fisherman_id: ${jsonData['fisherman_id']}');
    print('   - latitude: ${jsonData['latitude']}');
    print('   - longitude: ${jsonData['longitude']}');
    print('   - message: ${jsonData['message']}');
    print('   - status: ${jsonData['status']}');
    print('   - created_at: ${jsonData['created_at']}');
    print('   - resolved_at: ${jsonData['resolved_at']}\n');

    // Simulate database storage
    print('4. Storing in database...');
    try {
      final success = await databaseService.createSOSAlert(
        fishermanId: sosAlert.fishermanId,
        latitude: sosAlert.latitude,
        longitude: sosAlert.longitude,
        message: sosAlert.message,
      );

      if (success) {
        print('   ✓ SOS Alert successfully stored in database!');
        print('   ✓ Coast Guard has been notified!');
      } else {
        print('   ✗ Failed to store SOS Alert in database');
      }
    } catch (e) {
      print('   ✗ Error storing SOS Alert: $e');
    }

    // Demonstrate status update
    print('\n5. Updating alert status...');
    
    // Dynamic status progression
    final statusOptions = ['active', 'acknowledged', 'in_progress', 'resolved'];
    final currentStatusIndex = (randomSeed % (statusOptions.length - 1)) + 1; // Skip 'active' since we start with it
    final newStatus = statusOptions[currentStatusIndex];
    
    // Dynamic resolution time based on emergency type
    final baseMinutes = selectedScenario.contains('Medical') ? 10 : 
                       selectedScenario.contains('Fire') ? 5 :
                       selectedScenario.contains('Water') ? 15 : 8;
    final resolutionMinutes = baseMinutes + (randomSeed % 10);
    
    final resolvedAlert = sosAlert.copyWith(
      status: newStatus,
      resolvedAt: newStatus == 'resolved' ? DateTime.now().add(Duration(minutes: resolutionMinutes)) : null,
    );

    print('   ✓ Alert status updated:');
    print('   - Status: ${resolvedAlert.status}');
    print('   - Emergency type: $selectedScenario');
    print('   - Estimated resolution time: $resolutionMinutes minutes');
    if (resolvedAlert.resolvedAt != null) {
      print('   - Resolved at: ${resolvedAlert.resolvedAt}');
    }

  } else {
    print('   ✗ Failed to get GPS location');
    print('   - Please check location permissions');
    print('   - Ensure GPS is enabled');
    print('   - Try again in an open area');
  }

  print('\n=== Demo Complete ===');
  print('Demo completed at: ${DateTime.now().toIso8601String()}');
  print('Total demo duration: ${DateTime.now().difference(demoStartTime).inSeconds} seconds');
  print('\nThe SOS Alert System is ready for use!');
  print('Fishermen can now send emergency alerts with their GPS location.');
  print('System supports dynamic emergency scenarios and real-time status tracking.');
}

