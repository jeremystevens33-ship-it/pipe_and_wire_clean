import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';
import 'package:pipe_and_wire_clean/job_material_catalog.dart';
import 'package:pipe_and_wire_clean/job_material_entry.dart';
import 'package:pipe_and_wire_clean/job_material_voice.dart';

void main() {
  test('Speech retains fitting subtype and separates size and count', () {
    final compression =
        parseMaterialCommand('25 half-inch EMT compression connectors', []);
    expect(compression.name, 'EMT compression connector');
    expect(compression.size, '1/2"');
    expect(compression.quantity, '25');
    expect(
        parseMaterialCommand(
            '12 three-quarter inch EMT set-screw couplings', []).name,
        'EMT set screw coupling');
    expect(parseMaterialCommand('4 half-inch liquidtight connectors', []).name,
        'Liquid-tight connector');
  });

  testWidgets('Fitting family expands subtypes and resets after adding',
      (tester) async {
    MaterialChoice? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MaterialCategoryPicker(
                remembered: const [],
                onForget: (_) {},
                onPick: (choice) async {
                  selected = choice;
                  return true;
                }))));
    await tester.tap(find.text('Connectors'));
    await tester.pumpAndSettle();
    expect(find.text('Compression'), findsNothing);
    await tester.tap(find.text('EMT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compression'));
    await tester.pumpAndSettle();
    expect(selected!.name, 'EMT compression connector');
    expect(find.text('Choose connectors type'), findsNothing);
    await tester.tap(find.text('Couplings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rigid'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Three-piece'));
    await tester.pumpAndSettle();
    expect(selected!.name, 'Rigid three-piece coupling');
    expect(tester.takeException(), isNull);
  });
  test('Legacy materials retain name, quantity, availability and custom unit',
      () {
    final material = JobMaterial.fromJson({
      'name': '3/4-inch EMT',
      'quantity': '2',
      'unit': 'bundles',
      'state': 'Purchased'
    });
    expect(material.name, '3/4-inch EMT');
    expect(material.size, '');
    final reloaded = JobMaterial.fromJson(material.toJson());
    expect(reloaded.unit, 'bundles');
    expect(reloaded.quantity, '2');
    expect(reloaded.state, 'Purchased');
  });

  test('Inch-size input formats common spoken and numeric sizes', () {
    for (final entry in {
      'half inch': '1/2"',
      'three-quarter inch': '3/4"',
      'one and a quarter inch': '1 1/4"',
      '.75': '3/4"',
      '1.5': '1 1/2"',
      '1-1/4"': '1 1/4"',
      '½″': '1/2"',
      'custom size': 'custom size'
    }.entries) {
      expect(formatMaterialInches(entry.key), entry.value);
    }
  });

  testWidgets(
      'Category entry and remembered custom buttons persist on a narrow phone',
      (tester) async {
    final task = BoardTask(
        id: 'materials-test',
        title: 'Garage lights',
        materials: [
          JobMaterial(name: 'Old fixture', quantity: '4', unit: 'each')
        ]);
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [task.toJson()],
        'daily': []
      })
    });
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> tap(String text) async {
      final finder = find.text(text).first;
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> openMaterials() async {
      await tap('1. Task list');
      await tap('Garage lights');
      await tap('Materials');
    }

    Widget board() =>
        MaterialApp(theme: ThemeData.light(), home: const JobBoardScreen());
    await tester.pumpWidget(board());
    await tester.pumpAndSettle();
    await openMaterials();
    await tap('Connectors');
    await tap('EMT');
    await tap('Type not specified');
    expect(find.text('Quantity basis'), findsNothing);
    await tap('1/2"');
    final quantity = find.widgetWithText(TextFormField, 'Quantity');
    await tester.enterText(quantity, '-1');
    await tap('Add');
    expect(find.text('Enter a quantity greater than zero'), findsOneWidget);
    await tester.enterText(quantity, '1.5');
    await tap('Add');
    expect(find.text('Enter a whole item count'), findsOneWidget);
    await tester.enterText(quantity, '12');
    await tap('Add');
    expect(tester.takeException(), isNull);
    final prefs = await SharedPreferences.getInstance();
    Map data() => jsonDecode(prefs.getString('job_board_v1')!) as Map;
    final materials = (data()['tasks'] as List).single['materials'] as List;
    expect(materials.first['name'], 'Old fixture');
    expect(materials.last['name'], 'EMT connector');
    expect(materials.last['size'], '1/2"');
    expect(materials.last['quantity'], '12');
    expect(materials.last['unit'], 'each');
    expect(find.text('Choose connectors type'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Needed'), findsNothing);
    await tap('EMT connector • 1/2"');
    expect(find.widgetWithText(ChoiceChip, 'Needed'), findsOneWidget);
    await tap('EMT connector • 1/2"');
    await tap('Add custom material');
    await tester.enterText(find.widgetWithText(TextFormField, 'Material name'),
        'Weatherproof cover');
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '3');
    expect(
        tester
            .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, 'Save as a quick button'))
            .value,
        isTrue);
    await tap('Add');
    expect((data()['materialButtons'] as List).single['name'],
        'Weatherproof cover');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(board());
    await tester.pumpAndSettle();
    await openMaterials();
    await tap('Custom');
    await tap('Weatherproof cover');
    expect(find.text('Material name'), findsNothing);
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '2');
    await tap('Add');
    expect((data()['materialButtons'] as List).length, 1);
    expect(((data()['tasks'] as List).single['materials'] as List).length, 4);
    await tap('Pipe');
    await tap('EMT');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Size (optional)'),
        'three-quarter inch');
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '6');
    await tap('Add');
    var lastMaterial =
        ((data()['tasks'] as List).single['materials'] as List).last;
    expect(lastMaterial['size'], '3/4"');
    expect(lastMaterial['unit'], 'sticks');
    await tap('Wire');
    await tap('THHN / THWN-2');
    await tap('#12 AWG');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'), '100');
    await tap('Add');
    lastMaterial = ((data()['tasks'] as List).single['materials'] as List).last;
    expect(lastMaterial['size'], '#12 AWG');
    expect(lastMaterial['unit'], 'feet');
    await tap('Custom');
    final remove = find.byTooltip('Remove saved button');
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pumpAndSettle();
    await tap('Remove');
    expect((data()['materialButtons'] as List), isEmpty);
    expect(((data()['tasks'] as List).single['materials'] as List).length, 6);
    expect(tester.takeException(), isNull);
    await tap('Garage lights');
    await tap('Garage lights');
    expect(find.text('Choose wire type'), findsNothing);
    expect(find.text('Pipe'), findsNothing);
    expect(find.text('Size (optional)'), findsNothing);
  });
}
