import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/menu/adaptive_menu.dart';
import 'package:piano_app/menu/chords_grid.dart';
import 'package:piano_app/menu/scales_grid.dart';
import 'package:piano_app/piano/piano_screen_controller.dart';

class TopMenuBar extends StatelessWidget {
  final PianoScreenController controller;
  final bool isCompact;

  const TopMenuBar({
    super.key,
    required this.controller,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? AppSizes.space20 : AppSizes.space32;
    final iconPadding = EdgeInsets.all(
      isCompact ? AppSizes.space2 : AppSizes.space8,
    );

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.space4),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: isCompact ? 1 : AppSizes.space4,
          runSpacing: isCompact ? 1 : AppSizes.space4,
          children: [
            if (isCompact) ...[
              AdaptiveMenu(
                isCompact: true,
                trigger: (context, open) => IconButton(
                  icon: const Icon(Icons.piano),
                  tooltip: 'Chords',
                  iconSize: iconSize,
                  padding: iconPadding,
                  onPressed: open,
                ),
                content: ChordsGrid(
                  onChordSelected: controller.onChordSelected,
                  onChordCleared: controller.clearSelectedChord,
                  initialRootPc: controller.selectedChord.rootPc ?? 0,
                  initialChordType: controller.selectedChord.type,
                  initialInversion: controller.selectedChord.inversion,
                  keySignature: controller.selectedKeySignature,
                  useFlats: controller.useFlats,
                ),
              ),
              AdaptiveMenu(
                isCompact: true,
                trigger: (context, open) => IconButton(
                  onPressed: open,
                  icon: const Icon(Icons.music_note),
                  tooltip: 'Scales',
                  iconSize: iconSize,
                  padding: iconPadding,
                ),
                content: ScalesGrid(
                  onScaleSelected: controller.onScaleSelected,
                  onScaleCleared: controller.clearSelectedScale,
                  initialRootPc: controller.selectedScale.rootPc ?? 0,
                  initialScaleType: controller.selectedScale.type,
                  keySignature: controller.selectedKeySignature,
                  useFlats: controller.useFlats,
                ),
              ),
            ] else ...[
              // Wide layout: the pickers live permanently above the keyboard,
              // so these only toggle which row is showing.
              _PickerToggle(
                icon: Icons.piano,
                label: 'Chords',
                iconSize: iconSize,
                selected: controller.activePicker == MenuPicker.chords,
                onPressed: () => controller.togglePicker(MenuPicker.chords),
              ),
              _PickerToggle(
                icon: Icons.music_note,
                label: 'Scales',
                iconSize: iconSize,
                selected: controller.activePicker == MenuPicker.scales,
                onPressed: () => controller.togglePicker(MenuPicker.scales),
              ),
            ],
            MenuAnchor(
              builder: (context, controller, _) {
                return IconButton(
                  icon: const Icon(Icons.devices),
                  tooltip: 'MIDI Devices',
                  iconSize: iconSize,
                  padding: iconPadding,
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                );
              },
              menuChildren: [
                if (controller.connectedDeviceNames.isEmpty)
                  const MenuItemButton(
                    onPressed: null,
                    child: Text('No MIDI device connected'),
                  )
                else
                  for (final device in controller.connectedDeviceNames)
                    MenuItemButton(onPressed: () {}, child: Text(device)),
              ],
            ),
            MenuAnchor(
              builder: (context, controller, _) {
                return IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  iconSize: iconSize,
                  padding: iconPadding,
                  onPressed: controller.open,
                );
              },
              menuChildren: [
                MenuAnchor(
                  builder: (context, controller, _) {
                    return MenuItemButton(
                      closeOnActivate: false,
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left, size: 18),
                          AppSizes.space6.sbWidth,
                          const Text('Choose Sound'),
                        ],
                      ),
                    );
                  },
                  menuChildren: [
                    for (final soundFont in controller.availableSoundFonts)
                      MenuItemButton(
                        onPressed: () => controller.setSoundFont(soundFont),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              soundFont.assetPath ==controller.selectedSoundFont.assetPath ? Icons.check : null,
                              size: 18,
                            ),
                            AppSizes.space8.sbWidth,
                            Text(soundFont.name),
                          ],
                        ),
                      ),
                    const Divider(),
                    MenuItemButton(
                      closeOnActivate: false,
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['sf2'],
                          );
                          final path = result?.files.single.path;
                          if (path == null || path.isEmpty) return;
                          await controller.importSoundFontFile(path);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to import SF2: $error'),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.upload_file, size: 18),
                          AppSizes.space8.sbWidth,
                          const Text('Import SF2...'),
                        ],
                      ),
                    ),
                  ],
                ),
                MenuItemButton(
                  closeOnActivate: false,
                  onPressed: controller.toggleMuted,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.isMuted ? Icons.volume_off : Icons.volume_up,
                        size: 18,
                      ),
                      AppSizes.space8.sbWidth,
                      Text(controller.isMuted ? 'Unmute' : 'Mute'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chords / Scales switch shown on wide layouts. The active picker is tinted
/// with the primary color.
class _PickerToggle extends StatelessWidget {
  const _PickerToggle({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final double iconSize;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: selected ? colors.primary : colors.onSurface,
        backgroundColor: selected
            ? colors.primary.withValues(alpha: 0.12)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
    );
  }
}
