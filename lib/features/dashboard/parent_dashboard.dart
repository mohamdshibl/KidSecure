import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../attendance/domain/models/student_model.dart';
import '../attendance/domain/repositories/attendance_repository.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/localization/language_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../admin/presentation/widgets/broadcast_banner.dart';
import '../attendance/domain/models/dismissal_request.dart';
import '../attendance/domain/models/attendance_record.dart';
import '../attendance/domain/models/child_state.dart';
import '../attendance/domain/repositories/dismissal_repository.dart';
import '../notifications/presentation/pages/notifications_history_page.dart';
import '../tracking/presentation/pages/bus_tracking_page.dart';
import '../notifications/domain/models/notification_model.dart';
import '../notifications/domain/repositories/notification_repository.dart';
import '../../core/services/fcm_v1_service.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  late final Stream<List<StudentModel>> _studentsStream;
  late final Stream<List<AppNotification>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    final user = context.read<AuthBloc>().state.user!;
    setState(() {
      _studentsStream = context.read<AttendanceRepository>().getStudentsByParent(
        user.id,
      );
      _notificationsStream = context
          .read<NotificationRepository>()
          .getNotifications(user.id);
    });
  }

  Future<void> _onRefresh() async {
    _initStreams();
    // Small delay to make the spinner visible if the stream updates instantly
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user!;

    return StreamBuilder<List<StudentModel>>(
      stream: _studentsStream,
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];
        final busId = students.isNotEmpty ? students.first.busId : null;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _HomeView(
                  user: user,
                  students: students,
                  onTrackBus: () => setState(() => _selectedIndex = 2),
                  onRefresh: _onRefresh,
                ),
                const NotificationsHistoryPage(),
                busId != null
                    ? BusTrackingPage(busId: busId)
                    : _NoBusAssigned(),
                _ProfileView(user: user),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
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
        selectedLabelStyle: GoogleFonts.notoKufiArabic(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.notoKufiArabic(fontSize: 12),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: AppLocalizations.of(context)?.home ?? 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_rounded),
                Positioned(
                  right: 0,
                  top: 0,
                  child: StreamBuilder<List<AppNotification>>(
                    stream: _notificationsStream,
                    builder: (context, snapshot) {
                      final hasUnread =
                          snapshot.data?.any((n) => !n.isRead) ?? false;
                      if (!hasUnread) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                Theme.of(context).cardTheme.color ??
                                const Color(0xFF1E293B),
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            label: AppLocalizations.of(context)?.notifications ?? 'التنبيهات',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_rounded),
            label: AppLocalizations.of(context)?.tracking ?? 'تتبع',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: AppLocalizations.of(context)?.profile ?? 'الملف',
          ),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  final dynamic user;
  final List<StudentModel> students;
  final VoidCallback onTrackBus;
  final RefreshCallback onRefresh;
  const _HomeView({
    required this.user,
    required this.students,
    required this.onTrackBus,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).primaryColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, user.name),
              const SizedBox(height: 24),
              const BroadcastBanner(),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)?.children ?? 'أبنائي',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (students.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: _EmptyDashboard(),
                ))
              else
                ...students.map((student) => _StudentCard(student: student)),
              const SizedBox(height: 32),
              _QuickActions(onTrackBus: onTrackBus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.of(context)?.welcome ?? 'أهلاً بك'}، $name',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "تابع سلامة أبنائك بانتظام.",
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            return IconButton(
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              icon: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: mode == ThemeMode.dark
                    ? Colors.amber
                    : Theme.of(context).primaryColor,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  final dynamic user;
  const _ProfileView({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
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
                        user.name,
                        style: GoogleFonts.notoKufiArabic(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)?.parent ?? 'ولي أمر',
                        style: GoogleFonts.notoKufiArabic(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _ProfileTile(
            icon: Icons.dark_mode_rounded,
            title: AppLocalizations.of(context)?.darkMode ?? 'المظهر الداكن',
            trailing: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) {
                return Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                  activeColor: Theme.of(context).primaryColor,
                );
              },
            ),
          ),
          _ProfileTile(
            icon: Icons.language_rounded,
            title: AppLocalizations.of(context)?.language ?? 'اللغة',
            trailing: BlocBuilder<LanguageCubit, Locale>(
              builder: (context, locale) {
                return Switch(
                  value: locale.languageCode == 'en',
                  onChanged: (_) => context.read<LanguageCubit>().toggleLanguage(),
                  activeColor: Theme.of(context).primaryColor,
                );
              },
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthLogoutRequested()),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                AppLocalizations.of(context)?.logout ?? 'تسجيل الخروج',
                style: GoogleFonts.notoKufiArabic(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: GoogleFonts.notoKufiArabic(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/student-details', extra: student),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'الصف: ${student.grade}',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _LiveStatusBadge(studentId: student.id),
            ],
          ),
          _DismissalActions(student: student),
        ],
      ),
    );
  }
}

class _DismissalActions extends StatefulWidget {
  final StudentModel student;

  const _DismissalActions({required this.student});

  @override
  State<_DismissalActions> createState() => _DismissalActionsState();
}

class _DismissalActionsState extends State<_DismissalActions> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    final parentId = context.read<AuthBloc>().state.user?.id ?? '';
    return StreamBuilder<DismissalRequest?>(
      stream: context.read<DismissalRepository>().getActiveRequestForStudent(
        widget.student.id,
        parentId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('DismissalActions Stream Error: ${snapshot.error}');
          // If there's a permission error, do not hide the widget entirely.
          // Fall through so the pickup button stays visible.
        }
        final activeRequest = snapshot.data;

        return StreamBuilder<List<AttendanceRecord>>(
          stream: context.read<AttendanceRepository>().getStudentAttendance(widget.student.id),
          builder: (context, attendanceSnapshot) {
            final childState = (attendanceSnapshot.data ?? []).resolveChildState();
            
            // Only hide the button if the child has already left or is absent.
            // When the child is onBus, the parent SHOULD be able to request pickup.
            if (activeRequest == null &&
                (childState == ChildState.leftSchool ||
                    childState == ChildState.absent)) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: (activeRequest != null || _isRequesting)
                        ? _buildStatusIndicator(
                            context,
                            activeRequest ??
                                DismissalRequest(
                                  id: '',
                                  studentId: widget.student.id,
                                  studentName: widget.student.name,
                                  studentGrade: widget.student.grade,
                                  parentId: parentId,
                                  parentName: '',
                                  status: DismissalStatus.pending,
                                  timestamp: DateTime.now(),
                                ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () async {
                              final parent = context.read<AuthBloc>().state.user!;
                              
                              setState(() => _isRequesting = true);
                              
                              // Logic to determine if child is on bus and which bus
                              final attendanceRecords = attendanceSnapshot.data ?? [];
                              final sortedRecords = attendanceRecords.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                              final latestRecord = sortedRecords.isNotEmpty ? sortedRecords.first : null;
                              final busId = childState == ChildState.onBus ? latestRecord?.busId : null;

                              final request = DismissalRequest(
                                id: '',
                                studentId: widget.student.id,
                                studentName: widget.student.name,
                                studentGrade: widget.student.grade,
                                parentId: parent.id,
                                parentName: parent.name,
                                busId: busId, // Route to bus if on board
                                status: DismissalStatus.pending,
                                timestamp: DateTime.now(),
                              );

                              try {
                                await context
                                    .read<DismissalRepository>()
                                    .requestDismissal(request);
                                
                                // Send push notification to routing target
                                if (context.mounted) {
                                  final fcmService = context.read<FcmV1Service>();
                                  if (busId != null) {
                                    await fcmService.sendToBus(
                                      busId: busId,
                                      title: 'Pickup Request',
                                      body: 'Parent of ${widget.student.name} is waiting at the stop.',
                                      data: {'type': 'pickup', 'studentId': widget.student.id},
                                    );
                                  } else {
                                    // Optionally send to gate tokens if you have them, 
                                    // but usually Gate Officers listen to the live stream.
                                  }
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)
                                                ?.requestSentSuccessfully ??
                                            'تم إرسال طلب الانصراف بنجاح!',
                                        style: GoogleFonts.notoKufiArabic(),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isRequesting = false);
                                }
                              }
                            },
                            icon: const Icon(Icons.hail_rounded, size: 18),
                            label: Text(
                              AppLocalizations.of(context)?.pickupRequest ??
                                  'طلب استلام',
                              style: GoogleFonts.notoKufiArabic(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusIndicator(BuildContext context, DismissalRequest request) {
    final color = _getStatusColor(request.status);
    final label = _getStatusText(context, request.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.notoKufiArabic(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (request.eta != null) ...[
            const Spacer(),
            Text(
              request.eta!,
              style: GoogleFonts.notoKufiArabic(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(DismissalStatus status) {
    switch (status) {
      case DismissalStatus.pending:
        return Colors.grey;
      case DismissalStatus.arrivingSoon:
        return Colors.orange;
      case DismissalStatus.atGate:
        return Colors.blue;
      case DismissalStatus.completed:
        return Colors.green;
      case DismissalStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(BuildContext context, DismissalStatus status) {
    switch (status) {
      case DismissalStatus.pending:
        return AppLocalizations.of(context)?.pending ?? 'Pending';
      case DismissalStatus.arrivingSoon:
        return AppLocalizations.of(context)?.arrivingSoon ?? 'Arriving Soon';
      case DismissalStatus.atGate:
        return AppLocalizations.of(context)?.atGate ?? 'At Gate';
      case DismissalStatus.completed:
        return AppLocalizations.of(context)?.completed ?? 'Completed';
      case DismissalStatus.cancelled:
        return AppLocalizations.of(context)?.cancelled ?? 'Cancelled';
    }
  }
}


class _LiveStatusBadge extends StatelessWidget {
  final String studentId;

  const _LiveStatusBadge({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: context.read<AttendanceRepository>().getStudentAttendance(studentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Attendance Stream Error: ${snapshot.error}');
          // Show a neutral badge instead of exposing a raw error
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              AppLocalizations.of(context)?.notSpecified ?? 'Not Specified',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final records = snapshot.data ?? [];
        final childState = records.resolveChildState();
        final label = _labelForState(context, childState);
        final color = _colorForState(childState);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: GoogleFonts.notoKufiArabic(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        );
      },
    );
  }

  String _labelForState(BuildContext context, ChildState state) {
    switch (state) {
      case ChildState.inSchool:
        return AppLocalizations.of(context)?.inSchool ?? 'In School';
      case ChildState.onBus:
        return AppLocalizations.of(context)?.onBus ?? 'On Bus';
      case ChildState.leftSchool:
        return AppLocalizations.of(context)?.leftSchool ?? 'Left';
      case ChildState.absent:
        return 'Absent';
      case ChildState.unknown:
        return AppLocalizations.of(context)?.notSpecified ?? 'Not Specified';
    }
  }

  Color _colorForState(ChildState state) {
    switch (state) {
      case ChildState.inSchool:
        return Colors.green;
      case ChildState.onBus:
        return Colors.orange;
      case ChildState.leftSchool:
        return Colors.blue;
      case ChildState.absent:
        return Colors.orange;
      case ChildState.unknown:
        return Colors.grey;
    }
  }
}

class _EmptyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_care_rounded,
            size: 64,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لم يتم تسجيل أبناء بعد.',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () => context.push('/add-student'),
            child: Text('أضف ابنك الأول', style: GoogleFonts.notoKufiArabic()),
          ),
        ],
      ),
    );
  }
}

class _NoBusAssigned extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_rounded,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد حافلة مسجلة',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم تعيين حافلة لأبنائك بعد.',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onTrackBus;
  const _QuickActions({required this.onTrackBus});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.quickActions ?? 'إجراءات سريعة',
          style: GoogleFonts.notoKufiArabic(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _ActionItem(
              icon: Icons.bus_alert_rounded,
              label: AppLocalizations.of(context)?.trackBus ?? 'تتبع الحافلة',
              color: Colors.blue,
              onTap: onTrackBus,
            ),
            const SizedBox(width: 16),
            _ActionItem(
              icon: Icons.history_rounded,
              label: AppLocalizations.of(context)?.history ?? 'السجل',
              color: Colors.orange,
              onTap: () => context.push('/attendance-history'),
            ),
            const SizedBox(width: 16),
            _ActionItem(
              icon: Icons.person_add_alt_1_rounded,
              label: AppLocalizations.of(context)?.addStudent ?? 'أضف طفل',
              color: Colors.purple,
              onTap: () => context.push('/add-student'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
