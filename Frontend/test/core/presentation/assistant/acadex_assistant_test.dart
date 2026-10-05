import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/assistant/acadex_assistant.dart';
import 'package:campus_management/core/presentation/assistant/acadex_assistant_controller.dart';
import 'package:campus_management/core/presentation/assistant/acadex_assistant_types.dart';
import 'package:campus_management/core/presentation/assistant/acadex_assistant_painter.dart';
import 'package:campus_management/core/presentation/assistant/acadex_assistant_showcase_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AcadexAssistant Widget & Painter Tests', () {
    testWidgets('Renders character at default size with Semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexAssistant(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AcadexAssistant), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify semantics label
      final semantics = tester.getSemantics(find.byType(AcadexAssistant));
      expect(semantics.label, contains('ACADEX Assistant'));
    });

    testWidgets('Renders all supported poses cleanly without errors', (tester) async {
      for (final pose in AcadexAssistantPose.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AcadexAssistant(
                  size: 140,
                  initialPose: pose,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(AcadexAssistant), findsOneWidget);
      }
    });

    testWidgets('Renders all supported facial expressions cleanly', (tester) async {
      for (final expression in AcadexAssistantExpression.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AcadexAssistant(
                  size: 140,
                  initialExpression: expression,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(AcadexAssistant), findsOneWidget);
      }
    });

    testWidgets('Adapts to responsive constraints and size presets', (tester) async {
      final testSizes = [80.0, 140.0, 220.0, 300.0];

      for (final size in testSizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AcadexAssistant(size: size),
              ),
            ),
          ),
        );
        await tester.pump();

        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(AcadexAssistant),
            matching: find.byType(CustomPaint),
          ).first,
        );
        expect(customPaint.size, Size(size, size));
      }
    });

    testWidgets('Complies with reduced motion (MediaQuery.disableAnimations)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: AcadexAssistant(size: 160),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AcadexAssistant),
          matching: find.byType(CustomPaint),
        ).first,
      );
      final painter = customPaint.painter as AcadexAssistantPainter;
      expect(painter.poseProgress, 0.0);
      expect(painter.breathingValue, 0.0);
    });

    testWidgets('Disposes internal animation controllers and timers cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexAssistant(size: 140),
            ),
          ),
        ),
      );
      await tester.pump();

      // Unmount the widget to verify no exceptions on disposal
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(find.byType(AcadexAssistant), findsNothing);
    });
  });

  group('AcadexAssistantController Tests', () {
    late AcadexAssistantController controller;

    setUp(() {
      controller = AcadexAssistantController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initializes in calm idle pose with friendly expression', () {
      expect(controller.pose, AcadexAssistantPose.idle);
      expect(controller.expression, AcadexAssistantExpression.defaultExpression);
      expect(controller.visibility, 1.0);
      expect(controller.isVisible, isTrue);
      expect(controller.gazeDirection, Offset.zero);
      expect(controller.isActionRunning, isFalse);
    });

    test('setPose updates pose and notifies listeners', () {
      bool notified = false;
      controller.addListener(() => notified = true);

      controller.setPose(AcadexAssistantPose.point, expression: AcadexAssistantExpression.focused);

      expect(controller.pose, AcadexAssistantPose.point);
      expect(controller.expression, AcadexAssistantExpression.focused);
      expect(notified, isTrue);
    });

    test('lookAt clamps gaze direction to [-1.0, 1.0]', () {
      controller.lookAt(const Offset(2.5, -3.0));
      expect(controller.gazeDirection, const Offset(1.0, -1.0));

      controller.lookAt(const Offset(-0.5, 0.8));
      expect(controller.gazeDirection, const Offset(-0.5, 0.8));
    });

    test('resetToIdle restores default calm stance', () {
      controller.setPose(AcadexAssistantPose.wipe, expression: AcadexAssistantExpression.focused);
      controller.lookAt(const Offset(0.5, 0.5));

      controller.resetToIdle();

      expect(controller.pose, AcadexAssistantPose.idle);
      expect(controller.expression, AcadexAssistantExpression.friendly);
      expect(controller.gazeDirection, Offset.zero);
      expect(controller.visibility, 1.0);
      expect(controller.isActionRunning, isFalse);
    });

    test('playGreeting executes and settles back to idle', () async {
      bool completed = false;
      controller.playGreeting(
        duration: const Duration(milliseconds: 40),
        onComplete: () => completed = true,
      );

      expect(controller.pose, AcadexAssistantPose.greet);
      expect(controller.expression, AcadexAssistantExpression.greeting);
      expect(controller.isActionRunning, isTrue);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(completed, isTrue);
      expect(controller.pose, AcadexAssistantPose.idle);
      expect(controller.isActionRunning, isFalse);
    });

    test('playMagicGesture activates magic pose and triggers sparkle peak', () {
      controller.playMagicGesture(
        totalDuration: const Duration(milliseconds: 200),
      );

      expect(controller.pose, AcadexAssistantPose.magic);
      expect(controller.expression, AcadexAssistantExpression.success);
      expect(controller.isActionRunning, isTrue);
    });

    test('playAppear and playDisappear transition visibility', () {
      controller.setVisibility(0.0);
      expect(controller.visibility, 0.0);
      expect(controller.isVisible, isFalse);

      controller.playAppear(duration: const Duration(milliseconds: 50));
      expect(controller.pose, AcadexAssistantPose.appear);
      expect(controller.visibility, 1.0);
      expect(controller.isVisible, isTrue);

      controller.playDisappear(duration: const Duration(milliseconds: 50));
      expect(controller.pose, AcadexAssistantPose.disappear);
      expect(controller.expression, AcadexAssistantExpression.farewell);
    });
  });

  group('AcadexAssistantShowcaseScreen Tests', () {
    testWidgets('Mounts showcase studio screen and renders controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AcadexAssistantShowcaseScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ACADEX Assistant Studio'), findsOneWidget);
      expect(find.text('ACADEX Academic Mentor & Campus Assistant'), findsOneWidget);
      expect(find.byType(AcadexAssistant), findsOneWidget);
      expect(find.text('CHOREOGRAPHED ACTIONS'), findsOneWidget);
      expect(find.text('FACIAL EXPRESSIONS'), findsOneWidget);
      expect(find.text('SIZE PRESETS & ACCESSIBILITY'), findsOneWidget);

      // Verify action buttons exist
      expect(find.text('👋 Greeting'), findsOneWidget);
      expect(find.text('🙋 Wave Hand'), findsOneWidget);
      expect(find.text('✨ Magic Gesture'), findsOneWidget);
      expect(find.text('🧹 Wipe / Erase'), findsOneWidget);
      expect(find.text('✍️ Write'), findsOneWidget);
    });
  });
}
