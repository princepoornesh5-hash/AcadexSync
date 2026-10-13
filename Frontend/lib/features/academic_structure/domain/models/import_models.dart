class ColumnMappingModel {
  final String sourceColumn;
  final String targetField;
  final String confidence;
  final String status;

  const ColumnMappingModel({
    required this.sourceColumn,
    required this.targetField,
    required this.confidence,
    required this.status,
  });

  factory ColumnMappingModel.fromJson(Map<String, dynamic> json) {
    return ColumnMappingModel(
      sourceColumn: json['sourceColumn']?.toString() ?? '',
      targetField: json['targetField']?.toString() ?? 'UNMAPPED',
      confidence: json['confidence']?.toString() ?? 'LOW',
      status: json['status']?.toString() ?? 'UNMAPPED',
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceColumn': sourceColumn,
        'targetField': targetField,
        'confidence': confidence,
        'status': status,
      };
}

class ImportIssueModel {
  final String code;
  final String severity;
  final String message;
  final String? column;
  final int rowNumber;

  const ImportIssueModel({
    required this.code,
    required this.severity,
    required this.message,
    this.column,
    required this.rowNumber,
  });

  factory ImportIssueModel.fromJson(Map<String, dynamic> json) {
    return ImportIssueModel(
      code: json['code']?.toString() ?? 'UNKNOWN',
      severity: json['severity']?.toString() ?? 'ERROR',
      message: json['message']?.toString() ?? '',
      column: json['column']?.toString(),
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
    );
  }
}

class NormalizedImportRowModel {
  final int rowNumber;
  final String status;
  final String? studentName;
  final String? studentPin;
  final String? rollNumber;
  final String? sectionName;
  final double? marks;
  final String? attendanceStatus;
  final List<ImportIssueModel> issues;

  const NormalizedImportRowModel({
    required this.rowNumber,
    required this.status,
    this.studentName,
    this.studentPin,
    this.rollNumber,
    this.sectionName,
    this.marks,
    this.attendanceStatus,
    this.issues = const [],
  });

  factory NormalizedImportRowModel.fromJson(Map<String, dynamic> json) {
    final res = json['studentResolution'] as Map<String, dynamic>? ?? {};
    final sem = json['semanticValues'] as Map<String, dynamic>? ?? {};
    final rawIssues = json['issues'] as List<dynamic>? ?? [];

    return NormalizedImportRowModel(
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'VALID',
      studentName: res['studentName']?.toString(),
      studentPin: res['studentPin']?.toString(),
      rollNumber: res['rollNumber']?.toString(),
      sectionName: res['sectionName']?.toString(),
      marks: (sem['marks'] as num?)?.toDouble(),
      attendanceStatus: sem['status']?.toString(),
      issues: rawIssues
          .map((i) => ImportIssueModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ImportSummaryModel {
  final int rowCount;
  final int validCount;
  final int warningCount;
  final int unresolvedCount;
  final int errorCount;
  final int conflictCount;
  final String? detectedPrecision;
  final int detailedCount;
  final int summaryCount;
  final int percentageOnlyCount;

  const ImportSummaryModel({
    this.rowCount = 0,
    this.validCount = 0,
    this.warningCount = 0,
    this.unresolvedCount = 0,
    this.errorCount = 0,
    this.conflictCount = 0,
    this.detectedPrecision,
    this.detailedCount = 0,
    this.summaryCount = 0,
    this.percentageOnlyCount = 0,
  });

  factory ImportSummaryModel.fromJson(Map<String, dynamic> json) {
    return ImportSummaryModel(
      rowCount: (json['rowCount'] as num?)?.toInt() ?? 0,
      validCount: (json['validCount'] as num?)?.toInt() ?? 0,
      warningCount: (json['warningCount'] as num?)?.toInt() ?? 0,
      unresolvedCount: (json['unresolvedCount'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      conflictCount: (json['conflictCount'] as num?)?.toInt() ?? 0,
      detectedPrecision: json['detectedPrecision']?.toString(),
      detailedCount: (json['detailedCount'] as num?)?.toInt() ?? 0,
      summaryCount: (json['summaryCount'] as num?)?.toInt() ?? 0,
      percentageOnlyCount: (json['percentageOnlyCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ImportBatchModel {
  final String id;
  final String importBatchId;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String dataType;
  final String status;
  final String? selectedSheet;
  final List<String> sheetNames;
  final List<String> headers;
  final List<ColumnMappingModel> columnMappings;
  final int rowCount;
  final int validCount;
  final int warningCount;
  final int unresolvedCount;
  final int errorCount;
  final int importedCount;
  final int failedCount;

  const ImportBatchModel({
    required this.id,
    required this.importBatchId,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.dataType,
    required this.status,
    this.selectedSheet,
    this.sheetNames = const [],
    this.headers = const [],
    this.columnMappings = const [],
    this.rowCount = 0,
    this.validCount = 0,
    this.warningCount = 0,
    this.unresolvedCount = 0,
    this.errorCount = 0,
    this.importedCount = 0,
    this.failedCount = 0,
  });

  factory ImportBatchModel.fromJson(Map<String, dynamic> json) {
    final rawSheets = json['sheetNames'] as List<dynamic>? ?? [];
    final rawHeaders = json['headers'] as List<dynamic>? ?? [];
    final rawMappings = json['columnMappings'] as List<dynamic>? ?? [];

    return ImportBatchModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      importBatchId: json['importBatchId']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? 'CSV',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      dataType: json['dataType']?.toString() ?? 'ASSESSMENT',
      status: json['status']?.toString() ?? 'UPLOADED',
      selectedSheet: json['selectedSheet']?.toString(),
      sheetNames: rawSheets.map((s) => s.toString()).toList(),
      headers: rawHeaders.map((h) => h.toString()).toList(),
      columnMappings: rawMappings
          .map((m) => ColumnMappingModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      rowCount: (json['rowCount'] as num?)?.toInt() ?? 0,
      validCount: (json['validCount'] as num?)?.toInt() ?? 0,
      warningCount: (json['warningCount'] as num?)?.toInt() ?? 0,
      unresolvedCount: (json['unresolvedCount'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      importedCount: (json['importedCount'] as num?)?.toInt() ?? 0,
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ImportPreviewResponseModel {
  final ImportBatchModel batch;
  final ImportSummaryModel summary;
  final List<NormalizedImportRowModel> previewRows;

  const ImportPreviewResponseModel({
    required this.batch,
    required this.summary,
    required this.previewRows,
  });

  factory ImportPreviewResponseModel.fromJson(Map<String, dynamic> json) {
    final rawRows = json['previewRows'] as List<dynamic>? ?? [];
    return ImportPreviewResponseModel(
      batch: ImportBatchModel.fromJson(json['batch'] as Map<String, dynamic>),
      summary: ImportSummaryModel.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
      previewRows: rawRows
          .map((r) =>
              NormalizedImportRowModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
