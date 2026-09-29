import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:pipe_and_wire_clean/rack_state.dart';
import 'dart:math' as math;

const _distance = 66.0;
const _vertical = 6.0;
const _horizontal = 8.0;
const _angle = 30.0;
const _overall = 110.0;
const _clr = 4.0;
const _deduct = 5.0;
const _pipeOD = 0.706;

RackState _buildRack({
  required bool rolling,
  required bending_data.BendingMethod method,
  required bool arrow,
  required bool reverse,
  required bending_data.OffsetLayoutDirection direction,
}) {
  final rack = RackState();
  rack.setPipeProgressionOffsets(<double>[0.0], sizes: <String>['1/2"']);
  rack.setCalcMode(
    rolling ? RackCalcMode.rollingOffset : RackCalcMode.parallelOffset,
  );
  rack.setParallel90BenderData(
    gain: 2.5,
    takeup: _deduct,
    clr: _clr,
    pipeOD: _pipeOD,
  );
  rack.setBendingMethod(method, arrow: arrow, reverse: reverse);
  if (rolling) {
    rack.setRollingOffsetInputs(
      distanceToObstruction: _distance,
      verticalOffset: _vertical,
      horizontalOffset: _horizontal,
      overallLengthValue: _overall,
      bendAngleValue: _angle,
      layoutDirection: direction,
    );
  } else {
    rack.setOffsetInputs(
      distanceToObstruction: _distance,
      offsetHeightValue: _vertical,
      overallLengthValue: _overall,
      bendAngleValue: _angle,
      layoutDirection: direction,
    );
  }
  return rack;
}

({double markA, double markB, double cut}) _standaloneResult({
  required bool rolling,
  required bending_data.BendingMethod method,
  required bool arrow,
  required bool reverse,
  required bending_data.OffsetLayoutDirection direction,
}) {
  final layout = bending_data.calculateOffsetLayout(
    verticalOffset: _vertical,
    horizontalRoll: rolling ? _horizontal : 0.0,
    angleDeg: _angle,
    distanceToObstruction: _distance,
    requestedFinishedOverallLength: _overall,
    layoutDirection: direction,
  );
  if (arrow) {
    return (markA: layout.markA, markB: layout.markB, cut: layout.cutLength);
  }

  final centers = bending_data.calculateOffsetCenterMarks(
    layout: layout,
    layoutDirection: direction,
    clr: _clr,
    angleDeg: _angle,
  );
  return (
    markA: bending_data.convertCenterMarkToBenderReference(
      centerMark: centers.markA,
      method: method,
      clr: _clr,
      deduct: _deduct,
      pipeOD: _pipeOD,
      angleDeg: _angle,
      reverse: reverse,
    ),
    markB: bending_data.convertCenterMarkToBenderReference(
      centerMark: centers.markB,
      method: method,
      clr: _clr,
      deduct: _deduct,
      pipeOD: _pipeOD,
      angleDeg: _angle,
      reverse: reverse,
    ),
    cut: layout.cutLength,
  );
}

void main() {
  group('standalone Offset to Rack Builder Pipe 1 parity', () {
    for (final rolling in <bool>[false, true]) {
      for (final direction in bending_data.OffsetLayoutDirection.values) {
        for (final method in bending_data.BendingMethod.values) {
          for (final reverse in <bool>[false, true]) {
            final arrow = method == bending_data.BendingMethod.centerline &&
                reverse == false;
            test(
              '${rolling ? 'Rolling' : 'Standard'} ${direction.name} ${arrow ? 'Arrow' : method.name} ${reverse ? 'Reverse' : 'Forward'}',
              () {
                final rack = _buildRack(
                  rolling: rolling,
                  method: method,
                  arrow: arrow,
                  reverse: reverse,
                  direction: direction,
                );
                final expected = _standaloneResult(
                  rolling: rolling,
                  method: method,
                  arrow: arrow,
                  reverse: reverse,
                  direction: direction,
                );
                final pipe = rack.allConduits.first;

                expect(pipe.markA, closeTo(expected.markA, 0.000001));
                expect(pipe.markB, closeTo(expected.markB, 0.000001));
                expect(pipe.ol, closeTo(expected.cut, 0.000001));
              },
            );
          }
        }
      }
    }
  });

  group('Rolling Offset direction selection', () {
    test('preserves Rolling mode for every rack direction', () {
      final rack = _buildRack(
        rolling: true,
        method: bending_data.BendingMethod.centerline,
        arrow: true,
        reverse: false,
        direction: bending_data.OffsetLayoutDirection.towardObstruction,
      );

      for (final direction in <int>[-1, 0, 1, 2]) {
        rack.setOffsetDirection(direction);

        expect(rack.calcMode, RackCalcMode.rollingOffset);
        expect(rack.offsetDirectionSign, direction);
        expect(rack.allConduits.first.markA, isNot(0.0));
        expect(rack.allConduits.first.markB, isNot(0.0));
      }
    });

    test('rejects an unknown rack direction', () {
      final rack = RackState();

      expect(() => rack.setOffsetDirection(99), throwsArgumentError);
    });
  });

  group('Parallel Rolling Offset graduation', () {
    RackState buildThreePipeRack({
      required int rackDirection,
      required bool arrow,
    }) {
      final rack = RackState();
      rack.setPipeProgressionOffsets(
        <double>[0.0, 2.0, 4.0],
        sizes: <String>['1/2"', '1/2"', '1/2"'],
      );
      rack.setCalcMode(RackCalcMode.rollingOffset);
      rack.setParallel90BenderData(
        gain: 2.5,
        takeup: _deduct,
        clr: _clr,
        pipeOD: _pipeOD,
      );
      rack.setBendingMethod(
        bending_data.BendingMethod.notch,
        arrow: arrow,
        reverse: false,
      );
      rack.setOffsetDirection(rackDirection);
      rack.setRollingOffsetInputs(
        distanceToObstruction: _distance,
        verticalOffset: _vertical,
        horizontalOffset: _horizontal,
        overallLengthValue: _overall,
        bendAngleValue: _angle,
        layoutDirection: bending_data.OffsetLayoutDirection.towardObstruction,
      );
      return rack;
    }

    for (final rackDirection in <int>[-1, 1]) {
      for (final arrow in <bool>[true, false]) {
        test(
          '${rackDirection == -1 ? 'Left' : 'Right'} ${arrow ? 'Arrow' : 'Notch'} marks graduate by spacing times tan half-angle',
          () {
            final rack = buildThreePipeRack(
              rackDirection: rackDirection,
              arrow: arrow,
            );
            final pipes = rack.allConduits;
            final expectedStep =
                2.0 * math.tan((_angle / 2.0) * math.pi / 180.0);

            expect(pipes[1].markA - pipes[0].markA,
                closeTo(expectedStep, 0.000001));
            expect(pipes[1].markB - pipes[0].markB,
                closeTo(expectedStep, 0.000001));
            expect(pipes[2].markA - pipes[0].markA,
                closeTo(expectedStep * 2, 0.000001));
            expect(pipes[2].markB - pipes[0].markB,
                closeTo(expectedStep * 2, 0.000001));
            expect(pipes[1].ol, closeTo(pipes[0].ol, 0.000001));
            expect(pipes[2].ol, closeTo(pipes[0].ol, 0.000001));
          },
        );
      }
    }
  });
}
