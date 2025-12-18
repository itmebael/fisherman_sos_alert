import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/boundary_service.dart';
import '../../services/location_service.dart';
import '../../providers/admin_provider_simple.dart';
import 'dart:async';

class MapWidgetSimple extends StatefulWidget {
  final bool showBoundaries;
  final bool showSOSAlerts;
  final bool showAdminLocations; // Show admin/coastguard locations with green markers
  final Function(bool)? onBoundaryCheck;
  final latlong.LatLng? searchedLocation;
  
  const MapWidgetSimple({
    super.key,
    this.showBoundaries = false,
    this.showSOSAlerts = true,
    this.showAdminLocations = false,
    this.onBoundaryCheck,
    this.searchedLocation,
  });

  @override
  State<MapWidgetSimple> createState() => _MapWidgetSimpleState();
}

class _MapWidgetSimpleState extends State<MapWidgetSimple> {
  final MapController _mapController = MapController();
  final Set<String> _knownAlertIds = <String>{};
  final Set<String> _outsideBoundaryFishermen = <String>{};
  latlong.LatLng? _currentUserLatLng;
  StreamSubscription? _locationSubscription;
  latlong.LatLng? _searchedLocation;
  bool _hasCenteredToUser = false;
  bool _isMapReady = false;
  latlong.LatLng? _pendingCenterLocation;
  List<Map<String, dynamic>> _adminLocations = [];
  StreamSubscription? _adminLocationsSubscription;
  List<Map<String, dynamic>> _liveFishermenLocations = [];
  StreamSubscription? _liveLocationsSubscription;

  @override
  void initState() {
    super.initState();
    _searchedLocation = widget.searchedLocation;
    if (_searchedLocation != null) {
      _pendingCenterLocation = _searchedLocation;
    }
    _initLocation();
    // Initialize admin locations stream if needed
    if (widget.showAdminLocations) {
      _startAdminLocationsStream();
    }
    // Always start live locations stream for active fishermen (for fisherman map)
    _startLiveLocationsStream();
  }

  @override
  void didUpdateWidget(MapWidgetSimple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchedLocation != oldWidget.searchedLocation) {
      setState(() {
        _searchedLocation = widget.searchedLocation;
        if (_searchedLocation != null) {
          _pendingCenterLocation = _searchedLocation;
        }
      });
      // Center map to searched location when it changes (only if map is ready)
      if (_searchedLocation != null && _isMapReady) {
        _centerMapToLocation(_searchedLocation!);
      }
    }
    // Handle showAdminLocations changes
    if (widget.showAdminLocations != oldWidget.showAdminLocations) {
      if (widget.showAdminLocations) {
        _startAdminLocationsStream();
      } else {
        _adminLocationsSubscription?.cancel();
        setState(() {
          _adminLocations = [];
        });
      }
    }
  }

  void _centerMapToLocation(latlong.LatLng location) {
    // Validate coordinates
    if (location.latitude < -90 || location.latitude > 90 ||
        location.longitude < -180 || location.longitude > 180) {
      print('Invalid coordinates: ${location.latitude}, ${location.longitude}');
      return;
    }

    if (!_isMapReady) {
      print('Map not ready yet, storing location for later: ${location.latitude}, ${location.longitude}');
      _pendingCenterLocation = location;
      return;
    }

    print('Centering map to: ${location.latitude}, ${location.longitude}');
    
    // Wait a bit longer to ensure tiles are loaded, then move
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || !_isMapReady) {
        print('Map not mounted or not ready, skipping center');
        return;
      }
      
      try {
        // Move map to location with zoom level 14
        _mapController.move(location, 14.0);
        print('Successfully centered map to: ${location.latitude}, ${location.longitude}');
      } catch (e) {
        print('Error centering map: $e');
        // Retry after a longer delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && _isMapReady) {
            try {
              _mapController.move(location, 14.0);
              print('Successfully centered map (retry): ${location.latitude}, ${location.longitude}');
            } catch (e2) {
              print('Error centering map (retry): $e2');
            }
          }
        });
      }
    });
  }

  void _onMapReady() {
    if (mounted) {
      setState(() {
        _isMapReady = true;
      });
      // Center to pending location if any, otherwise use current searched location
      final locationToCenter = _pendingCenterLocation ?? _searchedLocation;
      if (locationToCenter != null) {
        // Delay slightly to ensure map is fully initialized
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _centerMapToLocation(locationToCenter);
          }
        });
      }
      _pendingCenterLocation = null;
    }
  }

  Future<void> _initLocation() async {
    // Get current location once
    final position = await LocationService().getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentUserLatLng = latlong.LatLng(position.latitude, position.longitude);
      });
      // Center map to user only once on first acquire
      if (!_hasCenteredToUser) {
        _mapController.move(_currentUserLatLng!, 14.0);
        _hasCenteredToUser = true;
      }
    }

    // Listen to location updates with error handling
    // Cancel any existing subscription first
    _locationSubscription?.cancel();
    
    _locationSubscription = LocationService().getLocationStream().listen(
      (pos) {
        if (!mounted) return;
        // Use WidgetsBinding to ensure we're on the correct thread
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentUserLatLng = latlong.LatLng(pos.latitude, pos.longitude);
            });
          }
        });
      },
      onError: (error) {
        print('Location stream error: $error');
        // Don't crash - location updates are not critical
      },
      cancelOnError: false, // Continue listening even if errors occur
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _adminLocationsSubscription?.cancel();
    _liveLocationsSubscription?.cancel();
    super.dispose();
  }

  void _startAdminLocationsStream() {
    // Cancel existing subscription if any
    _adminLocationsSubscription?.cancel();
    
    // Start listening to admin/coastguard locations stream
    _adminLocationsSubscription = DatabaseService().getCoastguardsStream().listen(
      (admins) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _adminLocations = admins;
            });
          }
        });
      },
      onError: (error) {
        print('Admin locations stream error: $error');
      },
    );
  }

  void _startLiveLocationsStream() {
    // Cancel existing subscription if any
    _liveLocationsSubscription?.cancel();
    
    // Start listening to live fisherman locations stream
    _liveLocationsSubscription = DatabaseService().getLiveLocationsStream().listen(
      (locations) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // Filter to only active locations (updated within last 10 minutes)
              final now = DateTime.now();
              _liveFishermenLocations = locations.where((location) {
                if (location['is_active'] != true) return false;
                final updatedAt = location['updated_at'];
                if (updatedAt == null) return false;
                try {
                  final updateTime = DateTime.parse(updatedAt);
                  return now.difference(updateTime).inMinutes < 10;
                } catch (e) {
                  return false;
                }
              }).toList();
            });
          }
        });
      },
      onError: (error) {
        print('Live locations stream error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Only show SOS alerts if showSOSAlerts is true
      if (widget.showSOSAlerts) {
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getSOSAlertsStream(),
        builder: (context, snapshot) {
          final alerts = snapshot.data ?? [];

          // Detect new alerts and notify with red alert + recenter
          if (alerts.isNotEmpty) {
            final currentIds = alerts.map((a) => a['id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
            final newIds = currentIds.difference(_knownAlertIds);
            if (newIds.isNotEmpty) {
              final latest = alerts.firstWhere((a) => newIds.contains(a['id'].toString()), orElse: () => alerts.first);
              final lat = (latest['latitude'] as num).toDouble();
              final lng = (latest['longitude'] as num).toDouble();
              final name = latest['fishermen'] != null ? (latest['fishermen']['name']?.toString() ?? 'Unknown') : (latest['message']?.toString() ?? 'SOS Alert');

              // Only center if no searched location is active
              if (_searchedLocation == null && _isMapReady) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _centerMapToLocation(latlong.LatLng(lat, lng));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(child: Text('SOS received from $name (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})')),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                });
              } else {
                // Just show notification without centering if searched location is active
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(child: Text('SOS received from $name (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})')),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                });
              }
              _knownAlertIds.addAll(newIds);
            }
          }

          // Check for fishermen outside boundaries
          _checkFishermenOutsideBoundaries(alerts);
          
          // Check current user's boundary status if callback is provided
          if (widget.onBoundaryCheck != null) {
            _checkCurrentUserBoundaryStatus();
          }
        
        // If showBoundaries is true, show boundary stream, otherwise show simple map
        if (widget.showBoundaries) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: BoundaryService.getBoundariesStream(),
            builder: (context, boundarySnapshot) {
              final boundaries = boundarySnapshot.data ?? [];
              
              return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        // Always start with default center, then move if needed
                        initialCenter: const latlong.LatLng(11.7753, 124.8861),
                        initialZoom: 12.0,
                        minZoom: 8.0,
                        maxZoom: 18.0,
                        onMapReady: _onMapReady,
                        // Keep interaction enabled
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                          userAgentPackageName: 'com.example.fisherman_sos_alert',
                          maxZoom: 18,
                          errorTileCallback: (tile, error, stackTrace) {
                            print('Tile loading error at ${tile.coordinates}: $error');
                          },
                        ),
                        // Add boundary polygons only if showBoundaries is true
                        if (widget.showBoundaries && boundaries.isNotEmpty)
                          PolygonLayer(
                            polygons: _buildBoundaryPolygons(boundaries),
                          ),
                        MarkerLayer(
                          markers: _buildMarkers(alerts),
                        ),
                        // Live locations stream
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: DatabaseService().getLiveLocationsStream(),
                          builder: (context, liveLocationSnapshot) {
                            final liveLocations = liveLocationSnapshot.data ?? [];
                            return MarkerLayer(
                              markers: _buildLiveLocationMarkers(liveLocations),
                            );
                          },
                        ),
                        if (_currentUserLatLng != null)
                          MarkerLayer(
                            markers: _buildUserMarkers(),
                          ),
                        if (_searchedLocation != null)
                          MarkerLayer(
                            markers: _buildSearchedLocationMarker(),
                          ),
                      ],
                    ),
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
                          'Samar Waters Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        } else {
          // Simple map without boundaries
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      // Always start with default center, then move if needed
                      initialCenter: const latlong.LatLng(11.7753, 124.8861),
                      initialZoom: 12.0,
                      minZoom: 8.0,
                      maxZoom: 18.0,
                      onMapReady: _onMapReady,
                      // Keep interaction enabled
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.example.fisherman_sos_alert',
                        maxZoom: 18,
                        errorTileCallback: (tile, error, stackTrace) {
                          print('Tile loading error at ${tile.coordinates}: $error');
                        },
                      ),
                      MarkerLayer(
                        markers: _buildMarkers(alerts),
                      ),
                      // Live locations stream
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: DatabaseService().getLiveLocationsStream(),
                        builder: (context, liveLocationSnapshot) {
                          final liveLocations = liveLocationSnapshot.data ?? [];
                          return MarkerLayer(
                            markers: _buildLiveLocationMarkers(liveLocations),
                          );
                        },
                      ),
                      if (_currentUserLatLng != null)
                        MarkerLayer(
                          markers: _buildUserMarkers(),
                        ),
                      if (_searchedLocation != null)
                        MarkerLayer(
                          markers: _buildSearchedLocationMarker(),
                        ),
                      if (widget.showAdminLocations)
                        MarkerLayer(
                          markers: _buildAdminMarkers(),
                        ),
                      // Show active fishermen on admin map
                      if (widget.showSOSAlerts && _liveFishermenLocations.isNotEmpty)
                        MarkerLayer(
                          markers: _buildLiveLocationMarkers(_liveFishermenLocations),
                        ),
                    ],
                  ),
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
                        'Samar Waters Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
    } else {
      // Simple map without SOS alerts - for fisherman view
      return _buildSimpleMap();
    }
    } catch (e) {
      // Return a simple error widget if something goes wrong
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Map temporarily unavailable',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSimpleMap() {
    try {
      // Check current user's boundary status if callback is provided
      if (widget.onBoundaryCheck != null) {
        _checkCurrentUserBoundaryStatus();
      }
    
    // If showBoundaries is true, show boundary stream, otherwise show simple map
    if (widget.showBoundaries) {
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: BoundaryService.getBoundariesStream(),
        builder: (context, boundarySnapshot) {
          final boundaries = boundarySnapshot.data ?? [];
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const latlong.LatLng(11.7753, 124.8861),
                      initialZoom: 12.0,
                      minZoom: 8.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.example.fisherman_sos_alert',
                        maxZoom: 18,
                      ),
                      // Add boundary polygons only if showBoundaries is true
                      if (widget.showBoundaries && boundaries.isNotEmpty)
                        PolygonLayer(
                          polygons: _buildBoundaryPolygons(boundaries),
                        ),
                      if (_currentUserLatLng != null)
                        MarkerLayer(
                          markers: _buildUserMarkers(),
                        ),
                      // Show active fishermen on fisherman map
                      if (_liveFishermenLocations.isNotEmpty)
                        MarkerLayer(
                          markers: _buildLiveLocationMarkers(_liveFishermenLocations),
                        ),
                      // Show admin markers on fisherman map
                      if (widget.showAdminLocations)
                        MarkerLayer(
                          markers: _buildAdminMarkers(),
                        ),
                    ],
                  ),
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
                        'Samar Waters Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Simple map without boundaries
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
                children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  // Always start with default center, then move if needed
                  initialCenter: const latlong.LatLng(11.7753, 124.8861),
                  initialZoom: 12.0,
                  minZoom: 8.0,
                  maxZoom: 18.0,
                  onMapReady: _onMapReady,
                  // Keep interaction enabled
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.example.fisherman_sos_alert',
                    maxZoom: 18,
                    errorTileCallback: (tile, error, stackTrace) {
                      print('Tile loading error at ${tile.coordinates}: $error');
                    },
                  ),
                  if (_currentUserLatLng != null)
                    MarkerLayer(
                      markers: _buildUserMarkers(),
                    ),
                  if (_searchedLocation != null)
                    MarkerLayer(
                      markers: _buildSearchedLocationMarker(),
                    ),
                  if (widget.showAdminLocations)
                    MarkerLayer(
                      markers: _buildAdminMarkers(),
                    ),
                  // Show active fishermen on fisherman map
                  if (!widget.showSOSAlerts && _liveFishermenLocations.isNotEmpty)
                    MarkerLayer(
                      markers: _buildLiveLocationMarkers(_liveFishermenLocations),
                    ),
                ],
              ),
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
                    'Samar Waters Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    } catch (e) {
      // Return a simple error widget if something goes wrong
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Map temporarily unavailable',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }

  List<Polygon> _buildBoundaryPolygons(List<Map<String, dynamic>> boundaries) {
    return boundaries.map((boundary) {
      return Polygon(
        points: [
          latlong.LatLng(boundary['tl_lat'], boundary['tl_lng']),
          latlong.LatLng(boundary['tr_lat'], boundary['tr_lng']),
          latlong.LatLng(boundary['br_lat'], boundary['br_lng']),
          latlong.LatLng(boundary['bl_lat'], boundary['bl_lng']),
        ],
        color: Colors.green.withOpacity(0.3),
        borderColor: Colors.green,
        borderStrokeWidth: 2,
        isFilled: true,
      );
    }).toList();
  }

  List<Marker> _buildMarkers(List<Map<String, dynamic>> alerts) {
    return alerts.map((alert) {
      final lat = (alert['latitude'] as num).toDouble();
      final lng = (alert['longitude'] as num).toDouble();
      final fishermanId = alert['fisherman_id']?.toString() ?? '';
      
      // Get fisherman name
      final fishermanName = alert['fisherman_name'] ?? 
                           alert['fisherman_first_name'] ?? 
                           alert['fishermen']?['name'] ?? 
                           alert['fisherman_email'] ?? 
                           'Unknown';
      
      // Check if this fisherman is outside boundary
      final isOutsideBoundary = _outsideBoundaryFishermen.contains(fishermanId);
      
      return Marker(
        point: latlong.LatLng(lat, lng),
        width: 80,
        height: 60,
        child: GestureDetector(
          onTap: () => _showAlertDetails(alert),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fishermanName.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                decoration: BoxDecoration(
                  color: isOutsideBoundary ? Colors.orange : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (isOutsideBoundary ? Colors.orange : Colors.red).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isOutsideBoundary ? Icons.location_off : Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildSearchedLocationMarker() {
    if (_searchedLocation == null) return const [];
    return [
      Marker(
        point: _searchedLocation!,
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () {
            // Show searched location details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Searched Location: ${_searchedLocation!.latitude.toStringAsFixed(6)}, ${_searchedLocation!.longitude.toStringAsFixed(6)}',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    ];
  }

  List<Marker> _buildUserMarkers() {
    if (_currentUserLatLng == null) return const [];
    return [
      Marker(
        point: _currentUserLatLng!,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ),
    ];
  }

  List<Marker> _buildAdminMarkers() {
    if (!widget.showAdminLocations || _adminLocations.isEmpty) {
      return const [];
    }

    return _adminLocations.map((admin) {
      // Try multiple possible field names for location
      final lat = admin['current_latitude'] ?? 
                  admin['latitude'] ?? 
                  admin['current_location']?['latitude'];
      final lng = admin['current_longitude'] ?? 
                  admin['longitude'] ?? 
                  admin['current_location']?['longitude'];
      
      // Skip admins without location data
      if (lat == null || lng == null) return null;
      
      return Marker(
        point: latlong.LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        ),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () {
            // Show admin details on tap
            _showAdminDetails(admin);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_police,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }).where((marker) => marker != null).cast<Marker>().toList();
  }

  // Build markers for live fisherman locations
  List<Marker> _buildLiveLocationMarkers(List<Map<String, dynamic>> liveLocations) {
    if (liveLocations.isEmpty) return const [];
    
    return liveLocations.map((location) {
      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      
      // Skip locations without valid coordinates
      if (lat == null || lng == null) return null;
      
      // Check how recent the location is (within last 5 minutes = active)
      final updatedAt = location['updated_at']?.toString();
      final isRecent = updatedAt != null && 
          DateTime.now().difference(DateTime.parse(updatedAt)).inMinutes < 5;
      
      return Marker(
        point: latlong.LatLng(lat, lng),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _showLiveLocationDetails(location),
          child: Container(
            decoration: BoxDecoration(
              color: isRecent ? Colors.blue : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: (isRecent ? Colors.blue : Colors.grey).withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.person_pin_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      );
    }).where((marker) => marker != null).cast<Marker>().toList();
  }

  // Show live location details dialog
  void _showLiveLocationDetails(Map<String, dynamic> location) {
    final fishermanName = location['fisherman_name']?.toString() ?? 'Fisherman';
    final lat = (location['latitude'] as num?)?.toDouble();
    final lng = (location['longitude'] as num?)?.toDouble();
    final accuracy = (location['accuracy'] as num?)?.toDouble();
    final speed = (location['speed'] as num?)?.toDouble();
    final updatedAt = location['updated_at']?.toString();
    
    String timeAgo = 'Unknown';
    if (updatedAt != null) {
      final updateTime = DateTime.parse(updatedAt);
      final difference = DateTime.now().difference(updateTime);
      if (difference.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes} minutes ago';
      } else {
        timeAgo = '${difference.inHours} hours ago';
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text('Live Location: $fishermanName')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lat != null && lng != null) ...[
              Text('Latitude: ${lat.toStringAsFixed(6)}'),
              Text('Longitude: ${lng.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
            ],
            if (accuracy != null)
              Text('Accuracy: ${accuracy.toStringAsFixed(0)} meters'),
            if (speed != null)
              Text('Speed: ${(speed * 3.6).toStringAsFixed(1)} km/h'), // Convert m/s to km/h
            const SizedBox(height: 8),
            Text('Updated: $timeAgo', 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: updatedAt != null && 
                  DateTime.now().difference(DateTime.parse(updatedAt)).inMinutes < 5
                  ? Colors.green
                  : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          if (lat != null && lng != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Center map to this location
                _centerMapToLocation(latlong.LatLng(lat, lng));
              },
              icon: const Icon(Icons.center_focus_strong, size: 18),
              label: const Text('Center Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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

  void _showAdminDetails(Map<String, dynamic> admin) {
    final adminName = admin['name'] ?? 
                     '${admin['first_name'] ?? ''} ${admin['last_name'] ?? ''}'.trim() ??
                     admin['email'] ?? 
                     'Admin';
    final lat = admin['current_latitude'] ?? admin['latitude'];
    final lng = admin['current_longitude'] ?? admin['longitude'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_police, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text('Admin: $adminName')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lat != null && lng != null) ...[
              Text('Location: ${(lat as num).toStringAsFixed(6)}, ${(lng as num).toStringAsFixed(6)}'),
              const SizedBox(height: 8),
            ],
            if (admin['email'] != null)
              Text('Email: ${admin['email']}'),
            if (admin['phone'] != null) ...[
              const SizedBox(height: 4),
              Text('Phone: ${admin['phone']}'),
            ],
          ],
        ),
        actions: [
          if (admin['phone'] != null && admin['phone'].toString().isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _makePhoneCall(admin['phone'].toString()),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Call'),
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

  void _checkFishermenOutsideBoundaries(List<Map<String, dynamic>> alerts) async {
    for (final alert in alerts) {
      final lat = (alert['latitude'] as num).toDouble();
      final lng = (alert['longitude'] as num).toDouble();
      final fishermanId = alert['fisherman_id']?.toString() ?? '';
      
      if (fishermanId.isNotEmpty) {
        final isInsideBoundary = await BoundaryService.isPointInsideBoundary(lat, lng);
        
        if (!isInsideBoundary && !_outsideBoundaryFishermen.contains(fishermanId)) {
          _outsideBoundaryFishermen.add(fishermanId);
          
          // Show notification for fisherman outside boundary
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final name = alert['fishermen'] != null ? (alert['fishermen']['name']?.toString() ?? 'Unknown') : 'Fisherman';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.orange,
                  content: Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$name is outside safe fishing zone!')),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          });
        } else if (isInsideBoundary && _outsideBoundaryFishermen.contains(fishermanId)) {
          _outsideBoundaryFishermen.remove(fishermanId);
        }
      }
    }
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    // Get fisherman information from denormalized fields
    final fishermanName = alert['fisherman_name'] ?? 
                         alert['fisherman_first_name'] ?? 
                         (alert['fisherman_first_name'] != null && alert['fisherman_last_name'] != null
                           ? '${alert['fisherman_first_name']} ${alert['fisherman_last_name']}'
                           : null) ??
                         alert['fishermen']?['name'] ?? 
                         alert['fisherman_email'] ?? 
                         'Unknown';
    
    final fishermanEmail = alert['fisherman_email'] ?? '-';
    final fishermanPhone = alert['fisherman_phone'] ?? '-';
    final fishermanAddress = alert['fisherman_address'] ?? '-';
    final fishingArea = alert['fisherman_fishing_area'] ?? '-';
    final emergencyContact = alert['fisherman_emergency_contact_person'] ?? '-';
    
    final alertTime = alert['created_at']?.toString() ?? '-';
    final status = alert['status']?.toString() ?? 'active';
    final latitude = alert['latitude']?.toString() ?? '-';
    final longitude = alert['longitude']?.toString() ?? '-';
    final message = alert['message']?.toString() ?? 'SOS Alert';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('SOS Alert Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fisherman Information Section
              const Text(
                'Fisherman Information:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Name', fishermanName.toString()),
              _buildInfoRow('Email', fishermanEmail.toString()),
              if (fishermanPhone != '-') _buildInfoRow('Phone', fishermanPhone.toString()),
              if (fishermanAddress != '-') _buildInfoRow('Address', fishermanAddress.toString()),
              if (fishingArea != '-') _buildInfoRow('Fishing Area', fishingArea.toString()),
              if (emergencyContact != '-') _buildInfoRow('Emergency Contact', emergencyContact.toString()),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              // Alert Information Section
              const Text(
                'Alert Information:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Status', status.toUpperCase()),
              _buildInfoRow('Message', message),
              _buildInfoRow('Time', alertTime),
              _buildInfoRow('Location', 'Lat: $latitude, Lng: $longitude'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _notifyOnTheWay(alert['id']);
            },
            icon: const Icon(Icons.directions_boat, size: 16),
            label: const Text('On the Way'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _markAsResolved(alert['id']);
            },
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Resolved'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _notifyOnTheWay(String alertId) async {
    try {
      await DatabaseService().updateSOSAlertStatus(alertId, 'on_the_way');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.directions_boat, color: Colors.white),
                SizedBox(width: 8),
                Text('Help is on the way!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {}
  }

  void _markAsResolved(String alertId) async {
    final databaseService = DatabaseService();
    
    // Get alert details first
    final alert = await databaseService.getSOSAlertById(alertId);
    if (alert == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Alert not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final fishermanName = alert['fisherman_name'] ?? 
                         alert['fisherman_first_name'] ?? 
                         alert['fisherman_email'] ?? 
                         'fisherman';
    
    // Show resolve dialog with statistics input (same as rescue notifications page)
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ResolveDialog(
        fishermanName: fishermanName.toString(),
      ),
    );

    if (result != null && result['confirmed'] == true) {
      // Show loading indicator
      if (mounted) {
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
        final success = await databaseService.updateSOSAlertStatus(
          alertId,
          'inactive',
          casualties: casualties,
          injured: injured,
        );
        
        if (success) {
          // Wait a moment for database to update
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Refresh dashboard data if available
          if (mounted) {
            try {
              final adminProvider = Provider.of<AdminProviderSimple>(context, listen: false);
              await adminProvider.loadDashboardData();
            } catch (e) {
              print('Could not refresh dashboard: $e');
            }
          }
          
          // Get statistics and show popup
          final stats = await databaseService.getRescueStatistics();
          
          if (mounted) {
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
        if (mounted) {
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

  void _checkCurrentUserBoundaryStatus() async {
    // This is a simplified version - in a real app, you'd get the user's current location
    // For now, we'll use a sample location around Catbalogan, Samar
    const double sampleLat = 11.7753;
    const double sampleLng = 124.8861;
    
    try {
      final isInsideBoundary = await BoundaryService.isPointInsideBoundary(sampleLat, sampleLng);
      if (widget.onBoundaryCheck != null) {
        widget.onBoundaryCheck!(!isInsideBoundary); // true if outside boundary
      }
    } catch (e) {
      print('Error checking boundary status: $e');
    }
  }
}

// Resolve Dialog with statistics input (same as rescue notifications page)
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

// Rescue Statistics Dialog (same as rescue notifications page)
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
