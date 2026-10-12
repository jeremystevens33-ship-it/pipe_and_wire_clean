import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pipe_and_wire_clean/job_input_field.dart';
import 'package:pipe_and_wire_clean/job_material_catalog.dart';
import 'package:pipe_and_wire_clean/job_material_voice.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';

void main() {
  const channel = MethodChannel('pipe_and_wire/offline_speech');
  testWidgets(
      'Text size keyboard enters fractions with a slash on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JobInputField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Size')))));
    await tester.tap(find.byTooltip('Type Size'));
    await tester.pumpAndSettle();
    for (final key in ['3', '/', '8']) {
      await tester.ensureVisible(find.text(key));
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(controller.text, '3/8');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add task offers direct voice without the Android keyboard',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'available') return true;
      if (call.method == 'status') return {'message': 'Phone voice service'};
      if (call.method == 'listen') return 'Exit signs on levels 1 and 2';
      return null;
    });
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ADD TASK'));
    await tester.pumpAndSettle();
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.keyboardType, TextInputType.none);
    }
    await tester.tap(find.byTooltip('Speak Task name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final data = jsonDecode(prefs.getString('job_board_v1')!);
    expect(data['tasks'].single['title'], 'Exit signs on levels 1 and 2');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Phone-service mode is visible and no keyboard opens for voice',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'available') return true;
      if (call.method == 'status') {
        return {
          'mode': 'phone_service',
          'message':
              'Phone voice service: offline preferred; it may need a connection.'
        };
      }
      if (call.method == 'listen') return 'twelve';
      return null;
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JobInputField(
                controller: controller,
                kind: JobKeypadKind.number,
                speechTransform: formatSpokenQuantity,
                decoration: const InputDecoration(labelText: 'Quantity')))));
    await tester.tap(find.byTooltip('Speak Quantity'));
    await tester.pumpAndSettle();
    expect(controller.text, '12');
    expect(find.textContaining('Phone voice service:'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.none);
  });

  testWidgets(
      'Stopping during startup prevents a late recording from beginning',
      (tester) async {
    final controller = TextEditingController(text: 'Keep this');
    addTearDown(controller.dispose);
    final available = Completer<bool>();
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      if (call.method == 'available') return available.future;
      return null;
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JobInputField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Note')))));
    await tester.tap(find.byTooltip('Speak Note'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Stop voice'));
    await tester.pumpAndSettle();
    available.complete(true);
    await tester.pumpAndSettle();
    expect(controller.text, 'Keep this');
    expect(methods, ['available', 'cancel']);
    expect(tester.takeException(), isNull);
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test('Inch-and-a-half speech becomes a fraction without rewriting counts',
      () {
    expect(formatMaterialInches('an inch and a half'), '1 1/2"');
    expect(formatInchMeasurements('Used 12 inch-and-a-half connectors today'),
        'Used 12 1 1/2" connectors today');
    expect(
        formatInchMeasurements('12 boxes on level 5'), '12 boxes on level 5');
    expect(formatSpokenQuantity('twelve'), '12');
    expect(formatSpokenQuantity('twenty-four'), '24');
    final draft =
        parseMaterialCommand('Add twelve inch-and-a-half EMT connectors', []);
    expect(draft.quantity, '12');
    expect(draft.size, '1 1/2"');
    expect(draft.choice!.name, 'EMT connector');
  });

  testWidgets(
      'Typing controls stay reachable on a short screen with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller =
        TextEditingController(text: 'First line\nSecond line\nThird line');
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        home: Scaffold(
            body: JobInputField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Note')))));
    await tester.tap(find.byTooltip('Type Note'));
    await tester.pumpAndSettle();
    expect(find.text('Done').hitTestable(), findsOneWidget);
    expect(find.text('Cancel typing').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel typing'));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Field microphone stops on second tap; cancel discards late speech',
      (tester) async {
    final controller = TextEditingController(text: 'Original');
    addTearDown(controller.dispose);
    var pending = Completer<String>();
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      if (call.method == 'available') return true;
      if (call.method == 'listen') return pending.future;
      if (call.method == 'stop') pending.complete('inch and a half');
      if (call.method == 'cancel' && !pending.isCompleted) {
        pending.complete('Discard me');
      }
      return null;
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JobInputField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Size'),
                speechTransform: formatMaterialInches))));
    await tester.tap(find.byTooltip('Speak Size'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Original');
    expect(find.byTooltip('Stop voice'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.byTooltip('Stop voice'));
    await tester.pumpAndSettle();
    expect(controller.text, '1 1/2"');
    expect(methods, contains('stop'));
    pending = Completer<String>();
    await tester.tap(find.byTooltip('Speak Size'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel voice'));
    await tester.pumpAndSettle();
    expect(controller.text, '1 1/2"');
    expect(methods, contains('cancel'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'App keypad edits selections and cancels without changing draft on a compact phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController(text: 'pipe');
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: JobInputField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Name')))));
    expect(tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.none);
    await tester.tap(find.byTooltip('Type Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('b'));
    await tester.pumpAndSettle();
    expect(controller.text, 'pipe');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(controller.text, 'b');
    await tester.tap(find.byTooltip('Type Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('o'));
    await tester.tap(find.text('Cancel typing'));
    await tester.pumpAndSettle();
    expect(controller.text, 'b');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Daily note dictation is a draft until saved and keeps its task link',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [BoardTask(id: 'light', title: 'Lighting').toJson()],
        'daily': []
      })
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'available') return true;
      if (call.method == 'listen') {
        return 'Installed 12 inch and a half connectors';
      }
      return null;
    });
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    Future<void> tap(String text) async {
      await tester.ensureVisible(find.text(text).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(text).first);
      await tester.pumpAndSettle();
    }

    await tap('5. Daily notes');
    await tap('ADD DAILY NOTE');
    await tap('General');
    await tap('Lighting');
    await tester.tap(find.byTooltip('Speak What did you work on today?'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('job_board_v1')!)['daily'], isEmpty);
    await tap('Save note');
    final note =
        (jsonDecode(prefs.getString('job_board_v1')!)['daily'] as List).single;
    expect(note['text'], 'Installed 12 1 1/2" connectors');
    expect(note['task'], 'light');
    expect(tester.takeException(), isNull);
  });
}
