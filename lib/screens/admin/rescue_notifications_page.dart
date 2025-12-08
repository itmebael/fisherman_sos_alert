import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/colors.dart';
import '../../services/database_service.dart';
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
              "Salbar_Mangirisda",
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
                                              final fishermanName = (a['fisherman_name'] ?? 
                                                                   a['fisherman_first_name'] ?? 
                                                                   a['fisherman_email'] ?? 
                                                                   'Unknown').toString();
                                              final boatNumber = a['fisherman_boat_number']?.toString() ?? 
                                                               a['boat_number']?.toString() ?? 
                                                               '-';
                                              final timestamp = a['created_at']?.toString() ?? 
                                                              a['alertTime']?.toString() ?? 
                                                              '';
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
          
          // Fisherman info and timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'From: $fishermanName    Boat NO: $boatNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
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
    // Navigate to map view or show location details
    final fishermanPhone = alert['fisherman_phone']?.toString() ?? 
                          alert['phone']?.toString();
    final hasPhone = fishermanPhone != null && fishermanPhone.isNotEmpty;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Alert Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fisherman: ${alert['fisherman_name'] ?? alert['fisherman_first_name'] ?? alert['fisherman_email'] ?? 'Unknown'}'),
            if (hasPhone) ...[
              const SizedBox(height: 8),
              Text('Phone: $fishermanPhone'),
            ],
            const SizedBox(height: 8),
            Text('Latitude: ${alert['latitude']}'),
            Text('Longitude: ${alert['longitude']}'),
            Text('Time: ${alert['created_at']}'),
            Text('Status: ${alert['status']}'),
          ],
        ),
        actions: [
          if (hasPhone)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _makePhoneCall(fishermanPhone);
              },
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Call Fisherman'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: Text('Are you sure you want to mark this SOS alert from ${alert['fisherman_name'] ?? alert['fisherman_first_name'] ?? alert['fisherman_email'] ?? 'fisherman'} as resolved?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
        final success = await _databaseService.updateSOSAlertStatus(alertId, 'resolved');
        
        if (success) {
          // Reload alerts to get updated data
          await _loadAlerts();
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('SOS alert from ${alert['fisherman_name'] ?? alert['fisherman_first_name'] ?? alert['fisherman_email'] ?? 'fisherman'} marked as resolved!'),
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
  }

  // Helper methods for status display
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFFE53E3E); // Red
      case 'on_the_way':
        return const Color(0xFF3182CE); // Blue
      case 'resolved':
        return const Color(0xFF38A169); // Green
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
      case 'resolved':
        return Icons.check_circle;
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
      case 'resolved':
        return 'Alert Resolved';
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
      case 'resolved':
        return 'This SOS alert has been resolved.\nFisherman is safe.';
      default:
        return 'Fisherman in distress. Immediate rescue needed at sea.\nPlease respond urgently.';
    }
  }
}