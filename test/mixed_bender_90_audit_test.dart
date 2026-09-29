import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as b;

void main() {
  test('six mixed EMT pipes retain assigned size-specific benders through MAX and selection', () {
    final rack = RackState();
    final sizes = ['2"', '2"', '2"', '1"', '1"', '1"'];
    final offsets = [0.0, 4.0095, 8.019, 11.5115, 14.487, 17.4625];
    final ideal = b.benderDatabase.firstWhere((v) => v.brand == 'Ideal' && v.conduitSize == '1.0' && v.conduitType == b.ConduitType.emt);
    final greenlee = b.benderDatabase.firstWhere((v) => v.brand == 'Greenlee 1818' && v.conduitSize == '2.0' && v.conduitType == b.ConduitType.emt);
    rack.setPipeProgressionOffsets(List.generate(6, (i) => i * 3.0), sizes: List.filled(6, '1"'));
    // Change the first pipe twice, then finish the user's three + three setup.
    rack.setPipeProgressionOffsets(offsets, sizes: sizes);
    rack.setPipeProgressionOffsets(offsets, sizes: ['1"', ...sizes.skip(1)]);
    rack.setPipeProgressionOffsets(offsets, sizes: sizes);
    void assign(int selected, b.Bender bender) {
      rack.select(selected);
      rack.assignBenderToSize(bender);
    }
    assign(3, ideal);
    assign(0, greenlee);
    rack.setIsFromBox(false);
    rack.setCalcMode(RackCalcMode.parallel90);
    rack.setParallel90Direction('left');
    rack.setStubLength(60);
    rack.setLegLength(29);
    rack.setLegLength(rack.parallel90MaxLegLength);
    for (var i = 0; i < 6; i++) {
      final p = rack.allConduits[i];
      print('P${i+1}: ${p.benderBrand}, takeup=${p.benderTakeup}, gain=${p.benderGain}, A=${RackState.inchFmt(p.markA)}, C=${RackState.inchFmt(p.ol)}');
    }
    for (var i = 0; i < 6; i++) {
      expect(rack.allConduits[i].benderTakeup, i < 3 ? 15 : 8, reason: 'P${i+1} take-up');
      final expectedA = [14.242, 18.2515, 22.261, 32.7535, 35.729, 38.7045][i];
      final expectedC = [83.097, 91.116, 99.135, 108.098, 114.049, 120.0][i];
      expect(rack.allConduits[i].markA, closeTo(expectedA, 1e-8));
      expect(rack.allConduits[i].ol, closeTo(expectedC, 1e-8));
    }
    for (var i = 5; i >= 0; i--) { rack.select(i); rack.forceRefresh(); }
    expect(rack.allConduits.last.ol, closeTo(120, 1e-8));
    expect(rack.parallel90Leg, closeTo(29.242, 1e-8));
    // Repeat a size edit after assignments, as well as before assignments.
    rack.setPipeProgressionOffsets(offsets, sizes: ['1"', ...sizes.skip(1)]);
    rack.assignBenderToSize(ideal);
    rack.assignBenderToSize(greenlee);
    expect(rack.allConduits.first.benderTakeup, 8);
    rack.setPipeProgressionOffsets(offsets, sizes: sizes);
    rack.assignBenderToSize(ideal);
    rack.assignBenderToSize(greenlee);
    expect(rack.allConduits.first.benderTakeup, 15);
    expect(rack.allConduits.last.benderTakeup, 8);
    expect(rack.allConduits.last.ol, closeTo(120, 1e-8));
  });
}
