import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/fisherman_notification_service.dart';

class FishermanDrawer extends StatefulWidget {
  const FishermanDrawer({super.key});

  @override
  State<FishermanDrawer> createState() => _FishermanDrawerState();
}

class _FishermanDrawerState extends State<FishermanDrawer> {
  final FishermanNotificationService _notificationService =
      FishermanNotificationService();
  int _unreadCount = 0;
  StreamSubscription? _notificationCountSubscription;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _startListeningToNotifications();
  }

  @override
  void dispose() {
    _notificationCountSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;

    if (currentUser == null) return;

    final count = await _notificationService.getUnreadNotificationsCount(
      fishermanUid: currentUser.id,
      fishermanEmail: currentUser.email,
    );

    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void _startListeningToNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.currentUser;

      if (currentUser == null) return;

      _notificationCountSubscription = _notificationService
          .getNotificationsStream(
            fishermanUid: currentUser.id,
            fishermanEmail: currentUser.email,
          )
          .listen((notifications) {
            if (!mounted) return;

            final unreadCount = notifications
                .where((n) => !(n['isRead'] as bool? ?? false))
                .length;
            setState(() {
              _unreadCount = unreadCount;
            });
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      // 👇 Drawer width adjusts based on screen size
      width: screenWidth * 0.7, // 70% of screen width (adjust as needed)
      child: Drawer(
        child: Container(
          color: AppColors.drawerColor,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.drawerColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          AppStrings.welcome,
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),

              // Menu Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Menu Items
              Expanded(
                child: Container(
                  color: AppColors.drawerColor,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      _buildDrawerItem(
                        context,
                        icon: Icons.home,
                        title: AppStrings.home,
                        route: AppRoutes.fishermanHome,
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.wb_sunny,
                        title: 'Weather',
                        route: AppRoutes.fishermanNews,
                      ),
                      _buildDrawerItemWithBadge(
                        context,
                        icon: Icons.notifications_active,
                        title: 'Notifications',
                        route: AppRoutes.fishermanNotifications,
                        badgeCount: _unreadCount,
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.map,
                        title: 'Map',
                        route: AppRoutes.fishermanMap,
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.person,
                        title: 'Profile',
                        route: AppRoutes.fishermanProfile,
                      ),
                    ],
                  ),
                ),
              ),

              // Account Section Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: const Text(
                  'Account',
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Logout Button
              Container(
                margin: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    "Logout",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    _showLogoutConfirmation(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Store root context before closing dialog
              final rootContext = Navigator.of(context, rootNavigator: true).context;
              
              // Close the dialog first
              Navigator.of(context).pop();
              
              // Wait a moment for dialog to close
              await Future.delayed(const Duration(milliseconds: 100));
              
              // Perform logout
              try {
                await Provider.of<AuthProvider>(
                  rootContext,
                  listen: false,
                ).logout();
              } catch (e) {
                print('Logout error: $e');
                // Continue with navigation even if logout has issues
              }

              // Navigate to login screen
              if (rootContext.mounted) {
                Navigator.pushReplacementNamed(rootContext, AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.whiteColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.whiteColor, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.whiteColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushNamed(context, route);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minVerticalPadding: 0,
      ),
    );
  }

  Widget _buildDrawerItemWithBadge(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required int badgeCount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.whiteColor, size: 18),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.whiteColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushNamed(context, route);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minVerticalPadding: 0,
      ),
    );
  }
}
