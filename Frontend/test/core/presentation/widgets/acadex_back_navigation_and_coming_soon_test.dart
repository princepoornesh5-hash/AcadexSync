import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/core/presentation/widgets/acadex_back_button.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_header.dart';
import 'package:campus_management/core/presentation/widgets/acadex_sliver_page_header.dart';
import 'package:campus_management/features/dashboard/presentation/screens/coming_soon_screen.dart';
import 'package:campus_management/core/presentation/utils/navigation_extensions.dart';

void main() {
  group('AcadexBackButton Widget Tests', () {
    testWidgets('renders with LucideIcons.arrowLeft and tooltip Back', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AcadexBackButton())),
      );

      expect(find.byType(AcadexBackButton), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Back'));
      expect(iconButton.constraints?.minWidth, equals(40));
      expect(iconButton.constraints?.minHeight, equals(40));
    });

    testWidgets('triggers custom onPressed callback when tapped', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexBackButton(
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AcadexBackButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('respects custom color when provided', (tester) async {
      const customColor = Colors.purple;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AcadexBackButton(color: customColor)),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(LucideIcons.arrowLeft));
      expect(icon.color, equals(customColor));
    });
  });

  group('AcadexPageHeader Back Button Tests', () {
    testWidgets(
      'automatically shows AcadexBackButton on secondary screens by default',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AcadexPageHeader(
                title: 'Academic Departments',
                subtitle: 'Manage departments and programs',
              ),
            ),
          ),
        );

        expect(find.byType(AcadexBackButton), findsOneWidget);
        expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
        expect(find.text('Academic Departments'), findsOneWidget);
      },
    );

    testWidgets(
      'suppresses back button when showBackButton is explicitly false',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AcadexPageHeader(
                title: 'Root List View',
                showBackButton: false,
              ),
            ),
          ),
        );

        expect(find.byType(AcadexBackButton), findsNothing);
        expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
        expect(find.text('Root List View'), findsOneWidget);
      },
    );

    testWidgets('triggers onBack callback when back button is pressed', (
      tester,
    ) async {
      bool backCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexPageHeader(
              title: 'Course Catalog',
              onBack: () => backCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AcadexBackButton));
      await tester.pump();
      expect(backCalled, isTrue);
    });

    testWidgets(
      'renders custom leading widget instead of default back button when provided',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AcadexPageHeader(
                title: 'Custom Header',
                leading: Icon(LucideIcons.sparkles),
              ),
            ),
          ),
        );

        expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
        expect(find.byType(AcadexBackButton), findsNothing);
      },
    );
  });

  group('AcadexSliverPageHeader Back Button Tests', () {
    testWidgets('automatically renders back button at top-left by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const AcadexSliverPageHeader(
                  title: 'Weekly Timetable',
                  subtitle: 'Student weekly schedule',
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Text('Slot $index'),
                    childCount: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AcadexBackButton), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.text('Weekly Timetable'), findsOneWidget);
    });

    testWidgets(
      'suppresses back button when showBackButton is explicitly false',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  const AcadexSliverPageHeader(
                    title: 'No Back Header',
                    showBackButton: false,
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([const Text('Body')]),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(AcadexBackButton), findsNothing);
        expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
      },
    );

    testWidgets('executes onBack callback when sliver back button is pressed', (
      tester,
    ) async {
      bool onBackFired = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                AcadexSliverPageHeader(
                  title: 'Back Test',
                  onBack: () => onBackFired = true,
                ),
                SliverList(
                  delegate: SliverChildListDelegate([const Text('Content')]),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AcadexBackButton));
      await tester.pump();
      expect(onBackFired, isTrue);
    });
  });

  group('ComingSoonScreen Tests', () {
    testWidgets('renders heading, module name, default message and back button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ComingSoonScreen(moduleName: 'Certificates'),
          ),
        ),
      );

      // Verify heading 'Coming Soon'
      expect(find.text('Coming Soon'), findsOneWidget);

      // Verify module name
      expect(
        find.text('Certificates'),
        findsNWidgets(2),
      ); // in app bar title and body heading

      // Verify default message
      expect(
        find.text(
          "We're working on this module. It will be available in a future update.",
        ),
        findsOneWidget,
      );

      // Verify 'COMING SOON' badge
      expect(find.text('COMING SOON'), findsOneWidget);

      // Verify consistent top-left back button
      expect(find.byType(AcadexBackButton), findsOneWidget);

      // Verify Return / Go Back button
      expect(find.text('Go Back'), findsOneWidget);

      // Verify Certificates module icon is LucideIcons.award
      expect(find.byIcon(LucideIcons.award), findsOneWidget);
    });

    testWidgets('renders custom description and custom icon when specified', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ComingSoonScreen(
              moduleName: 'Advanced Timetable AI Optimizer',
              description:
                  'AI automated timetable collision resolver will be released in Phase 10.',
              icon: LucideIcons.cpu,
            ),
          ),
        ),
      );

      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.text('Advanced Timetable AI Optimizer'), findsNWidgets(2));
      expect(
        find.text(
          'AI automated timetable collision resolver will be released in Phase 10.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.cpu), findsOneWidget);
    });

    testWidgets('adapts gracefully to dark mode theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const ComingSoonScreen(moduleName: 'Achievements'),
          ),
        ),
      );

      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.text('Achievements'), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.trophy), findsOneWidget);
      expect(find.byType(AcadexBackButton), findsOneWidget);
    });
  });

  group('SafeNavigationExtension Tests', () {
    testWidgets(
      'resolveDefaultFallback resolves parent route or /dashboard without error',
      (tester) async {
        String fallbackResult = '';
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                fallbackResult = context.resolveDefaultFallback();
                return const SizedBox();
              },
            ),
          ),
        );

        expect(fallbackResult, isNotEmpty);
        expect(fallbackResult, equals('/dashboard'));
      },
    );
  });
}
