import 'package:piano_app/common/constants.dart';
import 'package:piano_app/common/logic/voice_leading/voice_leader.dart';
import 'package:piano_app/domain/key_signature_reference.dart';

class ChordStep {
  ChordStep({required this.rootPc, this.type = '', this.inversion = 0});

  int rootPc;
  String type;
  int inversion;

  String label({bool useFlats = false, KeySignatureReference? keySignature}) {
    final root = Constants.noteName(
      rootPc,
      useFlats: useFlats,
      keySignature: keySignature,
    );
    return '$root$type';
  }

  ChordSpec? get spec => ChordSpec.fromType(rootPc, type);
}
