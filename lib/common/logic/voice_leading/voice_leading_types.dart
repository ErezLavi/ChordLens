// The value types the voice leader takes in and hands back: what counts as a
// playable voicing, and what a solved progression or a single live step is.

import 'voice_leading_cost.dart';

/// Bounds on what counts as a playable, sane-sounding voicing.
class VoicingRange {
  const VoicingRange({
    this.lowest = 40,
    this.highest = 84,
    this.maxUpperGap = 12,
    this.maxBassGap = 19,
  });

  /// Lowest allowed pitch (MIDI). 40 = E2.
  final int lowest;

  /// Highest allowed pitch (MIDI). 84 = C6.
  final int highest;

  /// Largest gap tolerated between two adjacent upper notes.
  final int maxUpperGap;

  /// Largest gap tolerated between the bass and the note above it. Wider than
  /// [maxUpperGap] because an open bass is normal, not a defect.
  final int maxBassGap;
}

/// A solved progression.
class VoiceLeadingResult {
  const VoiceLeadingResult({
    required this.voicings,
    required this.transitions,
    required this.totalCost,
  });

  /// One voicing per input chord.
  final List<Voicing> voicings;

  /// Moves between consecutive voicings — `voicings.length - 1` of them, or
  /// one more when a starting voicing was supplied to lead out of.
  final List<VoiceTransition> transitions;

  final double totalCost;

  @override
  String toString() => 'VoiceLeadingResult($voicings)';
}

/// One step of live mode.
class VoiceLeadingStep {
  const VoiceLeadingStep({required this.voicing, required this.transition});

  final Voicing voicing;

  /// Null when there was no previous voicing to move from.
  final VoiceTransition? transition;
}
