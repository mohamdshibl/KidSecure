import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/notification_model.dart';
import '../domain/repositories/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<AppNotification>> getNotifications(String parentId) {
    return _firestore
        .collection('notifications')
        .where('parentId', isEqualTo: parentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AppNotification.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  @override
  Future<void> sendNotification(AppNotification notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
  }
}
