import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'Dark cards, forms, buttons and calendar stay readable in a light app',
      (tester) async {
    final task = BoardTask(id: 'theme-test', title: 'Level one lighting');
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [task.toJson()],
        'daily': []
      }),
    });
    await tester.pumpWidget(
        MaterialApp(theme: ThemeData.light(), home: const JobBoardScreen()));
    await tester.pumpAndSettle();
    Color? textColor(String label) => tester
        .widget<RichText>(find
            .descendant(
                of: find.text(label).first, matching: find.byType(RichText))
            .first)
        .text
        .style
        ?.color;
    expect(textColor('ADD TASK'), Colors.white);
    await tester.tap(find.text('1. Task list'));
    await tester.pumpAndSettle();
    expect(
        textColor('Level one lighting')!.computeLuminance(), greaterThan(0.5));
    await tester.tap(find.text('ADD TASK'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(AlertDialog))).brightness,
        Brightness.dark);
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .style
            .color!
            .computeLuminance(),
        greaterThan(0.5));
    expect(textColor('Save'), Colors.white);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Level one lighting'));
    await tester.pumpAndSettle();
    expect(textColor('Details & progress'), Colors.black);
    await tester.ensureVisible(find.text('Details & progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details & progress'));
    await tester.pumpAndSettle();
    expect(textColor('Not started')!.computeLuminance(), greaterThan(0.5));
    await tester.ensureVisible(find.text('Dates & completion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dates & completion'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Due date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Due date'));
    await tester.pumpAndSettle();
    final calendarTheme =
        Theme.of(tester.element(find.byType(DatePickerDialog)));
    expect(calendarTheme.brightness, Brightness.dark);
    expect(calendarTheme.colorScheme.onSurface, Colors.white);
    expect(calendarTheme.colorScheme.onPrimary, Colors.white);
    expect(tester.takeException(), isNull);
  });

  test('Saved task retains assignment, dates and material availability', () {
    final task = BoardTask(
      id: 'lighting',
      title: 'Level one lighting',
      worker: 'Mike',
      status: 'Blocked',
      notes: 'Waiting on fixtures',
      start: DateTime(2026, 10, 8),
      due: DateTime(2026, 10, 12),
      materials: [
        JobMaterial(
            name: '1/2-inch EMT',
            quantity: '40',
            unit: 'feet',
            state: 'On hand')
      ],
    );
    final saved = BoardTask.fromJson(
        jsonDecode(jsonEncode(task.toJson())) as Map<String, dynamic>);
    expect(saved.worker, 'Mike');
    expect(saved.status, 'Blocked');
    expect(saved.notes, 'Waiting on fixtures');
    expect(saved.start, DateTime(2026, 10, 8));
    expect(saved.due, DateTime(2026, 10, 12));
    expect(saved.materials.single.state, 'On hand');
    expect(saved.materials.single.quantity, '40');
  });

  testWidgets('Create on a narrow phone, complete, reopen and reload task',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget board() => const MaterialApp(home: JobBoardScreen());
    await tester.pumpWidget(board());
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Task list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ADD TASK'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).at(0), 'Lighting on level one');
    await tester.enterText(find.byType(TextFormField).at(1), 'Mike');
    await tester.enterText(
        find.byType(TextFormField).at(2), 'Four fixtures in the hallway');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('1 open • 0 completed'), findsOneWidget);
    await tester.tap(find.text('Lighting on level one'));
    await tester.pumpAndSettle();
    expect(find.text('Details & progress'), findsOneWidget);
    for (final section in [
      'Details & progress',
      'Dates & completion',
      'Materials',
      'Workers',
      'Daily notes'
    ]) {
      await tester.ensureVisible(find.text(section));
      await tester.pumpAndSettle();
      await tester.tap(find.text(section));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(section));
      await tester.pumpAndSettle();
      await tester.tap(find.text(section));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    final completedPrefs = await SharedPreferences.getInstance();
    final completedData =
        jsonDecode(completedPrefs.getString('job_board_v1')!) as Map;
    expect((completedData['tasks'] as List).single['status'], 'Completed');
    await tester.ensureVisible(find.text('Completed').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lighting on level one'));
    await tester.pumpAndSettle();
    if (find.byType(Checkbox).evaluate().isEmpty) {
      await tester.tap(find.text('Lighting on level one'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString('job_board_v1')!) as Map;
    expect((stored['tasks'] as List).single['status'], 'Not started');
    expect((stored['tasks'] as List).single['completed'], isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(board());
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Task list'));
    await tester.pumpAndSettle();
    expect(find.text('Lighting on level one'), findsOneWidget);
    expect(find.text('Mike • Not started'), findsOneWidget);
    expect(find.text('1 open • 0 completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
