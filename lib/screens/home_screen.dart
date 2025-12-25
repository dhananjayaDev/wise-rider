
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trip_provider.dart';
import 'map_result_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<TextEditingController> _controllers = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Start with 2 inputs (Start & End)
    _addInput();
    _addInput();
  }

  void _addInput() {
    setState(() {
      _controllers.add(TextEditingController());
    });
    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (_scrollController.hasClients) {
          _scrollController.animateTo(
             _scrollController.position.maxScrollExtent, 
             duration: const Duration(milliseconds: 300), 
             curve: Curves.easeOut);
       }
    });
  }

  void _removeInput(int index) {
      if (_controllers.length <= 2) return; // Keep at least 2
      setState(() {
         _controllers[index].dispose();
         _controllers.removeAt(index);
      });
  }

  void _planTrip() async {
    final List<String> locations = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (locations.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least start and end points')),
      );
      return;
    }

    // Trigger state change
    await ref.read(tripProvider.notifier).planTrip(locations);

    if (mounted) {
       final error = ref.read(tripProvider).error;
       if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
       } else {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const MapResultScreen()
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: Stack(
        children: [
           // Background Gradient
           Container(
             decoration: const BoxDecoration(
               gradient: LinearGradient(
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
                 colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
               )
             ),
           ),
           
           SafeArea(
             child: Column(
               children: [
                 const SizedBox(height: 40),
                 const Text("RIDE WISE", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.cyanAccent)),
                 const SizedBox(height: 8),
                 Text("Plan your perfect ride", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                 const SizedBox(height: 40),

                 // Dynamic Inputs List
                 Expanded(
                   child: ListView.builder(
                     controller: _scrollController,
                     padding: const EdgeInsets.symmetric(horizontal: 24),
                     itemCount: _controllers.length,
                     itemBuilder: (context, index) {
                        final isFirst = index == 0;
                        final isLast = index == _controllers.length - 1;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                               Column(
                                 children: [
                                   Icon(
                                      isFirst ? Icons.trip_origin : (isLast ? Icons.flag : Icons.circle_outlined), 
                                      color: isFirst ? Colors.greenAccent : (isLast ? Colors.orangeAccent : Colors.grey),
                                      size: 20
                                   ),
                                   if (!isLast)
                                     Container(width: 2, height: 40, color: Colors.white12, margin: const EdgeInsets.symmetric(vertical: 4))
                                 ],
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: TextField(
                                   controller: _controllers[index],
                                   style: const TextStyle(color: Colors.white),
                                   decoration: InputDecoration(
                                     labelText: isFirst ? "Start Location" : (isLast ? "Destination" : "Way Point"),
                                     labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                     filled: true,
                                     fillColor: Colors.white.withOpacity(0.05),
                                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                     suffixIcon: (_controllers.length > 2) ? IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                        onPressed: () => _removeInput(index),
                                     ) : null,
                                   ),
                                 ),
                               ),
                            ],
                          ),
                        );
                     },
                   ),
                 ),
                 
                 // Add Stop Button
                 TextButton.icon(
                    onPressed: _controllers.length < 8 ? _addInput : null,
                    icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
                    label: const Text("Add Stop", style: TextStyle(color: Colors.cyanAccent)),
                 ),
                 
                 const SizedBox(height: 20),

                 // Action Button
                 Padding(
                   padding: const EdgeInsets.all(24.0),
                   child: SizedBox(
                     width: double.infinity,
                     height: 56,
                     child: ElevatedButton(
                       onPressed: isLoading ? null : _planTrip,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.cyanAccent,
                         foregroundColor: Colors.black,
                         elevation: 0,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                       ),
                       child: isLoading 
                         ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                         : const Text("START ENGINES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                     ),
                   ),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }
}
