import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campus_management/core/presentation/design_system/acadex_breakpoints.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_container.dart';
import 'package:campus_management/core/presentation/widgets/acadex_page_header.dart';
import 'package:campus_management/core/presentation/widgets/acadex_sliver_page_header.dart';
import 'package:campus_management/core/presentation/widgets/acadex_button.dart';
import 'package:campus_management/core/presentation/widgets/acadex_badge.dart';

void main() {
  group('ACADEX Responsive Design System Tests', () {
    testWidgets('AcadexBreakpoints accurately classifies device form factors', (tester) async {
      Widget buildTest(double width) {
        return MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(
            builder: (context) {
              return Text(
                AcadexBreakpoints.isMobile(context)
                    ? 'mobile'
                    : (AcadexBreakpoints.isTablet(context) ? 'tablet' : 'desktop'),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        );
      }

      await tester.pumpWidget(buildTest(320));
      expect(find.text('mobile'), findsOneWidget);

      await tester.pumpWidget(buildTest(360));
      expect(find.text('mobile'), findsOneWidget);

      await tester.pumpWidget(buildTest(393));
      expect(find.text('mobile'), findsOneWidget);

      await tester.pumpWidget(buildTest(768));
      expect(find.text('tablet'), findsOneWidget);

      await tester.pumpWidget(buildTest(1200));
      expect(find.text('desktop'), findsOneWidget);
    });

    testWidgets('AcadexPageContainer adds status bar padding when no AppBar is present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              padding: EdgeInsets.only(top: 48, bottom: 34),
            ),
            child: Scaffold(
              body: AcadexPageContainer(
                child: const Text('Top Content'),
              ),
            ),
          ),
        ),
      );

      final contentOffset = tester.getTopLeft(find.text('Top Content'));
      // contentOffset.dy must be >= 48 (status bar inset)
      expect(contentOffset.dy >= 48, isTrue,
          reason: 'Page content must start strictly below the 48px system status bar');
    });

    testWidgets('AcadexPageContainer avoids duplicate padding when AppBar absorbs top inset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              padding: EdgeInsets.only(top: 48, bottom: 34),
            ),
            child: Scaffold(
              appBar: AppBar(title: const Text('AppBar Title')),
              body: AcadexPageContainer(
                child: const Text('Body Content'),
              ),
            ),
          ),
        ),
      );

      final bodyOffset = tester.getTopLeft(find.text('Body Content'));
      final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
      // Body content should start directly below AppBar plus standard compact padding (12px), not an extra 48px
      expect(bodyOffset.dy, equals(appBarBottom + 12.0));
    });

    testWidgets('AcadexPageHeader displays actions on dedicated row on narrow screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(360, 800)),
            child: Scaffold(
              body: AcadexPageHeader(
                title: 'Academic Structure',
                subtitle: 'Manage departments and programs',
                actions: [
                  AcadexButton(
                    label: 'Setup Department',
                    icon: LucideIcons.building,
                    onPressed: () {},
                  ),
                  AcadexButton(
                    label: 'Create Course',
                    icon: LucideIcons.plus,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify header rendered without overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Academic Structure'), findsOneWidget);
      expect(find.text('Setup Department'), findsOneWidget);
      expect(find.text('Create Course'), findsOneWidget);

      final titleBottom = tester.getBottomLeft(find.text('Academic Structure')).dy;
      final buttonTop = tester.getTopLeft(find.text('Setup Department')).dy;
      // On mobile (360px), multi-action buttons are placed below the title
      expect(buttonTop >= titleBottom, isTrue,
          reason: 'Actions must not collide horizontally with title on narrow viewports');
    });

    testWidgets('AcadexSliverPageHeader separates title and toolbar actions vertically', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              padding: EdgeInsets.only(top: 24),
            ),
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  AcadexSliverPageHeader(
                    title: 'Timetable Hub',
                    subtitle: 'Weekly schedule authoring',
                    actions: [
                      IconButton(
                        icon: const Icon(LucideIcons.calendar),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 200)),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Timetable Hub'), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);

      final iconCenter = tester.getCenter(find.byIcon(LucideIcons.calendar));
      final titleTop = tester.getTopLeft(find.text('Timetable Hub')).dy;
      // Title top must be below the toolbar actions when fully expanded
      expect(titleTop > iconCenter.dy, isTrue,
          reason: 'Expanded title must sit below the toolbar actions bar');
    });

    testWidgets('Responsive Card & Badge text wraps cleanly under high accessibility font scale', (tester) async {
      const widths = [320.0, 360.0, 393.0, 430.0];
      const fontScales = [1.0, 1.15, 1.3];

      for (final width in widths) {
        for (final scale in fontScales) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(child: Text('S')),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Aarav Chandrasekharan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'ENG-2026-CS-010492',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 0,
                            child: AcadexBadge(
                              label: 'Pending Activation',
                              variant: AcadexBadgeVariant.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Overflow occurred at width $width with font scale $scale');
        }
      }
    });

    testWidgets('Timetable tag and action buttons fit narrow 320px viewport without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(1.15),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Computer Science Year 3 Sem 5',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: const Text(
                                '09:00 - 17:00 (50m slots)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('Edit Draft', overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: const Text('Open Grid', overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: '320px narrow screen with 1.15x font scale must not cause overflow');
    });

    testWidgets('AI Assistant composer disclaimer wraps cleanly across widths and font scaling', (tester) async {
      const widths = [320.0, 360.0, 393.0];
      const fontScales = [1.0, 1.2, 1.3];

      for (final width in widths) {
        for (final scale in fontScales) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 700),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Acadex AI can make mistakes. Verify important academic information.',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'AI composer disclaimer must not overflow at width $width, scale $scale');
        }
      }
    });
  });
}
