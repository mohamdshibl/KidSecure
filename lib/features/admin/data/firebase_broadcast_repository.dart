import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/broadcast_repository.dart';
import '../../../../core/services/fcm_v1_service.dart';

class FirebaseBroadcastRepository implements BroadcastRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FcmV1Service _fcmV1Service;

  FirebaseBroadcastRepository(this._fcmV1Service);

  @override
  Future<void> sendBroadcast(BroadcastMessage message) async {
    // 1. Save to Firestore
    await _firestore.collection('broadcasts').add(message.toMap());

    // 2. Send Push Notification
    String topic = 'all_users';
    
    // Customize topic based on target if needed
    switch (message.target) {
      case BroadcastTarget.parents:
        topic = 'parents';
        break;
      case BroadcastTarget.drivers:
        topic = 'drivers';
        break;
      case BroadcastTarget.gateOfficers:
        topic = 'gate_officers';
        break;
      case BroadcastTarget.all:
      default:
        topic = 'all_users';
    }

    await _fcmV1Service.sendToTopic(
      topic: topic,
      title: message.title,
      body: message.body,
      data: {
        'type': 'broadcast',
        'broadcast_id': message.id,
      },
    );
  }

  @override
  Stream<List<BroadcastMessage>> getBroadcasts() {
    return _firestore
        .collection('broadcasts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BroadcastMessage.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<void> deleteBroadcast(String id) async {
    await _firestore.collection('broadcasts').doc(id).delete();
  }
}
