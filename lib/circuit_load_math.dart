/// Single-phase load conversion. Retain the entered basis at full precision;
/// rounding the companion display must not change circuit-capacity calculations.
class CircuitLoadInput {
  final double value;
  final bool enteredWatts;
  final double voltage;
  final double powerFactor;

  const CircuitLoadInput({
    required this.value,
    required this.enteredWatts,
    required this.voltage,
    required this.powerFactor,
  });

  bool get isValid =>
      value.isFinite &&
      value >= 0 &&
      voltage.isFinite &&
      voltage > 0 &&
      powerFactor.isFinite &&
      powerFactor > 0 &&
      powerFactor <= 1;

  double get amps => !isValid
      ? 0
      : enteredWatts
          ? value / (voltage * powerFactor)
          : value;

  double get watts => !isValid
      ? 0
      : enteredWatts
          ? value
          : value * voltage * powerFactor;

  // Identical loads: multiply each unit's current/watts by the quantity.
  // Example: 16 units * 60W at 120V/PF 1 = 960W and 8A actual current.
  double totalAmps(int quantity) => quantity < 0 ? 0 : amps * quantity;
  double totalWatts(int quantity) => quantity < 0 ? 0 : watts * quantity;
  // Maximum whole units = usable circuit amps / unit amps, rounded DOWN.
  // Example: a 20A ordinary continuous circuit has 16A usable capacity.
  // A 60W, 120V/PF 1 unit draws 0.5A: floor(16 / 0.5) = 32 units.
  int maximumUnits(double usableAmps) =>
      amps <= 0 || !usableAmps.isFinite || usableAmps <= 0
          ? 0
          : (usableAmps / amps).floor();
}

class CircuitLoadEntry {
  final String name;
  final double value;
  final bool enteredWatts;
  final double powerFactor;
  final int quantity;
  final bool continuous;

  const CircuitLoadEntry(
      {required this.name,
      required this.value,
      required this.enteredWatts,
      required this.powerFactor,
      required this.quantity,
      required this.continuous});

  CircuitLoadInput atVoltage(double voltage) => CircuitLoadInput(
      value: value,
      enteredWatts: enteredWatts,
      voltage: voltage,
      powerFactor: powerFactor);
}

/// Ordinary branch circuit preview: 125% continuous + 100% noncontinuous.
/// Remaining capacity is sizing headroom, not universally available load amps.
class MixedCircuitSummary {
  final List<CircuitLoadEntry> loads;
  final double voltage;
  final double breakerAmps;

  MixedCircuitSummary(
      {required List<CircuitLoadEntry> loads,
      required this.voltage,
      required this.breakerAmps})
      : loads = List.unmodifiable(loads) {
    if (!voltage.isFinite ||
        voltage <= 0 ||
        !breakerAmps.isFinite ||
        breakerAmps <= 0 ||
        loads.any((entry) =>
            entry.name.trim().isEmpty ||
            entry.quantity < 1 ||
            entry.value <= 0 ||
            !entry.atVoltage(voltage).isValid ||
            !entry.atVoltage(voltage).amps.isFinite ||
            !entry.atVoltage(voltage).watts.isFinite)) {
      throw ArgumentError(
          'Mixed loads require valid circuit and positive named loads.');
    }
  }

  double get totalAmps => loads.fold(0.0,
      (sum, entry) => sum + entry.atVoltage(voltage).totalAmps(entry.quantity));
  double get totalWatts => loads.fold(
      0.0,
      (sum, entry) =>
          sum + entry.atVoltage(voltage).totalWatts(entry.quantity));
  double get continuousAmps => loads.where((entry) => entry.continuous).fold(
      0.0,
      (sum, entry) => sum + entry.atVoltage(voltage).totalAmps(entry.quantity));
  double get noncontinuousAmps =>
      loads.where((entry) => !entry.continuous).fold(
          0.0,
          (sum, entry) =>
              sum + entry.atVoltage(voltage).totalAmps(entry.quantity));
  // Example: 8A continuous + 2A noncontinuous = 10A actual current.
  // Capacity Used = (8 * 1.25) + 2 = 12A under the ordinary 210.20(A) rule.
  double get sizingAmps => continuousAmps * 1.25 + noncontinuousAmps;
  // On a 20A breaker, that leaves 20 - 12 = 8A of sizing headroom.
  // Another continuous load consumes 1.25 times its actual current here.
  double get remainingAmps => breakerAmps - sizingAmps;
  // Meter fraction: 12A capacity used / 20A breaker = 0.60 (60%).
  double get usage => sizingAmps / breakerAmps;
}
// LOAD CALCULATOR: WHAT THE MATH MEANS
// This file calculates load current and circuit-capacity previews. It does not
// select wire size, apply conductor derating, or perform a building/service load
// calculation. Ordinary power conversions are electrical math, not NEC tables.
// Keep the entered value at full precision; round only the displayed results.
//
// SINGLE-PHASE POWER:
//   Amps = Watts / (Volts * Power Factor)
//   Watts = Amps * Volts * Power Factor
// Volts means the voltage across this load. A 277V line-to-neutral lighting load
// uses this calculation even when supplied from a three-phase panel. This file
// does not calculate balanced three-phase total power.
// Example: 277W / (277V * PF 1) = 1A per unit.
// At PF 0.8, the same 277W load draws 1.25A. PF defaults to 1 in the screen;
// use known equipment PF for conversion, or enter nameplate amps directly.
// Converting nameplate amps back to watts is an estimate if PF is unknown.
//
// CIRCUIT CAPACITY:
// The ordinary branch-circuit protection preview uses NEC 2023 210.20(A):
//   Capacity Used = (Continuous Amps * 1.25) + Noncontinuous Amps.
// This is a sizing allowance, not extra current actually drawn by the load.
// The exception for assemblies listed for 100% operation and equipment-specific
// rules are outside this preview. Conductor sizing is a separate check.
// Reference explanation: https://productinfo.se.com/na-std-ref/viewer?docidentity=NECInformationOfNote-F20BDBCC&extension=xml&lang=en&manualidentity=DataBulletinConductorAmpacityTables-F209E73A
