import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/pipe_and_box_fill.dart';
import 'package:flutter/material.dart';

void main() {
  group('PipeAndBoxFill - Smoke and Sizing Tests', () {
    testWidgets('renders PipeAndBoxFill widget successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PipeAndBoxFill(),
        ),
      );
      await tester.pump();

      expect(find.text('Pipe and Box Fill'), findsOneWidget);
      expect(find.text('Pipe Size'), findsOneWidget);
      expect(find.text('Box Size'), findsOneWidget);
      expect(find.text('Wire Size'), findsOneWidget);
    });
  });
}
