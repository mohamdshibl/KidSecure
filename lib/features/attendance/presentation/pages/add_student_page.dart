import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/student_management_cubit.dart';

class AddStudentPage extends StatelessWidget {
  const AddStudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final parentId = context.read<AuthBloc>().state.user?.id ?? '';

    return BlocProvider(
      create: (context) => StudentManagementCubit(
        attendanceRepository: context.read<AttendanceRepository>(),
        parentId: parentId,
      ),
      child: const AddStudentView(),
    );
  }
}

class AddStudentView extends StatelessWidget {
  const AddStudentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentManagementCubit, StudentManagementState>(
      listener: (context, state) {
        if (state.status == StudentManagementStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'An error occurred')),
          );
        } else if (state.status == StudentManagementStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Child added successfully!')),
          );
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Add Child',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Child Information',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _NameInput(),
              const SizedBox(height: 16),
              _GradeInput(),
              const SizedBox(height: 16),
              _BusIdInput(),
              const SizedBox(height: 32),
              _SubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) =>
          context.read<StudentManagementCubit>().nameChanged(value),
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter child\'s full name',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _GradeInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) =>
          context.read<StudentManagementCubit>().gradeChanged(value),
      decoration: InputDecoration(
        labelText: 'Grade',
        hintText: 'e.g. Grade 1, KG 2',
        prefixIcon: const Icon(Icons.school_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _BusIdInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) =>
          context.read<StudentManagementCubit>().busIdChanged(value),
      decoration: InputDecoration(
        labelText: 'Bus Route (Optional)',
        hintText: 'e.g. Fahd Kingdom st',
        prefixIcon: const Icon(Icons.directions_bus_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentManagementCubit, StudentManagementState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.status == StudentManagementStatus.loading
                ? null
                : () => context.read<StudentManagementCubit>().addStudent(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: state.status == StudentManagementStatus.loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Add Child',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
