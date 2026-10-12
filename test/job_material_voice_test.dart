import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';
import 'package:pipe_and_wire_clean/job_material_voice.dart';

void main() {
  test('PVC adapters and prefab bends retain type, angle, size and count', () {
    for (final pair in {'MA': 'male', 'FA': 'female'}.entries) {
      final draft = parseMaterialCommand('12 half-inch PVC ${pair.key}', []);
      expect(draft.name, 'PVC ${pair.value} adapter');
      expect(draft.size, '1/2"');
      expect(draft.quantity, '12');
    }
    for (final phrase in [
      '6 two-inch PVC prefab 90s',
      '6 two-inch 90 degree PVC elbows',
      '6 two-inch PVC ninety degree bends'
    ]) {
      final draft = parseMaterialCommand(phrase, []);
      expect(draft.name, 'PVC 90-degree bend');
      expect(draft.size, '2"');
      expect(draft.quantity, '6');
      expect(draft.choice?.category, 'Prefab bends');
    }
    expect(parseMaterialCommand('12 half-inch PVC male adapters', []).name,
        'PVC male adapter');
    expect(
        parseMaterialCommand('4 three-quarter inch rigid 45-degree kicks', [])
            .name,
        'Rigid 45-degree bend');
    expect(parseMaterialCommand('6 PVC bends', []).choice, isNull);
    final offset = parseMaterialCommand(
        'four two-inch twenty two and a half degree PVC bends', []);
    expect(offset.name, 'PVC 22.5-degree bend');
    expect(offset.quantity, '4');
    expect(offset.size, '2"');
    final noCount = parseMaterialCommand('90 degree PVC elbows', []);
    expect(noCount.name, 'PVC 90-degree bend');
    expect(noCount.quantity, '');
  });
  test('Strut straps distinguish thin wall EMT from standard rigid', () {
    for (final phrase in ['thin wall', 'T.W.', 'TW', 'EMT']) {
      final draft =
          parseMaterialCommand('25 three-quarter $phrase Unistrut straps', []);
      expect(draft.choice?.name, 'Thin-wall strut strap');
      expect(draft.size, '3/4"');
      expect(draft.quantity, '25');
    }
    for (final phrase in ['standard', 'STD.', 'rigid']) {
      expect(
          parseMaterialCommand('12 half-inch $phrase strut straps', [])
              .choice
              ?.name,
          'Standard strut strap');
    }
  });
  test(
      'Unistrut mishearings keep strap size separate from channel and quantity',
      () {
    for (final word in [
      'Unistrut',
      'Unistretch',
      'unistrretch',
      'unit strut'
    ]) {
      final draft = parseMaterialCommand('25 three-quarter $word straps', []);
      expect(draft.choice?.name, 'Unistrut strap');
      expect(draft.size, '3/4"');
      expect(draft.quantity, '25');
    }
    expect(parseMaterialCommand('3/4 Unistrut straps', []).size, '3/4"');
    final channel = parseMaterialCommand('2 sticks of Unistretch', []);
    expect(channel.choice?.name, 'Unistrut');
    expect(channel.choice?.category, 'Supports');
    expect(channel.quantity, '2');
    expect(channel.size, '');
  });
  test(
      'Material commands keep size separate from quantity and do not guess types',
      () {
    final connector =
        parseMaterialCommand('Add twelve half-inch EMT connectors', []);
    expect(connector.choice?.name, 'EMT connector');
    expect(connector.size, '1/2"');
    expect(connector.quantity, '12');
    final coupling = parseMaterialCommand(
        'Add twenty five three-quarter inch PVC couplings', []);
    expect(coupling.choice?.name, 'PVC coupling');
    expect(coupling.size, '3/4"');
    expect(coupling.quantity, '25');
    expect(
        parseMaterialCommand('Add half-inch EMT connectors', []).quantity, '');
    expect(
        parseMaterialCommand('Add 40 feet of three-quarter inch EMT', []).unit,
        'feet');
    expect(parseMaterialCommand('Add ten connectors', []).choice, isNull);
    expect(parseMaterialCommand('Add ten EMT specialty connectors', []).choice,
        isNull);
    expect(
        parseMaterialCommand(
            'Add twelve EMT connectors and ten PVC couplings', []).choice,
        isNull);
    expect(
        parseMaterialCommand(
            'Add one hundred and twenty five EMT connectors', []).quantity,
        '125');
  });

  test('Multiple workers retain existing storage and remove duplicate names',
      () {
    final task = BoardTask(
        id: 'crew', title: 'Lighting', worker: 'Mike, Joe; mike\nSam');
    expect(task.workers, ['Mike', 'Joe', 'Sam']);
    final loaded = BoardTask.fromJson(task.toJson());
    expect(loaded.workers, task.workers);
    expect(loaded.workerLabel, 'Mike, Joe, Sam');
  });

  for (final available in [true, false]) {
    testWidgets(
        'Voice preview saves only after review; offline available=$available',
        (tester) async {
      const channel = MethodChannel('pipe_and_wire/offline_speech');
      final methods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methods.add(call.method);
        if (call.method == 'available') return available;
        if (call.method == 'listen') {
          return 'Add twelve half-inch EMT connectors';
        }
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));
      final task = BoardTask(id: 'voice-test', title: 'Lighting');
      SharedPreferences.setMockInitialValues({
        'job_board_v1': jsonEncode({
          'tasks': [task.toJson()],
          'daily': []
        })
      });
      await tester.pumpWidget(
          MaterialApp(theme: ThemeData.light(), home: const JobBoardScreen()));
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(text).first);
        await tester.pumpAndSettle();
      }

      await tap('1. Task list');
      await tap('Lighting');
      await tap('Materials');
      await tester.ensureVisible(find.byTooltip('Speak material'));
      await tester.tap(find.byTooltip('Speak material'));
      await tester.pumpAndSettle();
      expect(methods.where((method) => method == 'listen').length,
          available ? 1 : 0);
      if (!available) {
        expect(find.textContaining('Offline voice is unavailable'),
            findsOneWidget);
        await tester.enterText(find.byType(TextField).first,
            'Add twelve half-inch EMT connectors');
      }
      await tap('Review');
      expect(
          tester
              .widget<TextFormField>(
                  find.widgetWithText(TextFormField, 'Quantity'))
              .controller!
              .text,
          '12');
      expect(
          tester
              .widget<TextFormField>(
                  find.widgetWithText(TextFormField, 'Size (optional)'))
              .controller!
              .text,
          '1/2"');
      final prefs = await SharedPreferences.getInstance();
      Map data() => jsonDecode(prefs.getString('job_board_v1')!) as Map;
      expect((data()['tasks'] as List).single['materials'], isEmpty);
      await tap('Add');
      expect(
          ((data()['tasks'] as List).single['materials'] as List)
              .single['name'],
          'EMT connector');
      expect(methods,
          available ? ['available', 'status', 'listen'] : ['available']);
      expect(tester.takeException(), isNull);
    });
  }
}
