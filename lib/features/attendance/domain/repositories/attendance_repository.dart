import '../models/student_model.dart';
import '../models/attendance_record.dart';

abstract class AttendanceRepository {
  Future<void> recordAttendance(AttendanceRecord record);
  Stream<List<AttendanceRecord>> getStudentAttendance(String studentId);
  Stream<List<StudentModel>> getStudentsByParent(String parentId);
  Future<StudentModel?> getStudentByQrCode(String qrCode);
  Future<void> addStudent(StudentModel student);
  Future<void> updateStudent(StudentModel student);
  Future<void> deleteStudent(String studentId);
  Stream<List<AttendanceRecord>> getDailyAttendance(DateTime date);
  Stream<List<StudentModel>> getStudentsByBus(String busId);
  Future<List<StudentModel>> searchStudents(String query);
}
