import '../models/dismissal_request.dart';

abstract class DismissalRepository {
  Future<void> requestDismissal(DismissalRequest request);
  Future<void> updateDismissalStatus(String requestId, DismissalStatus status);
  Stream<List<DismissalRequest>> getActiveRequests();
  Stream<List<DismissalRequest>> getRequestsHistory();
}
