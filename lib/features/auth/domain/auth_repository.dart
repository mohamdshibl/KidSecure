import 'user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get user;
  Stream<List<UserModel>> get users;

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.parent,
  });

  Future<UserModel> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? busId,
  });

  Future<void> toggleUserStatus(String userId, bool status);

  Future<UserModel> logInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> updateFcmToken(String userId, String? token);

  Future<void> logOut();
}
