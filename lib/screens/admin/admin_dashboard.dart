import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../admin/admin_drawer.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/dashboard_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/img/logo.png',
                width: 36, // bigger logo
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 5),
            ClipOval(
              child: Image.asset(
                'assets/img/coastguard.png',
                width: 36, // bigger logo
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "BantayDagat",
              style: TextStyle(
                color: Color(0xFF13294B),
                fontWeight: FontWeight.bold,
                fontSize: 24, // much bigger font for app title
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: Container(
        width: double.infinity,
        color: AppColors.homeBackground,
        child: SafeArea(
          child: Consumer<AdminProvider>(
            builder: (context, admin, _) {
              return Padding(
                padding: const EdgeInsets.all(10), // less padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mobile Rescue And Location Tracking System",
                      style: TextStyle(
                        fontSize: 24, // much bigger header text to match the reference
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Layout matching the UI design - 2 cards on top row, 1 card below
                    Expanded(
                      child: Column(
                        children: [
                          // Top row - Total Users and Registered Boats
                          SizedBox(
                            height: 250, // Much larger height for top row cards
                            child: Row(
                              children: [
                                // Total Users card
                                Expanded(
                                  child: DashboardCard(
                                    title: 'Total Users',
                                    value: admin.totalUsers.toString(),
                                    icon: Icons.people,
                                    onTap: () {},
                                    backgroundColor: AppColors.newsBackground,
                                    iconColor: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Registered Boats card
                                Expanded(
                                  child: DashboardCard(
                                    title: 'Registered Boats',
                                    value: admin.totalBoats.toString(),
                                    icon: Icons.directions_boat,
                                    onTap: () {},
                                    backgroundColor: AppColors.newsBackground,
                                    iconColor: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10), // Small gap between rows
                          // Bottom row - Total Rescued (taking half width on left side)
                          SizedBox(
                            height: 250, // Much larger height for bottom row cards
                            child: Row(
                              children: [
                                // Total Rescued card (half width)
                                Expanded(
                                  child: DashboardCard(
                                    title: 'Total Rescued',
                                    value: admin.totalRescued.toString(),
                                    icon: Icons.sos,
                                    onTap: () {},
                                    backgroundColor: AppColors.newsBackground,
                                    iconColor: AppColors.primaryColor,
                                  ),
                                ),
                                // Empty space to match the layout
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ),
                          // Add spacer to push content to top
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}