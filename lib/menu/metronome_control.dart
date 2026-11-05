import 'package:flutter/material.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/common/metronome_service.dart';
import 'package:piano_app/menu/adaptive_menu.dart';
import 'package:piano_app/piano/piano_screen_controller.dart';

class MetronomeControl extends StatelessWidget {
  const MetronomeControl({
    super.key,
    required this.controller,
    required this.isCompact,
    required this.iconSize,
    required this.iconPadding,
  });

  final PianoScreenController controller;
  final bool isCompact;
  final double iconSize;
  final EdgeInsets iconPadding;

  @override
  Widget build(BuildContext context) {
    if (!isCompact) return _MetronomePill(controller: controller);
    return AdaptiveMenu(
      isCompact: true,
      trigger: (context, open) => IconButton(
        onPressed: open,
        tooltip: 'Metronome',
        iconSize: iconSize,
        padding: iconPadding,
        icon: _PulsingIcon(beat: controller.metronome.beat),
      ),
      content: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(AppSizes.space16),
          child: _MetronomePill(controller: controller),
        ),
      ),
    );
  }
}

class _MetronomePill extends StatelessWidget {
  const _MetronomePill({required this.controller});

  final PianoScreenController controller;

  @override
  Widget build(BuildContext context) {
    final metronome = controller.metronome;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: Constants.chromeColor.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: controller.toggleMetronome,
              tooltip: metronome.isRunning
                  ? 'Stop metronome'
                  : 'Start metronome',
              icon: Icon(metronome.isRunning ? Icons.stop : Icons.play_arrow),
              color: Constants.chromeColor,
              visualDensity: VisualDensity.compact,
            ),
            _BpmStepper(bpm: metronome.bpm, onNudged: controller.nudgeBpm),
            if (metronome.isRunning) ...[
              AppSizes.space4.sbWidth,
              _BeatDots(beat: metronome.beat),
              IconButton(
                onPressed: controller.toggleMetronomeClick,
                tooltip: metronome.clickAudible ? 'Mute click' : 'Unmute click',
                icon: Icon(
                  metronome.clickAudible ? Icons.volume_up : Icons.volume_off,
                  size: 18,
                ),
                color: Constants.chromeColor,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onNudged(-MetronomeService.bpmStep),
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
            onPressed: () => onNudged(MetronomeService.bpmStep),
            icon: const Icon(Icons.add, size: 18),
            visualDensity: VisualDensity.compact,
            color: Constants.chromeColor,
          ),
        ],
      ),
    );
  }
}

class _BeatDots extends StatelessWidget {
  const _BeatDots({required this.beat});

  final ValueNotifier<int?> beat;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: beat,
      builder: (context, current, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSizes.space4,
        children: [
          for (var index = 0; index < MetronomeService.beatsPerBar; index++)
            Container(
              width: index == 0 ? 10 : 8,
              height: index == 0 ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current == index ? Constants.chromeColor : null,
                border: Border.all(
                  color: Constants.chromeColor.withValues(alpha: 0.45),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatelessWidget {
  const _PulsingIcon({required this.beat});

  final ValueNotifier<int?> beat;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: beat,
      builder: (context, current, _) {
        if (current == null) return const Icon(Icons.timer_outlined);
        final peak = current == 0 ? 1.0 : 0.6;
        return TweenAnimationBuilder<double>(
          key: ValueKey(current),
          tween: Tween(begin: peak, end: 0),
          duration: const Duration(milliseconds: 250),
          builder: (context, pulse, _) => Transform.scale(
            scale: 1 + 0.2 * pulse,
            child: Icon(
              Icons.timer,
              color: Color.lerp(
                Constants.chromeColor.withValues(alpha: 0.6),
                Constants.chromeColor,
                pulse,
              ),
            ),
          ),
        );
      },
    );
  }
}
