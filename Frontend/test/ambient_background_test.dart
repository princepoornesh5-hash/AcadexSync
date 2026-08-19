import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_container.dart';

void main() {
  group('AcadexAmbientBackground Tests', () {
    testWidgets('Renders background and child properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexAmbientBackground(
              density: AcadexAmbientDensity.standard,
              child: Center(
                child: Text('Main Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(IgnorePointer), findsWidgets);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('Density none renders only child without CustomPaint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexAmbientBackground(
              density: AcadexAmbientDensity.none,
              child: Center(
                child: Text('No Particles Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Particles Content'), findsOneWidget);
      // No custom painter for ambient background
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString().contains('ParticlePainter')), findsNothing);
    });

    testWidgets('Respects MediaQuery disableAnimations (Reduced Motion)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AcadexAmbientBackground(
                density: AcadexAmbientDensity.dense,
                child: Text('Static Frame Mode'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Static Frame Mode'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('AcadexPageContainer with ambientDensity integrates seamlessly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AcadexPageContainer(
              ambientDensity: AcadexAmbientDensity.subtle,
              child: Text('Container with Ambient Motion'),
            ),
          ),
        ),
      );

      expect(find.text('Container with Ambient Motion'), findsOneWidget);
      expect(find.byType(AcadexAmbientBackground), findsOneWidget);
    });
  });
}
