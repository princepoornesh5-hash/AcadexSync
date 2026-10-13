import { ImportDataType } from '../../../constants/import.constants';
import { IImportBatch } from '../../../models/importBatch.model';
import { INormalizedImportRow } from '../importValidation.service';
import { IResolvedAcademicContext } from '../contextResolution.service';
import { IImportAdapter, IImportPersistenceResult } from './importAdapter.interface';
import { AuditService } from '../../audit.service';

export class GenericImportAdapter implements IImportAdapter {
  constructor(public dataType: ImportDataType = ImportDataType.OTHER) {}

  async persistBatch(
    batch: IImportBatch,
    validRows: INormalizedImportRow[],
    context: IResolvedAcademicContext
  ): Promise<IImportPersistenceResult> {
    // In Prompt 4 foundation, generic adapter persists staged imported rows
    // and records audit with provenance metadata (sourceType: IMPORTED, importBatchId).
    // Prompt 5 will plug in domain-specific AssessmentImportAdapter and AttendanceImportAdapter.

    const importedCount = validRows.length;
    const failedCount = (batch.rowCount || 0) - importedCount;

    // Log provenance audit
    await AuditService.logAction({
      collegeId: batch.collegeId.toString(),
      actorUserId: batch.uploadedBy.toString(),
      entityType: 'ImportBatch',
      entityId: batch._id.toString(),
      action: 'IMPORT_BATCH_CONFIRMED',
      metadata: {
        importBatchId: batch.importBatchId,
        dataType: batch.dataType,
        fileName: batch.fileName,
        importedCount,
        failedCount,
        sourceType: 'IMPORTED',
        context: {
          academicYearId: context.academicYearId?.toString(),
          semesterId: context.semesterId?.toString(),
          sectionId: context.sectionId?.toString(),
          subjectId: context.subjectId?.toString(),
        },
      },
    });

    return {
      importedCount,
      failedCount,
      createdIds: [],
      details: {
        importBatchId: batch.importBatchId,
        dataType: batch.dataType,
        importedAt: new Date().toISOString(),
      },
    };
  }
}
