import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../attendance/domain/models/student_model.dart';
import '../attendance/domain/models/attendance_record.dart';
import '../attendance/domain/repositories/attendance_repository.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../../core/theme/theme_cubit.dart';
import '../admin/presentation/widgets/broadcast_banner.dart';
import '../../core/services/location_service.dart';
import '../notifications/domain/models/notification_model.dart';
import '../notifications/domain/repositories/notification_repository.dart';
import 'package:uuid/uuid.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isSharingLocation = false;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user!;
    final busId = user.busId ?? 'NOT_ASSIGNED';
    final locationService = context.read<LocationService>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Bus Driver',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return IconButton(
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                icon: Icon(
                  mode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                tooltip: 'Toggle Theme',
              );
            },
          ),
          Switch(
            value: _isSharingLocation,
            onChanged: (val) async {
              try {
                if (val) {
                  await locationService.startLocationSharing(busId);
                } else {
                  await locationService.stopLocationSharing();
                }
                setState(() => _isSharingLocation = val);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            activeColor: Colors.orange,
          ),
          IconButton(
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBusInfo(busId, _isSharingLocation),
            const SizedBox(height: 24),
            const BroadcastBanner(),
            const SizedBox(height: 16),
            Text(
              'Student Manifest',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<StudentModel>>(
                stream: context.read<AttendanceRepository>().getStudentsByBus(
                  busId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data ?? [];

                  if (students.isEmpty) {
                    return Center(
                      child: Text(
                        'No students assigned to this bus.',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      return _StudentManifestItem(student: students[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusInfo(String busId, bool isLive) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [Colors.green.shade600, Colors.green.shade800]
              : [Colors.orange.shade600, Colors.orange.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isLive ? Colors.green.shade200 : Colors.orange.shade200)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.sensors_rounded : Icons.directions_bus_rounded,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bus ID: $busId',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isLive ? 'Live Tracking Enabled' : 'Live Student List',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentManifestItem extends StatelessWidget {
  final StudentModel student;

  const _StudentManifestItem({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFF1F5F9),
            child: Icon(Icons.person, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                Text(
                  student.grade,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _QuickAttendanceButtons(student: student),
        ],
      ),
    );
  }
}

class _QuickAttendanceButtons extends StatelessWidget {
  final StudentModel student;

  const _QuickAttendanceButtons({required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _record(context, AttendanceStatus.checkIn),
          icon: const Icon(Icons.login_rounded, color: Colors.green),
          tooltip: 'Pick-up',
        ),
        IconButton(
          onPressed: () => _record(context, AttendanceStatus.checkOut),
          icon: const Icon(Icons.logout_rounded, color: Colors.blue),
          tooltip: 'Drop-off',
        ),
      ],
    );
  }

  void _record(BuildContext context, AttendanceStatus status) async {
    final user = context.read<AuthBloc>().state.user!;
    final record = AttendanceRecord(
      id: '',
      studentId: student.id,
      timestamp: DateTime.now(),
      status: status,
      busId: user.busId,
      location: 'Bus Stop',
    );

    try {
      await context.read<AttendanceRepository>().recordAttendance(record);

      if (context.mounted) {
        // Send notification to parent
        final notification = AppNotification(
          id: const Uuid().v4(),
          title: 'تحديث الحافلة',
          body: status == AttendanceStatus.checkIn
              ? 'ركب ${student.name} الحافلة الآن'
              : 'نزل ${student.name} من الحافلة الآن',
          timestamp: DateTime.now(),
          isRead: false,
          type: NotificationType.bus,
          parentId: student.parentId,
          studentId: student.id,
        );

        context.read<NotificationRepository>().sendNotification(notification);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${status == AttendanceStatus.checkIn ? 'Picked up' : 'Dropped off'} successfully',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}
