import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<void> updateFirestoreLocation(double lat, double lng) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'latitude': lat,
        'longitude': lng,
      });
    } catch (e) {
      debugPrint('Error updating location in Firestore: $e');
    }
  }

  void startTracking() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update only if moved by 10 meters
    );

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      updateFirestoreLocation(position.latitude, position.longitude);
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
