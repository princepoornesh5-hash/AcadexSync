import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'role_enum.dart';

enum ActivationStatus { pending, used, expired, disabled }

extension ActivationStatusExtension on ActivationStatus {
  String get value => name;

  static ActivationStatus fromString(String val) {
    return ActivationStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ActivationStatus.pending,
    );
  }
}

class ActivationRecord {
  final String id;
  final String? studentId;
  final String? rollNumber;
  final String? facultyId;
  final String? employeeId;
  final AppRole role;
  final String codeHash;
  final ActivationStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? usedAt;

  const ActivationRecord({
    required this.id,
    this.studentId,
    this.rollNumber,
    this.facultyId,
    this.employeeId,
    this.role = AppRole.student,
    required this.codeHash,
    this.status = ActivationStatus.pending,
    required this.expiresAt,
    required this.createdAt,
    this.usedAt,
  });

  factory ActivationRecord.fromJson(Map<String, dynamic> json) {
    return ActivationRecord(
      id: json['id'] as String,
      studentId: json['studentId'] as String?,
      rollNumber: json['rollNumber'] as String?,
      facultyId: json['facultyId'] as String?,
      employeeId: json['employeeId'] as String?,
      role: json['role'] != null
          ? AppRoleExtension.fromValue(json['role'] as String)
          : AppRole.student,
      codeHash: json['codeHash'] as String,
      status: ActivationStatusExtension.fromString(json['status'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      usedAt: json['usedAt'] != null
          ? DateTime.parse(json['usedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (studentId != null) 'studentId': studentId,
      if (rollNumber != null) 'rollNumber': rollNumber,
      if (facultyId != null) 'facultyId': facultyId,
      if (employeeId != null) 'employeeId': employeeId,
      'role': role.value,
      'codeHash': codeHash,
      'status': status.value,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      if (usedAt != null) 'usedAt': usedAt?.toIso8601String(),
    };
  }

  ActivationRecord copyWith({
    String? id,
    String? studentId,
    String? rollNumber,
    String? facultyId,
    String? employeeId,
    AppRole? role,
    String? codeHash,
    ActivationStatus? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? usedAt,
  }) {
    return ActivationRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      rollNumber: rollNumber ?? this.rollNumber,
      facultyId: facultyId ?? this.facultyId,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      codeHash: codeHash ?? this.codeHash,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  static String hashCodeString(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class ContactOption {
  final String method; // 'email' | 'phone'
  final String maskedValue;

  const ContactOption({required this.method, required this.maskedValue});

  factory ContactOption.fromJson(Map<String, dynamic> json) {
    return ContactOption(
      method: (json['method'] ?? json['type'] ?? '') as String,
      maskedValue: (json['maskedValue'] ?? json['masked'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'method': method,
    'maskedValue': maskedValue,
  };
}

class ActivationValidationResult {
  final String activationFlowId;
  final String displayName;
  final String institutionName;
  final String collegeCode;
  final String role;
  final bool isExistingUser;
  final List<ContactOption> contactOptions;
  final String permittedNextAction;

  const ActivationValidationResult({
    required this.activationFlowId,
    required this.displayName,
    required this.institutionName,
    required this.collegeCode,
    required this.role,
    required this.isExistingUser,
    required this.contactOptions,
    required this.permittedNextAction,
  });

  factory ActivationValidationResult.fromJson(Map<String, dynamic> json) {
    final rawOptions =
        json['contactOptions'] as List<dynamic>? ??
        json['availableChannels'] as List<dynamic>? ??
        [];
    return ActivationValidationResult(
      activationFlowId: (json['activationFlowId'] ?? '') as String,
      displayName: (json['displayName'] ?? json['name'] ?? '') as String,
      institutionName:
          (json['institutionName'] ?? json['collegeName'] ?? '') as String,
      collegeCode: (json['collegeCode'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      isExistingUser:
          (json['isExistingUser'] ?? json['isExistingActiveUser'] ?? false)
              as bool,
      contactOptions: rawOptions
          .map((item) => ContactOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      permittedNextAction: (json['permittedNextAction'] ?? '') as String,
    );
  }
}

class SendOtpResult {
  final String message;
  final String maskedDestination;
  final int cooldownSeconds;
  final int expiresInSeconds;

  const SendOtpResult({
    required this.message,
    required this.maskedDestination,
    required this.cooldownSeconds,
    required this.expiresInSeconds,
  });

  factory SendOtpResult.fromJson(Map<String, dynamic> json) {
    return SendOtpResult(
      message: (json['message'] ?? '') as String,
      maskedDestination: (json['maskedDestination'] ?? '') as String,
      cooldownSeconds: (json['cooldownSeconds'] ?? 60) as int,
      expiresInSeconds: (json['expiresInSeconds'] ?? 600) as int,
    );
  }
}

class VerifyOtpResult {
  final String activationToken;
  final bool isExistingActiveUser;
  final String message;

  const VerifyOtpResult({
    required this.activationToken,
    required this.isExistingActiveUser,
    required this.message,
  });

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResult(
      activationToken: (json['activationToken'] ?? '') as String,
      isExistingActiveUser: (json['isExistingActiveUser'] ?? false) as bool,
      message: (json['message'] ?? '') as String,
    );
  }
}

class CompleteActivationResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? user;

  const CompleteActivationResult({
    required this.success,
    required this.message,
    this.user,
  });

  factory CompleteActivationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CompleteActivationResult(
      success: (json['success'] ?? true) as bool,
      message:
          (data['message'] ??
                  json['message'] ??
                  'Account activated successfully')
              as String,
      user: data['user'] as Map<String, dynamic>?,
    );
  }
}
