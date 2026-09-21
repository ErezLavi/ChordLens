import 'package:flutter/material.dart';
import 'package:piano_app/menu/chords/chords_grid.dart';
import 'package:piano_app/menu/progressions/progression_bar.dart';
import 'package:piano_app/piano/piano_screen_controller.dart';

class ProgressionsPanel extends StatelessWidget {
  const ProgressionsPanel({
    super.key,
    required this.controller,
    required this.isCompact,
  });

  final PianoScreenController controller;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final progression = controller.progression;
    final editingStep = progression.editingStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressionBar(
          labels: progression.labels(
            useFlats: controller.useFlats,
            keySignature: controller.selectedKeySignature,
          ),
          selectedIndex: progression.selectedIndex,
          editingIndex: progression.editingIndex,
          voiceLeadingEnabled: progression.voiceLeadingEnabled,
          onStepTapped: controller.tapProgressionStep,
          onStepEditRequested: controller.editProgressionStep,
          onStepAdded: controller.addProgressionStep,
          onVoiceLeadingChanged: controller.setProgressionVoiceLeading,
          onRemove: controller.removeProgressionStep,
          onDone: controller.finishProgressionEdit,
        ),
        if (editingStep != null) ...[
          const Divider(height: 1),
          ChordsGrid(
            key: ValueKey(progression.editingIndex),
            isCompact: isCompact,
            chordLabel: 'CHORD ${progression.editingIndex! + 1}',
            showInversion: false,
            showClear: false,
            onChordSelected: controller.updateProgressionStep,
            initialRootPc: editingStep.rootPc,
            initialChordType: editingStep.type,
            initialInversion: editingStep.inversion,
            keySignature: controller.selectedKeySignature,
            useFlats: controller.useFlats,
          ),
        ],
      ],
    );
  }
}
