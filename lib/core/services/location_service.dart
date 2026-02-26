import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSubscription;

  Future<void> startLocationSharing(String busId) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // Optimized location settings for school bus tracking
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 30, // Update every 30 meters
      intervalDuration: const Duration(seconds: 15), // Min 15s between updates
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "KidSecure is sharing bus location for parents",
        notificationTitle: "Location Sharing Active",
        enableWakeLock: true,
      ),
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _updateFirestoreLocation(busId, position);
          },
        );
  }

  Future<void> stopLocationSharing() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _updateFirestoreLocation(String busId, Position position) async {
    await _firestore.collection('bus_locations').doc(busId).set({
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'busId': busId,
    });
  }

  Stream<DocumentSnapshot> getBusLocation(String busId) {
    return _firestore.collection('bus_locations').doc(busId).snapshots();
  }
}
