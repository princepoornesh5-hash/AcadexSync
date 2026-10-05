import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/widgets/acadex_character_loading.dart';
import 'package:campus_management/core/presentation/widgets/acadex_feedback.dart';

void main() {
  group('AcadexCharacterLoading & Loading Variants', () {
    testWidgets('renders character loading with message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexCharacterLoading(
              message: 'Loading department metrics...',
            ),
          ),
        ),
      );

      expect(find.text('Loading department metrics...'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify animation frames step smoothly without error
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Loading department metrics...'), findsOneWidget);
    });

    testWidgets('renders compact variant properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexCharacterLoading(
              isCompact: true,
              message: 'Compact loading',
            ),
          ),
        ),
      );

      expect(find.text('Compact loading'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects reduced motion (disableAnimationsOf)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AcadexCharacterLoading(
                message: 'Reduced motion active',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Reduced motion active'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AcadexLoadingState renders character by default and spinner when requested', (WidgetTester tester) async {
      // 1. Default loading state uses character
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexLoadingState(message: 'Default loader'),
          ),
        ),
      );

      expect(find.byType(AcadexCharacterLoading), findsOneWidget);
      expect(find.text('Default loader'), findsOneWidget);

      // 2. Spinner loading state uses CircularProgressIndicator
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexLoadingState.spinner(message: 'Spinner loader'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Spinner loader'), findsOneWidget);

      // 3. Inline loading state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexLoadingState.inline(message: 'Inline loader'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Inline loader'), findsOneWidget);
    });

    testWidgets('Snowman Dock bounce animation cycles through bounce stages smoothly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexCharacterLoading(
              message: 'Preparing your campus dashboard...',
            ),
          ),
        ),
      );

      // Verify initial frame
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Preparing your campus dashboard...'), findsOneWidget);

      // Pump through first bounce peak (~260ms)
      await tester.pump(const Duration(milliseconds: 260));
      expect(tester.takeException(), isNull);

      // Pump through landing impact (~520ms)
      await tester.pump(const Duration(milliseconds: 260));
      expect(tester.takeException(), isNull);

      // Pump through second bounce peak (~800ms)
      await tester.pump(const Duration(milliseconds: 280));
      expect(tester.takeException(), isNull);

      // Pump to settle rest (~1200ms)
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles long loading message gracefully without layout overflow', (WidgetTester tester) async {
      const longMessage = 'Synchronizing real-time academic records, timetable updates, and departmental allocations for your session...';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 480,
              child: AcadexCharacterLoading(
                message: longMessage,
              ),
            ),
          ),
        ),
      );

      expect(find.text(longMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
