import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/domain/user_model.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import 'parent_dashboard.dart';
import 'gate_officer_dashboard.dart';
import 'admin_dashboard.dart';
import 'driver_dashboard.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (user.role) {
      case UserRole.parent:
        return const ParentDashboard();
      case UserRole.gateOfficer:
        return const GateOfficerDashboard();
      case UserRole.driver:
        return const DriverDashboard();
      case UserRole.admin:
        return const AdminDashboard();
    }
  }
}
