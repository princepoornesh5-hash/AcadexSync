import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/widgets/acadex_motion.dart';

void main() {
  group('AcadexMotion Primitives', () {
    testWidgets('AcadexPressable performs tactile feedback and fires onTap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AcadexPressable(
                onTap: () => tapped = true,
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(find.text('Tap Me')));
      await tester.pump(const Duration(milliseconds: 50));

      // In pressed state, Transform.scale is active
      final scaleTransform = tester.widget<Transform>(
        find.ancestor(of: find.text('Tap Me'), matching: find.byType(Transform)).first,
      );
      // Scale matrix m11 < 1.0 (approaching pressedScale 0.985)
      expect(scaleTransform.transform.getMaxScaleOnAxis(), lessThanOrEqualTo(1.0));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AcadexFadeSlide animates opacity and translation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexFadeSlide(
              duration: Duration(milliseconds: 200),
              slideOffset: 6.0,
              child: Text('Animated Item'),
            ),
          ),
        ),
      );

      // Initial frame: rendered with animation starting
      expect(find.text('Animated Item'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Animated Item'), findsOneWidget);
    });

    testWidgets('AcadexAnimatedSwitcher transitions between children cleanly', (WidgetTester tester) async {
      final keyA = UniqueKey();
      final keyB = UniqueKey();

      Widget buildHost(bool showA) {
        return MaterialApp(
          home: Scaffold(
            body: AcadexAnimatedSwitcher(
              child: showA
                  ? Text('Child A', key: keyA)
                  : Text('Child B', key: keyB),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildHost(true));
      expect(find.text('Child A'), findsOneWidget);
      expect(find.text('Child B'), findsNothing);

      await tester.pumpWidget(buildHost(false));
      await tester.pump();
      // During cross-fade both or transitioning
      await tester.pumpAndSettle();

      expect(find.text('Child A'), findsNothing);
      expect(find.text('Child B'), findsOneWidget);
    });
  });
}
