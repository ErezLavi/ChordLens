// The cost model for voice leading: what a voicing costs where it sits, and
// what a move between two voicings costs. No `package:flutter` here — the
// algorithm has to be runnable and testable on its own.

import 'voice_leading_types.dart';

export 'voice_leading_types.dart';

/// Scores voicings and the moves between them. Offline and live modes share
/// one instance, so the two can never drift apart.
///
/// All weights are guesses until you hear them.
class VoiceLeadingCost {
  const VoiceLeadingCost({
    this.unmatchedPenalty = 2.0,
    this.bassWeight = 0.3,
    this.registerWeight = 0.30,
    this.targetCenter = 65.0,
    this.mudPenalty = 10.0,
    this.spreadWeight = 1.0,
    this.idealBassGap = 12,
    this.idealUpperGap = 5,
  });

  /// Charged per upper note that has no partner, i.e. per note of size
  /// difference between two voicings.
  final double unmatchedPenalty;

  /// Multiplier on the bass move. Below 1 because bass leaps are idiomatic;
  /// at full weight the optimizer glues the bass in place.
  final double bassWeight;

  /// Cost per semitone *squared* away from [targetCenter]. Quadratic so that
  /// sitting slightly off-centre is nearly free while a slow climb up the
  /// keyboard gets expensive faster than smooth voice leading can pay for it.
  final double registerWeight;

  /// The register the voices above the bass are held in, as a MIDI number
  /// (65 = F4). This is the mean of the *upper* voices, so it sits above the
  /// root a close-position chord is built on, not on it.
  final double targetCenter;

  /// Charged per semitone by which adjacent voices are crowded closer than
  /// they can bear at their register.
  final double mudPenalty;

  /// Charged per semitone by which a gap between adjacent voices exceeds the
  /// ideal. Without it nothing prefers close position: the generator's gap
  /// limits are hard bounds, so every spacing inside them scores the same.
  final double spreadWeight;

  /// Gap above the bass that costs nothing. Wider than [idealUpperGap]
  /// because an open bass is normal, not a defect.
  final int idealBassGap;

  /// Gap between two adjacent upper voices that costs nothing.
  final int idealUpperGap;

  /// What a voicing costs on its own terms, before any movement: where it
  /// sits, and how it is spaced.
  ///
  /// The register pull is what keeps a long progression from drifting upward,
  /// and it is quadratic so that a slow climb gets expensive faster than
  /// smooth voice leading can pay for it.
  double staticCost(Voicing voicing) {
    final drift = voicing.upperCenter - targetCenter;
    return registerWeight * drift * drift +
        mudPenalty * _crowdExcess(voicing) +
        spreadWeight * _spreadExcess(voicing);
  }

  /// Total semitones by which the voicing is spaced wider than ideal.
  int _spreadExcess(Voicing voicing) {
    var excess = 0;
    for (var i = 1; i < voicing.size; i++) {
      final gap = voicing.pitches[i] - voicing.pitches[i - 1];
      final ideal = i == 1 ? idealBassGap : idealUpperGap;
      if (gap > ideal) excess += gap - ideal;
    }
    return excess;
  }

  /// Minimum-cost pairing between two voicings.
  ///
  /// The bass of one chord always becomes the bass of the next — a bass that
  /// gets paired with an inner voice is not voice leading, it is a different
  /// voice. Above the bass, each note of the smaller voicing is paired with a
  /// *distinct* note of the larger one, in order: voices do not cross, and
  /// surplus notes cost [unmatchedPenalty] each.
  ///
  /// Deliberately not nearest-note (chamfer) distance: chamfer allows
  /// many-to-one mappings, so a cluster crowded around the previous chord's
  /// notes scores well while sounding wrong.
  VoiceTransition move(Voicing from, Voicing to) {
    final bass = NoteMove(from: from.bass, to: to.bass);

    final upperFrom = from.pitches.sublist(1);
    final upperTo = to.pitches.sublist(1);
    // Solve the tall case as its transpose — the only place either
    // orientation is considered.
    final flipped = upperFrom.length > upperTo.length;
    final rows = flipped ? upperTo : upperFrom;
    final cols = flipped ? upperFrom : upperTo;

    final alignment = alignInOrder(rows, cols, skipCost: unmatchedPenalty);
    final skipped = [
      for (var j = 0; j < cols.length; j++)
        if (!alignment.pairs.any((p) => p.col == j)) cols[j],
    ];

    return VoiceTransition(
      cost: bassWeight * bass.distance + alignment.cost,
      moves: [
        bass,
        for (final (:row, :col) in alignment.pairs)
          NoteMove(
            from: flipped ? cols[col] : rows[row],
            to: flipped ? rows[row] : cols[col],
          ),
      ],
      dropped: flipped ? skipped : const [],
      added: flipped ? const [] : skipped,
    );
  }

  /// Total semitones by which adjacent voices are crowded tighter than they
  /// can bear. Below middle C that means anything under a minor third — down
  /// there it is mud. Higher up a second is a colour, but a semitone between
  /// adjacent voices still bites.
  int _crowdExcess(Voicing voicing) {
    var excess = 0;
    for (var i = 1; i < voicing.size; i++) {
      final lower = voicing.pitches[i - 1];
      final gap = voicing.pitches[i] - lower;
      final minimum = lower < 60 ? 3 : 2;
      if (gap < minimum) excess += minimum - gap;
    }
    return excess;
  }
}

/// Cheapest order-preserving pairing of every value in [rows] with a distinct
/// value in [cols], where pairs cost the distance between them and each
/// unpaired column costs [skipCost].
///
/// Order-preserving means row `i` pairs with a strictly later column than row
/// `i - 1` — no crossings. Requires `rows.length <= cols.length`.
///
/// Pure: no notion of pitch, bass or chords lives in here.
({List<({int row, int col})> pairs, double cost}) alignInOrder(
  List<int> rows,
  List<int> cols, {
  required double skipCost,
}) {
  assert(rows.length <= cols.length, 'rows must be the shorter side');
  final m = rows.length;
  final n = cols.length;

  // best[i][j] = cheapest pairing of the first i rows inside the first j
  // columns. Either column j-1 is paired with row i-1, or it is skipped.
  final best = [
    for (var i = 0; i <= m; i++) List<double>.filled(n + 1, double.infinity),
  ];
  for (var j = 0; j <= n; j++) {
    best[0][j] = j * skipCost;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = i; j <= n; j++) {
      final paired = best[i - 1][j - 1] + (rows[i - 1] - cols[j - 1]).abs();
      final skipped = best[i][j - 1] + skipCost;
      best[i][j] = paired < skipped ? paired : skipped;
    }
  }

  final pairs = <({int row, int col})>[];
  var i = m;
  var j = n;
  while (i > 0) {
    final paired = best[i - 1][j - 1] + (rows[i - 1] - cols[j - 1]).abs();
    if (paired <= best[i][j - 1] + skipCost) {
      pairs.add((row: i - 1, col: j - 1));
      i--;
    }
    j--;
  }
  return (pairs: pairs.reversed.toList(), cost: best[m][n]);
}
