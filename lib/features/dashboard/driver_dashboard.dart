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
  int _selectedIndex = 0;
  bool _isSharingLocation = false;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user!;
    final busId = user.busId ?? 'NOT_ASSIGNED';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeView(busId: busId, isSharingLocation: _isSharingLocation),
            _ProfileView(
              isSharingLocation: _isSharingLocation,
              onSharingLocationChanged: (val) async {
                final locationService = context.read<LocationService>();
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  final String busId;
  final bool isSharingLocation;

  const _HomeView({required this.busId, required this.isSharingLocation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBar(
          title: Text(
            'Bus Driver',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBusInfo(context, busId, isSharingLocation),
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
            ],
          ),
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return _StudentManifestItem(student: students[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBusInfo(BuildContext context, String busId, bool isLive) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [Colors.green.shade600, Colors.green.shade800]
              : [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (isLive
                        ? Colors.green.shade200
                        : Theme.of(context).primaryColor.withOpacity(0.2))
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
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surface,
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

class _ProfileView extends StatelessWidget {
  final bool isSharingLocation;
  final Function(bool) onSharingLocationChanged;

  const _ProfileView({
    required this.isSharingLocation,
    required this.onSharingLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floating: true,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Profile',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileCard(context, user?.name ?? 'Driver'),
                const SizedBox(height: 32),
                _buildSettingsSection(context),
                const SizedBox(height: 48),
                _buildLogoutButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(
              Icons.person_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Bus Driver',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            return _SettingsTile(
              icon: mode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              label: 'Dark Mode',
              trailing: Switch(
                value: mode == ThemeMode.dark,
                onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
              ),
            );
          },
        ),
        _SettingsTile(
          icon: isSharingLocation
              ? Icons.location_on_rounded
              : Icons.location_off_rounded,
          label: 'Location Sharing',
          trailing: Switch(
            value: isSharingLocation,
            onChanged: onSharingLocationChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
          foregroundColor: Theme.of(context).colorScheme.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
