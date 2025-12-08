import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/fisherman/notification_popup.dart';
import '../providers/auth_provider.dart';
import 'fisherman_notification_service.dart';

class GlobalNotificationManager {
  static final GlobalNotificationManager _instance = GlobalNotificationManager._internal();
  factory GlobalNotificationManager() => _instance;
  GlobalNotificationManager._internal();

  final FishermanNotificationService _notificationService = FishermanNotificationService();
  StreamSubscription? _notificationStreamSubscription;
  Set<String> _shownNotificationIds = {};
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
    _removeOverlay();
    _context = null;
    _authProvider = null;
  }

  void _startListening() {
    if (_context == null || _authProvider == null) return;

    final currentUser = _authProvider!.currentUser;
    if (currentUser == null) return;

    // Cancel existing subscription if any
    _notificationStreamSubscription?.cancel();

    // Listen to real-time notifications
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
  }

  void _showNotificationPopup(Map<String, dynamic> notification) {
    if (_context == null || !_context!.mounted) return;

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
      Navigator.of(_context!).pushNamed('/fisherman/notifications');
    }
  }

  // Method to manually refresh the listener (useful after login)
  void refresh() {
    _shownNotificationIds.clear();
    _startListening();
  }
}

