import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_app/domain/music_notation.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/custom_piano/custom_interactive_piano.dart';
import 'package:piano_app/domain/key_signature_reference.dart';

void main() {
  final oneOctave = NoteRange(
    from: NotePosition(note: Note.C, octave: 4),
    to: NotePosition(note: Note.B, octave: 4),
  );

  KeySignatureReference keyOf(String major) => Constants.keySignatureReferences
      .firstWhere((s) => s.majorKey == major);

  Widget pianoIn(KeySignatureReference key) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: CustomInteractivePiano(
              noteRange: oneOctave,
              keyWidth: 60,
              keySignature: key,
            ),
          ),
        ),
      );

  testWidgets(
      'black keys are labelled sharp in a sharp key, flat in a flat key',
      (tester) async {
    await tester.pumpWidget(pianoIn(keyOf('D major'))); // sharp key
    expect(find.textContaining('C♯'), findsWidgets);
    expect(find.textContaining('D♭'), findsNothing);

    await tester.pumpWidget(pianoIn(keyOf('F major'))); // flat key
    expect(find.textContaining('D♭'), findsWidgets);
    expect(find.textContaining('C♯'), findsNothing);
  });
}
