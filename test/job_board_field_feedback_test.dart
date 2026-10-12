import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/job_input_field.dart';
import 'package:pipe_and_wire_clean/job_material_entry.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const channel = MethodChannel('pipe_and_wire/offline_speech');
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  testWidgets(
      'Daily note dictation continues and Clear discards late voice without closing',
      (tester) async {
    final controller = TextEditingController(text: 'First entry.');
    addTearDown(controller.dispose);
    Completer<String>? pending;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'available') return true;
      if (call.method == 'status') return {'message': 'Phone voice service'};
      if (call.method == 'listen')
        return pending?.future ?? Future.value('Second entry.');
      return null;
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JobInputField(
                controller: controller,
                appendSpeech: true,
                speechSeparator: '\n',
                showClearButton: true,
                speechPauseMillis: 3000,
                decoration: const InputDecoration(labelText: 'Daily note')))));
    await tester.tap(find.byTooltip('Speak Daily note'));
    await tester.pumpAndSettle();
    expect(controller.text, 'First entry.\nSecond entry.');
    pending = Completer<String>();
    await tester.tap(find.byTooltip('Speak Daily note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    pending.complete('Discard this late result');
    await tester.pumpAndSettle();
    expect(controller.text, '');
    expect(find.byTooltip('Speak Daily note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily notes created inside a task also appear in the board log',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [
          BoardTask(id: 'lighting', title: 'Lighting on level one').toJson()
        ],
        'daily': []
      })
    });
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    Future<void> tap(String title) async {
      await tester.ensureVisible(find.text(title).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();
    }

    await tap('1. Task list');
    await tap('Lighting on level one');
    await tap('Daily notes');
    await tap('ADD DAILY NOTE');
    expect(find.text('Link to task'), findsNothing);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'What did you work on today?'),
        'Installed lights. Waiting on connectors.');
    await tap('Save note');
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('job_board_v1')!)['daily'] as List;
    expect(saved.single['task'], 'lighting');
    expect(saved.single['text'], 'Installed lights. Waiting on connectors.');
    await tap('1. Task list');
    await tap('5. Daily notes');
    expect(
        find.text('Installed lights. Waiting on connectors.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Worker dictation appends full names and accepts numbered separators',
      (tester) async {
    final controller = TextEditingController(text: 'Priscilla Santana');
    addTearDown(controller.dispose);
    Object? arguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'available') return true;
      if (call.method == 'status') return {'message': 'Phone voice service'};
      if (call.method == 'listen') {
        arguments = call.arguments;
        return 'number two Jeremy Stevens and Joe Smith';
      }
      return null;
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JobInputField(
                controller: controller,
                appendSpeech: true,
                speechPauseMillis: 3000,
                speechTransform: formatSpokenWorkers,
                decoration: const InputDecoration(labelText: 'Workers')))));
    await tester.tap(find.byTooltip('Speak Workers'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Priscilla Santana, Jeremy Stevens, Joe Smith');
    expect(arguments, {'pauseMillis': 3000});
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unistrut size is chosen inline and spoken feet save as a number',
      (tester) async {
    MaterialEntryResult? saved;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'available') return true;
      if (call.method == 'status') return {'message': 'Phone voice service'};
      if (call.method == 'listen') return '60 feet';
      return null;
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => MaterialCategoryPicker(
                    remembered: const [],
                    onForget: (_) {},
                    onPick: (choice) async {
                      saved = await showDialog<MaterialEntryResult>(
                          context: context,
                          builder: (_) => MaterialEntryDialog(choice: choice));
                      return saved != null;
                    })))));
    await tester.tap(find.text('Supports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unistrut'));
    await tester.pumpAndSettle();
    expect(find.text('7/8"'), findsOneWidget);
    await tester.tap(find.text('1 5/8"'));
    await tester.pumpAndSettle();
    expect(find.text('Size: 1 5/8"'), findsOneWidget);
    expect(find.byTooltip('Type Size (optional)'), findsNothing);
    await tester.tap(find.byTooltip('Speak Quantity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(saved!.size, '1 5/8"');
    expect(saved!.quantity, '60');
    expect(saved!.unit, 'feet');
    expect(find.text('Choose Unistrut size'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
