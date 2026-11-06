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
- Metronome in the top bar, usable anywhere in the app, with adjustable BPM, a visual beat and a mutable click
- Chord progressions with playback in time with the metronome and voice leading
- Hardware MIDI input support (auto-connects to the first available device) / Playing from the computer's keyboard
- SoundFont playback via SF2 assets / uploaded custom SF2 files + mute mode

| Main Layout |
| --- |
| ![Main layout](assets/showcase/main_layout.png) |

| Chords | Scales |
| --- | --- |
| ![Chords](assets/showcase/chords.png) | ![Scales](assets/showcase/scales.png) |

| Progressions | Editing a chord |
| --- | --- |
| ![Progressions](assets/showcase/progressions.png) | ![Editing a chord](assets/showcase/progressions_edit.png) |

| Mobile | Menu |
| --- | --- |
| ![Mobile](assets/showcase/mobile.png) | ![Menu](assets/showcase/menu.png) |

## Controls

- Computer keyboard mapping:
  - `Z S X D C V G B H N J M , L . ; /`
  - `[` and `]` to shift the keyboard octave
  - `Space` to start / stop the metronome (or the progression, while Progressions is open)

## Chord Progressions

Open **Progressions** from the top-right menu to build and play a sequence of chords.

- Tap `+` to add a chord, tap a chord to select it, and tap it again (or long-press) to change or remove it
- Press play to loop the progression, one chord per bar (needs at least 2 chords). It follows the metronome: if the metronome is already running, the progression joins on the next bar
- Set the tempo (40–240 BPM) and mute the click from the metronome in the top bar
- Turn on **VL** (voice leading) for smooth transitions between chords

## Metronome

The metronome lives in the top bar and works on its own, with or without a progression.

- Press play (or `Space`) to start it, and set the tempo with `-` / `+` (40–240 BPM)
- While it runs, the beat dots show where you are in the bar and the speaker button mutes the click
- On mobile it sits behind a single icon that pulses on the beat

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
