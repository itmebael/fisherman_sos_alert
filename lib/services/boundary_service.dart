import 'package:supabase_flutter/supabase_flutter.dart';

class BoundaryService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static String? lastErrorMessage;

  // Create boundaries table if it doesn't exist
  static Future<void> createBoundariesTable() async {
    try {
      await _supabase.rpc('create_boundaries_table_if_not_exists');
    } catch (e) {
      // Table might already exist, ignore error
      print('Boundaries table creation: $e');
    }
  }

  // Save boundary coordinates to database
  static Future<bool> saveBoundary({
    required double tlLat,
    required double tlLng,
    required double trLat,
    required double trLng,
    required double brLat,
    required double brLng,
    required double blLat,
    required double blLng,
  }) async {
    try {
      lastErrorMessage = null;
      await _supabase.from('boundaries').insert({
        'tl_lat': tlLat,
        'tl_lng': tlLng,
        'tr_lat': trLat,
        'tr_lng': trLng,
        'br_lat': brLat,
        'br_lng': brLng,
        'bl_lat': blLat,
        'bl_lng': blLng,
      });
      return true;
    } catch (e) {
      print('Error saving boundary: $e');
      lastErrorMessage = e.toString();
      return false;
    }
  }

  // Get all boundaries
  static Future<List<Map<String, dynamic>>> getActiveBoundaries() async {
    try {
      final response = await _supabase
          .from('boundaries')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching boundaries: $e');
      return [];
    }
  }

  // Check if a point is inside any boundary
  static Future<bool> isPointInsideBoundary(double lat, double lng) async {
    try {
      final boundaries = await getActiveBoundaries();
      
      for (final boundary in boundaries) {
        if (_isPointInPolygon(
          lat,
          lng,
          [
            LatLng(boundary['tl_lat'], boundary['tl_lng']),
            LatLng(boundary['tr_lat'], boundary['tr_lng']),
            LatLng(boundary['br_lat'], boundary['br_lng']),
            LatLng(boundary['bl_lat'], boundary['bl_lng']),
          ],
        )) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking boundary: $e');
      return false;
    }
  }

  // Ray casting algorithm to check if point is inside polygon
  static bool _isPointInPolygon(double lat, double lng, List<LatLng> polygon) {
    int intersections = 0;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];

      if (((pi.latitude > lat) != (pj.latitude > lat)) &&
          (lng < (pj.longitude - pi.longitude) * (lat - pi.latitude) / (pj.latitude - pi.latitude) + pi.longitude)) {
        intersections++;
      }
      j = i;
    }

    return (intersections % 2) == 1;
  }

  // Get boundary stream for real-time updates
  static Stream<List<Map<String, dynamic>>> getBoundariesStream() {
    return _supabase
        .from('boundaries')
        .stream(primaryKey: ['id']);
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

