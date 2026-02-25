import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../auth/domain/auth_repository.dart';
import '../auth/domain/user_model.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';

import '../../core/theme/theme_cubit.dart';
import '../admin/presentation/widgets/broadcast_banner.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  UserRole? _filterRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeView(
              filterRole: _filterRole,
              onFilterRoleChanged: (role) => setState(() => _filterRole = role),
            ),
            const _ProfileView(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/add-staff'),
              backgroundColor: Theme.of(context).primaryColor,
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: Text(
                'Add Staff',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
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
  final UserRole? filterRole;
  final Function(UserRole?) onFilterRoleChanged;

  const _HomeView({
    required this.filterRole,
    required this.onFilterRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(
            'Admin Console',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        SliverToBoxAdapter(child: _buildQuickActions(context)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: BroadcastBanner(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverToBoxAdapter(child: _buildRoleFilter(context)),
        _UserList(filterRole: filterRole),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'Emergency',
                  subtitle: 'Critical alerts',
                  icon: Icons.emergency_share_rounded,
                  color: const Color(0xFFEF4444),
                  onTap: () => context.push('/admin/emergency-broadcast'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickActionCard(
                  title: 'Broadcast',
                  subtitle: 'General updates',
                  icon: Icons.campaign_rounded,
                  color: Colors.orange,
                  onTap: () => context.push('/admin/broadcast'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'Stats',
                  subtitle: 'View activity',
                  icon: Icons.analytics_rounded,
                  color: Colors.blue,
                  onTap: () => context.push('/admin/stats'),
                ),
              ),
              const SizedBox(width: 16),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Theme.of(context).cardTheme.color,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: filterRole == null,
              onSelected: () => onFilterRoleChanged(null),
            ),
            ...UserRole.values.map((role) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _FilterChip(
                  label: role.toString().split('.').last,
                  isSelected: filterRole == role,
                  onSelected: () => onFilterRoleChanged(role),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      labelStyle: GoogleFonts.inter(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final UserRole? filterRole;

  const _UserList({this.filterRole});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: context.read<AuthRepository>().users,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        var users = snapshot.data ?? [];
        if (filterRole != null) {
          users = users.where((u) => u.role == filterRole).toList();
        }

        if (users.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'No users found',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _UserCard(user: users[index]),
              childCount: users.length,
            ),
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
            child: Icon(
              _getRoleIcon(user.role),
              color: _getRoleColor(user.role),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: user.isActive,
            onChanged: (val) {
              context.read<AuthRepository>().toggleUserStatus(user.id, val);
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.parent:
        return Colors.blue;
      case UserRole.gateOfficer:
        return Colors.orange;
      case UserRole.driver:
        return Colors.teal;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.parent:
        return Icons.family_restroom_rounded;
      case UserRole.gateOfficer:
        return Icons.security_rounded;
      case UserRole.driver:
        return Icons.drive_eta_rounded;
    }
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

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
                _buildProfileCard(context, user?.name ?? 'Admin'),
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
                  'School Administrator',
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
          backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
          foregroundColor: const Color(0xFFEF4444),
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
