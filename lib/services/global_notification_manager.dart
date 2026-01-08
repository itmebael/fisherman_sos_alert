import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/fisherman/notification_popup.dart';
import '../providers/auth_provider.dart';
import 'fisherman_notification_service.dart';
import 'database_service.dart';
import '../constants/routes.dart';

class GlobalNotificationManager {
  static final GlobalNotificationManager _instance = GlobalNotificationManager._internal();
  factory GlobalNotificationManager() => _instance;
  GlobalNotificationManager._internal();

  final FishermanNotificationService _notificationService = FishermanNotificationService();
  StreamSubscription? _notificationStreamSubscription;
  StreamSubscription? _sosSubscription;
  Set<String> _shownNotificationIds = {};
  Set<String> _shownSOSAlertIds = {};
  OverlayEntry? _currentOverlay;
  BuildContext? _context;
  AuthProvider? _authProvider;

  void initialize(BuildContext context, AuthProvider authProvider) {
    _context = context;
    _authProvider = authProvider;
    _startListening();
  }

  void dispose() {
    _notificationStreamSubscription?.cancel();
    _sosSubscription?.cancel();
    _removeOverlay();
    _context = null;
    _authProvider = null;
  }

  void _startListening() {
    if (_context == null || _authProvider == null) return;

    final currentUser = _authProvider!.currentUser;
    if (currentUser == null) return;

    // Cancel existing subscriptions if any
    _notificationStreamSubscription?.cancel();
    _sosSubscription?.cancel();

    // 1. Listen to real-time notifications (table: notifications)
    _notificationStreamSubscription = _notificationService
        .getNotificationsStream(
          fishermanUid: currentUser.id,
          fishermanEmail: currentUser.email,
        )
        .listen((notifications) {
      if (_context == null || !_context!.mounted) return;

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
    });

    // 2. Listen to SOS status changes directly (table: sos_alerts)
    // This ensures we catch status changes even if a notification record wasn't created
    _sosSubscription = DatabaseService()
        .getFishermanSOSStream(currentUser.id)
        .listen((alerts) {
      if (_context == null || !_context!.mounted) return;

      for (final alert in alerts) {
        final alertId = alert['id'] as String;
        final status = alert['status'] as String;
        
        // Check for 'on_the_way' status
        if (status == 'on_the_way') {
          // Use a unique key for this specific state to avoid repetition
          final trackingKey = '${alertId}_on_the_way';
          
          if (!_shownSOSAlertIds.contains(trackingKey)) {
            _shownSOSAlertIds.add(trackingKey);
            
            // Create a synthetic notification object
            final notification = {
              'id': 'temp_$trackingKey',
              'title': 'Rescue Incoming!',
              'message': 'The admin has marked your SOS as "On The Way". Rescue team is heading to your location.',
              'type': 'sos_on_the_way',
              'isRead': false,
            };
            
            _showCriticalNotificationDialog(notification);
          }
        }
      }
    });
  }

  void _showNotificationPopup(Map<String, dynamic> notification) {
    if (_context == null || !_context!.mounted) return;

    final type = notification['type'] ?? 'system';

    // For critical updates (SOS status changes), show a dialog
    if (type == 'sos_on_the_way' || type == 'sos_resolved') {
      _showCriticalNotificationDialog(notification);
      return;
    }

    // Remove any existing overlay
    _removeOverlay();

    final overlay = Overlay.of(_context!);

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

  void _showCriticalNotificationDialog(Map<String, dynamic> notification) {
    if (_context == null || !_context!.mounted) return;

    final type = notification['type'];
    final title = notification['title'] ?? 'Update';
    final message = notification['message'] ?? '';

    Color dialogColor;
    IconData icon;

    if (type == 'sos_on_the_way') {
      dialogColor = Colors.green;
      icon = Icons.directions_boat;
    } else if (type == 'sos_resolved') {
      dialogColor = Colors.orange;
      icon = Icons.check_circle;
    } else {
      dialogColor = Colors.blue;
      icon = Icons.info;
    }

    showDialog(
      context: _context!,
      barrierDismissible: false, // User must acknowledge
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: dialogColor, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: dialogColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleNotificationTap(notification); // Mark as read and navigate
            },
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                color: dialogColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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

    // Navigate to notifications screen
    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pushNamed(AppRoutes.fishermanNotifications);
    }
  }

  // Method to manually refresh the listener (useful after login)
  void refresh() {
    _shownNotificationIds.clear();
    _startListening();
  }
}

