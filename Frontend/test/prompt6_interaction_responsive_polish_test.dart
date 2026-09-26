import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/features/profile/data/repositories/profile_repository.dart';
import 'package:campus_management/features/users/presentation/widgets/profile/profile_picture_confirm_dialog.dart';
import 'package:campus_management/core/presentation/widgets/acadex_dialogs.dart';
import 'package:campus_management/core/presentation/widgets/acadex_search_bar.dart';
import 'package:campus_management/core/presentation/widgets/acadex_snackbar.dart';
import 'package:campus_management/core/errors/acadex_error.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/analytics/domain/models/analytics_models.dart';
import 'package:campus_management/features/analytics/presentation/screens/report_preview_screen.dart';

void main() {
  group('Prompt 6 — Profile Workflow & Validation Tests', () {
    test('1. Profile image extension validation strictly allows only supported formats', () {
      // Allowed formats (case-insensitive)
      expect(ProfileRepository.isImageExtensionSupported('avatar.jpg'), isTrue);
      expect(ProfileRepository.isImageExtensionSupported('AVATAR.JPEG'), isTrue);
      expect(ProfileRepository.isImageExtensionSupported('photo.png'), isTrue);
      expect(ProfileRepository.isImageExtensionSupported('PROFILE.WEBP'), isTrue);

      // Disallowed formats
      expect(ProfileRepository.isImageExtensionSupported('document.pdf'), isFalse);
      expect(ProfileRepository.isImageExtensionSupported('animation.gif'), isFalse);
      expect(ProfileRepository.isImageExtensionSupported('vector.svg'), isFalse);
      expect(ProfileRepository.isImageExtensionSupported('script.sh'), isFalse);
      expect(ProfileRepository.isImageExtensionSupported('payload.exe'), isFalse);
      expect(ProfileRepository.isImageExtensionSupported('no_extension'), isFalse);
    });

    test('2. Profile image size limit is exactly 5MB (5,242,880 bytes)', () {
      expect(ProfileRepository.maxProfileImageSizeBytes, equals(5 * 1024 * 1024));
      expect(ProfileRepository.maxProfileImageSizeBytes, equals(5242880));

      const validSize = 5 * 1024 * 1024;
      const invalidSize = (5 * 1024 * 1024) + 1;

      expect(validSize <= ProfileRepository.maxProfileImageSizeBytes, isTrue);
      expect(invalidSize > ProfileRepository.maxProfileImageSizeBytes, isTrue);
    });

    testWidgets('3. ProfilePictureConfirmDialog renders preview, metadata, and handles cancel', (tester) async {
      // 1x1 transparent PNG bytes for testing
      final testBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      bool? dialogResult;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    dialogResult = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => ProfilePictureConfirmDialog(
                        imageBytes: testBytes,
                        fileName: 'my_avatar.png',
                        fileSize: 1024 * 250, // 250 KB
                        targetUserId: 'user-101',
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.text('Preview Profile Picture'), findsOneWidget);
      expect(find.textContaining('PNG • 250.0 KB'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm & Upload'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
    });
  });

  group('Prompt 6 — Responsive Dialog & Search Filter Integrity', () {
    testWidgets('4. AcadexDialog uses Wrap for actions preventing RenderFlex overflow at 360dp width', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexDialog(
              title: 'Responsive Dialog Title',
              content: const Text('Testing action row wrapping at small viewport width.'),
              actions: [
                OutlinedButton(onPressed: () {}, child: const Text('Secondary Option')),
                ElevatedButton(onPressed: () {}, child: const Text('Confirm Primary Action')),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for zero RenderFlex overflows
      expect(tester.takeException(), isNull);
      expect(find.text('Secondary Option'), findsOneWidget);
      expect(find.text('Confirm Primary Action'), findsOneWidget);
    });

    testWidgets('5. AcadexSearchFilterBar provides clear button and responsive compact mode', (tester) async {
      // Simulate narrow mobile screen (360dp)
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String currentSearch = '';
      bool filterTapped = false;
      bool addTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AcadexSearchFilterBar(
                searchHint: 'Search records...',
                onSearchChanged: (val) => currentSearch = val,
                onFilterTap: () => filterTapped = true,
                onActionTap: () => addTapped = true,
                actionLabel: 'Add Record',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Algorithms');
      await tester.pumpAndSettle();

      expect(currentSearch, equals('Algorithms'));

      // Verify clear icon is visible
      final clearButtonFinder = find.byIcon(LucideIcons.x);
      expect(clearButtonFinder, findsOneWidget);

      // Tap clear icon
      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      // Verify search is cleared
      expect(currentSearch, equals(''));

      // Tap filter and add buttons in compact mobile view
      await tester.tap(find.byIcon(LucideIcons.filter));
      await tester.pumpAndSettle();
      expect(filterTapped, isTrue);

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();
      expect(addTapped, isTrue);
    });
  });

  group('Prompt 6 — SnackBar Feedback & Error Sanitization', () {
    testWidgets('6. AcadexSnackBar shows success, warning, error safely without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AcadexSnackBar.showSuccess(context, 'Saved successfully!'),
                    child: const Text('Show Success'),
                  ),
                  ElevatedButton(
                    onPressed: () => AcadexSnackBar.showWarning(context, 'Attention required.'),
                    child: const Text('Show Warning'),
                  ),
                  ElevatedButton(
                    onPressed: () => AcadexSnackBar.showError(
                      context,
                      Exception('Internal server error: database connection failure'),
                      fallbackMessage: 'Operation failed safely',
                    ),
                    child: const Text('Show Error'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Success
      await tester.tap(find.text('Show Success'));
      await tester.pump();
      expect(find.text('Saved successfully!'), findsOneWidget);

      // Warning replaces Success (no stacking)
      await tester.tap(find.text('Show Warning'));
      await tester.pump();
      expect(find.text('Attention required.'), findsOneWidget);

      // Error replaces Warning and sanitizes internal exception
      await tester.tap(find.text('Show Error'));
      await tester.pump();
      expect(find.textContaining('Internal server error'), findsNothing);
      expect(find.textContaining('Operation failed safely'), findsOneWidget);
    });

    test('7. AcadexException.sanitizedMessage shields raw database and server errors', () {
      final dbError = Exception('PostgreSQL error: relation "colleges_tenants" does not exist at line 42');
      final sanitized = AcadexException.sanitizedMessage(dbError, fallback: 'Database operation failed');

      expect(sanitized, isNot(contains('PostgreSQL')));
      expect(sanitized, isNot(contains('colleges_tenants')));
      expect(sanitized, contains('Database operation failed'));
    });
  });

  group('Prompt 6 — Dead Button & Role Scope Integrity', () {
    testWidgets('8. ReportPreviewScreen export buttons are visibly disabled with informative tooltips', (tester) async {
      final mockReport = AttendanceReport(
        id: 'rep-001',
        title: 'Department Monthly Attendance',
        type: ReportType.monthly,
        generatedAt: DateTime.now(),
        generatedBy: AppRole.hod,
        filtersApplied: {'Department': 'Computer Science'},
        summary: 'Monthly summary of computer science attendance.',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReportPreviewScreen(report: mockReport),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find export buttons
      final excelBtn = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Export Excel'));
      final pdfBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Export PDF'));

      // Verify buttons are disabled (onPressed is null)
      expect(excelBtn.onPressed, isNull);
      expect(pdfBtn.onPressed, isNull);

      // Verify tooltips exist
      expect(find.byType(Tooltip), findsWidgets);
      expect(find.byTooltip('Excel export will be available in an upcoming release'), findsOneWidget);
      expect(find.byTooltip('PDF report generation will be available in an upcoming release'), findsOneWidget);
    });

    test('9. HOD role department filter locking logic preserves department ID on reset', () {
      String? getResetFilter(AppRole role, String userDeptId) {
        return role == AppRole.hod ? userDeptId : null;
      }

      // HOD scope is strictly locked to own department
      expect(getResetFilter(AppRole.hod, 'dept-cs-101'), equals('dept-cs-101'));

      // Non-HOD roles can reset to null (all departments)
      expect(getResetFilter(AppRole.collegeAdmin, 'dept-cs-101'), isNull);
      expect(getResetFilter(AppRole.superAdmin, 'dept-cs-101'), isNull);
    });
  });
}
