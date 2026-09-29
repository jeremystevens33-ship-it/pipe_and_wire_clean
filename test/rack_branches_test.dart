import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/rack_branches.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';

RackBranches project(RackState rack) => RackBranches(RackBranch(name: 'Main Rack',
    rack: rack, spacing: 2, centerToCenter: true, conduitType: 'EMT', benders: {}, strutLength: 24));
RackBranch split(RackBranches work, int from, String name, List<int> selected) =>
    work.split(from: from, name: name, selected: selected, spacing: 2,
      centerToCenter: true, conduitType: 'EMT', benders: {}, strutLength: 0);

void main() {
  test('nine pipes split five/four, shared materials count once, paths join independently', () {
    final rack = RackState();
    rack.setPipeProgressionOffsets(List.generate(9, (i) => i * 2.0), sizes: List.filled(9, '1/2"'));
    rack.addBendSegment('90', 90, 100, multiplier: 9, stub: 50, leg: 50);
    final upstream = rack.runSequence.single;
    final work = project(rack);
    final left = split(work, 0, 'Left Rack', [0, 1, 2, 3, 4]);
    expect(rack.allConduits.length, 4);
    expect(left.rack.allConduits.length, 5);
    expect(left.rack.runSequence.single.id, same(upstream.id));
    rack.addStraightSegment(120, multiplier: 4);
    left.rack.addStraightSegment(120, multiplier: 5);
    expect(work.materials.sticks, 18);
    expect(work.materials.couplings, 9);
    expect(rack.runSequence.first.multiplier, 9);
    left.rack.addFittingSegment('Pull Box', 0);
    left.rack.addStraightSegment(120, multiplier: 5);
    expect(work.materials.sticks, 23);
    expect(work.materials.couplings, 9);
    expect(work.materials.fittings, 1);
    expect(rack.runSequence.length, 2);
  });

  test('branch snapshots, gaps and supports remain isolated across nested splits', () {
    final rack = RackState();
    rack.setPipeProgressionOffsets([0, 2, 4, 6], sizes: List.filled(4, '1/2"'));
    rack.addBendSegment('90', 90, 100, multiplier: 4, stub: 50, leg: 50);
    final work = project(rack);
    final child = split(work, 0, 'Left', [0, 2, 3]);
    expect(child.rack.pipeProgressionOffsets, [0, 4, 6]);
    expect(rack.pipeProgressionOffsets, [0]);
    child.rack.addStraightSegment(100, multiplier: 3);
    child.rack.addPlannedSupport(150);
    expect(rack.supportPositions, isNot(contains(150)));
    final grandchild = split(work, 1, 'Up', [1]);
    grandchild.rack.addStraightSegment(100, multiplier: 1);
    child.rack.addStraightSegment(100, multiplier: 2);
    expect(work.materials.sticks, 10);
    expect(work.materials.couplings, 6);
    child.rack.removeSegment(0);
    expect(child.rack.runSequence.length, 3);
    expect(child.rack.moveSupport(0, 10), isFalse);
    child.rack.clearRunSequence();
    expect(child.rack.runSequence.length, 2);
    expect(grandchild.rack.runSequence.length, 3);
  });

  test('invalid split and duplicate names leave the project untouched', () {
    final rack = RackState();
    rack.setPipeProgressionOffsets([0, 2], sizes: ['1/2"', '1/2"']);
    final work = project(rack);
    expect(() => split(work, 0, 'Left', [0, 1]), throwsArgumentError);
    expect(() => split(work, 0, 'Main Rack', [0]), throwsArgumentError);
    expect(() => split(work, 0, '', [0]), throwsArgumentError);
    expect(work.branches.length, 1);
    expect(rack.allConduits.length, 2);
  });
}
