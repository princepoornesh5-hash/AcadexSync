import 'role_enum.dart';

enum AccountStatus { active, inactive, suspended, pending }

extension AccountStatusExtension on AccountStatus {
  String get value => name;

  static AccountStatus fromString(String val) {
    return AccountStatus.values.firstWhere((e) => e.name == val, orElse: () => AccountStatus.pending);
  }
}

class UserModel {
  final String id;
  final String? firebaseUid;
  final String name;
  final String email;
  final AppRole role;
  final String? profilePictureUrl;
  final String? collegeId;
  final String? departmentId;
  final String? sectionId;
  final String? semesterId;
  final AccountStatus accountStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    this.firebaseUid,
    required this.name,
    required this.email,
    required this.role,
    this.profilePictureUrl,
    this.collegeId,
    this.departmentId,
    this.sectionId,
    this.semesterId,
    this.accountStatus = AccountStatus.active,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      role: AppRoleExtension.fromValue(json['role'] as String),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      collegeId: json['collegeId'] as String?,
      departmentId: json['departmentId'] as String?,
      sectionId: json['sectionId'] as String?,
      semesterId: json['semesterId'] as String?,
      accountStatus: json['accountStatus'] != null 
          ? AccountStatusExtension.fromString(json['accountStatus'] as String)
          : AccountStatus.active,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'name': name,
      'email': email,
      'role': role.value,
      'profilePictureUrl': profilePictureUrl,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'sectionId': sectionId,
      'semesterId': semesterId,
      'accountStatus': accountStatus.value,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? firebaseUid,
    String? name,
    String? email,
    AppRole? role,
    String? profilePictureUrl,
    String? collegeId,
    String? departmentId,
    String? sectionId,
    String? semesterId,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      sectionId: sectionId ?? this.sectionId,
      semesterId: semesterId ?? this.semesterId,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
