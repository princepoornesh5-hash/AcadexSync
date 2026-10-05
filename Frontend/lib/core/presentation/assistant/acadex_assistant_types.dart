import 'package:flutter/material.dart';

/// Available animation poses and action states for the canonical ACADEX Assistant.
enum AcadexAssistantPose {
  /// Calm resting pose with subtle natural breathing.
  idle,

  /// Smoothly rises or fades into view.
  appear,

  /// Welcoming nod with warm smile and friendly focus on the user.
  greet,

  /// Right arm raised, smoothly waving hand side-to-side.
  wave,

  /// Head tilted, eyes focused intently toward a target object/card.
  focused,

  /// Arm outstretched reaching toward a target.
  reach,

  /// Right arm extended pointing with index finger.
  point,

  /// Arm and palm sweeping horizontally across a surface to clear/wipe.
  wipe,

  /// Right hand performing focused writing gestures with rhythmic pen-stroke oscillations.
  write,

  /// Signature ACADEX Assistant gesture: hand raised with upward flourish,
  /// radiating a luminous sapphire/cyan magic pulse ring and shimmering stardust starlets!
  magic,

  /// Cheerful satisfied posture with smiling eyes and celebratory nod.
  happy,

  /// Slightly widened eyes and raised brows with subtle surprise.
  surprise,

  /// Smoothly descends and fades out back to resting boundary.
  disappear,
}

/// Facial expressions supported by the canonical ACADEX Assistant.
enum AcadexAssistantExpression {
  /// Neutral, calm, approachable expression.
  defaultExpression,

  /// Gentle warm smile with soft eyes.
  friendly,

  /// Welcoming smile with direct eye contact.
  greeting,

  /// Focused brow and concentrated gaze.
  focused,

  /// Wide cheerful smile with happy crescent eye arcs.
  happy,

  /// Raised eyebrows with slightly wider round eyes.
  slightlySurprised,

  /// Confident, pleased smile with slight wink or happy nod.
  success,

  /// Warm gentle parting smile with soft eyes.
  farewell,
}

/// Particle representation for the signature Magic Gesture sparkle effect.
class AcadexMagicSparkle {
  final double angle;
  final double distance;
  final double size;
  final double opacity;
  final double rotation;
  final Color color;

  const AcadexMagicSparkle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.color,
  });
}
