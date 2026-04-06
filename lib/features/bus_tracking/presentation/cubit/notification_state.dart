import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationSending extends NotificationState {
  final String studentId;
  const NotificationSending(this.studentId);
  
  @override
  List<Object?> get props => [studentId];
}

class NotificationSentSuccess extends NotificationState {
  final String studentId;
  const NotificationSentSuccess(this.studentId);
  
  @override
  List<Object?> get props => [studentId];
}

class NotificationSentFailure extends NotificationState {
  final String studentId;
  final String error;
  const NotificationSentFailure(this.studentId, this.error);
  
  @override
  List<Object?> get props => [studentId, error];
}
