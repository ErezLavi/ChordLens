// Note naming follows standard music notation, where pitch classes and
// accidentals are conventionally capitalised.
// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart';

enum Note { C, D, E, F, G, A, B }

enum Accidental { Sharp, Flat, None }

extension AccidentalName on Accidental {
  String get symbol {
    switch (this) {
      case Accidental.Sharp:
        return "♯";
      case Accidental.Flat:
        return "♭";
      case Accidental.None:
        return "";
    }
  }
}

extension NoteAccidentals on Note {
  List<Accidental> get accidentals {
    switch (this) {
      case Note.C:
        return [Accidental.Sharp];
      case Note.D:
        return [Accidental.Flat, Accidental.Sharp];
      case Note.E:
        return [Accidental.Flat];
      case Note.F:
        return [Accidental.Sharp];
      case Note.G:
        return [Accidental.Flat, Accidental.Sharp];
      case Note.A:
        return [Accidental.Flat, Accidental.Sharp];
      case Note.B:
        return [Accidental.Flat];
    }
  }

  Note get previous =>
      (this == Note.C) ? Note.B : Note.values[Note.values.indexOf(this) - 1];

  Note get next =>
      (this == Note.B) ? Note.C : Note.values[Note.values.indexOf(this) + 1];
}

/// A note of the scale, at a given octave, with an optional accidental.
class NotePosition {
  final Note note;
  final int octave;
  final Accidental accidental;

  const NotePosition({
    required this.note,
    this.octave = 4,
    this.accidental = Accidental.None,
  });

  static NotePosition get middleC => NotePosition(note: Note.C, octave: 4);

  ///
  /// Parse a `String` into a `NotePosition`. Accepts strings of two or three
  /// characters, which must include a note name, an optional sharp or flat
  /// symbol, and an octave number.
  ///
  /// Sharp symbols are '#' or '♯'.
  /// Flat symbols are  '♭' or 'b'.
  ///
  /// Example strings:
  /// * F#5
  /// * C3
  /// * B♭4
  static NotePosition? fromName(String string) {
    if (string.length < 2) {
      return null;
    }

    final name = string[0];
    final accidentalSymbol = string.length == 3 ? string[1] : null;
    final octaveString = string.length == 3 ? string[2] : string[1];

    final note = Note.values.firstWhereOrNull((note) => note.name == name);
    final octave = int.tryParse(octaveString);

    if (note == null || octave == null) {
      return null;
    }

    final Accidental accidental;

    if (accidentalSymbol == '#' || accidentalSymbol == '♯') {
      accidental = Accidental.Sharp;
    } else if (accidentalSymbol == '♭' || accidentalSymbol == 'b') {
      accidental = Accidental.Flat;
    } else {
      accidental = Accidental.None;
    }

    return NotePosition(note: note, octave: octave, accidental: accidental);
  }

  NotePosition copyWith({Note? note, int? octave, Accidental? accidental}) =>
      NotePosition(
        note: note ?? this.note,
        octave: octave ?? this.octave,
        accidental: accidental ?? this.accidental,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotePosition &&
          other.runtimeType == runtimeType &&
          other.note == note &&
          other.octave == octave &&
          other.accidental == accidental;

  @override
  int get hashCode => Object.hash(runtimeType, note, octave, accidental);

  @override
  String toString() =>
      'NotePosition(note: $note, octave: $octave, accidental: $accidental)';
}

extension NotePositionHelpers on NotePosition {
  ///
  /// Returns a string identifying this position, composed of a note name,
  /// sharp or flat symbol, and octave number. For example 'F#5'. Use
  /// `NotePosition.fromName` to convert back into a `NotePosition.`
  ///
  String get name => "${note.name}${accidental.symbol}$octave";

  int get pitch {
    int offset;
    switch (note) {
      case Note.C:
        offset = 24; // C1
        break;
      case Note.D:
        offset = 26;
        break;
      case Note.E:
        offset = 28;
        break;
      case Note.F:
        offset = 29;
        break;
      case Note.G:
        offset = 31;
        break;
      case Note.A:
        offset = 33;
        break;
      case Note.B:
        offset = 35;
    }
    if (accidental == Accidental.Flat) {
      offset -= 1;
    } else if (accidental == Accidental.Sharp) {
      offset += 1;
    }
    return offset + ((octave - 1) * 12);
  }

  NotePosition? get alternativeAccidental {
    switch (accidental) {
      case Accidental.None:
        return null;
      case Accidental.Sharp:
        // A flat is always the next note after a sharp, in the same octave
        return NotePosition(
          note: note.next,
          accidental: Accidental.Flat,
          octave: octave,
        );
      case Accidental.Flat:
        // A sharp is always the previous note before a flat, in the same octave
        return NotePosition(
          note: note.previous,
          accidental: Accidental.Sharp,
          octave: octave,
        );
    }
  }

  bool equalsAccidentalInsensitive(NotePosition another) =>
      note == another.note && octave == another.octave;
}
