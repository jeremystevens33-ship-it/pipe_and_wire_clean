import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';

void main() {
  test('skipped-start 66-inch Parallel 90 creates both corner supports after reset', () {
    final rack = RackState();
    rack.setIsFromBox(false);
    rack.addBendSegment('Kick 90', 120, 100, stub: 40, leg: 60);
    rack.removeSupport(0); // An authored prior layout must not suppress a new run.
    rack.clearRunSequence();
    rack.setIsFromBox(false);
    rack.addBendSegment('90° Rack', 90, 66 + 41.1875 - 2.570,
        stub: 66, leg: 41.1875, direction: 'left');
    final stage = rack.runSequence.single;
    expect(stage.isBoxTransition, isFalse);
    expect(rack.supportPositions, [42.0, 90.0]);
    expect(rack.hasCornerSupport(stage.id, incoming: true), isTrue);
    expect(rack.hasCornerSupport(stage.id, incoming: false), isTrue);
  });
  test('older Kick stages recover missing incoming leg without live inputs', () {
    final oldKick = RunSegment(type: RunSegmentType.bend,
        label: 'Kick 90', degrees: 105, length: 99, stub: 33);
    expect(oldKick.distanceBefore90, 66);
    expect(oldKick.distanceAfter90, 33);
    final newKick = RunSegment(type: RunSegmentType.bend,
        label: 'Kick 90', degrees: 105, length: 99, stub: 33, leg: 70);
    expect(newKick.distanceBefore90, 70);
    expect(newKick.distanceAfter90, 33);
    final offset = RunSegment(type: RunSegmentType.bend,
        label: 'Offset', degrees: 90, length: 99);
    expect(offset.distanceAfter90, isNull);
  });
  group('Construction Hub sequence integrity', () {
    test('first Kick gets before/after corner supports without a box origin', () {
      final rack = RackState();
      rack.setIsFromBox(false);
      rack.addBendSegment('Kick 90', 105, 99, stub: 33, leg: 66);
      final stage = rack.runSequence.single;
      expect(stage.has90Corner, isTrue);
      expect(rack.supportPositions, [42.0, 90.0]);
      expect(rack.hasCornerSupport(stage.id, incoming: true), isTrue);
      expect(rack.hasCornerSupport(stage.id, incoming: false), isTrue);
      expect(rack.getSupportLabel(42), contains('Before Turn'));
      expect(rack.getSupportLabel(90), contains('After Turn'));
      expect(rack.moveSupport(1, 93, moveDownstream: false), isTrue);
      expect(stage.outSupportOffset, 27);
      rack.removeSupport(1);
      rack.removeSupport(0);
      rack.addInitialHubSupport();
      expect(rack.supportPositions, [36.0]);
      expect(rack.getSupportLabel(36), 'Support (from Run Start)');
      expect(rack.runSequence.single.length - rack.supportPositions.last, 63);
      rack.setIsFromBox(true); // Later screen choices do not redefine this bend's origin.
      expect(rack.hubStartsAtBox, isFalse);
      rack.addInitialHubSupport();
      expect(rack.supportPositions, [36.0]);
    });

    test('actual box-start support keeps its box reference', () {
      final rack = RackState();
      rack.setIsFromBox(true);
      rack.addBendSegment('Box 90', 90, 78, stub: 12, leg: 66);
      rack.setIsFromBox(false);
      rack.addInitialHubSupport();
      expect(rack.hubStartsAtBox, isTrue);
      expect(rack.getSupportLabel(36), 'Vertical (from Box)');
    });

    test('removing either corner support hides only its diagram measurement', () {
      for (final incoming in [true, false]) {
        final rack = RackState();
        rack.addBendSegment('90', 90, 116, stub: 66, leg: 54);
        final id = rack.runSequence.single.id;
        rack.removeSupport(incoming ? 0 : 1);
        expect(rack.hasCornerSupport(id, incoming: incoming), isFalse);
        expect(rack.hasCornerSupport(id, incoming: !incoming), isTrue);
        rack.addBendSegment('Next 90', 90, 116, stub: 66, leg: 54);
        expect(rack.hasCornerSupport(id, incoming: incoming), isFalse);
        expect(rack.hasCornerSupport(id, incoming: !incoming), isTrue);
        rack.removeSupport(0);
        expect(rack.hasCornerSupport(id, incoming: true), isFalse);
        expect(rack.hasCornerSupport(id, incoming: false), isFalse);
      }
    });

    test('moving downstream preserves gaps, labels, and the authored layout', () {
      final rack = RackState();
      rack.addSupport(20, label: 'First');
      rack.addSupport(50, label: 'Second');
      rack.addSupport(80, label: 'Third');
      expect(rack.moveSupport(1, 60, moveDownstream: true), isTrue);
      expect(rack.supportPositions, [20, 60, 90]);
      expect(rack.getSupportLabel(90), 'Third');
      rack.recalculateSupports();
      expect(rack.supportPositions, [20, 60, 90]);
    });

    test('just this support leaves later supports fixed and rejects overlap', () {
      final rack = RackState();
      rack.addSupport(20);
      rack.addSupport(50);
      rack.addSupport(80);
      expect(rack.moveSupport(1, 60), isTrue);
      expect(rack.supportPositions, [20, 60, 80]);
      expect(rack.moveSupport(1, 80), isFalse);
      expect(rack.supportPositions, [20, 60, 80]);
    });

    test('corner edit moves downstream and keeps corner offsets consistent', () {
      final rack = RackState();
      rack.addBendSegment('90', 90, 116, stub: 66, leg: 54);
      rack.addSupport(110, label: 'Field');
      expect(rack.supportPositions, [42, 90, 110]);
      expect(rack.moveSupport(0, 38, moveDownstream: true), isTrue);
      expect(rack.supportPositions, [38, 86, 106]);
      expect(rack.runSequence.single.inSupportOffset, 28);
      expect(rack.runSequence.single.outSupportOffset, 20);
      rack.addBendSegment('Next 90', 90, 116, stub: 66, leg: 54);
      expect(rack.supportPositions.take(3), [38, 86, 106]);
    });

    test('stage identities survive insertion, removal, and editing', () {
      final rack = RackState();
      rack.addStraightSegment(10);
      rack.addStraightSegment(20);
      final selected = rack.runSequence.last.id;
      final expanded = {selected};
      rack.addStraightSegment(15, atIndex: 0);
      expect(rack.segmentIndex(selected), 2);
      rack.addStraightSegment(25, atIndex: 2);
      rack.removeSegment(0);
      expect(rack.segmentIndex(selected), 1);
      rack.updateSegment(rack.segmentIndex(selected)!, length: 30);
      expect(expanded.contains(rack.runSequence[1].id), isTrue);
      rack.removeSegment(1);
      expect(rack.segmentIndex(selected), isNull);
      expect(expanded.contains(rack.runSequence[1].id), isFalse);
      rack.clearRunSequence();
      rack.addStraightSegment(30);
      expect(rack.segmentIndex(selected), isNull);
    });

    test('commit identity updates current stage but allows identical new bends', () {
      final rack = RackState();
      final commit = Object();
      rack.addBendSegment('Offset', 60, 40, commitId: commit);
      rack.addStraightSegment(12);
      rack.addBendSegment('Offset', 60, 40, commitId: commit);
      expect(rack.runSequence.length, 2);
      rack.addBendSegment('Offset', 60, 40, commitId: Object(), atIndex: 0);
      expect(rack.runSequence.map((s) => s.type),
          [RunSegmentType.bend, RunSegmentType.bend, RunSegmentType.straight]);
      rack.addBendSegment('Offset', 60, 40);
      rack.addBendSegment('Offset', 60, 40);
      expect(rack.runSequence.length, 5);
    });

    test('recalculation refreshes snapshot and geometry while preserving authored supports', () {
      final rack = RackState();
      final token = Object();
      rack.addBendSegment('Kick 90', 120, 100, commitId: token,
          stub: 35, leg: 65, savedResult: rack.captureResult({'view': 'kick90'}));
      final id = rack.runSequence.single.id;
      rack.updateSegment(0, label: 'My kick');
      rack.runSequence.single.inSupportOffset = 18;
      rack.addPlannedSupport(42);
      final supports = List<double>.from(rack.supportPositions);
      rack.addStraightSegment(20);
      final snapshot = rack.captureResult({'view': 'kick90', 'revision': '2'});
      rack.addBendSegment('Kick 90', 135, 110, commitId: token,
          stub: 40, leg: 70, multiplier: 3, direction: 'left', savedResult: snapshot);
      expect(rack.runSequence.length, 2);
      final updated = rack.runSequence.first;
      expect(updated.id, same(id));
      expect(updated.label, 'My kick');
      expect(updated.savedResult, same(snapshot));
      expect(updated.length, 110);
      expect(updated.degrees, 135);
      expect(updated.distanceBefore90, 70);
      expect(updated.distanceAfter90, 40);
      expect(updated.multiplier, 3);
      expect(updated.direction, 'left');
      expect(updated.inSupportOffset, 18);
      expect(rack.supportPositions, containsAll(supports));
    });

    test('editing a segment preserves all non-edited metadata', () {
      final rack = RackState()..setIsFromBox(true);
      rack.addBendSegment(
        'Parallel 90',
        90,
        72,
        multiplier: 3,
        stub: 24,
        leg: 50,
        direction: 'left',
      );

      final original = rack.runSequence.single;
      original.inSupportOffset = 18;
      original.outSupportOffset = 30;

      rack.updateSegment(0, length: 84, label: 'Updated Parallel 90');

      final updated = rack.runSequence.single;
      expect(updated.label, 'Updated Parallel 90');
      expect(updated.length, 84);
      expect(updated.type, RunSegmentType.bend);
      expect(updated.degrees, 90);
      expect(updated.multiplier, 3);
      expect(updated.stub, 24);
      expect(updated.leg, 50);
      expect(updated.direction, 'left');
      expect(updated.inSupportOffset, 18);
      expect(updated.outSupportOffset, 30);
      expect(updated.isBoxTransition, isTrue);
    });

    test('moving a support preserves its existing label by default', () {
      final rack = RackState();
      rack.addSupport(48, label: 'Field support');

      rack.updateSupport(0, 54);

      expect(rack.supportPositions, [54]);
      expect(rack.getSupportLabel(48), isNull);
      expect(rack.getSupportLabel(54), 'Field support');
    });

    test('clearing the run also clears support labels', () {
      final rack = RackState();
      rack.addStraightSegment(96);
      rack.addSupport(50, label: 'Field support');

      rack.clearRunSequence();

      expect(rack.runSequence, isEmpty);
      expect(rack.supportPositions, isEmpty);
      expect(rack.getSupportLabel(50), isNull);
    });

    test('360 degrees reaches the limit and more than 360 exceeds it', () {
      final rack = RackState();
      for (var i = 0; i < 4; i++) {
        rack.addBendSegment('90 ${i + 1}', 90, 12 + i.toDouble());
      }
      expect(rack.totalRunDegrees, 360);

      rack.addBendSegment('Additional bend', 15, 20);
      expect(rack.totalRunDegrees, 375);
    });
  });
}
