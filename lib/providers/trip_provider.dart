
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';
import '../services/routing_service.dart';
import '../services/weather_service.dart';
import '../services/ai_service.dart';

// Service Providers
final geocodingServiceProvider = Provider((ref) => GeocodingService());
final routingServiceProvider = Provider((ref) => RoutingService());
final weatherServiceProvider = Provider((ref) => WeatherService());
final aiServiceProvider = Provider((ref) => AIService());

class TripState {
  final bool isLoading;
  final String? error;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final String startName;
  final String endName;
  final List<LatLng> routePoints;
  final String tripDuration;
  final String tripDistance;
  final String weatherSummary;
  final List<Map<String, dynamic>> weatherTabs; 
  final bool isRainy;
  final String aiAdvice;
  final List<LatLng> allWaypoints; // New: Store all intermediate points

  TripState({
    this.isLoading = false,
    this.error,
    this.startPoint,
    this.endPoint,
    this.startName = '',
    this.endName = '',
    this.routePoints = const [],
    this.tripDuration = '',
    this.tripDistance = '',
    this.weatherTabs = const [],
    this.weatherSummary = '',
    this.isRainy = false,
    this.aiAdvice = '',
    this.allWaypoints = const [],
  });

  TripState copyWith({
    bool? isLoading,
    String? error,
    LatLng? startPoint,
    LatLng? endPoint,
    String? startName,
    String? endName,
    List<LatLng>? routePoints,
    String? tripDuration,
    String? tripDistance,
    List<Map<String, dynamic>>? weatherTabs,
    String? weatherSummary,
    bool? isRainy,
    String? aiAdvice,
    List<LatLng>? allWaypoints,
  }) {
    return TripState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      startName: startName ?? this.startName,
      endName: endName ?? this.endName,
      routePoints: routePoints ?? this.routePoints,
      tripDuration: tripDuration ?? this.tripDuration,
      tripDistance: tripDistance ?? this.tripDistance,
      weatherTabs: weatherTabs ?? this.weatherTabs,
      weatherSummary: weatherSummary ?? this.weatherSummary,
      isRainy: isRainy ?? this.isRainy,
      aiAdvice: aiAdvice ?? this.aiAdvice,
      allWaypoints: allWaypoints ?? this.allWaypoints,
    );
  }
}

// Changed from StateNotifier to Notifier
class TripNotifier extends Notifier<TripState> {
  @override
  TripState build() {
    return TripState();
  }

  Future<void> planTrip(List<String> locations) async {
    if (locations.length < 2) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final geocodingService = ref.read(geocodingServiceProvider);
      final routingService = ref.read(routingServiceProvider);
      final weatherService = ref.read(weatherServiceProvider);
      final aiService = ref.read(aiServiceProvider);

      // 1. Geocode All Locations
      List<LatLng> waypoints = [];
      List<String> waypointNames = [];
      
      for (final query in locations) {
          if (query.trim().isEmpty) continue;
          final data = await geocodingService.searchPlace(query);
          waypoints.add(data['point'] as LatLng);
          // Try to get a short city name for the tab
          String fullName = data['name'];
          waypointNames.add(fullName.split(',')[0].trim());
      }

      if (waypoints.length < 2) {
          throw Exception("Need at least 2 valid locations");
      }

      state = state.copyWith(
        startPoint: waypoints.first,
        endPoint: waypoints.last,
        startName: waypointNames.first,
        endName: waypointNames.last,
        allWaypoints: waypoints,
      );

      // 2. Route
      final routeData = await routingService.getRoute(waypoints);
      final points = routeData['points'] as List<LatLng>;
      final dist = (routeData['distance'] / 1000).toStringAsFixed(1) + " km";
      final durSeconds = routeData['duration'] as num;
      final durHours = (durSeconds / 3600).toStringAsFixed(1) + " hr";

      state = state.copyWith(
        routePoints: points,
        tripDistance: dist,
        tripDuration: durHours,
      );

      // 3. Weather (Check User-Defined Stops)
      // We fetch weather for the exact points the user selected
      final weatherResults = await weatherService.getBatchWeather(waypoints);

      List<Map<String, dynamic>> finalTabs = [];
      String overallSummary = "Tripping through ${waypointNames.join(' -> ')}";
      bool rainy = false;
      List<String> summaryParts = [];

      for(int i=0; i<waypoints.length; i++) {
         final w = weatherResults[i];
         final name = waypointNames[i];
         
         finalTabs.add({
             'city': name,
             'timeline': w['timeline'],
             'desc': w['desc']
         });
         
         summaryParts.add("$name: ${w['desc']}");
         if ((w['max_rain'] as num) > 50) rainy = true;
      }
      
      if (summaryParts.isNotEmpty) overallSummary = summaryParts.join(", ");

      state = state.copyWith(
        weatherTabs: finalTabs,
        weatherSummary: overallSummary,
        isRainy: rainy,
      );

      // 4. AI Advice
      // Pass the route description for context
      final advice = await aiService.getTripAdvice(
          waypointNames.first, waypointNames.last, durHours, summaryParts.join("; "));
      
      state = state.copyWith(
        aiAdvice: advice,
        isLoading: false,
      );

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tripProvider = NotifierProvider<TripNotifier, TripState>(TripNotifier.new);
