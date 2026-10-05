import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../widgets/acadex_button.dart';
import '../widgets/acadex_card.dart';
import '../time_board/acadex_live_time_board.dart';
import 'acadex_assistant.dart';
import 'acadex_assistant_controller.dart';
import 'acadex_assistant_types.dart';

/// Interactive development showcase and verification screen for the canonical
/// ACADEX Assistant character foundation.
///
/// Allows real-time interactive testing of:
/// - Poses & multi-step choreographed sequences (Wave, Greet, Magic, Wipe, Write, Appear, Disappear)
/// - Facial expressions & eye gaze tracking
/// - Responsive scaling (Compact 80dp, Dashboard 140dp, Showcase 220dp, Hero 300dp)
/// - Light & Dark canvas rendering
/// - Accessibility reduced motion simulation
class AcadexAssistantShowcaseScreen extends StatefulWidget {
  const AcadexAssistantShowcaseScreen({super.key});

  @override
  State<AcadexAssistantShowcaseScreen> createState() =>
      _AcadexAssistantShowcaseScreenState();
}

class _AcadexAssistantShowcaseScreenState
    extends State<AcadexAssistantShowcaseScreen> {
  late final AcadexAssistantController _controller;
  final GlobalKey<AcadexLiveTimeBoardState> _timeBoardKey = GlobalKey();
  double _characterSize = 220.0;
  bool _darkCanvas = false;
  bool _simulateReducedMotion = false;
  bool _enableShadow = true;
  String _statusMessage = 'Assistant ready. Tap any action or drag to direct gaze.';

  @override
  void initState() {
    super.initState();
    _controller = AcadexAssistantController(
      initialPose: AcadexAssistantPose.idle,
      initialExpression: AcadexAssistantExpression.friendly,
    );
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSystemDark = theme.brightness == Brightness.dark;
    final canvasColor = _darkCanvas
        ? const Color(0xFF0F172A)
        : (isSystemDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: isSystemDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        title: const Text('ACADEX Assistant Studio'),
        backgroundColor: isSystemDark ? AcadexColors.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Toggle Stage Theme',
            icon: Icon(_darkCanvas ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _darkCanvas = !_darkCanvas),
          ),
          IconButton(
            tooltip: 'Reset to Idle',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.resetToIdle();
              setState(() => _statusMessage = 'Reset to calm idle pose.');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            AcadexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CANONICAL 3D IDENTITY',
                          style: AcadexTypography.caption(
                            color: AcadexColors.primary,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Pose: ${_controller.pose.name}',
                        style: AcadexTypography.caption(
                          color: isSystemDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ACADEX Academic Mentor & Campus Assistant',
                    style: AcadexTypography.heading2(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusMessage,
                    style: AcadexTypography.body(
                      color: isSystemDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Interactive Character Stage
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: canvasColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSystemDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    // Interactive Touch / Gaze Area
                    GestureDetector(
                      onPanUpdate: (details) {
                        final size = _characterSize;
                        final local = details.localPosition;
                        final dx = ((local.dx - (size / 2)) / (size / 2)).clamp(-1.0, 1.0);
                        final dy = ((local.dy - (size / 2)) / (size / 2)).clamp(-1.0, 1.0);
                        _controller.lookAt(Offset(dx, dy));
                        setState(() {
                          _statusMessage = 'Tracking gaze to: (${dx.toStringAsFixed(2)}, ${dy.toStringAsFixed(2)})';
                        });
                      },
                      onPanEnd: (_) {
                        _controller.lookAt(Offset.zero);
                      },
                      child: Container(
                        width: _characterSize,
                        height: _characterSize,
                        alignment: Alignment.center,
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            disableAnimations: _simulateReducedMotion,
                          ),
                          child: AcadexAssistant(
                            size: _characterSize,
                            controller: _controller,
                            enableShadow: _enableShadow,
                            onTap: () {
                              _controller.playGreeting(
                                onComplete: () {
                                  setState(() => _statusMessage = 'Greeting finished.');
                                },
                              );
                              setState(() => _statusMessage = 'Playing greeting animation...');
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Drag on character to direct gaze • Tap character to greet',
                      style: AcadexTypography.caption(
                        color: _darkCanvas
                            ? const Color(0xFF94A3B8)
                            : (isSystemDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Live IST Time Board + Minute Transition Test Bench
            AcadexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'LIVE IST TIME BOARD & MINUTE TRANSITION',
                          style: AcadexTypography.heading3(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '24-HOUR IST',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AcadexColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mechanical scoreboard displays live IST. Tap the clock or action buttons below to test the full underground emergence, greeting, wipe, write, magic flourish, and descent sequence.',
                    style: AcadexTypography.caption(
                      color: isSystemDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSystemDark ? const Color(0xFF161E2E) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSystemDark ? const Color(0xFF283548) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: AcadexLiveTimeBoard(
                        key: _timeBoardKey,
                        userName: 'Poornesh',
                        onMinuteSequenceFinished: () {
                          if (mounted) {
                            setState(() => _statusMessage = 'Minute change sequence completed.');
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AcadexButton(
                        label: '⏱️ Trigger Minute Transition',
                        size: AcadexButtonSize.sm,
                        onPressed: () {
                          setState(() => _statusMessage = 'Triggered choreographed minute change animation.');
                          _timeBoardKey.currentState?.triggerMinuteChange();
                        },
                      ),
                      AcadexButton(
                        label: '🌙 Test 11:59 PM ➔ 12:00 AM',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          setState(() => _statusMessage = 'Testing midnight roll-over transition.');
                          _timeBoardKey.currentState?.triggerMinuteChange(
                            nextTime: DateTime(2026, 10, 6, 0, 0),
                          );
                        },
                      ),
                      AcadexButton(
                        label: '☀️ Test 11:59 AM ➔ 12:00 PM',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          setState(() => _statusMessage = 'Testing noon transition (AM -> PM).');
                          _timeBoardKey.currentState?.triggerMinuteChange(
                            nextTime: DateTime(2026, 10, 5, 12, 0),
                          );
                        },
                      ),
                      AcadexButton(
                        label: '⏳ Test 12:59 PM ➔ 1:00 PM',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          setState(() => _statusMessage = 'Testing hour roll-over transition (12 PM -> 1 PM).');
                          _timeBoardKey.currentState?.triggerMinuteChange(
                            nextTime: DateTime(2026, 10, 5, 13, 0),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Choreographed Animations & Gestures
            AcadexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHOREOGRAPHED ACTIONS', style: AcadexTypography.heading3()),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      AcadexButton(
                        label: '👋 Greeting',
                        size: AcadexButtonSize.sm,
                        onPressed: () {
                          setState(() => _statusMessage = 'Playing greeting gesture...');
                          _controller.playGreeting(onComplete: () {
                            if (mounted) setState(() => _statusMessage = 'Greeting complete.');
                          });
                        },
                      ),
                      AcadexButton(
                        label: '🙋 Wave Hand',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          setState(() => _statusMessage = 'Waving hand...');
                          _controller.playWave(onComplete: () {
                            if (mounted) setState(() => _statusMessage = 'Wave complete.');
                          });
                        },
                      ),
                      AcadexButton(
                        label: '✨ Magic Gesture',
                        size: AcadexButtonSize.sm,
                        onPressed: () {
                          setState(() => _statusMessage = 'Casting signature magic sparkle gesture...');
                          _controller.playMagicGesture(
                            onSparklePeak: () {
                              if (mounted) setState(() => _statusMessage = '✨ Magic flourish peak reached!');
                            },
                            onComplete: () {
                              if (mounted) setState(() => _statusMessage = 'Magic gesture complete.');
                            },
                          );
                        },
                      ),
                      AcadexButton(
                        label: '🧹 Wipe / Erase',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          setState(() => _statusMessage = 'Sweeping horizontal wipe...');
                          _controller.playWipe(onComplete: () {
                            if (mounted) setState(() => _statusMessage = 'Wipe complete.');
                          });
                        },
                      ),
                      AcadexButton(
                        label: '✍️ Write',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          setState(() => _statusMessage = 'Writing with stylus...');
                          _controller.playWrite(onComplete: () {
                            if (mounted) setState(() => _statusMessage = 'Writing complete.');
                          });
                        },
                      ),
                      AcadexButton(
                        label: '👉 Point',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.soft,
                        onPressed: () {
                          _controller.setPose(AcadexAssistantPose.point);
                          setState(() => _statusMessage = 'Pointing forward.');
                        },
                      ),
                      AcadexButton(
                        label: '🌟 Appear',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.soft,
                        onPressed: () {
                          setState(() => _statusMessage = 'Emerging into view...');
                          _controller.playAppear(onComplete: () {
                            if (mounted) setState(() => _statusMessage = 'Appeared.');
                          });
                        },
                      ),
                      AcadexButton(
                        label: '💨 Disappear',
                        size: AcadexButtonSize.sm,
                        variant: AcadexButtonVariant.soft,
                        onPressed: () {
                          setState(() => _statusMessage = 'Descending and fading out...');
                          _controller.playDisappear(onComplete: () {
                            if (mounted) setState(() => _statusMessage = 'Disappeared.');
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Expressions Selector
            AcadexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FACIAL EXPRESSIONS', style: AcadexTypography.heading3()),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AcadexAssistantExpression.values.map((expr) {
                      final isSelected = _controller.expression == expr;
                      return ChoiceChip(
                        label: Text(expr.name),
                        selected: isSelected,
                        selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                        onSelected: (selected) {
                          if (selected) {
                            _controller.setExpression(expr);
                            setState(() => _statusMessage = 'Expression changed to: ${expr.name}');
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Responsive Scaling & Options
            AcadexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SIZE PRESETS & ACCESSIBILITY', style: AcadexTypography.heading3()),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Compact (80dp)'),
                        avatar: const Icon(Icons.photo_size_select_small, size: 16),
                        onPressed: () => setState(() => _characterSize = 80.0),
                      ),
                      ActionChip(
                        label: const Text('Dashboard (140dp)'),
                        avatar: const Icon(Icons.dashboard, size: 16),
                        onPressed: () => setState(() => _characterSize = 140.0),
                      ),
                      ActionChip(
                        label: const Text('Showcase (220dp)'),
                        avatar: const Icon(Icons.aspect_ratio, size: 16),
                        onPressed: () => setState(() => _characterSize = 220.0),
                      ),
                      ActionChip(
                        label: const Text('Hero (300dp)'),
                        avatar: const Icon(Icons.fullscreen, size: 16),
                        onPressed: () => setState(() => _characterSize = 300.0),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Simulate Reduced Motion'),
                      subtitle: const Text('Renders static canonical posture for accessibility compliance'),
                      value: _simulateReducedMotion,
                      onChanged: (val) => setState(() => _simulateReducedMotion = val),
                    ),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dynamic Floor Shadow'),
                      subtitle: const Text('Ambient ground contact shadow with breathing scale'),
                      value: _enableShadow,
                      onChanged: (val) => setState(() => _enableShadow = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
