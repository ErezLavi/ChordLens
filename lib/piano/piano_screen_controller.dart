import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:piano/piano.dart';
import 'package:piano_app/common/audio_service.dart';
import 'package:piano_app/common/chord_detector.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/common/midi_service.dart';
import 'package:piano_app/common/piano_utils.dart';
import 'package:piano_app/domain/key_signature_reference.dart';
import 'package:piano_app/domain/sound_font_option.dart';
import 'package:piano_app/domain/selected_chord.dart';
import 'package:piano_app/domain/selected_scale.dart';

/// Which picker the top bar has toggled on. On wide layouts the matching row
/// sits permanently above the keyboard; `null` means neither is open.
enum MenuPicker { chords, scales }

class PianoScreenController extends ChangeNotifier {
  PianoScreenController();

  static final NoteRange fullRange = NoteRange(
    from: NotePosition(note: Note.A, octave: 0),
    to: NotePosition(note: Note.C, octave: 8),
  );

  final FocusNode focusNode = FocusNode();
  final Set<NotePosition> _pressedNotes = {};
  final Map<LogicalKeyboardKey, NotePosition> _activeKeyNotes = {};
  final List<SoundFontOption> _availableSoundFonts = List.of(
    Constants.soundFonts,
  );
  final MidiService _midiService = MidiService();
  final AudioService _audioService = AudioService();
  final PianoUtils _pianoTheory = const PianoUtils();

  // Variables
  int _keyboardOctave = 4;
  KeySignatureReference _selectedKeySignature =
      Constants.keySignatureReferences.first;
  bool _isMuted = false;
  SoundFontOption _soundFont = Constants.soundFonts.first;
  String currentChord = '';
  final SelectedChord _selectedChord = SelectedChord();
  final SelectedScale _selectedScale = SelectedScale();
  MenuPicker? _activePicker;

  // Getters
  List<NotePosition> get pressedNotes => _pressedNotes.toList();
  NoteRange get noteRange => fullRange;
  int get keyboardOctave => _keyboardOctave;
  bool get useFlats => _selectedKeySignature.usesFlats;
  bool get isMuted => _isMuted;
  SoundFontOption get selectedSoundFont => _soundFont;
  SelectedChord get selectedChord => _selectedChord;
  SelectedScale get selectedScale => _selectedScale;
  MenuPicker? get activePicker => _activePicker;
  KeySignatureReference get selectedKeySignature => _selectedKeySignature;
  List<KeySignatureReference> get keySignatureReferences =>
      Constants.keySignatureReferences;
  List<SoundFontOption> get availableSoundFonts =>
      List.unmodifiable(_availableSoundFonts);
  List<NotePosition> get combinedHighlightedNotes {
    final combined = <NotePosition>{};
    combined.addAll(_selectedChord.notes);
    combined.addAll(_selectedScale.notes);
    return combined.toList();
  }

  // Connected devices
  List<String> get connectedDeviceNames => _midiService.connectedDeviceNames;

  void _updateChord() {
    final detected = ChordDetector.detect(
      _pressedNotes,
      useFlats: useFlats,
      keySignature: _selectedKeySignature,
    );
    currentChord = detected?.name ?? "";
  }

  void setSelectedKeySignature(KeySignatureReference value) {
    if (_selectedKeySignature == value) return;
    _selectedKeySignature = value;
    _updateChord();
    notifyListeners();
  }

  void incrementOctave() {
    final newOctave = (_keyboardOctave + 1).clamp(0, 8).toInt();
    if (newOctave != _keyboardOctave) {
      _keyboardOctave = newOctave;
      _rebuildSelectedHighlights();
      notifyListeners();
    }
  }

  void decrementOctave() {
    final newOctave = (_keyboardOctave - 1).clamp(0, 8).toInt();
    if (newOctave != _keyboardOctave) {
      _keyboardOctave = newOctave;
      _rebuildSelectedHighlights();
      notifyListeners();
    }
  }

  (String, String) splitChordName(String chord) {
    if (chord.isEmpty) return ('', '');
    int rootLen = 1;
    if (chord.length > 1) {
      final accidental = chord[1];
      if (accidental == '#' || accidental == 'b') {
        rootLen = 2;
      }
    }
    return (chord.substring(0, rootLen), chord.substring(rootLen));
  }

  void handleKeyboardKey(KeyEvent event) {
    var updated = false;
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.bracketLeft) {
        decrementOctave();
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.bracketRight) {
        incrementOctave();
        return;
      } else {
        final offset = Constants.keyboardKeyOffsets[event.logicalKey];
        if (offset != null && !_activeKeyNotes.containsKey(event.logicalKey)) {
          final semitone = _keyboardOctave * 12 + offset;
          final note = _pianoTheory.noteFromOffset(semitone);

          if (fullRange.contains(note)) {
            _pressedNotes.add(note);
            _activeKeyNotes[event.logicalKey] = note;

            if (!_isMuted) {
              _audioService.playNote(key: note.pitch);
            }
            updated = true;
          }
        }
      }
    } else if (event is KeyUpEvent) {
      final note = _activeKeyNotes.remove(event.logicalKey);
      if (note != null) {
        _pressedNotes.remove(note);
        if (!_isMuted) {
          _audioService.stopNote(key: note.pitch);
        }
        updated = true;
      }
    }

    if (updated) {
      _updateChord();
      notifyListeners();
    }
  }

  void togglePicker(MenuPicker picker) {
    _activePicker = _activePicker == picker ? null : picker;
    notifyListeners();
  }

  void onChordSelected(int rootPc, String chordType, int inversion) {
    _selectedChord.rootPc = rootPc;
    _selectedChord.type = chordType;
    _selectedChord.inversion = inversion;
    _selectedChord.notes = _pianoTheory.buildChordNotesForOctave(
      rootPc: rootPc,
      chordType: chordType,
      octave: _keyboardOctave,
      inversion: _selectedChord.inversion,
      noteRange: fullRange,
    );
    notifyListeners();
  }

  void clearSelectedChord() {
    _selectedChord.reset();
    notifyListeners();
  }

  void onScaleSelected(int rootPc, String scaleType) {
    _selectedScale.rootPc = rootPc;
    _selectedScale.type = scaleType;
    _selectedScale.notes = _pianoTheory.buildScaleNotesForOctave(
      rootPc: rootPc,
      scaleType: scaleType,
      octave: _keyboardOctave,
      noteRange: fullRange,
    );
    notifyListeners();
  }

  void clearSelectedScale() {
    _selectedScale.reset();
    notifyListeners();
  }

  void _rebuildSelectedHighlights() {
    if (_selectedChord.rootPc != null) {
      _selectedChord.notes = _pianoTheory.buildChordNotesForOctave(
        rootPc: _selectedChord.rootPc!,
        chordType: _selectedChord.type,
        octave: _keyboardOctave,
        inversion: _selectedChord.inversion,
        noteRange: fullRange,
      );
    }
    if (_selectedScale.rootPc != null) {
      _selectedScale.notes = _pianoTheory.buildScaleNotesForOctave(
        rootPc: _selectedScale.rootPc!,
        scaleType: _selectedScale.type,
        octave: _keyboardOctave,
        noteRange: fullRange,
      );
    }
  }

  void pressNote(NotePosition position) {
    if (!_pressedNotes.contains(position)) {
      _pressedNotes.add(position);

      if (!_isMuted) {
        _audioService.playNote(key: position.pitch);
      }

      _updateChord();
      notifyListeners();
    }
  }

  void releaseNote(NotePosition position) {
    if (_pressedNotes.contains(position)) {
      _pressedNotes.remove(position);

      if (!_isMuted) {
        _audioService.stopNote(key: position.pitch);
      }
      _updateChord();
      notifyListeners();
    }
  }

  //*** Audio handling***
  Future<void> setSoundFont(SoundFontOption soundFont) async {
    if (_soundFont.assetPath == soundFont.assetPath) return;
    _soundFont = soundFont;
    for (final note in _pressedNotes) {
      _audioService.stopNote(key: note.pitch);
    }
    if (soundFont.assetPath.startsWith('assets/')) {
      await _audioService.loadSoundFont(assetPath: soundFont.assetPath);
    } else {
      await _audioService.loadSoundFontFromFile(filePath: soundFont.assetPath);
    }
    notifyListeners();
  }

  Future<void> importSoundFontFile(String filePath) async {
    final existing = _availableSoundFonts
        .where((option) => option.assetPath == filePath)
        .cast<SoundFontOption?>()
        .firstWhere((option) => option != null, orElse: () => null);
    if (existing != null) {
      await setSoundFont(existing);
      return;
    }

    final fileName = filePath.replaceAll('\\', '/').split('/').last;
    final importedSoundFont = SoundFontOption(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: fileName,
      assetPath: filePath,
    );
    _availableSoundFonts.add(importedSoundFont);
    await setSoundFont(importedSoundFont);
  }

  Future<void> loadSoundFont() async {
    if (_soundFont.assetPath.startsWith('assets/')) {
      await _audioService.loadSoundFont(assetPath: _soundFont.assetPath);
    } else {
      await _audioService.loadSoundFontFromFile(filePath: _soundFont.assetPath);
    }
  }

  void setMuted(bool value) {
    if (_isMuted == value) return;
    _isMuted = value;
    if (_isMuted) {
      for (final note in _pressedNotes) {
        _audioService.stopNote(key: note.pitch);
      }
    }
    notifyListeners();
  }

  void toggleMuted() => setMuted(!_isMuted);

  //*** Midi handling ***
  Future<void> startHardwareMidiListening() async {
    await _midiService.startListening(
      onNoteOn: (midiKey) {
        final notePosition = _noteFromMidiKey(midiKey);
        if (notePosition != null) {
          pressNote(notePosition);
        }
      },
      onNoteOff: (midiKey) {
        final notePosition = _noteFromMidiKey(midiKey);
        if (notePosition != null) {
          releaseNote(notePosition);
        }
      },
      onDeviceNamesChanged: notifyListeners,
    );
  }

  NotePosition? _noteFromMidiKey(int key) {
    if (key < 0 || key > 127) return null;
    final note = _pianoTheory.noteFromOffset(key);
    if (!fullRange.contains(note)) return null;
    return note;
  }

  @override
  void dispose() {
    _midiService.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
