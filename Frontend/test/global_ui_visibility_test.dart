import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/app/theme/app_theme.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/acadex_app_bar.dart';
import 'package:campus_management/core/presentation/widgets/acadex_form_card.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testUser = UserModel(
    id: 'user-001',
    name: 'Dr. Turing',
    email: 'turing@campus.edu',
    role: AppRole.hod,
    collegeId: 'col-001',
    departmentId: 'dept-001',
  );

  final commonOverrides = [
    authProvider.overrideWith((ref) => MockAuthNotifier(const AuthAuthenticated(
          user: testUser,
          token: 'test-token',
        ))),
    notificationRepositoryProvider.overrideWithValue(MockNotificationRepository()),
  ];

  group('ACADEX Global UI Visibility & Header Tests (Prompt 11 Scope B)', () {
    testWidgets('19. TextField text color is dark navy (#07111F)', (tester) async {
      final controller = TextEditingController(text: 'Sample input value');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TextField(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      final effectiveColor = textField.style?.color ?? AppTheme.lightTheme.textTheme.bodyMedium?.color;
      expect(effectiveColor, const Color(0xFF07111F));
    });

    testWidgets('20. TextField hint is visible and not white', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: TextField(
              decoration: InputDecoration(hintText: 'Enter course name here'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter course name here'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Enter course name here'));
      final hintColor = textWidget.style?.color ?? AppTheme.lightTheme.inputDecorationTheme.hintStyle?.color;
      expect(hintColor, isNotNull);
      expect(hintColor, isNot(Colors.white));
      expect(hintColor, isNot(const Color(0xFFFFFFFF)));
      expect(hintColor, const Color(0xFF64748B));
    });

    testWidgets('21. AcadexFormField label is dark navy (#07111F)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AcadexFormField(
              label: 'Course Name *',
              child: TextField(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final labelWidget = tester.widget<Text>(find.text('Course Name *'));
      expect(labelWidget.style?.color, const Color(0xFF07111F));
    });

    testWidgets('22. Dropdown hint text is visible and readable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              decoration: const InputDecoration(hintText: 'Select Department'),
              items: const [
                DropdownMenuItem(value: 'd1', child: Text('Computer Science')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Department'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Select Department'));
      final hintColor = textWidget.style?.color ?? AppTheme.lightTheme.inputDecorationTheme.hintStyle?.color;
      expect(hintColor, isNotNull);
      expect(hintColor, isNot(Colors.white));
    });

    testWidgets('23. Dropdown selected value is visible with high contrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              value: 'd1',
              items: const [
                DropdownMenuItem(value: 'd1', child: Text('Computer Science')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Computer Science'), findsOneWidget);
    });

    testWidgets('24. Dropdown menu items are visible upon expansion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              decoration: const InputDecoration(hintText: 'Select Item'),
              items: const [
                DropdownMenuItem(value: '1', child: Text('Option Alpha')),
                DropdownMenuItem(value: '2', child: Text('Option Beta')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select Item'));
      await tester.pumpAndSettle();

      expect(find.text('Option Alpha'), findsWidgets);
      expect(find.text('Option Beta'), findsWidgets);
    });

    testWidgets('25. Search bar text is dark and readable in AcadexAppBar', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonOverrides,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              appBar: AcadexAppBar(title: 'Courses'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Data Structures');
      await tester.pumpAndSettle();

      expect(find.text('Data Structures'), findsOneWidget);
      final textField = tester.widget<TextField>(searchField);
      expect(textField.style?.color, const Color(0xFF07111F));
    });

    testWidgets('26. Search bar hint is visible in AcadexAppBar', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonOverrides,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              appBar: AcadexAppBar(title: 'Courses'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search...'), findsOneWidget);
      final hintWidget = tester.widget<Text>(find.text('Search...'));
      expect(hintWidget.style?.color, const Color(0xFF64748B));
    });

    testWidgets('27. Form error text is semantic red and visible', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                validator: (val) => 'This field is required',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      formKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsOneWidget);
      final errorText = tester.widget<Text>(find.text('This field is required'));
      final errorColor = errorText.style?.color ?? AppTheme.lightTheme.inputDecorationTheme.errorStyle?.color;
      expect(errorColor, const Color(0xFFDC2626));
    });

    testWidgets('28. Dialog title and content text are visible with proper contrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (_) => const AlertDialog(
                      title: Text('Confirmation Title'),
                      content: Text('Are you sure you want to proceed?'),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmation Title'), findsOneWidget);
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);

      final titleWidget = tester.widget<Text>(find.text('Confirmation Title'));
      final titleColor = titleWidget.style?.color ?? AppTheme.lightTheme.dialogTheme.titleTextStyle?.color;
      expect(titleColor, const Color(0xFF07111F));

      final contentWidget = tester.widget<Text>(find.text('Are you sure you want to proceed?'));
      final contentColor = contentWidget.style?.color ?? AppTheme.lightTheme.dialogTheme.contentTextStyle?.color;
      expect(contentColor, const Color(0xFF334155));
    });

    testWidgets('29. Profile control with avatar and menu is visible in AcadexAppBar', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonOverrides,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              appBar: AcadexAppBar(title: 'Courses'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Turing'), findsOneWidget);
      expect(find.text('HOD'), findsOneWidget);

      // Tap profile to open menu
      await tester.tap(find.byTooltip('Account Menu'));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('30. Header responsive: desktop shows full search and profile, mobile shows compact controls', (tester) async {
      // 1. Desktop size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonOverrides,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              appBar: AcadexAppBar(title: 'Courses'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On desktop: full search TextField is visible, user name is visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Dr. Turing'), findsOneWidget);

      // 2. Mobile size
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpAndSettle();

      // On mobile: search bar is not an expanded TextField; it is a compact search icon button
      expect(find.byType(TextField), findsNothing);
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Account Menu'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });

    testWidgets('31. No black ACADEX header remains; header background is white (#FFFFFF)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: commonOverrides,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              appBar: AcadexAppBar(title: 'Courses'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(AcadexAppBar),
        matching: find.byType(Container),
      ).first;

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AcadexColors.surface);
      expect(decoration.color, const Color(0xFFFFFFFF));
    });

    testWidgets('32. No layout overflow at 360px mobile width', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: commonOverrides,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              appBar: AcadexAppBar(
                title: 'Courses (Degree Programs)',
                subtitle: 'Manage degree programs across departments',
              ),
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Courses (Degree Programs)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
