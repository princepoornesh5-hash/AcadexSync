import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'acadex_minute_writing.dart';

/// Modern mechanical scoreboard display for 12-hour h:mm AM/PM India Standard Time.
///
/// Features:
/// - Mechanical split-flap aesthetics with physical horizontal flap seam
/// - Tabular monospace figures (Inter font with tabularFigures feature)
/// - 12-hour format with no leading zero on hours (e.g. 6:43 PM, 12:00 AM)
/// - Synchronized wipe-away and progressive write-in transitions
/// - Smart component animation:
///   - Minute updates every minute
///   - Hour only animates on hour changes (e.g. 6:59 PM -> 7:00 PM)
///   - AM/PM only animates on noon/midnight transitions (11:59 AM -> 12:00 PM)
/// - Compact responsive sizing for mobile and desktop hero headers
/// - Full accessibility semantics ("Current time 6:43 PM India Standard Time")
class AcadexScoreboardCard extends StatelessWidget {
  final String hours;
  final String minutes;
  final String period; // 'AM' or 'PM'
  final String? oldHours;
  final String? oldMinutes;
  final String? oldPeriod;
  final double wipeProgress; // 0.0 (fully visible) to 1.0 (wiped away)
  final double writeProgress; // 0.0 (not written) to 1.0 (fully written)
  final bool isWiping;
  final bool isWriting;
  final bool isCompact;
  final GlobalKey? minuteKey;

  const AcadexScoreboardCard({
    super.key,
    required this.hours,
    required this.minutes,
    this.period = 'AM',
    this.oldHours,
    this.oldMinutes,
    this.oldPeriod,
    this.wipeProgress = 0.0,
    this.writeProgress = 1.0,
    this.isWiping = false,
    this.isWriting = false,
    this.isCompact = false,
    this.minuteKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dimensions
    final cardW = isCompact ? 28.0 : 34.0;
    final cardH = isCompact ? 32.0 : 38.0;
    final periodW = isCompact ? 26.0 : 30.0;
    final fontSize = isCompact ? 15.0 : 18.0;
    final periodFontSize = isCompact ? 10.5 : 12.0;
    final colonW = isCompact ? 8.0 : 10.0;

    final bool hourChanged = oldHours != null && oldHours != hours;
    final bool periodChanged = oldPeriod != null && oldPeriod != period;

    return Semantics(
      label: 'Current time $hours:$minutes $period India Standard Time',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6.0 : 8.0,
          vertical: isCompact ? 4.0 : 5.0,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFF475569),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hours Card [ h ] (1..12, no leading zero)
            _buildHourCard(
              hours: hours,
              oldHours: oldHours,
              width: cardW,
              height: cardH,
              fontSize: fontSize,
              isWiping: isWiping && hourChanged,
              isWriting: isWriting && hourChanged,
              wipeProgress: wipeProgress,
              writeProgress: writeProgress,
            ),

            // Scoreboard Mechanical Colon [ : ]
            SizedBox(
              width: colonW,
              height: cardH,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildColonDot(isCompact),
                  SizedBox(height: isCompact ? 4 : 5),
                  _buildColonDot(isCompact),
                ],
              ),
            ),

            // Minutes Card [ mm ] (00..59)
            Container(
              key: minuteKey,
              child: _buildMinuteCard(
                digits: minutes,
                oldDigits: oldMinutes,
                width: cardW,
                height: cardH,
                fontSize: fontSize,
                isWiping: isWiping,
                isWriting: isWriting,
                wipeProgress: wipeProgress,
                writeProgress: writeProgress,
              ),
            ),

            SizedBox(width: isCompact ? 3 : 5),

            // AM / PM Indicator Card
            _buildPeriodCard(
              currentPeriod: period,
              oldPeriod: oldPeriod,
              width: periodW,
              height: cardH,
              fontSize: periodFontSize,
              isWiping: isWiping && periodChanged,
              isWriting: isWriting && periodChanged,
              wipeProgress: wipeProgress,
              writeProgress: writeProgress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColonDot(bool isCompact) {
    final dotSize = isCompact ? 3.0 : 3.5;
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: const BoxDecoration(
        color: Color(0xFF60A5FA),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3B82F6),
            blurRadius: 3,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }

  Widget _buildHourCard({
    required String hours,
    required String? oldHours,
    required double width,
    required double height,
    required double fontSize,
    required bool isWiping,
    required bool isWriting,
    required double wipeProgress,
    required double writeProgress,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF283548),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visual Handwriting & Wipe Layer (CustomPainter)
          if (isWiping || isWriting)
            CustomPaint(
              size: Size(width, height),
              painter: HourWritingPainter(
                currentHours: hours,
                oldHours: oldHours,
                isWiping: isWiping,
                isWriting: isWriting,
                wipeProgress: wipeProgress,
                writeProgress: writeProgress,
                fontSize: fontSize,
                isCompact: isCompact,
              ),
            ),

          // Hidden test/semantics node during animation; full visible text when calm
          if (isWiping && oldHours != null)
            Opacity(
              opacity: 0.0,
              child: _buildDigitText(oldHours, fontSize),
            )
          else if (isWriting)
            Opacity(
              opacity: 0.0,
              child: _buildDigitText(hours, fontSize),
            )
          else if (oldHours != null && wipeProgress == 0.0 && writeProgress == 0.0)
            _buildDigitText(oldHours, fontSize)
          else
            _buildDigitText(hours, fontSize),

          // Mechanical Split-Flap Center Seam
          Positioned(
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 1, color: Colors.black54),
                Container(height: 0.6, color: const Color(0xFF334155)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinuteCard({
    required String digits,
    required String? oldDigits,
    required double width,
    required double height,
    required double fontSize,
    required bool isWiping,
    required bool isWriting,
    required double wipeProgress,
    required double writeProgress,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF283548),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visual Handwriting & Wipe Layer (CustomPainter)
          if (isWiping || isWriting)
            CustomPaint(
              size: Size(width, height),
              painter: MinuteWritingPainter(
                currentMinutes: digits,
                oldMinutes: oldDigits,
                isWiping: isWiping,
                isWriting: isWriting,
                wipeProgress: wipeProgress,
                writeProgress: writeProgress,
                fontSize: fontSize,
                isCompact: isCompact,
              ),
            ),

          // Hidden test/semantics node during animation; full visible text when calm
          if (isWiping && oldDigits != null)
            Opacity(
              opacity: 0.0,
              child: _buildDigitText(oldDigits, fontSize),
            )
          else if (isWriting)
            Opacity(
              opacity: 0.0,
              child: _buildDigitText(digits, fontSize),
            )
          else if (oldDigits != null && wipeProgress == 0.0 && writeProgress == 0.0)
            _buildDigitText(oldDigits, fontSize)
          else
            _buildDigitText(digits, fontSize),

          // Mechanical Split-Flap Center Seam
          Positioned(
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 1, color: Colors.black54),
                Container(height: 0.6, color: const Color(0xFF334155)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard({
    required String currentPeriod,
    required String? oldPeriod,
    required double width,
    required double height,
    required double fontSize,
    required bool isWiping,
    required bool isWriting,
    required double wipeProgress,
    required double writeProgress,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF283548),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visual Wipe & Reveal Layer (CustomPainter)
          if (isWiping || isWriting)
            CustomPaint(
              size: Size(width, height),
              painter: PeriodWritingPainter(
                currentPeriod: currentPeriod,
                oldPeriod: oldPeriod,
                isWiping: isWiping,
                isWriting: isWriting,
                wipeProgress: wipeProgress,
                writeProgress: writeProgress,
                fontSize: fontSize,
                isCompact: isCompact,
              ),
            ),

          // Hidden test/semantics node during animation; full visible text when calm
          if (isWiping && oldPeriod != null)
            Opacity(
              opacity: 0.0,
              child: _buildPeriodText(oldPeriod, fontSize),
            )
          else if (isWriting)
            Opacity(
              opacity: 0.0,
              child: _buildPeriodText(currentPeriod, fontSize),
            )
          else if (oldPeriod != null && wipeProgress == 0.0 && writeProgress == 0.0)
            _buildPeriodText(oldPeriod, fontSize)
          else
            _buildPeriodText(currentPeriod, fontSize),

          // Split-Flap Center Seam
          Positioned(
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 1, color: Colors.black54),
                Container(height: 0.6, color: const Color(0xFF334155)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitText(String text, double fontSize) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Inter',
        fontFeatures: const [ui.FontFeature.tabularFigures()],
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFF8FAFC),
        letterSpacing: -0.3,
        height: 1.0,
      ),
    );
  }

  Widget _buildPeriodText(String text, double fontSize) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF93C5FD),
        letterSpacing: 0.2,
        height: 1.0,
      ),
    );
  }
}
