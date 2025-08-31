import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/routes.dart';
import '../../providers/auth_provider.dart';

class FishermanDrawer extends StatelessWidget {
  const FishermanDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.drawerColor,
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              color: AppColors.drawerColor,
              child: const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        AppStrings.welcome,
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                    _buildDrawerItem(
                      context,
                      icon: Icons.home,
                      title: AppStrings.home,
                      route: AppRoutes.fishermanHome,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.newspaper,
                      title: AppStrings.news,
                      route: AppRoutes.fishermanNews,
                    ),
                  ],
                ),
              ),
            ),

            // Logout Button (matching admin drawer design)
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
                onPressed: () async {
                  // Call AuthProvider to logout
                  await Provider.of<AuthProvider>(context, listen: false).logout();

                  // Navigate to login screen
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
              ),
            ),
          ],
        ),
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
          child: Icon(
            icon,
            color: AppColors.whiteColor,
            size: 20, // Adjusted to match admin drawer
          ),
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
          Navigator.of(context).pop();
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}