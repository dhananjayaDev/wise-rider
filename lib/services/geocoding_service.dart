
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  final String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<Map<String, dynamic>> searchPlace(String query) async {
    final url = Uri.parse(
        '$_baseUrl?q=${Uri.encodeComponent(query)}&format=json&limit=1');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'MotorcycleTripPlanner/1.0 (com.riders.app)'
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final item = data.first;
          return {
            'name': item['display_name'],
            'point': LatLng(
                double.parse(item['lat']), double.parse(item['lon']))
          };
        }
      }
    } catch (e) {
// print('Geocoding error: $e');
    }
    throw Exception('Place not found');
  }
  Future<String> getCityName(LatLng point) async {
    final url = Uri.parse(
        '$_baseUrl?lat=${point.latitude}&lon=${point.longitude}&format=json&zoom=10');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'MotorcycleTripPlanner/1.0 (com.riders.app)'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null) {
          final address = data['address'];
          // Try to find the most relevant city-like name
          return address['city'] ?? 
                 address['town'] ?? 
                 address['village'] ?? 
                 address['county'] ?? 
                 "Unknown Location";
        }
      }
    } catch (e) {
      // print('Reverse Geo error: $e');
    }
    return "Unknown Location";
  }
}
