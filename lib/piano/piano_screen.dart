import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/custom_piano/custom_interactive_piano.dart';
import 'package:piano_app/piano/piano_screen_controller.dart';
import 'package:piano_app/piano/widgets/grand_stuff_viewer_widget.dart';
import 'package:piano_app/piano/widgets/chord_viewer.dart';
import 'package:piano_app/piano/widgets/octave_buttons_widget.dart';
import 'package:piano_app/menu/adaptive_menu.dart';
import 'package:piano_app/menu/chords_grid.dart';
import 'package:piano_app/menu/key_signature_grid.dart';
import 'package:piano_app/menu/scales_grid.dart';
import 'package:piano_app/menu/top_bar.dart';

class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key, required this.controller});

  final PianoScreenController controller;

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> {
  late final PianoScreenController _controller;
  bool get _showOctaveControls =>
      defaultTargetPlatform != TargetPlatform.android ||
      _controller.connectedDeviceNames.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.loadSoundFont();
    _controller.startHardwareMidiListening();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyWidth = AppSizes.keyWidth(screenSize.width);
    final horizontalPadding = AppSizes.overlayHorizontalPadding(
      screenSize.width,
    );
    final verticalPadding = AppSizes.overlayVerticalPadding(screenSize.height);
    final isCompact = AppSizes.isCompactSize(screenSize);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Scaffold(
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSizes.space16,
                      horizontal: AppSizes.space12,
                    ),
                    child: Row(
                      children: [
                        GrandStaffViewerWidget(
                          pressedNotes: _controller.pressedNotes,
                          keySignature: _controller.selectedKeySignature,
                        ),
                        Expanded(
                          child: ChordViewer(
                            chord: _controller.currentChord,
                            splitChordName: _controller.splitChordName,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isCompact && _controller.activePicker != null)
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: switch (_controller.activePicker!) {
                      MenuPicker.chords => ChordsGrid(
                        isCompact: false,
                        onChordSelected: _controller.onChordSelected,
                        onChordCleared: _controller.clearSelectedChord,
                        initialRootPc: _controller.selectedChord.rootPc ?? 0,
                        initialChordType: _controller.selectedChord.type,
                        initialInversion: _controller.selectedChord.inversion,
                        keySignature: _controller.selectedKeySignature,
                        useFlats: _controller.useFlats,
                      ),
                      MenuPicker.scales => ScalesGrid(
                        isCompact: false,
                        onScaleSelected: _controller.onScaleSelected,
                        onScaleCleared: _controller.clearSelectedScale,
                        initialRootPc: _controller.selectedScale.rootPc ?? 0,
                        initialScaleType: _controller.selectedScale.type,
                        keySignature: _controller.selectedKeySignature,
                        useFlats: _controller.useFlats,
                      ),
                    },
                  ),
                Expanded(
                  flex: 1,
                  child: KeyboardListener(
                    focusNode: _controller.focusNode,
                    autofocus: true,
                    onKeyEvent: _controller.handleKeyboardKey,
                    child: CustomInteractivePiano(
                      highlightedNotes: _controller.pressedNotes,
                      chordHighlightedNotes:
                          _controller.combinedHighlightedNotes,
                      naturalColor: Colors.white,
                      accidentalColor: Colors.black,
                      keyWidth: keyWidth,
                      noteRange: _controller.noteRange,
                      keySignature: _controller.selectedKeySignature,
                      onNotePositionTapped: _controller.pressNote,
                      onNotePositionReleased: _controller.releaseNote,
                    ),
                  ),
                ),
              ],
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = AppSizes.isCompactLayout(constraints);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_showOctaveControls) ...[
                            OctaveButtonsWidget(
                              isCompact: isCompact,
                              keyboardOctave: _controller.keyboardOctave,
                              onIncrement: _controller.incrementOctave,
                              onDecrement: _controller.decrementOctave,
                            ),
                            isCompact
                                ? AppSizes.space12.sbWidth
                                : AppSizes.space36.sbWidth,
                          ],
                          AdaptiveMenu(
                            isCompact: isCompact,
                            trigger: (context, open) => isCompact
                                ? Material(
                                    elevation: 6,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusM,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: IconButton(
                                      tooltip: _controller
                                          .selectedKeySignature.label,
                                      onPressed: open,
                                      icon: const Text(
                                        '\u{1D11E}', // 𝄞 treble (G) clef
                                        style: TextStyle(
                                          fontSize: 20,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  )
                                : Material(
                                    elevation: 6,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusM,
                                    ),
                                    child: SizedBox(
                                      width: 180,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusM,
                                        ),
                                        onTap: open,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSizes.space12,
                                            vertical: AppSizes.space12,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _controller
                                                      .selectedKeySignature
                                                      .label,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              AppSizes.space8.sbWidth,
                                              const Icon(Icons.arrow_drop_down),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            content: ListenableBuilder(
                              listenable: _controller,
                              builder: (context, _) => KeySignatureGrid(
                                keySignatures:
                                    _controller.keySignatureReferences,
                                selectedKeySignature:
                                    _controller.selectedKeySignature,
                                onSelected:
                                    _controller.setSelectedKeySignature,
                              ),
                            ),
                          ),
                          isCompact
                              ? AppSizes.space12.sbWidth
                              : AppSizes.space36.sbWidth,
                          TopMenuBar(
                            controller: _controller,
                            isCompact: isCompact,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
