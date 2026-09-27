import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/assignment_models.dart';

String getMarkEmoji(int marks, int maximumMarks) {
  if (maximumMarks <= 0) return '🙂';
  final ratio = marks / maximumMarks;
  if (ratio >= 1.0) return '🏆';
  if (ratio >= 0.9) return '⭐';
  if (ratio >= 0.8) return '🔥';
  if (ratio >= 0.6) return '👍';
  if (ratio >= 0.4) return '🙂';
  return '😕';
}

class MarksSliderRow extends StatefulWidget {
  final StudentAssignmentActivityModel student;
  final int maximumMarks;
  final int? currentMark;
  final ValueChanged<int> onMarkChanged;

  const MarksSliderRow({
    super.key,
    required this.student,
    required this.maximumMarks,
    required this.currentMark,
    required this.onMarkChanged,
  });

  @override
  State<MarksSliderRow> createState() => _MarksSliderRowState();
}

class _MarksSliderRowState extends State<MarksSliderRow>
    with SingleTickerProviderStateMixin {
  late double _currentValue;
  bool _isDragging = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentValue = (widget.currentMark ?? 0).toDouble().clamp(0.0, widget.maximumMarks.toDouble());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(covariant MarksSliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMark != oldWidget.currentMark && !_isDragging) {
      setState(() {
        _currentValue = (widget.currentMark ?? 0).toDouble().clamp(0.0, widget.maximumMarks.toDouble());
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onChanged(double val) {
    final intVal = val.round();
    setState(() {
      _currentValue = intVal.toDouble();
    });
    widget.onMarkChanged(intVal);
  }

  void _setFullMarks() {
    final full = widget.maximumMarks;
    setState(() {
      _currentValue = full.toDouble();
    });
    widget.onMarkChanged(full);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int currentInt = _currentValue.round();
    final hasMark = widget.currentMark != null || widget.student.marks != null;
    final isReviewed = widget.student.reviewStatus == FacultyReviewStatus.reviewed || hasMark;
    final maxMarks = widget.maximumMarks > 0 ? widget.maximumMarks : 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isReviewed
              ? (isDark ? AcadexColors.primaryDark.withOpacity(0.3) : AcadexColors.primaryLight)
              : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
          width: isReviewed ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Single Header line: Name, review state badge, and Full Marks action
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.student.studentName,
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.student.rollNumber != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${widget.student.rollNumber})',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isReviewed
                            ? const Color(0xFFDCFCE7)
                            : (isDark ? AcadexColors.darkCanvasSoft : AcadexColors.canvasSoft),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isReviewed ? '✓ Reviewed' : '✓ Done',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isReviewed ? const Color(0xFF15803D) : AcadexColors.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Compact shortcut [ Full Marks ]
              InkWell(
                onTap: _setFullMarks,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkCanvasSoft : AcadexColors.primaryTint,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AcadexColors.primary.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'Full Marks',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AcadexColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Slider & floating mark bubble area
          LayoutBuilder(
            builder: (context, constraints) {
              final sliderWidth = constraints.maxWidth - 70; // reserving space for right label
              final thumbFraction = maxMarks > 0 ? (_currentValue / maxMarks).clamp(0.0, 1.0) : 0.0;
              final bubbleLeft = (thumbFraction * (sliderWidth - 28)).clamp(0.0, sliderWidth - 28);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Row: Slider (left) + Score Text (right)
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            activeTrackColor: AcadexColors.primary,
                            inactiveTrackColor: isDark ? AcadexColors.darkHairline : const Color(0xFFE2E8F0),
                            thumbColor: AcadexColors.primary,
                            overlayColor: AcadexColors.primary.withOpacity(0.12),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1.5),
                            activeTickMarkColor: Colors.white70,
                            inactiveTickMarkColor: isDark ? Colors.white10 : Colors.black12,
                          ),
                          child: Slider(
                            value: _currentValue,
                            min: 0,
                            max: maxMarks.toDouble(),
                            divisions: maxMarks,
                            onChangeStart: (_) {
                              setState(() {
                                _isDragging = true;
                              });
                              _animController.forward();
                            },
                            onChanged: _onChanged,
                            onChangeEnd: (_) {
                              _animController.reverse().then((_) {
                                if (mounted) {
                                  setState(() {
                                    _isDragging = false;
                                  });
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Current Mark text (compact)
                      SizedBox(
                        width: 55,
                        child: Text(
                          '$currentInt / $maxMarks',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Floating Playful Mark Bubble (visible ONLY during drag)
                  if (_isDragging)
                    Positioned(
                      left: bubbleLeft,
                      top: -38,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        alignment: Alignment.bottomCenter,
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$currentInt / $maxMarks',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      getMarkEmoji(currentInt, maxMarks),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Downward pointing arrow
                              CustomPaint(
                                size: const Size(8, 4),
                                painter: _TrianglePainter(color: const Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}
