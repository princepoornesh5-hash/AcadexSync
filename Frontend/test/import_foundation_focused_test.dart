import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/academic_structure/domain/models/import_models.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/import_data_dialog.dart';

void main() {
  group('PROMPT 4/6 — Import Models & Serialization Tests', () {
    test('1. ColumnMappingModel serializes and deserializes cleanly', () {
      final json = {
        'sourceColumn': 'PIN Number',
        'targetField': 'studentPin',
        'confidence': 'HIGH',
        'status': 'AUTO_MATCHED',
      };

      final model = ColumnMappingModel.fromJson(json);
      expect(model.sourceColumn, 'PIN Number');
      expect(model.targetField, 'studentPin');
      expect(model.confidence, 'HIGH');
      expect(model.status, 'AUTO_MATCHED');

      final serialized = model.toJson();
      expect(serialized['sourceColumn'], 'PIN Number');
      expect(serialized['targetField'], 'studentPin');
    });

    test('2. NormalizedImportRowModel parses student resolution and issues', () {
      final json = {
        'rowNumber': 12,
        'status': 'INVALID',
        'studentResolution': {
          'studentName': 'Rahul Sharma',
          'studentPin': '23A014',
          'rollNumber': 'CS514',
          'sectionName': 'Section A',
        },
        'semanticValues': {
          'marks': 22.5,
          'status': 'PRESENT',
        },
        'issues': [
          {
            'code': 'STUDENT_CONTEXT_MISMATCH',
            'severity': 'ERROR',
            'message': 'Student enrolled in Section B',
            'column': 'PIN',
            'rowNumber': 12,
          }
        ],
      };

      final row = NormalizedImportRowModel.fromJson(json);
      expect(row.rowNumber, 12);
      expect(row.status, 'INVALID');
      expect(row.studentName, 'Rahul Sharma');
      expect(row.studentPin, '23A014');
      expect(row.marks, 22.5);
      expect(row.issues, hasLength(1));
      expect(row.issues.first.code, 'STUDENT_CONTEXT_MISMATCH');
    });

    test('3. ImportBatchModel and ImportSummaryModel calculation parsing', () {
      final json = {
        'id': 'batch_123',
        'importBatchId': 'IMP-20261009-A1B2',
        'fileName': 'unit_test_marks.xlsx',
        'fileType': 'XLSX',
        'fileSize': 10240,
        'dataType': 'ASSESSMENT',
        'status': 'READY_FOR_CONFIRMATION',
        'sheetNames': ['UT1', 'UT2'],
        'headers': ['PIN', 'Name', 'Marks'],
        'columnMappings': [
          {
            'sourceColumn': 'PIN',
            'targetField': 'studentPin',
            'confidence': 'HIGH',
            'status': 'AUTO_MATCHED',
          }
        ],
        'rowCount': 50,
        'validCount': 48,
        'warningCount': 1,
        'errorCount': 1,
      };

      final batch = ImportBatchModel.fromJson(json);
      expect(batch.importBatchId, 'IMP-20261009-A1B2');
      expect(batch.sheetNames, ['UT1', 'UT2']);
      expect(batch.headers, ['PIN', 'Name', 'Marks']);
      expect(batch.validCount, 48);
      expect(batch.errorCount, 1);
    });

    test('4. ImportSummaryModel parses detectedPrecision and precision breakdown', () {
      final json = {
        'rowCount': 60,
        'validCount': 58,
        'warningCount': 2,
        'errorCount': 0,
        'conflictCount': 0,
        'duplicateCount': 0,
        'detectedPrecision': 'PERIOD_SUMMARY',
        'detailedCount': 0,
        'summaryCount': 58,
        'percentageOnlyCount': 0,
      };

      final summary = ImportSummaryModel.fromJson(json);
      expect(summary.rowCount, 60);
      expect(summary.validCount, 58);
      expect(summary.detectedPrecision, 'PERIOD_SUMMARY');
      expect(summary.summaryCount, 58);
      expect(summary.detailedCount, 0);
      expect(summary.percentageOnlyCount, 0);
    });
  });

  group('PROMPT 4/6 & PROMPT 5/6 — ImportDataDialog Widget Tests', () {
    testWidgets('5. Renders ImportDataDialog step 1 with upload options',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ImportDataDialog(
                entityName: 'Internal Marks',
                sectionId: 'sec_123',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Import Internal Marks'), findsOneWidget);
      expect(find.textContaining('Step 1 of 3: Upload Spreadsheet File'), findsOneWidget);
      expect(find.text('Select CSV or Excel (.xlsx) file'), findsOneWidget);
      expect(find.text('Load Spreadsheet Template'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('6. Renders ImportDataDialog for ATTENDANCE data type',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ImportDataDialog(
                entityName: 'Attendance Register',
                sectionId: 'sec_123',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Import Attendance Register'), findsOneWidget);
      expect(find.textContaining('Step 1 of 3: Upload Spreadsheet File'), findsOneWidget);
      expect(find.text('Select CSV or Excel (.xlsx) file'), findsOneWidget);
    });
  });
}
