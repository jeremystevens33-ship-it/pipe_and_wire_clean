import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pipe_and_wire_clean/rack_builder_11.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';

void main() {
  testWidgets('Hub additions append after the last stage, not the expanded stage', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rack = RackState();
    await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(
        value: rack, child: const RackBuilderScreen())));
    await tester.pump(const Duration(milliseconds: 500));
    rack.setIsFromBox(false);
    rack.addBendSegment('90° Rack', 90, 100);
    rack.addBendSegment('Offset', 60, 120);
    final originalIds = rack.runSequence.map((s) => s.id).toList();
    await tester.tap(find.text('H'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('STAGE 1'));
    await tester.pump();
    await tester.tap(find.text('+ PULL POINT'));
    await tester.pump();
    expect(rack.runSequence.map((s) => s.label), ['90° Rack', 'Offset', 'Pull Box']);
    await tester.tap(find.text('+ STRAIGHT'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('3').last);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check_circle).hitTestable().last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(rack.runSequence.length, 4);
    expect(rack.runSequence.take(2).map((s) => s.id), originalIds);
    expect(rack.runSequence.last.type, RunSegmentType.straight);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    rack.dispose();
  });
  for (final submit in ['ADD', '✔']) {
    testWidgets('Hub support entry commits only on $submit', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(600, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rack = RackState();
      await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider.value(
        value: rack, child: const RackBuilderScreen())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      rack.setIsFromBox(false);
      rack.addBendSegment('Kick 90', 105, 88, stub: 22, leg: 66);
      while (rack.supportPositions.isNotEmpty) {
        rack.removeSupport(0);
      }
      rack.addSupport(24, label: 'Support (from Run Start)');
      await tester.tap(find.text('H'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final addRow = find.ancestor(of: find.text('ADD NEW SUPPORT'),
          matching: find.byType(Row)).first;
      await tester.ensureVisible(addRow);
      await tester.tap(find.descendant(of: addRow,
          matching: find.byType(GestureDetector)).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(rack.supportPositions, [24.0]);
      expect(find.text('0""'), findsNothing);
      await tester.tap(find.text('3').last);
      await tester.pump();
      await tester.tap(find.text('3').last);
      await tester.pump();
      expect(find.text('33"'), findsOneWidget);
      final submitButton = submit == 'ADD'
          ? find.text('ADD').hitTestable().last
          : find.byIcon(Icons.check_circle).hitTestable().last;
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(rack.supportPositions, [24.0, 57.0]);
      expect(rack.runSequence.single.length - rack.supportPositions.last, 31);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
      rack.dispose();
    });
  }
}
