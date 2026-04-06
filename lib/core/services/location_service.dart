import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Checks if location services are enabled and permissions are granted
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false; // Location services are disabled.
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // Location permissions are denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false; // Location permissions are permanently denied
    }

    return true; // All clear
  }

  /// Gets the current position once
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Streams position continuously with distance filters
  Stream<Position> streamLocation() {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Only notify if moved by 10 meters
        intervalDuration: Duration(seconds: 5), // Update frequently
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: "KidSecure is sharing bus location for parents",
          notificationTitle: "Location Sharing Active",
          enableWakeLock: true,
        ),
      ),
    );
  }
}
