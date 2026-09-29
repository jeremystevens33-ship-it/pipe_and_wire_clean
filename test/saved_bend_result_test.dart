import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';
import 'package:pipe_and_wire_clean/rack_builder_11.dart';

void main() {
  Map<String, String> presentation(String view) => {
    'view': view, 'style': 'Across', 'kickDirection': 'left',
    'kickVertical': 'up', 'asset': 'assets/images/rack_builder/parallel_90s_left.png',
    'spacingMode': 'Center to center', 'enteredSpacing': '2"',
  };

  test('saved values survive source edits, segment copies and isolated selection', () {
    final rack = RackState();
    rack.setPipeProgressionOffsets([0, 2], sizes: ['1/2"', '1/2"']);
    rack.setStubLength(66);
    rack.setLegLength(40);
    final saved = rack.captureResult(presentation('parallel90'));
    final original = saved.pipes.last.markC;
    rack.addBendSegment('90', 90, 106, savedResult: saved);
    rack.updateSegment(0, label: 'Renamed');
    expect(identical(rack.runSequence.single.savedResult, saved), isTrue);
    rack.setStubLength(20);
    rack.allConduits.last.ol = 999;
    expect(saved.pipes.last.markC, original);
    expect(() => saved.inputs['Stub'] = 999, throwsUnsupportedError);
    expect(() => saved.pipes.clear(), throwsUnsupportedError);
    final isolated = RackState.fromSavedResult(saved)..select(1);
    expect(isolated.current.ol, original);
    expect(rack.selectedPipeIndex, 0);
    expect(isolated.runSequence, isEmpty);
    rack.clearRunSequence();
    expect(saved.inputs['Stub'], 66);
  });

  for (final mode in [RackCalcMode.parallel90, RackCalcMode.offset,
    RackCalcMode.rollingOffset, RackCalcMode.kick90]) {
    testWidgets('saved ${mode.name} displays frozen marks and selects Pipe 6', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rack = RackState();
      rack.setPipeProgressionOffsets(List.generate(6, (i) => i * 2.0),
        sizes: List.filled(6, '1/2"'));
      rack.setCalcMode(mode);
      for (var i = 0; i < 6; i++) {
        rack.allConduits[i].markA = 30.0 + i;
        rack.allConduits[i].markB = 50.0 + i;
        rack.allConduits[i].ol = 100.0 + i;
      }
      final saved = rack.captureResult(presentation(mode == RackCalcMode.parallel90
        ? 'parallel90' : mode == RackCalcMode.kick90 ? 'kick90' : 'offset'));
      await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider(
        create: (_) => RackState.fromSavedResult(saved),
        child: RackBuilderScreen(savedResult: saved))));
      await tester.pumpAndSettle();
      expect(find.text('Saved results • Read-only'), findsOneWidget);
      if (mode == RackCalcMode.kick90) {
        // Legacy snapshots keep their marks but display the renamed Kick style.
        expect(find.text('Saved Kick 90 — Parallel'), findsOneWidget);
        expect(find.text('Saved Kick 90 — Across'), findsNothing);
      }
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pipe 6'));
      await tester.pumpAndSettle();
      expect(find.text('105"'), findsWidgets);
      expect(rack.selectedPipeIndex, 0);
      expect(rack.runSequence, isEmpty);

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
