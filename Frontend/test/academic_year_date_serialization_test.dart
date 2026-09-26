import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/academic_structure/presentation/providers/academic_providers.dart';
import 'package:campus_management/features/academic_structure/presentation/screens/academic_year_screens.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PROMPT 14 — Academic Year Date Serialization & Hotfix Suite', () {
    late UserModel adminUser;

    setUp(() {
      adminUser = UserModel(
        id: 'admin_1',
        name: 'College Admin',
        email: 'admin@college.edu',
        role: AppRole.collegeAdmin,
        collegeId: 'c1',
        accountStatus: AccountStatus.active,
      );
    });

    // -------------------------------------------------------------------------
    // TEST 1: Canonical Serialization of Start Date (2024-01-01)
    // -------------------------------------------------------------------------
    test('1. Create Academic Year serializes Start Date to canonical ISO 8601 UTC string', () {
      final localStartDate = DateTime(2024, 1, 1);
      final serialized = AcademicYearDateUtils.serialize(localStartDate);

      expect(serialized, '2024-01-01T00:00:00.000Z');
      expect(serialized.endsWith('Z'), isTrue);
      expect(serialized.startsWith('2024-01-01'), isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 2: Canonical Serialization of End Date (2027-12-31)
    // -------------------------------------------------------------------------
    test('2. Create Academic Year serializes End Date to canonical ISO 8601 UTC string', () {
      final localEndDate = DateTime(2027, 12, 31);
      final serialized = AcademicYearDateUtils.serialize(localEndDate);

      expect(serialized, '2027-12-31T00:00:00.000Z');
      expect(serialized.endsWith('Z'), isTrue);
      expect(serialized.startsWith('2027-12-31'), isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 3: Model Constructor & toJson Serialization Contract
    // -------------------------------------------------------------------------
    test('3. AcademicYear model toJson produces contract-compliant JSON payload', () {
      final ay = AcademicYear(
        id: 'ay-2024-2027',
        collegeId: 'c1',
        name: '2024-2027',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2027, 12, 31),
        status: 'active',
        isCurrent: true,
      );

      final json = ay.toJson();
      expect(json['name'], '2024-2027');
      expect(json['startDate'], '2024-01-01T00:00:00.000Z');
      expect(json['endDate'], '2027-12-31T00:00:00.000Z');
      expect(json['isCurrent'], true);
    });

    // -------------------------------------------------------------------------
    // TEST 4: Backend Contract Acceptance Regex Simulation
    // -------------------------------------------------------------------------
    test('4. Serialized payload satisfies Zod datetime ISO regex contract', () {
      // Zod's default z.string().datetime() pattern:
      final zodIsoRegex = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$');

      final startIso = AcademicYearDateUtils.serialize(DateTime(2024, 1, 1));
      final endIso = AcademicYearDateUtils.serialize(DateTime(2027, 12, 31));

      expect(zodIsoRegex.hasMatch(startIso), isTrue, reason: 'startIso must match Zod datetime regex');
      expect(zodIsoRegex.hasMatch(endIso), isTrue, reason: 'endIso must match Zod datetime regex');

      // Contrast: old local toIso8601String() fails Zod:
      final oldLocalStart = DateTime(2024, 1, 1).toIso8601String();
      if (!oldLocalStart.endsWith('Z')) {
        expect(zodIsoRegex.hasMatch(oldLocalStart), isFalse, reason: 'Old local format without Z failed backend validation');
      }
    });

    // -------------------------------------------------------------------------
    // TEST 5: Academic Year Creation Succeeds via Repository
    // -------------------------------------------------------------------------
    test('5. Academic Year creation succeeds with 2024-01-01 and 2027-12-31', () async {
      final repo = MockAcademicRepository(currentUser: adminUser);
      final ay = AcademicYear(
        id: 'ay-new',
        collegeId: 'c1',
        name: '2024-2027',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2027, 12, 31),
        status: 'active',
        isCurrent: true,
      );

      await repo.addAcademicYear(ay);
      final years = await repo.getAcademicYears();
      final created = years.firstWhere((y) => y.id == 'ay-new');

      expect(created.name, '2024-2027');
      expect(created.startDate, DateTime.utc(2024, 1, 1));
      expect(created.endDate, DateTime.utc(2027, 12, 31));
      expect(created.isCurrent, true);
    });

    // -------------------------------------------------------------------------
    // TEST 6: Date Range Validation (End Date before Start Date is rejected)
    // -------------------------------------------------------------------------
    test('6. End Date before Start Date is rejected by isRangeValid', () {
      final start = DateTime(2027, 12, 31);
      final end = DateTime(2024, 1, 1);

      expect(AcademicYearDateUtils.isRangeValid(start, end), isFalse);
      // Same day is also invalid (must be strictly before)
      expect(AcademicYearDateUtils.isRangeValid(DateTime(2024, 1, 1), DateTime(2024, 1, 1)), isFalse);
      // Proper range is valid
      expect(AcademicYearDateUtils.isRangeValid(DateTime(2024, 1, 1), DateTime(2027, 12, 31)), isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 7: Round-Trip Parsing and Serialization
    // -------------------------------------------------------------------------
    test('7. Edit flow: backend date string round-trips with zero drift', () {
      const backendStartDate = '2024-01-01T00:00:00.000Z';
      const backendEndDate = '2027-12-31T00:00:00.000Z';

      // 1. Backend -> Frontend model parsing
      final parsedStart = AcademicYearDateUtils.parse(backendStartDate);
      final parsedEnd = AcademicYearDateUtils.parse(backendEndDate);

      expect(parsedStart.year, 2024);
      expect(parsedStart.month, 1);
      expect(parsedStart.day, 1);

      expect(parsedEnd.year, 2027);
      expect(parsedEnd.month, 12);
      expect(parsedEnd.day, 31);

      // 2. UI Display format
      expect(AcademicYearDateUtils.formatDisplay(parsedStart), '2024-01-01');
      expect(AcademicYearDateUtils.formatDisplay(parsedEnd), '2027-12-31');

      // 3. Edit -> Re-serialization to backend
      final reserializedStart = AcademicYearDateUtils.serialize(parsedStart);
      final reserializedEnd = AcademicYearDateUtils.serialize(parsedEnd);

      expect(reserializedStart, backendStartDate);
      expect(reserializedEnd, backendEndDate);
    });

    // -------------------------------------------------------------------------
    // TEST 8: Timezone Shift Protection Across Diverse Global Offsets
    // -------------------------------------------------------------------------
    test('8. Date values do NOT shift across timezone conversions (UTC-10 to UTC+12)', () {
      final candidateStrings = [
        '2026-01-01T00:00:00.000Z',
        '2026-01-01T18:30:00.000Z', // Local in IST
        '2026-01-01T08:00:00.000Z', // Local in PST
        '2026-01-01',               // Plain date
      ];

      for (final raw in candidateStrings) {
        final parsed = AcademicYearDateUtils.parse(raw);
        expect(parsed.year, 2026, reason: 'Failed for input: $raw');
        expect(parsed.month, 1, reason: 'Failed for input: $raw');
        expect(parsed.day, 1, reason: 'Failed for input: $raw');

        // Re-serialized canonical string must always anchor to 2026-01-01 UTC
        final serialized = AcademicYearDateUtils.serialize(parsed);
        expect(serialized, '2026-01-01T00:00:00.000Z', reason: 'Failed for input: $raw');
      }
    });

    // -------------------------------------------------------------------------
    // TEST 9: Set as Current Academic Year Behavior
    // -------------------------------------------------------------------------
    test('9. Set as Current Academic Year unsets previous current year', () async {
      final repo = MockAcademicRepository(currentUser: adminUser);
      final y1 = AcademicYear(
        id: 'ay-prev',
        collegeId: 'c1',
        name: '2023-2024',
        startDate: DateTime(2023, 6, 1),
        endDate: DateTime(2024, 5, 31),
        status: 'active',
        isCurrent: true,
      );
      await repo.addAcademicYear(y1);

      final y2 = AcademicYear(
        id: 'ay-new',
        collegeId: 'c1',
        name: '2024-2027',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2027, 12, 31),
        status: 'active',
        isCurrent: true,
      );
      await repo.addAcademicYear(y2);

      final allYears = await repo.getAcademicYears();
      final prev = allYears.firstWhere((y) => y.id == 'ay-prev');
      final curr = allYears.firstWhere((y) => y.id == 'ay-new');

      expect(prev.isCurrent, false);
      expect(prev.status, 'completed');
      expect(curr.isCurrent, true);
      expect(curr.status, 'active');
    });

    // -------------------------------------------------------------------------
    // TEST 10: Provider Refreshes & Department Setup Integration
    // -------------------------------------------------------------------------
    test('10. Provider refresh recalculates currentAcademicYearProvider and departmentSetupProvider', () async {
      final repo = MockAcademicRepository(currentUser: adminUser);
      final container = ProviderContainer(
        overrides: [
          academicRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: adminUser, token: 'mock-token'))),
        ],
      );
      addTearDown(container.dispose);

      // Initially, verify academic years list is loaded
      final initialYears = await container.read(academicYearsProvider.future);
      expect(initialYears.any((y) => y.id == 'ay-new-2024'), isFalse);

      // Add Academic Year via notifier
      final newAy = AcademicYear(
        id: 'ay-new-2024',
        collegeId: 'c1',
        name: '2024-2027',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2027, 12, 31),
        status: 'active',
        isCurrent: true,
      );
      await container.read(academicYearsProvider.notifier).addAcademicYear(newAy);

      // Read refreshed academic years
      final refreshedYears = await container.read(academicYearsProvider.future);
      final created = refreshedYears.firstWhere((y) => y.id == 'ay-new-2024');
      expect(created.name, '2024-2027');
      expect(created.isCurrent, true);

      // currentAcademicYearProvider picks up the newly active year
      final currentAy = container.read(currentAcademicYearProvider);
      expect(currentAy?.id, 'ay-new-2024');
      expect(currentAy?.name, '2024-2027');
    });

    // -------------------------------------------------------------------------
    // TEST 11: UI Form Renders and Submits cleanly on 360px Mobile Screen
    // -------------------------------------------------------------------------
    testWidgets('11. AcademicYearFormScreen renders without overflow on 360px mobile width', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockAcademicRepository(currentUser: adminUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academicRepositoryProvider.overrideWithValue(repo),
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: adminUser, token: 'mock-token'))),
          ],
          child: const MaterialApp(
            home: AcademicYearFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify form elements exist
      expect(find.text("Academic Year Details"), findsOneWidget);
      expect(find.byKey(const Key('academic_year_name_input')), findsOneWidget);
      expect(find.byKey(const Key('academic_year_start_date_btn')), findsOneWidget);
      expect(find.byKey(const Key('academic_year_end_date_btn')), findsOneWidget);
      expect(find.text("Create Academic Year"), findsWidgets);

      // Zero RenderFlex overflow errors
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST 12: UI Form Renders on 390px and 412px Screens Without Overflow
    // -------------------------------------------------------------------------
    testWidgets('12. AcademicYearFormScreen renders without overflow on 390px and 412px widths', (tester) async {
      for (final width in [390.0, 412.0]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;

        final repo = MockAcademicRepository(currentUser: adminUser);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              academicRepositoryProvider.overrideWithValue(repo),
              authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: adminUser, token: 'mock-token'))),
            ],
            child: const MaterialApp(
              home: AcademicYearFormScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text("Academic Year Details"), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Failed overflow check on ${width}px');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // -------------------------------------------------------------------------
    // TEST 13: UI Validation Rejects Empty Name and Shows SnackBar Warning
    // -------------------------------------------------------------------------
    testWidgets('13. UI form validates name length and presents clear error', (tester) async {
      final repo = MockAcademicRepository(currentUser: adminUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academicRepositoryProvider.overrideWithValue(repo),
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: adminUser, token: 'mock-token'))),
          ],
          child: const MaterialApp(
            home: AcademicYearFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter short name '24' (< 4 characters)
      await tester.enterText(find.byKey(const Key('academic_year_name_input')), '24');
      await tester.tap(find.widgetWithText(ElevatedButton, "Create Academic Year"));
      await tester.pumpAndSettle();

      // Validator error should appear
      expect(find.text('Must be at least 4 characters (e.g. 2026-2027)'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 14: UI Date Picker Interaction
    // -------------------------------------------------------------------------
    testWidgets('14. UI Date picker opens and allows selecting date without error', (tester) async {
      final repo = MockAcademicRepository(currentUser: adminUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academicRepositoryProvider.overrideWithValue(repo),
            authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: adminUser, token: 'mock-token'))),
          ],
          child: const MaterialApp(
            home: AcademicYearFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Start Date button
      await tester.tap(find.byKey(const Key('academic_year_start_date_btn')));
      await tester.pumpAndSettle();

      // DatePickerDialog is visible
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Tap OK button to confirm
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Date picker dialog is dismissed
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
