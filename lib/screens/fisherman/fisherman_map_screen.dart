import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../widgets/admin/map_widget_simple.dart';
import '../../services/live_location_service.dart';
import 'fisherman_drawer.dart';

class FishermanMapScreen extends StatefulWidget {
  const FishermanMapScreen({super.key});

  @override
  State<FishermanMapScreen> createState() => _FishermanMapScreenState();
}

class _FishermanMapScreenState extends State<FishermanMapScreen> {
  final LiveLocationService _liveLocationService = LiveLocationService();
  bool isOutsideBoundary = false; // 🟦 flag to detect if outside zone
  String currentLatitude = "11.7753°N";
  String currentLongitude = "124.8861°E";
  String currentAccuracy = "±5m";

  @override
  void initState() {
    super.initState();
    // Start live location tracking when screen opens
    _startLiveTracking();
  }

  @override
  void dispose() {
    // Stop live location tracking when screen closes
    _liveLocationService.stopTracking();
    super.dispose();
  }

  Future<void> _startLiveTracking() async {
    try {
      await _liveLocationService.startTracking();
      if (mounted) {
        setState(() {
          // Update UI if needed
        });
      }
    } catch (e) {
      print('Error starting live location tracking: $e');
      // Don't show error to user - tracking will work silently in background
    }
  }

  void _onMapClick() {
    // Show options when fisherman clicks on map
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Map Actions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'What would you like to do?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sendSOSAlert();
            },
            icon: const Icon(Icons.emergency, color: Colors.white),
            label: const Text('Send SOS Alert', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _checkLocation();
            },
            icon: const Icon(Icons.location_on, color: Colors.white),
            label: const Text('Check Location', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _sendSOSAlert() {
    // Show SOS alert confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Send SOS Alert'),
          ],
        ),
        content: const Text(
          'Are you sure you want to send an SOS alert? This will notify rescue teams of your emergency.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmSOSAlert();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmSOSAlert() {
    // Here you would implement the actual SOS alert sending logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.emergency, color: Colors.white),
            SizedBox(width: 8),
            Text('SOS Alert sent! Rescue teams have been notified.'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _checkLocation() {
    // Show current location information
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppColors.primaryColor),
            SizedBox(width: 8),
            Text('Your Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Position:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Latitude: $currentLatitude'),
            Text('Longitude: $currentLongitude'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOutsideBoundary ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isOutsideBoundary ? Icons.warning : Icons.check_circle,
                    color: isOutsideBoundary ? Colors.red : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOutsideBoundary 
                      ? 'Outside safe fishing zone'
                      : 'Within safe fishing zone',
                    style: TextStyle(
                      color: isOutsideBoundary ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map & Location',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.whiteColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const FishermanDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.homeBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Location & Fishing Area',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Monitor your position and fishing boundaries',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 12),

                // 🧭 Display map + boundary polygon + fisherman marker
                SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      // 🔹 Pass property to MapWidgetSimple to show admin boundaries and admin locations
                      child: GestureDetector(
                        onTap: _onMapClick,
                        child: MapWidgetSimple(
                          showBoundaries: true,
                          showSOSAlerts: false, // Hide SOS alerts for fishermen
                          showAdminLocations: true, // Show admin/coastguard locations with green markers
                          onBoundaryCheck: (outside) {
                            if (mounted) {
                              setState(() => isOutsideBoundary = outside);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 📍 GPS Location Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                            child: const Icon(
                              Icons.gps_fixed,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Your GPS Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGPSInfo('Latitude', currentLatitude),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGPSInfo('Longitude', currentLongitude),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Accuracy: $currentAccuracy',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 🚨 Status Indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isOutsideBoundary ? Colors.red.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isOutsideBoundary ? Icons.warning_amber_rounded : Icons.check_circle,
                        color: isOutsideBoundary ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOutsideBoundary
                            ? "You are outside the safe fishing zone!"
                            : "You are within the safe fishing zone.",
                        style: TextStyle(
                          color: isOutsideBoundary ? Colors.red : Colors.blue[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGPSInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
