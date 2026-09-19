import 'package:flutter/services.dart';
import 'package:piano_app/domain/key_signature_reference.dart';
import 'package:piano_app/domain/sound_font_option.dart';

class Constants {
  // sounds
  static const SoundFontOption rhodesSoundFont = SoundFontOption(
    id: 'rhodes',
    name: 'Rhodes',
    assetPath: 'assets/sf2/Rhodes.sf2',
  );
  // static const SoundFontOption yamahaSoundFont = SoundFontOption(
  //   id: 'yamaha',
  //   name: 'Yamaha Piano',
  //   assetPath: 'assets/sf2/yamaha_piano.sf2',
  // );
  static const List<SoundFontOption> soundFonts = [rhodesSoundFont];

  // colors
  static const Color playedNoteColor = Color(0xFF7F0881);
  static const Color highlightedNoteColor = Color(0xFFE97F4A);

  static final Map<LogicalKeyboardKey, int> keyboardKeyOffsets = {
    LogicalKeyboardKey.keyZ: 0,
    LogicalKeyboardKey.keyS: 1,
    LogicalKeyboardKey.keyX: 2,
    LogicalKeyboardKey.keyD: 3,
    LogicalKeyboardKey.keyC: 4,
    LogicalKeyboardKey.keyV: 5,
    LogicalKeyboardKey.keyG: 6,
    LogicalKeyboardKey.keyB: 7,
    LogicalKeyboardKey.keyH: 8,
    LogicalKeyboardKey.keyN: 9,
    LogicalKeyboardKey.keyJ: 10,
    LogicalKeyboardKey.keyM: 11,
    LogicalKeyboardKey.comma: 12,
    LogicalKeyboardKey.keyL: 13,
    LogicalKeyboardKey.period: 14,
    LogicalKeyboardKey.semicolon: 15,
    LogicalKeyboardKey.slash: 16,
  };

  static const sharpNames = [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
  ];

  static const flatNames = [
    "C",
    "Db",
    "D",
    "Eb",
    "E",
    "F",
    "Gb",
    "G",
    "Ab",
    "A",
    "Bb",
    "B",
  ];

  static const List<KeySignatureReference> keySignatureReferences = [
    KeySignatureReference(
      majorKey: "C major",
      minorKey: "A minor",
      accidentalCount: 0,
      usesFlats: false,
      accidentals: [],
    ),
    KeySignatureReference(
      majorKey: "G major",
      minorKey: "E minor",
      accidentalCount: 1,
      usesFlats: false,
      accidentals: ["F#"],
    ),
    KeySignatureReference(
      majorKey: "D major",
      minorKey: "B minor",
      accidentalCount: 2,
      usesFlats: false,
      accidentals: ["F#", "C#"],
    ),
    KeySignatureReference(
      majorKey: "A major",
      minorKey: "F# minor",
      accidentalCount: 3,
      usesFlats: false,
      accidentals: ["F#", "C#", "G#"],
    ),
    KeySignatureReference(
      majorKey: "E major",
      minorKey: "C# minor",
      accidentalCount: 4,
      usesFlats: false,
      accidentals: ["F#", "C#", "G#", "D#"],
    ),
    KeySignatureReference(
      majorKey: "B major",
      minorKey: "G# minor",
      accidentalCount: 5,
      usesFlats: false,
      accidentals: ["F#", "C#", "G#", "D#", "A#"],
    ),
    KeySignatureReference(
      majorKey: "F# major",
      minorKey: "D# minor",
      accidentalCount: 6,
      usesFlats: false,
      accidentals: ["F#", "C#", "G#", "D#", "A#", "E#"],
    ),
    KeySignatureReference(
      majorKey: "C# major",
      minorKey: "A# minor",
      accidentalCount: 7,
      usesFlats: false,
      accidentals: ["F#", "C#", "G#", "D#", "A#", "E#", "B#"],
    ),
    KeySignatureReference(
      majorKey: "F major",
      minorKey: "D minor",
      accidentalCount: 1,
      usesFlats: true,
      accidentals: ["Bb"],
    ),
    KeySignatureReference(
      majorKey: "Bb major",
      minorKey: "G minor",
      accidentalCount: 2,
      usesFlats: true,
      accidentals: ["Bb", "Eb"],
    ),
    KeySignatureReference(
      majorKey: "Eb major",
      minorKey: "C minor",
      accidentalCount: 3,
      usesFlats: true,
      accidentals: ["Bb", "Eb", "Ab"],
    ),
    KeySignatureReference(
      majorKey: "Ab major",
      minorKey: "F minor",
      accidentalCount: 4,
      usesFlats: true,
      accidentals: ["Bb", "Eb", "Ab", "Db"],
    ),
    KeySignatureReference(
      majorKey: "Db major",
      minorKey: "Bb minor",
      accidentalCount: 5,
      usesFlats: true,
      accidentals: ["Bb", "Eb", "Ab", "Db", "Gb"],
    ),
    KeySignatureReference(
      majorKey: "Gb major",
      minorKey: "Eb minor",
      accidentalCount: 6,
      usesFlats: true,
      accidentals: ["Bb", "Eb", "Ab", "Db", "Gb", "Cb"],
    ),
    KeySignatureReference(
      majorKey: "Cb major",
      minorKey: "Ab minor",
      accidentalCount: 7,
      usesFlats: true,
      accidentals: ["Bb", "Eb", "Ab", "Db", "Gb", "Cb", "Fb"],
    ),
  ];

  static String noteName(
    int pc, {
    bool useFlats = false,
    KeySignatureReference? keySignature,
  }) {
    final normalizedPc = pc % 12;
    if (keySignature != null) {
      for (final accidental in keySignature.accidentals) {
        if (_pitchClassForSpelling(accidental) == normalizedPc) {
          return accidental;
        }
      }
      useFlats = keySignature.usesFlats;
    }
    return useFlats ? flatNames[normalizedPc] : sharpNames[normalizedPc];
  }

  static int _pitchClassForSpelling(String spelling) {
    if (spelling.isEmpty) return 0;

    final naturalBase = switch (spelling[0]) {
      'C' => 0,
      'D' => 2,
      'E' => 4,
      'F' => 5,
      'G' => 7,
      'A' => 9,
      'B' => 11,
      _ => 0,
    };

    if (spelling.endsWith('#')) {
      return (naturalBase + 1) % 12;
    }
    if (spelling.endsWith('b')) {
      return (naturalBase + 11) % 12;
    }
    return naturalBase;
  }
}
