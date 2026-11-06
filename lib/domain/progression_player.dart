import 'package:piano_app/common/metronome_service.dart';
import 'package:piano_app/domain/chord_progression.dart';

/// Loops a [ChordProgression] in time, holding each step for a bar and
/// changing on the downbeat. Nothing is sounded but the click itself — the
/// beat only moves the highlight.
class ProgressionPlayer {
  ProgressionPlayer({
    required this.progression,
    required this.onStepChanged,
    required MetronomeService metronome,
  }) : _metronome = metronome;

  final ChordProgression progression;
  final void Function() onStepChanged;
  final MetronomeService _metronome;

  bool _awaitingDownbeat = false;
  bool _holdFirstBar = false;
  bool _startedClock = false;

  bool get isPlaying => _metronome.isFollowedBy(_handleBeat);
  bool get isAwaitingDownbeat => isPlaying && _awaitingDownbeat;
  bool get canPlay => progression.length > 1;

  void play() {
    if (isPlaying || !canPlay) return;
    _awaitingDownbeat = true;
    // The clock opens on a downbeat: a step already selected plays its full
    // first bar, otherwise that downbeat selects the first step.
    _holdFirstBar = progression.selectedIndex != null;
    _startedClock = !_metronome.isRunning;
    progression.doneEditing();
    _metronome.follow(_handleBeat);
  }

  void pause() {
    if (!isPlaying) return;
    _metronome.unfollow(_handleBeat);
    if (_startedClock) _metronome.stop();
  }

  void toggle() => isPlaying ? pause() : play();

  void _handleBeat(int beatInBar) {
    if (beatInBar != 0) return;
    _awaitingDownbeat = false;
    if (_holdFirstBar) {
      _holdFirstBar = false;
    } else {
      progression.advance();
    }
    onStepChanged();
  }
}
