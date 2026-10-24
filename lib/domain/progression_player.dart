import 'dart:async';

import 'package:piano_app/common/metronome_service.dart';
import 'package:piano_app/domain/chord_progression.dart';

/// Loops a [ChordProgression] in time, holding each step for a bar and
/// changing on the downbeat. Nothing is sounded but the click itself — the
/// beat only moves the highlight.
class ProgressionPlayer {
  ProgressionPlayer({
    required this.progression,
    required this.onStepChanged,
    MetronomeService? metronome,
  }) : _metronome = metronome ?? MetronomeService();

  static const int minBpm = 40;
  static const int maxBpm = 240;
  static const int bpmStep = 4;
  static const int defaultBpm = 96;

  final ChordProgression progression;
  final void Function() onStepChanged;
  final MetronomeService _metronome;

  bool _isPlaying = false;
  bool _clickEnabled = true;
  int _bpm = defaultBpm;

  bool get isPlaying => _isPlaying;
  bool get clickEnabled => _clickEnabled;
  int get bpm => _bpm;
  bool get canPlay => progression.length > 1;

  void play() {
    if (_isPlaying || !canPlay) return;
    _isPlaying = true;
    progression.doneEditing();
    unawaited(
      _metronome.start(
        bpm: _bpm,
        clickAudible: _clickEnabled,
        onBeat: _handleBeat,
      ),
    );
  }

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    unawaited(_metronome.stop());
  }

  void toggle() => _isPlaying ? pause() : play();

  void setBpm(int value) {
    final next = value.clamp(minBpm, maxBpm);
    if (next == _bpm) return;
    _bpm = next;
    unawaited(_metronome.setBpm(next));
  }

  void nudgeBpm(int delta) => setBpm(_bpm + delta);

  void setClickEnabled(bool value) {
    if (_clickEnabled == value) return;
    _clickEnabled = value;
    unawaited(_metronome.setClickAudible(value));
  }

  void toggleClick() => setClickEnabled(!_clickEnabled);

  void _handleBeat(int beatInBar) {
    if (beatInBar != 0) return;
    progression.advance();
    onStepChanged();
  }

  Future<void> dispose() {
    _isPlaying = false;
    return _metronome.dispose();
  }
}
