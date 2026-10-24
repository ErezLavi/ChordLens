import 'package:piano_app/domain/music_notation.dart';

class SelectedScale {
  SelectedScale({
    this.rootPc,
    this.type = 'major',
    List<NotePosition>? notes,
  }) : notes = notes ?? [];

  int? rootPc;
  String type;
  List<NotePosition> notes;

  void reset() {
    rootPc = null;
    type = 'major';
    notes = [];
  }
}