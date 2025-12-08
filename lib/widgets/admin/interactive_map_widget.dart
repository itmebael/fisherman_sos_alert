import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/colors.dart';
import '../../services/database_service.dart';

class InteractiveMapWidget extends StatefulWidget {
  const InteractiveMapWidget({super.key});

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  final MapController _mapController = MapController();
  final Set<String> _knownAlertIds = <String>{};
  bool _isMapLoaded = false;
  bool _hasConnectionError = false;
  final bool _useAltTiles = true; // default to OSM tiles to avoid ArcGIS DNS issues

  // Fishing boundary coordinates (rectangle)
  final List<LatLng> _fishingBoundary = [
    const LatLng(11.762287028459264, 124.8828659554447),
    const LatLng(11.757767131958472, 124.86957178574627),
    const LatLng(11.750687626848679, 124.89209956285033),
    const LatLng(11.74453375520325, 124.8823097142688),
  ];

  @override
  void initState() {
    super.initState();
    // Try to load map after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isMapLoaded = true;
        });
      }
    });
  }

  // Check if a point is inside the fishing boundary
  bool _isPointInsideBoundary(LatLng point) {
    // Using ray casting algorithm to check if point is inside polygon
    int intersections = 0;
    for (int i = 0; i < _fishingBoundary.length; i++) {
      LatLng p1 = _fishingBoundary[i];
      LatLng p2 = _fishingBoundary[(i + 1) % _fishingBoundary.length];
      
      if (point.latitude > p1.latitude != point.latitude > p2.latitude) {
        if (point.longitude < (p2.longitude - p1.longitude) * (point.latitude - p1.latitude) / (p2.latitude - p1.latitude) + p1.longitude) {
          intersections++;
        }
      }
    }
    return intersections % 2 == 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Map or Fallback
            if (_isMapLoaded)
              _buildMap()
            else
              _buildFallbackMap(),
            
            // Map title overlay
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Maritime Waters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Legend overlay
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legend',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Inside',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Outside',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Status indicator
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasConnectionError ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _hasConnectionError ? 'Offline' : 'Active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Retry button if connection error
            if (_hasConnectionError)
              Positioned(
                bottom: 8,
                left: 8,
                child: ElevatedButton.icon(
                  onPressed: _retryMapLoad,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getFishermenStream(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> fishermen = List<Map<String, dynamic>>.from(snapshot.data ?? []);

        // Always add demo fishermen for testing boundary compliance
        // Some inside boundary (blue), some outside boundary (red)
        final demoFishermen = [
          {
            'id': 'demo_fisherman_1',
            'email': 'cain22@gmail.com',
            'first_name': 'Cain',
            'last_name': 'Fisherman',
            'name': 'Cain Fisherman',
            'phone': '+639123456789',
            'user_type': 'fisherman',
            'is_active': true,
            'current_latitude': 11.755, // Inside boundary (blue)
            'current_longitude': 124.88,
            'last_active': DateTime.now().toIso8601String(),
          },
          {
            'id': 'demo_fisherman_2',
            'email': 'john@gmail.com',
            'first_name': 'John',
            'last_name': 'Boatman',
            'name': 'John Boatman',
            'phone': '+639123456790',
            'user_type': 'fisherman',
            'is_active': true,
            'current_latitude': 11.76, // Inside boundary (blue)
            'current_longitude': 124.885,
            'last_active': DateTime.now().toIso8601String(),
          },
          {
            'id': 'demo_fisherman_3',
            'email': 'mike@gmail.com',
            'first_name': 'Mike',
            'last_name': 'Sailor',
            'name': 'Mike Sailor',
            'phone': '+639123456791',
            'user_type': 'fisherman',
            'is_active': true,
            'current_latitude': 11.78, // Outside boundary (red)
            'current_longitude': 125.01,
            'last_active': DateTime.now().toIso8601String(),
          },
          {
            'id': 'demo_fisherman_4',
            'email': 'alex@gmail.com',
            'first_name': 'Alex',
            'last_name': 'Mariner',
            'name': 'Alex Mariner',
            'phone': '+639123456792',
            'user_type': 'fisherman',
            'is_active': true,
            'current_latitude': 11.73, // Outside boundary (red)
            'current_longitude': 124.85,
            'last_active': DateTime.now().toIso8601String(),
          }
        ];
        
        // Add demo fishermen to the list
        fishermen.addAll(demoFishermen);
        
        // Debug: Print boundary status for each fisherman
        print('=== FISHERMEN BOUNDARY STATUS ===');
        for (var fisherman in fishermen) {
          final lat = fisherman['current_latitude'] as num?;
          final lng = fisherman['current_longitude'] as num?;
          if (lat != null && lng != null) {
            final point = LatLng(lat.toDouble(), lng.toDouble());
            final isInside = _isPointInsideBoundary(point);
            final status = isInside ? 'INSIDE (Blue)' : 'OUTSIDE (Red)';
            print('${fisherman['name']}: ${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)} - $status');
          }
        }
        print('=== END BOUNDARY STATUS ===');

        // Update known fishermen IDs for tracking
        if (fishermen.isNotEmpty) {
          final currentIds = fishermen.map((f) => f['id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
          final newIds = currentIds.difference(_knownAlertIds);
          if (newIds.isNotEmpty) {
            // Show notification for new fishermen
            final latest = fishermen.firstWhere((f) => newIds.contains(f['id'].toString()), orElse: () => fishermen.first);
            final lat = (latest['current_latitude'] as num).toDouble();
            final lng = (latest['current_longitude'] as num).toDouble();
            final name = latest['name']?.toString() ?? latest['first_name']?.toString() ?? 'Fisherman';

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(LatLng(lat, lng), 14.0);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.blue,
                    content: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Fisherman $name is now active (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})')),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            });
            _knownAlertIds.addAll(newIds);
          }
        }

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            // Always center on Catbalogan, Samar
            initialCenter: const LatLng(11.7753, 124.8861),
            initialZoom: 12.0,
            minZoom: 8.0,
            maxZoom: 18.0,
            onMapReady: () {
              // Force center near requested reference marker to ensure visibility
              _mapController.move(const LatLng(11.770772390325703, 124.88783864232731), 14.0);
            },
            onTap: (tapPosition, point) {
              // Handle map tap
            },
          ),
          children: [
            // Try multiple tile providers for better reliability
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.fisherman_sos_alert',
              maxZoom: 19,
              // Keep simple; avoid subdomain warnings and DNS failures
            ),
            // Fishing boundary polygon - Make it very visible
            PolygonLayer(
              polygons: [
                Polygon(
                  points: _fishingBoundary,
                  color: Colors.blue.withOpacity(0.1), // Very light fill
                  borderColor: Colors.red, // Red border to make it stand out
                  borderStrokeWidth: 4.0, // Very thick border
                  isFilled: true,
                ),
              ],
            ),
            MarkerLayer(
              markers: _buildFishermenMarkers(fishermen),
            ),
            // Add boundary corner markers for visibility
            MarkerLayer(
              markers: _fishingBoundary.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                return Marker(
                  point: point,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFallbackMap() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade100,
            Colors.green.shade100,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Samar Waters Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasConnectionError 
                  ? 'Connection Error - Tap Retry'
                  : 'Emergency Response System',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _hasConnectionError ? Colors.red.shade600 : Colors.blue.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _hasConnectionError ? 'Connection Failed' : 'Map Loading...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildFishermenMarkers(List<Map<String, dynamic>> fishermen) {
    return fishermen.map((fisherman) {
      final lat = fisherman['current_latitude'] as num?;
      final lng = fisherman['current_longitude'] as num?;
      
      // Skip fishermen without location data
      if (lat == null || lng == null) return null;
      
      final point = LatLng(lat.toDouble(), lng.toDouble());
      final isInsideBoundary = _isPointInsideBoundary(point);
      final markerColor = isInsideBoundary ? Colors.blue : Colors.red;
      
      return Marker(
        point: point,
        width: 50, // Larger markers
        height: 50,
        child: GestureDetector(
          onTap: () => _showFishermanDetails(fisherman),
          child: Container(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3), // Thicker white border
              boxShadow: [
                BoxShadow(
                  color: markerColor.withOpacity(0.4), // More visible shadow
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              isInsideBoundary ? Icons.person : Icons.warning,
              color: Colors.white,
              size: 24, // Larger icon
            ),
          ),
        ),
      );
    }).where((marker) => marker != null).cast<Marker>().toList();
  }

  void _showFishermanDetails(Map<String, dynamic> fisherman) {
    final lat = fisherman['current_latitude'] as num?;
    final lng = fisherman['current_longitude'] as num?;
    final point = lat != null && lng != null ? LatLng(lat.toDouble(), lng.toDouble()) : null;
    final isInsideBoundary = point != null ? _isPointInsideBoundary(point) : false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fisherman Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${fisherman['name'] ?? 'Unknown'}'),
            Text('Email: ${fisherman['email'] ?? 'Unknown'}'),
            Text('Phone: ${fisherman['phone'] ?? 'Unknown'}'),
            if (lat != null && lng != null) ...[
              Text('Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isInsideBoundary ? Colors.blue.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isInsideBoundary ? Colors.blue : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isInsideBoundary ? Icons.check_circle : Icons.warning,
                      color: isInsideBoundary ? Colors.blue : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isInsideBoundary ? 'Inside fishing boundary' : 'Outside fishing boundary',
                      style: TextStyle(
                        color: isInsideBoundary ? Colors.blue : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text('Last Active: ${_formatDateTime(fisherman['last_active'])}'),
          ],
        ),
        actions: [
          if (fisherman['phone'] != null && fisherman['phone'].toString().isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _makePhoneCall(fisherman['phone'].toString()),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Unknown';
    try {
      final dt = DateTime.parse(dateTime.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _retryMapLoad() {
    setState(() {
      _hasConnectionError = false;
      _isMapLoaded = false;
    });
    
    // Retry loading after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isMapLoaded = true;
        });
      }
    });
  }
}

