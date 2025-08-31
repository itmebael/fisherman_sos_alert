import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/routes.dart';

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
            
            Expanded(
              child: Container(
                color: AppColors.drawerColor,
                child: Column(
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
                    _buildDrawerItem(
                      context,
                      icon: Icons.login,
                      title: AppStrings.login,
                      route: AppRoutes.login,
                    ),
                  ],
                ),
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
            size: 24,
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