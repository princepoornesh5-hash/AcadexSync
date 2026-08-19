import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'role_enum.dart';

enum ActivationStatus { pending, used, expired, disabled }

extension ActivationStatusExtension on ActivationStatus {
  String get value => name;

  static ActivationStatus fromString(String val) {
    return ActivationStatus.values.firstWhere((e) => e.name == val, orElse: () => ActivationStatus.pending);
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
      role: json['role'] != null ? AppRoleExtension.fromValue(json['role'] as String) : AppRole.student,
      codeHash: json['codeHash'] as String,
      status: ActivationStatusExtension.fromString(json['status'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt'] as String) : null,
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
