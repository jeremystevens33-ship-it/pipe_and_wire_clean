import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';

void main() {
  testWidgets(
      'General material entry persists and can be assigned without copying',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [BoardTask(id: 'lighting', title: 'Lighting').toJson()],
        'daily': []
      })
    });
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tap(find.text('3. Job materials'));
    await tap(find.text('Couplings'));
    await tap(find.text('EMT'));
    await tap(find.text('Type not specified'));
    await tap(find.text('1/2"'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'), '12');
    await tap(find.text('Add'));
    final prefs = await SharedPreferences.getInstance();
    Map data() => jsonDecode(prefs.getString('job_board_v1')!) as Map;
    final original =
        Map.from((data()['generalMaterials'] as List).single as Map);
    expect(original['name'], 'EMT coupling');
    expect(original['size'], '1/2"');
    expect(original['quantity'], '12');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    await tap(find.text('3. Job materials'));
    await tap(find.text('EMT coupling • 1/2"'));
    await tap(find.byTooltip('Assign material to task'));
    await tap(find.text('Unassigned materials'));
    await tap(find.text('Lighting').last);
    await tap(find.text('Assign'));
    expect(data()['generalMaterials'], isEmpty);
    final materials = (data()['tasks'] as List).single['materials'] as List;
    expect(materials, hasLength(1));
    expect(materials.single, original);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Reopening from Completed restores a usable task even under a filter',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'job_board_v1': jsonEncode({
        'tasks': [
          BoardTask(
                  id: 'done',
                  title: 'Lighting',
                  status: 'Completed',
                  worker: 'JJ')
              .toJson()
        ],
        'daily': []
      })
    });
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Task list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blocked'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('JJ'), findsNothing);
    expect(find.byTooltip('Edit task'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('complete-done')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All'))
            .selected,
        isTrue);
    await tester.tap(find.byTooltip('Edit task'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lighting'));
    await tester.pumpAndSettle();
    expect(find.text('Workers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
