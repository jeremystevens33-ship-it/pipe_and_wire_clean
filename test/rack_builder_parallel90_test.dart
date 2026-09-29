import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';

RackState buildRack(List<double> offsets, {String direction = 'right'}) {
  final rack = RackState();
  rack.setPipeProgressionOffsets(offsets,
      sizes: List.filled(offsets.length, '1"'));
  rack.setParallel90Direction(direction);
  rack.setParallel90BenderData(gain: 4, takeup: 9.5);
  rack.setStubLength(66);
  rack.setLegLength(54);
  return rack;
}

void main() {
  test('reported 66-inch stub and 2 5/16 centers reproduce overflow', () {
    final rack = buildRack([0, 2.3125, 4.625]);
    expect(rack.allConduits.map((p) => p.ol), [116, 120.625, 125.25]);
    expect(rack.allConduits.map((p) => p.markA), [44.5, 46.8125, 49.125]);
    rack.setLegLength(rack.parallel90MaxLegLength);
    expect(rack.allConduits.map((p) => p.ol), [110.75, 115.375, 120]);
    expect(rack.stubLength, 66);
  });

  for (final direction in ['left', 'right', 'up', 'down']) {
    for (final count in [3, 6]) {
      test('MAX PIPE uses result lengths for $direction, $count pipes', () {
        final rack = buildRack(
            List.generate(count, (i) => i * 2.315), direction: direction);
        rack.allConduits[1].benderGain = 2;
        rack.forceRefresh();
        rack.setLegLength(rack.parallel90MaxLegLength);
        expect(rack.allConduits.map((p) => p.ol).reduce(math.max),
            closeTo(120, 0.000001));
      });
    }
  }
}
