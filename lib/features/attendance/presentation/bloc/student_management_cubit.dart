import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/student_model.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../../../core/services/storage_service.dart';

enum StudentManagementStatus { initial, loading, success, failure }

class StudentManagementState extends Equatable {
  final String name;
  final String grade;
  final String busId;
  final String schoolId;
  final File? imageFile;
  final StudentManagementStatus status;
  final String? errorMessage;

  const StudentManagementState({
    this.name = '',
    this.grade = '',
    this.busId = '',
    this.schoolId = 'SCHOOL_001',
    this.imageFile,
    this.status = StudentManagementStatus.initial,
    this.errorMessage,
  });

  StudentManagementState copyWith({
    String? name,
    String? grade,
    String? busId,
    String? schoolId,
    File? imageFile,
    StudentManagementStatus? status,
    String? errorMessage,
  }) {
    return StudentManagementState(
      name: name ?? this.name,
      grade: grade ?? this.grade,
      busId: busId ?? this.busId,
      schoolId: schoolId ?? this.schoolId,
      imageFile: imageFile ?? this.imageFile,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    name,
    grade,
    busId,
    schoolId,
    imageFile,
    status,
    errorMessage,
  ];
}

class StudentManagementCubit extends Cubit<StudentManagementState> {
  final AttendanceRepository _attendanceRepository;
  final StorageService _storageService;
  final String _parentId;

  StudentManagementCubit({
    required AttendanceRepository attendanceRepository,
    required StorageService storageService,
    required String parentId,
  }) : _attendanceRepository = attendanceRepository,
       _storageService = storageService,
       _parentId = parentId,
       super(const StudentManagementState());

  void nameChanged(String value) => emit(state.copyWith(name: value));
  void gradeChanged(String value) => emit(state.copyWith(grade: value));
  void busIdChanged(String value) => emit(state.copyWith(busId: value));
  void imageFileChanged(File? file) => emit(state.copyWith(imageFile: file));

  Future<void> addStudent() async {
    if (state.name.isEmpty || state.grade.isEmpty) {
      emit(
        state.copyWith(
          status: StudentManagementStatus.failure,
          errorMessage: 'Please fill in all fields',
        ),
      );
      return;
    }

    emit(state.copyWith(status: StudentManagementStatus.loading));

    try {
      final id = const Uuid().v4();
      String? profileImageUrl;

      if (state.imageFile != null) {
        profileImageUrl = await _storageService.uploadProfilePicture(
          state.imageFile!,
          _parentId,
        );
      }

      final student = StudentModel(
        id: id,
        name: state.name,
        parentId: _parentId,
        schoolId: state.schoolId,
        grade: state.grade,
        busId: state.busId.isNotEmpty ? state.busId : null,
        qrCode: 'STUDENT_$id',
        profileImageUrl: profileImageUrl,
      );

      await _attendanceRepository.addStudent(student);
      emit(state.copyWith(status: StudentManagementStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: StudentManagementStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
