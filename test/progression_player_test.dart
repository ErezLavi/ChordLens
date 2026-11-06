import 'package:flutter_test/flutter_test.dart';
import 'package:piano_app/common/audio_service.dart';
import 'package:piano_app/common/metronome_service.dart';
import 'package:piano_app/domain/chord_progression.dart';
import 'package:piano_app/domain/chord_step.dart';
import 'package:piano_app/domain/progression_player.dart';

class _FakeMetronomeService implements MetronomeService {
  final Set<void Function(int beatInBar)> followers = {};
  bool running = false;

  void beatOn(int beatInBar) {
    for (final onBeat in List.of(followers)) {
      onBeat(beatInBar);
    }
  }

  void playBars(int bars) {
    for (var i = 0; i < bars * MetronomeService.beatsPerBar; i++) {
      beatOn(i % MetronomeService.beatsPerBar);
    }
  }

  @override
  bool get isRunning => running;

  @override
  void start() => running = true;

  @override
  void stop() {
    running = false;
    followers.clear();
  }

  @override
  void follow(void Function(int beatInBar) onBeat) {
    followers.add(onBeat);
    start();
  }

  @override
  void unfollow(void Function(int beatInBar) onBeat) =>
      followers.remove(onBeat);

  @override
  bool isFollowedBy(void Function(int beatInBar) onBeat) =>
      followers.contains(onBeat);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

    test('holds each step for a bar and changes on the downbeat', () {
      player.play();

      metronome.playBars(2);

      expect(progression.selectedIndex, 1);
      expect(changes, 2);
    });

    test('the off-beats of a bar leave the selection alone', () {
      player.play();

      metronome.beatOn(0);
      expect(progression.selectedIndex, 0);

      for (var beat = 1; beat < MetronomeService.beatsPerBar; beat++) {
        metronome.beatOn(beat);
        expect(progression.selectedIndex, 0);
      }
      expect(changes, 1);
    });

    test('wraps back to the first step after the last bar', () {
      player.play();

      metronome.playBars(4);

      expect(progression.selectedIndex, 0);
    });

    test('play leaves edit mode and pause stops the clock it started', () {
      progression.beginEdit(1);
      player.play();
      expect(progression.isEditing, isFalse);
      expect(metronome.running, isTrue);

      player.pause();
      expect(player.isPlaying, isFalse);
      expect(metronome.running, isFalse);
    });

    test('joins a running clock on its next downbeat', () {
      metronome.start();
      player.play();

      metronome.beatOn(2);
      expect(player.isAwaitingDownbeat, isTrue);
      expect(progression.selectedIndex, isNull);

      metronome.beatOn(0);
      expect(player.isAwaitingDownbeat, isFalse);
      expect(progression.selectedIndex, 0);
    });

    test('pausing leaves a clock it joined running', () {
      metronome.start();
      player.play();

      player.pause();
      expect(player.isPlaying, isFalse);
      expect(metronome.running, isTrue);
    });

    test('stopping the clock stops the progression', () {
      player.play();

      metronome.stop();
      expect(player.isPlaying, isFalse);
    });

    test('refuses to play a progression with fewer than two steps', () {
      final single = ProgressionPlayer(
        progression: _progressionOf([0]),
        onStepChanged: () {},
        metronome: _FakeMetronomeService(),
      )..play();
      expect(single.isPlaying, isFalse);
    });
  });

  group('MetronomeService', () {
    late MetronomeService metronome;

    setUp(() => metronome = MetronomeService(audio: AudioService()));
    tearDown(() => metronome.dispose());

    test('a follower starts the clock and hears the first downbeat', () {
      final beats = <int>[];
      metronome.follow(beats.add);

      expect(metronome.isRunning, isTrue);
      expect(beats, [0]);
      expect(metronome.beat.value, 0);
    });

    test('stopping releases every follower and clears the beat', () {
      void onBeat(int _) {}
      metronome.follow(onBeat);

      metronome.stop();
      expect(metronome.isFollowedBy(onBeat), isFalse);
      expect(metronome.beat.value, isNull);
    });

    test('bpm nudges are clamped to the supported range', () {
      metronome.setBpm(MetronomeService.maxBpm);
      metronome.nudgeBpm(MetronomeService.bpmStep);
      expect(metronome.bpm, MetronomeService.maxBpm);

      metronome.setBpm(MetronomeService.minBpm);
      metronome.nudgeBpm(-MetronomeService.bpmStep);
      expect(metronome.bpm, MetronomeService.minBpm);
    });

    test('toggling the click mutes without stopping the clock', () {
      metronome.start();
      metronome.toggleClick();

      expect(metronome.clickAudible, isFalse);
      expect(metronome.isRunning, isTrue);
    });
  });
}
