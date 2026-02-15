import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { parent, gateOfficer, driver, admin }

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime? createdAt;
  final String? busId;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    this.isActive = true,
    this.createdAt,
    this.busId,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.parent,
      ),
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      busId: map['busId'],
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'busId': busId,
      'fcmToken': fcmToken,
    };
  }

  static final empty = UserModel(
    id: '',
    email: '',
    name: '',
    role: UserRole.parent,
    createdAt: DateTime.now(),
  );

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    role,
    phoneNumber,
    profileImageUrl,
    isActive,
    createdAt,
    busId,
    fcmToken,
  ];
}
