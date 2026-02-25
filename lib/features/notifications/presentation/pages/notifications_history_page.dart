import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class NotificationsHistoryPage extends StatefulWidget {
  const NotificationsHistoryPage({super.key});

  @override
  State<NotificationsHistoryPage> createState() =>
      _NotificationsHistoryPageState();
}

class _NotificationsHistoryPageState extends State<NotificationsHistoryPage> {
  String _activeFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<AppNotification>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user!;
    _notificationsStream = context
        .read<NotificationRepository>()
        .getNotifications(user.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.read<AuthBloc>().state.user == null) {
      return const Center(child: Text('Please login'));
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildSearchAndFilter(),
              _buildNotificationList(),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      floating: true,
      title: Text(
        'سجل التنبيهات',
        style: GoogleFonts.notoKufiArabic(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.done_all_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () {
            // Mark all as read logic
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'البحث في التنبيهات...',
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
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 20),
            _buildFilterChips(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final List<Map<String, dynamic>> filters = [
      {'id': 'all', 'label': 'الكل', 'icon': null},
      {'id': 'bus', 'label': 'الحافلة', 'icon': Icons.directions_bus_rounded},
      {
        'id': 'attendance',
        'label': 'الحضور',
        'icon': Icons.person_outline_rounded,
      },
      {'id': 'announcement', 'label': 'عام', 'icon': Icons.campaign_rounded},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _activeFilter == filter['id'];

          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filter['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  if (filter['icon'] != null) ...[
                    Icon(
                      filter['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    filter['label'] as String,
                    style: GoogleFonts.notoKufiArabic(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationList() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        var notifications = snapshot.data ?? [];

        // Apply Filters
        if (_activeFilter != 'all') {
          notifications = notifications
              .where((n) => n.type.toString().split('.').last == _activeFilter)
              .toList();
        }

        // Apply Search
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          notifications = notifications
              .where(
                (n) =>
                    n.title.toLowerCase().contains(query) ||
                    n.body.toLowerCase().contains(query),
              )
              .toList();
        }

        if (notifications.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد تنبيهات حالياً',
                    style: GoogleFonts.notoKufiArabic(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final n = notifications[index];
            return Dismissible(
              key: Key(n.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                context.read<NotificationRepository>().deleteNotification(n.id);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('تم حذف التنبيه')));
              },
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              child: _NotificationCard(notification: n),
            );
          }, childCount: notifications.length),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          context.read<NotificationRepository>().markAsRead(notification.id);
        }
        context.push('/notification-details', extra: notification);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUnread
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Theme.of(context).dividerColor.withOpacity(0.05),
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.notoKufiArabic(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: GoogleFonts.notoKufiArabic(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.notoKufiArabic(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.6,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.bus:
        icon = Icons.directions_bus_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case NotificationType.attendance:
        icon = Icons.person_outline_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case NotificationType.announcement:
        icon = Icons.campaign_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      case NotificationType.alert:
        icon = Icons.error_outline_rounded;
        color = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}
