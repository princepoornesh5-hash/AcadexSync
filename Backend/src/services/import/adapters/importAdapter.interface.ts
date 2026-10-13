import { ImportDataType } from '../../../constants/import.constants';
import { IImportBatch } from '../../../models/importBatch.model';
import { INormalizedImportRow } from '../importValidation.service';
import { IResolvedAcademicContext } from '../contextResolution.service';

export interface IImportPersistenceResult {
  importedCount: number;
  failedCount: number;
  createdIds?: string[];
  details?: Record<string, any>;
}

export interface IImportAdapter {
  dataType: ImportDataType;
  persistBatch(
    batch: IImportBatch,
    validRows: INormalizedImportRow[],
    context: IResolvedAcademicContext
  ): Promise<IImportPersistenceResult>;
}
