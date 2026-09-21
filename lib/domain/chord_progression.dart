import 'package:piano_app/common/logic/voice_leading/voice_leader.dart';
import 'package:piano_app/domain/chord_step.dart';
import 'package:piano_app/domain/key_signature_reference.dart';

class ChordProgression {
  ChordProgression({
    List<ChordStep>? steps,
    this.voiceLeader = const VoiceLeader(),
  }) : _steps = steps ?? <ChordStep>[];

  final List<ChordStep> _steps;
  final VoiceLeader voiceLeader;

  int? _selectedIndex;
  int? _editingIndex;

  bool voiceLeadingEnabled = true;

  List<Voicing>? _voicings;

  List<ChordStep> get steps => List.unmodifiable(_steps);
  int get length => _steps.length;
  bool get isEmpty => _steps.isEmpty;

  int? get selectedIndex => _selectedIndex;
  int? get editingIndex => _editingIndex;
  bool get isEditing => _editingIndex != null;

  ChordStep? get selectedStep => _stepAt(_selectedIndex);
  ChordStep? get editingStep => _stepAt(_editingIndex);

  List<String> labels({
    bool useFlats = false,
    KeySignatureReference? keySignature,
  }) => [
    for (final step in _steps)
      step.label(useFlats: useFlats, keySignature: keySignature),
  ];

  void select(int index) {
    if (!_isValid(index)) return;
    _selectedIndex = index;
  }

  void clearSelection() {
    _selectedIndex = null;
    _editingIndex = null;
  }

  void beginEdit(int index) {
    if (!_isValid(index)) return;
    _editingIndex = index;
    _selectedIndex = index;
  }

  void doneEditing() => _editingIndex = null;

  void addStep() {
    final at = _selectedIndex == null ? _steps.length : _selectedIndex! + 1;
    _steps.insert(at, ChordStep(rootPc: 0));
    _invalidate();
    beginEdit(at);
  }

  void updateEditing({
    required int rootPc,
    required String type,
    required int inversion,
  }) {
    final step = editingStep;
    if (step == null) return;
    step
      ..rootPc = rootPc
      ..type = type
      ..inversion = inversion;
    _invalidate();
  }

  void removeEditing() {
    final index = _editingIndex;
    if (index == null) return;
    _steps.removeAt(index);
    _invalidate();
    if (_steps.isEmpty) {
      clearSelection();
      return;
    }
    beginEdit(index.clamp(0, _steps.length - 1));
  }

  Voicing? voiceLedVoicingAt(int index) {
    if (!voiceLeadingEnabled || !_isValid(index)) return null;
    return (_voicings ??= _solve()).elementAtOrNull(index);
  }

  List<Voicing> _solve() {
    final specs = <ChordSpec>[];
    for (final step in _steps) {
      final spec = step.spec;
      if (spec == null) return const [];
      specs.add(spec);
    }
    return voiceLeader.solve(specs).voicings;
  }

  void _invalidate() => _voicings = null;

  ChordStep? _stepAt(int? index) => _isValid(index) ? _steps[index!] : null;

  bool _isValid(int? index) =>
      index != null && index >= 0 && index < _steps.length;
}
