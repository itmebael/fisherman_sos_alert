import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final totalRescued = admin.totalRescued;
    final activeAlerts = admin.activeSOSAlerts;
    final totalForChart = totalRescued + activeAlerts;
    
    // Calculate percentages based on rescued + alerts only (100% total)
    final rescuedPercent = totalForChart > 0 ? (totalRescued / totalForChart) * 100 : 0;
    final alertsPercent = totalForChart > 0 ? (activeAlerts / totalForChart) * 100 : 0;
    
    // Prepare pie chart data with accurate values
    final rescuedValue = totalRescued > 0 ? totalRescued.toDouble() : 0.1;
    final alertsValue = activeAlerts > 0 ? activeAlerts.toDouble() : 0.1;
    
    final pieChartData = [
      PieChartSectionData(
        value: rescuedValue,
        title: rescuedValue > 0 ? '${rescuedPercent.toStringAsFixed(1)}%' : '',
        color: AppColors.successColor,
        radius: 50.0,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: totalRescued > 0
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 16, color: Colors.white),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        value: alertsValue,
        title: alertsValue > 0 ? '${alertsPercent.toStringAsFixed(1)}%' : '',
        color: AppColors.errorColor,
        radius: 50.0,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: activeAlerts > 0
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, size: 16, color: Colors.white),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
    ];

    return GestureDetector(
      onTap: () => _showChartDetails(context, admin),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User Distribution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  // 3D Pie Chart using fl_chart
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 3D shadow effect (bottom layer)
                        Transform.translate(
                          offset: const Offset(2, 2),
                          child: PieChart(
                            PieChartData(
                              sections: pieChartData.map((section) {
                                final radiusValue = section.radius;
                                return PieChartSectionData(
                                  value: section.value,
                                  color: Colors.black.withOpacity(0.1),
                                  radius: radiusValue - 2.0,
                                  showTitle: false,
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 30,
                            ),
                          ),
                        ),
                        // Main pie chart (top layer)
                        PieChart(
                          PieChartData(
                            sections: pieChartData,
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            centerSpaceColor: Colors.white,
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                if (event is FlTapUpEvent && pieTouchResponse != null) {
                                  final sectionIndex = pieTouchResponse.touchedSection?.touchedSectionIndex ?? -1;
                                  if (sectionIndex >= 0 && sectionIndex < pieChartData.length) {
                                    final labels = ['Rescued', 'Active Alerts'];
                                    final values = [totalRescued, activeAlerts];
                                    final colors = [AppColors.successColor, AppColors.errorColor];
                                    final percents = [rescuedPercent, alertsPercent];
                                    _showCategoryDetails(
                                      context,
                                      labels[sectionIndex],
                                      values[sectionIndex],
                                      colors[sectionIndex],
                                      percents[sectionIndex].toDouble(),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        // Center text with total
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              totalForChart.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legend with percentages
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Rescued', totalRescued, AppColors.successColor, rescuedPercent.toDouble()),
                        const SizedBox(height: 6),
                        _buildLegendItem('Active Alerts', activeAlerts, AppColors.errorColor, alertsPercent.toDouble()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color, double percent) {
    return GestureDetector(
      onTap: () => _showCategoryDetails(context, label, value, color, percent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showChartDetails(BuildContext context, AdminProviderSimple admin) {
    final totalRescued = admin.totalRescued;
    final activeAlerts = admin.activeSOSAlerts;
    final totalForChart = totalRescued + activeAlerts;
    
    // Calculate percentages based on rescued + alerts only (100% total)
    final rescuedPercent = totalForChart > 0 ? (totalRescued / totalForChart) * 100 : 0;
    final alertsPercent = totalForChart > 0 ? (activeAlerts / totalForChart) * 100 : 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Distribution Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Total', totalForChart.toString(), Colors.blue),
            const SizedBox(height: 12),
            _buildDetailRow('Rescued', totalRescued.toString(), AppColors.successColor, 
                percent: rescuedPercent.toDouble()),
            const SizedBox(height: 12),
            _buildDetailRow('Active Alerts', activeAlerts.toString(), AppColors.errorColor,
                percent: alertsPercent.toDouble()),
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
  
  void _showCategoryDetails(BuildContext context, String label, int value, Color color, double percent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
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
  
  Widget _buildDetailRow(String label, String value, Color color, {double? percent}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (percent != null) ...[
                const SizedBox(width: 8),
                Text(
                  '(${percent.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
    final totalRescues = chartData.fold<int>(0, (sum, e) => sum + (e['rescues'] as int));

    return GestureDetector(
      onTap: () => _showBarChartDetails(context, chartData, totalRescues),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Rescues',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: chartData.asMap().entries.map((entry) {
                    final data = entry.value;
                    final value = data['rescues'] as int;
                    final height = maxValue > 0 ? (value / maxValue) * 100.0 : 0.0;
                    final percent = totalRescues > 0 ? (value / totalRescues) * 100.0 : 0.0;
                    
                    return GestureDetector(
                      onTap: () => _showDayDetails(context, data['day'] as String, value, percent),
                      child: Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Tooltip(
                              message: '${data['day']}: $value (${percent.toStringAsFixed(1)}%)',
                              child: Container(
                                width: 20,
                                height: height.toDouble(),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
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
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showBarChartDetails(BuildContext context, List<Map<String, dynamic>> chartData, int totalRescues) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weekly Rescues Details'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Rescues:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      totalRescues.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...chartData.map((data) {
                final value = data['rescues'] as int;
                final percent = totalRescues > 0 ? (value / totalRescues) * 100 : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data['day'] as String),
                      Row(
                        children: [
                          Text(
                            value.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${percent.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
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
  
  void _showDayDetails(BuildContext context, String day, int value, double percent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(day),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percent.toStringAsFixed(1)}% of total',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
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
}