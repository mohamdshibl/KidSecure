import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user_model.dart';

enum SignUpStatus { initial, loading, success, failure }

class SignUpState extends Equatable {
  final String email;
  final String name;
  final String password;
  final UserRole role;
  final SignUpStatus status;
  final String? errorMessage;
  final String? busId;

  const SignUpState({
    this.email = '',
    this.name = '',
    this.password = '',
    this.role = UserRole.parent,
    this.status = SignUpStatus.initial,
    this.errorMessage,
    this.busId,
  });

  SignUpState copyWith({
    String? email,
    String? name,
    String? password,
    UserRole? role,
    SignUpStatus? status,
    String? errorMessage,
    String? busId,
  }) {
    return SignUpState(
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      role: role ?? this.role,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      busId: busId ?? this.busId,
    );
  }

  @override
  List<Object?> get props => [
    email,
    name,
    password,
    role,
    status,
    errorMessage,
    busId,
  ];
}

class SignUpCubit extends Cubit<SignUpState> {
  final AuthRepository _authRepository;

  SignUpCubit(this._authRepository) : super(const SignUpState());

  void emailChanged(String value) => emit(state.copyWith(email: value));
  void nameChanged(String value) => emit(state.copyWith(name: value));
  void passwordChanged(String value) => emit(state.copyWith(password: value));
  void roleChanged(UserRole value) => emit(state.copyWith(role: value));
  void busIdChanged(String value) => emit(state.copyWith(busId: value));

  Future<void> signUp() async {
    if (state.status == SignUpStatus.loading) return;

    emit(state.copyWith(status: SignUpStatus.loading));
    try {
      await _authRepository.signUp(
        email: state.email,
        password: state.password,
        name: state.name,
        role: state.role,
      );
      emit(state.copyWith(status: SignUpStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> createUserByAdmin() async {
    if (state.status == SignUpStatus.loading) return;

    emit(state.copyWith(status: SignUpStatus.loading));
    try {
      await _authRepository.createUserByAdmin(
        email: state.email,
        password: state.password,
        name: state.name,
        role: state.role,
        busId: state.busId,
      );
      emit(state.copyWith(status: SignUpStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
