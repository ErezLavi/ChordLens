import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/menu/picker_row.dart';

class ProgressionBar extends StatelessWidget {
  const ProgressionBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.editingIndex,
    required this.voiceLeadingEnabled,
    required this.onStepTapped,
    required this.onStepEditRequested,
    required this.onStepAdded,
    required this.onVoiceLeadingChanged,
    required this.onRemove,
    required this.onDone,
  });

  final List<String> labels;
  final int? selectedIndex;
  final int? editingIndex;
  final bool voiceLeadingEnabled;
  final ValueChanged<int> onStepTapped;
  final ValueChanged<int> onStepEditRequested;
  final VoidCallback onStepAdded;
  final ValueChanged<bool> onVoiceLeadingChanged;
  final VoidCallback onRemove;
  final VoidCallback onDone;

  bool get _isEditing => editingIndex != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: AppSizes.space8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.queue_music,
            color: Constants.primaryColor,
            size: AppSizes.space24,
          ),
          AppSizes.space12.sbWidth,
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: AppSizes.space4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSizes.space8,
                children: [
                  for (var index = 0; index < labels.length; index++)
                    PickerChip(
                      label: labels[index],
                      selected: selectedIndex == index,
                      outlined: true,
                      ringed: editingIndex == index,
                      onTap: () => onStepTapped(index),
                      onLongPress: () => onStepEditRequested(index),
                    ),
                  _AddChordButton(onPressed: onStepAdded),
                ],
              ),
            ),
          ),
          AppSizes.space12.sbWidth,
          if (_isEditing) ...[
            OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove'),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                foregroundColor: Colors.black87,
              ),
            ),
            AppSizes.space8.sbWidth,
            FilledButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Done'),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: Constants.primaryColor,
              ),
            ),
          ] else
            _VoiceLeadingSwitch(
              value: voiceLeadingEnabled,
              onChanged: onVoiceLeadingChanged,
            ),
        ],
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
          activeTrackColor: Constants.primaryColor,
        ),
        AppSizes.space6.sbWidth,
        Tooltip(
          message: 'Voice leading',
          child: Text(
            'VOICE LEADING',
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
          color: Constants.primaryColor.withValues(alpha: 0.45),
        ),
        child: SizedBox.square(
          dimension: 40,
          child: InkResponse(
            onTap: onPressed,
            radius: 20,
            child: const Icon(
              Icons.add,
              size: 20,
              color: Constants.primaryColor,
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
