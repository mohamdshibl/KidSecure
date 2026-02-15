import '../models/notification_model.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> getNotifications(String parentId);
  Future<void> markAsRead(String notificationId);
  Future<void> deleteNotification(String notificationId);
  Future<void> sendNotification(AppNotification notification);
}
