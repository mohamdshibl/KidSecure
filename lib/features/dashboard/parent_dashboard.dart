import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../attendance/domain/models/student_model.dart';
import '../attendance/domain/repositories/attendance_repository.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../../core/theme/theme_cubit.dart';
import '../admin/presentation/widgets/broadcast_banner.dart';
import '../attendance/domain/models/dismissal_request.dart';
import '../attendance/domain/repositories/dismissal_repository.dart';
import '../notifications/presentation/pages/notifications_history_page.dart';
import '../tracking/presentation/pages/bus_tracking_page.dart';
import '../notifications/domain/models/notification_model.dart';
import '../notifications/domain/repositories/notification_repository.dart';

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
    final user = context.read<AuthBloc>().state.user!;
    _studentsStream = context.read<AttendanceRepository>().getStudentsByParent(
      user.id,
    );
    _notificationsStream = context
        .read<NotificationRepository>()
        .getNotifications(user.id);
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
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
            label: 'التنبيهات',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'تتبع',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'الملف',
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
  const _HomeView({
    required this.user,
    required this.students,
    required this.onTrackBus,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return _EmptyDashboard();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, user.name),
          const SizedBox(height: 24),
          const BroadcastBanner(),
          const SizedBox(height: 24),
          Text(
            'أبنائي',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...students.map((student) => _StudentCard(student: student)),
          const SizedBox(height: 32),
          _QuickActions(onTrackBus: onTrackBus),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلاً بك، $name',
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
                        'ولي أمر',
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
            icon: Icons.settings_rounded,
            title: 'الإعدادات',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.dark_mode_rounded,
            title: 'المظهر الداكن',
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
            icon: Icons.help_outline_rounded,
            title: 'مركز المساعدة',
            onTap: () {},
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthLogoutRequested()),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'تسجيل الخروج',
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
              const _StatusBadge(status: 'في المدرسة'),
            ],
          ),
          _DismissalActions(student: student),
        ],
      ),
    );
  }
}

class _DismissalActions extends StatelessWidget {
  final StudentModel student;

  const _DismissalActions({required this.student});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final parent = context.read<AuthBloc>().state.user!;
                final request = DismissalRequest(
                  id: '',
                  studentId: student.id,
                  studentName: student.name,
                  studentGrade: student.grade,
                  parentId: parent.id,
                  parentName: parent.name,
                  status: DismissalStatus.pending,
                  timestamp: DateTime.now(),
                );

                try {
                  await context.read<DismissalRepository>().requestDismissal(
                    request,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم إرسال طلب الانصراف بنجاح!',
                          style: GoogleFonts.notoKufiArabic(),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                  }
                }
              },
              icon: const Icon(Icons.hail_rounded, size: 18),
              label: Text(
                'طلب استلام',
                style: GoogleFonts.notoKufiArabic(fontWeight: FontWeight.bold),
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
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: GoogleFonts.notoKufiArabic(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
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
          'إجراءات سريعة',
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
              label: 'تتبع الحافلة',
              color: Colors.blue,
              onTap: onTrackBus,
            ),
            const SizedBox(width: 16),
            _ActionItem(
              icon: Icons.history_rounded,
              label: 'السجل',
              color: Colors.orange,
              onTap: () => context.push('/attendance-history'),
            ),
            const SizedBox(width: 16),
            _ActionItem(
              icon: Icons.person_add_alt_1_rounded,
              label: 'أضف طفل',
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
