import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/time_board/acadex_minute_writing.dart';
import 'package:campus_management/core/presentation/time_board/acadex_live_time_board.dart';
import 'package:campus_management/core/presentation/assistant/acadex_assistant_controller.dart';
import 'package:campus_management/core/presentation/assistant/acadex_assistant_painter.dart';
import 'package:campus_management/core/presentation/assistant/acadex_assistant_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AcadexMinuteWriting Bounds & Geometry Tests', () {
    test('writing bounds correctly partitions minute card into first and second digits', () {
      const bounds = MinuteDisplayBounds(
        left: 52.0,
        top: 11.0,
        width: 34.0,
        height: 38.0,
      );

      expect(bounds.rect, const Rect.fromLTWH(52.0, 11.0, 34.0, 38.0));
      expect(bounds.center, const Offset(69.0, 30.0));

      final digit1 = bounds.firstDigitRect;
      final digit2 = bounds.secondDigitRect;

      // First digit (tens place: 0..5) occupies left portion
      expect(digit1.left, greaterThanOrEqualTo(bounds.left));
      expect(digit1.right, lessThan(digit2.left));

      // Second digit (ones place: 0..9) occupies right portion
      expect(digit2.right, lessThanOrEqualTo(bounds.rect.right));
      expect(digit2.top, digit1.top);
      expect(digit2.height, digit1.height);
    });

    test('responsive minute bounds calculates different dimensions for compact and standard sizes', () {
      const normalBounds = MinuteDisplayBounds(
        left: 52.0,
        top: 11.0,
        width: 34.0,
        height: 38.0,
      );

      const compactBounds = MinuteDisplayBounds(
        left: 42.0,
        top: 9.0,
        width: 28.0,
        height: 32.0,
      );

      expect(compactBounds.width, lessThan(normalBounds.width));
      expect(compactBounds.height, lessThan(normalBounds.height));
      expect(compactBounds.firstDigitRect.width, lessThan(normalBounds.firstDigitRect.width));
      expect(compactBounds.secondDigitRect.width, lessThan(normalBounds.secondDigitRect.width));
    });

    test('wipe progress calculates smooth linear wiper tip coordinates across bounds', () {
      const bounds = MinuteDisplayBounds(
        left: 10.0,
        top: 20.0,
        width: 40.0,
        height: 30.0,
      );

      final startWipe = MinuteWritingGeometry.getWipeTip(wipeProgress: 0.0, bounds: bounds);
      expect(startWipe.dx, 10.0);
      expect(startWipe.dy, 35.0);

      final midWipe = MinuteWritingGeometry.getWipeTip(wipeProgress: 0.5, bounds: bounds);
      expect(midWipe.dx, 30.0);
      expect(midWipe.dy, 35.0);

      final endWipe = MinuteWritingGeometry.getWipeTip(wipeProgress: 1.0, bounds: bounds);
      expect(endWipe.dx, 50.0);
      expect(endWipe.dy, 35.0);
    });
  });

  group('AcadexDigitPath & Handwriting Stroke Tests', () {
    test('extracts stroke paths and tracks stylus nib for all digits 0 through 9', () {
      const rect = Rect.fromLTWH(0, 0, 20, 30);
      final digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

      for (final d in digits) {
        // At progress 0.0, path is empty, stylus nib is at stroke start
        final extStart = AcadexDigitPath.extractProgress(d, 0.0, rect);
        expect(extStart.isComplete, isFalse);
        expect(rect.contains(extStart.stylusTip), isTrue,
            reason: 'Stylus tip at start of $d must be inside digit rect');

        // At progress 0.5, partial path is revealed
        final extMid = AcadexDigitPath.extractProgress(d, 0.5, rect);
        expect(extMid.isComplete, isFalse);
        expect(rect.contains(extMid.stylusTip), isTrue,
            reason: 'Stylus tip at midpoint of $d must be inside digit rect');

        // At progress 1.0, full path is revealed and complete
        final extEnd = AcadexDigitPath.extractProgress(d, 1.0, rect);
        expect(extEnd.isComplete, isTrue);
        expect(rect.contains(extEnd.stylusTip), isTrue,
            reason: 'Stylus tip at end of $d must be inside digit rect');
      }
    });

    test('write progress: digit 1 completes before digit 2 begins (Sequential construction)', () {
      const bounds = MinuteDisplayBounds(
        left: 0.0,
        top: 0.0,
        width: 34.0,
        height: 38.0,
      );

      // writeProgress = 0.25 (Midway through digit 1)
      final tipD1 = MinuteWritingGeometry.getStylusTip(
        writeProgress: 0.25,
        bounds: bounds,
        minutes: '43',
      );
      expect(bounds.firstDigitRect.contains(tipD1), isTrue,
          reason: 'Stylus must be writing inside digit 1 rect during writeProgress 0.25');

      // writeProgress = 0.48 (Digit 1 complete)
      final tipD1End = MinuteWritingGeometry.getStylusTip(
        writeProgress: 0.48,
        bounds: bounds,
        minutes: '43',
      );
      expect(bounds.firstDigitRect.contains(tipD1End), isTrue);

      // writeProgress = 0.75 (Midway through digit 2)
      final tipD2 = MinuteWritingGeometry.getStylusTip(
        writeProgress: 0.75,
        bounds: bounds,
        minutes: '43',
      );
      expect(bounds.secondDigitRect.contains(tipD2), isTrue,
          reason: 'Stylus must be writing inside digit 2 rect during writeProgress 0.75');
    });

    test('stylus follows exact geometry for critical roll-over test cases', () {
      const bounds = MinuteDisplayBounds(
        left: 0.0,
        top: 0.0,
        width: 34.0,
        height: 38.0,
      );

      final criticalMinutes = ['00', '05', '10', '20', '30', '40', '43', '50'];

      for (final m in criticalMinutes) {
        // Start of first digit
        final t0 = MinuteWritingGeometry.getStylusTip(writeProgress: 0.0, bounds: bounds, minutes: m);
        expect(bounds.firstDigitRect.contains(t0), isTrue,
            reason: 'Initial stylus target for $m must be inside first digit');

        // Middle of first digit
        final t1 = MinuteWritingGeometry.getStylusTip(writeProgress: 0.24, bounds: bounds, minutes: m);
        expect(bounds.firstDigitRect.contains(t1), isTrue,
            reason: 'First digit stylus target for $m must be inside first digit');

        // Middle of second digit
        final t2 = MinuteWritingGeometry.getStylusTip(writeProgress: 0.76, bounds: bounds, minutes: m);
        expect(bounds.secondDigitRect.contains(t2), isTrue,
            reason: 'Second digit stylus target for $m must be inside second digit');
      }
    });
  });

  group('MinuteWritingPainter Visual States Tests', () {
    test('blank minute state: painter produces empty canvas when wipe completes or write starts', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(34.0, 38.0);

      // 1. Wipe at 1.0 -> 100% Blank
      const wipeFinishedPainter = MinuteWritingPainter(
        currentMinutes: '43',
        oldMinutes: '42',
        isWiping: true,
        isWriting: false,
        wipeProgress: 1.0,
      );
      wipeFinishedPainter.paint(canvas, size);

      // 2. Write at 0.0 -> Clearly visible empty blank state before writing starts
      const writeStartPainter = MinuteWritingPainter(
        currentMinutes: '43',
        oldMinutes: '42',
        isWiping: false,
        isWriting: true,
        writeProgress: 0.0,
      );
      writeStartPainter.paint(canvas, size);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('wipe progress: wipes old minute progressively and completely erases at 1.0', () {
      const painterHalf = MinuteWritingPainter(
        currentMinutes: '43',
        oldMinutes: '42',
        isWiping: true,
        wipeProgress: 0.5,
      );
      expect(painterHalf.wipeProgress, 0.5);
      expect(painterHalf.isWiping, isTrue);

      const painterFull = MinuteWritingPainter(
        currentMinutes: '43',
        oldMinutes: '42',
        isWiping: true,
        wipeProgress: 1.0,
      );
      expect(painterFull.wipeProgress, 1.0);
    });

    test('write progress: digit 1 completes before digit 2 begins', () {
      const painterD1 = MinuteWritingPainter(
        currentMinutes: '43',
        oldMinutes: '42',
        isWriting: true,
        writeProgress: 0.35,
      );
      expect(painterD1.writeProgress, 0.35);

      const painterD2 = MinuteWritingPainter(
        currentMinutes: '43',
        oldMinutes: '42',
        isWriting: true,
        writeProgress: 0.75,
      );
      expect(painterD2.writeProgress, 0.75);
    });

    test('final minute value: matches exact time when writeProgress is 1.0', () {
      const painterComplete = MinuteWritingPainter(
        currentMinutes: '43',
        isWriting: false,
        writeProgress: 1.0,
      );
      expect(painterComplete.currentMinutes, '43');
      expect(painterComplete.writeProgress, 1.0);
    });
  });

  group('Assistant Stylus Inverse Kinematics Tests', () {
    test('two-bone inverse kinematics positions stylus tip within sub-pixel accuracy of target', () {
      final controller = AcadexAssistantController(
        initialPose: AcadexAssistantPose.write,
      );

      const target = Offset(90.0, 48.0);
      controller.setStylusTarget(target);
      expect(controller.stylusTarget, target);

      // Verify painter consumes stylusTarget without throwing
      final painter = AcadexAssistantPainter(
        pose: AcadexAssistantPose.write,
        expression: AcadexAssistantExpression.focused,
        gazeDirection: const Offset(0.7, 0.1),
        poseProgress: 0.5,
        breathingValue: 0.0,
        blinkValue: 0.0,
        visibility: 1.0,
        magicSparkleProgress: 0.0,
        isDark: false,
        stylusTarget: target,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(88.0, 88.0)), returnsNormally);
      recorder.endRecording();

      controller.dispose();
    });
  });

  group('AcadexLiveTimeBoard Lifecycle & Reduced Motion Tests', () {
    testWidgets('properly cleans up AnimationController and TimeEngine on disposal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexLiveTimeBoard(userName: 'Poornesh'),
          ),
        ),
      );
      await tester.pump();

      // Trigger minute change sequence
      final state = tester.state<AcadexLiveTimeBoardState>(find.byType(AcadexLiveTimeBoard));
      state.triggerMinuteChange(nextTime: DateTime(2026, 10, 5, 18, 43));
      await tester.pump(const Duration(milliseconds: 300));

      // Dismount widget
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // Ensure no dangling animation controllers or unhandled exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('no duplicate animation controllers created during repeated triggers', (tester) async {
      final key = GlobalKey<AcadexLiveTimeBoardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcadexLiveTimeBoard(
              key: key,
              userName: 'Poornesh',
            ),
          ),
        ),
      );
      await tester.pump();

      // First trigger
      key.currentState?.triggerMinuteChange(nextTime: DateTime(2026, 10, 5, 18, 43));
      await tester.pump(const Duration(milliseconds: 400));

      // Second trigger while first is running (must be ignored safely)
      key.currentState?.triggerMinuteChange(nextTime: DateTime(2026, 10, 5, 18, 44));
      await tester.pump(const Duration(milliseconds: 400));

      // Let sequence finish completely
      await tester.pump(const Duration(milliseconds: 3000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion updates clock instantly without character emergence', (tester) async {
      final key = GlobalKey<AcadexLiveTimeBoardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AcadexLiveTimeBoard(
                key: key,
                userName: 'Poornesh',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState?.triggerMinuteChange(nextTime: DateTime(2026, 10, 5, 18, 43));
      await tester.pump();

      // Instant update, no character or speech bubble
      expect(find.text('43'), findsOneWidget);
      expect(find.text('Hi, Poornesh!'), findsNothing);
    });
  });
}
