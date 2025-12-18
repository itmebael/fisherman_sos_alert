import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../constants/colors.dart';
import '../../widgets/admin/map_widget_simple.dart';
import '../../widgets/admin/interactive_boundary_map.dart';
import '../../services/boundary_service.dart';
import '../../services/live_location_service.dart';
import 'admin_drawer.dart';

class AdminMapScreen extends StatefulWidget {
  final String? alertId; // Optional alert ID to highlight
  final double? initialLatitude; // Optional initial latitude
  final double? initialLongitude; // Optional initial longitude
  
  const AdminMapScreen({
    super.key,
    this.alertId,
    this.initialLatitude,
    this.initialLongitude,
  });
  
  // Factory constructor to create from route arguments
  factory AdminMapScreen.fromRouteArguments(Map<String, dynamic>? arguments) {
    if (arguments == null) {
      return const AdminMapScreen();
    }
    return AdminMapScreen(
      alertId: arguments['alertId']?.toString(),
      initialLatitude: (arguments['latitude'] as num?)?.toDouble(),
      initialLongitude: (arguments['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final LiveLocationService _liveLocationService = LiveLocationService();
  latlong.LatLng? _searchedLocation;
  
  @override
  void initState() {
    super.initState();
    // If initial coordinates are provided, set them as searched location
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _searchedLocation = latlong.LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    // Ensure boundaries table exists before using admin features
    BoundaryService.createBoundariesTable();
    // Start live location tracking for admin view (if admin is a fisherman)
    // Note: Admin tracking is optional - they may not need to share location
    // _startLiveTracking();
  }

  @override
  void dispose() {
    // Stop live location tracking if it was started
    _liveLocationService.stopTracking();
    super.dispose();
  }

  Future<void> _startLiveTracking() async {
    try {
      await _liveLocationService.startTracking();
    } catch (e) {
      print('Error starting live location tracking: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maritime Map',
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
                  'Maritime Monitoring System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Monitor fishermen locations and rescue operations',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ Add Three Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showInteractiveBoundaryDialog(context),
                        icon: const Icon(Icons.touch_app, color: Colors.white),
                        label: const Text("Click Map", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showBoundaryDialog(context),
                        icon: const Icon(Icons.border_all, color: Colors.white),
                        label: const Text("Manual Entry", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showManualLatLngDialog(context),
                        icon: const Icon(Icons.location_searching, color: Colors.white),
                        label: const Text("Search", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Map Legend
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // SOS Alert Marker Legend
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SOS Alert',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      // Search Marker Legend
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1.5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Search',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
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
                      child: MapWidgetSimple(
                        searchedLocation: _searchedLocation ?? (widget.initialLatitude != null && widget.initialLongitude != null 
                          ? latlong.LatLng(widget.initialLatitude!, widget.initialLongitude!)
                          : null),
                      ),
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

  // 🟦 Interactive Boundary Creation Dialog
  void _showInteractiveBoundaryDialog(BuildContext context) {
    List<latlong.LatLng> selectedPoints = [];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Create Boundary by Clicking Map", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const Text(
                  "Click on the map to select 4 boundary points (Top Left, Top Right, Bottom Right, Bottom Left)",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: InteractiveBoundaryMap(
                    initialPoints: selectedPoints.isNotEmpty ? selectedPoints : null,
                    onBoundaryPointsSelected: (points) {
                      setState(() {
                        selectedPoints = points;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedPoints.isEmpty 
                    ? "Click on the map to select 4 boundary points"
                    : "Selected ${selectedPoints.length}/4 points",
                  style: TextStyle(
                    color: selectedPoints.length == 4 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancel")
            ),
            ElevatedButton(
              onPressed: selectedPoints.length == 4
                ? () async {
                    // Save to database
                    final success = await BoundaryService.saveBoundary(
                      tlLat: selectedPoints[0].latitude,
                      tlLng: selectedPoints[0].longitude,
                      trLat: selectedPoints[1].latitude,
                      trLng: selectedPoints[1].longitude,
                      brLat: selectedPoints[2].latitude,
                      brLng: selectedPoints[2].longitude,
                      blLat: selectedPoints[3].latitude,
                      blLng: selectedPoints[3].longitude,
                    );

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Boundary saved successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      final message = BoundaryService.lastErrorMessage ?? 'Failed to save boundary';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedPoints.length == 4
                  ? AppColors.primaryColor
                  : Colors.grey,
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // 🟦 Dialog for Adding Boundaries
  void _showBoundaryDialog(BuildContext context) {
    final tlLatController = TextEditingController();
    final tlLngController = TextEditingController();
    final trLatController = TextEditingController();
    final trLngController = TextEditingController();
    final brLatController = TextEditingController();
    final brLngController = TextEditingController();
    final blLatController = TextEditingController();
    final blLngController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Add Boundary Coordinates", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text("Enter TL, TR, BR, BL latitude and longitude coordinates"),
              const SizedBox(height: 12),
              _buildCoordinateField("Top Left (TL)", tlLatController, tlLngController),
              _buildCoordinateField("Top Right (TR)", trLatController, trLngController),
              _buildCoordinateField("Bottom Right (BR)", brLatController, brLngController),
              _buildCoordinateField("Bottom Left (BL)", blLatController, blLngController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // Validate coordinates
              final tlLat = double.tryParse(tlLatController.text);
              final tlLng = double.tryParse(tlLngController.text);
              final trLat = double.tryParse(trLatController.text);
              final trLng = double.tryParse(trLngController.text);
              final brLat = double.tryParse(brLatController.text);
              final brLng = double.tryParse(brLngController.text);
              final blLat = double.tryParse(blLatController.text);
              final blLng = double.tryParse(blLngController.text);

              if (tlLat == null || tlLng == null || trLat == null || trLng == null ||
                  brLat == null || brLng == null || blLat == null || blLng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter valid coordinates")),
                );
                return;
              }

              // Save to database
              final success = await BoundaryService.saveBoundary(
                tlLat: tlLat,
                tlLng: tlLng,
                trLat: trLat,
                trLng: trLng,
                brLat: brLat,
                brLng: brLng,
                blLat: blLat,
                blLng: blLng,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Boundary saved successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else {
                final message = BoundaryService.lastErrorMessage ?? 'Failed to save boundary';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🟦 Dialog for Manual Coordinate Search
  void _showManualLatLngDialog(BuildContext context) {
    final latController = TextEditingController();
    final lngController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Search Coordinates", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter latitude and longitude to search"),
            const SizedBox(height: 12),
            _buildCoordinateField("Coordinates", latController, lngController),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              
              if (lat == null || lng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter valid coordinates")),
                );
                return;
              }

              // Check if coordinates are within valid range
              if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid coordinate range")),
                );
                return;
              }

              // Check if point is inside any boundary
              final isInsideBoundary = await BoundaryService.isPointInsideBoundary(lat, lng);
              
              Navigator.pop(context);
              
              // Update searched location to show orange marker on map
              // This will trigger the map widget to update via didUpdateWidget
              setState(() {
                _searchedLocation = latlong.LatLng(lat, lng);
              });
              
              // Show result
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Coordinates: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}\n'
                      'Status: ${isInsideBoundary ? "Inside safe fishing zone" : "Outside safe fishing zone"}',
                    ),
                    backgroundColor: isInsideBoundary ? Colors.green : Colors.orange,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Clear',
                      textColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _searchedLocation = null;
                        });
                      },
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text("Search", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateField(String label, TextEditingController lat, TextEditingController lng) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: lat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Latitude", border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: lng,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Longitude", border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
