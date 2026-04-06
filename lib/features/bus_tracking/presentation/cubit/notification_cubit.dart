import 'package:bloc/bloc.dart';
import '../../../../core/services/push_notification_service.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final PushNotificationService _notificationService;

  NotificationCubit({
    required PushNotificationService notificationService,
  })  : _notificationService = notificationService,
        super(NotificationInitial());

  Future<void> sendNotification({
    required String studentId,
    required String parentId,
    required String studentName,
    required String type, // 'NEAR' or 'ARRIVING'
  }) async {
    emit(NotificationSending(studentId));

    final success = await _notificationService.sendDriverNotificationToParent(
      parentId: parentId,
      studentName: studentName,
      notificationType: type,
    );

    if (success) {
      emit(NotificationSentSuccess(studentId));
    } else {
      emit(NotificationSentFailure(studentId, 'Failed to send notification via server.'));
    }
  }
}
