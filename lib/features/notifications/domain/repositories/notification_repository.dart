import '../models/notification_model.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> getNotifications(String parentId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String parentId);
  Future<void> deleteNotification(String notificationId);
  Future<void> deleteAll(String parentId);
  Future<void> sendNotification(AppNotification notification);
}
