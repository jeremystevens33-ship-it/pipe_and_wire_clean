import 'package:flutter_test/flutter_test.dart';
import 'package:pipe_and_wire_clean/precise_inches_controller.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';

void main() {
  test('full-stick precision survives display, selection and confirmation', () {
    final input = PreciseInchesController();
    addTearDown(input.dispose);
    input.setInches(40.712345);
    expect(RackState.parseInches(input.text), isNot(input.inches));
    input.setInches(input.inches);
    expect(input.inches, 40.712345);
    input.beginManualEdit();
    expect(input.inches, RackState.parseInches(input.text));
    input.text = '42';
    expect(input.inches, 42);
    input.setInches(40.712345);
    input.clear();
    expect(input.inches, 0);
  });

  test('Parallel full stick stays exact through formatted input round trip', () {
    final rack = RackState();
    final input = PreciseInchesController();
    addTearDown(rack.dispose);
    addTearDown(input.dispose);
    rack.setPipeProgressionOffsets([0, 2.315, 4.63],
        sizes: List.filled(3, '1"'));
    rack.setParallel90BenderData(gain: 4, takeup: 9.5);
    rack.setStubLength(66);
    rack.setLegLength(54);
    input.setInches(rack.parallel90MaxLegLength);
    rack.setLegLength(input.inches);
    input.setInches(rack.legLength);
    rack.setLegLength(input.inches);
    expect(rack.parallel90LongestCutLength, closeTo(120, 1e-9));
    input.text = '60';
    rack.setLegLength(input.inches);
    expect(rack.parallel90LongestCutLength, greaterThan(120));
  });
}
