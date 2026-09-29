import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as b;
import 'package:pipe_and_wire_clean/rack_state.dart';

void main() {
  test('two-inch advisory boundary uses hook reference', () {
    const clr = 7.0, od = 1.163, takeup = 8.0, angle = 30.0, stub = 36.0;
    final end = b.calculateCurveEnd(stub: stub, clr: clr, pipeOD: od);
    final shift = b.convertCenterMarkToFrontHookMark(centerMark: 0,
      deduct: takeup, clr: clr, pipeOD: od, angleDeg: angle);
    for (final distance in [1.99, 2.0, 2.01]) {
      expect(b.needsKickClearanceAdvisory(centerMark: end + distance - shift,
        stub: stub, clr: clr, pipeOD: od, deduct: takeup, angleDeg: angle), distance < 2);
    }
  });
  for (final style in Kick90RackStyle.values) {
    test('$style mixed benders: method-invariant advisory and saved warning', () {
      final results = <String?>[];
      for (final method in b.BendingMethod.values) {
        final r = RackState();
        r.setPipeProgressionOffsets([0, 3, 6], sizes: ['1"', '2"', '1"']);
        r.setPipeODs({0: 1.163, 1: 2.197, 2: 1.163});
        for (final machine in b.benderDatabase.where((v) => v.conduitType == b.ConduitType.emt &&
            ((v.brand == 'Ideal' && v.conduitSize == '1.0') ||
             (v.brand == 'Greenlee 1818' && v.conduitSize == '2.0')))) {
          r.assignBenderToSize(machine);
        }
        r.setCalcMode(RackCalcMode.kick90);
        r.setKick90Inputs(stub: 36, height: 1, angle: 30, leg: 60,
          matchBendDistance: 2, gain: 4.167, takeup: 8, clr: 7, pipeOD: 1.163,
          method: method, style: style);
        final marks = r.allConduits.map((p) => [p.markA, p.markB, p.ol]).toList();
        final warning = r.kickClearanceWarning;
        expect(warning, isNotNull);
        expect(warning, contains('Check bender fit'));
        expect(warning, isNot(contains('COLLISION')));
        results.add(warning);
        final saved = r.captureResult({});
        expect(saved.settings['kickClearanceWarning'], warning);
        expect(r.allConduits.map((p) => [p.markA, p.markB, p.ol]).toList(), marks);
      }
      expect(results.toSet().length, 1);
    });
  }
  test('ample hook separation has no advisory', () {
    expect(b.needsKickClearanceAdvisory(centerMark: 100, stub: 36,
      clr: 7, pipeOD: 1.163, deduct: 8, angleDeg: 30), isFalse);
  });
}
