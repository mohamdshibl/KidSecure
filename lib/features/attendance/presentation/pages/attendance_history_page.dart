import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/student_model.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'سجل الحضور',
          style: GoogleFonts.notoKufiArabic(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<StudentModel>>(
        stream: context.read<AttendanceRepository>().getStudentsByParent(
          user.id,
        ),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = studentSnapshot.data ?? [];

          if (students.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد أبناء مسجلين.',
                style: GoogleFonts.notoKufiArabic(
                  color: const Color(0xFF64748B),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return _StudentAttendanceSection(student: students[index]);
            },
          );
        },
      ),
    );
  }
}

class _StudentAttendanceSection extends StatelessWidget {
  final StudentModel student;

  const _StudentAttendanceSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                student.name,
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<List<AttendanceRecord>>(
          stream: context.read<AttendanceRepository>().getStudentAttendance(
            student.id,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final records = snapshot.data ?? [];

            if (records.isEmpty) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'لا توجد سجلات حضور.',
                    style: GoogleFonts.notoKufiArabic(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: records.take(10).map((record) {
                final isCheckIn = record.status == AttendanceStatus.checkIn;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isCheckIn ? Colors.green : Colors.blue)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCheckIn
                              ? Icons.login_rounded
                              : Icons.logout_rounded,
                          color: isCheckIn ? Colors.green : Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCheckIn ? 'صعود' : 'نزول',
                              style: GoogleFonts.notoKufiArabic(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              record.location ?? '',
                              style: GoogleFonts.notoKufiArabic(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('hh:mm a').format(record.timestamp),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('yyyy/MM/dd').format(record.timestamp),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
