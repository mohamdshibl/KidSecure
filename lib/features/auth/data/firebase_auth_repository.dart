import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../domain/auth_repository.dart';
import '../domain/user_model.dart';

class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, firebaseUser.uid);
      }
      return null;
    });
  }

  @override
  Stream<List<UserModel>> get users {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.parent,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toMap());

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unknown error occurred');
    }
  }

  @override
  Future<UserModel> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? busId,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
        busId: busId,
      );

      await _firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toMap());

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unknown error occurred');
    }
  }

  @override
  Future<void> toggleUserStatus(String userId, bool status) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': status,
    });
  }

  @override
  Future<UserModel> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!, credential.user!.uid);
        if (!user.isActive) {
          await _firebaseAuth.signOut();
          throw Exception(
            'This account has been deactivated. Please contact the administrator.',
          );
        }
        return user;
      } else {
        throw Exception('User data not found');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unknown error occurred');
    }
  }

  @override
  Future<void> updateFcmToken(String userId, String? token) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }

  @override
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }
}
