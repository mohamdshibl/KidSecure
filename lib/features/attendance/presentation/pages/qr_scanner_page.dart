import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kidsecure/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:kidsecure/features/attendance/domain/models/attendance_record.dart';
import 'package:kidsecure/features/attendance/domain/models/dismissal_request.dart';
import 'package:kidsecure/features/attendance/domain/repositories/dismissal_repository.dart';
import 'package:kidsecure/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kidsecure/features/auth/domain/user_model.dart';
import 'package:kidsecure/features/attendance/domain/models/student_model.dart';
import 'package:kidsecure/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kidsecure/features/notifications/domain/models/notification_model.dart';
import 'package:kidsecure/core/services/fcm_v1_service.dart';
import 'package:uuid/uuid.dart';
import 'package:kidsecure/l10n/app_localizations.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.scanStudentQr ?? 'Scan Student QR',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  HapticFeedback.lightImpact(); // Feedback on detect
                  setState(() => _isProcessing = true);
                  await _handleScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          _buildOverlay(),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
        Row(
          children: [
            Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            Expanded(child: Container(color: Colors.black.withOpacity(0.5))),
          ],
        ),
        Expanded(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            child: Text(
              AppLocalizations.of(context)?.alignQrCode ??
                  'Align student QR code within the frame',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleScan(String qrCode) async {
    final repository = context.read<AttendanceRepository>();
    final user = context.read<AuthBloc>().state.user;
    final busId = user?.role == UserRole.driver ? user?.busId : null;

    try {
      final student = await repository.getStudentByQrCode(qrCode, busId: busId);

      if (!mounted) return;

      if (student == null) {
        if (mounted) {
          _showResult(
            context,
            AppLocalizations.of(context)?.studentNotFound ?? 'Student not found',
            Colors.red,
          );
        }
      } else {
        if (mounted) {
          // Await the dialog to close before we allow scanning again
          await _showAttendanceDialog(context, student);
        }
      }
    } catch (e) {
      if (mounted) {
        _showResult(
          context,
          '${AppLocalizations.of(context)?.errorProcessingScan ?? 'Error processing scan'}: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showAttendanceDialog(BuildContext context, StudentModel student) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, size: 40, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              student.name,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.gradeLabel(student.grade) ??
                  'Grade: ${student.grade}',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            
            // Show Active Dismissal Request if any
            StreamBuilder<DismissalRequest?>(
              stream: context.read<DismissalRepository>().getActiveRequestForStudent(student.id, ''),
              builder: (context, snapshot) {
                final activeRequest = snapshot.data;
                if (activeRequest != null) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hail_rounded, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pending Pickup Request by ${activeRequest.parentName}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleDismissal(context, activeRequest, student),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Complete Dismissal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 40),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _register(
                      context,
                      student,
                      AttendanceStatus.checkIn,
                    ),
                    icon: const Icon(Icons.login_rounded),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    label: Text(
                      AppLocalizations.of(context)?.checkInAction ?? 'Check In',
                      style: GoogleFonts.notoKufiArabic(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _register(
                      context,
                      student,
                      AttendanceStatus.checkOut,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    label: Text(
                      AppLocalizations.of(context)?.checkOutAction ?? 'Check Out',
                      style: GoogleFonts.notoKufiArabic(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDismissal(BuildContext context, DismissalRequest request, StudentModel student) async {
    final dismissalRepo = context.read<DismissalRepository>();
    final attendanceRepo = context.read<AttendanceRepository>();
    final notificationRepo = context.read<NotificationRepository>();
    final fcmService = context.read<FcmV1Service>();
    final localizations = AppLocalizations.of(context);
    final user = context.read<AuthBloc>().state.user;
    
    Navigator.pop(context); // Close bottom sheet
    
    try {
      // 1. Record checkout
      final record = AttendanceRecord(
        id: '',
        studentId: request.studentId,
        timestamp: DateTime.now(),
        status: AttendanceStatus.checkOut,
        location: 'Scan Confirmation',
        busId: user?.role == UserRole.driver ? user?.busId : null,
        officerId: user?.id,
      );
      await attendanceRepo.recordAttendance(record);

      // 2. Complete dismissal
      await dismissalRepo.updateDismissalStatus(request.id, DismissalStatus.completed);

      // 3. Send Notification to Parent
      final title = localizations?.schoolGateUpdate ?? 'اكتمل الانصراف';
      final body = localizations?.leftSchoolNotification(student.name) ?? 
          'تم استلام ${student.name} من المدرسة.';

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

      notificationRepo.sendNotification(notification);
      fcmService.sendToParent(
        parentId: student.parentId,
        title: title,
        body: body,
        data: {'type': 'check_out', 'studentId': student.id},
      );

      _showResult(context, 'Dismissal Completed Successfully', Colors.green);
    } catch (e) {
      _showResult(context, 'Error: $e', Colors.red);
    }
  }

  Future<void> _register(
    BuildContext context,
    StudentModel student,
    AttendanceStatus status,
  ) async {
    final attendanceRepo = context.read<AttendanceRepository>();
    final notificationRepo = context.read<NotificationRepository>();
    final fcmService = context.read<FcmV1Service>();
    final localizations = AppLocalizations.of(context);
    final user = context.read<AuthBloc>().state.user;

    Navigator.pop(context); // Close bottom sheet

    final record = AttendanceRecord(
      id: '', // Firestore auto-id
      studentId: student.id,
      timestamp: DateTime.now(),
      status: status,
      busId: user?.role == UserRole.driver ? user?.busId : null,
      officerId: user?.id,
    );

    await attendanceRepo.recordAttendance(record);

    final title = localizations?.schoolGateUpdate ?? 'تحديث الحضور';
    final body = status == AttendanceStatus.checkIn
        ? (localizations?.enteredSchool(student.name) ?? 'تم تسجيل دخول ${student.name} للمدرسة.')
        : (localizations?.leftSchoolNotification(student.name) ?? 'تم تسجيل خروج ${student.name} من المدرسة.');

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

    notificationRepo.sendNotification(notification);
    final success = await fcmService.sendToParent(
      parentId: student.parentId,
      title: title,
      body: body,
      data: {
        'type': status == AttendanceStatus.checkIn ? 'check_in' : 'check_out',
        'studentId': student.id,
      },
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
      HapticFeedback.heavyImpact(); // Stronger feedback on success
      _showResult(
        context,
        AppLocalizations.of(context)?.scanSuccess(status.toString().split('.').last) ??
            'Success: ${status.toString().split('.').last}',
        Colors.green,
      );
    }
  }

  void _showResult(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
