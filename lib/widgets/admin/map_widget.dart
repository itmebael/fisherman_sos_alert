import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MapWidget extends StatefulWidget {
  const MapWidget({Key? key}) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  MapController? _mapController;
  List<Marker> _markers = [];
  // Catbalogan City, Samar coordinates (more precise)
  LatLng _currentPosition = const LatLng(11.7745, 124.8958);
  LatLng _catbaloganCenter = const LatLng(11.7745, 124.8958);
  StreamSubscription<QuerySnapshot>? _sosAlertsSubscription;
  List<Map<String, dynamic>> _webSOSAlerts = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
    if (kIsWeb) {
      _listenToSOSAlertsWeb();
    } else {
      _getCurrentLocation();
      _listenToSOSAlerts();
    }
  }

  @override
  void dispose() {
    _sosAlertsSubscription?.cancel();
    super.dispose();
  }

  // Initialize map with default markers
  void _initializeMap() {
    // Add default marker for Catbalogan City Coast Guard Station
    _markers.add(
      Marker(
        point: _catbaloganCenter,
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showLocationInfo('Coast Guard Station Catbalogan', 'Catbalogan City, Samar'),
          child: _createMarkerWidget(
            color: Colors.blue,
            icon: Icons.security,
          ),
        ),
      ),
    );
  }

  // Web version - listen to SOS alerts
  void _listenToSOSAlertsWeb() {
    _sosAlertsSubscription = FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _webSOSAlerts = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    });
  }

  // Get user's current location (Mobile only)
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        // Only move map if we're not already centered on Catbalogan
        if (_mapController != null) {
          _mapController!.move(_currentPosition, 14.0);
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Keep default Catbalogan location if GPS fails
    }
  }

  // Listen to real-time SOS alerts from Firestore (Mobile)
  void _listenToSOSAlerts() {
    _sosAlertsSubscription = FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      _updateSOSMarkers(snapshot.docs);
    });
  }

  // Create marker widget with improved styling
  Widget _createMarkerWidget({
    required Color color,
    required IconData icon,
    Color iconColor = Colors.white,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 28,
      ),
    );
  }

  // Update SOS markers on map (Mobile)
  void _updateSOSMarkers(List<QueryDocumentSnapshot> sosAlerts) {
    List<Marker> newMarkers = [];

    // Always add Catbalogan Coast Guard Station marker
    newMarkers.add(
      Marker(
        point: _catbaloganCenter,
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showLocationInfo('Coast Guard Station Catbalogan', 'Catbalogan City, Samar'),
          child: _createMarkerWidget(
            color: Colors.blue,
            icon: Icons.security,
          ),
        ),
      ),
    );

    // Add current location marker if different from Catbalogan
    if (_currentPosition != _catbaloganCenter) {
      newMarkers.add(
        Marker(
          point: _currentPosition,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showLocationInfo('Current Location', 'Your current position'),
            child: _createMarkerWidget(
              color: Colors.green,
              icon: Icons.my_location,
            ),
          ),
        ),
      );
    }

    // Add SOS alert markers
    for (var alert in sosAlerts) {
      final data = alert.data() as Map<String, dynamic>;
      final geoPoint = data['location'] as GeoPoint?;
      
      if (geoPoint != null) {
        newMarkers.add(
          Marker(
            point: LatLng(geoPoint.latitude, geoPoint.longitude),
            width: 45,
            height: 45,
            child: GestureDetector(
              onTap: () => _showSOSDetails(alert.id, data),
              child: _createMarkerWidget(
                color: Colors.red,
                icon: Icons.warning,
              ),
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _showLocationInfo(String title, String subtitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSOSDetails(String alertId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('SOS ALERT'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fisherman: ${data['fishermanName'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Phone: ${data['phoneNumber'] ?? 'Not provided'}'),
            const SizedBox(height: 8),
            Text('Message: ${data['message'] ?? 'Emergency assistance needed'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiateRescue(alertId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Initiate Rescue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _initiateRescue(String alertId) {
    FirebaseFirestore.instance
        .collection('sos_alerts')
        .doc(alertId)
        .update({'status': 'in_progress'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rescue operation initiated!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Reset map to Catbalogan City
  void _resetToCatbalogan() {
    if (_mapController != null) {
      _mapController!.move(_catbaloganCenter, 14.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Both Web and Mobile versions now show the map
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _catbaloganCenter, // Always start at Catbalogan
            initialZoom: 14.0,
            minZoom: 3.0,
            maxZoom: 19.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // Map tiles from OpenStreetMap with improved performance
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fisherman_sos_alert.app',
              maxZoom: 19,
              // Improved tile loading performance for web
              tileProvider: kIsWeb 
                ? CancellableNetworkTileProvider()
                : NetworkTileProvider(),
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint('Tile loading error: $error');
              },
            ),
            // Markers layer
            MarkerLayer(markers: _markers),
            // Attribution (required for OpenStreetMap)
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () {
                    // Optional: open OSM website
                  },
                ),
              ],
            ),
          ],
        ),
        
        // SOS Alerts overlay for web (only show if there are alerts)
        if (kIsWeb && _webSOSAlerts.isNotEmpty)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Active SOS Alerts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _webSOSAlerts.length,
                      itemBuilder: (context, index) {
                        final alert = _webSOSAlerts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${alert['fishermanName'] ?? 'Unknown'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${alert['phoneNumber'] ?? 'No phone'}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                ElevatedButton(
                                  onPressed: () => _initiateRescue(alert['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: const Size(80, 25),
                                  ),
                                  child: const Text(
                                    'Rescue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Status indicator for no alerts
        if (_webSOSAlerts.isEmpty)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'No Active Alerts - All Safe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Catbalogan City button (reset to center)
        Positioned(
          top: 20,
          right: 20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.blue,
            heroTag: "catbalogan_center",
            onPressed: _resetToCatbalogan,
            child: const Icon(Icons.location_city, color: Colors.white),
          ),
        ),
        
        // My location button (only show on mobile)
        if (!kIsWeb)
          Positioned(
            top: 80,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              heroTag: "my_location",
              onPressed: () {
                _getCurrentLocation();
                if (_mapController != null && _currentPosition != _catbaloganCenter) {
                  _mapController!.move(_currentPosition, 15.0);
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        
        // Map zoom controls
        Positioned(
          top: kIsWeb ? 80 : 140,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                heroTag: "zoom_in",
                onPressed: () {
                  if (_mapController != null) {
                    double currentZoom = _mapController!.camera.zoom;
                    _mapController!.move(_mapController!.camera.center, currentZoom + 1);
                  }
                },
                child: const Icon(Icons.add, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                heroTag: "zoom_out",
                onPressed: () {
                  if (_mapController != null) {
                    double currentZoom = _mapController!.camera.zoom;
                    _mapController!.move(_mapController!.camera.center, currentZoom - 1);
                  }
                },
                child: const Icon(Icons.remove, color: Colors.blue),
              ),
            ],
          ),
        ),
        
        // Location info overlay
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Monitoring Area',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Catbalogan City, Samar',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );

  }
  }
