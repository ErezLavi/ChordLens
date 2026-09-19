import 'package:piano_app/common/constants.dart';
import 'package:piano/piano.dart';
import 'package:piano_app/domain/key_signature_reference.dart';
import 'package:piano_app/common/logic/music_db.dart';

class DetectedChord {
  DetectedChord({required this.name, required this.root, required this.bass});

  final String name;
  final int root;
  final int bass;
}

class Candidate {
  Candidate(this.root, this.type, this.score);

  final int root;
  final String type;
  final int score;
}

class ChordDetector {
  /// Main entry point
  static DetectedChord? detect(
    Set<NotePosition> pressed, {
    bool useFlats = false,
    KeySignatureReference? keySignature,
  }) {
    final List<int> pcs = pressed.map((e) => e.pitch % 12).toSet().toList()
      ..sort();

    final pcsSet = pcs.toSet();
    if (pcsSet.length < 3) return null;

    final bassPc =
        pressed.reduce((a, b) => a.pitch < b.pitch ? a : b).pitch % 12;

    final candidates = <Candidate>[];

    for (final rootPc in pcs) {
      // Root must actually be played (no rootless inference)
      if (!pcsSet.contains(rootPc)) continue;

      final playedIntervals = _intervalsFromRoot(pcsSet, rootPc);

      // HARD structural gate: must be a real chord
      //if (!_isStructurallyChord(playedIntervals)) continue;

      for (final entry in MusicDb.chordDB.entries) {
        final chordType = entry.key;
        final template = entry.value;

        if (!_acceptableRoot(template, playedIntervals)) continue;

        final required = MusicDb.chordRequiredIntervals[chordType];
        if (required != null && !required.every(playedIntervals.contains)) {
          continue;
        }

        final missing = template.difference(playedIntervals).length;
        if (missing > 1) continue;

        final isSus = chordType.contains("sus");
        if (isSus &&
            (playedIntervals.contains(3) || playedIntervals.contains(4))) {
          continue;
        }

        final score = _scoreChord(template, playedIntervals);
        candidates.add(Candidate(rootPc, chordType, score));
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      // Accuracy First: Highest score wins
      if (a.score != b.score) {
        return b.score.compareTo(a.score);
      }

      // prefer Root Position
      if (a.root == bassPc && b.root != bassPc) return -1;
      if (b.root == bassPc && a.root != bassPc) return 1;

      // Commonality: Lower rank (more common) wins
      final aRank = MusicDb.chordRank[a.type] ?? 9999;
      final bRank = MusicDb.chordRank[b.type] ?? 9999;
      if (aRank != bRank) {
        return aRank.compareTo(bRank);
      }

      return a.root.compareTo(b.root);
    });

    final best = candidates.first;
    final playedIntervals = _intervalsFromRoot(pcsSet, best.root);

    return DetectedChord(
      name: _buildName(
        best.root,
        bassPc,
        best.type,
        playedIntervals,
        useFlats: useFlats,
        keySignature: keySignature,
      ),
      root: best.root,
      bass: bassPc,
    );
  }

  /// Convert played notes to interval set
  static Set<int> _intervalsFromRoot(Set<int> pcs, int root) {
    final out = <int>{};
    for (final p in pcs) {
      final i = (p - root + 12) % 12;
      if (i != 0) out.add(i);
    }
    return out;
  }

  static int _scoreChord(Set<int> template, Set<int> played) {
    final extra = played.difference(template).length;
    final missing = template.difference(played).length;
    return -(extra + missing);
  }

  static bool _acceptableRoot(Set<int> template, Set<int> played) {
    final isMajorTriad = template.contains(4) && template.contains(7);
    final isMinorTriad = template.contains(3) && template.contains(7);

    // Only require the third (quality-defining interval), not the fifth
    if (isMajorTriad && !played.contains(4)) {
      return false;
    }
    if (isMinorTriad && !played.contains(3)) {
      return false;
    }
    return true;
  }

  /// Naming logic including slash/inversion rules
  static String _buildName(
    int rootPc,
    int bassPc,
    String chordType,
    Set<int> playedIntervals, {
    bool useFlats = false,
    KeySignatureReference? keySignature,
  }) {
    final rootName = Constants.noteName(
      rootPc,
      useFlats: useFlats,
      keySignature: keySignature,
    );
    String name = "$rootName$chordType";

    if (bassPc == rootPc) return name;

    final bassName = Constants.noteName(
      bassPc,
      useFlats: useFlats,
      keySignature: keySignature,
    );
    return "$name/$bassName";
  }
}
