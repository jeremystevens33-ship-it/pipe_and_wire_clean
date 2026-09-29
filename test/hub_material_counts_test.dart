import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';
import 'package:pipe_and_wire_clean/saved_bend_result.dart';

void main() {
  test('separate stages join each pipe; pull box terminates all three paths', () {
    final rack = RackState();
    rack.addBendSegment('Rolling Offset', 60, 110, multiplier: 3);
    rack.addBendSegment('Rolling Offset', 60, 110, multiplier: 3);
    rack.addBendSegment('90', 90, 80, multiplier: 3);
    expect(rack.projectMaterialSummary.sticks, 9);
    expect(rack.projectMaterialSummary.couplings, 6);
    rack.addFittingSegment('Pull Box', 0);
    rack.addBendSegment('90', 90, 80, multiplier: 3);
    expect(rack.projectMaterialSummary.sticks, 12);
    expect(rack.projectMaterialSummary.couplings, 6);
    expect(rack.projectMaterialSummary.fittings, 1);
    rack.addStraightSegment(240, multiplier: 3);
    expect(rack.projectMaterialSummary.sticks, 18);
    expect(rack.projectMaterialSummary.couplings, 12);
  });

  test('uses each saved cut, not stage distance, with exact-stock tolerance', () {
    final rack = RackState();
    final saved = SavedBendResult(mode: 'parallel90', progression: [],
      inputs: {}, settings: {}, pipes: [
        for (final cut in [119.0, 120.0000001, 121.0])
          SavedPipeResult(size: '0.5', conduitType: 'emt', markA: 10,
            markB: 20, markC: cut, markD: 0, angle: 90,
            measureFromTail: false, bender: null, gain: 0, takeup: 0,
            clr: 0, od: 0),
      ]);
    rack.addBendSegment('90', 90, 200, multiplier: 3, savedResult: saved);
    expect(rack.projectMaterialSummary.sticks, 4);
    expect(rack.projectMaterialSummary.couplings, 1);
    expect(rack.projectMaterialSummary.footage, 40);
  });
}
