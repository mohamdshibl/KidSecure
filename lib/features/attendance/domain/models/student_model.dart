import 'package:equatable/equatable.dart';

class StudentModel extends Equatable {
  final String id;
  final String name;
  final String parentId;
  final String schoolId;
  final String grade;
  final String? profileImageUrl;
  final String qrCode;
  final String? busId;

  const StudentModel({
    required this.id,
    required this.name,
    required this.parentId,
    required this.schoolId,
    required this.grade,
    this.profileImageUrl,
    required this.qrCode,
    this.busId,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String id) {
    return StudentModel(
      id: id,
      name: map['name'] ?? '',
      parentId: map['parentId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      grade: map['grade'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      qrCode: map['qrCode'] ?? id,
      busId: map['busId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'schoolId': schoolId,
      'grade': grade,
      'profileImageUrl': profileImageUrl,
      'qrCode': qrCode,
      'busId': busId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    parentId,
    schoolId,
    grade,
    qrCode,
    busId,
  ];

  StudentModel copyWith({
    String? name,
    String? grade,
    String? profileImageUrl,
    String? busId,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      parentId: parentId,
      schoolId: schoolId,
      grade: grade ?? this.grade,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      qrCode: qrCode,
      busId: busId ?? this.busId,
    );
  }
}
