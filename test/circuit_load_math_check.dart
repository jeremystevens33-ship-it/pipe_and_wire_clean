import 'dart:io';
import 'package:pipe_and_wire_clean/circuit_load_math.dart';

void close(double actual, double expected) {
  if ((actual - expected).abs() > 1e-9) {
    throw StateError('Expected $expected, got $actual');
  }
}

void main() {
  // Independent examples: sixteen 60W lamps on a 120V circuit at PF 1
  // draw 8A and 960W, using half of a 16A usable capacity; 32 lamps fit.
  const lamps = CircuitLoadInput(
      value: 60, enteredWatts: true, voltage: 120, powerFactor: 1);
  close(lamps.amps, 0.5);
  close(lamps.totalAmps(16), 8);
  close(lamps.totalWatts(16), 960);
  close(lamps.totalAmps(16) / 16, 0.5);
  if (lamps.maximumUnits(16) != 32) throw StateError('Lamp maximum');

  // The same watts with PF 0.8 draw more current, not more real power.
  const drivers = CircuitLoadInput(
      value: 60, enteredWatts: true, voltage: 120, powerFactor: 0.8);
  close(drivers.totalAmps(16), 10);
  close(drivers.totalWatts(16), 960);
  if (drivers.maximumUnits(16) != 25) throw StateError('PF maximum');

  const enteredAmps = CircuitLoadInput(
      value: 0.625, enteredWatts: false, voltage: 240, powerFactor: 0.8);
  close(enteredAmps.amps, 0.625);
  close(enteredAmps.watts, 120);

  // Precision at the full-circuit boundary: 38W, not rounded 0.3167A.
  const smallLamps = CircuitLoadInput(
      value: 38, enteredWatts: true, voltage: 120, powerFactor: 1);
  close(smallLamps.totalWatts(50), 1900);
  if (smallLamps.maximumUnits(16) != 50) throw StateError('38W maximum');
  const boundary = CircuitLoadInput(
      value: 120, enteredWatts: true, voltage: 120, powerFactor: 1);
  close(boundary.totalAmps(17), 17);
  if (boundary.maximumUnits(16) != 16) throw StateError('Exact boundary');

  for (final invalid in [
    const CircuitLoadInput(
        value: -1, enteredWatts: true, voltage: 120, powerFactor: 1),
    const CircuitLoadInput(
        value: 60, enteredWatts: true, voltage: 0, powerFactor: 1),
    const CircuitLoadInput(
        value: 60, enteredWatts: true, voltage: 120, powerFactor: 0),
    const CircuitLoadInput(
        value: 60, enteredWatts: true, voltage: 120, powerFactor: 1.1),
  ]) {
    if (invalid.isValid) throw StateError('Invalid input accepted');
    close(invalid.amps, 0);
  }
  const zero = CircuitLoadInput(
      value: 0, enteredWatts: true, voltage: 120, powerFactor: 1);
  if (zero.maximumUnits(16) != 0) throw StateError('Zero load');
  stdout.writeln('Circuit load numerical checks passed.');
  // 12 x 38W continuous + 6 x 60W noncontinuous at 120V:
  // 456W / 120 = 3.8A; 360W / 120 = 3A. Sizing = 4.75 + 3 = 7.75A.
  const lighting = CircuitLoadEntry(
      name: 'Lighting',
      value: 38,
      enteredWatts: true,
      powerFactor: 1,
      quantity: 12,
      continuous: true);
  const other = CircuitLoadEntry(
      name: 'Other fixtures',
      value: 60,
      enteredWatts: true,
      powerFactor: 1,
      quantity: 6,
      continuous: false);
  final mixed = MixedCircuitSummary(
      loads: [lighting, other], voltage: 120, breakerAmps: 20);
  close(mixed.totalWatts, 816);
  close(mixed.totalAmps, 6.8);
  close(mixed.continuousAmps, 3.8);
  close(mixed.noncontinuousAmps, 3);
  close(mixed.sizingAmps, 7.75);
  close(mixed.remainingAmps, 12.25);
  close(mixed.usage, 0.3875);
  final higherVoltage = MixedCircuitSummary(
      loads: [lighting, other], voltage: 240, breakerAmps: 20);
  close(higherVoltage.sizingAmps, 3.875);
  const boundaryLoad = CircuitLoadEntry(
      name: 'Full continuous',
      value: 16,
      enteredWatts: false,
      powerFactor: 0.9,
      quantity: 1,
      continuous: true);
  final full =
      MixedCircuitSummary(loads: [boundaryLoad], voltage: 120, breakerAmps: 20);
  close(full.sizingAmps, 20);
  close(full.remainingAmps, 0);
  final overload = MixedCircuitSummary(
      loads: [boundaryLoad, other], voltage: 120, breakerAmps: 20);
  close(overload.remainingAmps, -3);
  close(overload.totalAmps, 19);
  final empty = MixedCircuitSummary(loads: [], voltage: 120, breakerAmps: 20);
  close(empty.totalAmps, 0);
  close(empty.sizingAmps, 0);
  stdout.writeln('Mixed circuit numerical checks passed.');
}
