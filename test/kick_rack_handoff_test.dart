import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as b;
import 'package:pipe_and_wire_clean/kick_rack_handoff.dart';
import 'package:pipe_and_wire_clean/rack_builder_11.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';
import 'package:pipe_and_wire_clean/rack_change_editor.dart';

void main() {
  for (final method in b.BendingMethod.values) {
    for (final c2c in [true, false]) {
      testWidgets('Kick handoff preserves $method marks; c2c=$c2c', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Effective rounded gain differs from the database's 5.694.
        const bender = b.Bender(brand: 'Ideal', model: '74-066',
          conduitSize: '1.25', conduitType: b.ConduitType.emt,
          clr: 9.75, deduct: 11, gain: 5.6875);
        final a = b.calculateKick90MarkA(stub: 36, takeUp: 11);
        final markB = b.calculateKick90MarkB(stub: 36, kickHeight: 6,
          angleDeg: 30, gain90: bender.gain, pipeOD: 1.510,
          clr: bender.clr, deduct: 11, method: method);
        final cut = b.calculateKick90CutLength(stub: 36, leg: 60,
          kickHeight: 6, angleDeg: 30, gain90: bender.gain);
        final source = KickRackHandoff(stub: 36, height: 6, angle: 30, leg: 60,
          markA: a, markB: markB, cut: cut, bender: bender, method: method);
        final rack = RackState();
        await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(
          value: rack, child: RackBuilderScreen(initialKick: source,
            initialPipeCount: 3, initialPipeSizes: List.filled(3, '1 1/4"'),
            initialSpacing: 2, initialSpacingIsC2C: c2c,
            boxLayoutConduitType: 'EMT', initialIsArrowMethod: false))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('4. KICK MEASUREMENTS'), findsOneWidget);
        expect(rack.calcMode, RackCalcMode.kick90);
        expect(rack.isFromBox, isFalse);
        expect(rack.allConduits.length, 3);
        expect(rack.allConduits.first.benderBrand, 'Ideal');
        expect(rack.allConduits.first.benderGain, bender.gain);
        expect(rack.allConduits.first.markA, closeTo(a, 1e-9));
        expect(rack.allConduits.first.markB, closeTo(markB, 1e-9));
        expect(rack.allConduits.first.ol, closeTo(cut, 1e-9));
        expect(rack.pipeProgressionOffsets[1], closeTo(c2c ? 2 : 3.510, 1e-9));
        expect(rack.runSequence, isEmpty);
        await tester.ensureVisible(find.text('Same Angle 2'));
        await tester.tap(find.text('Same Angle 2'));
        await tester.pump();
        expect(rack.kick90RackStyle, Kick90RackStyle.sameAngleSamePlane);
        expect(rack.kickStubLength, 36);
        expect(rack.kickLegLength, 60);
        expect(rack.bendingMethod, method);
        await tester.ensureVisible(find.text('Continue').last);
        await tester.tap(find.text('Continue').last);
        await tester.pump();
        await tester.ensureVisible(find.text('MAX STUB').first);
        await tester.tap(find.text('MAX STUB').first);
        await tester.pump();
        final longest = rack.allConduits.map((p) => p.ol)
            .reduce((a, b) => a > b ? a : b);
        // Exercises the actual button and fractional field round trip. The
        // clear-gap cases formerly rounded the stub up beyond a full stick.
        expect(longest, closeTo(120, 1e-9));
        final exactStub = rack.kickStubLength;
        await tester.ensureVisible(find.text('Continue').last);
        await tester.tap(find.text('Continue').last);
        await tester.pump();
        expect(rack.kickStubLength, exactStub);
        expect(rack.allConduits.map((p) => p.ol)
            .reduce((a, b) => a > b ? a : b), closeTo(120, 1e-9));
        await tester.ensureVisible(find.text('CALCULATE'));
        await tester.tap(find.text('CALCULATE'));
        await tester.pump();
        expect(rack.runSequence.length, 1);
        expect(rack.runSequence.single.savedResult!.inputs['Kick stub'], exactStub);
        expect(rack.runSequence.single.savedResult!.pipes.map((p) => p.markC)
            .reduce((a, b) => a > b ? a : b), closeTo(120, 1e-9));
        expect(rack.allConduits.map((p) => p.ol)
            .reduce((a, b) => a > b ? a : b), closeTo(120, 1e-9));
        expect(rack.kickLegLength, 60);
        final stageId = rack.runSequence.single.id;
        // Back from Results and calculate again must replace this same stage.
        await tester.tap(find.byKey(const ValueKey('rack-back')));
        await tester.pump();
        await tester.ensureVisible(find.text('CALCULATE'));
        await tester.tap(find.text('CALCULATE'));
        await tester.pump();
        expect(rack.runSequence.length, 1);
        expect(rack.runSequence.single.id, same(stageId));
        expect(rack.runSequence.single.savedResult!.inputs['Kick stub'], exactStub);
        await tester.tap(find.byKey(const ValueKey('rack-next-bend')));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.ensureVisible(find.textContaining('LATEST RESULTS'));
        await tester.tap(find.textContaining('LATEST RESULTS'));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('rack-back')));
        await tester.pump();
        await tester.ensureVisible(find.text('CALCULATE'));
        await tester.tap(find.text('CALCULATE'));
        await tester.pump();
        expect(rack.runSequence.length, 1);
        expect(rack.runSequence.single.id, same(stageId));
        expect(find.textContaining('exceeds 10ft by'), findsNothing);
        if (method == b.BendingMethod.notch && c2c) {
          final originalStage = rack.runSequence.single;
          final originalPipes = List.of(rack.allConduits);
          await tester.tap(find.byKey(const ValueKey('rack-next-bend')));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.ensureVisible(find.text('CONTINUE / BRANCH / END PIPES'));
          await tester.tap(find.text('CONTINUE / BRANCH / END PIPES'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.ensureVisible(find.byKey(const ValueKey('continue-pipe-1')).first);
          await tester.tap(find.byKey(const ValueKey('continue-pipe-1')).first);
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('continue-pipe-1')).first);
          await tester.pump();
          await tester.ensureVisible(find.text('Apply'));
          await tester.tap(find.text('Apply'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(rack.allConduits.length, 2);
          expect(rack.allConduits.first.id, originalPipes[0].id);
          expect(rack.pipeProgressionOffsets, [0, 4]);
          expect(rack.runSequence.single, same(originalStage));
          expect(originalStage.savedResult!.pipes.length, 3);
          await tester.ensureVisible(find.text('ADD'));
          await tester.tap(find.text('ADD'));
          await tester.pump();
          expect(rack.runSequence.length, 2);
          expect(rack.runSequence.last.multiplier, 2);
          await tester.ensureVisible(find.text('CONTINUE / BRANCH / END PIPES'));
          await tester.tap(find.text('CONTINUE / BRANCH / END PIPES'));
          await tester.pump();
          tester.widget<RackSplitEditor>(find.byType(RackSplitEditor)).onCreate('Left Rack', [0]);
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.text('Main Rack'), findsOneWidget);
          expect(rack.allConduits.length, 1);
          await tester.ensureVisible(find.text('ADD'));
          await tester.tap(find.text('ADD'));
          await tester.pump();
          // The new branch has its own stage; the main rack does not receive it.
          expect(rack.runSequence.length, 2);
          await tester.ensureVisible(find.text('Main Rack'));
          await tester.tap(find.text('Main Rack'));
          await tester.pump();
          expect(rack.runSequence.length, 2);
          await tester.ensureVisible(find.text('Left Rack'));
          await tester.tap(find.text('Left Rack'));
          await tester.pump();
          await tester.ensureVisible(find.text('Main Rack'));
          await tester.tap(find.text('Main Rack'));
          await tester.pump();
          await tester.ensureVisible(find.textContaining('LATEST RESULTS'));
          await tester.tap(find.textContaining('LATEST RESULTS'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(rack.allConduits.length, 1);
          expect(rack.runSequence.first, same(originalStage));
          // Return from saved review, then choose a genuinely new 90.
          await tester.pageBack();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          rack.setStubLength(66);
          rack.setLegLength(45.1875);
          await tester.pump();
          await tester.ensureVisible(find.text('90s'));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(find.text('90s'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(rack.stubLength, 0);
          expect(rack.legLength, 0);
          expect(rack.runSequence.first, same(originalStage));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 4));
        rack.dispose();
      });
    }
  }
}
