import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../attendance/domain/models/student_model.dart';
import '../attendance/domain/models/child_state.dart';
import '../attendance/domain/models/attendance_record.dart';
import '../attendance/domain/repositories/attendance_repository.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/localization/language_cubit.dart';
import '../admin/presentation/widgets/broadcast_banner.dart';
import '../notifications/domain/models/notification_model.dart';
import '../notifications/domain/repositories/notification_repository.dart';
import '../bus_tracking/presentation/cubit/driver_location_cubit.dart';
import '../attendance/domain/repositories/dismissal_repository.dart';
import '../attendance/domain/models/dismissal_request.dart';
import '../../core/services/fcm_v1_service.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_localizations.dart';
import '../attendance/presentation/pages/qr_scanner_page.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;
  bool _isSharingLocation = false;

  Future<void> _toggleLocationSharing(bool val) async {
    final user = context.read<AuthBloc>().state.user!;
    final busId = user.busId ?? 'NOT_ASSIGNED';
    
    try {
      final locationCubit = context.read<DriverLocationCubit>();
      if (val) {
        await locationCubit.startTrip(busId, user.id);
      } else {
        await locationCubit.endTrip();
      }
      if (mounted) setState(() => _isSharingLocation = val);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user!;
    final busId = user.busId ?? 'NOT_ASSIGNED';

    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = _HomeView(busId: busId, isSharingLocation: _isSharingLocation);
        break;
      case 1:
        body = const QrScannerPage();
        break;
      case 2:
        body = _ProfileView(
          isSharingLocation: _isSharingLocation,
          onSharingLocationChanged: _toggleLocationSharing,
        );
        break;
      default:
        body = _HomeView(busId: busId, isSharingLocation: _isSharingLocation);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _selectedIndex == 1 
          ? AppBar(
            title: Text(AppLocalizations.of(context)?.scan ?? 'Scan'),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ) 
          : null,
      drawer: _selectedIndex == 0 ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
            ),
            SwitchListTile(
              secondary: Icon(
                _isSharingLocation ? Icons.location_on : Icons.location_off,
                color: _isSharingLocation ? Colors.green : Colors.grey,
              ),
              title: Text(
                AppLocalizations.of(context)?.startTripStatus ?? 'Trip Status',
              ),
              subtitle: Text(
                _isSharingLocation 
                  ? (AppLocalizations.of(context)?.tripInProgress ?? 'Trip in Progress')
                  : (AppLocalizations.of(context)?.inactive ?? 'Inactive'),
              ),
              value: _isSharingLocation,
              onChanged: _toggleLocationSharing,
            ),
          ],
        ),
      ) : null,
      body: body,
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: AppLocalizations.of(context)?.dashboard ?? 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: AppLocalizations.of(context)?.scan ?? 'Scan',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: AppLocalizations.of(context)?.profile ?? 'Profile',
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
            AppLocalizations.of(context)?.busDriverDashboard ?? 'Bus Driver',
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
              _buildDismissalRequests(context),
              const SizedBox(height: 16),
              const BroadcastBanner(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.studentManifest ??
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
                    AppLocalizations.of(context)?.noStudentsAssigned ??
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

  Widget _buildDismissalRequests(BuildContext context) {
    return StreamBuilder<List<DismissalRequest>>(
      stream: context.read<DismissalRepository>().getRequestsByBus(busId),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hail_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.pickupRequest ?? 'طلبات استلام',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${requests.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120, // Increased height to prevent overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          request.studentName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Waiting at stop',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade900),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                context.read<DismissalRepository>().updateDismissalStatus(
                                  request.id,
                                  DismissalStatus.completed,
                                );
                                
                                // ALSO record check-out to update ChildState to "Left"
                                context.read<AttendanceRepository>().recordAttendance(
                                  AttendanceRecord(
                                    id: const Uuid().v4(),
                                    studentId: request.studentId,
                                    status: AttendanceStatus.checkOut,
                                    timestamp: DateTime.now(),
                                    officerId: context.read<AuthBloc>().state.user!.id,
                                    location: 'Bus Drop-off',
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: Colors.orange.shade900,
                              ),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
          ],
        );
      },
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
                  AppLocalizations.of(context)?.busIdLabel(busId) ??
                      'Bus ID: $busId',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isLive
                      ? (AppLocalizations.of(context)?.liveTrackingEnabled ??
                            'Live Tracking Enabled')
                      : (AppLocalizations.of(context)?.liveStudentList ??
                            'Live Student List'),
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

class _StudentManifestItem extends StatefulWidget {
  final StudentModel student;

  const _StudentManifestItem({required this.student, super.key});

  @override
  State<_StudentManifestItem> createState() => _StudentManifestItemState();
}

class _StudentManifestItemState extends State<_StudentManifestItem> {
  late Stream<List<AttendanceRecord>> _attendanceStream;

  @override
  void initState() {
    super.initState();
    _attendanceStream = context.read<AttendanceRepository>().getStudentAttendance(widget.student.id);
  }

  @override
  void didUpdateWidget(_StudentManifestItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.id != widget.student.id) {
      _attendanceStream = context.read<AttendanceRepository>().getStudentAttendance(widget.student.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _attendanceStream,
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final state = records.resolveChildState();
        final isOnBus = state == ChildState.onBus;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            color: isOnBus 
                ? Colors.green.withOpacity(0.05) 
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOnBus 
                  ? Colors.green.withOpacity(0.2) 
                  : Theme.of(context).dividerColor
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      isOnBus ? Icons.check_circle_rounded : Icons.person,
                      color: isOnBus ? Colors.green : Colors.blue.shade100,
                      size: 20,
                    ),
                  ),
                  if (!isOnBus)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: isOnBus ? Colors.green.shade800 : null,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          widget.student.grade,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(context, state),
                      ],
                    ),
                  ],
                ),
              ),
              _QuickAttendanceButtons(student: widget.student, isOnBus: isOnBus),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, ChildState state) {
    Color color;
    String label;
    
    switch (state) {
      case ChildState.inSchool:
        color = Colors.blue;
        label = AppLocalizations.of(context)?.inSchool ?? 'In School';
        break;
      case ChildState.onBus:
        color = Colors.green;
        label = AppLocalizations.of(context)?.onBus ?? 'On Bus';
        break;
      case ChildState.leftSchool:
        color = Colors.grey;
        label = AppLocalizations.of(context)?.leftSchool ?? 'Left';
        break;
      case ChildState.absent:
        color = Colors.orange;
        label = 'Absent';
        break;
      case ChildState.unknown:
        color = Colors.grey;
        label = AppLocalizations.of(context)?.notSpecified ?? 'Not Specified';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _QuickAttendanceButtons extends StatelessWidget {
  final StudentModel student;
  final bool isOnBus;

  const _QuickAttendanceButtons({
    required this.student, 
    required this.isOnBus
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _notifyArrival(context);
          },
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 22,
          icon: const Icon(
            Icons.notifications_active_rounded,
            color: Colors.orange,
          ),
          tooltip:
              AppLocalizations.of(context)?.notifyNearArrival ??
              'Notify Near Arrival',
        ),
        const SizedBox(width: 4),
        if (!isOnBus) ...[
          IconButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              _record(context, AttendanceStatus.checkIn);
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 22,
            icon: const Icon(Icons.login_rounded, color: Colors.green),
            tooltip: AppLocalizations.of(context)?.pickup ?? 'Pick-up',
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {
              HapticFeedback.vibrate();
              _record(context, AttendanceStatus.checkOut);
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 22,
            icon: const Icon(Icons.logout_rounded, color: Colors.orange),
            tooltip: 'Leave from Bus',
          ),
        ],
        if (isOnBus)
          IconButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              _record(context, AttendanceStatus.checkOut);
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 22,
            icon: const Icon(Icons.logout_rounded, color: Colors.blue),
            tooltip: AppLocalizations.of(context)?.dropoff ?? 'Drop-off',
          ),
      ],
    );
  }

  void _notifyArrival(BuildContext context) {
    final title =
        AppLocalizations.of(context)?.busArrivalAlert ?? 'تنبيه اقتراب الحافلة';
    final body =
        AppLocalizations.of(context)?.busApproachingBody(student.name) ??
        'حافلة ${student.name} تقترب، ستصل خلال دقيقة تقريباً.';

    final notification = AppNotification(
      id: const Uuid().v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.bus,
      parentId: student.parentId,
      studentId: student.id,
    );

    try {
      context.read<NotificationRepository>().sendNotification(notification);

      context.read<FcmV1Service>().sendToParent(
        parentId: student.parentId,
        title: title,
        body: body,
        data: {'type': 'bus', 'studentId': student.id},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.arrivalNotificationSent ??
                'Arrival notification sent',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
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
        final title =
            AppLocalizations.of(context)?.busUpdate ?? 'تحديث الحافلة';
        final body = status == AttendanceStatus.checkIn
            ? (AppLocalizations.of(context)?.onBusNow(student.name) ??
                  'ركب ${student.name} الحافلة الآن')
            : status == AttendanceStatus.checkOut
                ? (AppLocalizations.of(context)?.offBusNow(student.name) ??
                      'نزل ${student.name} من الحافلة الآن')
                : 'تم تسجيل ${student.name} كغائب اليوم'; // Absent body

        final notification = AppNotification(
          id: const Uuid().v4(),
          title: title,
          body: body,
          timestamp: DateTime.now(),
          isRead: false,
          type: NotificationType.bus,
          parentId: student.parentId,
          studentId: student.id,
        );

        context.read<NotificationRepository>().sendNotification(notification);

        context.read<FcmV1Service>().sendToParent(
          parentId: student.parentId,
          title: title,
          body: body,
          data: {
            'type': status == AttendanceStatus.checkIn
                ? 'check_in'
                : 'check_out',
            'studentId': student.id,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == AttendanceStatus.checkIn
                  ? (AppLocalizations.of(context)?.pickedUpSuccessfully ??
                        'Picked up successfully')
                  : status == AttendanceStatus.checkOut
                      ? (AppLocalizations.of(context)?.droppedOffSuccessfully ??
                            'Dropped off successfully')
                      : 'Marked as absent successfully',
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
            AppLocalizations.of(context)?.profile ?? 'Profile',
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
                  AppLocalizations.of(context)?.driver ?? 'Bus Driver',
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
          AppLocalizations.of(context)?.settings ?? 'Settings',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            return _SettingsTile(
              icon: mode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              label: AppLocalizations.of(context)?.darkMode ?? 'Dark Mode',
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
          label: AppLocalizations.of(context)?.startTripStatus ?? 'Location Sharing',
          trailing: Switch(
            value: isSharingLocation,
            onChanged: onSharingLocationChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ),
        BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) {
            return _SettingsTile(
              icon: Icons.language_rounded,
              label: AppLocalizations.of(context)?.language ?? 'Language',
              trailing: Switch(
                value: locale.languageCode == 'en',
                onChanged: (_) =>
                    context.read<LanguageCubit>().toggleLanguage(),
                activeColor: Theme.of(context).primaryColor,
              ),
            );
          },
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
        label: Text(AppLocalizations.of(context)?.logout ?? 'Logout'),
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
