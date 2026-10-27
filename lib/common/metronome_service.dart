import 'dart:async';

import 'package:piano_app/common/audio_service.dart';

/// The single clock for progression playback, kept in Dart.
///
/// Beats are scheduled against a [Stopwatch] rather than chained timer
/// periods, so a late timer never pushes the beats after it. The click is a
/// short, high note on the loaded soundfont, so it shares the piano's output
/// and volume and needs no audio plugin of its own.
class MetronomeService {
  MetronomeService({required AudioService audio}) : _audio = audio;

  static const int beatsPerBar = 4;
  static const int accentKey = 96;
  static const int beatKey = 91;
  static const int accentVelocity = 110;
  static const int beatVelocity = 80;
  static const Duration clickLength = Duration(milliseconds: 60);

  final AudioService _audio;
  final Stopwatch _clock = Stopwatch();
  Timer? _beatTimer;
  void Function(int beatInBar)? _onBeat;
  bool _clickAudible = true;
  int _bpm = 120;
  int _beatInBar = 0;
  Duration _nextBeatAt = Duration.zero;

  Duration get _beatLength =>
      Duration(microseconds: Duration.microsecondsPerMinute ~/ _bpm);

  /// [onBeat] receives the beat's index within the bar, counting from zero on
  /// the accented downbeat. The first downbeat sounds immediately.
  Future<void> start({
    required int bpm,
    required bool clickAudible,
    required void Function(int beatInBar) onBeat,
  }) async {
    _beatTimer?.cancel();
    _bpm = bpm;
    _clickAudible = clickAudible;
    _onBeat = onBeat;
    _beatInBar = 0;
    _nextBeatAt = Duration.zero;
    _clock
      ..reset()
      ..start();
    _tick();
  }

  Future<void> stop() async {
    _beatTimer?.cancel();
    _beatTimer = null;
    _clock.stop();
    _onBeat = null;
  }

  /// Keeps the beat already counting down where it was and stretches or
  /// shrinks only the wait for it, so a tempo change lands on the next beat.
  Future<void> setBpm(int bpm) async {
    if (bpm == _bpm) return;
    final previous = _beatLength;
    _bpm = bpm;
    if (_beatTimer == null) return;
    _nextBeatAt += _beatLength - previous;
    _scheduleNextBeat();
  }

  Future<void> setClickAudible(bool audible) async => _clickAudible = audible;

  void _tick() {
    final now = _clock.elapsed;
    // After a stall longer than a beat, pick up from now instead of firing
    // the missed beats back to back.
    if (now - _nextBeatAt > _beatLength) _nextBeatAt = now;

    final beat = _beatInBar;
    _beatInBar = (_beatInBar + 1) % beatsPerBar;
    _nextBeatAt += _beatLength;
    _scheduleNextBeat();

    if (_clickAudible) _click(accented: beat == 0);
    _onBeat?.call(beat);
  }

  void _scheduleNextBeat() {
    _beatTimer?.cancel();
    final wait = _nextBeatAt - _clock.elapsed;
    _beatTimer = Timer(wait.isNegative ? Duration.zero : wait, _tick);
  }

  void _click({required bool accented}) {
    final key = accented ? accentKey : beatKey;
    _audio.playNote(
      key: key,
      velocity: accented ? accentVelocity : beatVelocity,
    );
    Timer(clickLength, () => _audio.stopNote(key: key));
  }

  Future<void> dispose() => stop();
}
