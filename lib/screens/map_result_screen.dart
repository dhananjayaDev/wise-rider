
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trip_provider.dart';

class MapResultScreen extends ConsumerWidget {
  const MapResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripProvider);
    
    // Safety check just in case
    if (state.startPoint == null || state.endPoint == null) {
      return const Scaffold(body: Center(child: Text("No Data")));
    }

    final bounds = LatLngBounds.fromPoints(state.routePoints);

    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
          FlutterMap(
            options: MapOptions(
              initialCenter: state.startPoint!,
              initialZoom: 9.0,
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.riders.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: state.routePoints,
                    color: Colors.cyanAccent,
                    strokeWidth: 5.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                   // Dynamically render all markers
                   ...state.allWaypoints.asMap().entries.map((entry) {
                       final index = entry.key;
                       final point = entry.value;
                       final isStart = index == 0;
                       final isEnd = index == state.allWaypoints.length - 1;
                       
                       return Marker(
                         point: point,
                         width: 40,
                         height: 40,
                         child: isStart 
                           ? const Icon(Icons.location_on, color: Colors.green, size: 40)
                           : isEnd 
                              ? const Icon(Icons.flag, color: Colors.orange, size: 40)
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)]
                                  ),
                                  child: const Icon(Icons.stop, color: Colors.black, size: 20),
                                ),
                       );
                   }).toList(),
                ],
              ),
            ],
          ),

          // Weather Details Button (Top Right)
          Positioned(
             top: 50,
             right: 16,
             child: FloatingActionButton.small(
                heroTag: "weather_fab",
                onPressed: () => _showWeatherDetails(context, state),
                backgroundColor: Colors.blueGrey[900],
                child: const Icon(Icons.cloud_queue, color: Colors.cyanAccent),
             ),
          ),

          // Bottom Sheet Content
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.1,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                     BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)
                  ]
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4, 
                          color: Colors.grey[600],
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                      ),
                      
                      // Trip Summary
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(Icons.timer_outlined, "Duration", state.tripDuration),
                            Container(width: 1, height: 40, color: Colors.white24),
                            _StatItem(Icons.map_outlined, "Distance", state.tripDistance),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                       // AI Advice Card
                      Container(
                        decoration: BoxDecoration(
                           color: const Color(0xFF2D2D2D),
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                           boxShadow: [
                             BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 10)
                           ]
                        ),
                        child: Padding(
                           padding: const EdgeInsets.all(20.0),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(children: [
                                const Icon(Icons.smart_toy_outlined, color: Colors.cyanAccent),
                                const SizedBox(width: 12),
                                Text(
                                  "Short Advice", 
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              MarkdownBody(
                                data: state.aiAdvice, 
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(color: Colors.white70, height: 1.5),
                                  strong: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                  listBullet: const TextStyle(color: Colors.cyanAccent),
                                  blockSpacing: 8.0, 
                                ),
                              ),
                             ],
                           ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showWeatherDetails(BuildContext context, TripState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WeatherDetailsSheet(state: state),
    );
  }

  Widget _StatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }
}

class _WeatherDetailsSheet extends StatefulWidget {
  final TripState state;
  const _WeatherDetailsSheet({required this.state});

  @override
  State<_WeatherDetailsSheet> createState() => _WeatherDetailsSheetState();
}

class _WeatherDetailsSheetState extends State<_WeatherDetailsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Dynamic length based on tabs
    _tabController = TabController(length: widget.state.weatherTabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // Safety check
    if (widget.state.weatherTabs.isEmpty) {
        return const Center(child: Text("No Weather Data", style: TextStyle(color: Colors.white)));
    }
  
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Handle
          Container(width: 40, height: 4, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text("City-wise Weather", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          
          TabBar(
            controller: _tabController,
            isScrollable: true, // Allow scrolling if many cities
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.cyanAccent,
            tabs: widget.state.weatherTabs.map((t) => Tab(text: t['city'])).toList(),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: widget.state.weatherTabs.map((t) {
                   return _buildTimeline(t['timeline'] as List<Map<String, dynamic>>);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const Center(child: Text("No Data", style: TextStyle(color: Colors.white54)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        final isRain = (item['rain'] as num) > 30;
        return Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRain ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent
            )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item['time'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 12),
              Icon(
                isRain ? Icons.water_drop : Icons.wb_cloudy, 
                color: isRain ? Colors.blueAccent : Colors.orangeAccent
              ),
              const SizedBox(height: 12),
              Text("${item['temp']}°", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("${item['rain']}%", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ],
          ),
        );
      },
    );
  }
}
