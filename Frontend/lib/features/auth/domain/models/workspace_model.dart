import 'role_enum.dart';

class WorkspaceMembershipModel {
  final String id;
  final String collegeId;
  final String collegeName;
  final String collegeCode;
  final String? collegeStatus;
  final String? collegeCity;
  final String? collegeState;
  final String status;
  final bool isDefault;
  final List<AppRole> roles;
  final AppRole primaryRole;
  final String? departmentId;
  final String? departmentName;
  final String? departmentCode;
  final String? instituteId;
  final DateTime? joinedAt;
  final DateTime? lastAccessedAt;

  const WorkspaceMembershipModel({
    required this.id,
    required this.collegeId,
    required this.collegeName,
    required this.collegeCode,
    this.collegeStatus,
    this.collegeCity,
    this.collegeState,
    required this.status,
    this.isDefault = false,
    required this.roles,
    required this.primaryRole,
    this.departmentId,
    this.departmentName,
    this.departmentCode,
    this.instituteId,
    this.joinedAt,
    this.lastAccessedAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory WorkspaceMembershipModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = (json['roles'] as List<dynamic>?) ?? [];
    final parsedRoles = rawRoles
        .map((r) => AppRoleExtension.fromValue(r.toString()))
        .toList();

    final primaryRoleVal = json['primaryRole'] != null
        ? AppRoleExtension.fromValue(json['primaryRole'].toString())
        : (parsedRoles.isNotEmpty ? parsedRoles.first : AppRole.student);

    final firstDept =
        (json['departments'] is List &&
            (json['departments'] as List).isNotEmpty)
        ? (json['departments'] as List).first as Map<String, dynamic>?
        : null;

    return WorkspaceMembershipModel(
      id: (json['id'] ?? json['_id'] ?? json['membershipId'] ?? '').toString(),
      collegeId: (json['collegeId'] ?? '').toString(),
      collegeName: (json['collegeName'] ?? 'College Workspace').toString(),
      collegeCode: (json['collegeCode'] ?? '').toString(),
      collegeStatus: json['collegeStatus'] as String?,
      collegeCity: json['collegeCity'] as String?,
      collegeState: json['collegeState'] as String?,
      status: (json['status'] ?? 'ACTIVE').toString(),
      isDefault: json['isDefault'] == true,
      roles: parsedRoles,
      primaryRole: primaryRoleVal,
      departmentId: (json['departmentId'] ?? firstDept?['id'])?.toString(),
      departmentName: (json['departmentName'] ?? firstDept?['name']) as String?,
      departmentCode: (json['departmentCode'] ?? firstDept?['code']) as String?,
      instituteId: json['instituteId'] as String?,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.tryParse(json['lastAccessedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeId': collegeId,
      'collegeName': collegeName,
      'collegeCode': collegeCode,
      'collegeStatus': collegeStatus,
      'collegeCity': collegeCity,
      'collegeState': collegeState,
      'status': status,
      'isDefault': isDefault,
      'roles': roles.map((r) => r.value).toList(),
      'primaryRole': primaryRole.value,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'departmentCode': departmentCode,
      'instituteId': instituteId,
      'joinedAt': joinedAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    };
  }

  WorkspaceMembershipModel copyWith({
    String? id,
    String? collegeId,
    String? collegeName,
    String? collegeCode,
    String? collegeStatus,
    String? collegeCity,
    String? collegeState,
    String? status,
    bool? isDefault,
    List<AppRole>? roles,
    AppRole? primaryRole,
    String? departmentId,
    String? departmentName,
    String? departmentCode,
    String? instituteId,
    DateTime? joinedAt,
    DateTime? lastAccessedAt,
  }) {
    return WorkspaceMembershipModel(
      id: id ?? this.id,
      collegeId: collegeId ?? this.collegeId,
      collegeName: collegeName ?? this.collegeName,
      collegeCode: collegeCode ?? this.collegeCode,
      collegeStatus: collegeStatus ?? this.collegeStatus,
      collegeCity: collegeCity ?? this.collegeCity,
      collegeState: collegeState ?? this.collegeState,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      roles: roles ?? this.roles,
      primaryRole: primaryRole ?? this.primaryRole,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      departmentCode: departmentCode ?? this.departmentCode,
      instituteId: instituteId ?? this.instituteId,
      joinedAt: joinedAt ?? this.joinedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}

class SwitchWorkspaceResult {
  final String accessToken;
  final Map<String, dynamic> activeWorkspace;
  final Map<String, dynamic> userJson;

  const SwitchWorkspaceResult({
    required this.accessToken,
    required this.activeWorkspace,
    required this.userJson,
  });

  factory SwitchWorkspaceResult.fromJson(Map<String, dynamic> json) {
    return SwitchWorkspaceResult(
      accessToken: (json['accessToken'] ?? '').toString(),
      activeWorkspace: (json['activeWorkspace'] as Map<String, dynamic>?) ?? {},
      userJson: (json['user'] as Map<String, dynamic>?) ?? {},
    );
  }
}
