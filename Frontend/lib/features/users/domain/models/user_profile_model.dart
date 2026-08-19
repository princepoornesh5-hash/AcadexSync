import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import 'user_status_enum.dart';

class UserProfileModel extends UserModel {
  final UserStatus status;
  final String phone;
  final String? employeeId;
  final String? rollNumber;
  final List<String> assignedSubjects;
  final List<String> assignedClasses;
  final double? attendancePercentage;

  const UserProfileModel({
    required super.id,
    super.firebaseUid,
    required super.name,
    required super.email,
    required super.role,
    super.profilePictureUrl,
    super.collegeId,
    super.departmentId,
    super.sectionId,
    super.semesterId,
    super.accountStatus,
    super.createdAt,
    super.updatedAt,
    super.lastLoginAt,
    required this.status,
    required this.phone,
    this.employeeId,
    this.rollNumber,
    this.assignedSubjects = const [],
    this.assignedClasses = const [],
    this.attendancePercentage,
  });

  @override
  UserProfileModel copyWith({
    String? id,
    String? firebaseUid,
    String? name,
    String? email,
    AppRole? role,
    String? profilePictureUrl,
    String? collegeId,
    String? departmentId,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    UserStatus? status,
    String? phone,
    String? employeeId,
    String? rollNumber,
    String? semesterId,
    String? sectionId,
    List<String>? assignedSubjects,
    List<String>? assignedClasses,
    double? attendancePercentage,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      employeeId: employeeId ?? this.employeeId,
      rollNumber: rollNumber ?? this.rollNumber,
      semesterId: semesterId ?? this.semesterId,
      sectionId: sectionId ?? this.sectionId,
      assignedSubjects: assignedSubjects ?? this.assignedSubjects,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      role: AppRoleExtension.fromValue(json['role'] as String),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      collegeId: json['collegeId'] as String?,
      departmentId: json['departmentId'] as String?,
      accountStatus: json['accountStatus'] != null 
          ? AccountStatusExtension.fromString(json['accountStatus'] as String)
          : AccountStatus.active,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
      status: json['status'] != null
          ? UserStatusExtension.fromValue(json['status'] as String)
          : UserStatus.active,
      phone: json['phone'] as String? ?? '',
      employeeId: json['employeeId'] as String?,
      rollNumber: json['rollNumber'] as String?,
      semesterId: json['semesterId'] as String?,
      sectionId: json['sectionId'] as String?,
      assignedSubjects: (json['assignedSubjects'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      assignedClasses: (json['assignedClasses'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble(),
    );
  }

  @override
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
      'accountStatus': accountStatus.value,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'status': status.value,
      'phone': phone,
      'employeeId': employeeId,
      'rollNumber': rollNumber,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'assignedSubjects': assignedSubjects,
      'assignedClasses': assignedClasses,
      'attendancePercentage': attendancePercentage,
    };
  }
}
