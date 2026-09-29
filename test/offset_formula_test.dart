import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/bending_data.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';

void main() {
  group('current toward-obstruction offset layout', () {
    test('preserves standard offset marks, shrink, travel, and cut length', () {
      final result = calculateOffsetTowardLayout(
        verticalOffset: 6.0,
        angleDeg: 30.0,
        distanceToObstruction: 66.0,
        requestedFinishedOverallLength: 120.0,
      );

      expect(result.trueOffset, closeTo(6.0, 0.000001));
      expect(result.shrink, closeTo(1.6076951546, 0.000001));
      expect(result.distanceBetweenBends, closeTo(12.0, 0.000001));
      expect(result.markA, closeTo(67.6076951546, 0.000001));
      expect(result.markB, closeTo(55.6076951546, 0.000001));
      expect(result.cutLength, closeTo(121.6076951546, 0.000001));
      expect(result.finishedOverallLength, closeTo(120.0, 0.000001));
    });

    test('preserves rolling offset use of the true offset', () {
      final result = calculateOffsetTowardLayout(
        verticalOffset: 6.0,
        horizontalRoll: 8.0,
        angleDeg: 30.0,
        distanceToObstruction: 66.0,
        requestedFinishedOverallLength: 120.0,
      );

      expect(result.trueOffset, closeTo(10.0, 0.000001));
      expect(result.shrink, closeTo(2.6794919243, 0.000001));
      expect(result.distanceBetweenBends, closeTo(20.0, 0.000001));
      expect(result.markA, closeTo(68.6794919243, 0.000001));
      expect(result.markB, closeTo(48.6794919243, 0.000001));
      expect(result.cutLength, closeTo(122.6794919243, 0.000001));
    });

    test('matches the field-reported Ideal notch rolling-offset marks', () {
      const idealHalfInchEmtClr = 4.34375;
      const idealHalfInchEmtDeduct = 5.0;
      const halfInchEmtOd = 0.706;
      final layout = calculateOffsetTowardLayout(
        verticalOffset: 6.0,
        horizontalRoll: 3.0,
        angleDeg: 30.0,
        distanceToObstruction: 65.0,
        requestedFinishedOverallLength: 100.0,
      );
      final centers = calculateOffsetCenterMarks(
        layout: layout,
        layoutDirection: OffsetLayoutDirection.towardObstruction,
        clr: idealHalfInchEmtClr,
        angleDeg: 30.0,
      );
      final markA = convertCenterMarkToBenderReference(
        centerMark: centers.markA,
        method: BendingMethod.notch,
        clr: idealHalfInchEmtClr,
        deduct: idealHalfInchEmtDeduct,
        pipeOD: halfInchEmtOd,
        angleDeg: 30.0,
      );
      final markB = convertCenterMarkToBenderReference(
        centerMark: centers.markB,
        method: BendingMethod.notch,
        clr: idealHalfInchEmtClr,
        deduct: idealHalfInchEmtDeduct,
        pipeOD: halfInchEmtOd,
        angleDeg: 30.0,
      );

      expect(layout.trueOffset, closeTo(6.7082039325, 0.000001));
      expect(layout.shrink, closeTo(1.7974578264, 0.000001));
      expect(layout.distanceBetweenBends, closeTo(13.4164078650, 0.000001));
      expect(markA, closeTo(66.2288622810, 0.000001));
      expect(markB, closeTo(52.8124544160, 0.000001));
      expect(layout.cutLength, closeTo(101.7974578264, 0.000001));
      expect(RackState.inchFmt(markA), '66 1/4"');
      expect(RackState.inchFmt(markB), '52 13/16"');
      expect(RackState.inchFmt(layout.cutLength), '101 13/16"');
    });

    test('preserves full-stick cut length and finished distance', () {
      final result = calculateOffsetTowardLayout(
        verticalOffset: 6.0,
        angleDeg: 30.0,
        distanceToObstruction: 66.0,
        requestedFinishedOverallLength: 0.0,
        useFullStick: true,
      );

      expect(result.cutLength, closeTo(120.0, 0.000001));
      expect(result.finishedOverallLength, closeTo(118.3923048454, 0.000001));
      expect(result.markA, closeTo(67.6076951546, 0.000001));
      expect(result.markB, closeTo(55.6076951546, 0.000001));
    });
  });

  group('past-obstruction offset layout', () {
    test('controls the near bend and adds travel to locate the far bend', () {
      final result = calculateOffsetLayout(
        verticalOffset: 6.0,
        angleDeg: 30.0,
        distanceToObstruction: 66.0,
        requestedFinishedOverallLength: 120.0,
        layoutDirection: OffsetLayoutDirection.pastObstruction,
      );

      expect(result.trueOffset, closeTo(6.0, 0.000001));
      expect(result.shrink, closeTo(1.6076951546, 0.000001));
      expect(result.distanceBetweenBends, closeTo(12.0, 0.000001));
      expect(result.markB, closeTo(66.0, 0.000001));
      expect(result.markA, closeTo(78.0, 0.000001));
      expect(result.cutLength, closeTo(121.6076951546, 0.000001));
    });

    test('uses rolling true offset before locating past-obstruction marks', () {
      final result = calculateOffsetLayout(
        verticalOffset: 6.0,
        horizontalRoll: 8.0,
        angleDeg: 30.0,
        distanceToObstruction: 66.0,
        requestedFinishedOverallLength: 120.0,
        layoutDirection: OffsetLayoutDirection.pastObstruction,
      );

      expect(result.trueOffset, closeTo(10.0, 0.000001));
      expect(result.markB, closeTo(66.0, 0.000001));
      expect(result.markA, closeTo(86.0, 0.000001));
    });

    test('adds radius adjustment for past and subtracts it for toward', () {
      final toward = calculateOffsetTowardLayout(
        verticalOffset: 6.0,
        angleDeg: 30.0,
        distanceToObstruction: 66.0,
        requestedFinishedOverallLength: 120.0,
      );
      final past = calculateOffsetLayout(
        verticalOffset: 6.0,
        angleDeg: 30.0,
        distanceToObstruction: 66.0,
        requestedFinishedOverallLength: 120.0,
        layoutDirection: OffsetLayoutDirection.pastObstruction,
      );

      final towardCenters = calculateOffsetCenterMarks(
        layout: toward,
        layoutDirection: OffsetLayoutDirection.towardObstruction,
        clr: 5.0,
        angleDeg: 30.0,
      );
      final pastCenters = calculateOffsetCenterMarks(
        layout: past,
        layoutDirection: OffsetLayoutDirection.pastObstruction,
        clr: 5.0,
        angleDeg: 30.0,
      );

      expect(towardCenters.radiusAdjustment, closeTo(1.3089969390, 0.000001));
      expect(towardCenters.markA, closeTo(66.2986982156, 0.000001));
      expect(towardCenters.markB, closeTo(54.2986982156, 0.000001));
      expect(pastCenters.markA, closeTo(79.3089969390, 0.000001));
      expect(pastCenters.markB, closeTo(67.3089969390, 0.000001));
    });
  });

  group('offset bender-reference conversion', () {
    const centerMark = 20.0;
    const clr = 5.0;
    const angle = 30.0;
    const deduct = 11.0;
    const pipeOD = 0.706;

    test('centerline is unchanged by Forward or Reverse orientation', () {
      final forward = convertCenterMarkToBenderReference(
        centerMark: centerMark,
        method: BendingMethod.centerline,
        clr: clr,
        deduct: deduct,
        pipeOD: pipeOD,
        angleDeg: angle,
      );
      final reverse = convertCenterMarkToBenderReference(
        centerMark: centerMark,
        method: BendingMethod.centerline,
        clr: clr,
        deduct: deduct,
        pipeOD: pipeOD,
        angleDeg: angle,
        reverse: true,
      );

      expect(forward, closeTo(centerMark, 0.000001));
      expect(reverse, closeTo(centerMark, 0.000001));
    });

    test('Notch conversion reverses equally around the true center', () {
      final correction = calculate45NotchCorrection(
        clr: clr,
        angleDeg: angle,
      );
      final forward = convertCenterMarkToBenderReference(
        centerMark: centerMark,
        method: BendingMethod.notch,
        clr: clr,
        deduct: deduct,
        pipeOD: pipeOD,
        angleDeg: angle,
      );
      final reverse = convertCenterMarkToBenderReference(
        centerMark: centerMark,
        method: BendingMethod.notch,
        clr: clr,
        deduct: deduct,
        pipeOD: pipeOD,
        angleDeg: angle,
        reverse: true,
      );

      expect(forward, closeTo(centerMark + correction, 0.000001));
      expect(reverse, closeTo(centerMark - correction, 0.000001));
      expect((forward + reverse) / 2.0, closeTo(centerMark, 0.000001));
    });

    test('Hook conversion reverses equally around the true center', () {
      final adjustment = calculateFrontHookAdjustment(
        deduct: deduct,
        clr: clr,
        pipeOD: pipeOD,
        angleDeg: angle,
      );
      final forward = convertCenterMarkToBenderReference(
        centerMark: centerMark,
        method: BendingMethod.hook,
        clr: clr,
        deduct: deduct,
        pipeOD: pipeOD,
        angleDeg: angle,
      );
      final reverse = convertCenterMarkToBenderReference(
        centerMark: centerMark,
        method: BendingMethod.hook,
        clr: clr,
        deduct: deduct,
        pipeOD: pipeOD,
        angleDeg: angle,
        reverse: true,
      );

      expect(forward, closeTo(centerMark + adjustment, 0.000001));
      expect(reverse, closeTo(centerMark - adjustment, 0.000001));
      expect((forward + reverse) / 2.0, closeTo(centerMark, 0.000001));
    });

    test('reference conversion preserves A/B order and bend spacing', () {
      for (final direction in OffsetLayoutDirection.values) {
        final layout = calculateOffsetLayout(
          verticalOffset: 6.0,
          angleDeg: angle,
          distanceToObstruction: 66.0,
          requestedFinishedOverallLength: 120.0,
          layoutDirection: direction,
        );
        final centers = calculateOffsetCenterMarks(
          layout: layout,
          layoutDirection: direction,
          clr: clr,
          angleDeg: angle,
        );

        for (final method in BendingMethod.values) {
          for (final reverse in [false, true]) {
            final markA = convertCenterMarkToBenderReference(
              centerMark: centers.markA,
              method: method,
              clr: clr,
              deduct: deduct,
              pipeOD: pipeOD,
              angleDeg: angle,
              reverse: reverse,
            );
            final markB = convertCenterMarkToBenderReference(
              centerMark: centers.markB,
              method: method,
              clr: clr,
              deduct: deduct,
              pipeOD: pipeOD,
              angleDeg: angle,
              reverse: reverse,
            );

            expect(markA, greaterThan(markB));
            expect(
              markA - markB,
              closeTo(layout.distanceBetweenBends, 0.000001),
            );
          }
        }
      }
    });
  });
}
