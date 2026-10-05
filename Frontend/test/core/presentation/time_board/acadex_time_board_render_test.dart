import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_management/core/presentation/time_board/acadex_live_time_board.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Renders and captures AcadexLiveTimeBoard 8 mechanical transitions', (tester) async {
    await tester.binding.runAsync(() async {
      final fontBytes = await File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytes();
      final fontByteData = ByteData.view(fontBytes.buffer);
      final fontLoader = FontLoader('Inter');
      fontLoader.addFont(Future.value(fontByteData));
      await fontLoader.load();
    });

    final key = GlobalKey<AcadexLiveTimeBoardState>();
    final repaintKey = GlobalKey();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: Container(
                width: 700,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'P',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Poornesh',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Text(
                                  'SUPER ADMIN',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  '•  Today, 5 Oct',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Live Time Board with key for triggering
                    AcadexLiveTimeBoard(
                      key: key,
                      userName: 'Poornesh',
                      isCompact: false,
                      initialTime: DateTime(2026, 10, 5, 18, 42),
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

    Future<void> saveScreenshot(String filename) async {
      await tester.binding.runAsync(() async {
        final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) return;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          final dir = Directory('/Users/poornesh/.gemini/antigravity-ide/brain/d99a5838-d3ca-40bf-b2a8-0f2e2e5d0f74');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final file = File('${dir.path}/$filename');
          await file.writeAsBytes(pngBytes);
        }
      });
    }

    // 1. Stable clock (6:42 PM, zero character, zero IST badge)
    await saveScreenshot('frame1_stable_clock.png');

    // 2. Minute-only transition: 6:42 PM -> 6:43 PM (midway writing 43)
    key.currentState?.triggerMinuteChange(
      nextTime: DateTime(2026, 10, 5, 18, 43),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750)); // t ≈ 0.62 (writing in progress)
    await saveScreenshot('frame2_minute_only_transition.png');
    await tester.pump(const Duration(milliseconds: 550)); // settle to 6:43 PM
    await tester.pumpAndSettle();

    // 3. Hour + minute transition: 6:59 PM -> 7:00 PM (both hour and minute animate)
    key.currentState?.setTime(DateTime(2026, 10, 5, 18, 59));
    await tester.pumpAndSettle();
    key.currentState?.triggerMinuteChange(
      nextTime: DateTime(2026, 10, 5, 19, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await saveScreenshot('frame3_hour_minute_transition.png');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    // 4. AM -> PM transition: 11:59 AM -> 12:00 PM (hour, minute, and period all animate)
    key.currentState?.setTime(DateTime(2026, 10, 5, 11, 59));
    await tester.pumpAndSettle();
    key.currentState?.triggerMinuteChange(
      nextTime: DateTime(2026, 10, 5, 12, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await saveScreenshot('frame4_am_to_pm_transition.png');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    // 5. PM -> AM transition: 11:59 PM -> 12:00 AM (hour, minute, and period all animate)
    key.currentState?.setTime(DateTime(2026, 10, 5, 23, 59));
    await tester.pumpAndSettle();
    key.currentState?.triggerMinuteChange(
      nextTime: DateTime(2026, 10, 6, 0, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await saveScreenshot('frame5_pm_to_am_transition.png');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    // 6. 9 -> 10 hour transition: 9:59 AM -> 10:00 AM (single to double digit hour, zero jump)
    key.currentState?.setTime(DateTime(2026, 10, 5, 9, 59));
    await tester.pumpAndSettle();
    key.currentState?.triggerMinuteChange(
      nextTime: DateTime(2026, 10, 5, 10, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await saveScreenshot('frame6_9_to_10_hour_transition.png');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    // 7. 12 -> 1 hour transition: 12:59 PM -> 1:00 PM (double to single digit hour, zero jump)
    key.currentState?.setTime(DateTime(2026, 10, 5, 12, 59));
    await tester.pumpAndSettle();
    key.currentState?.triggerMinuteChange(
      nextTime: DateTime(2026, 10, 5, 13, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await saveScreenshot('frame7_12_to_1_hour_transition.png');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    // 8. Final stable clock (1:00 PM, completely calm and stable)
    await saveScreenshot('frame8_final_stable_clock.png');

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
