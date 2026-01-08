import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../services/fisherman_notification_service.dart';
import '../../services/admin_notification_service.dart';
import '../../services/database_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/fisherman/notification_popup.dart';
import 'fisherman_drawer.dart';

class FishermanNotificationsScreen extends StatefulWidget {
  const FishermanNotificationsScreen({super.key});

  @override
  State<FishermanNotificationsScreen> createState() => _FishermanNotificationsScreenState();
}

class _FishermanNotificationsScreenState extends State<FishermanNotificationsScreen> {
  final FishermanNotificationService _notificationService = FishermanNotificationService();
  final AdminNotificationService _adminNotificationService = AdminNotificationService();
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _adminActions = [];
  bool _isLoading = true;
  StreamSubscription? _notificationStreamSubscription;
  Set<String> _shownNotificationIds = {}; // Track which notifications have been shown as pop-ups
  OverlayEntry? _currentOverlay;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _startRealTimeNotifications();
  }

  @override
  void dispose() {
    _notificationStreamSubscription?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _startRealTimeNotifications() {
    // Wait a bit for the widget to be fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.currentUser;
      
      if (currentUser == null) return;

      final fishermanUid = currentUser.id;
      final fishermanEmail = currentUser.email;

      // Listen to real-time notifications
      _notificationStreamSubscription = _notificationService
          .getNotificationsStream(
            fishermanUid: fishermanUid,
            fishermanEmail: fishermanEmail,
          )
          .listen((notifications) {
        if (!mounted) return;

        // Check for new unread notifications
        for (final notification in notifications) {
          final notificationId = notification['id'] as String;
          final isRead = notification['isRead'] as bool? ?? false;
          
          // Show pop-up for new unread notifications that haven't been shown yet
          if (!isRead && !_shownNotificationIds.contains(notificationId)) {
            _shownNotificationIds.add(notificationId);
            _showNotificationPopup(notification);
          }
        }

        // Update the notifications list
        _updateNotificationsList(notifications);
      });
    });
  }

  void _updateNotificationsList(List<Map<String, dynamic>> streamNotifications) {
    // Get current user from auth provider
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    
    if (currentUser == null) return;

    // Load admin notification actions from database (for compatibility)
    _adminNotificationService.getAllAdminNotificationActions().then((adminActions) {
      // Convert admin actions to notification format
      final adminNotifications = adminActions.map((action) {
        return {
          'id': 'admin_${action['id']}',
          'title': _adminNotificationService.getActionTypeDisplayName(action['action_type']),
          'message': _buildAdminActionMessage(action),
          'timestamp': DateTime.parse(action['action_timestamp']),
          'type': 'admin_action',
          'isRead': false,
          'adminAction': action,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _adminActions = adminActions;
          _notifications = [...streamNotifications, ...adminNotifications];
          _isLoading = false;
        });

        // Sort notifications by timestamp (newest first)
        _notifications.sort((a, b) {
          final aTime = a['timestamp'] as DateTime;
          final bTime = b['timestamp'] as DateTime;
          return bTime.compareTo(aTime);
        });
      }
    }).catchError((e) {
      print('Error loading admin actions: $e');
      if (mounted) {
        setState(() {
          _notifications = streamNotifications;
          _isLoading = false;
        });
      }
    });
  }

  void _showNotificationPopup(Map<String, dynamic> notification) {
    // Remove any existing overlay
    _removeOverlay();

    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 0,
        right: 0,
        child: NotificationPopup(
          title: notification['title'] ?? 'Notification',
          message: notification['message'] ?? 'You have a new notification',
          type: notification['type'] ?? 'system',
          onTap: () {
            // Navigate to notification details or mark as read
            _handleNotificationTap(notification);
          },
          onDismiss: () {
            _removeOverlay();
          },
        ),
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  void _removeOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    _removeOverlay();
    
    // Mark as read if not already read
    if (!(notification['isRead'] as bool? ?? false)) {
      try {
        final notificationId = notification['id'] as String;
        _notificationService.markNotificationAsRead(notificationId);
      } catch (e) {
        print('Error marking notification as read: $e');
      }
    }

    // Handle different notification types
    if (notification['type'] == 'admin_action' && notification['adminAction'] != null) {
      _showAdminActionDetails(notification['adminAction']);
    } else if (notification['type'] == 'sos_on_the_way' || 
               notification['type'] == 'sos_resolved' ||
               notification['type'] == 'sos_active') {
      final notificationData = notification['notificationData'] as Map<String, dynamic>?;
      if (notificationData != null) {
        _showSOSAlertDetailsFromNotification(notificationData);
      } else if (notification['sosAlertId'] != null) {
        _showSOSAlertDetailsById(notification['sosAlertId'] as String);
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user from auth provider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.currentUser;
      
      // Get fisherman UID and email
      final fishermanUid = currentUser?.id;
      final fishermanEmail = currentUser?.email;

      // Load notifications from fisherman_notifications table
      final fishermanNotifications = await _notificationService.getNotifications(
        fishermanUid: fishermanUid,
        fishermanEmail: fishermanEmail,
      );

      // Mark all loaded notifications as shown (so we don't show pop-ups for old ones)
      for (final notification in fishermanNotifications) {
        _shownNotificationIds.add(notification['id'] as String);
      }

      // Load admin notification actions from database (for compatibility)
      try {
        final adminActions = await _adminNotificationService.getAllAdminNotificationActions();
        
        // Convert admin actions to notification format
        final adminNotifications = adminActions.map((action) {
          return {
            'id': 'admin_${action['id']}',
            'title': _adminNotificationService.getActionTypeDisplayName(action['action_type']),
            'message': _buildAdminActionMessage(action),
            'timestamp': DateTime.parse(action['action_timestamp']),
            'type': 'admin_action',
            'isRead': false,
            'adminAction': action,
          };
        }).toList();

        setState(() {
          _adminActions = adminActions;
          _notifications = [...fishermanNotifications, ...adminNotifications];
          _isLoading = false;
        });
      } catch (e) {
        // If admin actions fail, just use fisherman notifications
        print('Error loading admin actions: $e');
        setState(() {
          _notifications = fishermanNotifications;
          _isLoading = false;
        });
      }

      // Sort notifications by timestamp (newest first)
      _notifications.sort((a, b) {
        final aTime = a['timestamp'] as DateTime;
        final bTime = b['timestamp'] as DateTime;
        return bTime.compareTo(aTime);
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildAdminActionMessage(Map<String, dynamic> action) {
    final adminName = action['admin_name'] ?? 'Admin';
    final actionType = action['action_type'];
    final sosAlertId = action['sos_alert_id'];
    
    switch (actionType) {
      case 'view_location':
        return '$adminName viewed the location of SOS Alert $sosAlertId';
      case 'mark_on_the_way':
        return '$adminName marked SOS Alert $sosAlertId as "On The Way"';
      case 'mark_resolved':
        return '$adminName marked SOS Alert $sosAlertId as "Resolved"';
      case 'view_details':
        return '$adminName viewed details of SOS Alert $sosAlertId';
      case 'export_data':
        return '$adminName exported data for SOS Alert $sosAlertId';
      case 'print_report':
        return '$adminName printed report for SOS Alert $sosAlertId';
      default:
        return '$adminName performed action on SOS Alert $sosAlertId';
    }
  }

  String _getTimeAgo(DateTime timestamp) {
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

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'weather':
        return Icons.wb_sunny;
      case 'sos':
        return Icons.emergency;
      case 'safety':
        return Icons.security;
      case 'system':
        return Icons.system_update;
      case 'admin_action':
        return Icons.admin_panel_settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'weather':
        return Colors.orange;
      case 'sos':
        return Colors.red;
      case 'safety':
        return Colors.blue;
      case 'system':
        return Colors.green;
      case 'admin_action':
        return Colors.purple;
      default:
        return AppColors.primaryColor;
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Notification Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.admin_panel_settings,
              title: 'Admin Actions',
              subtitle: 'View admin notification actions',
              onTap: () {
                Navigator.pop(context);
                _showAdminActionsDialog();
              },
            ),
            _buildMenuOption(
              icon: Icons.filter_list,
              title: 'Filter by Type',
              subtitle: 'Filter notifications by type',
              onTap: () {
                Navigator.pop(context);
                _showFilterDialog();
              },
            ),
            _buildMenuOption(
              icon: Icons.mark_email_read,
              title: 'Mark All Read',
              subtitle: 'Mark all notifications as read',
              onTap: () {
                Navigator.pop(context);
                _markAllAsRead();
              },
            ),
            _buildMenuOption(
              icon: Icons.refresh,
              title: 'Refresh',
              subtitle: 'Reload notifications',
              onTap: () {
                Navigator.pop(context);
                _loadNotifications();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showAdminActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Actions'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 400,
          child: _adminActions.isEmpty
              ? const Center(
                  child: Text('No admin actions found'),
                )
              : ListView.builder(
                  itemCount: _adminActions.length,
                  itemBuilder: (context, index) {
                    final action = _adminActions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Text(
                          _adminNotificationService.getActionTypeIcon(action['action_type']),
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          _adminNotificationService.getActionTypeDisplayName(action['action_type']),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin: ${action['admin_name'] ?? 'Unknown'}'),
                            Text('SOS Alert: ${action['sos_alert_id']}'),
                            Text(
                              _adminNotificationService.formatTimestamp(
                                DateTime.parse(action['action_timestamp']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All', 'all'),
            _buildFilterOption('Admin Actions', 'admin_action'),
            _buildFilterOption('Weather', 'weather'),
            _buildFilterOption('SOS', 'sos'),
            _buildFilterOption('Safety', 'safety'),
            _buildFilterOption('System', 'system'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, String type) {
    return ListTile(
      title: Text(title),
      leading: Icon(_getNotificationIcon(type)),
      onTap: () {
        Navigator.pop(context);
        _filterNotifications(type);
      },
    );
  }

  void _filterNotifications(String type) {
    // This would implement filtering logic
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtering by $type'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      // Get current user from auth provider
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.currentUser;
      
      // Get fisherman UID and email
      final fishermanUid = currentUser?.id;
      final fishermanEmail = currentUser?.email;

      // Mark all notifications as read in database
      final success = await _notificationService.markAllNotificationsAsRead(
        fishermanUid: fishermanUid,
        fishermanEmail: fishermanEmail,
      );

      if (success) {
        setState(() {
          for (var notification in _notifications) {
            notification['isRead'] = true;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notifications as read'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch phone call';
      }
    } catch (e) {
      // Handle error - phone call not available
      print('Error making phone call: $e');
    }
  }

  void _showAdminActionDetails(Map<String, dynamic> action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_adminNotificationService.getActionTypeDisplayName(action['action_type'])),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Admin Name', action['admin_name'] ?? 'Unknown'),
              _buildDetailRow('Admin Email', action['admin_email'] ?? 'N/A'),
              _buildDetailRow('SOS Alert ID', action['sos_alert_id']),
              _buildDetailRow('Action Type', action['action_type']),
              if (action['action_description'] != null)
                _buildDetailRow('Description', action['action_description']),
              if (action['previous_status'] != null)
                _buildDetailRow('Previous Status', action['previous_status']),
              if (action['new_status'] != null)
                _buildDetailRow('New Status', action['new_status']),
              _buildDetailRow('Timestamp', _adminNotificationService.formatTimestamp(
                DateTime.parse(action['action_timestamp']),
              )),
              if (action['ip_address'] != null)
                _buildDetailRow('IP Address', action['ip_address']),
              if (action['notes'] != null)
                _buildDetailRow('Notes', action['notes']),
            ],
          ),
        ),
        actions: [
          // Try to get admin phone from action data or fetch from database
          if (action['admin_phone'] != null && action['admin_phone'].toString().isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _makePhoneCall(action['admin_phone'].toString()),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Call Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showSOSAlertDetails(Map<String, dynamic> sosAlert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Alert Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Alert ID', sosAlert['id'] ?? 'N/A'),
              _buildDetailRow('Status', sosAlert['status'] ?? 'Unknown'),
              if (sosAlert['created_at'] != null)
                _buildDetailRow('Created', _getTimeAgo(DateTime.parse(sosAlert['created_at']))),
              if (sosAlert['updated_at'] != null)
                _buildDetailRow('Updated', _getTimeAgo(DateTime.parse(sosAlert['updated_at']))),
              if (sosAlert['on_the_way_at'] != null)
                _buildDetailRow('On The Way', _getTimeAgo(DateTime.parse(sosAlert['on_the_way_at']))),
              if (sosAlert['resolved_at'] != null)
                _buildDetailRow('Resolved', _getTimeAgo(DateTime.parse(sosAlert['resolved_at']))),
              if (sosAlert['latitude'] != null && sosAlert['longitude'] != null)
                _buildDetailRow('Location', '${sosAlert['latitude']}, ${sosAlert['longitude']}'),
              if (sosAlert['message'] != null)
                _buildDetailRow('Message', sosAlert['message']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSOSAlertDetailsFromNotification(Map<String, dynamic> notificationData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Alert Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notificationData['sos_alert_id'] != null)
                _buildDetailRow('Alert ID', notificationData['sos_alert_id'].toString()),
              if (notificationData['status'] != null)
                _buildDetailRow('Status', notificationData['status'].toString()),
              if (notificationData['admin_name'] != null)
                _buildDetailRow('Admin', notificationData['admin_name'].toString()),
              if (notificationData['on_the_way_at'] != null)
                _buildDetailRow('On The Way', _getTimeAgo(DateTime.parse(notificationData['on_the_way_at'].toString()))),
              if (notificationData['resolved_at'] != null)
                _buildDetailRow('Resolved', _getTimeAgo(DateTime.parse(notificationData['resolved_at'].toString()))),
              if (notificationData['latitude'] != null && notificationData['longitude'] != null)
                _buildDetailRow('Location', '${notificationData['latitude']}, ${notificationData['longitude']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSOSAlertDetailsById(String alertId) async {
    try {
      final alert = await _databaseService.getSOSAlerts();
      final foundAlert = alert.firstWhere(
        (a) => a['id'] == alertId,
        orElse: () => {},
      );
      
      if (foundAlert.isNotEmpty) {
        _showSOSAlertDetails(foundAlert);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS alert details not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching SOS alert details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWeatherAlertDetails(Map<String, dynamic> weatherAlert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weather Alert'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Alert ID', weatherAlert['id']),
              _buildDetailRow('Created', _getTimeAgo(DateTime.parse(weatherAlert['created_at']))),
              _buildDetailRow('Message', weatherAlert['message'] ?? 'Weather conditions may affect your fishing activities.'),
              if (weatherAlert['severity'] != null)
                _buildDetailRow('Severity', weatherAlert['severity']),
              if (weatherAlert['expires_at'] != null)
                _buildDetailRow('Expires', _getTimeAgo(DateTime.parse(weatherAlert['expires_at']))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSystemAlertDetails(Map<String, dynamic> systemAlert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Notification'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Notification ID', systemAlert['id']),
              _buildDetailRow('Title', systemAlert['title'] ?? 'System Notification'),
              _buildDetailRow('Created', _getTimeAgo(DateTime.parse(systemAlert['created_at']))),
              _buildDetailRow('Message', systemAlert['message'] ?? 'You have a new system notification.'),
              if (systemAlert['priority'] != null)
                _buildDetailRow('Priority', systemAlert['priority']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      drawer: const FishermanDrawer(),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.whiteColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.whiteColor, size: isMobile ? 20 : 24),
            onPressed: () => _showMenu(context),
            tooltip: 'Notification Options',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.whiteColor, size: isMobile ? 20 : 24),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        color: AppColors.homeBackground,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              )
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: isMobile ? 60 : 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          'You\'ll see important updates here',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['isRead'] as bool;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                          leading: Container(
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification['type']).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getNotificationIcon(notification['type']),
                              color: _getNotificationColor(notification['type']),
                              size: isMobile ? 20 : 24,
                            ),
                          ),
                          title: Text(
                            notification['title'],
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                              color: isRead ? Colors.grey[700] : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: isMobile ? 3 : 4),
                              Text(
                                notification['message'],
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  color: isRead ? Colors.grey[600] : Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: isMobile ? 6 : 8),
                              Text(
                                _getTimeAgo(notification['timestamp']),
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: isMobile ? 6 : 8,
                                  height: isMobile ? 6 : 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () async {
                            // Mark as read if not already read
                            if (!isRead) {
                              try {
                                final notificationId = notification['id'] as String;
                                final success = await _notificationService.markNotificationAsRead(notificationId);
                                
                                if (success) {
                                  setState(() {
                                    notification['isRead'] = true;
                                  });
                                }
                              } catch (e) {
                                print('Error marking notification as read: $e');
                                // Still update UI even if database update fails
                                setState(() {
                                  notification['isRead'] = true;
                                });
                              }
                            }
                            
                            // Handle different notification types
                            if (notification['type'] == 'admin_action' && notification['adminAction'] != null) {
                              _showAdminActionDetails(notification['adminAction']);
                            } else if (notification['type'] == 'sos_on_the_way' || 
                                       notification['type'] == 'sos_resolved' ||
                                       notification['type'] == 'sos_active') {
                              // Show SOS alert details from notification data
                              final notificationData = notification['notificationData'] as Map<String, dynamic>?;
                              if (notificationData != null) {
                                _showSOSAlertDetailsFromNotification(notificationData);
                              } else if (notification['sosAlert'] != null) {
                                _showSOSAlertDetails(notification['sosAlert']);
                              } else if (notification['sosAlertId'] != null) {
                                // Fetch SOS alert details if we have the ID
                                _showSOSAlertDetailsById(notification['sosAlertId'] as String);
                              }
                            } else if (notification['type'] == 'sos' && notification['sosAlert'] != null) {
                              _showSOSAlertDetails(notification['sosAlert']);
                            } else if (notification['type'] == 'weather' && notification['weatherAlert'] != null) {
                              _showWeatherAlertDetails(notification['weatherAlert']);
                            } else if (notification['type'] == 'system' && notification['systemAlert'] != null) {
                              _showSystemAlertDetails(notification['systemAlert']);
                            }
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
