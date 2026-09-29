/// Immutable values captured at commit time, never recalculated during review.
class SavedPipeResult {
  final String size, conduitType;
  final double markA, markB, markC, markD, angle;
  final bool measureFromTail;
  final String? bender;
  final double gain, takeup, clr, od;
  const SavedPipeResult({required this.size, required this.conduitType,
    required this.markA, required this.markB, required this.markC,
    required this.markD, required this.angle, required this.measureFromTail,
    required this.bender, required this.gain, required this.takeup,
    required this.clr, required this.od});
}

class SavedBendResult {
  final String mode;
  final List<SavedPipeResult> pipes;
  final List<double> progression;
  final Map<String, double> inputs;
  final Map<String, String> settings;
  SavedBendResult({required this.mode, required List<SavedPipeResult> pipes,
    required List<double> progression, required Map<String, double> inputs,
    required Map<String, String> settings})
    : pipes = List.unmodifiable(pipes), progression = List.unmodifiable(progression),
      inputs = Map.unmodifiable(inputs), settings = Map.unmodifiable(settings);
}
