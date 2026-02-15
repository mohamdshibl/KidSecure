import 'package:equatable/equatable.dart';
import '../../domain/user_model.dart';

enum AuthStatus { authenticated, unauthenticated, unknown }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;

  const AuthState._({this.status = AuthStatus.unknown, this.user});

  const AuthState.unknown() : this._();

  const AuthState.authenticated(UserModel user)
    : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [status, user];
}
