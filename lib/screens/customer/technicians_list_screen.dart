import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/fee_calculator.dart';
import '../../models/app_user.dart';
import '../../providers/app_state.dart';
import '../../services/api_error.dart';
import '../../widgets/common_widgets.dart';
import 'technician_profile_screen.dart';

class TechniciansListScreen extends StatefulWidget {
  const TechniciansListScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<TechniciansListScreen> createState() => _TechniciansListScreenState();
}

class _TechniciansListScreenState extends State<TechniciansListScreen> {
  List<AppUser> _techs = [];
  bool _loading = true;
  bool _showMap = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final techs = await context.read<AppState>().api.nearbyTechnicians(
            category: widget.initialCategory,
          );
      setState(() {
        _techs = techs;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e))),
        );
      }
      setState(() => _loading = false);
    }
  }

  Set<Marker> _buildMarkers() {
    return _techs.map((tech) {
      return Marker(
        markerId: MarkerId(tech.id),
        position: LatLng(tech.latitude, tech.longitude),
        infoWindow: InfoWindow(
          title: tech.name,
          snippet: '${tech.skills.join(', ')} - ${tech.distanceKm?.toStringAsFixed(1) ?? '0.0'} km',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TechnicianProfileScreen(technician: tech),
            ),
          ),
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_techs.isEmpty) {
      return const Center(child: Text('No technicians found nearby'));
    }

    final user = context.read<AppState>().currentUser;
    final initialPos = user != null
        ? LatLng(user.latitude, user.longitude)
        : const LatLng(31.5204, 74.3587);

    return Scaffold(
      body: _showMap
          ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPos,
                zoom: 13,
              ),
              markers: _buildMarkers(),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (ctrl) => _mapController = ctrl,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _techs.length,
                itemBuilder: (context, i) {
                  final tech = _techs[i];
                  final dist = tech.distanceKm ?? 0;
                  final fee = tech.checkFee ?? checkFeeForDistanceKm(dist);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(tech.name[0])),
                      title: Text(tech.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RatingStars(rating: tech.rating, size: 14),
                          Text('${dist.toStringAsFixed(1)} km • Rs $fee check fee'),
                          Text(tech.skills.join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (!tech.isAvailable)
                            const Text(
                              'Schedule only',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                      trailing: Icon(
                        tech.isAvailable ? Icons.check_circle : Icons.cancel,
                        color: tech.isAvailable ? Colors.green : Colors.grey,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TechnicianProfileScreen(technician: tech),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _showMap = !_showMap),
        icon: Icon(_showMap ? Icons.list : Icons.map),
        label: Text(_showMap ? 'List View' : 'Map View'),
      ),
    );
  }
}
