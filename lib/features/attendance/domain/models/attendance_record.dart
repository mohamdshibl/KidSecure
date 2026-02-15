import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { checkIn, checkOut, absent }

class AttendanceRecord extends Equatable {
  final String id;
  final String studentId;
  final DateTime timestamp;
  final AttendanceStatus status;
  final String? officerId; // Who registered this (Gate Officer)
  final String? busId; // If registered on a bus
  final String? location;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.timestamp,
    required this.status,
    this.officerId,
    this.busId,
    this.location,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecord(
      id: id,
      studentId: map['studentId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => AttendanceStatus.checkIn,
      ),
      officerId: map['officerId'],
      busId: map['busId'],
      location: map['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.toString().split('.').last,
      'officerId': officerId,
      'busId': busId,
      'location': location,
    };
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    timestamp,
    status,
    officerId,
    busId,
    location,
  ];
}
