import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../domain/repositories/bus_tracking_repository.dart';
import '../../domain/entities/bus_location.dart';
import 'bus_tracking_state.dart';

class BusTrackingCubit extends Cubit<BusTrackingState> {
  final BusTrackingRepository _repository;
  StreamSubscription<BusLocationEntity>? _subscription;

  BusTrackingCubit({
    required BusTrackingRepository repository,
  })  : _repository = repository,
        super(BusTrackingInitial());

  void subscribeToBus(String busId) {
    emit(BusTrackingLoading());

    _subscription?.cancel();
    _subscription = _repository.streamBusLocation(busId).listen(
      (BusLocationEntity location) {
        if (!location.tripActive) {
          emit(BusTripEnded());
        } else {
          emit(BusTrackingLoaded(location));
        }
      },
      onError: (e) {
        emit(BusTrackingError('Failed to load bus location: $e'));
      },
    );
  }

  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    emit(BusTrackingInitial());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
