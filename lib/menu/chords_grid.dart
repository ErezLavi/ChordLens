import 'package:flutter/material.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/domain/key_signature_reference.dart';
import 'package:piano_app/menu/chord_picker_bar.dart';

typedef OnChordSelected =
    void Function(int rootPc, String chordType, int inversion);
typedef OnChordCleared = void Function();

class ChordsGrid extends StatefulWidget {
  final OnChordSelected? onChordSelected;
  final OnChordCleared? onChordCleared;
  final int initialRootPc;
  final String initialChordType;
  final int initialInversion;
  final KeySignatureReference? keySignature;
  final bool useFlats;

  /// Compact lays the picker out as wrapping grids inside a bottom sheet; wide
  /// lays it out as the two scrolling rows that sit above the keyboard.
  final bool isCompact;

  const ChordsGrid({
    super.key,
    this.onChordSelected,
    this.onChordCleared,
    this.initialRootPc = 0,
    this.initialChordType = '',
    this.initialInversion = 0,
    this.keySignature,
    this.useFlats = false,
    this.isCompact = true,
  });

  @override
  State<ChordsGrid> createState() => _ChordsGridState();
}

class _ChordsGridState extends State<ChordsGrid> {
  late int _rootPc;
  late String _chordType;
  late int _inversion;

  @override
  void initState() {
    super.initState();
    _rootPc = widget.initialRootPc;
    _chordType = widget.initialChordType;
    _inversion = widget.initialInversion;
    _clampInversion();
  }

  @override
  void didUpdateWidget(covariant ChordsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRootPc != widget.initialRootPc ||
        oldWidget.initialChordType != widget.initialChordType ||
        oldWidget.initialInversion != widget.initialInversion) {
      _rootPc = widget.initialRootPc;
      _chordType = widget.initialChordType;
      _inversion = widget.initialInversion;
      _clampInversion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootNames = List<int>.generate(12, (index) => index)
        .map(
          (pc) => Constants.noteName(
            pc,
            useFlats: widget.useFlats,
            keySignature: widget.keySignature,
          ),
        )
        .toList();
    final chordTypes = Constants.chordDB.keys
        .where((type) => (Constants.chordRank[type] ?? 999) <= 27)
        .toList();
    final maxInversion = _maxInversion();

    if (!widget.isCompact) {
      return ChordPickerBar(
        rootNames: rootNames,
        types: [
          for (final type in chordTypes)
            (value: type, label: _labelForChordType(type)),
        ],
        selectedRootPc: _rootPc,
        selectedType: _chordType,
        inversion: _inversion,
        maxInversion: maxInversion,
        onRootSelected: _selectRoot,
        onTypeSelected: _selectType,
        onInversionSelected: _selectInversion,
        onCleared: _clearSelection,
      );
    }

    final titleStyle = Theme.of(context).textTheme.titleSmall;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearSelection,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ),
            Text('Root', style: titleStyle),
            AppSizes.space8.sbHeight,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                rootNames.length,
                (index) => ChoiceChip(
                  label: Text(rootNames[index]),
                  selected: _rootPc == index,
                  showCheckmark: false,
                  onSelected: (_) => _selectRoot(index),
                ),
              ),
            ),
            AppSizes.space12.sbHeight,
            Text('Quality', style: titleStyle),
            AppSizes.space8.sbHeight,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chordTypes
                  .map(
                    (type) => ChoiceChip(
                      label: Text(_labelForChordType(type)),
                      selected: _chordType == type,
                      showCheckmark: false,
                      onSelected: (_) => _selectType(type),
                    ),
                  )
                  .toList(),
            ),
            AppSizes.space12.sbHeight,
            Text('Inversion', style: titleStyle),
            AppSizes.space8.sbHeight,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                maxInversion + 1,
                (index) => ChoiceChip(
                  label: Text(index == 0 ? 'Root' : '$index'),
                  selected: _inversion == index,
                  showCheckmark: false,
                  onSelected: (_) => _selectInversion(index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectRoot(int rootPc) {
    setState(() {
      _rootPc = rootPc;
    });
    widget.onChordSelected?.call(_rootPc, _chordType, _inversion);
  }

  void _selectType(String chordType) {
    setState(() {
      _chordType = chordType;
      _clampInversion();
    });
    widget.onChordSelected?.call(_rootPc, _chordType, _inversion);
  }

  void _selectInversion(int inversion) {
    setState(() {
      _inversion = inversion;
    });
    widget.onChordSelected?.call(_rootPc, _chordType, _inversion);
  }

  void _clearSelection() {
    setState(() {
      _rootPc = 0;
      _chordType = '';
      _inversion = 0;
    });
    widget.onChordCleared?.call();
  }

  int _maxInversion() {
    final maxFromType = Constants.maxChordInversion(_chordType);
    return maxFromType.clamp(0, 3).toInt();
  }

  void _clampInversion() {
    final max = _maxInversion();
    if (_inversion > max) {
      _inversion = max;
    }
  }

  String _labelForChordType(String type) {
    if (type.isEmpty) return 'Maj';
    if (type == 'm') return 'Min';
    return type;
  }
}
