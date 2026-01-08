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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isMobile = screenWidth < 600;
              final padding = isMobile ? 12.0 : 16.0;
              
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Location & Fishing Area',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Text(
                      'Monitor your position and fishing boundaries',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: isMobile ? 10 : 12),

                    // 🧭 Display map + boundary polygon + fisherman marker
                    SizedBox(
                      height: isMobile ? 250 : 300,
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
                          child: MapWidgetSimple(
                            showBoundaries: true,
                            showSOSAlerts: false, // Hide SOS alerts as requested
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

                    SizedBox(height: isMobile ? 8 : 10),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
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
                      child: Row(
                        children: [
                          _buildLegendItem(
                            isMobile,
                            Colors.green,
                            Icons.local_police,
                            'Rescue Team (Admin)',
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          _buildLegendItem(
                            isMobile,
                            AppColors.primaryColor,
                            Icons.my_location,
                            'Your Location',
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 10 : 12),

                    // 📍 GPS Location Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                                padding: EdgeInsets.all(isMobile ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.gps_fixed,
                                  color: AppColors.primaryColor,
                                  size: isMobile ? 18 : 20,
                                ),
                              ),
                              SizedBox(width: isMobile ? 10 : 12),
                              Flexible(
                                child: Text(
                                  'Your GPS Location',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 10 : 12),
                          isMobile
                              ? Column(
                                  children: [
                                    _buildGPSInfo('Latitude', currentLatitude),
                                    const SizedBox(height: 8),
                                    _buildGPSInfo('Longitude', currentLongitude),
                                  ],
                                )
                              : Row(
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
                          SizedBox(height: isMobile ? 6 : 8),
                          Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                size: isMobile ? 14 : 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Accuracy: $currentAccuracy',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? 10 : 12),

                    // 🚨 Status Indicator
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12,
                        horizontal: isMobile ? 8 : 12,
                      ),
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
                            size: isMobile ? 18 : 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isOutsideBoundary
                                  ? "You are outside the safe fishing zone!"
                                  : "You are within the safe fishing zone.",
                              style: TextStyle(
                                color: isOutsideBoundary ? Colors.red : Colors.blue[900],
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 13 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
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

  Widget _buildGPSInfo(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
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
              fontSize: isMobile ? 11 : 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isMobile ? 3 : 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    bool isMobile,
    Color color,
    IconData icon,
    String label,
  ) {
    return Row(
      children: [
        Container(
          width: isMobile ? 20 : 22,
          height: isMobile ? 20 : 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: isMobile ? 14 : 16),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
