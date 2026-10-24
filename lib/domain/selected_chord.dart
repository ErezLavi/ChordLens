import 'package:piano_app/domain/music_notation.dart';

class SelectedChord {
  SelectedChord({
    this.rootPc,
    this.type = '',
    this.inversion = 0,
    List<NotePosition>? notes,
  }) : notes = notes ?? [];
  
  int? rootPc;
  String type;
  int inversion;
  List<NotePosition> notes;

  void reset() {
    rootPc = null;
    type = '';
    inversion = 0;
    notes = [];
  }
}