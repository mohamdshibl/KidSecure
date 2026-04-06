import 'package:equatable/equatable.dart';

abstract class DriverLocationState extends Equatable {
  const DriverLocationState();

  @override
  List<Object?> get props => [];
}

class DriverLocationInitial extends DriverLocationState {}

class DriverLocationTracking extends DriverLocationState {
  final double currentLat;
  final double currentLng;

  const DriverLocationTracking(this.currentLat, this.currentLng);

  @override
  List<Object?> get props => [currentLat, currentLng];
}

class DriverLocationError extends DriverLocationState {
  final String message;

  const DriverLocationError(this.message);

  @override
  List<Object?> get props => [message];
}

class DriverLocationStopped extends DriverLocationState {}
