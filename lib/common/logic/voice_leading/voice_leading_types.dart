// The value types of voice leading: the chords going in, the voicings and
// moves coming out, and the bounds they have to stay inside. No scoring and no
// search here — those live in voice_leading_cost.dart and voice_leader.dart.

import 'package:piano_app/common/logic/music_db.dart';

/// A chord with no octaves attached: a root pitch class plus the intervals
/// above it. Turning this into pitches is the candidate generator's job.
class ChordSpec {
  ChordSpec({required int root, required Iterable<int> intervals, this.voices})
    : root = root % 12,
      intervals = List.unmodifiable(intervals.toSet().toList()..sort()) {
    assert(
      this.intervals.isNotEmpty && this.intervals.first == 0,
      'intervals must include the root (0)',
    );
  }

  /// Builds a spec from a chord type in [MusicDb.chordDB], or null if the
  /// database does not know that type.
  ///
  /// The database stores the intervals above the root without the root
  /// itself, so it gets added back here.
  static ChordSpec? fromType(int rootPc, String chordType, {int? voices}) {
    final intervals = MusicDb.chordDB[chordType];
    if (intervals == null) return null;
    return ChordSpec(
      root: rootPc,
      intervals: {0, ...intervals},
      voices: voices,
    );
  }

  /// Root pitch class, 0-11 (0 = C).
  final int root;

  /// Semitones above the root, ascending, starting at 0.
  final List<int> intervals;

  /// How many notes to voice. Defaults to the number of chord tones.
  final int? voices;

  int get voiceCount => voices ?? intervals.length;

  @override
  String toString() => 'ChordSpec(root: $root, intervals: $intervals)';
}

/// A concrete voicing: MIDI pitches, strictly ascending.
class Voicing {
  Voicing(Iterable<int> pitches)
    : pitches = List.unmodifiable(pitches.toList()) {
    assert(this.pitches.isNotEmpty, 'a voicing needs at least one note');
    assert(_isAscending(this.pitches), 'pitches must be strictly ascending');
  }

  final List<int> pitches;

  int get size => pitches.length;
  int get bass => pitches.first;
  int get top => pitches.last;

  /// Mean pitch of the whole voicing.
  double get center => pitches.reduce((a, b) => a + b) / pitches.length;

  /// Mean pitch above the bass — the voicing's real register.
  ///
  /// The bass is excluded because it is free to leap by an octave whenever
  /// that is convenient, which is enough to hide an upper-voice climb inside
  /// an unchanged [center].
  double get upperCenter => size == 1
      ? bass.toDouble()
      : pitches.skip(1).reduce((a, b) => a + b) / (size - 1);

  static bool _isAscending(List<int> p) {
    for (var i = 1; i < p.length; i++) {
      if (p[i] <= p[i - 1]) return false;
    }
    return true;
  }

  @override
  String toString() => 'Voicing($pitches)';

  @override
  bool operator ==(Object other) =>
      other is Voicing &&
      other.pitches.length == pitches.length &&
      Object.hashAll(other.pitches) == Object.hashAll(pitches);

  @override
  int get hashCode => Object.hashAll(pitches);
}

/// One voice moving between two voicings. This is what a UI animates.
class NoteMove {
  const NoteMove({required this.from, required this.to});

  final int from;
  final int to;

  /// Signed motion in semitones; negative is downward.
  int get interval => to - from;
  int get distance => interval.abs();

  @override
  String toString() => 'NoteMove($from -> $to)';
}

/// The score for one chord-to-chord move, plus the pairing that produced it.
class VoiceTransition {
  const VoiceTransition({
    required this.cost,
    required this.moves,
    required this.dropped,
    required this.added,
  });

  final double cost;

  /// The winning pairing, bass first and ascending. Voices never cross, so
  /// this list is ordered consistently on both sides.
  final List<NoteMove> moves;

  /// Notes of the previous voicing left without a partner (it was larger).
  final List<int> dropped;

  /// Notes of the next voicing left without a partner (it was larger).
  final List<int> added;

  /// Largest single-voice motion, in semitones.
  int get maxMotion =>
      moves.fold(0, (m, move) => move.distance > m ? move.distance : m);

  /// Motion of the upper voices only — the bass is expected to leap.
  int get maxUpperMotion =>
      moves.skip(1).fold(0, (m, move) => move.distance > m ? move.distance : m);

  @override
  String toString() => 'VoiceTransition(${cost.toStringAsFixed(2)}, $moves)';
}

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
