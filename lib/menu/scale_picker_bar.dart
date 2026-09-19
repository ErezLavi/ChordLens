import 'package:flutter/material.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/menu/picker_row.dart';

/// Wide-layout scale picker: a ROOT row and a SCALE row with the clear button,
/// both scrolling horizontally.
class ScalePickerBar extends StatelessWidget {
  const ScalePickerBar({
    super.key,
    required this.rootNames,
    required this.types,
    required this.selectedRootPc,
    required this.selectedType,
    required this.onRootSelected,
    required this.onTypeSelected,
    required this.onCleared,
  });

  /// Note name per pitch class, indexed by pitch class.
  final List<String> rootNames;

  /// Scale types paired with the label to show for each.
  final List<({String value, String label})> types;

  final int selectedRootPc;
  final String selectedType;
  final ValueChanged<int> onRootSelected;
  final ValueChanged<String> onTypeSelected;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: AppSizes.space8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PickerRowLine(
            label: 'ROOT',
            chips: List.generate(
              rootNames.length,
              (index) => PickerChip(
                label: rootNames[index],
                selected: selectedRootPc == index,
                onTap: () => onRootSelected(index),
              ),
            ),
          ),
          AppSizes.space4.sbHeight,
          PickerRowLine(
            label: 'SCALE',
            chips: types
                .map(
                  (type) => PickerChip(
                    label: type.label,
                    selected: selectedType == type.value,
                    onTap: () => onTypeSelected(type.value),
                  ),
                )
                .toList(),
            trailing: PickerClearButton(onPressed: onCleared),
          ),
        ],
      ),
    );
  }
}
