
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../core/theme/app_theme.dart';

class OutbreakMapScreen extends StatefulWidget {
  const OutbreakMapScreen({super.key});

  @override
  State<OutbreakMapScreen> createState() => _OutbreakMapScreenState();
}

class _OutbreakMapScreenState extends State<OutbreakMapScreen> {
  // Creating a map controller is optional in simple cases, but good practice
  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _outbreaks = [
     {'lat': 28.7041, 'lng': 77.1025, 'title': 'Delhi', 'cases': 120, 'risk': 'High'},
     {'lat': 19.0760, 'lng': 72.8777, 'title': 'Mumbai', 'cases': 45, 'risk': 'Moderate'},
     {'lat': 12.9716, 'lng': 77.5946, 'title': 'Bengaluru', 'cases': 12, 'risk': 'Low'},
     {'lat': 22.5726, 'lng': 88.3639, 'title': 'Kolkata', 'cases': 200, 'risk': 'High'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Outbreak Map'), 
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // Simple mock "my location" movement
               _mapController.move(const LatLng(20.5937, 78.9629), 5);
            },
          ),
        ],
      ),
      body: Container(
        decoration: null,
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(20.5937, 78.9629), // Center on India
            initialZoom: 5.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              // Premium Dark Mode Map (CartoDB Dark Matter)
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.jal_rakshak_app',
            ),
            MarkerLayer(
              markers: _outbreaks.map((data) {
                return Marker(
                  point: LatLng(data['lat'], data['lng']),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showDetailsSheet(data),
                    child: Icon(
                      Icons.location_on,
                      color: _getRiskColor(data['risk']),
                      size: 40,
                      shadows: [
                         Shadow(blurRadius: 10, color: _getRiskColor(data['risk'])),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            // Attribution
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors & CartoDB',
                  onTap: null, // Open URL in real app
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'High': return AppTheme.error;
      case 'Moderate': return AppTheme.warning;
      case 'Low': return AppTheme.success;
      default: return Colors.white;
    }
  }

  void _showDetailsSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer.frostedGlass(
        height: 250,
        width: double.infinity,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['title'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRiskColor(data['risk']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(data['risk'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Text('${data['cases']} Cases Reported', style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Recent outbreak reported. Local authorities are monitoring the situation and sanitation drives are active.', style: TextStyle(color: Colors.white54)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                   onPressed: () => Navigator.pop(context),
                   child: const Text('Dismiss'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
