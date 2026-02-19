import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidsecure/features/admin/domain/models/admin_stats.dart';
import 'package:kidsecure/features/admin/domain/repositories/stats_repository.dart';

class FirebaseStatsRepository implements StatsRepository {
  final FirebaseFirestore _firestore;

  FirebaseStatsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AdminStats> getStats() {
    // Listen to changes in attendance to trigger a refresh of all stats.
    // This provides a "live" feel as attendance is the most frequent activity.
    return _firestore
        .collection('attendance')
        .snapshots()
        .asyncMap((_) => _fetchStats());
  }

  Future<AdminStats> _fetchStats() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      // 1. Total Students
      final totalStudentsQuery = await _firestore
          .collection('students')
          .count()
          .get();
      final totalStudents = totalStudentsQuery.count ?? 0;

      // 2. Today's Attendance
      final presentTodayQuery = await _firestore
          .collection('attendance')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfToday))
          .where('status', isEqualTo: 'checkIn')
          .count()
          .get();
      final presentToday = presentTodayQuery.count ?? 0;

      final absentTodayQuery = await _firestore
          .collection('attendance')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfToday))
          .where('status', isEqualTo: 'absent')
          .count()
          .get();
      final absentToday = absentTodayQuery.count ?? 0;

      // 3. Total Staff (Admins, Gate Officers, Drivers)
      final staffQuery = await _firestore
          .collection('users')
          .where('role', whereIn: ['admin', 'gateOfficer', 'driver'])
          .count()
          .get();
      final totalStaff = staffQuery.count ?? 0;

      // 4. Pending Dismissals
      final pendingDismissalsQuery = await _firestore
          .collection('dismissal_requests')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      final pendingDismissals = pendingDismissalsQuery.count ?? 0;

      // 5. Attendance Trend (Last 7 Days)
      final sevenDaysAgo = startOfToday.subtract(const Duration(days: 6));
      final trendQuery = await _firestore
          .collection('attendance')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          )
          .where('status', isEqualTo: 'checkIn')
          .get();

      final trendMap = <DateTime, int>{};
      for (int i = 0; i < 7; i++) {
        final date = startOfToday.subtract(Duration(days: i));
        trendMap[DateTime(date.year, date.month, date.day)] = 0;
      }

      for (var doc in trendQuery.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
        if (trendMap.containsKey(date)) {
          trendMap[date] = (trendMap[date] ?? 0) + 1;
        }
      }

      final attendanceTrend = trendMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      return AdminStats(
        totalStudents: totalStudents,
        presentToday: presentToday,
        absentToday: absentToday,
        totalStaff: totalStaff,
        pendingDismissals: pendingDismissals,
        attendanceTrend: attendanceTrend.map((e) => e.value).toList(),
      );
    } catch (e) {
      print('Error fetching stats: $e');
      return AdminStats.empty();
    }
  }
}
