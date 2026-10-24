// ignore_for_file: must_be_immutable

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:piano_app/domain/music_notation.dart';
import 'package:piano_app/common/piano_utils.dart';
import 'package:piano_app/domain/key_signature_reference.dart';

/// A single note to be drawn on a staff, at a horizontal [offset] expressed as
/// a fraction of the available width.
class NoteImage {
  final NotePosition notePosition;
  final double offset;
  final Color? color;

  NoteImage({required this.notePosition, this.offset = 0.5, this.color});
}

class CustomClefPainter extends CustomPainter with EquatableMixin {
  final Clef clef;

  /// The note range we'll make space for in this drawing.
  final NoteRange noteRange;

  /// The note range we'll actually draw notes for.
  final NoteRange? noteRangeToClip;
  final List<NoteImage> noteImages;
  final EdgeInsets padding;
  final int lineHeight;
  final Color clefColor;
  final Color noteColor;
  final KeySignatureReference? keySignature;

  /// Satisfies `EquatableMixin` and used in shouldRepaint for redraw efficiency
  @override
  List<Object?> get props => [
        clef,
        noteRange,
        noteRangeToClip,
        noteImages,
        padding,
        lineHeight,
        clefColor,
        noteColor,
        keySignature,
      ];

  final Paint _linePaint;
  final Paint _notePaint;
  final Paint _tailPaint;

  TextPainter? _clefSymbolPainter;
  Size? _lastClefSize;
  final List<NotePosition> _naturalPositions;

  CustomClefPainter({
    required this.clef,
    required this.noteRange,
    this.noteRangeToClip,
    this.noteImages = const [],
    this.padding = const EdgeInsets.all(16),
    this.clefColor = Colors.black,
    this.noteColor = Colors.black,
    this.lineHeight = 1,
    this.keySignature,
  })  : _naturalPositions = noteRange.naturalPositions,
        _linePaint = Paint()
          ..color = clefColor
          ..strokeWidth = lineHeight.toDouble(),
        _notePaint = Paint(),
        _tailPaint = Paint()..strokeWidth = lineHeight.toDouble();

  String _accidentalGlyph(Accidental accidental) {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!isAndroid) {
      return accidental.symbol;
    }
    switch (accidental) {
      case Accidental.Flat:
        return 'b';
      case Accidental.Sharp:
        return '#';
      default:
        return accidental.symbol;
    }
  }

  // Canonical staff octave for each accidental letter in a key signature, per
  // clef. These are the traditional engraving positions (the "zig-zag").
  static const Map<Note, int> _trebleSharpOctave = {
    Note.F: 5, Note.C: 5, Note.G: 5, Note.D: 5, Note.A: 4, Note.E: 5, Note.B: 4,
  };
  static const Map<Note, int> _trebleFlatOctave = {
    Note.B: 4, Note.E: 5, Note.A: 4, Note.D: 5, Note.G: 4, Note.C: 5, Note.F: 4,
  };
  static const Map<Note, int> _bassSharpOctave = {
    Note.F: 3, Note.C: 3, Note.G: 3, Note.D: 3, Note.A: 2, Note.E: 3, Note.B: 2,
  };
  static const Map<Note, int> _bassFlatOctave = {
    Note.B: 2, Note.E: 3, Note.A: 2, Note.D: 3, Note.G: 2, Note.C: 3, Note.F: 2,
  };

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

  (Note, Accidental) _parseAccidental(String spelling) {
    final note = _noteForLetter(spelling[0]);
    final accidental = spelling.endsWith('#')
        ? Accidental.Sharp
        : spelling.endsWith('b')
            ? Accidental.Flat
            : Accidental.None;
    return (note, accidental);
  }

  /// The ordered accidentals to draw as the key signature, each with the staff
  /// position it belongs on for this clef. Empty for C major / no signature or
  /// an unsupported clef.
  List<(NotePosition, Accidental)> _keySignatureGlyphs() {
    final sig = keySignature;
    if (sig == null || sig.accidentals.isEmpty) return const [];
    if (clef != Clef.Treble && clef != Clef.Bass) return const [];

    final sharp = !sig.usesFlats;
    final octaves = clef == Clef.Bass
        ? (sharp ? _bassSharpOctave : _bassFlatOctave)
        : (sharp ? _trebleSharpOctave : _trebleFlatOctave);

    final glyphs = <(NotePosition, Accidental)>[];
    for (final spelling in sig.accidentals) {
      final (note, accidental) = _parseAccidental(spelling);
      final octave = octaves[note];
      if (octave == null) continue;
      glyphs.add((NotePosition(note: note, octave: octave), accidental));
    }
    return glyphs;
  }

  /// Which accidental the key signature applies to each note letter.
  Map<Note, Accidental> _keySignatureByLetter() {
    final sig = keySignature;
    final map = <Note, Accidental>{};
    if (sig == null) return map;
    for (final spelling in sig.accidentals) {
      final (note, accidental) = _parseAccidental(spelling);
      map[note] = accidental;
    }
    return map;
  }

  TextPainter _glyphPainter(String glyph, double fontSize, Color color) =>
      TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(fontSize: fontSize, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = padding.deflateRect(Offset.zero & size);

    if (bounds.height <= 0) {
      return;
    }

    // Clip by pitch rather than NoteRange.contains: the latter only recognises
    // naturals/sharps and can't match enharmonic spellings like Fb or Cb, which
    // would otherwise be dropped even though they're on the staff.
    int diatonicOrder(Note note) => switch (note) {
      Note.C => 0,
      Note.D => 1,
      Note.E => 2,
      Note.F => 3,
      Note.G => 4,
      Note.A => 5,
      Note.B => 6,
    };

    const offStaff = -1000; // sentinel; a real row index (incl. -1) is valid
    naturalPositionOf(NotePosition notePosition) {
      final clip = noteRangeToClip;
      if (clip != null &&
          (notePosition.pitch < clip.firstPosition.pitch ||
              notePosition.pitch > clip.lastPosition.pitch)) {
        return offStaff;
      }
      // Index by diatonic step from the lowest natural, so enharmonic spellings
      // that fall just outside the natural list (e.g. B# below middle C) still
      // resolve to a staff row instead of vanishing.
      final first = _naturalPositions.first;
      return (notePosition.octave - first.octave) * 7 +
          diatonicOrder(notePosition.note) -
          diatonicOrder(first.note);
    }

    final clefSize = Size(80, bounds.height);

    final noteHeight = bounds.height / _naturalPositions.length.toDouble();

    final firstLineIndex =
        _naturalPositions.indexOf(clef.firstLineNotePosition);
    final lastLineIndex = _naturalPositions.indexOf(clef.lastLineNotePosition);

    final firstLineIsEven = firstLineIndex % 2 == 0;

    final ovalHeight = noteHeight * 2;
    final ovalWidth = ovalHeight * 1.5;

    // Key signature dimensions are needed up front so ledger lines and notes
    // share the same horizontal origin (everything shifts right of the glyphs).
    final keySignatureGlyphs = _keySignatureGlyphs();
    final keySignatureByLetter = _keySignatureByLetter();
    final keySignatureGlyphSpacing = ovalWidth * 0.55;
    final keySignatureWidth = keySignatureGlyphs.isEmpty
        ? 0.0
        : keySignatureGlyphs.length * keySignatureGlyphSpacing + ovalWidth * 0.4;

    double? firstLineY, lastLineY;

    for (var line = firstLineIsEven ? 0 : 1;
        line < _naturalPositions.length;
        line += 2) {
      NoteImage? ledgerLineImage;
      if (line < firstLineIndex || line > lastLineIndex) {
        ledgerLineImage = line < firstLineIndex
            ? noteImages.firstWhereOrNull((noteImage) {
                final position = naturalPositionOf(noteImage.notePosition);
                return position != offStaff && position <= line;
              })
            : noteImages.firstWhereOrNull(
                (noteImage) => naturalPositionOf(noteImage.notePosition) >= line);
        if (ledgerLineImage == null) {
          continue;
        }
      } else {
        ledgerLineImage = null;
      }
      final y = (bounds.height - ((line * noteHeight) - noteHeight / 2))
          .roundToDouble();
      if (ledgerLineImage != null) {
        final ledgerLineLeft = bounds.left +
            clefSize.width +
            keySignatureWidth +
            (bounds.width -
                    ovalWidth * 2 -
                    clefSize.width -
                    keySignatureWidth) *
                ledgerLineImage.offset;
        final ledgerLineRight = ledgerLineLeft + ovalWidth * 1.6;
        canvas.drawLine(
            Offset(ledgerLineLeft, y), Offset(ledgerLineRight, y), _linePaint);
      } else {
        canvas.drawLine(
            Offset(bounds.left, y), Offset(bounds.right, y), _linePaint);

        firstLineY ??= y;
        lastLineY = y;
      }
    }

    // --- Key signature: sharps/flats drawn just after the clef ---
    for (var i = 0; i < keySignatureGlyphs.length; i++) {
      final (position, accidental) = keySignatureGlyphs[i];
      final index = _naturalPositions.indexWhere(
          (p) => p.note == position.note && p.octave == position.octave);
      if (index == -1) continue;
      final ovalTop = bounds.height - (index * noteHeight) - noteHeight / 2;
      _glyphPainter(_accidentalGlyph(accidental), ovalHeight * 2, clefColor)
          .paint(
        canvas,
        Offset(
          bounds.left + clefSize.width + i * keySignatureGlyphSpacing,
          ovalTop - ovalHeight / 2,
        ),
      );
    }

    const tailHeight = 7;
    final middleLineIndex =
        (firstLineIndex + (lastLineIndex - firstLineIndex - 1) / 2).floor();

    // Notes that resolve to the same staff row (e.g. C and C#) would draw on
    // top of each other. Nudge the higher-pitched note of each such group one
    // notehead-width to the right so both are visible, while leaving their
    // accidentals in the original column. Capped at a single indent, matching
    // how a real chart offsets a clustered second.
    final rowMembers = <int, List<int>>{};
    final noteShifts = List<double>.filled(noteImages.length, 0.0);
    for (var i = 0; i < noteImages.length; i++) {
      final display = const PianoUtils().spellNotePosition(
        noteImages[i].notePosition,
        keySignature: keySignature,
      );
      final idx = naturalPositionOf(display);
      if (idx == offStaff) continue;
      rowMembers.putIfAbsent(idx, () => []).add(i);
    }
    for (final members in rowMembers.values) {
      if (members.length < 2) continue;
      members.sort((a, b) => noteImages[a]
          .notePosition
          .pitch
          .compareTo(noteImages[b].notePosition.pitch));
      for (var k = 1; k < members.length; k++) {
        noteShifts[members[k]] = ovalWidth * 0.7;
      }
    }

    for (var noteIdx = 0; noteIdx < noteImages.length; noteIdx++) {
      final noteImage = noteImages[noteIdx];
      final displayNotePosition = const PianoUtils().spellNotePosition(
        noteImage.notePosition,
        keySignature: keySignature,
      );
      final noteIndex = naturalPositionOf(displayNotePosition);
      if (noteIndex == offStaff) {
        continue;
      }
      final noteShift = noteShifts[noteIdx];
      final ovalBaseLeft = bounds.left +
          clefSize.width +
          keySignatureWidth +
          (bounds.width -
                  ovalWidth * 1.2 -
                  clefSize.width -
                  keySignatureWidth) *
              noteImage.offset;
      final ovalRect = Rect.fromLTWH(
          ovalBaseLeft + noteShift,
          bounds.height - (noteIndex * noteHeight) - noteHeight / 2,
          ovalWidth,
          ovalHeight);
      canvas.save();
      canvas.translate(ovalRect.left, ovalRect.top + noteHeight * 0.3);
      canvas.rotate(-0.2);
      _notePaint.color = noteImage.color ?? noteColor;
      canvas.drawOval(Offset.zero & ovalRect.size, _notePaint);
      canvas.restore();

      final isOnOrAboveMiddleLine = noteIndex > middleLineIndex;

      final Offset tailFrom, tailTo;

      if (isOnOrAboveMiddleLine) {
        // Tail hangs down, on the left side
        tailFrom = ovalRect.centerLeft -
            Offset(-_tailPaint.strokeWidth / 2 - ovalWidth * 0.06,
                -ovalHeight * 0.1);
        tailTo = tailFrom + Offset(0, noteHeight * tailHeight);
      } else {
        // Tail stucks up, on the right side
        tailFrom = ovalRect.centerRight +
            Offset(-_tailPaint.strokeWidth / 2 + ovalWidth * 0.06,
                -ovalHeight * 0.1);
        tailTo = tailFrom + Offset(0, -noteHeight * tailHeight);
      }

      _tailPaint.color = noteImage.color ?? noteColor;
      canvas.drawLine(tailFrom, tailTo, _tailPaint);

      // Only draw an accidental the key signature doesn't already imply. A note
      // that contradicts the key (e.g. F natural in G major) gets a natural.
      final expected = keySignatureByLetter[displayNotePosition.note];
      final actual = displayNotePosition.accidental;
      final String? accidentalGlyph;
      if (expected == actual || (expected == null && actual == Accidental.None)) {
        accidentalGlyph = null;
      } else if (actual == Accidental.None && expected != null) {
        accidentalGlyph = '♮';
      } else {
        accidentalGlyph = _accidentalGlyph(actual);
      }

      if (accidentalGlyph != null) {
        final glyphPainter = _glyphPainter(
            accidentalGlyph, ovalHeight * 2, noteImage.color ?? noteColor);
        // Sit the accidental just to the left of the notehead's un-shifted
        // column, vertically centred on it.
        glyphPainter.paint(
          canvas,
          Offset(
            ovalBaseLeft - glyphPainter.width - ovalWidth * 0.4,
            ovalRect.center.dy - glyphPainter.height / 2,
          ),
        );
      }
    }

    if (firstLineY == null || lastLineY == null) {
      return;
    }

    final clefHeight = (firstLineY - lastLineY);
    final isMacOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final clefSymbolOffset = isMacOS ? (clef == Clef.Treble ? 0.5 : 0.2) : 0.35;

    if (_clefSymbolPainter == null || clefSize != _lastClefSize) {
      final clefSymbolScale = isMacOS ? (clef == Clef.Treble ? 2.3 : 1.3) : 1.5;
      final targetHeight = clefHeight * clefSymbolScale;
      const baseSize = 100.0;

      final metricsPainter = TextPainter(
        text: TextSpan(
          text: clef.symbol,
          style: const TextStyle(fontSize: baseSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final metricsHeight = metricsPainter.height;
      final scale = metricsHeight > 0 ? targetHeight / metricsHeight : 1.0;
      final scaledFontSize = baseSize * scale;

      _clefSymbolPainter = TextPainter(
          text: TextSpan(
              text: clef.symbol,
              style: TextStyle(fontSize: scaledFontSize, color: clefColor)),
          textDirection: TextDirection.ltr)
        ..layout();
    }
    _lastClefSize = clefSize;

    _clefSymbolPainter?.paint(
        canvas, Offset(bounds.left, lastLineY - clefSymbolOffset * clefHeight));
  }

  @override
  bool shouldRepaint(covariant CustomClefPainter oldDelegate) =>
      oldDelegate != this;
}
