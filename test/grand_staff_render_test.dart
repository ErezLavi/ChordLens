import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_app/domain/music_notation.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/piano/widgets/grand_stuff_viewer_widget.dart';

void main() {
  // A spread of pressed notes covering naturals, sharps and enharmonics.
  final pressed = [
    NotePosition(note: Note.C, octave: 4),
    NotePosition(note: Note.F, octave: 4, accidental: Accidental.Sharp),
    NotePosition(note: Note.C, octave: 5, accidental: Accidental.Sharp),
    NotePosition(note: Note.G, octave: 3),
    NotePosition(note: Note.B, octave: 2),
  ];

  testWidgets('grand staff paints for every key signature without throwing',
      (tester) async {
    for (final sig in Constants.keySignatureReferences) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: GrandStaffViewerWidget(
                pressedNotes: pressed,
                keySignature: sig,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'threw for ${sig.majorKey}');
    }
  });
}
