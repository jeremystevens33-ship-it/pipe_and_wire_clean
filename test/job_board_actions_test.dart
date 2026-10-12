import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';

void main() {
  testWidgets('Front task controls edit and complete without expanding details',
      (tester) async {
    final task = BoardTask(id: 'front', title: 'Lighting');
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [task.toJson()],
        'daily': []
      })
    });
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Task list'));
    await tester.pumpAndSettle();
    final check = find.byKey(const ValueKey('complete-front'));
    expect(check, findsOneWidget);
    expect(find.text('Workers'), findsNothing);
    await tester.tap(find.byTooltip('Edit task'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'Lighting on level one');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Lighting on level one'), findsOneWidget);
    expect(find.text('Workers'), findsNothing);
    await tester.ensureVisible(check);
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    Map savedTask() =>
        (jsonDecode(prefs.getString('job_board_v1')!)['tasks'] as List).single
            as Map;
    expect(savedTask()['status'], 'Completed');
    expect(savedTask()['completed'], isNotNull);
    await tester.ensureVisible(find.text('Completed'));
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(check).value, isTrue);
    await tester.ensureVisible(check);
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(savedTask()['status'], 'Not started');
    expect(savedTask()['completed'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Edit and delete only the chosen note and preserve its original date',
      (tester) async {
    final task = BoardTask(id: 'light', title: 'Lighting');
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [task.toJson()],
        'daily': [
          {
            'text': 'Installed boxes',
            'date': '2026-10-09T00:00:00.000',
            'task': 'light'
          },
          {
            'text': 'Installed boxes',
            'date': '2026-10-08T00:00:00.000',
            'task': 'light'
          },
        ]
      })
    });
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('5. Daily notes'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5. Daily notes'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    List notes() =>
        jsonDecode(prefs.getString('job_board_v1')!)['daily'] as List;
    Future<void> tap(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(finder, 180,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tap(find.byTooltip('Edit daily note').first);
    await tester.enterText(
        find.byType(TextFormField).first, 'Discard this edit');
    await tap(find.text('Cancel'));
    expect(notes().first['text'], 'Installed boxes');
    await tap(find.byTooltip('Edit daily note').first);
    await tester.enterText(
        find.byType(TextFormField).first, 'Installed boxes and connectors');
    await tap(find.text('Save note'));
    expect(notes(), hasLength(2));
    expect(notes().first['text'], 'Installed boxes and connectors');
    expect(notes().first['date'], '2026-10-09T00:00:00.000');
    expect(notes().first['task'], 'light');
    await tap(find.byTooltip('Delete daily note').last);
    await tap(find.text('Keep note'));
    expect(notes(), hasLength(2));
    await tap(find.byTooltip('Delete daily note').last);
    await tap(find.text('Delete note'));
    expect(notes(), hasLength(1));
    expect(notes().single['text'], 'Installed boxes and connectors');
    expect(
        (jsonDecode(prefs.getString('job_board_v1')!)['tasks'] as List)
            .single['title'],
        'Lighting');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    await tap(find.text('5. Daily notes'));
    expect(find.text('Installed boxes and connectors'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
