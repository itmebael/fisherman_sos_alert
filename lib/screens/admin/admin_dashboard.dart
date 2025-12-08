import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../admin/admin_drawer.dart';
import '../../providers/admin_provider_simple.dart';
import '../../widgets/admin/dashboard_card.dart';
import '../../widgets/common/connection_status_widget.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProviderSimple>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientEnd,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.whiteColor),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.whiteColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: AppColors.whiteColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maritime Rescue Dashboard',
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Control Center Overview',
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: const ConnectionStatusWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const AdminDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart.withOpacity(0.1),
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AdminProviderSimple>(
            builder: (context, admin, _) {
              if (admin.isLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading dashboard data...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row - Total Users
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Total Fishermen Accounts',
                            value: admin.totalUsers.toString(),
                            icon: Icons.people_alt_rounded,
                            onTap: () {},
                            backgroundColor: AppColors.cardBackground,
                            iconColor: AppColors.primaryColor,
                            gradientStart: AppColors.primaryColor,
                            gradientEnd: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Second row - Total Rescued and Active SOS Alerts
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Total Rescued',
                            value: admin.totalRescued.toString(),
                            icon: Icons.emergency_rounded,
                            onTap: () {},
                            backgroundColor: AppColors.cardBackground,
                            iconColor: AppColors.successColor,
                            gradientStart: AppColors.successColor,
                            gradientEnd: AppColors.accentColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            title: 'Active SOS Alerts',
                            value: admin.activeSOSAlerts.toString(),
                            icon: Icons.warning_rounded,
                            onTap: () {
                              Navigator.pushNamed(context, '/rescue_notifications');
                            },
                            backgroundColor: AppColors.cardBackground,
                            iconColor: AppColors.errorColor,
                            gradientStart: AppColors.errorColor,
                            gradientEnd: AppColors.warningColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Third row - Device Management
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Total Devices',
                            value: admin.totalDevices.toString(),
                            icon: Icons.devices_other,
                            onTap: () {
                              Navigator.pushNamed(context, '/device-management');
                            },
                            backgroundColor: AppColors.cardBackground,
                            iconColor: AppColors.primaryColor,
                            gradientStart: AppColors.primaryColor,
                            gradientEnd: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            title: 'Device Management',
                            value: 'Manage',
                            icon: Icons.settings,
                            onTap: () {
                              Navigator.pushNamed(context, '/device-management');
                            },
                            backgroundColor: AppColors.cardBackground,
                            iconColor: AppColors.accentColor,
                            gradientStart: AppColors.accentColor,
                            gradientEnd: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Analytics Section with Charts
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.analytics_rounded,
                                  color: AppColors.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Analytics Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Charts Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildPieChart(admin),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildBarChart(admin),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Metrics Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildAnalyticsChart(
                                  title: 'Rescue Success Rate',
                                  value: '${((admin.totalRescued / (admin.totalUsers > 0 ? admin.totalUsers : 1)) * 100).toStringAsFixed(1)}%',
                                  color: AppColors.successColor,
                                  icon: Icons.trending_up_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAnalyticsChart(
                                  title: 'Active Alerts',
                                  value: admin.activeSOSAlerts.toString(),
                                  color: AppColors.errorColor,
                                  icon: Icons.warning_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAnalyticsChart(
                                  title: 'Response Time',
                                  value: '${(admin.totalRescued * 15).toString()} min',
                                  color: AppColors.secondaryColor,
                                  icon: Icons.timer_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAnalyticsChart(
                                  title: 'Coverage Area',
                                  value: '${admin.totalUsers * 5} km²',
                                  color: AppColors.accentColor,
                                  icon: Icons.location_on_rounded,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildAnalyticsChart({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(AdminProviderSimple admin) {
    final totalUsers = admin.totalUsers;
    final totalRescued = admin.totalRescued;
    final activeAlerts = admin.activeSOSAlerts;
    final otherUsers = totalUsers - totalRescued - activeAlerts;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Distribution',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                // Simple pie chart representation using colored circles
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.successColor,
                              AppColors.errorColor,
                              AppColors.secondaryColor,
                            ],
                            stops: [
                              totalRescued / totalUsers,
                              (totalRescued + activeAlerts) / totalUsers,
                              1.0,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                totalUsers.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Legend
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Rescued', totalRescued, AppColors.successColor),
                      const SizedBox(height: 4),
                      _buildLegendItem('Active Alerts', activeAlerts, AppColors.errorColor),
                      const SizedBox(height: 4),
                      _buildLegendItem('Others', otherUsers > 0 ? otherUsers : 0, AppColors.secondaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(AdminProviderSimple admin) {
    // Sample data for the last 7 days
    final chartData = [
      {'day': 'Mon', 'rescues': admin.totalRescued > 0 ? (admin.totalRescued * 0.8).round() : 2},
      {'day': 'Tue', 'rescues': admin.totalRescued > 0 ? (admin.totalRescued * 0.6).round() : 1},
      {'day': 'Wed', 'rescues': admin.totalRescued > 0 ? (admin.totalRescued * 1.2).round() : 3},
      {'day': 'Thu', 'rescues': admin.totalRescued > 0 ? (admin.totalRescued * 0.9).round() : 2},
      {'day': 'Fri', 'rescues': admin.totalRescued > 0 ? (admin.totalRescued * 1.1).round() : 4},
      {'day': 'Sat', 'rescues': admin.totalRescued > 0 ? (admin.totalRescued * 0.7).round() : 1},
      {'day': 'Sun', 'rescues': admin.totalRescued > 0 ? (admin.totalRescued * 0.5).round() : 1},
    ];

    final maxValue = chartData.map((e) => e['rescues'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Rescues',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final value = data['rescues'] as int;
                  final height = (value / maxValue) * 100; // Reduced max height to 100
                  
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 20,
                          height: height,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['day'] as String,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          value.toString(),
                          style: const TextStyle(
                            fontSize: 7,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}