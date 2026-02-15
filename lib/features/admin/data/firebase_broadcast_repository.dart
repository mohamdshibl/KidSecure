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
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return BroadcastMessage(
              id: doc.id,
              title: data['title'] ?? '',
              body: data['body'] ?? '',
              target: BroadcastTarget.values.firstWhere(
                (e) => e.toString().split('.').last == data['target'],
                orElse: () => BroadcastTarget.all,
              ),
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              senderId: data['senderId'] ?? '',
            );
          }).toList();
        });
  }
}
