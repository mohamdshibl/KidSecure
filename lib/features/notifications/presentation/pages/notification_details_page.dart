import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationDetailsPage extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailsPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'تفاصيل التنبيه',
            style: GoogleFonts.notoKufiArabic(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Text(
                  notification.body,
                  style: GoogleFonts.notoKufiArabic(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.8,
                  ),
                ),
              ),
              const Spacer(),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTypeIcon(notification.type),
                color: _getTypeColor(notification.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                notification.title,
                style: GoogleFonts.notoKufiArabic(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 16,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat(
                'yyyy/MM/dd - hh:mm a',
                'en',
              ).format(notification.timestamp),
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        if (notification.type == NotificationType.attendance ||
            notification.type == NotificationType.bus)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Determine where to go based on type
                if (notification.type == NotificationType.attendance) {
                  context.push('/attendance-history');
                } else if (notification.type == NotificationType.bus &&
                    notification.studentId != null) {
                  // If we had busId we could go to tracking, but for now history is safe
                  context.push('/attendance-history');
                }
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('عرض السجل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'حذف التنبيه؟',
                    style: GoogleFonts.notoKufiArabic(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'هل أنت متأكد من حذف هذا التنبيه؟',
                    style: GoogleFonts.notoKufiArabic(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('إلغاء', style: GoogleFonts.notoKufiArabic()),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('حذف', style: GoogleFonts.notoKufiArabic()),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await context.read<NotificationRepository>().deleteNotification(
                  notification.id,
                );
                if (context.mounted) {
                  context.pop(); // Return to history
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف التنبيه')),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('حذف التنبيه'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.bus:
        return const Color(0xFF3B82F6);
      case NotificationType.attendance:
        return const Color(0xFFF59E0B);
      case NotificationType.announcement:
        return const Color(0xFF8B5CF6);
      case NotificationType.alert:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bus:
        return Icons.directions_bus_rounded;
      case NotificationType.attendance:
        return Icons.person_outline_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.alert:
        return Icons.error_outline_rounded;
    }
  }
}
