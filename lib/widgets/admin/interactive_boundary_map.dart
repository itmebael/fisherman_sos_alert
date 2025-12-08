import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../constants/colors.dart';

class InteractiveBoundaryMap extends StatefulWidget {
  final Function(List<latlong.LatLng>) onBoundaryPointsSelected;
  final List<latlong.LatLng>? initialPoints;
  
  const InteractiveBoundaryMap({
    super.key,
    required this.onBoundaryPointsSelected,
    this.initialPoints,
  });

  @override
  State<InteractiveBoundaryMap> createState() => _InteractiveBoundaryMapState();
}

class _InteractiveBoundaryMapState extends State<InteractiveBoundaryMap> {
  final MapController _mapController = MapController();
  List<latlong.LatLng> _selectedPoints = [];
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPoints != null) {
      _selectedPoints = List.from(widget.initialPoints!);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                initialCenter: const latlong.LatLng(11.7753, 124.8861), // Catbalogan, Samar
                initialZoom: 12.0,
                minZoom: 8.0,
                maxZoom: 18.0,
                onTap: _isSelecting ? _onMapTap : null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.fisherman_sos_alert',
                  maxZoom: 18,
                ),
                // Show selected boundary points
                if (_selectedPoints.isNotEmpty)
                  MarkerLayer(
                    markers: _buildBoundaryMarkers(),
                  ),
                // Show boundary polygon if we have 4 points
                if (_selectedPoints.length == 4)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _selectedPoints,
                        color: Colors.green.withOpacity(0.3),
                        borderColor: Colors.green,
                        borderStrokeWidth: 2,
                        isFilled: true,
                      ),
                    ],
                  ),
              ],
            ),
            // Control buttons
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    onPressed: _toggleSelection,
                    backgroundColor: _isSelecting ? Colors.red : AppColors.primaryColor,
                    child: Icon(
                      _isSelecting ? Icons.stop : Icons.add_location,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedPoints.isNotEmpty)
                    FloatingActionButton.small(
                      onPressed: _clearPoints,
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.clear, color: Colors.white),
                    ),
                ],
              ),
            ),
            // Instructions
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isSelecting 
                    ? 'Tap on the map to select boundary points (${_selectedPoints.length}/4)'
                    : 'Tap the + button to start selecting boundary points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildBoundaryMarkers() {
    return _selectedPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return Marker(
        point: point,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onMapTap(TapPosition tapPosition, latlong.LatLng point) {
    if (!_isSelecting || _selectedPoints.length >= 4) return;

    setState(() {
      _selectedPoints.add(point);
    });

    // If we have 4 points, stop selecting and notify parent
    if (_selectedPoints.length == 4) {
      _isSelecting = false;
      widget.onBoundaryPointsSelected(_selectedPoints);
    }
  }

  void _toggleSelection() {
    setState(() {
      _isSelecting = !_isSelecting;
    });
  }

  void _clearPoints() {
    setState(() {
      _selectedPoints.clear();
      _isSelecting = false;
    });
  }
}
