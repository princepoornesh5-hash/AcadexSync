import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/note_mime_helper.dart';

enum ResourceType { textNote, externalLink, fileAttachment }

extension ResourceTypeExtension on ResourceType {
  String get value {
    switch (this) {
      case ResourceType.textNote:
        return 'text_note';
      case ResourceType.externalLink:
        return 'external_link';
      case ResourceType.fileAttachment:
        return 'file_attachment';
    }
  }

  String get displayName {
    switch (this) {
      case ResourceType.textNote:
        return 'Text Note';
      case ResourceType.externalLink:
        return 'External Link';
      case ResourceType.fileAttachment:
        return 'File Attachment';
    }
  }

  static ResourceType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'text_note':
      case 'textnote':
        return ResourceType.textNote;
      case 'external_link':
      case 'externallink':
        return ResourceType.externalLink;
      case 'file_attachment':
      case 'fileattachment':
        return ResourceType.fileAttachment;
      default:
        return ResourceType.fileAttachment;
    }
  }
}

enum NoteStatus { draft, published, unpublished, archived }

extension NoteStatusExtension on NoteStatus {
  String get value => name;

  String get displayName {
    switch (this) {
      case NoteStatus.draft:
        return 'Draft';
      case NoteStatus.published:
        return 'Published';
      case NoteStatus.unpublished:
        return 'Unpublished';
      case NoteStatus.archived:
        return 'Archived';
    }
  }

  static NoteStatus fromString(String val) {
    final lower = val.toLowerCase();
    return NoteStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == lower,
      orElse: () => NoteStatus.draft,
    );
  }
}

class NoteModel {
  final String id;
  final String title;
  final String description;
  final String? content;
  final String? externalUrl;
  final ResourceType resourceType;
  
  // File Attachment Metadata
  final String? chapter;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String? fileUrl;
  final String? thumbnailUrl;
  final String? storagePath;
  final String? fileId;
  final String? mimeType;
  final int version;
  
  // Context
  final String subjectId;
  final String sectionId;
  final String courseId;
  final String departmentId;
  final String collegeId;
  final String semesterId;
  final String? academicYearId;
  
  // Ownership
  final String facultyId;
  final String authorUserId;

  // Status
  final NoteStatus status;
  
  // Timestamps
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    this.externalUrl,
    required this.resourceType,
    this.chapter,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.fileUrl,
    this.thumbnailUrl,
    this.storagePath,
    this.fileId,
    this.mimeType,
    this.version = 1,
    required this.subjectId,
    this.sectionId = '',
    this.courseId = '',
    this.departmentId = '',
    this.collegeId = '',
    required this.semesterId,
    this.academicYearId,
    this.facultyId = '',
    required this.authorUserId,
    this.status = NoteStatus.draft,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPreviewable => NoteMimeHelper.isPreviewableFormat(fileType ?? fileName);

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      content: json['content'] as String?,
      externalUrl: json['externalUrl'] as String?,
      resourceType: json['resourceType'] != null
          ? ResourceTypeExtension.fromString(json['resourceType'].toString())
          : ResourceType.fileAttachment,
      chapter: json['chapter'] as String?,
      fileName: (json['fileName'] ?? json['originalFileName']) as String?,
      fileType: (json['fileType'] ?? json['fileExtension'] ?? json['mimeType']) as String?,
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : (json['fileSize'] != null ? int.tryParse(json['fileSize'].toString()) : null),
      fileUrl: json['fileUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      storagePath: (json['storagePath'] ?? json['storageKey']) as String?,
      fileId: json['fileId'] as String?,
      mimeType: json['mimeType'] as String?,
      version: json['version'] is int
          ? json['version'] as int
          : (json['version'] != null ? int.tryParse(json['version'].toString()) ?? 1 : 1),
      subjectId: (json['subjectId'] ?? '').toString(),
      sectionId: (json['sectionId'] ?? '').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      departmentId: (json['departmentId'] ?? '').toString(),
      collegeId: (json['collegeId'] ?? '').toString(),
      semesterId: (json['semesterId'] ?? '').toString(),
      academicYearId: json['academicYearId']?.toString(),
      facultyId: (json['facultyId'] ?? '').toString(),
      authorUserId: (json['authorUserId'] ?? '').toString(),
      status: json['status'] != null
          ? NoteStatusExtension.fromString(json['status'].toString())
          : NoteStatus.draft,
      publishedAt: json['publishedAt'] != null ? _parseDate(json['publishedAt']) : null,
      createdAt: json['createdAt'] != null ? _parseDate(json['createdAt'])! : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? _parseDate(json['updatedAt'])! : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'externalUrl': externalUrl,
      'resourceType': resourceType.value,
      'chapter': chapter,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'storagePath': storagePath,
      'fileId': fileId,
      'mimeType': mimeType,
      'version': version,
      'subjectId': subjectId,
      'sectionId': sectionId,
      'courseId': courseId,
      'departmentId': departmentId,
      'collegeId': collegeId,
      'semesterId': semesterId,
      if (academicYearId != null) 'academicYearId': academicYearId,
      'facultyId': facultyId,
      'authorUserId': authorUserId,
      'status': status.value,
      'publishedAt': publishedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? externalUrl,
    ResourceType? resourceType,
    String? chapter,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? fileUrl,
    String? thumbnailUrl,
    String? storagePath,
    String? fileId,
    String? mimeType,
    int? version,
    String? subjectId,
    String? sectionId,
    String? courseId,
    String? departmentId,
    String? collegeId,
    String? semesterId,
    String? academicYearId,
    String? facultyId,
    String? authorUserId,
    NoteStatus? status,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      externalUrl: externalUrl ?? this.externalUrl,
      resourceType: resourceType ?? this.resourceType,
      chapter: chapter ?? this.chapter,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      storagePath: storagePath ?? this.storagePath,
      fileId: fileId ?? this.fileId,
      mimeType: mimeType ?? this.mimeType,
      version: version ?? this.version,
      subjectId: subjectId ?? this.subjectId,
      sectionId: sectionId ?? this.sectionId,
      courseId: courseId ?? this.courseId,
      departmentId: departmentId ?? this.departmentId,
      collegeId: collegeId ?? this.collegeId,
      semesterId: semesterId ?? this.semesterId,
      academicYearId: academicYearId ?? this.academicYearId,
      facultyId: facultyId ?? this.facultyId,
      authorUserId: authorUserId ?? this.authorUserId,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
