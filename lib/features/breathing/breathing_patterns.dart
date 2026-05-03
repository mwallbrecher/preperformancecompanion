import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';

/// The four possible breathing actions. Painters read this to decide how to
/// animate the orb / dot / shape during a phase.
enum BreathingAction { inhale, hold, exhale, holdEmpty }

class BreathingPhase {
  final String label;          // shown to user: "Inhale", "Hold", "Exhale"
  final Duration duration;
  final BreathingAction action;

  const BreathingPhase({
    required this.label,
    required this.duration,
    required this.action,
  });
}

/// Unique identifier per technique, used for routing.
enum BreathingPatternId { pursedLip, fourSevenEight, box }

class BreathingPattern {
  final BreathingPatternId id;
  final String title;          // "Calm the Panic"
  final String techniqueName;  // "Pursed-Lip Breathing"
  final String tagline;        // "For acute panic"
  final String rhythmLabel;    // "2s in · 4s out"
  final List<BreathingPhase> phases;
  final Color primaryColor;    // dominant orb colour
  final Color accentColor;     // accent / secondary phase colour

  const BreathingPattern({
    required this.id,
    required this.title,
    required this.techniqueName,
    required this.tagline,
    required this.rhythmLabel,
    required this.phases,
    required this.primaryColor,
    required this.accentColor,
  });

  Duration get cycleDuration {
    var sum = Duration.zero;
    for (final p in phases) {
      sum += p.duration;
    }
    return sum;
  }
}

// ── Pattern definitions ─────────────────────────────────────────────────────

/// Pursed-Lip Breathing — for acute panic.
/// Fast inhale, slow exhale to lengthen CO2 exchange and settle the nervous system.
const pursedLipPattern = BreathingPattern(
  id: BreathingPatternId.pursedLip,
  title: 'Calm the Panic',
  techniqueName: 'Pursed-Lip Breathing',
  tagline: 'For acute panic',
  rhythmLabel: '2s in · 4s out',
  primaryColor: Color(0xFFB9DCC8), // soft mint
  accentColor: Color(0xFFF5D0B0),  // warm peach
  phases: [
    BreathingPhase(
      label: 'Breathe in',
      duration: Duration(seconds: 2),
      action: BreathingAction.inhale,
    ),
    BreathingPhase(
      label: 'Exhale slowly',
      duration: Duration(seconds: 4),
      action: BreathingAction.exhale,
    ),
  ],
);

/// 4-7-8 Breathing — for stress regulation.
/// Classic parasympathetic activation: 4 in, 7 hold, 8 out.
const fourSevenEightPattern = BreathingPattern(
  id: BreathingPatternId.fourSevenEight,
  title: 'Regulate Stress',
  techniqueName: '4-7-8 Breathing',
  tagline: 'For stress regulation',
  rhythmLabel: '4s in · 7s hold · 8s out',
  primaryColor: AppColors.blobPurple,
  accentColor: AppColors.accent,
  phases: [
    BreathingPhase(
      label: 'Breathe in',
      duration: Duration(seconds: 4),
      action: BreathingAction.inhale,
    ),
    BreathingPhase(
      label: 'Hold',
      duration: Duration(seconds: 7),
      action: BreathingAction.hold,
    ),
    BreathingPhase(
      label: 'Exhale',
      duration: Duration(seconds: 8),
      action: BreathingAction.exhale,
    ),
  ],
);

/// Box Breathing — for intrusive thoughts.
/// Equal four-sided rhythm gives the mind a concrete geometry to follow.
const boxPattern = BreathingPattern(
  id: BreathingPatternId.box,
  title: 'Quiet the Mind',
  techniqueName: 'Box Breathing',
  tagline: 'For intrusive thoughts',
  rhythmLabel: '4s on each side',
  primaryColor: Color(0xFF9FC9B5), // sage green
  accentColor: Color(0xFF6FA890),  // deeper sage
  phases: [
    BreathingPhase(
      label: 'Breathe in',
      duration: Duration(seconds: 4),
      action: BreathingAction.inhale,
    ),
    BreathingPhase(
      label: 'Hold',
      duration: Duration(seconds: 4),
      action: BreathingAction.hold,
    ),
    BreathingPhase(
      label: 'Exhale',
      duration: Duration(seconds: 4),
      action: BreathingAction.exhale,
    ),
    BreathingPhase(
      label: 'Hold',
      duration: Duration(seconds: 4),
      action: BreathingAction.holdEmpty,
    ),
  ],
);

const breathingPatterns = <BreathingPattern>[
  pursedLipPattern,
  fourSevenEightPattern,
  boxPattern,
];

BreathingPattern breathingPatternById(BreathingPatternId id) =>
    breathingPatterns.firstWhere((p) => p.id == id);
