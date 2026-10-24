import 'package:flutter/widgets.dart';
import 'package:piano_app/domain/music_notation.dart';
import 'package:piano_app/domain/key_signature_reference.dart';

import 'custom_clef_painter.dart';

class CustomClefImage extends StatelessWidget {
  final Clef clef;
  final NoteRange noteRange;
  final NoteRange noteRangeToClip;
  final List<NoteImage> noteImages;
  final Color clefColor;
  final Color noteColor;
  final KeySignatureReference? keySignature;

  const CustomClefImage({
    super.key,
    required this.clef,
    required this.noteRange,
    required this.noteImages,
    required this.clefColor,
    required this.noteColor,
    NoteRange? noteRangeToClip,
    this.keySignature,
  }) : noteRangeToClip = noteRangeToClip ?? noteRange;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: CustomPaint(
          painter: CustomClefPainter(
            clef: clef,
            clefColor: clefColor,
            noteColor: noteColor,
            noteRange: noteRange,
            noteRangeToClip: noteRangeToClip,
            lineHeight: 1,
            noteImages: noteImages,
            keySignature: keySignature,
          ),
        ),
      );
}
