import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import 'connection_service.dart';

class DatabaseService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final ConnectionService _connectionService = ConnectionService();

  // Test database connection
  Future<bool> testConnection() async {
    try {
      print('Testing database connection...');
      final response = await _supabase
          .from('sos_alerts')
          .select('id')
          .limit(1);
      print('Database connection test successful: $response');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      print('Error details: ${e.toString()}');
      return false;
    }
  }

  // Test if fishermen table exists and has correct structure
  Future<bool> testFishermenTable() async {
    try {
      print('Testing fishermen table...');
      final response = await _supabase
          .from('fishermen')
          .select('id, email, first_name, last_name')
          .limit(1);
      print('Fishermen table test successful: $response');
      return true;
    } catch (e) {
      print('Fishermen table test failed: $e');
      print('Error details: ${e.toString()}');
      return false;
    }
  }

  // Device Management Methods

  // Get all devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    return await _connectionService.executeWithRetry(() async {
      final response = await _supabase
          .from('devices')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  // Get devices for map display
  Future<List<Map<String, dynamic>>> getDevicesForMap() async {
    return await _connectionService.executeWithRetry(() async {
      final response = await _supabase
          .from('devices')
          .select('*')
          .eq('show_on_map', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  // Add a new device
  Future<String> addDevice(Map<String, dynamic> deviceData) async {
    return await _connectionService.executeWithRetry(() async {
      final response = await _supabase
          .from('devices')
          .insert(deviceData)
          .select('id')
          .single();
      return response['id'] as String;
    });
  }

  // Update device
  Future<void> updateDevice(String deviceId, Map<String, dynamic> deviceData) async {
    await _connectionService.executeWithRetry(() async {
      await _supabase
          .from('devices')
          .update(deviceData)
          .eq('id', deviceId);
    });
  }

  // Delete device
  Future<void> deleteDevice(String deviceId) async {
    await _connectionService.executeWithRetry(() async {
      await _supabase
          .from('devices')
          .delete()
          .eq('id', deviceId);
    });
  }

  // Toggle device status
  Future<void> toggleDeviceStatus(String deviceId, bool isActive) async {
    await _connectionService.executeWithRetry(() async {
      await _supabase
          .from('devices')
          .update({'is_active': isActive})
          .eq('id', deviceId);
    });
  }

  // Get device statistics
  Future<Map<String, int>> getDeviceStatistics() async {
    return await _connectionService.executeWithRetry(() async {
      final response = await _supabase
          .from('devices')
          .select('is_active, device_type, status');
      
      final devices = List<Map<String, dynamic>>.from(response);
      
      return {
        'total_devices': devices.length,
        'active_devices': devices.where((d) => d['is_active'] == true).length,
        'inactive_devices': devices.where((d) => d['is_active'] == false).length,
        'maintenance_devices': devices.where((d) => d['status'] == 'maintenance').length,
        'sos_devices': devices.where((d) => d['device_type'] == 'SOS').length,
        'gps_devices': devices.where((d) => d['device_type'] == 'GPS').length,
        'emergency_devices': devices.where((d) => d['device_type'] == 'Emergency').length,
      };
    });
  }

  // Search devices
  Future<List<Map<String, dynamic>>> searchDevices({
    String? searchQuery,
    String? deviceType,
    String? status,
    bool? isActive,
  }) async {
    return await _connectionService.executeWithRetry(() async {
      var query = _supabase.from('devices').select('*');
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('device_number.ilike.%$searchQuery%,fisherman_display_id.ilike.%$searchQuery%,fisherman_first_name.ilike.%$searchQuery%,fisherman_last_name.ilike.%$searchQuery%,fisherman_email.ilike.%$searchQuery%');
      }
      
      if (deviceType != null && deviceType != 'All') {
        query = query.eq('device_type', deviceType);
      }
      
      if (status != null && status != 'All') {
        if (status == 'Active') {
          query = query.eq('is_active', true);
        } else if (status == 'Inactive') {
          query = query.eq('is_active', false);
        } else {
          query = query.eq('status', status.toLowerCase());
        }
      }
      
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  // Send device signal (like SOS alert)
  Future<void> sendDeviceSignal(String deviceId, {
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    await _connectionService.executeWithRetry(() async {
      await _supabase
          .from('devices')
          .update({
            'is_sending_signal': true,
            'last_signal_sent': DateTime.now().toIso8601String(),
            'signal_message': message,
            'latitude': latitude,
            'longitude': longitude,
            'last_used': DateTime.now().toIso8601String(),
          })
          .eq('id', deviceId);
    });
  }

  // Stop device signal
  Future<void> stopDeviceSignal(String deviceId) async {
    await _connectionService.executeWithRetry(() async {
      await _supabase
          .from('devices')
          .update({
            'is_sending_signal': false,
          })
          .eq('id', deviceId);
    });
  }

  // Get devices currently sending signals
  Future<List<Map<String, dynamic>>> getDevicesSendingSignals() async {
    return await _connectionService.executeWithRetry(() async {
      final response = await _supabase
          .from('devices')
          .select('*')
          .eq('is_sending_signal', true)
          .order('last_signal_sent', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  // Get all SOS alerts (active only)
  Future<List<Map<String, dynamic>>> getSOSAlerts() async {
    try {
      print('=== FETCHING ACTIVE SOS ALERTS ===');
      return await _connectionService.executeWithRetry(() async {
        try {
          final response = await _supabase
              .from('sos_alerts')
              .select('*')
              .eq('status', 'active')
              .order('created_at', ascending: false);

          print('✅ Active SOS alerts fetched: ${response.length} records');
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          print('❌ Error fetching active SOS alerts: $e');
          print('Error type: ${e.runtimeType}');
          print('Error details: ${e.toString()}');
          if (e.toString().contains('permission') || e.toString().contains('RLS')) {
            print('⚠️ This might be an RLS (Row Level Security) issue');
          }
          rethrow;
        }
      });
    } catch (e) {
      print('❌ Failed to fetch active SOS alerts after retries: $e');
      return [];
    }
  }

  // Get all SOS alerts (all statuses)
  Future<List<Map<String, dynamic>>> getAllSOSAlerts() async {
    try {
      print('=== FETCHING ALL SOS ALERTS ===');
      return await _connectionService.executeWithRetry(() async {
        try {
          final response = await _supabase
              .from('sos_alerts')
              .select('*')
              .order('created_at', ascending: false)
              .limit(100);

          print('✅ All SOS alerts fetched: ${response.length} records');
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          print('❌ Error fetching all SOS alerts: $e');
          print('Error type: ${e.runtimeType}');
          print('Error details: ${e.toString()}');
          if (e.toString().contains('permission') || e.toString().contains('RLS')) {
            print('⚠️ This might be an RLS (Row Level Security) issue');
          }
          rethrow;
        }
      });
    } catch (e) {
      print('❌ Failed to fetch all SOS alerts after retries: $e');
      return [];
    }
  }

  // Get stream of SOS alerts for real-time updates
  Stream<List<Map<String, dynamic>>> getSOSAlertsStream() {
    return _supabase
        .from('sos_alerts')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('created_at', ascending: false);
  }

  // ============================================
  // Live Location Tracking Methods
  // ============================================

  // Update or insert live location for a fisherman
  Future<void> updateLiveLocation({
    required String? fishermanUid,
    required String? fishermanEmail,
    String? fishermanDisplayId,
    String? fishermanName,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    double? altitude,
  }) async {
    try {
      await _connectionService.executeWithRetry(() async {
        // Try to use the upsert function first (more efficient)
        try {
          await _supabase.rpc('upsert_live_location', params: {
            'p_fisherman_uid': fishermanUid,
            'p_fisherman_email': fishermanEmail,
            'p_fisherman_display_id': fishermanDisplayId,
            'p_fisherman_name': fishermanName,
            'p_latitude': latitude,
            'p_longitude': longitude,
            'p_accuracy': accuracy,
            'p_speed': speed,
            'p_heading': heading,
            'p_altitude': altitude,
          });
        } catch (e) {
          // If function doesn't exist, fall back to manual upsert
          print('Upsert function not available, using manual upsert: $e');
          
          // Check if location exists for this fisherman
          final existing = await _supabase
              .from('live_locations')
              .select('id')
              .eq('fisherman_uid', fishermanUid ?? '')
              .eq('is_active', true)
              .maybeSingle();

          if (existing != null) {
            // Update existing location
            await _supabase
                .from('live_locations')
                .update({
                  'latitude': latitude,
                  'longitude': longitude,
                  'accuracy': accuracy,
                  'speed': speed,
                  'heading': heading,
                  'altitude': altitude,
                  'updated_at': DateTime.now().toIso8601String(),
                  'is_active': true,
                  if (fishermanEmail != null) 'fisherman_email': fishermanEmail,
                  if (fishermanDisplayId != null) 'fisherman_display_id': fishermanDisplayId,
                  if (fishermanName != null) 'fisherman_name': fishermanName,
                })
                .eq('id', existing['id']);
          } else {
            // Insert new location
            await _supabase
                .from('live_locations')
                .insert({
                  'fisherman_uid': fishermanUid,
                  'fisherman_email': fishermanEmail,
                  'fisherman_display_id': fishermanDisplayId,
                  'fisherman_name': fishermanName,
                  'latitude': latitude,
                  'longitude': longitude,
                  'accuracy': accuracy,
                  'speed': speed,
                  'heading': heading,
                  'altitude': altitude,
                  'updated_at': DateTime.now().toIso8601String(),
                  'is_active': true,
                });
          }
        }
      });
    } catch (e) {
      print('Error updating live location: $e');
      // Don't throw - location updates should be resilient
    }
  }

  // Get all live locations
  Future<List<Map<String, dynamic>>> getLiveLocations() async {
    try {
      return await _connectionService.executeWithRetry(() async {
        final response = await _supabase
            .from('live_locations')
            .select('*')
            .eq('is_active', true)
            .order('updated_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching live locations: $e');
      return [];
    }
  }

  // Get stream of live locations for real-time updates
  Stream<List<Map<String, dynamic>>> getLiveLocationsStream() {
    return _supabase
        .from('live_locations')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('updated_at', ascending: false);
  }

  // Stop tracking location for a fisherman (mark as inactive)
  Future<void> stopLocationTracking(String fishermanUid) async {
    try {
      await _connectionService.executeWithRetry(() async {
        await _supabase
            .from('live_locations')
            .update({'is_active': false})
            .eq('fisherman_uid', fishermanUid);
      });
    } catch (e) {
      print('Error stopping location tracking: $e');
    }
  }

  // Get all fishermen with their current locations
  Future<List<Map<String, dynamic>>> getAllFishermen() async {
    try {
      print('=== FETCHING FISHERMEN ===');
      return await _connectionService.executeWithRetry(() async {
        try {
          final response = await _supabase
              .from('fishermen')
              .select('*')
              .eq('is_active', true)
              .order('last_active', ascending: false);

          print('✅ Fishermen fetched: ${response.length} records');
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          print('❌ Error fetching fishermen: $e');
          print('Error type: ${e.runtimeType}');
          rethrow;
        }
      });
    } catch (e) {
      print('❌ Failed to fetch fishermen after retries: $e');
      return [];
    }
  }

  // Get stream of all fishermen for real-time updates
  Stream<List<Map<String, dynamic>>> getFishermenStream() {
    return _supabase
        .from('fishermen')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('last_active', ascending: false);
  }

  // Get all active coastguards/admins with their locations
  Future<List<Map<String, dynamic>>> getActiveCoastguards() async {
    try {
      print('=== FETCHING ACTIVE COASTGUARDS/ADMINS ===');
      return await _connectionService.executeWithRetry(() async {
        try {
          final response = await _supabase
              .from('coastguards')
              .select('*')
              .eq('is_active', true)
              .order('last_active', ascending: false);

          print('✅ Coastguards/Admins fetched: ${response.length} records');
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          print('❌ Error fetching coastguards: $e');
          print('Error type: ${e.runtimeType}');
          rethrow;
        }
      });
    } catch (e) {
      print('❌ Failed to fetch coastguards after retries: $e');
      return [];
    }
  }

  // Get stream of active coastguards/admins for real-time updates
  Stream<List<Map<String, dynamic>>> getCoastguardsStream() {
    try {
      return _supabase
          .from('coastguards')
          .stream(primaryKey: ['id'])
          .eq('is_active', true)
          .order('last_active', ascending: false);
    } catch (e) {
      print('Error creating coastguards stream: $e');
      return Stream.value([]);
    }
  }

  // Create SOS alert
  Future<bool> createSOSAlert({
    required String fishermanId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    try {
      print('=== SOS ALERT CREATION DEBUG ===');
      print('Fisherman ID: $fishermanId');
      print('Latitude: $latitude');
      print('Longitude: $longitude');
      print('Message: $message');
      
      // Fetch fisherman details to denormalize into sos_alerts
      print('Fetching fisherman details...');
      final fisherman = await _supabase
          .from('fishermen')
          .select()
          .eq('id', fishermanId)
          .maybeSingle();

      print('Fisherman data: $fisherman');

      final alertId = 'sos_${DateTime.now().millisecondsSinceEpoch}';
      final alertData = <String, dynamic>{
        'id': alertId,
        'fisherman_uid': fishermanId,
        'latitude': latitude,
        'longitude': longitude,
        'message': message ?? 'Emergency SOS Alert',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'resolved_at': null,
      };

      // Add denormalized fisherman snapshot if available
      if (fisherman != null) {
        print('Adding fisherman details to alert...');
        alertData.addAll({
          'fisherman_display_id': fisherman['display_id'],
          'fisherman_first_name': fisherman['first_name'],
          'fisherman_middle_name': fisherman['middle_name'],
          'fisherman_last_name': fisherman['last_name'],
          'fisherman_name': fisherman['name'],
          'fisherman_email': fisherman['email'],
          'fisherman_phone': fisherman['phone'],
          'fisherman_user_type': fisherman['user_type'],
          'fisherman_address': fisherman['address'],
          'fisherman_fishing_area': fisherman['fishing_area'],
          'fisherman_emergency_contact_person': fisherman['emergency_contact_person'],
          'fisherman_profile_picture_url': fisherman['profile_picture_url'],
          'fisherman_profile_image_url': fisherman['profile_image_url'],
        });
      } else {
        print('⚠️ No fisherman data found - creating alert with minimal data');
      }

      print('Final alert data: $alertData');
      
      // Ensure at least fisherman_uid or fisherman_email is present
      if (alertData['fisherman_uid'] == null && alertData['fisherman_email'] == null) {
        print('⚠️ Warning: No fisherman identifier found. Creating alert with minimal data.');
        // Try to get fisherman ID from current user
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          alertData['fisherman_uid'] = currentUser.id;
          alertData['fisherman_email'] = currentUser.email;
          print('Using current user as fisherman: ${currentUser.id} / ${currentUser.email}');
        }
      }

      print('Inserting into sos_alerts table...');
      final response = await _supabase
          .from('sos_alerts')
          .insert(alertData)
          .select();

      print('✅ SOS alert created successfully: $response');
      
      // Verify the alert was created
      if (response.isEmpty) {
        print('⚠️ Warning: Alert insert returned empty response');
        return false;
      }
      
      print('Alert ID: ${response[0]['id']}');
      print('Alert Status: ${response[0]['status']}');
      print('Fisherman UID: ${response[0]['fisherman_uid']}');
      print('Fisherman Email: ${response[0]['fisherman_email']}');
      
      print('=== SOS ALERT CREATION COMPLETE ===');
      return true;
    } catch (e) {
      print('❌ Error creating SOS alert: $e');
      print('Error details: ${e.toString()}');
      print('Error type: ${e.runtimeType}');
      
      // Check for specific error types
      if (e.toString().contains('permission') || e.toString().contains('RLS')) {
        print('⚠️ This is likely a Row Level Security (RLS) issue');
        print('⚠️ Please check RLS policies on sos_alerts table');
      } else if (e.toString().contains('violates foreign key')) {
        print('⚠️ Foreign key constraint violation - fisherman may not exist');
      } else if (e.toString().contains('violates check constraint')) {
        print('⚠️ Check constraint violation - invalid data');
      } else if (e.toString().contains('null value')) {
        print('⚠️ NULL value violation - required field is missing');
      }
      
      print('=== SOS ALERT CREATION FAILED ===');
      return false;
    }
  }

  // Update SOS alert status
  Future<bool> updateSOSAlertStatus(String alertId, String status) async {
    return await _connectionService.executeWithRetry(() async {
      try {
        print('=== UPDATING SOS ALERT STATUS ===');
        print('Alert ID: $alertId');
        print('New Status: $status');
        
        // First, get the SOS alert details to extract fisherman information
        final alertResponse = await _supabase
            .from('sos_alerts')
            .select('*')
            .eq('id', alertId)
            .maybeSingle();

        if (alertResponse == null) {
          print('❌ SOS alert not found: $alertId');
          return false;
        }

        print('Current alert data:');
        print('- Fisherman UID: ${alertResponse['fisherman_uid']}');
        print('- Fisherman Email: ${alertResponse['fisherman_email']}');
        print('- Current Status: ${alertResponse['status']}');

        Map<String, dynamic> updateData = {'status': status};
        
        // Set on_the_way_at if status is 'on_the_way'
        if (status == 'on_the_way') {
          updateData['on_the_way_at'] = DateTime.now().toIso8601String();
        }
        
        // Only set resolved_at if status is 'resolved'
        if (status == 'resolved') {
          updateData['resolved_at'] = DateTime.now().toIso8601String();
        }
        
        // Update SOS alert status
        // The database trigger will automatically create a notification
        print('Updating alert status in database...');
        await _supabase
            .from('sos_alerts')
            .update(updateData)
            .eq('id', alertId);

        print('✅ SOS alert status updated: $alertId -> $status');

        // Also try to create notification manually (as backup)
        // The trigger should create it, but this ensures it's created even if trigger fails
        try {
          await _createFishermanNotificationForStatusChange(
            alertId: alertId,
            status: status,
            alertData: alertResponse,
          );
        } catch (notificationError) {
          print('⚠️ Manual notification creation failed (trigger should handle it): $notificationError');
          // Don't fail the entire operation if notification creation fails
          // The trigger should have created the notification
        }

        print('=== STATUS UPDATE COMPLETE ===');
        return true;
      } catch (e) {
        print('❌ Error updating SOS alert: $e');
        print('Error details: ${e.toString()}');
        print('Error type: ${e.runtimeType}');
        return false;
      }
    });
  }

  // Create notification for fisherman when SOS alert status changes
  Future<void> _createFishermanNotificationForStatusChange({
    required String alertId,
    required String status,
    required Map<String, dynamic> alertData,
  }) async {
    try {
      // Extract fisherman information from alert
      // Try multiple possible field names for fisherman info
      final fishermanUid = alertData['fisherman_uid']?.toString() ?? 
                           alertData['fisherman_id']?.toString();
      final fishermanEmail = alertData['fisherman_email']?.toString();
      final fishermanDisplayId = alertData['fisherman_display_id']?.toString();
      
      // Get admin information from current user
      final currentUser = _supabase.auth.currentUser;
      final adminEmail = currentUser?.email ?? 'coastguard@salbar-mangirisda.gov';
      final adminName = currentUser?.userMetadata?['name'] ?? 
                       currentUser?.userMetadata?['full_name'] ??
                       'Coast Guard';

      // Determine notification type, title, and message
      String notificationType;
      String title;
      String message;
      Map<String, dynamic> notificationData = {
        'sos_alert_id': alertId,
        'status': status,
        'admin_name': adminName,
        'admin_email': adminEmail,
        'latitude': alertData['latitude'],
        'longitude': alertData['longitude'],
      };

      if (status == 'on_the_way') {
        notificationType = 'sos_on_the_way';
        title = 'Rescue Team is On The Way';
        message = '$adminName has marked your SOS alert as "On The Way". Help is on the way!';
        notificationData['on_the_way_at'] = DateTime.now().toIso8601String();
      } else if (status == 'resolved') {
        notificationType = 'sos_resolved';
        title = 'SOS Alert Resolved';
        message = '$adminName has marked your SOS alert as "Resolved". You are safe now!';
        notificationData['resolved_at'] = DateTime.now().toIso8601String();
      } else {
        // For other statuses, use generic notification
        notificationType = 'sos_active';
        title = 'SOS Alert Status Update';
        message = '$adminName has updated your SOS alert status to "$status".';
        notificationData['updated_at'] = DateTime.now().toIso8601String();
      }

      // Prepare notification data for insertion
      final notificationInsertData = <String, dynamic>{
        'sos_alert_id': alertId,
        'notification_type': notificationType,
        'title': title,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'notification_data': notificationData,
      };

      // Add fisherman identifiers (at least one must be provided)
      if (fishermanUid != null && fishermanUid.isNotEmpty) {
        notificationInsertData['fisherman_uid'] = fishermanUid;
      }
      if (fishermanEmail != null && fishermanEmail.isNotEmpty) {
        notificationInsertData['fisherman_email'] = fishermanEmail;
      }
      if (fishermanDisplayId != null && fishermanDisplayId.isNotEmpty) {
        notificationInsertData['fisherman_display_id'] = fishermanDisplayId;
      }

      // If no fisherman identifier is available, try to get it from fishermen table
      if ((fishermanUid == null || fishermanUid.isEmpty) && 
          (fishermanEmail == null || fishermanEmail.isEmpty)) {
        // Try to get fisherman info from alert's fisherman_uid
        if (alertData['fisherman_uid'] != null) {
          try {
            final fisherman = await _supabase
                .from('fishermen')
                .select('id, email, display_id')
                .eq('id', alertData['fisherman_uid'])
                .maybeSingle();

            if (fisherman != null) {
              notificationInsertData['fisherman_uid'] = fisherman['id'];
              if (fisherman['email'] != null) {
                notificationInsertData['fisherman_email'] = fisherman['email'];
              }
              if (fisherman['display_id'] != null) {
                notificationInsertData['fisherman_display_id'] = fisherman['display_id'];
              }
            }
          } catch (e) {
            print('Error fetching fisherman info: $e');
          }
        }
      }

      // Use the SQL function create_fisherman_notification which has SECURITY DEFINER
      // This bypasses RLS and allows authenticated users to create notifications
      // The function reads fisherman info from sos_alerts table
      bool notificationCreated = false;
      
      try {
        final result = await _supabase.rpc(
          'create_fisherman_notification',
          params: {
            'p_sos_alert_id': alertId,
            'p_notification_type': notificationType,
            'p_title': title,
            'p_message': message,
            'p_notification_data': notificationData,
          },
        );

        if (result != null) {
          print('✅ Notification created for fisherman via function: $notificationType (ID: $result)');
          notificationCreated = true;
        } else {
          print('⚠️ Function returned NULL - notification may not have been created');
        }
      } catch (functionError) {
        print('❌ Error calling create_fisherman_notification function: $functionError');
        print('Function error details: $functionError');
        
        // Fallback: Try direct insert if function doesn't work
        // This will work if RLS policy allows it (after running updated SQL)
        try {
          // Ensure at least one fisherman identifier exists
          if ((fishermanUid != null && fishermanUid.isNotEmpty) || 
              (fishermanEmail != null && fishermanEmail.isNotEmpty)) {
            await _supabase
                .from('fisherman_notifications')
                .insert(notificationInsertData);
            print('✅ Notification created for fisherman via direct insert: $notificationType');
            notificationCreated = true;
          } else {
            print('⚠️ Cannot create notification: no fisherman identifier available');
          }
        } catch (insertError) {
          print('❌ Error creating fisherman notification (direct insert also failed): $insertError');
          print('Insert error details: $insertError');
          // Don't throw error - notification creation failure shouldn't block status update
          // The SQL trigger should still create the notification automatically
        }
      }
      
      // Note: Even if manual creation fails, the SQL trigger should create the notification
      // when the status is updated in the database
      if (!notificationCreated) {
        print('ℹ️ Notification will be created by database trigger when status is updated');
      }
    } catch (e) {
      print('Error creating fisherman notification: $e');
      // Don't throw error - notification creation failure shouldn't block status update
    }
  }

  // Get news articles
  Future<List<Map<String, dynamic>>> getNews() async {
    try {
      final response = await _supabase
          .from('news')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching news: $e');
      return [];
    }
  }

  // Create news article
  Future<bool> createNews({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final newsData = {
        'id': 'news_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'content': content,
        'image_url': imageUrl,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('news').insert(newsData);
      return true;
    } catch (e) {
      print('Error creating news: $e');
      return false;
    }
  }

  // Get dashboard statistics
  Future<Map<String, int>> getDashboardStats() async {
    try {
      // Get active fishermen
      final fishermen = await _supabase
          .from('fishermen')
          .select('id')
          .eq('is_active', true);

      // Get boats owned by active fishermen only
      final fishermenIds = fishermen.map((f) => f['id']).toList();
      final boatsCount = await _supabase
          .from('boats')
          .select('id')
          .eq('is_active', true)
          .inFilter('owner_id', fishermenIds);

      final coastguardsCount = await _supabase
          .from('coastguards')
          .select('id')
          .eq('is_active', true);

      final activeSOSCount = await _supabase
          .from('sos_alerts')
          .select('id')
          .eq('status', 'active');

      return {
        'fishermen': fishermen.length,
        'coastguards': coastguardsCount.length,
        'boats': boatsCount.length,
        'activeSOS': activeSOSCount.length,
      };
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {
        'fishermen': 0,
        'coastguards': 0,
        'boats': 0,
        'activeSOS': 0,
      };
    }
  }

  // Stream of news for real-time updates
  Stream<List<Map<String, dynamic>>> getNewsStream() {
    return _supabase
        .from('news')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false);
  }

  // Get total users count
  Future<int> getTotalUsersCount() async {
    return await _connectionService.executeWithRetry(() async {
      final fishermen = await _supabase
          .from('fishermen')
          .select('id')
          .eq('is_active', true);
      
      final coastguards = await _supabase
          .from('coastguards')
          .select('id')
          .eq('is_active', true);
      
      return fishermen.length + coastguards.length;
    });
  }

  // Get total boats count
  Future<int> getTotalBoatsCount() async {
    return await _connectionService.executeWithRetry(() async {
      // Get active fishermen first
      final fishermen = await _supabase
          .from('fishermen')
          .select('id')
          .eq('is_active', true);
      
      if (fishermen.isEmpty) return 0;
      
      // Get boats owned by active fishermen only
      final fishermenIds = fishermen.map((f) => f['id']).toList();
      final boats = await _supabase
          .from('boats')
          .select('id')
          .eq('is_active', true)
          .inFilter('owner_id', fishermenIds);
      
      return boats.length;
    });
  }

  // Get total rescued count
  Future<int> getTotalRescuedCount() async {
    return await _connectionService.executeWithRetry(() async {
      final rescued = await _supabase
          .from('sos_alerts')
          .select('id')
          .eq('status', 'resolved');
      
      return rescued.length;
    });
  }

  // Get active SOS alerts count
  Future<int> getActiveSOSAlertsCount() async {
    return await _connectionService.executeWithRetry(() async {
      final activeAlerts = await _supabase
          .from('sos_alerts')
          .select('id')
          .inFilter('status', ['active', 'on_the_way']);

      return activeAlerts.length;
    });
  }

  // Get rescue reports (resolved and active alerts with basic details)
  Future<List<Map<String, dynamic>>> getRescueReports() async {
    return await _connectionService.executeWithRetry(() async {
      // Select only columns from sos_alerts to avoid missing FK relation errors
      final response = await _supabase
          .from('sos_alerts')
          .select('id, status, created_at, resolved_at, fisherman_name, fisherman_email')
          .order('created_at', ascending: false);

      // Normalize shape for UI
      return List<Map<String, dynamic>>.from(response).map((row) {
        final nameFromAlert = (row['fisherman_name']?.toString() ?? '').trim();
        final emailFromAlert = (row['fisherman_email']?.toString() ?? '').trim();
        final fullName = nameFromAlert.isNotEmpty ? nameFromAlert : (emailFromAlert.isNotEmpty ? emailFromAlert : 'Unknown');

        return {
          'id': row['id'],
          'status': row['status'],
          'fullName': fullName,
          'distressTime': row['created_at'],
          'rescueTime': row['resolved_at'],
        };
      }).toList();
    });
  }

  // Get all users with boats
  Future<List<Map<String, dynamic>>> getAllUsersWithBoats() async {
    try {
      // First get all active fishermen
      final fishermen = await _supabase
          .from('fishermen')
          .select('*')
          .eq('is_active', true);
      
      // Then get all boats for these fishermen
      final fishermenWithBoats = <Map<String, dynamic>>[];
      
      for (final fisherman in fishermen) {
        final boats = await _supabase
            .from('boats')
            .select('*')
            .eq('owner_id', fisherman['id'])
            .eq('is_active', true);
        
        // Create a combined record for each fisherman
        final fishermanWithBoat = Map<String, dynamic>.from(fisherman);
        fishermanWithBoat['boat'] = boats.isNotEmpty ? boats.first : null;
        fishermanWithBoat['boats'] = boats; // Include all boats for this fisherman
        fishermenWithBoats.add(fishermanWithBoat);
      }
      
      return fishermenWithBoats;
    } catch (e) {
      print('Error getting users with boats: $e');
      return [];
    }
  }

  // Update fisherman status
  Future<bool> updateFishermanStatus(String fishermanId, bool isActive) async {
    try {
      await _supabase
          .from('fishermen')
          .update({'is_active': isActive})
          .eq('id', fishermanId);
      
      return true;
    } catch (e) {
      print('Error updating fisherman status: $e');
      return false;
    }
  }

  // Update fisherman last active
  Future<bool> updateFishermanLastActive(String fishermanId) async {
    try {
      await _supabase
          .from('fishermen')
          .update({'last_active': DateTime.now().toIso8601String()})
          .eq('id', fishermanId);
      
      return true;
    } catch (e) {
      print('Error updating fisherman last active: $e');
      return false;
    }
  }

  // Update boat last used
  Future<bool> updateBoatLastUsed(String boatId) async {
    try {
      await _supabase
          .from('boats')
          .update({'last_used': DateTime.now().toIso8601String()})
          .eq('id', boatId);
      
      return true;
    } catch (e) {
      print('Error updating boat last used: $e');
      return false;
    }
  }

  // Delete fisherman
  Future<bool> deleteFisherman(String fishermanId) async {
    try {
      await _supabase
          .from('fishermen')
          .update({'is_active': false})
          .eq('id', fishermanId);
      
      return true;
    } catch (e) {
      print('Error deleting fisherman: $e');
      return false;
    }
  }

  // Delete boat
  Future<bool> deleteBoat(String boatId) async {
    try {
      await _supabase
          .from('boats')
          .update({'is_active': false})
          .eq('id', boatId);
      
      return true;
    } catch (e) {
      print('Error deleting boat: $e');
      return false;
    }
  }

  // Get fisherman by email
  Future<Map<String, dynamic>?> getFishermanByEmail(String email) async {
    try {
      print('Looking for fisherman with email: $email');
      
      // First try with is_active filter
      var response = await _supabase
          .from('fishermen')
          .select()
          .eq('email', email)
          .eq('is_active', true)
          .maybeSingle();
      
      if (response != null) {
        print('Found active fisherman: $response');
        return response;
      }
      
      // If not found with is_active filter, try without it
      print('No active fisherman found, trying without is_active filter...');
      response = await _supabase
          .from('fishermen')
          .select()
          .eq('email', email)
          .maybeSingle();
      
      if (response != null) {
        print('Found fisherman (not active): $response');
        return response;
      }
      
      print('No fisherman found for email: $email');
      return null;
    } catch (e) {
      print('Error getting fisherman by email: $e');
      return null;
    }
  }

  // Create fisherman
  Future<String> createFisherman({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      // Generate a proper UUID for fisherman_id
      final fishermanId = _generateUUID();
      final fishermanData = {
        'id': fishermanId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'name': '$firstName $lastName',
        'phone': phone,
        'user_type': 'fisherman',
        'is_active': true,
        'registration_date': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      };

      print('Creating fisherman with data: $fishermanData');
      
      await _supabase
          .from('fishermen')
          .insert(fishermanData);
      
      print('Fisherman created successfully: $fishermanId');
      return fishermanId;
    } catch (e) {
      print('Error creating fisherman: $e');
      print('Error details: ${e.toString()}');
      throw Exception('Failed to create fisherman record');
    }
  }

  // Generate a proper UUID v4 using Supabase RPC or client-side helper
  String _generateUUID() {
    return _supabase.auth.currentUser?.id ??
        'uuid_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Test SOS alert creation with sample data
  Future<bool> testSOSAlertCreation() async {
    try {
      print('Testing SOS alert creation...');
      final testData = {
        'id': 'test_sos_${DateTime.now().millisecondsSinceEpoch}',
        'fisherman_uid': _generateUUID(),
        'latitude': 11.7753,
        'longitude': 124.8861,
        'message': 'Test SOS Alert',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'resolved_at': null,
      };

      print('Test data: $testData');
      
      final response = await _supabase
          .from('sos_alerts')
          .insert(testData)
          .select();
      
      print('Test SOS alert created successfully: $response');
      return true;
    } catch (e) {
      print('Test SOS alert creation failed: $e');
      print('Error details: ${e.toString()}');
      return false;
    }
  }

  // Fisherman Notifications Methods

  // Get all notifications for a fisherman
  Future<List<Map<String, dynamic>>> getFishermanNotifications({
    String? fishermanUid,
    String? fishermanEmail,
    bool unreadOnly = false,
  }) async {
    try {
      print('=== FETCHING FISHERMAN NOTIFICATIONS ===');
      print('Fisherman UID: $fishermanUid');
      print('Fisherman Email: $fishermanEmail');
      print('Unread Only: $unreadOnly');
      
      return await _connectionService.executeWithRetry(() async {
        try {
          var query = _supabase
              .from('fisherman_notifications')
              .select('*');

          // Filter by fisherman_uid if provided
          if (fishermanUid != null && fishermanUid.isNotEmpty) {
            query = query.eq('fisherman_uid', fishermanUid);
            print('Filtering by fisherman_uid: $fishermanUid');
          }

          // Filter by fisherman_email if provided
          if (fishermanEmail != null && fishermanEmail.isNotEmpty) {
            query = query.eq('fisherman_email', fishermanEmail);
            print('Filtering by fisherman_email: $fishermanEmail');
          }

          // Filter by unread status if requested
          if (unreadOnly) {
            query = query.eq('is_read', false);
            print('Filtering unread notifications only');
          }

          // Apply ordering and limit after filters
          print('Executing query...');
          final response = await query
              .order('created_at', ascending: false)
              .limit(100);
          
          print('✅ Notifications fetched: ${response.length} records');
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          print('❌ Error fetching notifications: $e');
          print('Error type: ${e.runtimeType}');
          print('Error details: ${e.toString()}');
          if (e.toString().contains('permission') || e.toString().contains('RLS')) {
            print('⚠️ This might be an RLS (Row Level Security) issue');
          }
          rethrow;
        }
      });
    } catch (e) {
      print('❌ Failed to fetch notifications after retries: $e');
      return [];
    }
  }

  // Get unread notifications count for a fisherman
  Future<int> getUnreadNotificationsCount({
    String? fishermanUid,
    String? fishermanEmail,
  }) async {
    return await _connectionService.executeWithRetry(() async {
      var query = _supabase
          .from('fisherman_notifications')
          .select('id')
          .eq('is_read', false);

      // Filter by fisherman_uid if provided
      if (fishermanUid != null && fishermanUid.isNotEmpty) {
        query = query.eq('fisherman_uid', fishermanUid);
      }

      // Filter by fisherman_email if provided
      if (fishermanEmail != null && fishermanEmail.isNotEmpty) {
        query = query.eq('fisherman_email', fishermanEmail);
      }

      final response = await query;
      return response.length;
    });
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    return await _connectionService.executeWithRetry(() async {
      await _supabase
          .from('fisherman_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
      return true;
    });
  }

  // Mark all notifications as read for a fisherman
  Future<bool> markAllNotificationsAsRead({
    String? fishermanUid,
    String? fishermanEmail,
  }) async {
    return await _connectionService.executeWithRetry(() async {
      var query = _supabase
          .from('fisherman_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('is_read', false);

      // Filter by fisherman_uid if provided
      if (fishermanUid != null && fishermanUid.isNotEmpty) {
        query = query.eq('fisherman_uid', fishermanUid);
      }

      // Filter by fisherman_email if provided
      if (fishermanEmail != null && fishermanEmail.isNotEmpty) {
        query = query.eq('fisherman_email', fishermanEmail);
      }

      await query;
      return true;
    });
  }

  // Get stream of notifications for real-time updates
  Stream<List<Map<String, dynamic>>> getFishermanNotificationsStream({
    String? fishermanUid,
    String? fishermanEmail,
  }) {
    // Build stream query conditionally - chain all filters at once
    dynamic streamBuilder = _supabase
        .from('fisherman_notifications')
        .stream(primaryKey: ['id']);

    // Apply filters conditionally
    if (fishermanUid != null && fishermanUid.isNotEmpty) {
      streamBuilder = streamBuilder.eq('fisherman_uid', fishermanUid);
    }
    if (fishermanEmail != null && fishermanEmail.isNotEmpty) {
      streamBuilder = streamBuilder.eq('fisherman_email', fishermanEmail);
    }

    // Convert to stream and sort in application layer
    final stream = streamBuilder as Stream<List<Map<String, dynamic>>>;
    return stream.map((notifications) {
      // Sort by created_at descending
      final sorted = List<Map<String, dynamic>>.from(notifications);
      sorted.sort((a, b) {
        try {
          final aTime = DateTime.parse(a['created_at'] ?? '');
          final bTime = DateTime.parse(b['created_at'] ?? '');
          return bTime.compareTo(aTime);
        } catch (e) {
          return 0;
        }
      });
      return sorted;
    });
  }
}
