import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class FishermanNotificationService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Stream to listen for SOS alert status updates for a specific fisherman
  Stream<Map<String, dynamic>?> getSOSAlertStatusStream(String fishermanId) {
    return _supabase
        .from('sos_alerts')
        .stream(primaryKey: ['id'])
        .eq('fisherman_uid', fishermanId)
        .order('created_at', ascending: false)
        .map((alerts) {
          // Filter for on_the_way or resolved status
          final filteredAlerts = alerts.where((alert) => 
            alert['status'] == 'on_the_way' || alert['status'] == 'resolved'
          ).toList();
          return filteredAlerts.isNotEmpty ? filteredAlerts.first : null;
        });
  }
  
  // Get the latest SOS alert status for a fisherman
  Future<Map<String, dynamic>?> getLatestSOSAlertStatus(String fishermanId) async {
    try {
      final response = await _supabase
          .from('sos_alerts')
          .select('*')
          .eq('fisherman_uid', fishermanId)
          .eq('status', 'on_the_way')
          .or('status.eq.resolved')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error getting latest SOS alert status: $e');
      return null;
    }
  }
  
  // Check if fisherman has any active SOS alerts
  Future<bool> hasActiveSOSAlert(String fishermanId) async {
    try {
      final response = await _supabase
          .from('sos_alerts')
          .select('id')
          .eq('fisherman_uid', fishermanId)
          .eq('status', 'active')
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking active SOS alert: $e');
      return false;
    }
  }
  
  // Get all SOS alerts for a fisherman
  Future<List<Map<String, dynamic>>> getFishermanSOSAlerts(String fishermanId) async {
    try {
      final response = await _supabase
          .from('sos_alerts')
          .select('*')
          .eq('fisherman_uid', fishermanId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting fisherman SOS alerts: $e');
      return [];
    }
  }

  // Get all notifications for fisherman from fisherman_notifications table
  Future<List<Map<String, dynamic>>> getNotifications({
    String? fishermanUid,
    String? fishermanEmail,
  }) async {
    try {
      // First try to get notifications from fisherman_notifications table
      var query = _supabase
          .from('fisherman_notifications')
          .select('*');

      // Filter by fisherman_uid if provided
      if (fishermanUid != null && fishermanUid.isNotEmpty) {
        query = query.eq('fisherman_uid', fishermanUid);
      }

      // Filter by fisherman_email if provided
      if (fishermanEmail != null && fishermanEmail.isNotEmpty) {
        query = query.eq('fisherman_email', fishermanEmail);
      }

      // Apply ordering and limit after filters
      final notifications = await query
          .order('created_at', ascending: false)
          .limit(100);
      
      // Convert to notification format
      final formattedNotifications = notifications.map((notification) {
        // Parse timestamp
        DateTime timestamp;
        try {
          timestamp = DateTime.parse(notification['created_at']);
        } catch (e) {
          timestamp = DateTime.now();
        }

        // Parse notification data if available
        Map<String, dynamic>? notificationData;
        if (notification['notification_data'] != null) {
          notificationData = Map<String, dynamic>.from(notification['notification_data']);
        }

        return {
          'id': notification['id'],
          'title': notification['title'] ?? 'Notification',
          'message': notification['message'] ?? 'You have a new notification',
          'timestamp': timestamp,
          'type': notification['notification_type'] ?? 'system',
          'isRead': notification['is_read'] ?? false,
          'sosAlertId': notification['sos_alert_id'],
          'notificationData': notificationData,
          'createdAt': notification['created_at'],
          'readAt': notification['read_at'],
        };
      }).toList();

      return formattedNotifications;
    } catch (e) {
      print('Error getting notifications from fisherman_notifications table: $e');
      // Fallback to old method if table doesn't exist yet
      return await _getLegacyNotifications(fishermanUid, fishermanEmail);
    }
  }

  // Legacy method for backwards compatibility (if fisherman_notifications table doesn't exist)
  Future<List<Map<String, dynamic>>> _getLegacyNotifications(
    String? fishermanUid,
    String? fishermanEmail,
  ) async {
    try {
      // Get SOS alerts that are relevant for notifications
      var sosQuery = _supabase
          .from('sos_alerts')
          .select('''
            id,
            fisherman_uid,
            status,
            created_at,
            on_the_way_at,
            resolved_at,
            latitude,
            longitude,
            message
          ''')
          .or('status.eq.on_the_way,status.eq.resolved,status.eq.active');

      // Filter by fisherman_uid if provided
      if (fishermanUid != null && fishermanUid.isNotEmpty) {
        sosQuery = sosQuery.eq('fisherman_uid', fishermanUid);
      }

      // Filter by fisherman_email if provided
      if (fishermanEmail != null && fishermanEmail.isNotEmpty) {
        sosQuery = sosQuery.eq('fisherman_email', fishermanEmail);
      }

      // Apply ordering and limit after filters
      final sosAlerts = await sosQuery
          .order('created_at', ascending: false)
          .limit(20);

      // Convert SOS alerts to notification format
      final sosNotifications = sosAlerts.map((alert) {
        String title;
        String message;
        String type;
        DateTime timestamp;
        
        switch (alert['status']) {
          case 'active':
            title = 'SOS Alert Active';
            message = 'Your emergency alert is being processed by the coast guard.';
            type = 'sos_active';
            timestamp = DateTime.parse(alert['created_at']);
            break;
          case 'on_the_way':
            title = 'Rescue Team is On The Way';
            message = 'Coast guard has been dispatched and is heading to your location.';
            type = 'sos_on_the_way';
            timestamp = alert['on_the_way_at'] != null 
                ? DateTime.parse(alert['on_the_way_at'])
                : DateTime.parse(alert['created_at']);
            break;
          case 'resolved':
            title = 'SOS Alert Resolved';
            message = 'Your emergency alert has been successfully resolved.';
            type = 'sos_resolved';
            timestamp = alert['resolved_at'] != null 
                ? DateTime.parse(alert['resolved_at'])
                : DateTime.parse(alert['created_at']);
            break;
          default:
            title = 'SOS Alert Update';
            message = 'Your SOS alert status has been updated.';
            type = 'sos';
            timestamp = DateTime.parse(alert['created_at']);
        }

        return {
          'id': alert['id'],
          'title': title,
          'message': message,
          'timestamp': timestamp,
          'type': type,
          'isRead': false,
          'sosAlert': alert,
        };
      }).toList();

      // Get admin notification actions
      List<Map<String, dynamic>> adminNotifications = [];
      try {
        var adminQuery = _supabase
            .from('admin_notification_actions')
            .select('*')
            .or('action_type.eq.mark_on_the_way,action_type.eq.mark_resolved');

        // Filter by fisherman if we have SOS alert IDs
        if (sosAlerts.isNotEmpty) {
          final alertIds = sosAlerts.map((a) => a['id'] as String).toList();
          // Build filter for multiple alert IDs
          if (alertIds.length == 1) {
            adminQuery = adminQuery.eq('sos_alert_id', alertIds.first);
          } else if (alertIds.isNotEmpty) {
            // Use 'in' filter by building OR conditions
            final orConditions = alertIds
                .map((id) => 'sos_alert_id.eq.$id')
                .join(',');
            adminQuery = adminQuery.or(orConditions);
          }
        }

        // Apply ordering and limit after filters
        final adminActions = await adminQuery
            .order('action_timestamp', ascending: false)
            .limit(20);

        adminNotifications = adminActions.map((action) {
          String title;
          String message;
          
          if (action['action_type'] == 'mark_on_the_way') {
            title = 'Rescue Team is On The Way';
            message = '${action['admin_name'] ?? 'Coast Guard'} has marked your SOS alert as "On The Way". Help is on the way!';
          } else if (action['action_type'] == 'mark_resolved') {
            title = 'SOS Alert Resolved';
            message = '${action['admin_name'] ?? 'Coast Guard'} has marked your SOS alert as "Resolved". You are safe now!';
          } else {
            title = 'Admin Action';
            message = '${action['admin_name'] ?? 'Admin'} performed an action on your SOS alert.';
          }

          return {
            'id': 'admin_${action['id']}',
            'title': title,
            'message': message,
            'timestamp': DateTime.parse(action['action_timestamp']),
            'type': 'admin_action',
            'isRead': false,
            'adminAction': action,
          };
        }).toList();
      } catch (e) {
        print('Admin notification actions not available: $e');
      }

      // Get weather alerts (if weather table exists)
      List<Map<String, dynamic>> weatherNotifications = [];
      try {
        final weatherAlerts = await _supabase
            .from('weather_alerts')
            .select('*')
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(10);

        weatherNotifications = weatherAlerts.map((alert) {
          return {
            'id': 'weather_${alert['id']}',
            'title': 'Weather Alert',
            'message': alert['message'] ?? 'Weather conditions may affect your fishing activities.',
            'timestamp': DateTime.parse(alert['created_at']),
            'type': 'weather',
            'isRead': false,
            'weatherAlert': alert,
          };
        }).toList();
      } catch (e) {
        print('Weather alerts not available: $e');
      }

      // Combine all notifications and sort by timestamp
      final allNotifications = [...sosNotifications, ...adminNotifications, ...weatherNotifications];
      allNotifications.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      return allNotifications;
    } catch (e) {
      print('Error getting legacy notifications: $e');
      return [];
    }
  }

  // Get unread notifications count
  Future<int> getUnreadNotificationsCount({
    String? fishermanUid,
    String? fishermanEmail,
  }) async {
    try {
      var query = _supabase
          .from('fisherman_notifications')
          .select('id')
          .eq('is_read', false);

      if (fishermanUid != null && fishermanUid.isNotEmpty) {
        query = query.eq('fisherman_uid', fishermanUid);
      }

      if (fishermanEmail != null && fishermanEmail.isNotEmpty) {
        query = query.eq('fisherman_email', fishermanEmail);
      }

      final response = await query;
      return response.length;
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('fisherman_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead({
    String? fishermanUid,
    String? fishermanEmail,
  }) async {
    try {
      var query = _supabase
          .from('fisherman_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('is_read', false);

      if (fishermanUid != null && fishermanUid.isNotEmpty) {
        query = query.eq('fisherman_uid', fishermanUid);
      }

      if (fishermanEmail != null && fishermanEmail.isNotEmpty) {
        query = query.eq('fisherman_email', fishermanEmail);
      }

      await query;
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Get stream of notifications for real-time updates
  Stream<List<Map<String, dynamic>>> getNotificationsStream({
    String? fishermanUid,
    String? fishermanEmail,
  }) {
    try {
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
      }).map((notifications) {
        return notifications.map((notification) {
          DateTime timestamp;
          try {
            timestamp = DateTime.parse(notification['created_at']);
          } catch (e) {
            timestamp = DateTime.now();
          }

          Map<String, dynamic>? notificationData;
          if (notification['notification_data'] != null) {
            notificationData = Map<String, dynamic>.from(notification['notification_data']);
          }

          return {
            'id': notification['id'],
            'title': notification['title'] ?? 'Notification',
            'message': notification['message'] ?? 'You have a new notification',
            'timestamp': timestamp,
            'type': notification['notification_type'] ?? 'system',
            'isRead': notification['is_read'] ?? false,
            'sosAlertId': notification['sos_alert_id'],
            'notificationData': notificationData,
            'createdAt': notification['created_at'],
            'readAt': notification['read_at'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error getting notifications stream: $e');
      return Stream.value([]);
    }
  }
}
