
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RoutingService {
  // Use local dotenv if set, otherwise fallback to public demo
  final String _baseUrl = dotenv.env['OSRM_API_URL'] ?? 'https://router.project-osrm.org/route/v1/driving';

  Future<Map<String, dynamic>> getRoute(List<LatLng> points) async {
    if (points.length < 2) throw Exception('Need at least 2 points');
    
    final coordinates = points
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = Uri.parse(
        '$_baseUrl/$coordinates?overview=full&geometries=polyline');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final points = decodePolyline(geometry)
              .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
              .toList();
          
          return {
            'points': points,
            'distance': route['distance'], // meters
            'duration': route['duration'] // seconds
          };
        }
      }
    } catch (e) {
// print('Routing error: $e');
    }
    throw Exception('Route not found');
  }
}
