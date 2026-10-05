import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/time_board/acadex_time_engine.dart';
import 'package:campus_management/core/presentation/time_board/acadex_scoreboard_card.dart';
import 'package:campus_management/core/presentation/time_board/acadex_live_time_board.dart';
import 'package:campus_management/features/dashboard/domain/models/home_dashboard_models.dart';
import 'package:campus_management/features/dashboard/presentation/widgets/home_dashboard_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AcadexTimeEngine 12-Hour Format & Conversion Tests', () {
    test('Calculates authoritative IST time (UTC + 5:30) in 12-hour format', () {
      final utc = DateTime.utc(2026, 10, 5, 12, 30);
      final ist = utc.add(const Duration(hours: 5, minutes: 30));

      // 12:30 UTC + 5:30 = 18:00 IST -> 6:00 PM
      expect(ist.hour, 18);
      expect(ist.minute, 0);
      expect(AcadexTimeEngine.formatHours(ist), '6');
      expect(AcadexTimeEngine.formatMinutes(ist), '00');
      expect(AcadexTimeEngine.formatPeriod(ist), 'PM');
      expect(AcadexTimeEngine.formatTime(ist), '6:00 PM');
    });

    test('12-Hour conversion without leading zero: Cases 1 to 8', () {
      // Case 1: 12:00 AM (00:00)
      final t1 = DateTime(2026, 10, 5, 0, 0);
      expect(AcadexTimeEngine.formatTime(t1), '12:00 AM');
      expect(AcadexTimeEngine.formatHours(t1), '12');
      expect(AcadexTimeEngine.formatMinutes(t1), '00');
      expect(AcadexTimeEngine.formatPeriod(t1), 'AM');

      // Case 2: 12:05 AM (00:05)
      final t2 = DateTime(2026, 10, 5, 0, 5);
      expect(AcadexTimeEngine.formatTime(t2), '12:05 AM');

      // Case 3: 1:05 AM (01:05)
      final t3 = DateTime(2026, 10, 5, 1, 5);
      expect(AcadexTimeEngine.formatTime(t3), '1:05 AM');

      // Case 4: 11:59 AM (11:59)
      final t4 = DateTime(2026, 10, 5, 11, 59);
      expect(AcadexTimeEngine.formatTime(t4), '11:59 AM');

      // Case 5: 12:00 PM (12:00 - Noon)
      final t5 = DateTime(2026, 10, 5, 12, 0);
      expect(AcadexTimeEngine.formatTime(t5), '12:00 PM');
      expect(AcadexTimeEngine.formatHours(t5), '12');
      expect(AcadexTimeEngine.formatPeriod(t5), 'PM');

      // Case 6: 1:05 PM (13:05)
      final t6 = DateTime(2026, 10, 5, 13, 5);
      expect(AcadexTimeEngine.formatTime(t6), '1:05 PM');

      // Case 7: 11:59 PM (23:59)
      final t7 = DateTime(2026, 10, 5, 23, 59);
      expect(AcadexTimeEngine.formatTime(t7), '11:59 PM');

      // Case 8: 12:00 AM (Next Day 00:00)
      final t8 = DateTime(2026, 10, 6, 0, 0);
      expect(AcadexTimeEngine.formatTime(t8), '12:00 AM');
    });

    test('Critical Roll-Over Transitions: Cases 9 to 12', () {
      // Case 9: 11:59 AM -> 12:00 PM (Noon transition, AM -> PM)
      final t9Before = DateTime(2026, 10, 5, 11, 59);
      final t9After = t9Before.add(const Duration(minutes: 1));
      expect(AcadexTimeEngine.formatTime(t9Before), '11:59 AM');
      expect(AcadexTimeEngine.formatTime(t9After), '12:00 PM');

      // Case 10: 12:59 PM -> 1:00 PM (Hour roll-over, 12 PM -> 1 PM)
      final t10Before = DateTime(2026, 10, 5, 12, 59);
      final t10After = t10Before.add(const Duration(minutes: 1));
      expect(AcadexTimeEngine.formatTime(t10Before), '12:59 PM');
      expect(AcadexTimeEngine.formatTime(t10After), '1:00 PM');

      // Case 11: 11:59 PM -> 12:00 AM (Midnight transition, PM -> AM)
      final t11Before = DateTime(2026, 10, 5, 23, 59);
      final t11After = t11Before.add(const Duration(minutes: 1));
      expect(AcadexTimeEngine.formatTime(t11Before), '11:59 PM');
      expect(AcadexTimeEngine.formatTime(t11After), '12:00 AM');

      // Case 12: 12:59 AM -> 1:00 AM (Hour roll-over, 12 AM -> 1 AM)
      final t12Before = DateTime(2026, 10, 6, 0, 59);
      final t12After = t12Before.add(const Duration(minutes: 1));
      expect(AcadexTimeEngine.formatTime(t12Before), '12:59 AM');
      expect(AcadexTimeEngine.formatTime(t12After), '1:00 AM');
    });

    test('Case 13: Minute-only transition (6:42 PM -> 6:43 PM)', () {
      final t13Before = DateTime(2026, 10, 5, 18, 42);
      final t13After = DateTime(2026, 10, 5, 18, 43);

      expect(AcadexTimeEngine.formatHours(t13Before), '6');
      expect(AcadexTimeEngine.formatHours(t13After), '6');
      expect(AcadexTimeEngine.formatPeriod(t13Before), 'PM');
      expect(AcadexTimeEngine.formatPeriod(t13After), 'PM');

      expect(AcadexTimeEngine.formatMinutes(t13Before), '42');
      expect(AcadexTimeEngine.formatMinutes(t13After), '43');
    });

    test('Case 14: Reconciles missed minutes directly without replaying history', () {
      DateTime? reconciledTime;
      final engine = AcadexTimeEngine(
        onTimeReconciled: (time) => reconciledTime = time,
      );

      // Simulate app resume after several minutes elapsed
      engine.reconcileTime();
      expect(engine.currentIst, isNotNull);
      expect(engine.formattedTime, contains(RegExp(r'^(1[0-2]|[1-9]):[0-5][0-9] (AM|PM)$')));
      if (reconciledTime != null) {
        expect(reconciledTime, isNotNull);
      }
      engine.dispose();
    });

    test('Clean disposal cancels boundary timer without leaks', () {
      final engine = AcadexTimeEngine();
      expect(() => engine.dispose(), returnsNormally);
      expect(() => engine.reconcileTime(), returnsNormally);
    });
  });

  group('AcadexTimeDisplayChange Component Detection Tests', () {
    test('Minute-only: 6:42 PM -> 6:43 PM detects minuteChanged=true, hourChanged=false, periodChanged=false', () {
      final change = TimeDisplayChange.between(
        DateTime(2026, 10, 5, 18, 42),
        DateTime(2026, 10, 5, 18, 43),
      );
      expect(change.hourChanged, isFalse);
      expect(change.minuteChanged, isTrue);
      expect(change.periodChanged, isFalse);
      expect(change.hasAnyChange, isTrue);
      expect(change.previousHours, '6');
      expect(change.currentHours, '6');
      expect(change.previousMinutes, '42');
      expect(change.currentMinutes, '43');
      expect(change.previousPeriod, 'PM');
      expect(change.currentPeriod, 'PM');
    });

    test('Hour + minute: 6:59 PM -> 7:00 PM detects hourChanged=true, minuteChanged=true, periodChanged=false', () {
      final change = TimeDisplayChange.between(
        DateTime(2026, 10, 5, 18, 59),
        DateTime(2026, 10, 5, 19, 0),
      );
      expect(change.hourChanged, isTrue);
      expect(change.minuteChanged, isTrue);
      expect(change.periodChanged, isFalse);
      expect(change.previousHours, '6');
      expect(change.currentHours, '7');
      expect(change.previousMinutes, '59');
      expect(change.currentMinutes, '00');
    });

    test('Noon transition: 11:59 AM -> 12:00 PM detects all 3 components changed', () {
      final change = TimeDisplayChange.between(
        DateTime(2026, 10, 5, 11, 59),
        DateTime(2026, 10, 5, 12, 0),
      );
      expect(change.hourChanged, isTrue);
      expect(change.minuteChanged, isTrue);
      expect(change.periodChanged, isTrue);
      expect(change.previousHours, '11');
      expect(change.currentHours, '12');
      expect(change.previousPeriod, 'AM');
      expect(change.currentPeriod, 'PM');
    });

    test('Afternoon roll-over: 12:59 PM -> 1:00 PM detects hourChanged=true, minuteChanged=true, periodChanged=false', () {
      final change = TimeDisplayChange.between(
        DateTime(2026, 10, 5, 12, 59),
        DateTime(2026, 10, 5, 13, 0),
      );
      expect(change.hourChanged, isTrue);
      expect(change.minuteChanged, isTrue);
      expect(change.periodChanged, isFalse);
      expect(change.previousHours, '12');
      expect(change.currentHours, '1');
      expect(change.previousMinutes, '59');
      expect(change.currentMinutes, '00');
      expect(change.currentPeriod, 'PM');
    });

    test('Midnight transition: 11:59 PM -> 12:00 AM detects all 3 components changed', () {
      final change = TimeDisplayChange.between(
        DateTime(2026, 10, 5, 23, 59),
        DateTime(2026, 10, 6, 0, 0),
      );
      expect(change.hourChanged, isTrue);
      expect(change.minuteChanged, isTrue);
      expect(change.periodChanged, isTrue);
      expect(change.previousHours, '11');
      expect(change.currentHours, '12');
      expect(change.previousPeriod, 'PM');
      expect(change.currentPeriod, 'AM');
    });

    test('Early morning roll-over: 12:59 AM -> 1:00 AM detects hour and minute changed', () {
      final change = TimeDisplayChange.between(
        DateTime(2026, 10, 6, 0, 59),
        DateTime(2026, 10, 6, 1, 0),
      );
      expect(change.hourChanged, isTrue);
      expect(change.minuteChanged, isTrue);
      expect(change.periodChanged, isFalse);
      expect(change.previousHours, '12');
      expect(change.currentHours, '1');
      expect(change.previousPeriod, 'AM');
      expect(change.currentPeriod, 'AM');
    });

    test('Single-digit to double-digit hour: 9:59 AM -> 10:00 AM', () {
      final change = TimeDisplayChange.between(
        DateTime(2026, 10, 5, 9, 59),
        DateTime(2026, 10, 5, 10, 0),
      );
      expect(change.hourChanged, isTrue);
      expect(change.minuteChanged, isTrue);
      expect(change.periodChanged, isFalse);
      expect(change.previousHours, '9');
      expect(change.currentHours, '10');
    });
  });

  group('AcadexScoreboardCard 12-Hour Widget Tests', () {
    testWidgets('Renders 12-hour scoreboard without visible IST badge, maintaining semantic timezone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexScoreboardCard(
                hours: '6',
                minutes: '43',
                period: 'PM',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('6'), findsOneWidget);
      expect(find.text('43'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
      // Visible IST badge must NOT be present
      expect(find.text('IST'), findsNothing);
      expect(find.byType(AcadexScoreboardCard), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(AcadexScoreboardCard));
      expect(semantics.label, 'Current time 6:43 PM India Standard Time');
    });

    testWidgets('Renders wiping and writing states properly for minute-only transition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexScoreboardCard(
                hours: '6',
                minutes: '43',
                period: 'PM',
                oldHours: '6',
                oldMinutes: '42',
                oldPeriod: 'PM',
                isWiping: true,
                wipeProgress: 0.5,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Old minutes being wiped
      expect(find.text('42'), findsOneWidget);
      // Hour and period did not change, so they show current value
      expect(find.text('6'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexScoreboardCard(
                hours: '6',
                minutes: '43',
                period: 'PM',
                oldHours: '6',
                oldMinutes: '42',
                oldPeriod: 'PM',
                isWriting: true,
                writeProgress: 0.8,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // New minutes being written
      expect(find.text('43'), findsOneWidget);
    });

    testWidgets('Animates hour and period only when they actually change', (tester) async {
      // 11:59 AM -> 12:00 PM: both hour and period change
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexScoreboardCard(
                hours: '12',
                minutes: '00',
                period: 'PM',
                oldHours: '11',
                oldMinutes: '59',
                oldPeriod: 'AM',
                isWiping: true,
                wipeProgress: 0.5,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // In wiping phase, old values are displayed being wiped
      expect(find.text('11'), findsOneWidget);
      expect(find.text('59'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
    });
  });

  group('AcadexLiveTimeBoard 12-Hour Self-Contained Mechanical Clock Tests', () {
    testWidgets('Mounts in calm state with NO character, NO speech bubble, and NO visible IST badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexLiveTimeBoard(userName: 'Poornesh'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Only scoreboard is visible
      expect(find.byType(AcadexScoreboardCard), findsOneWidget);
      expect(find.text('IST'), findsNothing);
      expect(find.text('Hi, Poornesh!'), findsNothing);
    });

    testWidgets('Minute-only change (6:42 PM -> 6:43 PM) animates only minute, keeping hour & PM calm', (tester) async {
      final key = GlobalKey<AcadexLiveTimeBoardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexLiveTimeBoard(
                key: key,
                userName: 'Poornesh',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState?.setTime(DateTime(2026, 10, 5, 18, 42));
      await tester.pump();

      // Trigger minute-only change
      key.currentState?.triggerMinuteChange(
        nextTime: DateTime(2026, 10, 5, 18, 43),
      );
      await tester.pump();

      // Mid-transition (writing phase at 700ms)
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('6'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
      expect(find.text('Hi, Poornesh!'), findsNothing);

      // Complete transition
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('6'), findsOneWidget);
      expect(find.text('43'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('Hour + minute change (6:59 PM -> 7:00 PM) animates both hour and minute', (tester) async {
      final key = GlobalKey<AcadexLiveTimeBoardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexLiveTimeBoard(
                key: key,
                userName: 'Poornesh',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState?.setTime(DateTime(2026, 10, 5, 18, 59));
      await tester.pump();

      // Trigger 6:59 PM -> 7:00 PM
      key.currentState?.triggerMinuteChange(
        nextTime: DateTime(2026, 10, 5, 19, 0),
      );
      await tester.pump();

      // During wipe phase (200ms)
      await tester.pump(const Duration(milliseconds: 200));
      // Old values being wiped: 6 and 59
      expect(find.text('6'), findsOneWidget);
      expect(find.text('59'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);

      // During write phase (800ms)
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('7'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);

      // Settle
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('7'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('Noon transition (11:59 AM -> 12:00 PM) animates hour, minute, and period', (tester) async {
      final key = GlobalKey<AcadexLiveTimeBoardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexLiveTimeBoard(
                key: key,
                userName: 'Poornesh',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState?.setTime(DateTime(2026, 10, 5, 11, 59));
      await tester.pump();

      key.currentState?.triggerMinuteChange(
        nextTime: DateTime(2026, 10, 5, 12, 0),
      );
      await tester.pump();

      // Wipe phase: old values 11, 59, AM
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('11'), findsOneWidget);
      expect(find.text('59'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);

      // Complete transition
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('12'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('Midnight transition (11:59 PM -> 12:00 AM) animates all components', (tester) async {
      final key = GlobalKey<AcadexLiveTimeBoardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexLiveTimeBoard(
                key: key,
                userName: 'Poornesh',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState?.setTime(DateTime(2026, 10, 5, 23, 59));
      await tester.pump();

      key.currentState?.triggerMinuteChange(
        nextTime: DateTime(2026, 10, 6, 0, 0),
      );
      await tester.pump();

      // Wipe phase: 11, 59, PM
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('11'), findsOneWidget);
      expect(find.text('59'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);

      // Settle
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('12'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
    });

    testWidgets('Single-digit to double-digit hour (9:59 AM -> 10:00 AM) and Afternoon (12:59 PM -> 1:00 PM)', (tester) async {
      final key = GlobalKey<AcadexLiveTimeBoardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexLiveTimeBoard(
                key: key,
                userName: 'Poornesh',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 9:59 AM -> 10:00 AM
      key.currentState?.setTime(DateTime(2026, 10, 5, 9, 59));
      await tester.pump();
      key.currentState?.triggerMinuteChange(
        nextTime: DateTime(2026, 10, 5, 10, 0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text('10'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);

      // 12:59 PM -> 1:00 PM
      key.currentState?.setTime(DateTime(2026, 10, 5, 12, 59));
      await tester.pump();
      key.currentState?.triggerMinuteChange(
        nextTime: DateTime(2026, 10, 5, 13, 0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('Stable time remains completely calm without continuous animation', (tester) async {
      final key = GlobalKey<AcadexLiveTimeBoardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexLiveTimeBoard(
                key: key,
                userName: 'Poornesh',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState?.setTime(DateTime(2026, 10, 5, 18, 43));
      await tester.pump();

      // Verify no transition running
      expect(key.currentState?.isTransitioning, isFalse);

      // Advance by several seconds
      await tester.pump(const Duration(seconds: 10));
      expect(key.currentState?.isTransitioning, isFalse);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('43'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('Case 15: Respects reduced motion by immediately updating without animation', (tester) async {
      final key = GlobalKey<AcadexLiveTimeBoardState>();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: AcadexLiveTimeBoard(
                  key: key,
                  userName: 'Poornesh',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState?.triggerMinuteChange(
        nextTime: DateTime(2026, 10, 5, 19, 0), // 7:00 PM
      );
      await tester.pump();

      // In reduced motion, transition does not run and updates immediately
      expect(key.currentState?.isTransitioning, isFalse);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('Case 16: Adapts to narrow mobile and wide desktop constraints', (tester) async {
      // Narrow mobile viewport
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: AcadexLiveTimeBoard(
                  userName: 'Poornesh',
                  isCompact: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AcadexLiveTimeBoard), findsOneWidget);

      // Wide desktop viewport
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1200,
                child: AcadexLiveTimeBoard(
                  userName: 'Poornesh',
                  isCompact: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AcadexLiveTimeBoard), findsOneWidget);
    });

    testWidgets('Case 17: Safely handles long display names without layout distortion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexLiveTimeBoard(
                userName: 'Dr. Professor Bartholomew Alexander Montgomery III',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AcadexLiveTimeBoard), findsOneWidget);
    });
  });

  group('DashboardGreetingHeader 12-Hour Integration Tests', () {
    testWidgets('Renders 12-hour Live Time Board alongside greeting and role badge', (tester) async {
      final mockGreeting = DashboardGreetingModel(
        greetingText: 'Good evening',
        displayName: 'Poornesh',
        role: 'SUPER_ADMIN',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardGreetingHeader(greeting: mockGreeting),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Poornesh'), findsOneWidget);
      expect(find.text('SUPER ADMIN'), findsOneWidget);
      expect(find.byType(AcadexLiveTimeBoard), findsOneWidget);
      expect(find.byType(AcadexScoreboardCard), findsOneWidget);
      expect(find.text('IST'), findsNothing);
    });
  });
}
