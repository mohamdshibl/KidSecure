import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user_model.dart';
import '../../../../core/services/notification_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final NotificationService _notificationService;
  late final StreamSubscription<UserModel?> _userSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required NotificationService notificationService,
  }) : _authRepository = authRepository,
       _notificationService = notificationService,
       super(const AuthState.unknown()) {
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLogoutRequested>(_onLogoutRequested);

    _userSubscription = _authRepository.user.listen(
      (user) => add(AuthUserChanged(user)),
    );

    // Listen for FCM token refreshes
    _tokenRefreshSubscription = _notificationService.onTokenRefresh.listen((token) async {
      final user = state.user;
      if (user != null) {
        await _authRepository.updateFcmToken(user.id, token);
      }
    });
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user != null) {
      // Sync token on login/change if needed
      final token = await _notificationService.getToken();
      if (token != null && user.fcmToken != token) {
        await _authRepository.updateFcmToken(user.id, token);
      }
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) {
    unawaited(_authRepository.logOut());
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    _tokenRefreshSubscription?.cancel();
    return super.close();
  }
}

