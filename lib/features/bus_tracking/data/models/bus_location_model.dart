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
    return BusLocationModel(
      busId: busId,
      driverId: json['driver_id'] ?? '',
      latitude: (json['location']?['lat'] ?? 0.0).toDouble(),
      longitude: (json['location']?['lng'] ?? 0.0).toDouble(),
      timestamp: json['location']?['timestamp'] ?? 0,
      tripActive: json['trip_active'] ?? false,
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
