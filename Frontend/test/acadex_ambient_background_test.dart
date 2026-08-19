import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/widgets/acadex_ambient_background.dart';

void main() {
  group('AcadexAmbientBackground Widget Tests', () {
    testWidgets('renders successfully with default settings', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexAmbientBackground(
              child: Center(child: Text('Hello Acadex')),
            ),
          ),
        ),
      );

      expect(find.text('Hello Acadex'), findsOneWidget);
      expect(find.byType(AcadexAmbientBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    testWidgets('renders with all density configurations', (tester) async {
      for (final density in AcadexAmbientDensity.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AcadexAmbientBackground(
                density: density,
                child: Text('Density: ${density.name}'),
              ),
            ),
          ),
        );
        expect(find.text('Density: ${density.name}'), findsOneWidget);
      }
    });

    testWidgets('respects disableAnimations accessibility setting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AcadexAmbientBackground(
                child: Text('Reduced Motion Active'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Reduced Motion Active'), findsOneWidget);
      // Let one frame render
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AcadexAmbientBackground), findsOneWidget);
    });

    testWidgets('handles pointer movement in interactive mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexAmbientBackground(
              enablePointerInteraction: true,
              child: Center(child: Text('Interactive Surface')),
            ),
          ),
        ),
      );

      expect(find.text('Interactive Surface'), findsOneWidget);

      // Simulate mouse hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await tester.pump();
      await gesture.moveTo(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(const Offset(300, 300));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Interactive Surface'), findsOneWidget);
    });
  });
}
