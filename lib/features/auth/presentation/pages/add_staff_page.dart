import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user_model.dart';
import '../bloc/signup_cubit.dart';

class AddStaffPage extends StatelessWidget {
  const AddStaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SignUpCubit(context.read<AuthRepository>())
            ..roleChanged(UserRole.gateOfficer), // Default for staff creation
      child: const AddStaffView(),
    );
  }
}

class AddStaffView extends StatelessWidget {
  const AddStaffView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpCubit, SignUpState>(
      listener: (context, state) {
        if (state.status == SignUpStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Failed to create staff account',
              ),
            ),
          );
        }
        if (state.status == SignUpStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff account created successfully!'),
            ),
          );
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Add New Staff',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff Details',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _NameInput(),
              const SizedBox(height: 16),
              _EmailInput(),
              const SizedBox(height: 16),
              _PasswordInput(),
              const SizedBox(height: 16),
              BlocBuilder<SignUpCubit, SignUpState>(
                buildWhen: (p, c) => p.role != c.role,
                builder: (context, state) {
                  if (state.role != UserRole.driver)
                    return const SizedBox.shrink();
                  return Column(
                    children: [_BusIdInput(), const SizedBox(height: 16)],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Assign Role',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _RoleSelector(),
              const SizedBox(height: 40),
              _CreateButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusIdInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (v) => context.read<SignUpCubit>().busIdChanged(v),
      decoration: _inputDeco(
        context,
        'Bus ID / Route Number',
        Icons.directions_bus_outlined,
      ),
    );
  }
}

class _NameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (v) => context.read<SignUpCubit>().nameChanged(v),
      decoration: _inputDeco(context, 'Full Name', Icons.person_outline),
    );
  }
}

class _EmailInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (v) => context.read<SignUpCubit>().emailChanged(v),
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDeco(context, 'Email Address', Icons.email_outlined),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (v) => context.read<SignUpCubit>().passwordChanged(v),
      obscureText: true,
      decoration: _inputDeco(context, 'Temporary Password', Icons.lock_outline),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      buildWhen: (p, c) => p.role != c.role,
      builder: (context, state) {
        return Row(
          children: [
            _RoleOption(
              label: 'Gate Officer',
              role: UserRole.gateOfficer,
              isSelected: state.role == UserRole.gateOfficer,
            ),
            const SizedBox(width: 12),
            _RoleOption(
              label: 'Driver',
              role: UserRole.driver,
              isSelected: state.role == UserRole.driver,
            ),
          ],
        );
      },
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final UserRole role;
  final bool isSelected;

  const _RoleOption({
    required this.label,
    required this.role,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<SignUpCubit>().roleChanged(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.status == SignUpStatus.loading
                ? null
                : () => context.read<SignUpCubit>().createUserByAdmin(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.status == SignUpStatus.loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Create Staff Account'),
          ),
        );
      },
    );
  }
}

InputDecoration _inputDeco(BuildContext context, String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    prefixIcon: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
    ),
  );
}
