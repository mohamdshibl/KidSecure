import '../../domain/entities/bus_location.dart';

class BusLocationModel extends BusLocationEntity {
  BusLocationModel({
    required super.busId,
    required super.driverId,
    required super.latitude,
    required super.longitude,
    required super.timestamp,
    required super.tripActive,
  });

  factory BusLocationModel.fromJson(Map<dynamic, dynamic> json, String busId) {
    final locationData = json['location'];
    final Map<dynamic, dynamic>? location = locationData is Map ? locationData.cast<dynamic, dynamic>() : null;
    
    return BusLocationModel(
      busId: busId,
      driverId: json['driver_id']?.toString() ?? '',
      latitude: (location?['lat'] ?? 0.0).toDouble(),
      longitude: (location?['lng'] ?? 0.0).toDouble(),
      timestamp: location?['timestamp'] ?? 0,
      tripActive: json['trip_active'] == true || 
                  json['trip_active'] == 1 || 
                  json['trip_active']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'trip_active': tripActive,
      'location': {
        'lat': latitude,
        'lng': longitude,
        'timestamp': timestamp,
      },
    };
  }

  // Helper method mapping Entity to Model for conversions
  factory BusLocationModel.fromEntity(BusLocationEntity entity) {
    return BusLocationModel(
      busId: entity.busId,
      driverId: entity.driverId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      timestamp: entity.timestamp,
      tripActive: entity.tripActive,
    );
  }
}
