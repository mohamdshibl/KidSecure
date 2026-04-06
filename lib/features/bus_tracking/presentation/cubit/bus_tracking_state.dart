import 'package:equatable/equatable.dart';
import '../../domain/entities/bus_location.dart';

abstract class BusTrackingState extends Equatable {
  const BusTrackingState();

  @override
  List<Object?> get props => [];
}

class BusTrackingInitial extends BusTrackingState {}

class BusTrackingLoading extends BusTrackingState {}

class BusTrackingLoaded extends BusTrackingState {
  final BusLocationEntity location;

  const BusTrackingLoaded(this.location);

  @override
  List<Object?> get props => [location];
}

class BusTrackingError extends BusTrackingState {
  final String message;

  const BusTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}

class BusTripEnded extends BusTrackingState {}
