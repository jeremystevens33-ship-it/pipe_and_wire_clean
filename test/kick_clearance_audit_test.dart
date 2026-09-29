import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as b;

// Characterization of the existing warning, not validation of physical clearance.
void main() {
  final machines = [
    b.benderDatabase.firstWhere((v) => v.brand == 'Ideal' && v.conduitSize == '1.0' && v.conduitType == b.ConduitType.emt),
    b.benderDatabase.firstWhere((v) => v.brand == 'Greenlee 1818' && v.conduitSize == '2.0' && v.conduitType == b.ConduitType.emt),
  ];
  double gap(b.Bender machine, double height, double angle, b.BendingMethod method) =>
      b.calculateKick90MarkB(stub: 36, kickHeight: height, angleDeg: angle,
          gain90: machine.gain, pipeOD: b.emtOD[machine.conduitSize]!,
          clr: machine.clr, deduct: machine.deduct, method: method) -
      b.calculateCurveEnd(stub: 36, clr: machine.clr, pipeOD: b.emtOD[machine.conduitSize]!);

  test('existing trigger accepts a gap below its five-inch suggestion target', () {
    expect(b.isBenderClearanceSafe(markB: 101, curveEnd: 100, buffer: .5), isTrue);
    expect(b.isBenderClearanceSafe(markB: 101, curveEnd: 100, buffer: 5), isFalse);
    expect(b.isBenderClearanceSafe(markB: 100.5, curveEnd: 100), isTrue);
    expect(b.isBenderClearanceSafe(markB: 100.499, curveEnd: 100), isFalse);
  });
  for (final machine in machines) {
    test('${machine.brand} ${machine.conduitSize}: warning can depend on mark reference', () {
      bool found = false;
      for (double h = .25; h <= 12 && !found; h += .25) {
        for (final angle in [10.0, 22.5, 30.0, 45.0, 60.0]) {
          final gaps = {for (final method in b.BendingMethod.values) method.name: gap(machine, h, angle, method)};
          final decisions = gaps.values.map((v) => v >= .5).toSet();
          if (decisions.length > 1) {
            print('${machine.brand}: height=$h angle=$angle reference gaps=$gaps');
            found = true;
            break;
          }
        }
      }
      expect(found, isTrue, reason: 'Same geometry gets different warning decisions');
    });
    test('${machine.brand}: existing fallback may suggest a failing angle', () {
      const height = .01;
      for (final method in b.BendingMethod.values) {
        expect(gap(machine, height, 30, method), lessThan(.5));
        double suggested = 30;
        bool found = false;
        while (suggested > 1) {
          suggested -= .5;
          if (gap(machine, height, suggested, method) >= 5) { found = true; break; }
        }
        print('${machine.brand} ${method.name}: returned angle=$suggested, target met=$found, gap=${gap(machine, height, suggested, method)}');
        expect(found, isFalse);
        expect(suggested, 1);
        expect(gap(machine, height, suggested, method), lessThan(5));
      }
    });
  }
}
