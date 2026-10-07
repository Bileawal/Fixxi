import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/app_state.dart';
import '../../models/app_user.dart';
import '../../services/ai_diagnosis_engine.dart';
import 'create_request_screen.dart';
import 'ai_diagnosis_screen.dart' as ai_diagnosis;

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  List<AppUser> _nearbyTechnicians = [];
  bool _loading = true;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  String? _selectedCategory;
  int _selectedDistanceFilter = 10;
  
  void _updateMarkers() {
    final markers = <Marker>{};
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_loc'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    }
    
    final filteredTechs = _nearbyTechnicians.where((t) {
      if (t.distanceKm == null) return true;
      return t.distanceKm! <= _selectedDistanceFilter;
    }).toList();

    for (var tech in filteredTechs) {
      markers.add(
        Marker(
          markerId: MarkerId(tech.id),
          position: LatLng(tech.latitude ?? 31.5204, tech.longitude ?? 74.3587),
          infoWindow: InfoWindow(
            title: tech.name,
            snippet: '${tech.skills.isNotEmpty ? tech.skills.first : 'Technician'} • ★${tech.rating?.toStringAsFixed(1) ?? 'N/A'}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        )
      );
    }
    setState(() {
      _markers = markers;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
    AiDiagnosisEngine.shared.initialize();
  }

  Future<void> _load() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          _currentPosition = await Geolocator.getCurrentPosition();
        }
      }

      final app = context.read<AppState>();
      final nearby = await app.api.nearbyTechnicians();
      
      if (mounted) {
        setState(() {
          _nearbyTechnicians = nearby;
          _loading = false;
        });
        _updateMarkers();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final initialPos = _currentPosition != null 
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(31.5204, 74.3587); // Default Lahore

    return Scaffold(
      body: Stack(
        children: [
          // MAP
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: initialPos,
                    zoom: 13.5,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
          ),
          
          // BOTTOM SHEET / DRAGGABLE
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.6,
            maxChildSize: 1.0,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    Text(
                      'Hello, ${user.name.split(' ').first} 👋',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What do you need help with today?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Services Grid
                    Text(
                      'Services',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ServiceItem(
                          icon: Icons.electrical_services, 
                          label: 'Electrician', 
                          color: Colors.yellow[700]!,
                          isSelected: _selectedCategory == 'Electrician',
                          onTap: () => setState(() => _selectedCategory = _selectedCategory == 'Electrician' ? null : 'Electrician'),
                        ),
                        _ServiceItem(
                          icon: Icons.plumbing, 
                          label: 'Plumber', 
                          color: Colors.blue[400]!,
                          isSelected: _selectedCategory == 'Plumber',
                          onTap: () => setState(() => _selectedCategory = _selectedCategory == 'Plumber' ? null : 'Plumber'),
                        ),
                        _ServiceItem(
                          icon: Icons.ac_unit, 
                          label: 'AC & Refrigerator Mechanic', 
                          color: Colors.lightBlue[300]!,
                          isSelected: _selectedCategory == 'AC & Refrigerator Mechanic',
                          onTap: () => setState(() => _selectedCategory = _selectedCategory == 'AC & Refrigerator Mechanic' ? null : 'AC & Refrigerator Mechanic'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Nearby Technicians
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nearby Technicians',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            DropdownButton<int>(
                              value: _selectedDistanceFilter,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.filter_list, size: 20),
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('1 km')),
                                DropdownMenuItem(value: 3, child: Text('3 km')),
                                DropdownMenuItem(value: 5, child: Text('5 km')),
                                DropdownMenuItem(value: 7, child: Text('7 km')),
                                DropdownMenuItem(value: 10, child: Text('10 km')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedDistanceFilter = v;
                                  });
                                  _updateMarkers();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    Builder(builder: (context) {
                      var filteredTechnicians = _selectedCategory == null 
                          ? _nearbyTechnicians 
                          : _nearbyTechnicians.where((t) => t.skills.contains(_selectedCategory)).toList();
                      
                      filteredTechnicians = filteredTechnicians.where((t) {
                        if (t.distanceKm == null) return true;
                        return t.distanceKm! <= _selectedDistanceFilter;
                      }).toList();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (filteredTechnicians.isEmpty && !_loading)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: Text('No technicians found for this category')),
                            ),
                          if (filteredTechnicians.isNotEmpty)
                            SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: filteredTechnicians.length,
                                itemBuilder: (ctx, i) {
                                  final t = filteredTechnicians[i];
                                  return _TechCard(technician: t);
                                },
                              ),
                            ),
                        ],
                      );
                    }),

                    const SizedBox(height: 24),

                    // AI Diagnostic Banner
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ai_diagnosis.AIDiagnosisScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFEA580C).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.smart_toy, color: Colors.white, size: 48),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('AI Diagnostic Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text('Describe your issue in Urdu or English and let AI diagnose it instantly.', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Urgent Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[200]!)
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Need help urgently?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[900])),
                                const SizedBox(height: 4),
                                Text('Post a request and get offers from nearby technicians.', style: TextStyle(fontSize: 12, color: Colors.green[800])),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                                  ),
                                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text('Post a Request'),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('🛠️', style: TextStyle(fontSize: 48)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80), // bottom padding for nav bar
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.icon, 
    required this.label, 
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.4) : color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : null,
            ), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }
}

class _TechCard extends StatelessWidget {
  final AppUser technician;
  
  const _TechCard({required this.technician});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(technician.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(technician.skills.isNotEmpty ? technician.skills.first : 'Technician', style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const SizedBox(width: 4),
              Text(technician.rating?.toStringAsFixed(1) ?? 'N/A', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('• ${technician.distanceKm?.toStringAsFixed(1) ?? '??'}km', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          )
        ],
      ),
    );
  }
}
