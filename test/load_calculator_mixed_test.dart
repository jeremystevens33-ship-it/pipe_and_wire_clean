import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/load_calculator2.dart';

void main() {
  testWidgets(
      'mixed edit replaces an entry, removal clears results, repeating draft survives',
      (tester) async {
    tester.view.physicalSize = const Size(440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LoadCalculator2()));
    Future<void> tapText(String text) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final matches = text == 'DONE'
          ? find.descendant(
              of: find.byWidgetPredicate((widget) => widget is AnimatedCrossFade &&
                  widget.crossFadeState == CrossFadeState.showSecond),
              matching: find.text(text))
          : find.text(text);
      for (var attempt = 0;
          matches.evaluate().isEmpty && attempt < 8;
          attempt++) {
        await tester.drag(find.byType(SingleChildScrollView).first,
            Offset(0, text.startsWith('5.') ? -600 : 600));
        await tester.pump();
      }
      final target = matches.first;
      await Scrollable.ensureVisible(tester.element(target), alignment: 0.4);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(target);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tapText('Mixed Load');
    await tapText('DONE');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Breaker Size').hitTestable(), findsOneWidget);
    await tester.tap(find.text('DONE').hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ADD LOAD'), findsNothing);
    final watts = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.labelText == 'Watts per Unit');
    final amps = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'Amps per Unit');
    final name = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'Load Name');
    final quantity = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'Quantity');
    expect(tester.getTopLeft(name).dy, tester.getTopLeft(quantity).dy);
    expect(tester.getSize(name).width, tester.getSize(quantity).width);
    expect(tester.getTopLeft(name).dy, lessThan(tester.getTopLeft(watts).dy));
    expect(tester.getSize(watts).width, tester.getSize(amps).width);
    expect(tester.getTopLeft(find.text('Continuous')).dy,
        greaterThan(tester.getTopLeft(watts).dy));
    expect(tester.widget<TextField>(watts).controller!.text, isEmpty);
    expect(tester.widget<TextField>(amps).controller!.text, isEmpty);
    expect(find.textContaining('Power Factor (optional)'), findsNothing);
    expect(find.text('Live Circuit Preview'), findsNothing);
    await Scrollable.ensureVisible(tester.element(watts), alignment: 0.4);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(watts);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('3').last);
    await tester.pump();
    expect(tester.widget<TextField>(watts).controller!.text, '3');
    expect(tester.widget<TextField>(amps).controller!.text, '0.03');
    await tester.tap(find.text('8').last);
    await tester.pump();
    expect(tester.widget<TextField>(watts).controller!.text, '38');
    expect(tester.widget<TextField>(amps).controller!.text, '0.32');
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Power Factor (optional)'), findsOneWidget);
    expect(find.text('Live Circuit Preview'), findsOneWidget);
    await tapText('DONE');
    expect(find.text('ADD ADDITIONAL LOAD'), findsOneWidget);
    expect(watts, findsNothing);
    expect(find.text('REMOVE'), findsOneWidget);
    await tapText('EDIT');
    await Scrollable.ensureVisible(tester.element(quantity), alignment: 0.4);
    await tester.tap(quantity);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('2').last);
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pump(const Duration(milliseconds: 300));
    await tapText('DONE');
    expect(find.text('REMOVE'), findsOneWidget);
    await tapText('5. RESULTS');
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(find.text('5. RESULTS')).dy, lessThan(110));
    expect(find.text('19.21A'), findsOneWidget);
    expect(find.text('0.79A'), findsOneWidget);
    expect(find.text('20A'), findsWidgets);
    expect(find.text('20.00A'), findsNothing);
    expect(find.text('Capacity Used'), findsOneWidget);
    expect(find.text('Actual Current'), findsOneWidget);
    await tapText('3. LOAD INPUTS');
    await tapText('REMOVE');
    await tapText('5. RESULTS');
    expect(find.text('Add a load in Step 3 to see circuit results.'),
        findsOneWidget);
    await tapText('1. MODE');
    await tapText('Repeating Load');
    await tapText('3. LOAD INPUTS');
    final quantityField = tester.widget<TextField>(quantity);
    expect(quantityField.controller!.text, '1');
    expect(tester.widget<TextField>(watts).controller!.text, isEmpty);
    await tester.tap(find.byTooltip('Reset calculator'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    expect(find.text('Basic Circuit').hitTestable(), findsOneWidget);
    await tapText('Mixed Load');
    await tapText('DONE');
    expect(find.text('120V'), findsWidgets);
    await tapText('DONE');
    expect(tester.widget<TextField>(watts).controller!.text, isEmpty);
    expect(tester.widget<TextField>(quantity).controller!.text, '1');
    expect(tester.widget<TextField>(name).controller!.text, 'Load 1');
    expect(find.text('REMOVE'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
