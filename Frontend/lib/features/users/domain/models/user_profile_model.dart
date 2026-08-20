import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import 'user_status_enum.dart';

class UserProfileModel extends UserModel {
  final UserStatus status;
  final String? employeeId;
  final String? rollNumber;
  final List<String> assignedSubjects;
  final List<String> assignedClasses;
  final double? attendancePercentage;

  @override
  String get phone => super.phone ?? '';

  const UserProfileModel({
    required super.id,
    super.firebaseUid,
    super.instituteId,
    required super.name,
    required super.email,
    String? phone,
    required super.role,
    super.profilePictureUrl,
    super.collegeId,
    super.departmentId,
    super.courseId,
    super.sectionId,
    super.semesterId,
    super.accountStatus,
    super.activationStatus,
    super.createdAt,
    super.updatedAt,
    super.lastLoginAt,
    required this.status,
    this.employeeId,
    this.rollNumber,
    this.assignedSubjects = const [],
    this.assignedClasses = const [],
    this.attendancePercentage,
  }) : super(phone: phone ?? '');

  @override
  UserProfileModel copyWith({
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
    UserStatus? status,
    String? employeeId,
    String? rollNumber,
    List<String>? assignedSubjects,
    List<String>? assignedClasses,
    double? attendancePercentage,
  }) {
    return UserProfileModel(
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
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      rollNumber: rollNumber ?? this.rollNumber,
      assignedSubjects: assignedSubjects ?? this.assignedSubjects,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
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
      status: json['status'] != null
          ? UserStatusExtension.fromValue(json['status'] as String)
          : UserStatus.active,
      employeeId: (json['employeeId'] ?? json['instituteId']) as String?,
      rollNumber: json['rollNumber'] as String?,
      assignedSubjects: (json['assignedSubjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      assignedClasses: (json['assignedClasses'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble(),
    );
  }

  @override
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
      'status': status.value,
      'employeeId': employeeId,
      'rollNumber': rollNumber,
      'assignedSubjects': assignedSubjects,
      'assignedClasses': assignedClasses,
      'attendancePercentage': attendancePercentage,
    };
  }
}
