import 'package:flutter/material.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/common/constants.dart';

/// A single labelled line of the persistent picker: a caption, a horizontally
/// scrolling strip of [chips], and an optional [trailing] control pinned to the
/// right (inversion stepper, clear button).
class PickerRowLine extends StatelessWidget {
  const PickerRowLine({
    super.key,
    required this.label,
    required this.chips,
    this.trailing,
    this.labelWidth = 72,
  });

  final String label;
  final List<Widget> chips;
  final Widget? trailing;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.space4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSizes.space6,
              children: chips,
            ),
          ),
        ),
        if (trailing != null) ...[
          AppSizes.space8.sbWidth,
          SizedBox(
            height: 28,
            child: VerticalDivider(
              width: 1,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          AppSizes.space8.sbWidth,
          trailing!,
        ],
      ],
    );
  }
}

/// Pill-shaped selectable chip used by the picker rows. The selected chip is
/// filled with the primary color.
class PickerChip extends StatelessWidget {
  const PickerChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.outlined = false,
    this.ringed = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool outlined;
  final bool ringed;

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: selected
          ? Constants.primaryColor
          : (outlined ? Colors.white : Colors.transparent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        side: BorderSide(
          color: selected
              ? Constants.primaryColor
              : (outlined ? Colors.black26 : Colors.transparent),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space12,
            vertical: AppSizes.space8,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );

    if (!ringed) return chip;
    return Container(
      padding: const EdgeInsets.all(AppSizes.space4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusL + AppSizes.space4),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: chip,
    );
  }
}

/// Clear button pinned to the end of a picker row.
class PickerClearButton extends StatelessWidget {
  const PickerClearButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.clear, size: 18),
      label: const Text('Clear'),
    );
  }
}

/// Compact `− value +` stepper used for the chord inversion control.
class PickerStepper extends StatelessWidget {
  const PickerStepper({
    super.key,
    required this.label,
    required this.value,
    this.onDecrement,
    this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(AppSizes.space4),
          constraints: const BoxConstraints(),
        ),
        SizedBox(
          width: 44,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge,
          ),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(AppSizes.space4),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
