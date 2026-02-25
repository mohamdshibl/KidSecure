import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../attendance/domain/models/dismissal_request.dart';
import '../attendance/domain/repositories/dismissal_repository.dart';
import '../attendance/domain/repositories/attendance_repository.dart';
import '../attendance/domain/models/student_model.dart';
import '../attendance/domain/models/attendance_record.dart';
import '../../core/theme/theme_cubit.dart';

class GateOfficerDashboard extends StatefulWidget {
  const GateOfficerDashboard({super.key});

  @override
  State<GateOfficerDashboard> createState() => _GateOfficerDashboardState();
}

class _GateOfficerDashboardState extends State<GateOfficerDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
      ),
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
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: GoogleFonts.notoKufiArabic(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.notoKufiArabic(fontSize: 12),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'السجل',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'ماسح',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'الملف',
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
        'طلبات الانصراف',
        style: GoogleFonts.notoKufiArabic(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      leading: IconButton(
        onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
        icon: const Icon(Icons.logout_rounded, color: Color(0xFF3B82F6)),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'متصل مباشر',
                style: TextStyle(color: Colors.green, fontSize: 12),
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
          hintText: 'البحث باسم الطالب أو الرقم التعريفي...',
          hintStyle: GoogleFonts.notoKufiArabic(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
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
            'عرض الكل',
            style: GoogleFonts.notoKufiArabic(
              color: const Color(0xFF3B82F6),
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
                    'حدث خطأ في جلب البيانات: ${snapshot.error}',
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
                  'لا توجد طلبات نشطة حالياً',
                  style: GoogleFonts.notoKufiArabic(
                    color: const Color(0xFF64748B),
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
              color: Theme.of(context).dividerColor.withOpacity(0.05),
            ),
          ),
          child: Stack(
            children: [
              CustomPaint(painter: _RadarPainter(), child: Container()),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF3B82F6),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'البوابة الرئيسية',
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
                  'تحديث تلقائي',
                  style: GoogleFonts.notoKufiArabic(
                    color: const Color(0xFF3B82F6),
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

  String _getStatusText(DismissalStatus status) {
    switch (status) {
      case DismissalStatus.pending:
        return 'قيد الانتظار';
      case DismissalStatus.arrivingSoon:
        return 'قادم قريباً';
      case DismissalStatus.atGate:
        return 'عند البوابة';
      case DismissalStatus.completed:
        return 'تم الانصراف';
      case DismissalStatus.cancelled:
        return 'ملغي';
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
          color: Theme.of(context).dividerColor.withOpacity(0.05),
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(request.status),
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
                        color: const Color(0xFF94A3B8),
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
                    backgroundColor: const Color(0xFF334155),
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
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Text(
                  'المصرح له: ${request.parentName}',
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
                    try {
                      await context
                          .read<DismissalRepository>()
                          .updateDismissalStatus(
                            request.id,
                            DismissalStatus.completed,
                          );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
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
                    'تأكيد الخروج',
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
                  color: const Color(0xFF334155),
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
            'سجل الطلبات',
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
              'أحدث الطلبات المنتهية',
              style: GoogleFonts.notoKufiArabic(
                color: const Color(0xFF94A3B8),
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
                      'السجل فارغ حالياً',
                      style: GoogleFonts.notoKufiArabic(
                        color: const Color(0xFF64748B),
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
              color: const Color(0xFF3B82F6).withOpacity(0.1),
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
            'ماسح الرموز السريع',
            style: GoogleFonts.notoKufiArabic(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
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
                      'تشغيل الكاميرا',
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
            'الملف الشخصي',
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
                _buildProfileCard(user?.name ?? 'مسؤول البوابة'),
                const SizedBox(height: 24),
                _buildSettingsSection(context),
                const SizedBox(height: 24),
                _buildSupportSection(),
                const SizedBox(height: 40),
                _buildLogoutButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(String name) {
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
                  style: GoogleFonts.notoKufiArabic(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ضابط أمن البوابة',
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
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التطبيق',
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
          title: 'المظهر الداكن',
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
          title: 'التنبيهات',
          trailing: Switch(
            value: true,
            onChanged: (val) {},
            activeColor: Colors.orange,
          ),
        ),
        _SettingsTile(
          icon: Icons.language_rounded,
          color: Colors.teal,
          title: 'اللغة',
          subtitle: 'العربية',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الدعم والمساعدة',
          style: GoogleFonts.notoKufiArabic(
            color: const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.help_outline_rounded,
          color: Colors.purple,
          title: 'مركز المساعدة',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          color: Colors.blueGrey,
          title: 'عن التطبيق',
          onTap: () {},
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
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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
        trailing:
            trailing ??
            (onTap != null
                ? Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 14,
                  )
                : null),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
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
      ..color = Colors.white.withOpacity(0.1)
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'تم تسجيل ${status == AttendanceStatus.checkIn ? 'الحضور' : 'الانصراف'} لـ ${student.name}',
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: _performSearch,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ادخل اسم الطالب...',
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
                              ? 'اكتب حرفين على الأقل للبحث'
                              : 'لا توجد نتائج',
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
                                  tooltip: 'حضور',
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
                                  tooltip: 'انصراف',
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
                  'إغلاق',
                  style: GoogleFonts.notoKufiArabic(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
