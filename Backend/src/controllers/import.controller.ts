import { Request, Response } from 'express';
import { ImportService } from '../services/import/import.service';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { asyncHandler } from '../utils/asyncHandler';
import { ImportDataType } from '../constants/import.constants';

export class ImportController {
  /**
   * Uploads and parses an Excel or CSV file.
   * Supports both multipart/form-data via req.file and base64 JSON via req.body.
   */
  static upload = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College tenant context missing');

    let buffer: Buffer;
    let fileName: string;

    if (req.file) {
      buffer = req.file.buffer;
      fileName = req.file.originalname;
    } else if (req.body.fileBase64 && req.body.fileName) {
      buffer = Buffer.from(req.body.fileBase64, 'base64');
      fileName = req.body.fileName;
    } else {
      throw ApiError.badRequest('No spreadsheet file provided. Provide a multipart file upload or fileBase64 and fileName.');
    }

    const dataType = (req.body.dataType as ImportDataType) || ImportDataType.ASSESSMENT;
    const academicContext = {
      collegeId: collegeId.toString(),
      academicYearId: req.body.academicYearId,
      semesterId: req.body.semesterId,
      sectionId: req.body.sectionId,
      departmentId: req.body.departmentId,
      courseId: req.body.courseId,
      subjectId: req.body.subjectId,
      facultyAssignmentId: req.body.facultyAssignmentId,
    };

    const result = await ImportService.uploadAndInitialize(collegeId.toString(), (req as any).user, {
      dataType,
      fileName,
      buffer,
      academicContext,
      selectedSheet: req.body.selectedSheet,
      defaultMaxMarks: req.body.defaultMaxMarks ? Number(req.body.defaultMaxMarks) : undefined,
    });

    return ApiResponse.success(res, result, 'File uploaded and parsed successfully', 201);
  });

  /**
   * Selects sheet and updates column mappings.
   */
  static updateSheetAndMappings = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College tenant context missing');

    const result = await ImportService.updateSheetAndMappings(
      collegeId.toString(),
      (req as any).user,
      req.params.id,
      req.body
    );

    return ApiResponse.success(res, result, 'Sheet and column mappings updated successfully');
  });

  /**
   * Validates staged data against academic context and generates preview.
   */
  static validateAndPreview = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College tenant context missing');

    const result = await ImportService.validateAndPreview(
      collegeId.toString(),
      (req as any).user,
      req.params.id,
      req.body
    );

    return ApiResponse.success(res, result, 'Data validated and preview generated successfully');
  });

  /**
   * Resolves an ambiguous or conflicting row manually.
   */
  static resolveRow = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College tenant context missing');

    const result = await ImportService.resolveRow(
      collegeId.toString(),
      (req as any).user,
      req.params.id,
      req.body
    );

    return ApiResponse.success(res, result, 'Row resolution recorded successfully');
  });

  /**
   * Explicitly confirms and persists the import batch.
   */
  static confirmImport = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College tenant context missing');

    const result = await ImportService.confirmImport(
      collegeId.toString(),
      (req as any).user,
      req.params.id,
      req.body
    );

    return ApiResponse.success(res, result, result.message);
  });

  /**
   * Gets details of an import batch.
   */
  static getBatch = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College tenant context missing');

    const result = await ImportService.getBatchDetails(
      collegeId.toString(),
      (req as any).user,
      req.params.id
    );

    return ApiResponse.success(res, result);
  });

  /**
   * Lists import batches.
   */
  static listBatches = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = (req as any).collegeId || (req as any).user?.collegeId;
    if (!collegeId) throw ApiError.unauthorized('College tenant context missing');

    const result = await ImportService.listBatches(
      collegeId.toString(),
      (req as any).user,
      req.query as any
    );

    return ApiResponse.success(res, result);
  });
}
