import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/repositories/bus_tracking_repository.dart';
import 'driver_location_state.dart';

class DriverLocationCubit extends Cubit<DriverLocationState> {
  final LocationService _locationService;
  final BusTrackingRepository _repository;
  
  StreamSubscription<Position>? _positionSubscription;
  String? _currentBusId;

  DriverLocationCubit({
    required LocationService locationService,
    required BusTrackingRepository repository,
  })  : _locationService = locationService,
        _repository = repository,
        super(DriverLocationInitial());

  Future<void> startTrip(String busId, String driverId) async {
    try {
      final hasPermission = await _locationService.handleLocationPermission();
      if (!hasPermission) {
        emit(const DriverLocationError('Location permissions denied'));
        return;
      }

      _currentBusId = busId;

      // Get initial position asynchronously so we don't block the UI switch
      _locationService.getCurrentPosition().then((initialPosition) {
        if (initialPosition != null && _currentBusId == busId) {
          _repository.updateBusLocation(
            busId,
            driverId,
            initialPosition.latitude,
            initialPosition.longitude,
            true,
          );
        }
      }).catchError((_) {});

      _positionSubscription = _locationService.streamLocation().listen(
        (Position position) async {
          // Update Firebase Realtime Database on subsequent movements
          await _repository.updateBusLocation(
            busId,
            driverId,
            position.latitude,
            position.longitude,
            true, // Trip is active
          );

          emit(DriverLocationTracking(position.latitude, position.longitude));
        },
        onError: (e) {
          emit(DriverLocationError('Error streaming location: $e'));
        },
      );
    } catch (e) {
      emit(DriverLocationError('Failed to start tracking: $e'));
    }
  }

  Future<void> endTrip() async {
    try {
      if (_currentBusId != null) {
        await _repository.endTrip(_currentBusId!);
      }
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _currentBusId = null;
      emit(DriverLocationStopped());
    } catch (e) {
      emit(DriverLocationError('Failed to stop trip: $e'));
    }
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
