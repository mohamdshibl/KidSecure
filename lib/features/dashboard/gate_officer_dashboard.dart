import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kidsecure/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kidsecure/features/auth/presentation/bloc/auth_event.dart';
import 'package:kidsecure/features/attendance/domain/models/dismissal_request.dart';
import 'package:kidsecure/features/attendance/domain/repositories/dismissal_repository.dart';
import 'package:kidsecure/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:kidsecure/features/attendance/domain/models/student_model.dart';
import 'package:kidsecure/features/attendance/domain/models/attendance_record.dart';
import 'package:kidsecure/core/theme/theme_cubit.dart';
import 'package:kidsecure/core/localization/language_cubit.dart';
import 'package:kidsecure/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:kidsecure/core/services/fcm_v1_service.dart';
import 'package:kidsecure/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kidsecure/features/notifications/domain/models/notification_model.dart';

class GateOfficerDashboard extends StatefulWidget {
  const GateOfficerDashboard({super.key});

  @override
  State<GateOfficerDashboard> createState() => _GateOfficerDashboardState();
}

class _GateOfficerDashboardState extends State<GateOfficerDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _RequestsView(),
            _HistoryView(),
            _ScannerView(),
            _ProfileView(),
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
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
            icon: const Icon(Icons.list_alt_rounded),
            label: AppLocalizations.of(context)?.requests ?? 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            label: AppLocalizations.of(context)?.history ?? 'السجل',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: AppLocalizations.of(context)?.scanner ?? 'ماسح',
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

class _RequestsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(child: _buildSearchBar(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'طلبات نشطة'),
          ),
        ),
        _buildRequestsList(context),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(child: _buildRadarSection(context)),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floating: true,
      elevation: 0,
      centerTitle: true,
      title: Text(
        AppLocalizations.of(context)?.dismissalRequests ?? 'طلبات الانصراف',
        style: GoogleFonts.notoKufiArabic(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      leading: IconButton(
        onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
        icon: Icon(Icons.logout_rounded, color: Theme.of(context).primaryColor),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)?.liveConnected ?? 'متصل مباشر',
                style: const TextStyle(color: Colors.green, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)?.searchStudentHint ??
              'البحث باسم الطالب أو الرقم التعريفي...',
          hintStyle: GoogleFonts.notoKufiArabic(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          border: InputBorder.none,
          icon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.notoKufiArabic(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            AppLocalizations.of(context)?.viewAll ?? 'عرض الكل',
            style: GoogleFonts.notoKufiArabic(
              color: Theme.of(context).primaryColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(BuildContext context) {
    return StreamBuilder<List<DismissalRequest>>(
      stream: context.read<DismissalRepository>().getActiveRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${AppLocalizations.of(context)?.errorFetchingData ?? 'حدث خطأ في جلب البيانات'}: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoKufiArabic(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                  if (snapshot.error.toString().contains('index'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        AppLocalizations.of(context)?.createFirestoreIndex ??
                            'يرجى إنشاء الفهرس المطلوب في Firestore console.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoKufiArabic(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)?.noActiveRequests ??
                      'لا توجد طلبات نشطة حالياً',
                  style: GoogleFonts.notoKufiArabic(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _DismissalCard(request: requests[index]),
            childCount: requests.length,
          ),
        );
      },
    );
  }

  Widget _buildRadarSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.parentLocationRadar ??
              'موقع أولياء الأمور (المنطقة الجغرافية)',
          style: GoogleFonts.notoKufiArabic(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            ),
          ),
          child: Stack(
            children: [
              CustomPaint(painter: _RadarPainter(), child: Container()),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.mainGate ?? 'البوابة الرئيسية',
                      style: GoogleFonts.notoKufiArabic(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Text(
                  AppLocalizations.of(context)?.autoUpdate ?? 'تحديث تلقائي',
                  style: GoogleFonts.notoKufiArabic(
                    color: Theme.of(context).primaryColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DismissalCard extends StatelessWidget {
  final DismissalRequest request;

  const _DismissalCard({required this.request});

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
        return AppLocalizations.of(context)?.pending ?? 'قيد الانتظار';
      case DismissalStatus.arrivingSoon:
        return AppLocalizations.of(context)?.arrivingSoon ?? 'قادم قريباً';
      case DismissalStatus.atGate:
        return AppLocalizations.of(context)?.atGate ?? 'عند البوابة';
      case DismissalStatus.completed:
        return AppLocalizations.of(context)?.completed ?? 'تم الانصراف';
      case DismissalStatus.cancelled:
        return AppLocalizations.of(context)?.cancelled ?? 'ملغي';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(request.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(context, request.status),
                        style: GoogleFonts.notoKufiArabic(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.studentName,
                      style: GoogleFonts.notoKufiArabic(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      request.studentGrade,
                      style: GoogleFonts.notoKufiArabic(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade100,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              Theme.of(context).cardTheme.color ??
                              (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context)?.authorizedPerson ?? 'المصرح له'}: ${request.parentName}',
                  style: GoogleFonts.notoKufiArabic(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                if (request.eta != null) ...[
                  const Spacer(),
                  Text(
                    request.eta!,
                    style: GoogleFonts.notoKufiArabic(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Extract all necessary references before any async gap
                    final dismissalRepo = context.read<DismissalRepository>();
                    final attendanceRepo = context.read<AttendanceRepository>();
                    final notificationRepo = context.read<NotificationRepository>();
                    final fcmService = context.read<FcmV1Service>();
                    final localizations = AppLocalizations.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      // 1. Record attendance check-out so Parent App immediately shows "Left"
                      final record = AttendanceRecord(
                        id: '',
                        studentId: request.studentId,
                        timestamp: DateTime.now(),
                        status: AttendanceStatus.checkOut,
                        location: 'Main Gate (Dismissal Confirmation)',
                      );
                      await attendanceRepo.recordAttendance(record);

                      // 2. Update dismissal status
                      await dismissalRepo.updateDismissalStatus(
                        request.id,
                        DismissalStatus.completed,
                      );

                      // 3. Send Notification to Parent
                      final title = localizations?.schoolGateUpdate ?? 'اكتمل الانصراف';
                      final body = localizations?.leftSchoolNotification(request.studentName) ?? 
                          'تم استلام ${request.studentName} من المدرسة.';

                      final notification = AppNotification(
                        id: const Uuid().v4(),
                        title: title,
                        body: body,
                        timestamp: DateTime.now(),
                        isRead: false,
                        type: NotificationType.attendance,
                        parentId: request.parentId,
                        studentId: request.studentId,
                      );

                      notificationRepo.sendNotification(notification);
                      final success = await fcmService.sendToParent(
                        parentId: request.parentId,
                        title: title,
                        body: body,
                        data: {'type': 'check_out', 'studentId': request.studentId},
                      );

                      if (context.mounted) {
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Push Notification Failed (No token or FCM error)'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Dismissal Completed Successfully')),
                        );
                      }
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.confirmDismissal ?? 'تأكيد الخروج',
                    style: GoogleFonts.notoKufiArabic(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floating: true,
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppLocalizations.of(context)?.requestsHistory ?? 'سجل الطلبات',
            style: GoogleFonts.notoKufiArabic(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverToBoxAdapter(
            child: Text(
              AppLocalizations.of(context)?.latestCompletedRequests ??
                  'أحدث الطلبات المنتهية',
              style: GoogleFonts.notoKufiArabic(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ),
        StreamBuilder<List<DismissalRequest>>(
          stream: context.read<DismissalRepository>().getRequestsHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)?.historyEmpty ?? 'السجل فارغ حالياً',
                      style: GoogleFonts.notoKufiArabic(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _DismissalCard(request: requests[index]),
                childCount: requests.length,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ScannerView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 100,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)?.quickQrScanner ?? 'ماسح الرموز السريع',
            style: GoogleFonts.notoKufiArabic(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.qrScannerDesc ??
                'قم بمسح الكود الخاص بالطالب للتحقق الفوري وتسجيل الحضور أو الانصراف.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoKufiArabic(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to existing full-screen scanner
                      context.push('/scan');
                    },
                    icon: const Icon(Icons.center_focus_strong_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.startCamera ?? 'تشغيل الكاميرا',
                      style: GoogleFonts.notoKufiArabic(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showManualSearchDialog(context),
                    icon: const Icon(Icons.search_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.manualChildSearch ??
                          'بحث يدوي عن طفل',
                      style: GoogleFonts.notoKufiArabic(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ManualSearchDialog(),
    );
  }
}

class _ProfileView extends StatelessWidget {
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
            AppLocalizations.of(context)?.profileScreen ?? 'الملف الشخصي',
            style: GoogleFonts.notoKufiArabic(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileCard(context, user?.name ?? 'مسؤول البوابة'),
                const SizedBox(height: 24),
                _buildSettingsSection(context),
                const SizedBox(height: 40),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                  style: GoogleFonts.notoKufiArabic(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)?.gateOfficerRoleLong ??
                      'ضابط أمن البوابة',
                  style: GoogleFonts.notoKufiArabic(
                    color: Colors.white.withValues(alpha: 0.8),
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
          AppLocalizations.of(context)?.appSettings ?? 'التطبيق',
          style: GoogleFonts.notoKufiArabic(
            color: const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.dark_mode_rounded,
          color: Colors.blue,
          title: AppLocalizations.of(context)?.darkMode ?? 'المظهر الداكن',
          trailing: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return Switch(
                value: mode == ThemeMode.dark,
                onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                activeColor: Colors.blue,
              );
            },
          ),
        ),
        _SettingsTile(
          icon: Icons.notifications_active_rounded,
          color: Colors.orange,
          title: AppLocalizations.of(context)?.notifications ?? 'التنبيهات',
          trailing: Switch(
            value: true,
            onChanged: (val) {},
            activeColor: Colors.orange,
          ),
        ),
        BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) {
            return _SettingsTile(
              icon: Icons.language_rounded,
              color: Colors.teal,
              title: AppLocalizations.of(context)?.languageSetting ??
                  'اللغة / Language',
              subtitle: locale.languageCode == 'ar'
                  ? (AppLocalizations.of(context)?.arabic ?? 'العربية')
                  : (AppLocalizations.of(context)?.english ?? 'English'),
              trailing: Switch(
                value: locale.languageCode == 'en',
                onChanged: (_) =>
                    context.read<LanguageCubit>().toggleLanguage(),
                activeColor: Colors.teal,
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
      child: OutlinedButton.icon(
        onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
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
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoKufiArabic(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: GoogleFonts.notoKufiArabic(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, (size.height / 3) * i / 2, paint);
    }

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 50; i++) {
      canvas.drawCircle(
        Offset((i * 137 % size.width), (i * 149 % size.height)),
        1,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _ManualSearchDialog extends StatefulWidget {
  const _ManualSearchDialog();

  @override
  State<_ManualSearchDialog> createState() => _ManualSearchDialogState();
}

class _ManualSearchDialogState extends State<_ManualSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<StudentModel> _searchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await context.read<AttendanceRepository>().searchStudents(
        query,
      );
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _recordAttendance(StudentModel student, AttendanceStatus status) async {
    final record = AttendanceRecord(
      id: '',
      studentId: student.id,
      timestamp: DateTime.now(),
      status: status,
      busId: null, // Gate check-in is not bus-specific
      location: 'Main Gate (Manual)',
    );

    try {
      await context.read<AttendanceRepository>().recordAttendance(record);
      if (mounted) {
        final title = AppLocalizations.of(context)?.schoolGateUpdate ?? 'تحديث البوابة';
        final body = status == AttendanceStatus.checkIn
            ? (AppLocalizations.of(context)?.enteredSchool(student.name) ??
                  'دخل ${student.name} المدرسة الآن')
            : (AppLocalizations.of(context)?.leftSchoolNotification(student.name) ??
                  'غادر ${student.name} المدرسة الآن');

        final notification = AppNotification(
          id: const Uuid().v4(),
          title: title,
          body: body,
          timestamp: DateTime.now(),
          isRead: false,
          type: NotificationType.attendance,
          parentId: student.parentId,
          studentId: student.id,
        );

        context.read<NotificationRepository>().sendNotification(notification);

        context.read<FcmV1Service>().sendToParent(
          parentId: student.parentId,
          title: title,
          body: body,
          data: {
            'type': 'attendance',
            'status': status == AttendanceStatus.checkIn ? 'check_in' : 'check_out',
            'studentId': student.id,
          },
        );

        final scaffoldMessenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              status == AttendanceStatus.checkIn
                  ? (AppLocalizations.of(context)
                          ?.attendanceCheckInSuccess(student.name) ??
                      'تم تسجيل الحضور لـ ${student.name}')
                  : (AppLocalizations.of(context)
                          ?.attendanceCheckOutSuccess(student.name) ??
                      'تم تسجيل الانصراف لـ ${student.name}'),
              style: GoogleFonts.notoKufiArabic(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)?.manualStudentSearch ??
                  'بحث يدوي عن طالب',
              style: GoogleFonts.notoKufiArabic(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onChanged: _performSearch,
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.enterStudentName ??
                    'ادخل اسم الطالب...',
                hintStyle: GoogleFonts.notoKufiArabic(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF3B82F6),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        _searchController.text.length < 2
                            ? (AppLocalizations.of(context)?.typeTwoCharsToSearch ??
                                'اكتب حرفين على الأقل للبحث')
                            : (AppLocalizations.of(context)?.noResults ??
                                'لا توجد نتائج'),
                        style: GoogleFonts.notoKufiArabic(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        final student = _searchResults[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            student.name,
                            style: GoogleFonts.notoKufiArabic(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            student.grade,
                            style: GoogleFonts.notoKufiArabic(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _recordAttendance(
                                  student,
                                  AttendanceStatus.checkIn,
                                ),
                                icon: const Icon(
                                  Icons.login_rounded,
                                  color: Colors.green,
                                ),
                                tooltip: AppLocalizations.of(context)?.checkIn ??
                                    'حضور',
                              ),
                              IconButton(
                                onPressed: () => _recordAttendance(
                                  student,
                                  AttendanceStatus.checkOut,
                                ),
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.blue,
                                ),
                                tooltip: AppLocalizations.of(context)?.checkOut ??
                                    'انصراف',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)?.close ?? 'إغلاق',
                style: GoogleFonts.notoKufiArabic(
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
