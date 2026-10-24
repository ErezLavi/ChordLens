import 'package:flutter_test/flutter_test.dart';
import 'package:piano_app/common/metronome_service.dart';
import 'package:piano_app/domain/chord_progression.dart';
import 'package:piano_app/domain/chord_step.dart';
import 'package:piano_app/domain/progression_player.dart';

class _FakeMetronomeService implements MetronomeService {
  void Function(int beatInBar)? beat;
  bool running = false;
  bool? clickAudible;
  int? bpm;

  /// Plays [bars] whole bars of beats, downbeat first.
  void playBars(int bars) {
    for (var i = 0; i < bars * MetronomeService.beatsPerBar; i++) {
      beat!(i % MetronomeService.beatsPerBar);
    }
  }

  @override
  Future<void> start({
    required int bpm,
    required bool clickAudible,
    required void Function(int beatInBar) onBeat,
  }) async {
    running = true;
    beat = onBeat;
    this.bpm = bpm;
    this.clickAudible = clickAudible;
  }

  @override
  Future<void> stop() async {
    running = false;
    beat = null;
  }

  @override
  Future<void> setBpm(int bpm) async => this.bpm = bpm;

  @override
  Future<void> setClickAudible(bool audible) async => clickAudible = audible;

  @override
  Future<void> dispose() => stop();
}

ChordProgression _progressionOf(List<int> rootPcs) =>
    ChordProgression(steps: [for (final pc in rootPcs) ChordStep(rootPc: pc)]);

void main() {
  group('ChordProgression.advance', () {
    test('starts at the first step when nothing is selected', () {
      final progression = _progressionOf([0, 5, 7]);
      progression.advance();
      expect(progression.selectedIndex, 0);
    });

    test('wraps around the end', () {
      final progression = _progressionOf([0, 5, 7])..select(2);
      progression.advance();
      expect(progression.selectedIndex, 0);
    });

    test('does nothing when empty', () {
      final progression = _progressionOf([]);
      progression.advance();
      expect(progression.selectedIndex, isNull);
    });
  });

  group('ProgressionPlayer', () {
    late _FakeMetronomeService metronome;
    late ChordProgression progression;
    late ProgressionPlayer player;
    late int changes;

    setUp(() {
      metronome = _FakeMetronomeService();
      progression = _progressionOf([0, 5, 7]);
      changes = 0;
      player = ProgressionPlayer(
        progression: progression,
        onStepChanged: () => changes++,
        metronome: metronome,
      );
    });

    test('holds each step for a bar and changes on the downbeat', () async {
      player.play();
      await Future<void>.value();

      metronome.playBars(2);

      expect(progression.selectedIndex, 1);
      expect(changes, 2);
    });

    test('the off-beats of a bar leave the selection alone', () async {
      player.play();
      await Future<void>.value();

      metronome.beat!(0);
      expect(progression.selectedIndex, 0);

      for (var beat = 1; beat < MetronomeService.beatsPerBar; beat++) {
        metronome.beat!(beat);
        expect(progression.selectedIndex, 0);
      }
      expect(changes, 1);
    });

    test('wraps back to the first step after the last bar', () async {
      player.play();
      await Future<void>.value();

      metronome.playBars(4);

      expect(progression.selectedIndex, 0);
    });

    test('play leaves edit mode and pause stops the clock', () async {
      progression.beginEdit(1);
      player.play();
      await Future<void>.value();
      expect(progression.isEditing, isFalse);
      expect(metronome.running, isTrue);

      player.pause();
      await Future<void>.value();
      expect(player.isPlaying, isFalse);
      expect(metronome.running, isFalse);
    });

    test('refuses to play a progression with fewer than two steps', () {
      final single = ProgressionPlayer(
        progression: _progressionOf([0]),
        onStepChanged: () {},
        metronome: _FakeMetronomeService(),
      )..play();
      expect(single.isPlaying, isFalse);
    });

    test('bpm nudges are clamped to the supported range', () async {
      player.setBpm(ProgressionPlayer.maxBpm);
      player.nudgeBpm(ProgressionPlayer.bpmStep);
      expect(player.bpm, ProgressionPlayer.maxBpm);

      player.setBpm(ProgressionPlayer.minBpm);
      player.nudgeBpm(-ProgressionPlayer.bpmStep);
      expect(player.bpm, ProgressionPlayer.minBpm);
    });

    test('toggling the click mutes without stopping playback', () async {
      player.play();
      await Future<void>.value();

      player.toggleClick();
      await Future<void>.value();

      expect(player.clickEnabled, isFalse);
      expect(metronome.clickAudible, isFalse);
      expect(metronome.running, isTrue);
    });
  });
}
