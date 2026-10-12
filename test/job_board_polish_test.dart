import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';
import 'package:pipe_and_wire_clean/job_material_catalog.dart';
import 'package:pipe_and_wire_clean/job_material_entry.dart';
import 'package:pipe_and_wire_clean/job_material_voice.dart';

void main() {
  testWidgets('Custom coupling saves a reusable type with size separate',
      (tester) async {
    MaterialEntryResult? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  child: const Text('Open'),
                  onPressed: () async {
                    result = await showDialog<MaterialEntryResult>(
                        context: context,
                        builder: (_) => const MaterialEntryDialog(
                            category: 'Couplings',
                            sizeKind: 'inches',
                            name: 'half-inch liquid-tight couplings'));
                  },
                )))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'), '12');
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(result!.name, 'Liquid-tight coupling');
    expect(result!.size, '1/2"');
    expect(result!.remember, isTrue);

    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: MaterialEntryDialog(
                choice: MaterialChoice(
                    'Couplings', 'half-inch liquid-tight couplings')))));
    await tester.pumpAndSettle();
    expect(find.text('Liquid-tight coupling'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(
                find.widgetWithText(TextFormField, 'Size (optional)'))
            .controller!
            .text,
        isEmpty);
  });

  test('Coupling quick labels omit category and separate the inch size', () {
    const choice =
        MaterialChoice('Couplings', 'half-inch liquid-tight couplings');
    expect(choice.buttonLabel, 'Liquid-tight');
    final parts = splitMaterialName(choice.category, choice.name);
    expect(parts.name, 'Liquid-tight coupling');
    expect(parts.size, '1/2"');
    expect(
        splitMaterialName('Couplings', '3/4-inch liquid-tight fittings').size,
        '3/4"');
    expect(const MaterialChoice('Boxes', '8 × 8 box').buttonLabel, '8 × 8 box');
    expect(splitMaterialName('Wire', '#12 THHN').name, '#12 THHN');
  });

  testWidgets('Board opens with five closed cards and retains saved tasks',
      (tester) async {
    final task = BoardTask(id: 'closed', title: 'Saved lighting');
    final saved = jsonEncode({
      'tasks': [task.toJson()],
      'daily': []
    });
    SharedPreferences.setMockInitialValues({'job_board_v1': saved});
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    expect(find.text('ADD TASK'), findsOneWidget);
    final tiles =
        tester.widgetList<ExpansionTile>(find.byType(ExpansionTile)).toList();
    expect(tiles, hasLength(5));
    expect(tiles.every((tile) => !tile.initiallyExpanded), isTrue);
    expect(find.text('Saved lighting'), findsNothing);
    expect(find.text('All'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('job_board_v1'), saved);
    await tester.tap(find.text('1. Task list'));
    await tester.pumpAndSettle();
    expect(find.text('Saved lighting'), findsOneWidget);
  });

  test('Box dimensions do not become quantity', () {
    for (final sentence in [
      '8 by 8 box',
      '12 x 12 box',
      '18 by 18 junction box'
    ]) {
      final draft = parseMaterialCommand(sentence, []);
      expect(draft.category, 'Boxes');
      expect(draft.quantity, '');
      expect(draft.name, contains('×'));
    }
    final draft = parseMaterialCommand('Add two 8 by 8 by 4 boxes', []);
    expect(draft.name, '8 × 8 × 4 box');
    expect(draft.quantity, '2');
  });

  testWidgets('Task sections have matching compact headers', (tester) async {
    final task =
        BoardTask(id: 'layout', title: 'Lighting', worker: 'Mike, Joe');
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [task.toJson()],
        'daily': []
      })
    });
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Task list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lighting'));
    await tester.pumpAndSettle();
    final heights = <double>[];
    for (final title in [
      'Workers',
      'Materials',
      'Details & progress',
      'Daily notes',
      'Dates & completion'
    ]) {
      final tile = find
          .ancestor(of: find.text(title), matching: find.byType(ListTile))
          .first;
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      heights.add(tester.getSize(tile).height);
    }
    expect(heights.toSet().length, 1);
    expect(heights.first, 52);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Clear board confirms and keeps saved buttons unless explicitly removed',
      (tester) async {
    final task = BoardTask(id: 'clear', title: 'Lighting');
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [task.toJson()],
        'daily': [
          {'text': 'Started', 'date': '2026-10-09', 'task': 'clear'}
        ],
        'materialButtons': [
          const MaterialChoice('Boxes', '8 × 8 box', sizeKind: 'text').toJson()
        ]
      })
    });
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    Map data() => jsonDecode(prefs.getString('job_board_v1')!) as Map;
    await tester.tap(find.byTooltip('Clear board'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect((data()['tasks'] as List).length, 1);
    await tester.tap(find.byTooltip('Clear board'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear board'));
    await tester.pumpAndSettle();
    expect(data()['tasks'], isEmpty);
    expect(data()['daily'], isEmpty);
    expect((data()['materialButtons'] as List).length, 1);
    await tester.tap(find.byTooltip('Clear board'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Also remove saved material buttons'));
    await tester.tap(find.text('Clear board'));
    await tester.pumpAndSettle();
    expect(data()['materialButtons'], isEmpty);
  });

  testWidgets('A custom sized box becomes a reusable Boxes button',
      (tester) async {
    const channel = MethodChannel('pipe_and_wire/offline_speech');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final task = BoardTask(id: 'boxes', title: 'Lighting');
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [task.toJson()],
        'daily': []
      })
    });
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    Future<void> tap(String label) async {
      await tester.ensureVisible(find.text(label).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
    }

    await tap('1. Task list');
    await tap('Lighting');
    await tap('Materials');
    await tester.ensureVisible(find.byTooltip('Speak material'));
    await tester.tap(find.byTooltip('Speak material'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '8 by 8 box');
    await tap('Review');
    expect(
        tester
            .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, 'Save as a quick button'))
            .value,
        isTrue);
    await tap('Add');
    await tap('Boxes');
    expect(find.widgetWithText(InputChip, '8 × 8 box'), findsOneWidget);
    await tap('8 × 8 box');
    expect(find.text('Material name'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
