import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class WeatherService {
  final String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Check weather for a specific list of points
  Future<List<Map<String, dynamic>>> getBatchWeather(List<LatLng> points) async {
    if (points.isEmpty) return [];

    // Prepare Batch Request
    final lats = points.map((p) => p.latitude).join(',');
    final longs = points.map((p) => p.longitude).join(',');

    // Request hourly data: temperature_2m, weathercode, precipitation_probability
    final url = Uri.parse(
        '$_baseUrl?latitude=$lats&longitude=$longs&hourly=temperature_2m,weathercode,precipitation_probability&timezone=auto&forecast_days=1');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> results;
        if (data is List) results = data;
        else results = [data];

        List<Map<String, dynamic>> batchResults = [];

        for (var i = 0; i < results.length; i++) {
          final hourly = results[i]['hourly'];
          if (hourly == null) {
              batchResults.add({'timeline': [], 'max_rain': 0, 'code': 0});
              continue;
          }

          final times = hourly['time'] as List;
          final temps = hourly['temperature_2m'] as List;
          final codes = hourly['weathercode'] as List;
          final probs = hourly['precipitation_probability'] as List;

          List<Map<String, dynamic>> locationTimeline = [];
          double maxRain = 0;
          int worstCode = 0;
          
          // Get next 12 hours
          final now = DateTime.now().hour;
          for(int h=0; h<24; h++) {
             String tStr = times[h];
             DateTime t = DateTime.parse(tStr);
             
             if (t.hour >= now) {
                 final rain = (probs[h] as num).toDouble();
                 if (rain > maxRain) maxRain = rain;
                 if ((codes[h] as int) > worstCode) worstCode = codes[h];

                 locationTimeline.add({
                     'time': "${t.hour}:00",
                     'temp': temps[h],
                     'code': codes[h],
                     'rain': rain,
                     'desc': _weatherCodeToString(codes[h] as int)
                 });
                 if (locationTimeline.length >= 8) break; // Limit to 8 hours
             }
          }
           
           batchResults.add({
               'timeline': locationTimeline,
               'max_rain': maxRain,
               'code': worstCode,
               'desc': _weatherCodeToString(worstCode)
           });
        }
        return batchResults;
      }
    } catch (e) {
      // print('Weather error: $e');
    }
    return [];
  }

  String _weatherCodeToString(int code) {
    if (code == 0) return "Clear";
    if (code < 4) return "Cloudy";
    if (code < 50) return "Fog";
    if (code < 70) return "Rain";
    if (code < 80) return "Snow";
    if (code < 100) return "Storm";
    return "Unknown";
  }


}
