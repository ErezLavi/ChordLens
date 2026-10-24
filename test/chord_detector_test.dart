import 'package:flutter_test/flutter_test.dart';
import 'package:piano_app/domain/music_notation.dart';
import 'package:piano_app/common/logic/chord_detector.dart';
import 'package:piano_app/common/logic/music_db.dart';

NotePosition n(
  Note note,
  int octave, [
  Accidental accidental = Accidental.None,
]) {
  return NotePosition(
    note: note,
    octave: octave,
    accidental: accidental,
  );
}

void main() {
  group('ChordDetector – Basic Triads & 7ths', () {
    test('detects C major triad', () {
      final chord = ChordDetector.detect({n(Note.C, 4), n(Note.E, 4), n(Note.G, 4)});
      expect(chord!.name, 'C');
    });

    test('detects C minor triad', () {
      final chord = ChordDetector.detect({n(Note.C, 4), n(Note.E, 4, Accidental.Flat), n(Note.G, 4)});
      expect(chord!.name, 'Cm');
    });

    test('detects Cmaj7 (Full Voicing)', () {
      final chord = ChordDetector.detect({n(Note.C, 4), n(Note.E, 4), n(Note.G, 4), n(Note.B, 4)});
      expect(chord!.name, 'Cmaj7');
    });

    test('detects Cmaj7 (Shell Voicing - No 5th)', () {
      // Musicians often omit the 5th; the detector should still catch this.
      final chord = ChordDetector.detect({n(Note.C, 4), n(Note.E, 4), n(Note.B, 4)});
      expect(chord!.name, 'Cmaj7');
    });
  });

  group('ChordDetector – The "Crunch" Cases (Clusters)', () {
    test('detects C(addb6) – The C-E-G-G# case', () {
      final chord = ChordDetector.detect({
        n(Note.C, 4), 
        n(Note.E, 4), 
        n(Note.G, 4), 
        n(Note.G, 4, Accidental.Sharp)
      });
      // This confirms the 'addb6' template beats the simple 'C' triad 
      // even though 'C' is a higher rank.
      expect(chord!.name, 'Caddb6'); 
    });

    test('detects C(add#11) – The Lydian C-E-F#-G case', () {
      final chord = ChordDetector.detect({
        n(Note.C, 4), 
        n(Note.E, 4), 
        n(Note.F, 4, Accidental.Sharp), 
        n(Note.G, 4)
      });
      expect(chord!.name, 'Cadd#11');
    });
  });

  group('ChordDetector – Modern Extensions', () {
    test('detects Cadd9 (previously "passing tone" test)', () {
      final chord = ChordDetector.detect({
        n(Note.C, 4), 
        n(Note.D, 4), // The 9th
        n(Note.E, 4), 
        n(Note.G, 4)
      });
      // In a piano app, the user wants to see the color they are playing!
      expect(chord!.name, 'Cadd9');
    });

    test('detects C6/9 (Rich Voicing)', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3), 
        n(Note.E, 4), 
        n(Note.A, 4), // 6th
        n(Note.D, 5)  // 9th
      });
      // Ensure your chordDB/Rank can handle multiple extensions.
      expect(chord!.name, 'C6/9'); 
    });
  });

  group('ChordDetector – Slash Chords & Inversions', () {
    test('detects C Major 1st Inversion (C/E)', () {
      final chord = ChordDetector.detect({n(Note.E, 4), n(Note.G, 4), n(Note.C, 5)});
      expect(chord!.name, 'C/E');
    });

    test('detects C-E-G-Ab as Caddb6 when C is bass', () {
  final chord = ChordDetector.detect({
    n(Note.C, 3), // Bass
    n(Note.E, 4), 
    n(Note.G, 4), 
    n(Note.A, 4, Accidental.Flat) 
  });
  
  expect(chord!.name, 'Caddb6');
  });
});

  group('ChordDetector – Suspensions', () {
    test('detects Csus2', () {
      final chord = ChordDetector.detect({n(Note.C, 4), n(Note.D, 4), n(Note.G, 4)});
      expect(chord!.name, 'Csus2');
    });

    test('detects C9sus4', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.F, 4),
        n(Note.G, 4),
        n(Note.B, 4, Accidental.Flat),
        n(Note.D, 5),
      });
      expect(chord!.name, 'C9sus4');
    });

    test('detects C13sus4', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.F, 4),
        n(Note.G, 4),
        n(Note.B, 4, Accidental.Flat),
        n(Note.D, 5),
        n(Note.A, 5),
      });
      expect(chord!.name, 'C13sus4');
    });

    test('a played third rules out every sus chord', () {
      // C-D-E-G has both the 2nd and the 3rd: it is add9, never sus2.
      final chord = ChordDetector.detect({
        n(Note.C, 4),
        n(Note.D, 4),
        n(Note.E, 4),
        n(Note.G, 4),
      });
      expect(chord!.name, 'Cadd9');
    });
  });

  group('ChordDetector – Lydian & Major Extensions', () {
    test('detects Cmaj7#11', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.E, 4),
        n(Note.G, 4),
        n(Note.B, 4),
        n(Note.F, 5, Accidental.Sharp),
      });
      expect(chord!.name, 'Cmaj7#11');
    });

    test('detects Cmaj9#11', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.E, 4),
        n(Note.G, 4),
        n(Note.B, 4),
        n(Note.D, 5),
        n(Note.F, 5, Accidental.Sharp),
      });
      expect(chord!.name, 'Cmaj9#11');
    });

    test('detects Cmaj11', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.E, 4),
        n(Note.G, 4),
        n(Note.B, 4),
        n(Note.D, 5),
        n(Note.F, 5),
      });
      expect(chord!.name, 'Cmaj11');
    });

    test('detects C9#11', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.E, 4),
        n(Note.G, 4),
        n(Note.B, 4, Accidental.Flat),
        n(Note.D, 5),
        n(Note.F, 5, Accidental.Sharp),
      });
      expect(chord!.name, 'C9#11');
    });

    test('Cadd#11 still beats Cmaj7#11 when the 7th is absent', () {
      final chord = ChordDetector.detect({
        n(Note.C, 4),
        n(Note.E, 4),
        n(Note.F, 4, Accidental.Sharp),
        n(Note.G, 4),
      });
      expect(chord!.name, 'Cadd#11');
    });
  });

  group('ChordDetector – Minor & Diminished Colors', () {
    test('detects Cm6/9', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.E, 4, Accidental.Flat),
        n(Note.G, 4),
        n(Note.A, 4),
        n(Note.D, 5),
      });
      expect(chord!.name, 'Cm6/9');
    });

    test('detects Cm(maj9)', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.E, 4, Accidental.Flat),
        n(Note.G, 4),
        n(Note.B, 4),
        n(Note.D, 5),
      });
      expect(chord!.name, 'Cm(maj9)');
    });

    test('detects CdimMaj7', () {
      final chord = ChordDetector.detect({
        n(Note.C, 4),
        n(Note.E, 4, Accidental.Flat),
        n(Note.G, 4, Accidental.Flat),
        n(Note.B, 4),
      });
      expect(chord!.name, 'CdimMaj7');
    });

    test('detects Cm7#5', () {
      final chord = ChordDetector.detect({
        n(Note.C, 4),
        n(Note.E, 4, Accidental.Flat),
        n(Note.G, 4, Accidental.Sharp),
        n(Note.B, 4, Accidental.Flat),
      });
      expect(chord!.name, 'Cm7#5');
    });
  });

  group('ChordDetector – Stacked Alterations', () {
    test('detects C7b9b13', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.E, 4),
        n(Note.G, 4),
        n(Note.B, 4, Accidental.Flat),
        n(Note.D, 5, Accidental.Flat),
        n(Note.A, 5, Accidental.Flat),
      });
      expect(chord!.name, 'C7b9b13');
    });

    test('detects C7#9b13', () {
      final chord = ChordDetector.detect({
        n(Note.C, 3),
        n(Note.E, 4),
        n(Note.G, 4),
        n(Note.B, 4, Accidental.Flat),
        n(Note.D, 5, Accidental.Sharp),
        n(Note.A, 5, Accidental.Flat),
      });
      expect(chord!.name, 'C7#9b13');
    });
  });

  group('MusicDb – vocabulary consistency', () {
    test('every ranked chord type exists in chordDB', () {
      final unknown = MusicDb.chordRank.keys
          .where((type) => !MusicDb.chordDB.containsKey(type))
          .toList();
      expect(unknown, isEmpty,
          reason: 'ranked but undefined, so unreachable everywhere');
    });

    test('every chord type in chordDB is ranked', () {
      final unranked = MusicDb.chordDB.keys
          .where((type) => !MusicDb.chordRank.containsKey(type))
          .toList();
      expect(unranked, isEmpty,
          reason: 'unranked types sort last by accident rather than by intent');
    });

    test('required and forbidden intervals only name known chord types', () {
      expect(
        MusicDb.chordRequiredIntervals.keys
            .where((type) => !MusicDb.chordDB.containsKey(type)),
        isEmpty,
      );
      expect(
        MusicDb.chordForbiddenIntervals.keys
            .where((type) => !MusicDb.chordDB.containsKey(type)),
        isEmpty,
      );
    });

    test('required intervals are part of their own template', () {
      for (final entry in MusicDb.chordRequiredIntervals.entries) {
        expect(
          MusicDb.chordDB[entry.key]!.containsAll(entry.value),
          isTrue,
          reason: '${entry.key} requires an interval it does not contain',
        );
      }
    });

    test('forbidden intervals are absent from their own template', () {
      for (final entry in MusicDb.chordForbiddenIntervals.entries) {
        expect(
          MusicDb.chordDB[entry.key]!.intersection(entry.value),
          isEmpty,
          reason: '${entry.key} forbids an interval it contains',
        );
      }
    });

    test('no two chord types share the same interval set', () {
      // add2 and add9 are the same pitch classes and differ only in where the
      // 2nd sits in the voicing, so the detector can never tell them apart —
      // it always reports the better-ranked add9. Any *other* collision is a
      // mistake: the loser is unreachable.
      const voicingOnlyPairs = {'add2,add9'};

      final byIntervals = <String, List<String>>{};
      for (final entry in MusicDb.chordDB.entries) {
        final key = (entry.value.toList()..sort()).join(',');
        byIntervals.putIfAbsent(key, () => []).add(entry.key);
      }
      final duplicates = byIntervals.values
          .where((types) => types.length > 1)
          .map((types) => (types..sort()).join(','))
          .where((pair) => !voicingOnlyPairs.contains(pair))
          .toList();
      expect(duplicates, isEmpty, reason: 'duplicate templates never both win');
    });
  });
}