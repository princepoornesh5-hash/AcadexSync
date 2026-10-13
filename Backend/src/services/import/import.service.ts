import { Types } from 'mongoose';
import { AuthUserContext } from '../teachingAuthorization.service';
import { AppRole } from '../../constants/roles';
import {
  ImportBatchStatus,
  ImportDataType,
  RowValidationStatus,
  ImportIssueCode,
  IMPORT_CONSTRAINTS,
} from '../../constants/import.constants';
import {
  ImportBatch,
  IImportBatch,
} from '../../models/importBatch.model';
import { ApiError } from '../../utils/apiError';
import { SpreadsheetParserService } from './spreadsheetParser.service';
import { ColumnMapperService } from './columnMapper.service';
import {
  ContextResolutionService,
  IAcademicContextOptions,
  IResolvedAcademicContext,
} from './contextResolution.service';
import {
  ImportValidationService,
  INormalizedImportRow,
} from './importValidation.service';
import { IImportAdapter } from './adapters/importAdapter.interface';
import { GenericImportAdapter } from './adapters/genericImportAdapter';
import { AssessmentImportAdapter } from './adapters/assessmentImportAdapter';
import { AttendanceImportAdapter } from './adapters/attendanceImportAdapter';
import { AuditService } from '../audit.service';

export interface IUploadImportOptions {
  dataType: ImportDataType;
  fileName: string;
  buffer: Buffer;
  academicContext?: IAcademicContextOptions;
  selectedSheet?: string;
  defaultMaxMarks?: number;
}

export class ImportService {
  private static adapters: Map<ImportDataType, IImportAdapter> = new Map<ImportDataType, IImportAdapter>([
    [ImportDataType.OTHER, new GenericImportAdapter(ImportDataType.OTHER)],
    [ImportDataType.STUDENT_ROSTER, new GenericImportAdapter(ImportDataType.STUDENT_ROSTER)],
    [ImportDataType.ASSESSMENT, new AssessmentImportAdapter()],
    [ImportDataType.ATTENDANCE, new AttendanceImportAdapter()],
    [ImportDataType.ASSIGNMENT, new GenericImportAdapter(ImportDataType.ASSIGNMENT)],
    [ImportDataType.ACADEMIC_RESULT, new GenericImportAdapter(ImportDataType.ACADEMIC_RESULT)],
  ]);

  static registerAdapter(adapter: IImportAdapter) {
    this.adapters.set(adapter.dataType, adapter);
  }

  /**
   * Generates a stable unique import batch identifier (e.g., IMP-20261009-8A3F).
   */
  static generateImportBatchId(): string {
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const randomHex = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `IMP-${dateStr}-${randomHex}`;
  }

  /**
   * Asserts user has permission to initiate or manage academic imports.
   */
  static assertImportAccess(user: AuthUserContext) {
    if (user.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students are strictly prohibited from performing academic data imports.');
    }
  }

  /**
   * Resolves and verifies an existing ImportBatch belongs to user's college.
   */
  static async resolveBatch(
    collegeId: string,
    user: AuthUserContext,
    batchIdentifier: string
  ): Promise<IImportBatch> {
    this.assertImportAccess(user);

    let query: any = { collegeId: new Types.ObjectId(collegeId) };
    if (Types.ObjectId.isValid(batchIdentifier)) {
      query.$or = [{ _id: new Types.ObjectId(batchIdentifier) }, { importBatchId: batchIdentifier }];
    } else {
      query.importBatchId = batchIdentifier;
    }

    const batch = await ImportBatch.findOne(query);
    if (!batch) {
      throw ApiError.notFound(`Import batch '${batchIdentifier}' not found or belongs to another tenant.`);
    }

    return batch;
  }

  /**
   * STEP 1: Upload file, detect sheets, extract headers, and generate initial mappings.
   */
  static async uploadAndInitialize(
    collegeId: string,
    user: AuthUserContext,
    options: IUploadImportOptions
  ): Promise<{
    batch: IImportBatch;
    sheetMetadata: ReturnType<typeof SpreadsheetParserService.inspectSheets>;
    previewData: ReturnType<typeof SpreadsheetParserService.extractSheetData>;
  }> {
    this.assertImportAccess(user);

    const { buffer, fileName, dataType } = options;
    const fileType = fileName.toLowerCase().endsWith('.csv') ? 'CSV' : 'XLSX';

    // 1. Parse workbook buffer
    const workbook = SpreadsheetParserService.parseWorkbook(buffer, fileName);
    const sheetMetadata = SpreadsheetParserService.inspectSheets(workbook);

    if (sheetMetadata.length === 0) {
      throw ApiError.badRequest('No readable sheets found in file');
    }

    // 2. Select initial sheet
    const targetSheetName = options.selectedSheet || sheetMetadata[0].sheetName;
    const sheetData = SpreadsheetParserService.extractSheetData(workbook, targetSheetName);

    // 3. Auto-detect column mappings
    const columnMappings = ColumnMapperService.generateMappings(sheetData.headers, dataType);

    // 4. Resolve academic context if provided
    let resolvedAcademicContext: IResolvedAcademicContext | undefined;
    if (options.academicContext) {
      resolvedAcademicContext = await ContextResolutionService.resolveAcademicContext({
        ...options.academicContext,
        collegeId,
      });
    }

    // 5. Create persistent ImportBatch record
    const importBatchId = this.generateImportBatchId();
    const batch = await ImportBatch.create({
      importBatchId,
      collegeId: new Types.ObjectId(collegeId),
      uploadedBy: new Types.ObjectId(user.id),
      uploadedAt: new Date(),
      dataType,
      academicYearId: resolvedAcademicContext?.academicYearId,
      semesterId: resolvedAcademicContext?.semesterId,
      sectionId: resolvedAcademicContext?.sectionId,
      departmentId: resolvedAcademicContext?.departmentId,
      courseId: resolvedAcademicContext?.courseId,
      subjectId: resolvedAcademicContext?.subjectId,
      facultyAssignmentId: resolvedAcademicContext?.facultyAssignmentId,
      fileName,
      fileType,
      fileSize: buffer.length,
      status: ImportBatchStatus.PARSED,
      selectedSheet: targetSheetName,
      sheetNames: workbook.SheetNames,
      detectedHeaderRow: sheetData.headerRowIndex,
      headers: sheetData.headers,
      columnMappings,
      rowCount: sheetData.rows.length,
      stagedRows: sheetData.rows.slice(0, IMPORT_CONSTRAINTS.MAX_ROWS),
      metadata: {
        rawSheetCount: workbook.SheetNames.length,
        defaultMaxMarks: options.defaultMaxMarks,
      },
    });

    await AuditService.logAction({
      collegeId,
      actorUserId: user.id,
      entityType: 'ImportBatch',
      entityId: batch._id.toString(),
      action: 'IMPORT_BATCH_UPLOADED',
      metadata: {
        importBatchId,
        fileName,
        fileType,
        rowCount: sheetData.rows.length,
        dataType,
      },
    });

    return {
      batch,
      sheetMetadata,
      previewData: sheetData,
    };
  }

  /**
   * STEP 2 & 3: Select or change sheet, update column mappings.
   */
  static async updateSheetAndMappings(
    collegeId: string,
    user: AuthUserContext,
    batchIdentifier: string,
    payload: {
      selectedSheet?: string;
      customMappings?: Array<{ sourceColumn: string; targetField: string }>;
    }
  ): Promise<IImportBatch> {
    const batch = await this.resolveBatch(collegeId, user, batchIdentifier);

    if (
      batch.status === ImportBatchStatus.COMPLETED ||
      batch.status === ImportBatchStatus.PARTIALLY_COMPLETED ||
      batch.status === ImportBatchStatus.IMPORTING
    ) {
      throw ApiError.badRequest('Cannot alter mappings of an import batch that is already finalized or importing.');
    }

    if (payload.customMappings && payload.customMappings.length > 0) {
      batch.columnMappings = ColumnMapperService.applyUserMappings(
        batch.columnMappings,
        payload.customMappings
      );
    }

    batch.status = ImportBatchStatus.MAPPED;
    await batch.save();
    return batch;
  }

  /**
   * STEP 4 & 5: Validate staged rows against academic context, resolve students, and generate preview.
   */
  static async validateAndPreview(
    collegeId: string,
    user: AuthUserContext,
    batchIdentifier: string,
    contextOptions?: IAcademicContextOptions
  ): Promise<{
    batch: IImportBatch;
    resolvedContext: IResolvedAcademicContext;
    summary: ReturnType<typeof ImportValidationService.validateRows>['summary'];
    previewRows: INormalizedImportRow[];
  }> {
    const batch = await this.resolveBatch(collegeId, user, batchIdentifier);

    if (
      batch.status === ImportBatchStatus.COMPLETED ||
      batch.status === ImportBatchStatus.PARTIALLY_COMPLETED ||
      batch.status === ImportBatchStatus.IMPORTING
    ) {
      throw ApiError.badRequest('Cannot re-validate an import batch that has already been finalized.');
    }

    // 1. Resolve context
    const academicContextOptions: IAcademicContextOptions = {
      collegeId,
      academicYearId: contextOptions?.academicYearId || batch.academicYearId?.toString(),
      semesterId: contextOptions?.semesterId || batch.semesterId?.toString(),
      sectionId: contextOptions?.sectionId || batch.sectionId?.toString(),
      departmentId: contextOptions?.departmentId || batch.departmentId?.toString(),
      courseId: contextOptions?.courseId || batch.courseId?.toString(),
      subjectId: contextOptions?.subjectId || batch.subjectId?.toString(),
      facultyAssignmentId: contextOptions?.facultyAssignmentId || batch.facultyAssignmentId?.toString(),
      academicYearName: contextOptions?.academicYearName,
      semesterName: contextOptions?.semesterName,
      sectionName: contextOptions?.sectionName,
      subjectCode: contextOptions?.subjectCode,
    };

    const resolvedContext = await ContextResolutionService.resolveAcademicContext(academicContextOptions);

    // Update batch context fields
    if (resolvedContext.academicYearId) batch.academicYearId = resolvedContext.academicYearId;
    if (resolvedContext.semesterId) batch.semesterId = resolvedContext.semesterId;
    if (resolvedContext.sectionId) batch.sectionId = resolvedContext.sectionId;
    if (resolvedContext.departmentId) batch.departmentId = resolvedContext.departmentId;
    if (resolvedContext.courseId) batch.courseId = resolvedContext.courseId;
    if (resolvedContext.subjectId) batch.subjectId = resolvedContext.subjectId;
    if (resolvedContext.facultyAssignmentId) batch.facultyAssignmentId = resolvedContext.facultyAssignmentId;

    // 2. Prepare batched student resolution maps
    const studentContext = await ContextResolutionService.prepareStudentResolutionContext(
      new Types.ObjectId(collegeId),
      resolvedContext
    );

    // 3. Validate rows
    const stagedRows = batch.stagedRows || [];
    const defaultMaxMarks = (batch.metadata as any)?.defaultMaxMarks;

    const { normalizedRows, summary } = ImportValidationService.validateRows(
      stagedRows,
      batch.columnMappings,
      batch.dataType,
      studentContext,
      defaultMaxMarks
    );

    // Apply any previously stored user row resolutions
    if (batch.userResolutions && batch.userResolutions.length > 0) {
      const resMap = new Map(batch.userResolutions.map((ur) => [ur.rowNumber, ur]));
      for (const nr of normalizedRows) {
        if (resMap.has(nr.rowNumber)) {
          const res = resMap.get(nr.rowNumber)!;
          if (res.action === 'EXCLUDE') {
            nr.status = RowValidationStatus.INVALID;
            nr.issues.push({
              code: ImportIssueCode.INVALID_VALUE,
              severity: ImportValidationService.name as any,
              message: 'Excluded by user resolution',
              rowNumber: nr.rowNumber,
            });
          }
        }
      }
    }

    // 4. Update batch metrics
    batch.rowCount = summary.rowCount;
    batch.validCount = summary.validCount;
    batch.warningCount = summary.warningCount;
    batch.unresolvedCount = summary.unresolvedCount;
    batch.errorCount = summary.errorCount;
    batch.status = ImportBatchStatus.READY_FOR_CONFIRMATION;
    batch.previewSummary = {
      ...summary,
      validatedAt: new Date().toISOString(),
    };

    // Store bounded validated rows in batch for final confirmation
    (batch as any).validatedStagedRows = normalizedRows;
    await batch.save();

    return {
      batch,
      resolvedContext,
      summary,
      previewRows: normalizedRows.slice(0, IMPORT_CONSTRAINTS.MAX_PREVIEW_ROWS),
    };
  }

  /**
   * Resolves an ambiguous or unresolved row manually.
   */
  static async resolveRow(
    collegeId: string,
    user: AuthUserContext,
    batchIdentifier: string,
    resolution: {
      rowNumber: number;
      resolvedEnrollmentId?: string;
      action: 'RESOLVE' | 'EXCLUDE';
      reason?: string;
    }
  ): Promise<IImportBatch> {
    const batch = await this.resolveBatch(collegeId, user, batchIdentifier);

    if (!batch.userResolutions) {
      batch.userResolutions = [];
    }

    // Replace or push
    const idx = batch.userResolutions.findIndex((r) => r.rowNumber === resolution.rowNumber);
    if (idx >= 0) {
      batch.userResolutions[idx] = resolution;
    } else {
      batch.userResolutions.push(resolution);
    }

    await batch.save();
    return batch;
  }

  /**
   * STEP 6 & 7: Explicit Confirmation & Persistence.
   */
  static async confirmImport(
    collegeId: string,
    user: AuthUserContext,
    batchIdentifier: string,
    options: { allowPartial?: boolean } = {}
  ): Promise<{
    batch: IImportBatch;
    message: string;
    importedCount: number;
    failedCount: number;
  }> {
    const batch = await this.resolveBatch(collegeId, user, batchIdentifier);

    // Idempotency: Protect against repeated or concurrent import confirmations
    if (
      batch.status === ImportBatchStatus.COMPLETED ||
      batch.status === ImportBatchStatus.PARTIALLY_COMPLETED
    ) {
      return {
        batch,
        message: 'This import batch has already been completed.',
        importedCount: batch.importedCount,
        failedCount: batch.failedCount,
      };
    }

    if (batch.status === ImportBatchStatus.IMPORTING) {
      throw ApiError.badRequest('Import is currently in progress. Please wait for completion.');
    }

    // Must be validated before confirmation
    if (
      batch.status !== ImportBatchStatus.READY_FOR_CONFIRMATION &&
      batch.status !== ImportBatchStatus.VALIDATED
    ) {
      throw ApiError.badRequest(
        `Import batch must be validated before confirmation. Current status: ${batch.status}`
      );
    }

    const { allowPartial = false } = options;

    // Check for blocking errors
    if (!allowPartial && (batch.errorCount > 0 || batch.unresolvedCount > 0)) {
      throw ApiError.badRequest(
        `Cannot confirm import with ${batch.errorCount} invalid rows and ${batch.unresolvedCount} unresolved rows. Please resolve issues or explicitly enable partial import.`
      );
    }

    batch.status = ImportBatchStatus.IMPORTING;
    await batch.save();

    try {
      const resolvedContext = await ContextResolutionService.resolveAcademicContext({
        collegeId,
        academicYearId: batch.academicYearId?.toString(),
        semesterId: batch.semesterId?.toString(),
        sectionId: batch.sectionId?.toString(),
        departmentId: batch.departmentId?.toString(),
        courseId: batch.courseId?.toString(),
        subjectId: batch.subjectId?.toString(),
        facultyAssignmentId: batch.facultyAssignmentId?.toString(),
      });

      const studentContext = await ContextResolutionService.prepareStudentResolutionContext(
        new Types.ObjectId(collegeId),
        resolvedContext
      );

      const defaultMaxMarks = (batch.metadata as any)?.defaultMaxMarks;
      const { normalizedRows } = ImportValidationService.validateRows(
        batch.stagedRows || [],
        batch.columnMappings,
        batch.dataType,
        studentContext,
        defaultMaxMarks
      );

      const validRows = normalizedRows.filter(
        (r) => r.status === RowValidationStatus.VALID || r.status === RowValidationStatus.WARNING
      );

      // Select registered adapter for dataType
      const adapter = this.adapters.get(batch.dataType) || new GenericImportAdapter(batch.dataType);

      const persistenceResult = await adapter.persistBatch(
        batch,
        validRows,
        resolvedContext
      );

      batch.importedCount = persistenceResult.importedCount;
      batch.failedCount = batch.rowCount - persistenceResult.importedCount;

      batch.status =
        batch.failedCount === 0
          ? ImportBatchStatus.COMPLETED
          : ImportBatchStatus.PARTIALLY_COMPLETED;

      await batch.save();

      const message =
        batch.failedCount > 0
          ? `Import partially completed: ${batch.importedCount} rows imported, ${batch.failedCount} rows skipped/failed.`
          : `Import completed successfully: all ${batch.importedCount} rows imported.`;

      return {
        batch,
        message,
        importedCount: batch.importedCount,
        failedCount: batch.failedCount,
      };
    } catch (err: any) {
      batch.status = ImportBatchStatus.FAILED;
      batch.errorMessage = err.message || 'Persistence failed';
      await batch.save();
      throw err;
    }
  }

  /**
   * Retrieves single import batch details.
   */
  static async getBatchDetails(
    collegeId: string,
    user: AuthUserContext,
    batchIdentifier: string
  ): Promise<IImportBatch> {
    return this.resolveBatch(collegeId, user, batchIdentifier);
  }

  /**
   * Lists import batches for the college tenant.
   */
  static async listBatches(
    collegeId: string,
    user: AuthUserContext,
    filter: { dataType?: ImportDataType; status?: ImportBatchStatus; limit?: number } = {}
  ): Promise<IImportBatch[]> {
    this.assertImportAccess(user);

    const query: any = { collegeId: new Types.ObjectId(collegeId) };
    if (filter.dataType) query.dataType = filter.dataType;
    if (filter.status) query.status = filter.status;

    return ImportBatch.find(query)
      .sort({ createdAt: -1 })
      .limit(filter.limit || 50);
  }
}
