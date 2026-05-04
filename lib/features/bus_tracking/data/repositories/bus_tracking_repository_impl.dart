import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../domain/repositories/bus_tracking_repository.dart';
import '../../domain/entities/bus_location.dart';
import '../models/bus_location_model.dart';

class BusTrackingRepositoryImpl implements BusTrackingRepository {
  final FirebaseDatabase _database;

  BusTrackingRepositoryImpl({String? databaseURL}) 
    : _database = databaseURL != null 
        ? FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: databaseURL)
        : FirebaseDatabase.instance;

  @override
  Future<void> updateBusLocation(
    String busId, 
    String driverId, 
    double lat, 
    double lng, 
    bool isTripActive
  ) async {
    final normalizedBusId = busId.trim().toLowerCase();
    final ref = _database.ref('buses/$normalizedBusId');
    final Map<String, dynamic> data = {
      'driver_id': driverId,
      'trip_active': isTripActive,
      'location': {
        'lat': lat,
        'lng': lng,
        'timestamp': ServerValue.timestamp,
      }
    };
    
    try {
      debugPrint('[BusRepo] Updating Firebase RTDB for bus: $busId (Lat: $lat, Lng: $lng)');
      // Add timeout to prevent hanging if the database URL is wrong or rules block the write
      await ref.update(data).timeout(const Duration(seconds: 5));
      debugPrint('[BusRepo] Update successful for bus: $busId');
    } catch (e) {
      debugPrint('[BusRepo] FAILED to update Firebase RTDB: $e');
    }
  }

  @override
  Future<void> endTrip(String busId) async {
    final ref = _database.ref('buses/$busId');
    await ref.update({
      'trip_active': false,
    });
  }

  @override
  Stream<BusLocationEntity> streamBusLocation(String busId) {
    final normalizedBusId = busId.trim().toLowerCase();
    final ref = _database.ref('buses/$normalizedBusId');
    debugPrint('Streaming bus location from path: buses/$normalizedBusId');
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) {
        // Return an "offline" state instead of throwing an exception
        return BusLocationEntity(
          busId: busId,
          driverId: '',
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          tripActive: false,
        );
      }
      
      try {
        final Map<dynamic, dynamic> data = (value as Map).cast<dynamic, dynamic>();
        return BusLocationModel.fromJson(data, busId);
      } catch (e) {
        debugPrint('Error parsing bus location for $busId: $e');
        debugPrint('Raw value: $value');
        return BusLocationEntity(
          busId: busId,
          driverId: '',
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          tripActive: false,
        );
      }
    });
  }
}
