import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/job_material_catalog.dart';
import 'package:pipe_and_wire_clean/job_material_entry.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';
import 'package:pipe_and_wire_clean/job_material_voice.dart';
import 'package:pipe_and_wire_clean/job_input_field.dart';

void main() {
  test('Fastener speech retains sizes, threads, and counts', () {
    for (final pair in {
      '12 quarter-inch fender washers': 'Fender washer',
      '8 three-eighths-inch nuts': 'Nuts',
      '60 half-inch all-thread': 'Threaded rod',
      '25 6-32 screws': 'Screws'
    }.entries) {
      final item = parseMaterialCommand(pair.key, []);
      expect(item.name, pair.value);
      expect(item.quantity, isNotEmpty, reason: pair.key);
      expect(item.size, isNotEmpty, reason: pair.key);
    }
    final wire = parseMaterialCommand('200 feet number 12 wire', []);
    expect(wire.name, 'Wire');
    expect(wire.size, '#12 AWG');
    expect(wire.quantity, '200');
  });
  test('Material details persist and old records remain readable', () {
    final item = JobMaterial(
        name: 'Screws',
        quantity: '25',
        size: '6-32',
        category: 'Fasteners',
        materialType: 'Self-tapping',
        length: '1 inch',
        specification: 'Stainless');
    final saved = JobMaterial.fromJson(item.toJson());
    expect(saved.materialType, 'Self-tapping');
    expect(saved.length, '1 inch');
    expect(saved.specification, 'Stainless');
    expect(
        JobMaterial.fromJson({
          'name': 'Wire',
          'quantity': '60',
          'unit': 'feet',
          'state': 'Needed'
        }).materialType,
        '');
  });
  testWidgets('Wire starts at gauge and washers offer size shortcuts',
      (tester) async {
    MaterialChoice? picked;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MaterialCategoryPicker(
                    remembered: [],
                    onForget: (_) {},
                    onPick: (c) async {
                      picked = c;
                      return true;
                    })))));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Wire'));
    await tester.pumpAndSettle();
    expect(find.text('THHN'), findsNothing);
    await tester.tap(find.text('#12 AWG'));
    await tester.pumpAndSettle();
    expect(picked!.defaultSize, '#12 AWG');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Fasteners'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Washers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1/4"'));
    await tester.pumpAndSettle();
    expect(picked!.name, 'Fender washer');
    expect(picked!.defaultSize, '1/4"');
  });
  testWidgets('Inline keypad changes the actual field on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: JobInputField(
                    controller: controller,
                    kind: JobKeypadKind.number,
                    inlineKeyboard: true,
                    decoration:
                        const InputDecoration(labelText: 'Quantity'))))));
    await tester.tap(find.byTooltip('Type Quantity'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.text('1'));
    await tester.tap(find.text('8'));
    await tester.pump();
    expect(controller.text, '18');
    expect(tester.takeException(), isNull);
  });
}
