<p align="center">
  <img src="assets/icons/app_icon_rounded.png" alt="ChordLens icon" width="128" />
</p>

<h1 align="center">ChordLens 🎹</h1>

<p align="center">
  A Flutter piano app with real time chord detection,
  MIDI input support and a playable keyboard.<br/>
  Fully supported on macOS, Windows and Android.
</p>

## Downloads

Website: **https://erezlavi.github.io/ChordLens/** 

[![macOS](https://img.shields.io/badge/macOS-Download-black?logo=apple)](https://github.com/ErezLavi/ChordLens/releases/latest)
[![Windows](https://img.shields.io/badge/Windows-Download-0078D6?logo=windows)](https://github.com/ErezLavi/ChordLens/releases/latest)
[![Android](https://img.shields.io/badge/Android-Download-3DDC84?logo=android&logoColor=white)](https://github.com/ErezLavi/ChordLens/releases/latest)


## Features

- Chord detection with a chord name display
- Grand staff view of currently pressed notes
- Chord and scales highlighting from the top-right menu
- Hardware MIDI input support (auto-connects to the first available device) / Playing from the computer's keyboard
- SoundFont playback via SF2 assets / uploaded custom SF2 files + mute mode

| Main Layout |
| --- |
| ![Main layout](assets/showcase/main_layout.png) |

| Chords | Scales |
| --- | --- |
| ![Chords](assets/showcase/chords.png) | ![Scales](assets/showcase/scales.png) |

| Menu |
| --- |
| ![Menu](assets/showcase/menu.png) |

## Controls

- Computer keyboard mapping:
  - `Z S X D C V G B H N J M , L . ; /`
  - `[` and `]` to shift the keyboard octave

## SoundFonts

The app uses SoundFont files for instrument sounds. The default soundfont is set in
`lib/common/constants.dart` (`rhodesSoundFontAsset`). But you can upload your own SoundFont files and use them in the app.

## Getting Started

1. Install a Flutter SDK compatible with Dart 3.9.
2. Clone the repository:
   ```bash
   git clone https://github.com/ErezLavi/ChordLens.git
   cd ChordLens
   ```
3. Fetch dependencies (requires `git`, since one package is pulled from GitHub):
   ```bash
   flutter pub get
   ```
4. Run the app on one of the supported platforms:
   ```bash
   flutter run -d macos
   flutter run -d windows
   flutter run -d android
   ```
