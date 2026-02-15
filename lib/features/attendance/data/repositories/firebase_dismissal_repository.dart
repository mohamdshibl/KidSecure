import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/dismissal_request.dart';
import '../../domain/repositories/dismissal_repository.dart';

class FirebaseDismissalRepository implements DismissalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> requestDismissal(DismissalRequest request) async {
    await _firestore.collection('dismissal_requests').add(request.toMap());
  }

  @override
  Future<void> updateDismissalStatus(
    String requestId,
    DismissalStatus status,
  ) async {
    await _firestore.collection('dismissal_requests').doc(requestId).update({
      'status': status.toString().split('.').last,
    });
  }

  @override
  Stream<List<DismissalRequest>> getActiveRequests() {
    return _firestore
        .collection('dismissal_requests')
        .where(
          'status',
          whereIn: [
            DismissalStatus.pending.toString().split('.').last,
            DismissalStatus.arrivingSoon.toString().split('.').last,
            DismissalStatus.atGate.toString().split('.').last,
          ],
        )
        // Note: Ordering might require an index in Firestore since we use a whereIn and orderBy
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DismissalRequest.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  @override
  Stream<List<DismissalRequest>> getRequestsHistory() {
    return _firestore
        .collection('dismissal_requests')
        .where(
          'status',
          whereIn: [
            DismissalStatus.completed.toString().split('.').last,
            DismissalStatus.cancelled.toString().split('.').last,
          ],
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DismissalRequest.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}
