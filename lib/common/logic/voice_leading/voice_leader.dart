// Candidate generation and the search over it. Layered shortest path
// (Viterbi) offline, greedy live — both scored by one VoiceLeadingCost.

import 'voice_leading_cost.dart';
import 'voice_leading_types.dart';

export 'voice_leading_types.dart';

/// Voices a chord sequence into pitches that move smoothly.
class VoiceLeader {
  const VoiceLeader({
    this.cost = const VoiceLeadingCost(),
    this.range = const VoicingRange(),
    this.maxCandidates = 600,
    this.beamWidth = 64,
  });

  final VoiceLeadingCost cost;
  final VoicingRange range;

  /// Cap on candidates per chord; the ones nearest the target register win.
  final int maxCandidates;

  /// How many nodes of a layer survive into the next. Pruning the tail costs
  /// nothing audible and keeps long progressions fast.
  final int beamWidth;

  /// Solves the whole progression offline.
  ///
  /// Pass [start] to lead out of a voicing that is already sounding.
  VoiceLeadingResult solve(List<ChordSpec> chords, {Voicing? start}) {
    if (chords.isEmpty) {
      return const VoiceLeadingResult(
        voicings: [],
        transitions: [],
        totalCost: 0,
      );
    }

    var layer = <_Node>[];
    for (final chord in chords) {
      final next = <_Node>[];
      for (final candidate in _candidates(chord)) {
        next.add(
          layer.isEmpty
              ? _openingNode(candidate, start)
              : _bestPathInto(candidate, layer),
        );
      }
      next.sort((a, b) => a.cost.compareTo(b.cost));
      layer = next.length > beamWidth ? next.sublist(0, beamWidth) : next;
    }

    final winner = layer.first;
    final voicings = <Voicing>[];
    final transitions = <VoiceTransition>[];
    for (_Node? node = winner; node != null; node = node.parent) {
      voicings.add(node.voicing);
      if (node.transition != null) transitions.add(node.transition!);
    }
    return VoiceLeadingResult(
      voicings: voicings.reversed.toList(),
      transitions: transitions.reversed.toList(),
      totalCost: winner.cost,
    );
  }

  /// Live mode: one chord at a time, no lookahead and no backward pass.
  VoiceLeadingStep next(ChordSpec chord, {Voicing? current}) {
    Voicing? best;
    VoiceTransition? bestTransition;
    var bestCost = double.infinity;

    for (final candidate in _candidates(chord)) {
      final transition = current == null ? null : cost.move(current, candidate);
      final total = (transition?.cost ?? 0) + cost.staticCost(candidate);
      if (total < bestCost) {
        bestCost = total;
        best = candidate;
        bestTransition = transition;
      }
    }
    return VoiceLeadingStep(voicing: best!, transition: bestTransition);
  }

  _Node _openingNode(Voicing candidate, Voicing? start) {
    final transition = start == null ? null : cost.move(start, candidate);
    return _Node(
      voicing: candidate,
      cost: cost.staticCost(candidate) + (transition?.cost ?? 0),
      parent: null,
      transition: transition,
    );
  }

  _Node _bestPathInto(Voicing candidate, List<_Node> layer) {
    late _Node bestParent;
    late VoiceTransition bestTransition;
    var bestCost = double.infinity;

    for (final previous in layer) {
      final transition = cost.move(previous.voicing, candidate);
      final total = previous.cost + transition.cost;
      if (total < bestCost) {
        bestCost = total;
        bestParent = previous;
        bestTransition = transition;
      }
    }
    return _Node(
      voicing: candidate,
      cost: bestCost + cost.staticCost(candidate),
      parent: bestParent,
      transition: bestTransition,
    );
  }

  List<Voicing> _candidates(ChordSpec chord) {
    final all = candidateVoicings(chord, range: range);
    if (all.isEmpty) {
      throw StateError('no playable voicing for $chord in $range');
    }
    if (all.length <= maxCandidates) return all;
    all.sort((a, b) => cost.staticCost(a).compareTo(cost.staticCost(b)));
    return all.sublist(0, maxCandidates);
  }
}

/// Every octave placement of [chord]'s pitch classes that fits [range].
///
/// Non-ascending voicings and ones with excessive gaps between adjacent upper
/// notes are never built rather than built and filtered.
List<Voicing> candidateVoicings(
  ChordSpec chord, {
  VoicingRange range = const VoicingRange(),
  int? voices,
}) {
  final remaining = <int, int>{};
  for (final interval in voicedIntervals(chord, voices ?? chord.voiceCount)) {
    final pc = (chord.root + interval) % 12;
    remaining.update(pc, (n) => n + 1, ifAbsent: () => 1);
  }

  final found = <Voicing>[];
  final placed = <int>[];

  void place() {
    if (found.length >= _enumerationGuard) return;
    if (remaining.isEmpty) {
      found.add(Voicing(List<int>.of(placed)));
      return;
    }

    final int low;
    final int high;
    if (placed.isEmpty) {
      low = range.lowest;
      high = range.highest;
    } else {
      final gap = placed.length == 1 ? range.maxBassGap : range.maxUpperGap;
      low = placed.last + 1;
      high = placed.last + gap < range.highest
          ? placed.last + gap
          : range.highest;
    }

    for (final pc in remaining.keys.toList()) {
      // Lowest pitch of this pitch class at or above `low`.
      for (
        var pitch = low + ((pc - low) % 12 + 12) % 12;
        pitch <= high;
        pitch += 12
      ) {
        final left = remaining[pc]!;
        if (left == 1) {
          remaining.remove(pc);
        } else {
          remaining[pc] = left - 1;
        }
        placed.add(pitch);

        place();

        placed.removeLast();
        remaining.update(pc, (n) => n + 1, ifAbsent: () => 1);
      }
    }
  }

  place();
  return found;
}

/// Which chord tones actually get voiced for a given voice count.
///
/// Doubles the stable tones when notes are needed (root, then fifth, then
/// third) and sheds the expendable ones when they are not (fifth, then root —
/// the 3rd and 7th are what carry the chord's identity). Duplicates in the
/// result mean doubling.
List<int> voicedIntervals(ChordSpec chord, int voices) {
  final tones = List<int>.of(chord.intervals);
  final third = tones.firstWhere((i) => i == 3 || i == 4, orElse: () => -1);
  final seventh = tones.firstWhere((i) => i == 10 || i == 11, orElse: () => -1);
  // Only a perfect fifth is expendable; an altered fifth is a colour tone.
  final fifth = tones.contains(7) ? 7 : -1;

  if (voices >= tones.length) {
    final doublingOrder = [0, if (fifth != -1) fifth, if (third != -1) third];
    for (var i = 0; tones.length < voices; i++) {
      tones.add(doublingOrder[i % doublingOrder.length]);
    }
    return tones..sort();
  }

  final expendable = <int>[
    if (fifth != -1) fifth,
    0,
    // Remaining colour tones, least characteristic (lowest) first.
    ...tones.where((i) => i != 0 && i != third && i != seventh && i != fifth),
    // Last resorts: the tones that define the chord.
    if (seventh != -1) seventh,
    if (third != -1) third,
  ];

  final dropped = <int>{};
  for (final tone in expendable) {
    if (tones.length - dropped.length <= voices) break;
    dropped.add(tone);
  }
  return tones..removeWhere(dropped.contains);
}

/// Backstop against pathological enumeration; unreachable for 3-6 note chords
/// in a normal range.
const int _enumerationGuard = 20000;

class _Node {
  _Node({
    required this.voicing,
    required this.cost,
    required this.parent,
    required this.transition,
  });

  final Voicing voicing;

  /// Cheapest path ending at this node.
  final double cost;
  final _Node? parent;

  /// The move from [parent] into this node.
  final VoiceTransition? transition;
}
