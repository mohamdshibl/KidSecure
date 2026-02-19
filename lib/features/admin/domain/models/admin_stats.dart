import 'package:equatable/equatable.dart';

class AdminStats extends Equatable {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final int totalStaff;
  final int pendingDismissals;
  final List<int> attendanceTrend; // Last 7 days

  const AdminStats({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.totalStaff,
    required this.pendingDismissals,
    required this.attendanceTrend,
  });

  factory AdminStats.empty() {
    return const AdminStats(
      totalStudents: 0,
      presentToday: 0,
      absentToday: 0,
      totalStaff: 0,
      pendingDismissals: 0,
      attendanceTrend: [0, 0, 0, 0, 0, 0, 0],
    );
  }

  @override
  List<Object?> get props => [
    totalStudents,
    presentToday,
    absentToday,
    pendingDismissals,
    attendanceTrend,
  ];
}
