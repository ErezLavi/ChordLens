import 'package:flutter_test/flutter_test.dart';
import 'package:piano_app/domain/music_notation.dart';
import 'package:piano_app/common/logic/chord_detector.dart';

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
}