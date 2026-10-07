import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/pipe_and_box_fill.dart';
import 'package:flutter/material.dart';

void main() {
  group('PipeAndBoxFill - Initial State Test', () {
    testWidgets('loads initial pipe and box fill screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PipeAndBoxFill(),
        ),
      );
      await tester.pump();

      expect(find.byType(PipeAndBoxFill), findsOneWidget);
    });
  });
}
