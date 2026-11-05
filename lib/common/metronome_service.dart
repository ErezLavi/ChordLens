import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:piano_app/common/audio_service.dart';

/// The single clock of the app, kept in Dart.
///
/// Beats are scheduled against a [Stopwatch] rather than chained timer
/// periods, so a late timer never pushes the beats after it. The click is a
/// short, high note on the loaded soundfont, so it shares the piano's output
/// and volume and needs no audio plugin of its own.
class MetronomeService {
  MetronomeService({required AudioService audio}) : _audio = audio;

  static const int beatsPerBar = 4;
  static const int minBpm = 40;
  static const int maxBpm = 240;
  static const int bpmStep = 4;
  static const int defaultBpm = 96;
  static const int accentKey = 96;
  static const int beatKey = 91;
  static const int accentVelocity = 110;
  static const int beatVelocity = 80;
  static const Duration clickLength = Duration(milliseconds: 60);

  final AudioService _audio;
  final Stopwatch _clock = Stopwatch();
  final Set<void Function(int beatInBar)> _followers = {};
  final ValueNotifier<int?> beat = ValueNotifier(null);
  Timer? _beatTimer;
  bool _clickAudible = true;
  int _bpm = defaultBpm;
  int _beatInBar = 0;
  Duration _nextBeatAt = Duration.zero;

  bool get isRunning => _clock.isRunning;
  bool get clickAudible => _clickAudible;
  int get bpm => _bpm;

  Duration get _beatLength =>
      Duration(microseconds: Duration.microsecondsPerMinute ~/ _bpm);

  /// The first downbeat sounds immediately.
  void start() {
    if (isRunning) return;
    _beatInBar = 0;
    _nextBeatAt = Duration.zero;
    _clock
      ..reset()
      ..start();
    _tick();
  }

  void stop() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _clock.stop();
    _followers.clear();
    beat.value = null;
  }

  void toggle() => isRunning ? stop() : start();

  void follow(void Function(int beatInBar) onBeat) {
    _followers.add(onBeat);
    start();
  }

  void unfollow(void Function(int beatInBar) onBeat) =>
      _followers.remove(onBeat);

  bool isFollowedBy(void Function(int beatInBar) onBeat) =>
      _followers.contains(onBeat);

  /// Keeps the beat already counting down where it was and stretches or
  /// shrinks only the wait for it, so a tempo change lands on the next beat.
  void setBpm(int value) {
    final next = value.clamp(minBpm, maxBpm);
    if (next == _bpm) return;
    final previous = _beatLength;
    _bpm = next;
    if (!isRunning) return;
    _nextBeatAt += _beatLength - previous;
    _scheduleNextBeat();
  }

  void nudgeBpm(int delta) => setBpm(_bpm + delta);

  void toggleClick() => _clickAudible = !_clickAudible;

  void _tick() {
    final now = _clock.elapsed;
    // After a stall longer than a beat, pick up from now instead of firing
    // the missed beats back to back.
    if (now - _nextBeatAt > _beatLength) _nextBeatAt = now;

    final current = _beatInBar;
    _beatInBar = (_beatInBar + 1) % beatsPerBar;
    _nextBeatAt += _beatLength;
    _scheduleNextBeat();

    if (_clickAudible) _click(accented: current == 0);
    beat.value = current;
    for (final onBeat in List.of(_followers)) {
      onBeat(current);
    }
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

  void dispose() {
    stop();
    beat.dispose();
  }
}
