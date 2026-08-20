import 'role_enum.dart';

enum AccountStatus { active, pendingActivation, inactive, deactivated, suspended }

extension AccountStatusExtension on AccountStatus {
  String get value {
    switch (this) {
      case AccountStatus.active:
        return 'active';
      case AccountStatus.pendingActivation:
        return 'pending_activation';
      case AccountStatus.inactive:
        return 'inactive';
      case AccountStatus.deactivated:
        return 'deactivated';
      case AccountStatus.suspended:
        return 'suspended';
    }
  }

  String get displayName {
    switch (this) {
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.pendingActivation:
        return 'Pending Activation';
      case AccountStatus.inactive:
        return 'Inactive';
      case AccountStatus.deactivated:
        return 'Deactivated';
      case AccountStatus.suspended:
        return 'Suspended';
    }
  }

  static AccountStatus fromString(String val) {
    switch (val.toLowerCase().replaceAll('-', '_')) {
      case 'active':
        return AccountStatus.active;
      case 'pending_activation':
      case 'pending':
      case 'pendingactivation':
        return AccountStatus.pendingActivation;
      case 'inactive':
        return AccountStatus.inactive;
      case 'deactivated':
        return AccountStatus.deactivated;
      case 'suspended':
        return AccountStatus.suspended;
      default:
        return AccountStatus.pendingActivation;
    }
  }
}

class UserModel {
  final String id;
  final String? firebaseUid;
  final String? instituteId;
  final String name;
  final String email;
  final String? phone;
  final AppRole role;
  final String? profilePictureUrl;
  final String? collegeId;
  final String? departmentId;
  final String? courseId;
  final String? sectionId;
  final String? semesterId;
  final AccountStatus accountStatus;
  final String? activationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    this.firebaseUid,
    this.instituteId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profilePictureUrl,
    this.collegeId,
    this.departmentId,
    this.courseId,
    this.sectionId,
    this.semesterId,
    this.accountStatus = AccountStatus.active,
    this.activationStatus,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firebaseUid: json['firebaseUid'] as String?,
      instituteId: json['instituteId'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: AppRoleExtension.fromValue(json['role'] as String? ?? 'STUDENT'),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      collegeId: json['collegeId'] as String?,
      departmentId: json['departmentId'] as String?,
      courseId: json['courseId'] as String?,
      sectionId: json['sectionId'] as String?,
      semesterId: json['semesterId'] as String?,
      accountStatus: json['accountStatus'] != null
          ? AccountStatusExtension.fromString(json['accountStatus'] as String)
          : AccountStatus.active,
      activationStatus: json['activationStatus'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'instituteId': instituteId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'profilePictureUrl': profilePictureUrl,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'courseId': courseId,
      'sectionId': sectionId,
      'semesterId': semesterId,
      'accountStatus': accountStatus.value,
      'activationStatus': activationStatus,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? firebaseUid,
    String? instituteId,
    String? name,
    String? email,
    String? phone,
    AppRole? role,
    String? profilePictureUrl,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? sectionId,
    String? semesterId,
    AccountStatus? accountStatus,
    String? activationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      instituteId: instituteId ?? this.instituteId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      courseId: courseId ?? this.courseId,
      sectionId: sectionId ?? this.sectionId,
      semesterId: semesterId ?? this.semesterId,
      accountStatus: accountStatus ?? this.accountStatus,
      activationStatus: activationStatus ?? this.activationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
