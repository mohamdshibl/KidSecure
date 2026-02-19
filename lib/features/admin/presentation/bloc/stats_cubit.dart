import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kidsecure/features/admin/domain/models/admin_stats.dart';
import 'package:kidsecure/features/admin/domain/repositories/stats_repository.dart';

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final AdminStats stats;
  const StatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class StatsError extends StatsState {
  final String message;
  const StatsError(this.message);

  @override
  List<Object?> get props => [message];
}

class StatsCubit extends Cubit<StatsState> {
  final StatsRepository _repository;

  StatsCubit(this._repository) : super(StatsInitial());

  void loadStats() {
    emit(StatsLoading());
    _repository.getStats().listen(
      (stats) => emit(StatsLoaded(stats)),
      onError: (error) => emit(StatsError(error.toString())),
    );
  }
}
