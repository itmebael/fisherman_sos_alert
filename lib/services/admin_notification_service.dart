import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import 'connection_service.dart';

class AdminNotificationService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final ConnectionService _connectionService = ConnectionService();

  /// Fetch admin notification actions for a specific SOS alert
  Future<List<Map<String, dynamic>>> getAdminNotificationActions(String sosAlertId) async {
    try {
      final response = await _connectionService.executeWithRetry(() async {
        return await _supabase
            .from('admin_notification_actions')
            .select('''
              id,
              sos_alert_id,
              admin_user_id,
              admin_email,
              admin_name,
              action_type,
              action_description,
              previous_status,
              new_status,
              action_timestamp,
              ip_address,
              user_agent,
              notes,
              created_at
            ''')
            .eq('sos_alert_id', sosAlertId)
            .order('action_timestamp', ascending: false);
      });
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching admin notification actions: $e');
      return [];
    }
  }

  /// Fetch all admin notification actions for fisherman notifications
  Future<List<Map<String, dynamic>>> getAllAdminNotificationActions() async {
    try {
      final response = await _connectionService.executeWithRetry(() async {
        return await _supabase
            .from('admin_notification_actions')
            .select('''
              id,
              sos_alert_id,
              admin_user_id,
              admin_email,
              admin_name,
              action_type,
              action_description,
              previous_status,
              new_status,
              action_timestamp,
              ip_address,
              user_agent,
              notes,
              created_at
            ''')
            .order('action_timestamp', ascending: false)
            .limit(50); // Limit to recent 50 actions
      });
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all admin notification actions: $e');
      return [];
    }
  }

  /// Fetch admin notification actions by action type
  Future<List<Map<String, dynamic>>> getAdminNotificationActionsByType(String actionType) async {
    try {
      final response = await _connectionService.executeWithRetry(() async {
        return await _supabase
            .from('admin_notification_actions')
            .select('''
              id,
              sos_alert_id,
              admin_user_id,
              admin_email,
              admin_name,
              action_type,
              action_description,
              previous_status,
              new_status,
              action_timestamp,
              ip_address,
              user_agent,
              notes,
              created_at
            ''')
            .eq('action_type', actionType)
            .order('action_timestamp', ascending: false);
      });
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching admin notification actions by type: $e');
      return [];
    }
  }

  /// Fetch admin notification actions by admin user
  Future<List<Map<String, dynamic>>> getAdminNotificationActionsByUser(String adminUserId) async {
    try {
      final response = await _connectionService.executeWithRetry(() async {
        return await _supabase
            .from('admin_notification_actions')
            .select('''
              id,
              sos_alert_id,
              admin_user_id,
              admin_email,
              admin_name,
              action_type,
              action_description,
              previous_status,
              new_status,
              action_timestamp,
              ip_address,
              user_agent,
              notes,
              created_at
            ''')
            .eq('admin_user_id', adminUserId)
            .order('action_timestamp', ascending: false);
      });
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching admin notification actions by user: $e');
      return [];
    }
  }

  /// Get action type display name
  String getActionTypeDisplayName(String actionType) {
    switch (actionType) {
      case 'view_location':
        return 'Viewed Location';
      case 'mark_on_the_way':
        return 'Marked On The Way';
      case 'mark_resolved':
        return 'Marked Resolved';
      case 'view_details':
        return 'Viewed Details';
      case 'export_data':
        return 'Exported Data';
      case 'print_report':
        return 'Printed Report';
      default:
        return actionType.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Get action type icon
  String getActionTypeIcon(String actionType) {
    switch (actionType) {
      case 'view_location':
        return '📍';
      case 'mark_on_the_way':
        return '🚁';
      case 'mark_resolved':
        return '✅';
      case 'view_details':
        return '👁️';
      case 'export_data':
        return '📊';
      case 'print_report':
        return '🖨️';
      default:
        return '📋';
    }
  }

  /// Format timestamp for display
  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
