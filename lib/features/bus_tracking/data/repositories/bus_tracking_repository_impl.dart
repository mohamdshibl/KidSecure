import 'package:firebase_database/firebase_database.dart';
import '../../domain/repositories/bus_tracking_repository.dart';
import '../../domain/entities/bus_location.dart';
import '../models/bus_location_model.dart';

class BusTrackingRepositoryImpl implements BusTrackingRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Future<void> updateBusLocation(
    String busId, 
    String driverId, 
    double lat, 
    double lng, 
    bool isTripActive
  ) async {
    final ref = _database.ref('buses/$busId');
    final Map<String, dynamic> data = {
      'driver_id': driverId,
      'trip_active': isTripActive,
      'location': {
        'lat': lat,
        'lng': lng,
        'timestamp': ServerValue.timestamp,
      }
    };
    
    await ref.update(data);
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
    final ref = _database.ref('buses/$busId');
    return ref.onValue.map((event) {
      if (event.snapshot.value == null) {
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
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return BusLocationModel.fromJson(data, busId);
    });
  }
}
