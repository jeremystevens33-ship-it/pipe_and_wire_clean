import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';
import 'package:pipe_and_wire_clean/rack_change_editor.dart';

void main() {
  test('nonadjacent continuing pipes preserve identity, overrides and history', () {
    final rack = RackState();
    rack.setPipeProgressionOffsets([0, 2, 4], sizes: ['1/2"', '3/4"', '1"']);
    final original = List.of(rack.allConduits);
    original[2].benderGain = 3.5;
    final saved = rack.captureResult({'view': 'parallel90'});
    rack.addBendSegment('90', 90, 60, multiplier: 3, savedResult: saved);
    final stage = rack.runSequence.single;
    rack.changeContinuingPipes([0, 2], ['1/2"', '1"']);
    rack.setPipeProgressionOffsets([0, 3], sizes: ['1/2"', '1"']);
    expect(rack.allConduits, [same(original[0]), same(original[2])]);
    expect(rack.allConduits[1].benderGain, 3.5);
    expect(rack.runSequence.single, same(stage));
    expect(stage.multiplier, 3);
    expect(saved.pipes.length, 3);
    expect(stage.pipeIds, original.map((p) => p.id));
  });

  test('new pipes do not inherit dropped pipe couplings; pull box resets paths', () {
    final rack = RackState();
    rack.setPipeProgressionOffsets([0, 2, 4], sizes: ['1/2"', '1/2"', '1/2"']);
    rack.addStraightSegment(60, multiplier: 3);
    rack.changeContinuingPipes([2, null], ['1/2"', '1/2"']);
    rack.setPipeProgressionOffsets([0, 2], sizes: ['1/2"', '1/2"']);
    rack.addStraightSegment(60, multiplier: 2);
    expect(rack.projectMaterialSummary.sticks, 5);
    expect(rack.projectMaterialSummary.couplings, 1);
    rack.addFittingSegment('Pull Box', 0);
    rack.addStraightSegment(60, multiplier: 2);
    expect(rack.projectMaterialSummary.sticks, 7);
    expect(rack.projectMaterialSummary.couplings, 1);
  });

  test('invalid selection is atomic; changing size starts a fresh pipe', () {
    final rack = RackState();
    rack.setPipeProgressionOffsets([0], sizes: ['1/2"']);
    final original = rack.allConduits.single;
    expect(() => rack.changeContinuingPipes([], []), throwsArgumentError);
    expect(() => rack.changeContinuingPipes([2], ['1/2"']), throwsArgumentError);
    expect(rack.allConduits.single, same(original));
    rack.changeContinuingPipes([0], ['1"']);
    expect(rack.allConduits.single.id, isNot(original.id));
  });

  testWidgets('rack editor validates empty selection and returns selected pipes', (tester) async {
    RackChange? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child:
      RackChangeEditor(sizes: const ['1/2"', '1"'], sizeOptions: const ['1/2"', '1"'],
        offsets: const [0, 3], spacing: 2, centerToCenter: false,
        outsideDiameter: (_) => 1, onApply: (value) => result = value,
        onCancel: () => result = null)))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-pipe-0')));
    await tester.tap(find.byKey(const ValueKey('continue-pipe-1')));
    await tester.tap(find.text('Apply Changes'));
    await tester.pump();
    expect(find.text('Keep at least one pipe.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('continue-pipe-1')));
    await tester.tap(find.text('Apply Changes'));
    await tester.pumpAndSettle();
    expect(result!.sources, [1]);
    expect(result!.sizes, ['1"']);
    expect(result!.strutLength, 4.25);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  test('middle removal retains its gap; outside removal trims only outer span', () {
    expect(continuingOffsets([0, 2, 4, 6], [0, 2, 3]), [0, 4, 6]);
    expect(continuingOffsets([0, 2, 4, 6], [1, 2]), [0, 2]);
    expect(continuingOffsets([0, 4, 6], [0, 2]), [0, 6]);
  });
}
