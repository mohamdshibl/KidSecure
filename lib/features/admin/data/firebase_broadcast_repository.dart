import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/broadcast_repository.dart';

class FirebaseBroadcastRepository implements BroadcastRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendBroadcast(BroadcastMessage message) async {
    await _firestore.collection('broadcasts').add(message.toMap());
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
