import '../entities/bus_location.dart';

abstract class BusTrackingRepository {
  /// Start or update the bus location in Firebase Realtime Database
  Future<void> updateBusLocation(String busId, String driverId, double lat, double lng, bool isTripActive);
  
  /// End the trip, marking trip_active as false
  Future<void> endTrip(String busId);

  /// Stream to listen to real-time bus location updates for parents
  Stream<BusLocationEntity> streamBusLocation(String busId);
}
