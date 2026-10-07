import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/service_request.dart';
import '../../providers/app_state.dart';

class TrackLocationScreen extends StatefulWidget {
  const TrackLocationScreen({
    super.key,
    required this.request,
    required this.trackingTechnician,
  });

  final ServiceRequest request;
  final bool trackingTechnician;

  @override
  State<TrackLocationScreen> createState() => _TrackLocationScreenState();
}

class _TrackLocationScreenState extends State<TrackLocationScreen> {
  GoogleMapController? _mapController;

  Future<void> _navigateToLocation(double lat, double lng) async {
    final url = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final me = appState.currentUser;
    if (me == null) return const SizedBox.shrink();

    final title = widget.trackingTechnician ? 'Track Technician' : 'Customer Location';
    final targetUserId = widget.trackingTechnician ? widget.request.technicianId : widget.request.customerId;

    if (targetUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('User location not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(targetUserId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final targetLat = (data['latitude'] as num?)?.toDouble() ?? 31.5204;
          final targetLng = (data['longitude'] as num?)?.toDouble() ?? 74.3587;
          final targetName = data['name'] as String? ?? 'User';

          final myPos = LatLng(me.latitude, me.longitude);
          final targetPos = LatLng(targetLat, targetLng);

          final markers = {
            Marker(
              markerId: const MarkerId('me'),
              position: myPos,
              infoWindow: const InfoWindow(title: 'Me'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
            Marker(
              markerId: const MarkerId('target'),
              position: targetPos,
              infoWindow: InfoWindow(title: targetName),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          };

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: targetPos, zoom: 14),
                markers: markers,
                myLocationEnabled: true,
                onMapCreated: (ctrl) => _mapController = ctrl,
              ),
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$targetName Location', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Lat: ${targetLat.toStringAsFixed(4)}, Lng: ${targetLng.toStringAsFixed(4)}'),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _navigateToLocation(targetLat, targetLng),
                          icon: const Icon(Icons.navigation),
                          label: const Text('Navigate with Google Maps'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
