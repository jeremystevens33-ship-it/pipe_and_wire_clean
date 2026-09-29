import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';

void main() {
  test('Kick Hub follows incoming leg and outgoing stub without changing inputs', () {
    final rack = RackState();
    rack.addBendSegment('Kick 90', 120, 105.6875, stub: 40.6875, leg: 65);
    final stage = rack.runSequence.single;
    expect(stage.distanceBefore90, 65);
    expect(stage.distanceAfter90, 40.6875);
    expect(stage.stub, 40.6875);
    expect(stage.leg, 65);
    expect(rack.supportPositions, [41, 89]);
    expect(rack.hasCornerSupport(stage.id, incoming: true), isTrue);
    expect(rack.hasCornerSupport(stage.id, incoming: false), isTrue);
    expect(rack.supportRunLength, 105.6875);
    final renamed = stage.copyWith(label: 'Renamed');
    expect(renamed.stub, stage.stub);
    expect(renamed.distanceBefore90, 65);
    expect(renamed.distanceAfter90, 40.6875);
    expect(rack.moveSupport(0, 42), isTrue);
    expect(stage.inSupportOffset, 23);
  });
  test('legacy Kick recovers incoming leg from its stored total', () {
    final stage = RunSegment(type: RunSegmentType.bend, label: 'Kick 90',
        degrees: 120, length: 105.6875, stub: 40.6875);
    expect(stage.distanceBefore90, 65);
    expect(stage.distanceAfter90, 40.6875);
  });
  test('26 5/8 outgoing leg fits a 24-inch support regardless of cut gain', () {
    final rack = RackState();
    rack.addBendSegment('90', 90, 73.5, stub: 50, leg: 26.625);
    expect(rack.supportPositions, [26, 74]);
    expect(rack.hasCornerSupport(rack.runSequence.first.id, incoming: false), isTrue);
    expect(rack.supportRunLength, 76.625);
  });
  test('straight suggestions and planned supports persist as conduit extends', () {
    final rack = RackState();
    rack.addStraightSegment(240);
    expect(rack.supportPositions, [36, 84, 204]);
    rack.addPlannedSupport(288);
    expect(rack.supportPositions.last - rack.supportRunLength, 48);
    rack.addStraightSegment(120);
    expect(rack.supportPositions, [36, 84, 204, 288]);
    rack.addPlannedSupport(288);
    expect(rack.supportPositions.where((p) => p == 288).length, 1);
  });
  test('keep positions preserves even supports beyond resized/deleted conduit', () {
    final rack = RackState();
    rack.addStraightSegment(120);
    rack.addPlannedSupport(180);
    rack.updateSegment(0, length: 60);
    expect(rack.supportPositions, [36, 84, 180]);
    rack.removeSegment(0);
    expect(rack.supportPositions, [36, 84, 180]);
    expect(rack.supportRunLength, 0);
  });
  test('shift downstream removes supports in lost portion and shifts future plans', () {
    final rack = RackState();
    rack.addStraightSegment(120);
    rack.addPlannedSupport(180);
    rack.updateSegment(0, length: 60, moveDownstream: true);
    expect(rack.supportPositions, [36, 120]);
    rack.removeSegment(0, moveDownstream: true);
    expect(rack.supportPositions, [60]);
  });
}
