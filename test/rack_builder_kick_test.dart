import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:pipe_and_wire_clean/rack_state.dart';

RackState _buildKickRack({
  required Kick90RackStyle style,
  required int pipeCount,
  double stub = 36.0,
  double leg = 88.0,
}) {
  final rack = RackState();
  rack.setPipeProgressionOffsets(
    List<double>.generate(pipeCount, (index) => index * 2.0),
    sizes: List<String>.filled(pipeCount, '1/2"'),
  );
  rack.setCalcMode(RackCalcMode.kick90);
  rack.setKick90Inputs(
    stub: stub,
    height: 6.0,
    angle: 30.0,
    leg: leg,
    matchBendDistance: 24.0,
    gain: 5.0,
    takeup: 11.0,
    clr: 4.0,
    pipeOD: 0.706,
    method: bending_data.BendingMethod.notch,
    style: style,
    size: '1/2"',
  );
  return rack;
}

double _longestCut(RackState rack) => rack.allConduits
    .map((pipe) => pipe.ol)
    .where((length) => length.isFinite)
    .fold<double>(0.0, math.max);

void main() {
  test('Forward outward shifts preserve perpendicular center spacing', () {
    for (final angle in [7.0, 15.0, 30.0, 45.0, 60.0]) {
      final radians = angle * math.pi / 180;
      for (final spacing in [2.0, 4.0, 7.5]) {
        final mark = bending_data.calculateKick90ForwardMarkB(
          baseMarkB: 20, spacingOffset: spacing, angleDeg: angle);
        final shift = mark - 20;
        // Project the outward vertex displacement onto the outgoing normal.
        // This checks actual spacing, independently of the half-angle formula.
        final outgoingSpacing =
            shift * math.sin(radians) + spacing * math.cos(radians);
        expect(outgoingSpacing, closeTo(spacing, 0.000001));
        expect(shift, greaterThan(0));
      }
    }
  });
  test('Forward uses increasing B with constant A, cut and angle', () {
    final rack = _buildKickRack(style: Kick90RackStyle.perpendicular, pipeCount: 3);
    final first = rack.allConduits.first;
    // 2-inch centers at 30 degrees: 2 * tan(15 degrees).
    const shift = 0.5358983848622454;
    for (var i = 0; i < 3; i++) {
      final pipe = rack.allConduits[i];
      expect(pipe.markB, closeTo(first.markB + i * shift, 0.000001));
      expect(pipe.markA, first.markA);
      expect(pipe.ol, first.ol);
      expect(pipe.angle, first.angle);
    }
  });
  group('Rack Builder Kick fixed stub-end order', () {
    test('Across Mark A always comes from the stub when stub exceeds leg', () {
      final rack = _buildKickRack(
        style: Kick90RackStyle.parallel,
        pipeCount: 3,
        stub: 36.0,
        leg: 12.0,
      );

      for (final pipe in rack.allConduits) {
        expect(pipe.markA, closeTo(25.0, 0.000001));
        expect(pipe.measureFromTail, isTrue);
      }
    });
  });

  group('Rack Builder Kick MAX STUB calculation', () {
    for (final style in Kick90RackStyle.values) {
      for (final pipeCount in <int>[3, 6]) {
        test('${style.name} with $pipeCount pipes reaches a 120-inch maximum',
            () {
          final rack = _buildKickRack(style: style, pipeCount: pipeCount);
          final originalLongest = _longestCut(rack);
          expect(originalLongest, greaterThan(120.0));

          final optimizedStub = 36.0 + (120.0 - originalLongest);
          expect(optimizedStub, greaterThanOrEqualTo(11.0));

          rack.setKick90Inputs(
            stub: optimizedStub,
            height: 6.0,
            angle: 30.0,
            leg: 88.0,
            matchBendDistance: 24.0,
            gain: 5.0,
            takeup: 11.0,
            clr: 4.0,
            pipeOD: 0.706,
            method: bending_data.BendingMethod.notch,
            style: style,
            size: '1/2"',
          );

          expect(_longestCut(rack), closeTo(120.0, 0.000001));
        });
      }
    }
  });
}
