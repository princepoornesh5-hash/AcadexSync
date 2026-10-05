import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/widgets/acadex_sliver_page_header.dart';

void main() {
  group('AcadexSliverPageHeader', () {
    testWidgets('renders single title widget in expanded state without duplication', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const AcadexSliverPageHeader(
                  title: 'Single Header Title',
                  subtitle: 'Expanded subtitle context',
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(title: Text('Item $index')),
                    childCount: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify single title widget in the entire tree (no duplicate title widget)
      expect(find.text('Single Header Title'), findsOneWidget);
      expect(find.text('Expanded subtitle context'), findsOneWidget);

      // Verify subtitle has non-zero opacity
      final subtitleFade = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Expanded subtitle context'),
          matching: find.byType(Opacity),
        ).first,
      );
      expect(subtitleFade.opacity, greaterThan(0.8));
    });

    testWidgets('scroll transition smoothly compacts header and fades subtitle without duplicate title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const AcadexSliverPageHeader(
                  title: 'Transforming Module',
                  subtitle: 'Subtitle that fades away',
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(title: Text('Item $index')),
                    childCount: 40,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 1. Initial State: Exactly ONE title widget
      expect(find.text('Transforming Module'), findsOneWidget);

      // 2. Intermediate scroll (drag by 40px)
      final scrollable = find.byType(Scrollable);
      await tester.drag(scrollable, const Offset(0, -40));
      await tester.pump();

      // Still exactly ONE title widget during transformation (no teleporting duplicate)
      expect(find.text('Transforming Module'), findsOneWidget);

      // 3. Full collapse (drag by another 200px)
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      // In compact state, title is STILL exactly ONE widget
      expect(find.text('Transforming Module'), findsOneWidget);

      // Subtitle is completely faded out (findsNothing for zero opacity)
      expect(find.text('Subtitle that fades away'), findsNothing);

      // 4. Reverse scroll back to top
      await tester.drag(scrollable, const Offset(0, 300));
      await tester.pumpAndSettle();

      // Restored to expanded state
      expect(find.text('Transforming Module'), findsOneWidget);
      expect(find.text('Subtitle that fades away'), findsOneWidget);
      final restoredSubtitleFade = tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Subtitle that fades away'),
          matching: find.byType(Opacity),
        ).first,
      );
      expect(restoredSubtitleFade.opacity, greaterThan(0.8));
    });

    testWidgets('handles leading and trailing actions correctly', (WidgetTester tester) async {
      bool leadingTapped = false;
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                AcadexSliverPageHeader(
                  title: 'Action Header',
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => leadingTapped = true,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => actionTapped = true,
                    ),
                  ],
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(title: Text('Item $index')),
                    childCount: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(leadingTapped, isTrue);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(actionTapped, isTrue);
    });

    testWidgets('dynamic content and long titles handle constraints without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const AcadexSliverPageHeader(
                  title: 'A Very Long Academic Structure Title That Exceeds A Single Line Comfortably',
                  subtitle: 'A similarly comprehensive contextual description detailing department courses, faculty distributions, and institutional metrics.',
                ),
                SliverList(
                  delegate: SliverChildListDelegate([const SizedBox(height: 1000)]),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify rendering without overflow exceptions
      expect(tester.takeException(), isNull);
      expect(find.textContaining('A Very Long Academic Structure'), findsOneWidget);
    });

    testWidgets('adapts gracefully to large accessibility text scaling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  const AcadexSliverPageHeader(
                    title: 'Accessibility Scaled Title',
                    subtitle: 'Context subtitle with text scaling enabled',
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([const SizedBox(height: 600)]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Accessibility Scaled Title'), findsOneWidget);

      // Drag to compact state under large text scale
      final scrollable = find.byType(Scrollable);
      await tester.drag(scrollable, const Offset(0, -150));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Accessibility Scaled Title'), findsOneWidget);
    });
  });
}
