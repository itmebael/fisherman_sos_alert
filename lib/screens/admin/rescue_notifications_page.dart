import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/routes.dart';
import '../../services/database_service.dart';
import '../../providers/admin_provider_simple.dart';
import '../admin/admin_drawer.dart';

class RescueNotificationsPage extends StatefulWidget {
  const RescueNotificationsPage({super.key});

  @override
  State<RescueNotificationsPage> createState() => _RescueNotificationsPageState();
}

class _RescueNotificationsPageState extends State<RescueNotificationsPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showAllAlerts = false; // Toggle to show all alerts or only active

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load alerts from database
      // Get all alerts (active, on_the_way, resolved) if showAllAlerts is true
      // Otherwise, get only active alerts
      List<Map<String, dynamic>> alerts;
      
      if (_showAllAlerts) {
        // Get all alerts with different statuses
        alerts = await _databaseService.getAllSOSAlerts();
      } else {
        // Get only active alerts
        alerts = await _databaseService.getSOSAlerts();
      }

      // Fetch boat information for each alert
      alerts = await _enrichAlertsWithBoatInfo(alerts);

      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading alerts: $e');
      setState(() {
        _errorMessage = 'Error loading alerts: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _enrichAlertsWithBoatInfo(List<Map<String, dynamic>> alerts) async {
    final enrichedAlerts = <Map<String, dynamic>>[];
    
    for (var alert in alerts) {
      final enrichedAlert = Map<String, dynamic>.from(alert);
      final fishermanUid = alert['fisherman_uid']?.toString();
      
      if (fishermanUid != null && fishermanUid.isNotEmpty) {
        try {
          // Fetch boat information for this fisherman
          final boats = await _databaseService.getBoatsByOwnerId(fishermanUid);
          if (boats.isNotEmpty) {
            final boat = boats.first;
            // Try different possible field names (registration_number is the most common identifier)
            enrichedAlert['boat_number'] = boat['registration_number'] ?? 
                                          boat['registrationNumber'] ??
                                          boat['boat_number'] ?? 
                                          boat['boatNumber'] ?? 
                                          boat['name'] ??
                                          boat['id'] ?? 
                                          '-';
            enrichedAlert['boat_name'] = boat['name'];
            enrichedAlert['boat_type'] = boat['type'] ?? boat['boat_type'] ?? boat['boatType'];
            enrichedAlert['boat_registration_number'] = boat['registration_number'] ?? boat['registrationNumber'];
          } else {
            enrichedAlert['boat_number'] = '-';
          }
        } catch (e) {
          print('Error fetching boat info for fisherman $fishermanUid: $e');
          enrichedAlert['boat_number'] = '-';
        }
      } else {
        enrichedAlert['boat_number'] = '-';
      }
      
      enrichedAlerts.add(enrichedAlert);
    }
    
    return enrichedAlerts;
  }

  // Method to toggle between active and all alerts
  void _toggleAlertView() {
    setState(() {
      _showAllAlerts = !_showAllAlerts;
    });
    _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // BantayDagat logo
            ClipOval(
              child: Image.asset(
                'assets/img/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            // Coast Guard logo
            ClipOval(
              child: Image.asset(
                'assets/img/coastguard.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // App title
            Text(
              "Salbar Mangirisda",
              style: const TextStyle(
                color: Color(0xFF13294B),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.homeBackground,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showAllAlerts ? Icons.filter_list : Icons.list,
              color: AppColors.textPrimary,
            ),
            tooltip: _showAllAlerts ? 'Show Active Only' : 'Show All Alerts',
            onPressed: _toggleAlertView,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Refresh',
            onPressed: _loadAlerts,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.homeBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mobile Rescue And Location Tracking System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.drawerColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Rescue Notification Record',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.drawerColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _errorMessage != null
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              size: 48,
                                              color: Colors.red[300],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.red[700],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: _loadAlerts,
                                              icon: const Icon(Icons.refresh),
                                              label: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _alerts.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.notifications_off,
                                                  size: 48,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  _showAllAlerts
                                                      ? 'No SOS alerts found'
                                                      : 'No active SOS alerts',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.separated(
                                            itemCount: _alerts.length,
                                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                                            itemBuilder: (context, index) {
                                              final a = _alerts[index];
                                              
                                              // Get fisherman name with better fallback logic
                                              String fishermanName = 'Unknown';
                                              if (a['fisherman_name'] != null && a['fisherman_name'].toString().isNotEmpty) {
                                                fishermanName = a['fisherman_name'].toString();
                                              } else if (a['fisherman_first_name'] != null && a['fisherman_last_name'] != null) {
                                                final firstName = a['fisherman_first_name'].toString().trim();
                                                final lastName = a['fisherman_last_name'].toString().trim();
                                                fishermanName = '$firstName $lastName'.trim();
                                                if (fishermanName.isEmpty) {
                                                  fishermanName = a['fisherman_first_name']?.toString() ?? 'Unknown';
                                                }
                                              } else if (a['fisherman_first_name'] != null && a['fisherman_first_name'].toString().isNotEmpty) {
                                                fishermanName = a['fisherman_first_name'].toString();
                                              } else if (a['fisherman_email'] != null && a['fisherman_email'].toString().isNotEmpty) {
                                                fishermanName = a['fisherman_email'].toString();
                                              }
                                              
                                              // Get boat number from enriched alert data
                                              final boatNumber = a['boat_number']?.toString() ?? 
                                                               a['boat_registration_number']?.toString() ??
                                                               '-';
                                              
                                              // Format timestamp
                                              String timestamp = '';
                                              if (a['created_at'] != null) {
                                                try {
                                                  final dateTime = DateTime.parse(a['created_at'].toString());
                                                  timestamp = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                                                } catch (e) {
                                                  timestamp = a['created_at'].toString();
                                                }
                                              }
                                              
                                              return _buildEmergencyAlertCard(
                                                context: context,
                                                alert: a,
                                                fishermanName: fishermanName,
                                                boatNumber: boatNumber,
                                                timestamp: timestamp,
                                              );
                                            },
                                          ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyAlertCard({
    required BuildContext context,
    required Map<String, dynamic> alert,
    required String fishermanName,
    required String boatNumber,
    required String timestamp,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D8C), // Teal blue background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status-based icon and text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(alert['status'] ?? 'active'),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(alert['status'] ?? 'active'),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusTitle(alert['status'] ?? 'active'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusMessage(alert['status'] ?? 'active'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Fisherman info
          Row(
            children: [
              const Text(
                'Fisherman: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  fishermanName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          // Additional fisherman details if available
          if (alert['fisherman_email'] != null && alert['fisherman_email'].toString().isNotEmpty && 
              fishermanName != alert['fisherman_email'].toString()) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Email: ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    alert['fisherman_email'].toString(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          
          if (alert['fisherman_phone'] != null && alert['fisherman_phone'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Phone: ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    alert['fisherman_phone'].toString(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Boat information
          if (boatNumber != '-') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Boat: ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    boatNumber,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                timestamp,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons - only show if alert is active
          if (alert['status'] == 'active' || alert['status'] == null)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showLocationOnMap(context, alert),
                        icon: const Icon(Icons.location_on, size: 18),
                        label: const Text('View on Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _notifyOnTheWay(context, alert),
                        icon: const Icon(Icons.directions_boat, size: 18),
                        label: const Text('On the Way'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsResolved(context, alert),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Mark as Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else if (alert['status'] == 'on_the_way')
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showLocationOnMap(context, alert),
                        icon: const Icon(Icons.location_on, size: 18),
                        label: const Text('View on Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsResolved(context, alert),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mark as Resolved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showLocationOnMap(context, alert),
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('View on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch phone call';
      }
    } catch (e) {
      // Handle error - phone call not available
      print('Error making phone call: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Unable to make phone call. $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationOnMap(BuildContext context, Map<String, dynamic> alert) {
    // Navigate to maritime map with the alert location
    final latitude = (alert['latitude'] as num?)?.toDouble();
    final longitude = (alert['longitude'] as num?)?.toDouble();
    final alertId = alert['id']?.toString();
    
    if (latitude != null && longitude != null && alertId != null) {
      // Navigate to admin map with the alert location as searched location
      Navigator.pushNamed(
        context,
        AppRoutes.adminMap,
        arguments: {
          'alertId': alertId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    } else {
      // Show error if location data is missing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Alert location data is missing'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _notifyOnTheWay(BuildContext context, Map<String, dynamic> alert) async {
    final alertId = alert['id']?.toString();
    if (alertId == null || alertId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Alert ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Updating alert status...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // Update alert status in database
      final success = await _databaseService.updateSOSAlertStatus(alertId, 'on_the_way');
      
      if (success) {
        // Reload alerts to get updated data
        await _loadAlerts();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.directions_boat, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Help is on the way to ${alert['fisherman_name'] ?? alert['fisherman_first_name'] ?? alert['fisherman_email'] ?? 'fisherman'}!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Failed to update alert status');
      }
    } catch (e) {
      print('Error updating alert status: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _markAsResolved(BuildContext context, Map<String, dynamic> alert) async {
    final alertId = alert['id']?.toString();
    if (alertId == null || alertId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Alert ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog with statistics input
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ResolveDialog(
        fishermanName: alert['fisherman_name'] ?? alert['fisherman_first_name'] ?? alert['fisherman_email'] ?? 'fisherman',
      ),
    );

    if (result != null && result['confirmed'] == true) {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Updating alert status...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      try {
        final casualties = result['casualties'] as int? ?? 0;
        final injured = result['injured'] as int? ?? 0;
        
        // Mark as inactive when resolved is clicked
        final success = await _databaseService.updateSOSAlertStatus(
          alertId,
          'inactive',
          casualties: casualties,
          injured: injured,
        );
        
        if (success) {
          // Wait a moment for database to update
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Reload alerts to get updated data
          await _loadAlerts();
          
          // Refresh dashboard data
          if (context.mounted) {
            // Trigger dashboard refresh if available
            final adminProvider = Provider.of<AdminProviderSimple>(context, listen: false);
            await adminProvider.loadDashboardData();
          }
          
          // Get statistics and show popup
          final stats = await _databaseService.getRescueStatistics();
          
          if (context.mounted) {
            // Show statistics popup
            await showDialog(
              context: context,
              builder: (context) => _RescueStatisticsDialog(
                totalRescue: stats['totalRescue'] ?? 0,
                casualties: stats['casualties'] ?? 0,
                injured: stats['injured'] ?? 0,
              ),
            );
          }
        } else {
          throw Exception('Failed to update alert status');
        }
      } catch (e) {
        print('Error updating alert status: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Helper methods for status display
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFFE53E3E); // Red
      case 'on_the_way':
        return const Color(0xFF3182CE); // Blue
      case 'inactive':
        return const Color(0xFF718096); // Gray
      case 'rescued':
        return const Color(0xFF38A169); // Green
      case 'resolved':
        return const Color(0xFF38A169); // Green (for backward compatibility)
      default:
        return const Color(0xFFE53E3E); // Red
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.warning;
      case 'on_the_way':
        return Icons.directions_boat;
      case 'inactive':
        return Icons.pause_circle;
      case 'rescued':
        return Icons.check_circle;
      case 'resolved':
        return Icons.check_circle; // for backward compatibility
      default:
        return Icons.warning;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'active':
        return 'Emergency Alert!';
      case 'on_the_way':
        return 'Rescue Team En Route';
      case 'inactive':
        return 'Alert Inactive';
      case 'rescued':
        return 'Rescue Completed';
      case 'resolved':
        return 'Alert Resolved'; // for backward compatibility
      default:
        return 'Emergency Alert!';
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'active':
        return 'Fisherman in distress. Immediate rescue needed at sea.\nPlease respond urgently.';
      case 'on_the_way':
        return 'Rescue team is on the way to the location.\nMonitor the situation.';
      case 'inactive':
        return 'This SOS alert has been marked as inactive.\nProcessing rescue status.';
      case 'rescued':
        return 'Rescue operation completed successfully.\nFisherman has been rescued.';
      case 'resolved':
        return 'This SOS alert has been resolved.\nFisherman is safe.'; // for backward compatibility
      default:
        return 'Fisherman in distress. Immediate rescue needed at sea.\nPlease respond urgently.';
    }
  }
}

// Resolve Dialog with statistics input
class _ResolveDialog extends StatefulWidget {
  final String fishermanName;
  
  const _ResolveDialog({required this.fishermanName});
  
  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final TextEditingController _casualtiesController = TextEditingController(text: '0');
  final TextEditingController _injuredController = TextEditingController(text: '0');
  
  @override
  void dispose() {
    _casualtiesController.dispose();
    _injuredController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as Resolved'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to mark this SOS alert from ${widget.fishermanName} as resolved?'),
            const SizedBox(height: 16),
            const Text('Rescue Statistics:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _casualtiesController,
              decoration: const InputDecoration(
                labelText: 'Casualties/Dead',
                hintText: 'Enter number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _injuredController,
              decoration: const InputDecoration(
                labelText: 'Injured',
                hintText: 'Enter number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {'confirmed': false}),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'confirmed': true,
              'casualties': int.tryParse(_casualtiesController.text) ?? 0,
              'injured': int.tryParse(_injuredController.text) ?? 0,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Resolve'),
        ),
      ],
    );
  }
}

// Rescue Statistics Dialog
class _RescueStatisticsDialog extends StatelessWidget {
  final int totalRescue;
  final int casualties;
  final int injured;
  
  const _RescueStatisticsDialog({
    required this.totalRescue,
    required this.casualties,
    required this.injured,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 8),
          Text('Rescue Completed'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rescue Statistics Summary:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Rescue', totalRescue.toString(), Colors.green),
          const SizedBox(height: 12),
          _buildStatRow('Casualties/Dead', casualties.toString(), Colors.red),
          const SizedBox(height: 12),
          _buildStatRow('Injured', injured.toString(), Colors.orange),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
  
  Widget _buildStatRow(String label, String value, Color color) {
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
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}