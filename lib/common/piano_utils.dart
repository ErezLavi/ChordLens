import 'package:piano/piano.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/common/logic/voice_leading/voice_leading_cost.dart';
import 'package:piano_app/domain/key_signature_reference.dart';
import 'package:piano_app/common/logic/music_db.dart';

class PianoUtils {
  const PianoUtils();

  /// Re-spells [source] according to [keySignature] (or the [useFlats] fallback
  /// when no signature is given), keeping the exact same pitch.
  ///
  /// This is the single source of truth for how a played pitch is named on the
  /// keyboard and the staff: it delegates the letter/accidental choice to
  /// [Constants.noteName] and then rebuilds a [NotePosition] whose octave is
  /// derived from that spelling — so enharmonics that cross an octave boundary
  /// (e.g. Cb, B#) land on the correct line.
  NotePosition spellNotePosition(
    NotePosition source, {
    KeySignatureReference? keySignature,
    bool useFlats = false,
  }) {
    final name = Constants.noteName(
      source.pitch % 12,
      useFlats: useFlats,
      keySignature: keySignature,
    );

    final letter = _noteForLetter(name[0]);
    final accidental = name.length > 1
        ? (name[1] == '#' ? Accidental.Sharp : Accidental.Flat)
        : Accidental.None;
    final accidentalOffset = switch (accidental) {
      Accidental.Sharp => 1,
      Accidental.Flat => -1,
      _ => 0,
    };
    // Solve for the octave that keeps the pitch identical, using the same
    // formula as `NotePosition.pitch`: pitch = noteOffset + accidental +
    // (octave - 1) * 12. This keeps octave-crossing enharmonics (Cb, B#) on
    // the correct line.
    final octave =
        (source.pitch - _noteOffset(letter) - accidentalOffset) ~/ 12 + 1;

    return NotePosition(note: letter, octave: octave, accidental: accidental);
  }

  Note _noteForLetter(String letter) => switch (letter) {
    'C' => Note.C,
    'D' => Note.D,
    'E' => Note.E,
    'F' => Note.F,
    'G' => Note.G,
    'A' => Note.A,
    'B' => Note.B,
    _ => Note.C,
  };

  /// Mirrors the per-note offsets used by `NotePosition.pitch` in the `piano`
  /// package (C1 == 24).
  int _noteOffset(Note note) => switch (note) {
    Note.C => 24,
    Note.D => 26,
    Note.E => 28,
    Note.F => 29,
    Note.G => 31,
    Note.A => 33,
    Note.B => 35,
  };

  NotePosition noteFromOffset(int semitone) {
    final octave = semitone ~/ 12;
    switch (semitone % 12) {
      case 0:
        return NotePosition(note: Note.C, octave: octave);
      case 1:
        return NotePosition(
          note: Note.C,
          octave: octave,
          accidental: Accidental.Sharp,
        );
      case 2:
        return NotePosition(note: Note.D, octave: octave);
      case 3:
        return NotePosition(
          note: Note.D,
          octave: octave,
          accidental: Accidental.Sharp,
        );
      case 4:
        return NotePosition(note: Note.E, octave: octave);
      case 5:
        return NotePosition(note: Note.F, octave: octave);
      case 6:
        return NotePosition(
          note: Note.F,
          octave: octave,
          accidental: Accidental.Sharp,
        );
      case 7:
        return NotePosition(note: Note.G, octave: octave);
      case 8:
        return NotePosition(
          note: Note.G,
          octave: octave,
          accidental: Accidental.Sharp,
        );
      case 9:
        return NotePosition(note: Note.A, octave: octave);
      case 10:
        return NotePosition(
          note: Note.A,
          octave: octave,
          accidental: Accidental.Sharp,
        );
      case 11:
      default:
        return NotePosition(note: Note.B, octave: octave);
    }
  }

  /// Reads a [Voicing] off the keyboard. Returns null if nothing is sounding.
  Voicing? voicingOf(Iterable<NotePosition> notes) {
    final pitches = notes.map((n) => n.pitch).toSet().toList()..sort();
    return pitches.isEmpty ? null : Voicing(pitches);
  }

  /// Turns a solved [Voicing] back into keyboard positions.
  ///
  /// Note the octave shift: [noteFromOffset] counts from C0 = 0, while
  /// [NotePositionHelpers.pitch] is true MIDI (C4 = 60).
  List<NotePosition> notesOf(Voicing voicing) =>
      voicing.pitches.map((midi) => noteFromOffset(midi - 12)).toList();

  List<NotePosition> buildChordNotesForOctave({
    required int rootPc,
    required String chordType,
    required int octave,
    required int inversion,
    required NoteRange noteRange,
  }) {
    final intervals = MusicDb.chordDB[chordType];
    if (intervals == null) return [];

    final rootPitch = octave * 12 + rootPc;
    final orderedIntervals = _normalizeChordIntervals(chordType, intervals);
    final invertedIntervals = MusicDb.applyChordInversion(
      orderedIntervals,
      inversion,
    );
    final selectedNotes = <NotePosition>[];
    final usedPitches = <int>{};

    for (final interval in invertedIntervals) {
      final pitch = rootPitch + interval;
      if (!usedPitches.add(pitch)) continue;
      final note = noteFromOffset(pitch);
      if (noteRange.contains(note)) {
        selectedNotes.add(note);
      }
    }

    return selectedNotes;
  }

  List<NotePosition> buildScaleNotesForOctave({
    required int rootPc,
    required String scaleType,
    required int octave,
    required NoteRange noteRange,
  }) {
    final intervals = MusicDb.scaleDB[scaleType];
    if (intervals == null) return [];

    final rootPitch = octave * 12 + rootPc;
    final orderedIntervals = intervals.toList()..sort();
    final selectedNotes = <NotePosition>[];
    final usedPitches = <int>{};

    for (final interval in orderedIntervals) {
      final pitch = rootPitch + interval;
      if (!usedPitches.add(pitch)) continue;
      final note = noteFromOffset(pitch);
      if (noteRange.contains(note)) {
        selectedNotes.add(note);
      }
    }

    return selectedNotes;
  }

  List<int> _normalizeChordIntervals(String chordType, Set<int> intervals) {
    final extensionIntervals = <int>{};

    if (chordType.contains('9')) {
      extensionIntervals.add(2);
    }
    if (chordType.contains('11')) {
      extensionIntervals.addAll([2, 5]);
    }
    if (chordType.contains('13')) {
      extensionIntervals.addAll([2, 5, 9]);
    }
    if (chordType.contains('b9')) extensionIntervals.add(1);
    if (chordType.contains('#9')) extensionIntervals.add(3);
    if (chordType.contains('#11')) extensionIntervals.add(6);
    if (chordType.contains('b13')) extensionIntervals.add(8);

    final normalized = <int>{0, ...intervals}.map((interval) {
      if (interval != 0 && extensionIntervals.contains(interval)) {
        return interval + 12;
      }
      return interval;
    }).toList()..sort();

    return normalized;
  }
}
