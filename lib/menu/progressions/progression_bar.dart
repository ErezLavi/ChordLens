import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/domain/progression_player.dart';
import 'package:piano_app/menu/picker_row.dart';
import 'package:piano_app/piano/piano_screen_controller.dart';

class ProgressionBar extends StatelessWidget {
  const ProgressionBar({
    super.key,
    required this.controller,
    required this.isCompact,
  });

  final PianoScreenController controller;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final progression = controller.progression;
    final labels = progression.labels(
      useFlats: controller.useFlats,
      keySignature: controller.selectedKeySignature,
    );

    final steps = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.space4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSizes.space8,
        children: [
          for (var index = 0; index < labels.length; index++)
            PickerChip(
              label: labels[index],
              selected: progression.selectedIndex == index,
              outlined: true,
              ringed: progression.editingIndex == index,
              onTap: () => controller.tapProgressionStep(index),
              onLongPress: () => controller.editProgressionStep(index),
            ),
          _AddChordButton(onPressed: controller.addProgressionStep),
        ],
      ),
    );

    final player = controller.progressionPlayer;
    final trailing = progression.isEditing
        ? _EditingActions(
            onRemove: controller.removeProgressionStep,
            onDone: controller.finishProgressionEdit,
          )
        : _Transport(
            isPlaying: player.isPlaying,
            canPlay: player.canPlay,
            clickEnabled: player.clickEnabled,
            bpm: player.bpm,
            voiceLeadingEnabled: progression.voiceLeadingEnabled,
            onPlayPause: controller.toggleProgressionPlayback,
            onClickToggled: controller.toggleProgressionClick,
            onBpmNudged: controller.nudgeProgressionBpm,
            onVoiceLeadingChanged: controller.setProgressionVoiceLeading,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: AppSizes.space8,
      ),
      child: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSizes.space8,
              children: [
                Row(
                  children: [
                    const _BarIcon(),
                    AppSizes.space12.sbWidth,
                    Expanded(child: steps),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: trailing,
                ),
              ],
            )
          : Row(
              children: [
                const _BarIcon(),
                AppSizes.space12.sbWidth,
                Expanded(child: steps),
                AppSizes.space12.sbWidth,
                trailing,
              ],
            ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.queue_music,
    color: Constants.chromeColor,
    size: AppSizes.space24,
  );
}

class _EditingActions extends StatelessWidget {
  const _EditingActions({required this.onRemove, required this.onDone});

  final VoidCallback onRemove;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSizes.space8,
      children: [
        OutlinedButton.icon(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Remove'),
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            foregroundColor: Colors.black87,
          ),
        ),
        FilledButton.icon(
          onPressed: onDone,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Done'),
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            backgroundColor: Constants.chromeColor,
          ),
        ),
      ],
    );
  }
}

/// Play / pause, click mute and tempo for the looping playback, plus the
/// voice-leading switch.
class _Transport extends StatelessWidget {
  const _Transport({
    required this.isPlaying,
    required this.canPlay,
    required this.clickEnabled,
    required this.bpm,
    required this.voiceLeadingEnabled,
    required this.onPlayPause,
    required this.onClickToggled,
    required this.onBpmNudged,
    required this.onVoiceLeadingChanged,
  });

  final bool isPlaying;
  final bool canPlay;
  final bool clickEnabled;
  final int bpm;
  final bool voiceLeadingEnabled;
  final VoidCallback onPlayPause;
  final VoidCallback onClickToggled;
  final ValueChanged<int> onBpmNudged;
  final ValueChanged<bool> onVoiceLeadingChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSizes.space8,
      children: [
        Tooltip(
          message: isPlaying ? 'Pause' : 'Play progression',
          child: IconButton.filled(
            onPressed: canPlay ? onPlayPause : null,
            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
            style: IconButton.styleFrom(
              backgroundColor: Constants.chromeColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Tooltip(
          message: clickEnabled ? 'Mute metronome' : 'Unmute metronome',
          child: FilledButton.icon(
            onPressed: onClickToggled,
            icon: Icon(
              clickEnabled ? Icons.timer_outlined : Icons.timer_off_outlined,
              size: 18,
            ),
            label: const Text('Click'),
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              backgroundColor: clickEnabled
                  ? Constants.chromeColor
                  : Colors.transparent,
              foregroundColor: clickEnabled
                  ? Colors.white
                  : Constants.chromeColor,
              side: clickEnabled
                  ? null
                  : BorderSide(
                      color: Constants.chromeColor.withValues(alpha: 0.45),
                    ),
            ),
          ),
        ),
        _BpmStepper(bpm: bpm, onNudged: onBpmNudged),
        _VoiceLeadingSwitch(
          value: voiceLeadingEnabled,
          onChanged: onVoiceLeadingChanged,
        ),
      ],
    );
  }
}

class _BpmStepper extends StatelessWidget {
  const _BpmStepper({required this.bpm, required this.onNudged});

  final int bpm;
  final ValueChanged<int> onNudged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$bpm BPM',
      child: Container(
        decoration: ShapeDecoration(
          shape: StadiumBorder(
            side: BorderSide(
              color: Constants.chromeColor.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => onNudged(-ProgressionPlayer.bpmStep),
              icon: const Icon(Icons.remove, size: 18),
              visualDensity: VisualDensity.compact,
              color: Constants.chromeColor,
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$bpm',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            IconButton(
              onPressed: () => onNudged(ProgressionPlayer.bpmStep),
              icon: const Icon(Icons.add, size: 18),
              visualDensity: VisualDensity.compact,
              color: Constants.chromeColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceLeadingSwitch extends StatelessWidget {
  const _VoiceLeadingSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: Constants.chromeColor,
        ),
        AppSizes.space6.sbWidth,
        Tooltip(
          message: 'Voice leading — smooth transitions',
          child: Text(
            'VL',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddChordButton extends StatelessWidget {
  const _AddChordButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add chord',
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: Constants.chromeColor.withValues(alpha: 0.45),
        ),
        child: SizedBox.square(
          dimension: 40,
          child: InkResponse(
            onTap: onPressed,
            radius: 20,
            child: const Icon(
              Icons.add,
              size: 20,
              color: Constants.chromeColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2 - 1;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final circumference = 2 * math.pi * radius;
    final step = (_dash + _gap) / radius;
    final dashes = (circumference / (_dash + _gap)).floor();
    final sweep = _dash / radius;

    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * step,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
