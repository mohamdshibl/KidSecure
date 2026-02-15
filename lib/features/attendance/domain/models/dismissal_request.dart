import 'package:cloud_firestore/cloud_firestore.dart';

enum DismissalStatus { pending, arrivingSoon, atGate, completed, cancelled }

class DismissalRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String studentGrade;
  final String parentId;
  final String parentName;
  final String? driverId;
  final String? driverName;
  final DismissalStatus status;
  final DateTime timestamp;
  final String? eta; // Estimated Time of Arrival, e.g. "2 min"

  DismissalRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.parentId,
    required this.parentName,
    this.driverId,
    this.driverName,
    required this.status,
    required this.timestamp,
    this.eta,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentGrade': studentGrade,
      'parentId': parentId,
      'parentName': parentName,
      'driverId': driverId,
      'driverName': driverName,
      'status': status.toString().split('.').last,
      'timestamp': FieldValue.serverTimestamp(),
      'eta': eta,
    };
  }

  factory DismissalRequest.fromMap(String id, Map<String, dynamic> map) {
    return DismissalRequest(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentGrade: map['studentGrade'] ?? '',
      parentId: map['parentId'] ?? '',
      parentName: map['parentName'] ?? '',
      driverId: map['driverId'],
      driverName: map['driverName'],
      status: DismissalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => DismissalStatus.pending,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eta: map['eta'],
    );
  }
}
