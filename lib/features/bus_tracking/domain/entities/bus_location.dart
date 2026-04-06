class BusLocationEntity {
  final String busId;
  final String driverId;
  final double latitude;
  final double longitude;
  final int timestamp;
  final bool tripActive;

  BusLocationEntity({
    required this.busId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.tripActive,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is BusLocationEntity &&
      other.busId == busId &&
      other.driverId == driverId &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.timestamp == timestamp &&
      other.tripActive == tripActive;
  }

  @override
  int get hashCode {
    return busId.hashCode ^
      driverId.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      timestamp.hashCode ^
      tripActive.hashCode;
  }
}
