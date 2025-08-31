import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/routes.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.drawerColor,
        child: Column(
          children: [
            // Header
            Container(
              height: 120,
              width: double.infinity,
              color: AppColors.drawerColor,
              child: const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Coast Guard Menu',
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: Container(
                color: AppColors.drawerColor,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildItem(context, Icons.dashboard, 'Dashboard', AppRoutes.adminDashboard),
                    _buildItem(context, Icons.people, 'Users', AppRoutes.adminUsers),
                    _buildItem(context, Icons.notifications_active, 'Rescue Notifications', AppRoutes.rescueNotifications),
                    _buildItem(context, Icons.navigation, 'Navigation', AppRoutes.navigation),
                    _buildItem(context, Icons.assessment, 'Reports', AppRoutes.reports),
                    _buildItem(context, Icons.settings, 'Settings', AppRoutes.settings),
                    _buildItem(context, Icons.person_add, 'Register', AppRoutes.register),
                  ],
                ),
              ),
            ),

            // 🔽 Highlighted Logout Button
            Container(
              margin: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Solid red background
                  foregroundColor: Colors.white, // White text & icon
                  minimumSize: const Size(double.infinity, 50), // Full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  elevation: 3, // Slight shadow to pop out
                ),
                icon: const Icon(Icons.logout, size: 22),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  // Call your provider/service to logout
                  Provider.of<AuthProvider>(context, listen: false).logout();

                  // Redirect to login
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, String route) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.whiteColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.whiteColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.whiteColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}
