import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

enum ConnectivityStatus { connected, disconnected }

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;

  const ConnectivityState(this.status);

  @override
  List<Object> get props => [status];
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  ConnectivityCubit() : super(const ConnectivityState(ConnectivityStatus.connected)) {
    _init();
  }

  void _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      emit(const ConnectivityState(ConnectivityStatus.disconnected));
    } else {
      emit(const ConnectivityState(ConnectivityStatus.connected));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
