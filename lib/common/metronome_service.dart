import 'dart:async';

import 'package:flutter/services.dart';

/// Drives the `metronome` plugin as the single clock for progression playback.
///
/// The click is muted by dropping the volume to zero rather than stopping the
/// engine, so beats keep arriving while the sound is switched off.
///
/// Talks to the plugin's channels directly instead of its Dart facade. The
/// native handlers never reply to the void methods, so every future the facade
/// hands back hangs forever; the facade works around its own `init` that way
/// too, which leaves no way to know the engine exists before calling `play`.
/// Issuing the messages here keeps them in channel order — `init` is always
/// posted before `play`, so the engine is built by the time it is told to run.
class MetronomeService {
  MetronomeService({AssetBundle? assets}) : _assets = assets ?? rootBundle;

  static const MethodChannel _channel = MethodChannel('metronome');
  static const EventChannel _tickChannel = EventChannel('metronome_tick');

  static const String clickAsset = 'assets/audio/click.wav';
  static const String accentAsset = 'assets/audio/click_accent.wav';
  static const int beatsPerBar = 4;
  static const int sampleRate = 44100;
  static const int clickVolume = 70;

  final AssetBundle _assets;
  StreamSubscription<dynamic>? _tickSubscription;
  bool _initialized = false;

  /// [onBeat] receives the beat's index within the bar, counting from zero on
  /// the accented downbeat.
  Future<void> start({
    required int bpm,
    required bool clickAudible,
    required void Function(int beatInBar) onBeat,
  }) async {
    await _ensureInitialized(bpm: bpm, clickAudible: clickAudible);
    _tickSubscription ??= _tickChannel.receiveBroadcastStream().listen((event) {
      if (event is int) onBeat(event);
    });
    _send('setBPM', {'bpm': bpm});
    _send('setVolume', {'volume': _volumeOf(clickAudible)});
    _send('play');
  }

  Future<void> stop() async {
    await _tickSubscription?.cancel();
    _tickSubscription = null;
    if (_initialized) _send('stop');
  }

  Future<void> setBpm(int bpm) async {
    if (_initialized) _send('setBPM', {'bpm': bpm});
  }

  Future<void> setClickAudible(bool audible) async {
    if (_initialized) _send('setVolume', {'volume': _volumeOf(audible)});
  }

  Future<void> _ensureInitialized({
    required int bpm,
    required bool clickAudible,
  }) async {
    if (_initialized) return;
    final main = await _assets.load(clickAsset);
    final accented = await _assets.load(accentAsset);
    _send('init', {
      'mainFileBytes': main.buffer.asUint8List(),
      'accentedFileBytes': accented.buffer.asUint8List(),
      'bpm': bpm,
      'volume': _volumeOf(clickAudible),
      'enableTickCallback': true,
      'timeSignature': beatsPerBar,
      'sampleRate': sampleRate,
      'manageAudioSession': true,
    });
    _initialized = true;
  }

  double _volumeOf(bool audible) => audible ? clickVolume / 100 : 0;

  void _send(String method, [Map<String, Object?>? arguments]) {
    unawaited(_channel.invokeMethod<void>(method, arguments));
  }

  Future<void> dispose() async {
    await stop();
    if (!_initialized) return;
    _initialized = false;
    _send('destroy');
  }
}
