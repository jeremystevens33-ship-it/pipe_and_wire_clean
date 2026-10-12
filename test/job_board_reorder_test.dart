import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pipe_and_wire_clean/job_board_screen.dart';

void main() {
  Future<void> open(WidgetTester tester, List<BoardTask> tasks, {Size size = const Size(420, 900)}) async {
    SharedPreferences.setMockInitialValues({'job_board_v1': jsonEncode({'tasks': tasks.map((t) => t.toJson()).toList(), 'daily': []})});
    tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. Task list')); await tester.pumpAndSettle();
  }
  Future<Map<String, dynamic>> saved() async {
    final prefs = await SharedPreferences.getInstance();
    return jsonDecode(prefs.getString('job_board_v1')!) as Map<String, dynamic>;
  }
  Future<void> move(WidgetTester tester, String title, Offset target) async {
    final gesture = await tester.startGesture(tester.getCenter(find.text(title)));
    await tester.pump(const Duration(milliseconds: 650));
    await gesture.moveBy(const Offset(0, 1)); await tester.pump(const Duration(milliseconds:20));
    await gesture.moveTo(target); await tester.pump(const Duration(milliseconds: 250));
    await gesture.up(); await tester.pumpAndSettle();
  }
  testWidgets('Hold and drag changes task order, preserves data and survives reopening', (tester) async {
    await open(tester, [BoardTask(id:'a',title:'Lighting', materials:[JobMaterial(name:'Nuts',quantity:'25',size:'3/8"')]),BoardTask(id:'b',title:'Exit signs'),BoardTask(id:'c',title:'Conduit')]);
    expect(find.text('Workers'), findsNothing);
    final target = tester.getBottomLeft(find.byKey(const ValueKey('order-c'))).translate(180, 75);
    await move(tester, 'Lighting', target);
    var data = await saved();
    expect((data['tasks'] as List).map((t) => t['id']), ['b','c','a']);
    expect(data['tasks'][2]['materials'][0]['quantity'], '25');
    await tester.pumpWidget(const SizedBox());await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: JobBoardScreen()));await tester.pumpAndSettle();
    await tester.tap(find.text('1. Task list'));await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Exit signs')).dy, lessThan(tester.getTopLeft(find.text('Lighting')).dy));
    await tester.tap(find.text('Roomy'));await tester.pumpAndSettle();
    data = await saved(); expect(data['compactTasks'], false);
    await tester.tap(find.text('Lighting'));await tester.pumpAndSettle();
    expect(find.text('Workers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Filtered task drag preserves hidden and completed tasks', (tester) async {
    await open(tester, [BoardTask(id:'a',title:'Blocked A',status:'Blocked'),BoardTask(id:'h',title:'Hidden'),BoardTask(id:'b',title:'Blocked B',status:'Blocked'),BoardTask(id:'done',title:'Finished',status:'Completed')]);
    await tester.tap(find.widgetWithText(ChoiceChip,'Blocked'));await tester.pumpAndSettle();
    await move(tester, 'Blocked B', tester.getTopLeft(find.byKey(const ValueKey('order-a'))).translate(180, -40));
    final data = await saved();
    expect((data['tasks'] as List).map((t) => t['id']), ['b','h','a','done']);
    expect(data['tasks'][3]['status'], 'Completed');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Dragging near the bottom scrolls the single page on a small phone', (tester) async {
    await open(tester, List.generate(16, (i) => BoardTask(id:'$i',title:'Task $i')), size: const Size(320,568));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final start = scrollable.position.pixels;
    final gesture = await tester.startGesture(tester.getCenter(find.text('Task 0')));
    await tester.pump(const Duration(milliseconds:650));
    await gesture.moveBy(const Offset(0,1));await tester.pump(const Duration(milliseconds:20));
    await gesture.moveTo(const Offset(160,450));
    for(var i=0; i<20; i++) {await tester.pump(const Duration(milliseconds:50));}
    expect(scrollable.position.pixels, greaterThan(start));
    await gesture.up();await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
