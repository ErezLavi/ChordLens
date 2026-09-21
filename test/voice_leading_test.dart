import 'package:flutter_test/flutter_test.dart';
import 'package:piano/piano.dart';
import 'package:piano_app/common/logic/voice_leading/voice_leader.dart';
import 'package:piano_app/common/piano_utils.dart';
import 'package:piano_app/common/logic/voice_leading/voice_leading_cost.dart';

ChordSpec chord(int root, List<int> intervals, {int? voices}) =>
    ChordSpec(root: root, intervals: intervals, voices: voices);

const majorTriad = [0, 4, 7];
const minorTriad = [0, 3, 7];
const minorSeventh = [0, 3, 7, 10];
const dominantSeventh = [0, 4, 7, 10];
const majorSeventh = [0, 4, 7, 11];
const thirteenth = [0, 2, 4, 7, 9, 10];

void main() {
  const cost = VoiceLeadingCost();

  group('cost model', () {
    test('rejects a cluster crowded around the previous chord', () {
      final from = Voicing([60, 64, 67]); // C4 E4 G4

      final open = Voicing([53, 57, 60, 64]); // F3 A3 C4 E4
      final cluster = Voicing([64, 65, 69, 72]); // E4 F4 A4 C5

      double total(Voicing v) => cost.move(from, v).cost + cost.staticCost(v);

      expect(total(open), lessThan(total(cluster)));
    });

    test('pairs bass with bass and never crosses voices', () {
      final transition = cost.move(
        Voicing([48, 64, 67]),
        Voicing([55, 59, 62, 65]),
      );

      expect(transition.moves.first.from, 48);
      expect(transition.moves.first.to, 55);

      final froms = transition.moves.map((m) => m.from).toList();
      final tos = transition.moves.map((m) => m.to).toList();
      expect(froms, orderedEquals(List.of(froms)..sort()));
      expect(tos, orderedEquals(List.of(tos)..sort()));
    });

    test('charges the size difference once per surplus note', () {
      final same = cost.move(Voicing([60, 64, 67]), Voicing([60, 64, 67]));
      final grown = cost.move(Voicing([60, 64, 67]), Voicing([60, 64, 67, 71]));

      expect(same.cost, 0);
      expect(same.added, isEmpty);
      expect(grown.added, [71]);
      expect(grown.cost, cost.unmatchedPenalty);
    });

    test('reports dropped notes when the next chord is smaller', () {
      final shrunk = cost.move(
        Voicing([60, 64, 67, 71]),
        Voicing([60, 64, 67]),
      );

      expect(shrunk.dropped, [71]);
      expect(shrunk.added, isEmpty);
    });
  });

  group('alignInOrder', () {
    test('keeps order rather than taking the nearest partner', () {
      // 20 is nearest to 21, so a crossing-free pairing has to leave 15 out
      // rather than pairing 10 with it.
      final result = alignInOrder([10, 20], [9, 15, 21], skipCost: 2);

      expect(result.pairs, [(row: 0, col: 0), (row: 1, col: 2)]);
      expect(result.cost, 1 + 1 + 2);
    });

    test('skips every column when there are no rows', () {
      expect(alignInOrder([], [1, 2, 3], skipCost: 2).cost, 6);
    });
  });

  group('candidate voicings', () {
    test('doubles the root first when more voices are wanted', () {
      expect(voicedIntervals(chord(0, majorTriad), 4), [0, 0, 4, 7]);
      expect(voicedIntervals(chord(0, majorTriad), 5), [0, 0, 4, 7, 7]);
    });

    test('sheds the fifth first, then the root, keeping 3rd and 7th', () {
      expect(voicedIntervals(chord(0, dominantSeventh), 3), [0, 4, 10]);
      expect(voicedIntervals(chord(0, dominantSeventh), 2), [4, 10]);
    });

    test('only builds ascending voicings inside the range', () {
      final range = const VoicingRange(lowest: 48, highest: 72);
      final candidates = candidateVoicings(chord(0, majorTriad), range: range);

      expect(candidates, isNotEmpty);
      for (final voicing in candidates) {
        expect(voicing.size, 3);
        expect(voicing.bass, greaterThanOrEqualTo(48));
        expect(voicing.top, lessThanOrEqualTo(72));
        expect(
          voicing.pitches,
          orderedEquals(List.of(voicing.pitches)..sort()),
        );
        expect(voicing.pitches.map((p) => p % 12).toSet(), {0, 4, 7});
      }
    });
  });

  group('solver', () {
    const leader = VoiceLeader();

    test('ii-V-I holds common tones and barely moves the upper voices', () {
      final result = leader.solve([
        chord(2, minorSeventh), // Dm7
        chord(7, dominantSeventh), // G7
        chord(0, majorSeventh), // Cmaj7
      ]);

      expect(result.voicings, hasLength(3));
      for (final transition in result.transitions) {
        expect(
          transition.maxUpperMotion,
          lessThanOrEqualTo(2),
          reason: 'upper voices should step, not leap: ${result.voicings}',
        );
      }
    });

    test('voices a lone triad in close position, not fanned out', () {
      final result = leader.solve([chord(0, majorTriad)]);
      final voicing = result.voicings.single;

      expect(
        voicing.top - voicing.bass,
        lessThanOrEqualTo(12),
        reason: 'a triad should fit in an octave: ${voicing.pitches}',
      );
    });

    test('keeps every voicing of a progression inside two octaves', () {
      final result = leader.solve([
        chord(0, majorTriad),
        chord(9, minorTriad),
        chord(5, majorTriad),
        chord(7, majorTriad),
      ]);

      for (final voicing in result.voicings) {
        expect(
          voicing.top - voicing.bass,
          lessThanOrEqualTo(17),
          reason: 'voicing is fanned out: ${voicing.pitches}',
        );
      }
    });

    test('does not drift over twelve chromatic chords', () {
      final chords = [for (var i = 0; i < 12; i++) chord(i, majorTriad)];
      final result = leader.solve(chords);

      final first = result.voicings.first.upperCenter;
      final last = result.voicings.last.upperCenter;
      expect(
        (last - first).abs(),
        lessThan(4),
        reason: 'register should hold, not climb: ${result.voicings}',
      );
    });

    test('triad to 13th and back makes no octave-sized jump', () {
      final result = leader.solve([
        chord(0, majorTriad),
        chord(5, thirteenth),
        chord(0, majorTriad),
      ]);

      final centers = result.voicings.map((v) => v.upperCenter).toList();
      expect((centers[1] - centers[0]).abs(), lessThan(12));
      expect((centers[2] - centers[1]).abs(), lessThan(12));
    });

    test('leads out of a voicing that is already sounding', () {
      final start = Voicing([60, 64, 67]);
      final result = leader.solve([chord(5, majorSeventh)], start: start);

      expect(result.voicings, hasLength(1));
      expect(result.transitions, hasLength(1));
      expect(result.transitions.first.moves.first.from, 60);
    });

    test('live mode scores with the same numbers as the solver', () {
      final start = Voicing([60, 64, 67]);
      final g7 = chord(7, dominantSeventh);

      final step = leader.next(g7, current: start);
      final offline = leader.solve([g7], start: start);

      expect(step.voicing, offline.voicings.single);
    });
  });

  group("the app's chord vocabulary", () {
    test('ChordSpec reads chord types straight out of MusicDb', () {
      expect(ChordSpec.fromType(5, 'maj7')!.intervals, [0, 4, 7, 11]);
      expect(ChordSpec.fromType(0, 'm7')!.intervals, [0, 3, 7, 10]);
      expect(ChordSpec.fromType(0, 'not a chord'), isNull);
    });

    test('voicings round-trip through NotePosition', () {
      const keyboard = PianoUtils();
      final voicing = Voicing([53, 57, 60, 64]);
      final notes = keyboard.notesOf(voicing);

      expect(notes.map((n) => n.name), ['F3', 'A3', 'C4', 'E4']);
      expect(keyboard.voicingOf(notes), voicing);
    });
  });
}
