import * as XLSX from 'xlsx';
import { ApiError } from '../../utils/apiError';
import { IMPORT_CONSTRAINTS } from '../../constants/import.constants';

export interface ISheetMetadata {
  sheetName: string;
  totalRowCount: number;
  nonEmptyRowCount: number;
  candidateHeaderRowIndex: number;
  detectedHeaders: string[];
  confidence: 'HIGH' | 'MEDIUM' | 'LOW';
}

export interface IParsedSheetData {
  sheetName: string;
  headerRowIndex: number;
  headers: string[];
  rows: Array<{
    rowNumber: number; // 1-indexed relative to spreadsheet
    values: Record<string, any>;
  }>;
}

export class SpreadsheetParserService {
  private static readonly HEADER_KEYWORDS = [
    'pin',
    'roll',
    'rollno',
    'rollnumber',
    'adm',
    'admission',
    'admissionnumber',
    'reg',
    'registration',
    'student',
    'studentname',
    'name',
    'fullname',
    'marks',
    'mark',
    'score',
    'ut1',
    'ut2',
    'ut',
    'internal',
    'mid',
    'total',
    'present',
    'absent',
    'status',
    'attendance',
    'percent',
    'percentage',
    'remarks',
  ];

  /**
   * Validates and reads an uploaded file buffer into an XLSX workbook.
   */
  static parseWorkbook(buffer: Buffer, fileName: string): XLSX.WorkBook {
    if (!buffer || buffer.length === 0) {
      throw ApiError.badRequest('Uploaded file buffer is empty or corrupted');
    }

    if (buffer.length > IMPORT_CONSTRAINTS.MAX_FILE_SIZE_BYTES) {
      throw ApiError.badRequest(
        `File size exceeds maximum permitted limit of ${IMPORT_CONSTRAINTS.MAX_FILE_SIZE_BYTES / (1024 * 1024)}MB`
      );
    }

    const lower = fileName.toLowerCase();
    const isSupported = IMPORT_CONSTRAINTS.SUPPORTED_EXTENSIONS.some((ext) => lower.endsWith(ext));
    if (!isSupported) {
      throw ApiError.badRequest(
        `Unsupported file format '${fileName}'. Allowed formats: ${IMPORT_CONSTRAINTS.SUPPORTED_EXTENSIONS.join(', ')}`
      );
    }

    if (lower.endsWith('.xlsx')) {
      const isZip = buffer.length >= 4 && buffer[0] === 0x50 && buffer[1] === 0x4B;
      if (!isZip) {
        throw ApiError.badRequest('File is not a valid XLSX workbook (corrupted or invalid format)');
      }
    }
    if (lower.endsWith('.xls')) {
      const isBiff = buffer.length >= 4 && buffer[0] === 0xD0 && buffer[1] === 0xCF;
      if (!isBiff) {
        throw ApiError.badRequest('File is not a valid XLS workbook (corrupted or invalid format)');
      }
    }

    try {
      const workbook = XLSX.read(buffer, {
        type: 'buffer',
        cellFormula: false,
        cellHTML: false,
        cellText: true,
        cellDates: true,
        dateNF: 'yyyy-mm-dd',
        raw: false,
        dense: false,
      });

      if (!workbook || !workbook.SheetNames || workbook.SheetNames.length === 0) {
        throw ApiError.badRequest('Workbook contains no readable sheets');
      }

      if (workbook.SheetNames.length > IMPORT_CONSTRAINTS.MAX_SHEETS) {
        throw ApiError.badRequest(
          `Workbook contains ${workbook.SheetNames.length} sheets, exceeding maximum limit of ${IMPORT_CONSTRAINTS.MAX_SHEETS}`
        );
      }

      return workbook;
    } catch (err: any) {
      if (err instanceof ApiError) throw err;
      throw ApiError.badRequest(`Failed to parse spreadsheet file: ${err.message || 'Corrupted file'}`);
    }
  }

  /**
   * Inspects all sheets in a workbook and detects candidate header rows and column metadata.
   */
  static inspectSheets(workbook: XLSX.WorkBook): ISheetMetadata[] {
    const results: ISheetMetadata[] = [];

    for (const sheetName of workbook.SheetNames) {
      const sheet = workbook.Sheets[sheetName];
      if (!sheet) continue;

      const rawRows: any[][] = XLSX.utils.sheet_to_json(sheet, {
        header: 1,
        defval: '',
        blankrows: false,
        dateNF: 'yyyy-mm-dd',
        raw: false,
      });

      const totalRowCount = rawRows.length;
      const nonEmptyRows = rawRows.filter((r) => r.some((c) => String(c).trim().length > 0));
      const nonEmptyRowCount = nonEmptyRows.length;

      const detection = this.detectHeaderRow(rawRows);

      results.push({
        sheetName,
        totalRowCount,
        nonEmptyRowCount,
        candidateHeaderRowIndex: detection.headerRowIndex,
        detectedHeaders: detection.headers,
        confidence: detection.confidence,
      });
    }

    return results;
  }

  /**
   * Heuristic bounded header detection:
   * Inspects up to the first 10 rows to detect the real table header row.
   */
  static detectHeaderRow(rawRows: any[][]): {
    headerRowIndex: number;
    headers: string[];
    confidence: 'HIGH' | 'MEDIUM' | 'LOW';
  } {
    if (!rawRows || rawRows.length === 0) {
      return { headerRowIndex: 0, headers: [], confidence: 'LOW' };
    }

    const maxInspect = Math.min(10, rawRows.length);
    let bestRowIdx = 0;
    let bestScore = -1;
    let bestHeaders: string[] = [];

    for (let i = 0; i < maxInspect; i++) {
      const row = rawRows[i] || [];
      const cells = row.map((c) => String(c ?? '').trim());
      const nonEmptyCells = cells.filter((c) => c.length > 0);

      if (nonEmptyCells.length < 2) {
        continue;
      }

      let score = 0;
      let keywordMatches = 0;

      for (const cell of nonEmptyCells) {
        const cleanCell = cell.toLowerCase().replace(/[^a-z0-9]/g, '');
        const matched = this.HEADER_KEYWORDS.some((kw) => cleanCell.includes(kw));
        if (matched) {
          keywordMatches++;
          score += 10;
        }

        // Penalize pure numbers (headers should usually be text labels)
        if (!isNaN(Number(cell)) && cell.length > 0) {
          score -= 5;
        }
      }

      // Reward density and uniqueness
      const uniqueCount = new Set(nonEmptyCells.map((c) => c.toLowerCase())).size;
      score += uniqueCount * 2;

      // Look at the row below: if row below has data (numbers or populated cells), this is likely the header
      if (i + 1 < rawRows.length) {
        const nextRow = rawRows[i + 1] || [];
        const nextNonEmpty = nextRow.filter((c) => String(c ?? '').trim().length > 0);
        if (nextNonEmpty.length >= nonEmptyCells.length * 0.7) {
          score += 5;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestRowIdx = i;
        bestHeaders = cells;
      }
    }

    if (bestHeaders.length === 0 && rawRows.length > 0) {
      bestHeaders = (rawRows[0] || []).map((c) => String(c ?? '').trim());
    }

    // Clean up empty trailing headers and provide synthetic names for blank header cells
    const cleanHeaders = bestHeaders.map((h, idx) => (h.length > 0 ? h : `Column_${idx + 1}`));

    let confidence: 'HIGH' | 'MEDIUM' | 'LOW' = 'LOW';
    if (bestScore >= 20) {
      confidence = 'HIGH';
    } else if (bestScore >= 10) {
      confidence = 'MEDIUM';
    }

    return {
      headerRowIndex: bestRowIdx,
      headers: cleanHeaders,
      confidence,
    };
  }

  /**
   * Extracts clean structured rows from a selected sheet given a header row index.
   */
  static extractSheetData(
    workbook: XLSX.WorkBook,
    sheetName: string,
    headerRowIndex?: number
  ): IParsedSheetData {
    const sheet = workbook.Sheets[sheetName];
    if (!sheet) {
      throw ApiError.badRequest(`Sheet '${sheetName}' does not exist in workbook`);
    }

    const rawRows: any[][] = XLSX.utils.sheet_to_json(sheet, {
      header: 1,
      defval: '',
      blankrows: false,
      dateNF: 'yyyy-mm-dd',
      raw: false,
    });

    if (!rawRows || rawRows.length === 0) {
      throw ApiError.badRequest(`Sheet '${sheetName}' is completely empty`);
    }

    const detection =
      headerRowIndex !== undefined && headerRowIndex >= 0
        ? {
            headerRowIndex,
            headers: (rawRows[headerRowIndex] || []).map((c, i) => {
              const str = String(c ?? '').trim();
              return str.length > 0 ? str : `Column_${i + 1}`;
            }),
          }
        : this.detectHeaderRow(rawRows);

    const activeHeaderIdx = detection.headerRowIndex;
    const headers = detection.headers;

    const dataRows: IParsedSheetData['rows'] = [];
    const maxDataRows = Math.min(rawRows.length, activeHeaderIdx + 1 + IMPORT_CONSTRAINTS.MAX_ROWS);

    for (let r = activeHeaderIdx + 1; r < maxDataRows; r++) {
      const row = rawRows[r] || [];
      const hasAnyContent = row.some((c) => String(c ?? '').trim().length > 0);
      if (!hasAnyContent) {
        continue; // Skip entirely blank row
      }

      const values: Record<string, any> = {};
      for (let c = 0; c < headers.length; c++) {
        const headerName = headers[c];
        const cellVal = row[c] !== undefined ? String(row[c]).trim() : '';
        values[headerName] = cellVal;
      }

      dataRows.push({
        rowNumber: r + 1, // 1-indexed for human readability
        values,
      });
    }

    return {
      sheetName,
      headerRowIndex: activeHeaderIdx,
      headers,
      rows: dataRows,
    };
  }
}
