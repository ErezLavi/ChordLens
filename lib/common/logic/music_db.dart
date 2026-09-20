// The chord and scale vocabulary the whole app shares, plus the helpers that
// read it. Deliberately free of `package:flutter` so logic that depends on it
// — chord detection, voice leading — stays plain Dart.

class MusicDb {
  static Map<String, Set<int>> chordDB = {
    "": {4, 7},
    "m": {3, 7},
    "7": {4, 7, 10},
    "maj7": {4, 7, 11},
    "m7": {3, 7, 10},
    "mMaj7": {3, 7, 11},
    "mMaj7#5": {3, 8, 11},
    "sus2": {2, 7},
    "sus4": {5, 7},
    "dim": {3, 6},
    "dim7": {3, 6, 9},
    "aug": {4, 8},

    // Extensions:
    "9": {4, 7, 10, 2},
    "11": {4, 7, 10, 2, 5},
    "13": {4, 7, 10, 2, 5, 9},

    // Altered
    "7b9": {4, 7, 10, 1},
    "7#9": {4, 7, 10, 3},
    "7#11": {4, 7, 10, 6},
    "7b13": {4, 7, 10, 8},
    "7#5": {4, 8, 10},

    // --- Additions ---
    "add2": {2, 4, 7},
    "add4": {4, 7, 5},
    "add9": {4, 7, 2},
    "m(add9)": {3, 7, 2},
    "6": {4, 7, 9},
    "6/9": {4, 7, 9, 2},
    "m9": {3, 7, 10, 2},
    "m11": {3, 7, 10, 2, 5},
    "m13": {3, 7, 10, 2, 5, 9},
    "m6": {3, 7, 9},
    "m7b5": {3, 6, 10},
    "7sus4": {5, 7, 10},
    "7b5": {4, 6, 10},
    "add#11": {4, 6, 7},
    "addb6": {4, 7, 8},
    "maj7#5": {4, 8, 11},
    "maj7sus4": {5, 7, 11},
    "maj9": {4, 7, 11, 2},
  };

  static Map<String, Set<int>> scaleDB = {
    "major": {0, 2, 4, 5, 7, 9, 11, 12},
    "natural_minor": {0, 2, 3, 5, 7, 8, 10, 12},
    "harmonic_minor": {0, 2, 3, 5, 7, 8, 11, 12},
    "melodic_minor": {0, 2, 3, 5, 7, 9, 11, 12},
    "dorian": {0, 2, 3, 5, 7, 9, 10, 12},
    "phrygian": {0, 1, 3, 5, 7, 8, 10, 12},
    "lydian": {0, 2, 4, 6, 7, 9, 11, 12},
    "mixolydian": {0, 2, 4, 5, 7, 9, 10, 12},
    "locrian": {0, 1, 3, 5, 6, 8, 10, 12},
    "major_pentatonic": {0, 2, 4, 7, 9, 12},
    "minor_pentatonic": {0, 3, 5, 7, 10, 12},
    "blues": {0, 3, 5, 6, 7, 10, 12},
    "chromatic": {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
    "whole_tone": {0, 2, 4, 6, 8, 10, 12},
    "diminished_whole_half": {0, 2, 3, 5, 6, 8, 9, 11, 12},
  };

  // Required intervals that must be explicitly present to allow a chord type.
  static final Map<String, Set<int>> chordRequiredIntervals = {
    // Suspensions
    "sus2": {2},
    "sus4": {5},
    "7sus4": {5},
    "maj7sus4": {5, 11},

    // Altered fifths
    "aug": {8},
    "7#5": {8},
    "maj7#5": {8},
    "mMaj7#5": {8},

    // Altered extensions
    "7b9": {1},
    "7#9": {3},
    "7#11": {6},
    "7b13": {8},
    "addb6": {8},
    "add#11": {6},
    "add2": {2},
  };

  static const Map<String, int> chordRank = {
    // 0-9: The "Essentials" (Triads & basic 7ths)
    "": 0,
    "m": 1,
    "7": 2,
    "maj7": 3,
    "m7": 4,
    "sus4": 5,
    "sus2": 6,
    "dim": 7,
    "aug": 8,

    // 10-19: Standard Extensions & 6th Chords
    "maj9": 10,
    "9": 11,
    "m9": 12,
    "6": 13,
    "m6": 14,
    "6/9": 15, // Added: Vital for your C6/9 test
    "m6/9": 16, // Added: Minor equivalent
    "dim7": 17,
    "m7b5": 18,

    // 20-29: The "Add" Chords (Specific color clusters)
    "add9": 20,
    "m(add9)": 21, // minor triad + 9, no 7th — preferred over "m9(no7)"
    "add2": 22,
    "add4": 23,
    "addb6": 24,
    "add#11": 25,
    "m9(no7)": 26,

    // 30-39: Advanced/Altered (Complex tensions)
    "7sus4": 30,
    "7#5": 31,
    "7b5": 32,
    "7b9": 33,
    "7#9": 34,
    "7#11": 35,
    "7b13": 36,
    "maj7#5": 37,
    "mMaj7": 38,
    "mMaj7#5": 39,
    "maj7sus4": 40,

    // 40+: Deep Extensions
    "11": 41,
    "13": 42,
    "m11": 43,
    "m13": 44,
  };

  static int maxChordInversion(String chordType) {
    final intervals = chordDB[chordType];
    if (intervals == null) return 0;
    final noteCount = intervals.length + 1;
    return noteCount > 0 ? noteCount - 1 : 0;
  }

  static List<int> applyChordInversion(List<int> intervals, int inversion) {
    if (intervals.isEmpty) return intervals;
    if (inversion <= 0) return intervals;
    final maxInversion = intervals.length - 1;
    final safeInversion = inversion.clamp(0, maxInversion).toInt();
    final adjusted = List<int>.from(intervals);
    for (var i = 0; i < safeInversion; i++) {
      adjusted[i] += 12;
    }
    adjusted.sort();
    return adjusted;
  }
}
