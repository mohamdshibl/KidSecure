import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/student_model.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

class FirebaseAttendanceRepository implements AttendanceRepository {
  final FirebaseFirestore _firestore;

  FirebaseAttendanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> recordAttendance(AttendanceRecord record) async {
    await _firestore.collection('attendance').add(record.toMap());
  }

  @override
  Stream<List<AttendanceRecord>> getStudentAttendance(String studentId) {
    return _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort in memory to avoid index requirement
          records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return records;
        });
  }

  @override
  Stream<List<StudentModel>> getStudentsByParent(String parentId) {
    return _firestore
        .collection('students')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<StudentModel?> getStudentByQrCode(
    String qrCode, {
    String? busId,
  }) async {
    var queryRef = _firestore
        .collection('students')
        .where('qrCode', isEqualTo: qrCode);

    if (busId != null) {
      queryRef = queryRef.where('busId', isEqualTo: busId);
    }

    final query = await queryRef.limit(1).get();

    if (query.docs.isEmpty) return null;
    return StudentModel.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  @override
  Future<void> addStudent(StudentModel student) async {
    await _firestore.collection('students').add(student.toMap());
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    await _firestore
        .collection('students')
        .doc(student.id)
        .update(student.toMap());
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    await _firestore.collection('students').doc(studentId).delete();
  }

  @override
  Stream<List<StudentModel>> getStudentsByBus(String busId) {
    return _firestore
        .collection('students')
        .where('busId', isEqualTo: busId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Stream<List<AttendanceRecord>> getDailyAttendance(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('attendance')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Stream<StudentModel?> getStudent(String studentId) {
    return _firestore
        .collection('students')
        .doc(studentId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return StudentModel.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<List<StudentModel>> searchStudents(String query) async {
    if (query.isEmpty) return [];

    final snapshots = await _firestore
        .collection('students')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshots.docs
        .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
