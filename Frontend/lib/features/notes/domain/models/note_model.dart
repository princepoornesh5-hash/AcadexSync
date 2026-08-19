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
    switch (val) {
      case 'text_note':
        return ResourceType.textNote;
      case 'external_link':
        return ResourceType.externalLink;
      case 'file_attachment':
        return ResourceType.fileAttachment;
      default:
        return ResourceType.textNote;
    }
  }
}

enum NoteStatus { draft, published, unpublished }

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
    }
  }

  static NoteStatus fromString(String val) {
    return NoteStatus.values.firstWhere((e) => e.name == val, orElse: () => NoteStatus.draft);
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
  final String? storagePath;
  
  // Context
  final String subjectId;
  final String sectionId;
  final String courseId;
  final String departmentId;
  final String collegeId;
  final String semesterId;
  final String? academicYearId;
  
  // Ownership
  final String facultyId; // academic faculty profile ID
  final String authorUserId; // UserModel ID of the author

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
    this.storagePath,
    required this.subjectId,
    required this.sectionId,
    required this.courseId,
    required this.departmentId,
    required this.collegeId,
    required this.semesterId,
    this.academicYearId,
    required this.facultyId,
    required this.authorUserId,
    this.status = NoteStatus.draft,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPreviewable => NoteMimeHelper.isPreviewableFormat(fileType ?? fileName);

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      content: json['content'] as String?,
      externalUrl: json['externalUrl'] as String?,
      resourceType: ResourceTypeExtension.fromString(json['resourceType'] as String),
      chapter: json['chapter'] as String?,
      fileName: json['fileName'] as String?,
      fileType: json['fileType'] as String?,
      fileSize: json['fileSize'] as int?,
      fileUrl: json['fileUrl'] as String?,
      storagePath: json['storagePath'] as String?,
      subjectId: json['subjectId'] as String,
      sectionId: json['sectionId'] as String,
      courseId: json['courseId'] as String,
      departmentId: json['departmentId'] as String,
      collegeId: json['collegeId'] as String,
      semesterId: json['semesterId'] as String,
      academicYearId: json['academicYearId'] as String?,
      facultyId: json['facultyId'] as String,
      authorUserId: json['authorUserId'] as String,
      status: json['status'] != null ? NoteStatusExtension.fromString(json['status'] as String) : NoteStatus.draft,
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
      'storagePath': storagePath,
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
    if (date is String) return DateTime.parse(date);
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
    String? storagePath,
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
      storagePath: storagePath ?? this.storagePath,
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
