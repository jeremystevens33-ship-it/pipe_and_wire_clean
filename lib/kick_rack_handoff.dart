import 'bending_data.dart' as bending_data;

/// The inputs that produced a completed standalone Kick, not reconstructed marks.
class KickRackHandoff {
  final double stub, height, angle, leg;
  final double markA, markB, cut;
  final bending_data.Bender bender;
  final bending_data.BendingMethod method;
  final String? clearanceWarning;

  const KickRackHandoff({required this.stub, required this.height,
    required this.angle, required this.leg, required this.markA,
    required this.markB, required this.cut, required this.bender,
    required this.method, this.clearanceWarning});
}
