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
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => DismissalRequest.fromMap(doc.id, doc.data()))
              .where((req) => req.busId == null) // Show only non-bus requests
              .toList();

          // Sort in memory to avoid index requirements
          requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return requests;
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
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            return DismissalRequest.fromMap(doc.id, doc.data());
          }).toList();
          // Sort in memory to avoid index requirements
          requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return requests;
        });
  }

  @override
  Stream<DismissalRequest?> getActiveRequestForStudent(
    String studentId,
    String parentId,
  ) {
    return _firestore
        .collection('dismissal_requests')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;

          final activeStatuses = [
            DismissalStatus.pending.toString().split('.').last,
            DismissalStatus.arrivingSoon.toString().split('.').last,
            DismissalStatus.atGate.toString().split('.').last,
          ];

          final activeDocs = snapshot.docs.where((doc) {
            final data = doc.data();
            final status = data['status'] as String?;
            final docStudentId = data['studentId'] as String?;
            return studentId == docStudentId && activeStatuses.contains(status);
          }).toList();

          if (activeDocs.isEmpty) return null;

          // Sort by timestamp to get the latest active request
          activeDocs.sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aTime = aData['timestamp'] as Timestamp?;
            final bTime = bData['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          final doc = activeDocs.first;
          return DismissalRequest.fromMap(doc.id, doc.data());
        });
  }

  @override
  Stream<List<DismissalRequest>> getRequestsByBus(String busId) {
    return _firestore
        .collection('dismissal_requests')
        .where('busId', isEqualTo: busId)
        .snapshots()
        .map((snapshot) {
          final activeStatuses = [
            DismissalStatus.pending.toString().split('.').last,
            DismissalStatus.arrivingSoon.toString().split('.').last,
            DismissalStatus.atGate.toString().split('.').last,
          ];

          final requests = snapshot.docs
              .map((doc) => DismissalRequest.fromMap(doc.id, doc.data()))
              .where(
                (req) => activeStatuses.contains(
                  req.status.toString().split('.').last,
                ),
              )
              .toList();

          requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return requests;
        });
  }
}
