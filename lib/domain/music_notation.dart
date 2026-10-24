/// The music-notation model this app is built on: pitch classes, accidentals,
/// note positions, ranges and clefs.
///
/// Adapted from the `piano` package (MIT), which is no longer maintained and
/// pinned itself to Dart `<3.13.5`. Only the model types are kept — the
/// package's widgets live here as `lib/custom_piano/`.
library;

export 'package:piano_app/domain/clef.dart';
export 'package:piano_app/domain/note_position.dart';
export 'package:piano_app/domain/note_range.dart';
