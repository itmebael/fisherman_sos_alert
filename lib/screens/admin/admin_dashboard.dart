import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../constants/colors.dart';
import '../../constants/routes.dart';
import '../admin/admin_drawer.dart';
import '../../providers/admin_provider_simple.dart';
import '../../widgets/common/connection_status_widget.dart';
import '../../widgets/common/liquid_glass_container.dart';
import '../../services/database_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialAlertHandled = false;
  StreamSubscription<List<Map<String, dynamic>>>? _sosSubscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProviderSimple>().loadDashboardData();
      _listenInitialSOSAlerts();
    });
  }

  @override
  void dispose() {
    _sosSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _listenInitialSOSAlerts() async {
    _sosSubscription?.cancel();
    _sosSubscription = DatabaseService().getSOSAlertsStream().listen((alerts) async {
      if (_initialAlertHandled) return;
      if (alerts.isEmpty) return;
      final latest = alerts.first;
      final lat = (latest['latitude'] as num).toDouble();
      final lng = (latest['longitude'] as num).toDouble();
      final name = latest['fishermen'] != null
          ? (latest['fishermen']['name']?.toString() ?? 'Unknown')
          : (latest['message']?.toString() ?? 'SOS Alert');
      try {
        HapticFeedback.heavyImpact();
        await _audioPlayer.play(AssetSource('sounds/sosalert.mp3'));
      } catch (_) {}
      if (!mounted) return;
      _showInitialSOSDialog(lat, lng, name, latest);
      _initialAlertHandled = true;
    });
  }

  void _showInitialSOSDialog(double lat, double lng, String name, Map<String, dynamic> alert) {
    final createdAt = alert['created_at']?.toString() ?? '';
    String timeDisplay = 'Just now';
    try {
      if (createdAt.isNotEmpty) {
        final createdTime = DateTime.parse(createdAt);
        final difference = DateTime.now().difference(createdTime);
        if (difference.inSeconds < 60) {
          timeDisplay = '${difference.inSeconds} seconds ago';
        } else if (difference.inMinutes < 60) {
          timeDisplay = '${difference.inMinutes} minutes ago';
        } else {
          timeDisplay = '${difference.inHours} hours ago';
        }
      }
    } catch (_) {}
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEW SOS ALERT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  Text(timeDisplay, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Fisherman: $name', style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              final alertId = alert['id']?.toString();
              Navigator.pushNamed(
                context,
                AppRoutes.adminMap,
                arguments: {
                  if (alertId != null) 'alertId': alertId,
                  'latitude': lat,
                  'longitude': lng,
                },
              );
            },
            icon: const Icon(Icons.map, size: 18),
            label: const Text('View on Map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow body to extend behind app bar for full immersion
      backgroundColor: const Color(0xFFF5F5F7), // Light background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
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
                    builder: (context) => Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu_rounded, color: Colors.black87),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.purple.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.dashboard_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Maritime Rescue',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Control Center',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: ConnectionStatusWidget(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: const AdminDrawer(),
      body: SafeArea(
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

              final screenWidth = MediaQuery.of(context).size.width;
              final isMobile = screenWidth < 600;
              final isTablet = screenWidth >= 600 && screenWidth < 900;
              final padding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
              final cardSpacing = isMobile ? 12.0 : 16.0;

              return RefreshIndicator(
                onRefresh: () => admin.loadDashboardData(silent: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Total Fishermen',
                              value: admin.totalUsers.toString(),
                              icon: Icons.people_alt_rounded,
                              color: Colors.blue.shade700,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: cardSpacing),
                      isMobile
                          ? Column(
                              children: [
                                _buildMetricCard(
                                  title: 'Total Rescued',
                                  value: admin.totalRescued.toString(),
                                  icon: Icons.emergency_rounded,
                                  color: Colors.green.shade700,
                                  onTap: () {},
                                ),
                                SizedBox(height: cardSpacing),
                                _buildMetricCard(
                                  title: 'Active SOS',
                                  value: admin.activeSOSAlerts.toString(),
                                  icon: Icons.warning_rounded,
                                  color: Colors.red.shade700,
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.rescueNotifications),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    title: 'Total Rescued',
                                    value: admin.totalRescued.toString(),
                                    icon: Icons.emergency_rounded,
                                    color: Colors.green.shade700,
                                    onTap: () {},
                                  ),
                                ),
                                SizedBox(width: cardSpacing),
                                Expanded(
                                  child: _buildMetricCard(
                                    title: 'Active SOS',
                                    value: admin.activeSOSAlerts.toString(),
                                    icon: Icons.warning_rounded,
                                    color: Colors.red.shade700,
                                    onTap: () => Navigator.pushNamed(context, AppRoutes.rescueNotifications),
                                  ),
                                ),
                              ],
                            ),
                      SizedBox(height: cardSpacing),
                      isMobile
                          ? Column(
                              children: [
                                _buildMetricCard(
                                  title: 'Total Devices',
                                  value: admin.totalDevices.toString(),
                                  icon: Icons.devices_other,
                                  color: Colors.purple.shade700,
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.deviceManagement),
                                ),
                                SizedBox(height: cardSpacing),
                                _buildMetricCard(
                                  title: 'Device Mgmt',
                                  value: 'Manage',
                                  icon: Icons.settings,
                                  color: Colors.orange.shade800,
                                  onTap: () => Navigator.pushNamed(context, '/device-management'),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    title: 'Total Devices',
                                    value: admin.totalDevices.toString(),
                                    icon: Icons.devices_other,
                                    color: Colors.purple.shade700,
                                    onTap: () => Navigator.pushNamed(context, AppRoutes.deviceManagement),
                                  ),
                                ),
                                SizedBox(width: cardSpacing),
                                Expanded(
                                  child: _buildMetricCard(
                                    title: 'Device Mgmt',
                                    value: 'Manage',
                                    icon: Icons.settings,
                                    color: Colors.orange.shade800,
                                    onTap: () => Navigator.pushNamed(context, '/device-management'),
                                  ),
                                ),
                              ],
                            ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildEmergencyOverviewChart(admin, isMobile: isMobile),
                      SizedBox(height: isMobile ? 16 : 24),
                      isMobile
                          ? Column(
                              children: [
                                _buildPieChart(admin, isMobile: true),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildPieChart(admin, isMobile: false),
                                ),
                              ],
                            ),
                      SizedBox(height: isMobile ? 16 : 24),
                      isMobile
                          ? Column(
                              children: [
                              _buildAnalyticsChart(
                                context: context,
                                title: 'Rescue Success Rate',
                                value: '85%',
                                percentage: 0.85,
                                color: Colors.green.shade700,
                                icon: Icons.check_circle_outline,
                              ),
                              SizedBox(height: cardSpacing),
                              _buildAnalyticsChart(
                                context: context,
                                title: 'Response Time',
                                value: '12m',
                                percentage: 0.65,
                                color: Colors.blue.shade700,
                                icon: Icons.timer_outlined,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildAnalyticsChart(
                                  context: context,
                                  title: 'Rescue Success Rate',
                                  value: '85%',
                                  percentage: 0.85,
                                  color: Colors.green.shade700,
                                  icon: Icons.check_circle_outline,
                                ),
                              ),
                              SizedBox(width: cardSpacing),
                              Expanded(
                                child: _buildAnalyticsChart(
                                  context: context,
                                  title: 'Response Time',
                                  value: '12m',
                                  percentage: 0.65,
                                  color: Colors.blue.shade700,
                                  icon: Icons.timer_outlined,
                                ),
                              ),
                            ],
                          ),
                    SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return LiquidGlassContainer(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(Icons.arrow_forward_ios_rounded, 
                  color: Colors.black26, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildAnalyticsChart({
    required BuildContext context,
    required String title,
    required String value, // Changed from percentage to value string
    required Color color,
    required IconData icon,
    double percentage = 0.0, // Added optional percentage for backward compatibility
  }) {
    return LiquidGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (percentage > 0)
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(AdminProviderSimple admin, {required bool isMobile}) {
    final totalRescued = admin.totalRescued;
    final activeAlerts = admin.activeSOSAlerts;
    final totalForChart = totalRescued + activeAlerts;
    final rescuedPercent = totalForChart > 0 ? (totalRescued / totalForChart) * 100 : 0;
    final alertsPercent = totalForChart > 0 ? (activeAlerts / totalForChart) * 100 : 0;
    final rescuedValue = totalRescued > 0 ? totalRescued.toDouble() : 0.1;
    final alertsValue = activeAlerts > 0 ? activeAlerts.toDouble() : 0.1;
    
    final pieChartData = [
      PieChartSectionData(
        value: rescuedValue,
        title: rescuedValue > 0 ? '${rescuedPercent.toStringAsFixed(1)}%' : '',
        color: Colors.green.shade700,
        radius: 40.0,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: alertsValue,
        title: alertsValue > 0 ? '${alertsPercent.toStringAsFixed(1)}%' : '',
        color: Colors.red.shade700,
        radius: 40.0,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return LiquidGlassContainer(
      onTap: () => _showChartDetails(context, admin),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(Icons.pie_chart_rounded, 
                  color: Colors.black45, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: pieChartData,
                        sectionsSpace: 4,
                        centerSpaceRadius: 30,
                        centerSpaceColor: Colors.transparent,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Rescued', Colors.green.shade700),
                        const SizedBox(height: 8),
                        _buildLegendItem('Active SOS', Colors.red.shade700),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  
  void _showChartDetails(BuildContext context, AdminProviderSimple admin) {
    final totalRescued = admin.totalRescued;
    final activeAlerts = admin.activeSOSAlerts;
    final totalForChart = totalRescued + activeAlerts;
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
                  style: const TextStyle(
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

  Widget _buildEmergencyOverviewChart(AdminProviderSimple admin, {required bool isMobile}) {
    final stats = admin.emergencyStats;
    final filters = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    
    return LiquidGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // Time Filters
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: filters.map((filter) {
                    final isSelected = admin.selectedTimeFilter == filter;
                    return GestureDetector(
                      onTap: () => admin.setTimeFilter(filter),
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildChartLegendItem('SOS Alerts', Colors.red.shade700),
                _buildChartLegendItem('Injured', Colors.amber.shade800),
                _buildChartLegendItem('Casualties', Colors.grey),
                _buildChartLegendItem('Rescued', Colors.green.shade700),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: isMobile ? 250 : 300,
              child: stats.isEmpty
                  ? Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.black12,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < stats.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      stats[index].label,
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 8 : 10,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value % 1 == 0) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.right,
                                  );
                                }
                                return const SizedBox();
                              },
                              reservedSize: 30,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (stats.length - 1).toDouble(),
                        minY: 0,
                        lineBarsData: [
                          _buildLineChartBarData(
                            stats.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.sosCount.toDouble())).toList(),
                            Colors.red.shade700,
                          ),
                          _buildLineChartBarData(
                            stats.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.injuredCount.toDouble())).toList(),
                            Colors.amber.shade800,
                          ),
                          _buildLineChartBarData(
                            stats.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.casualtyCount.toDouble())).toList(),
                            Colors.grey,
                          ),
                          _buildLineChartBarData(
                            stats.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.rescuedCount.toDouble())).toList(),
                            Colors.green.shade700,
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.black.withOpacity(0.8),
                            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                              return touchedBarSpots.map((barSpot) {
                                final flSpot = barSpot;
                                if (flSpot.x < 0 || flSpot.x >= stats.length) {
                                  return null;
                                }
                                
                                String label = '';
                                Color color = Colors.grey;
                                
                                switch (barSpot.barIndex) {
                                  case 0:
                                    label = 'SOS';
                                    color = Colors.red.shade700;
                                    break;
                                  case 1:
                                    label = 'Injured';
                                    color = Colors.amber.shade800;
                                    break;
                                  case 2:
                                    label = 'Casualties';
                                    color = Colors.grey;
                                    break;
                                  case 3:
                                    label = 'Rescued';
                                    color = Colors.green.shade700;
                                    break;
                                }

                                return LineTooltipItem(
                                  '$label: ${flSpot.y.toInt()}',
                                  TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }
  
  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }


}
   
