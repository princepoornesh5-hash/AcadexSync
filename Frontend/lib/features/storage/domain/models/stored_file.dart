import 'file_category.dart';
import 'file_status.dart';

class StoredFile {
  final String id;
  final String ownerUid;
  final String? collegeId;
  final String? departmentId;
  final FileCategory category;
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FileStatus status;
  final Map<String, dynamic> metadata;

  StoredFile({
    required this.id,
    required this.ownerUid,
    this.collegeId,
    this.departmentId,
    required this.category,
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
    required this.updatedAt,
    this.status = FileStatus.active,
    this.metadata = const {},
  });

  StoredFile copyWith({
    String? id,
    String? ownerUid,
    String? collegeId,
    String? departmentId,
    FileCategory? category,
    String? fileName,
    String? storagePath,
    String? downloadUrl,
    String? contentType,
    int? sizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    FileStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return StoredFile(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      collegeId: collegeId ?? this.collegeId,
      departmentId: departmentId ?? this.departmentId,
      category: category ?? this.category,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  factory StoredFile.fromJson(Map<String, dynamic> json) {
    return StoredFile(
      id: json['id'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? '',
      collegeId: json['collegeId'] as String?,
      departmentId: json['departmentId'] as String?,
      category: FileCategoryExtension.fromValue(json['category'] as String? ?? 'other'),
      fileName: json['fileName'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      status: FileStatusExtension.fromValue(json['status'] as String? ?? 'active'),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'collegeId': collegeId,
      'departmentId': departmentId,
      'category': category.value,
      'fileName': fileName,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.value,
      'metadata': metadata,
    };
  }
}
