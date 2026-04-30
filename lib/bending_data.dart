import 'dart:math' as math;

enum BendingMethod { arrow, centerline }
enum ConduitType { emt, imc, rigid, pvc }
enum MarkBMethod { pushThrough, reverseBender }

class Bender {
  const Bender({
    required this.brand,
    this.model,
    this.displayName,
    required this.conduitSize,
    required this.conduitType,
    required this.clr,
    required this.deduct,
    required this.gain,
  });

  final String brand;
  final String? model;
  final String? displayName;
  final String conduitSize;
  final ConduitType conduitType;
  final double clr;
  final double deduct;
  final double gain;
}

// ===== OD tables (inches) =====
const Map<String, double> emtOD = {
  '0.5': 0.706, '0.75': 0.922, '1.0': 1.163, '1.25': 1.510, '1.5': 1.740,
  '2.0': 2.197, '2.5': 2.875, '3.0': 3.500, '3.5': 4.000, '4.0': 4.500,
};
const Map<String, double> grcOD = {
  '0.5': 0.840, '0.75': 1.050, '1.0': 1.315, '1.25': 1.660, '1.5': 1.900,
  '2.0': 2.375, '2.5': 2.875, '3.0': 3.500, '3.5': 4.000, '4.0': 4.500,
};
const Map<String, String> pipeSizes = {
  '0.5': '1/2"', '0.75': '3/4"', '1.0': '1"', '1.25': '1 1/4"', '1.5': '1 1/2"',
  '2.0': '2"', '2.5': '2 1/2"', '3.0': '3"', '3.5': '3 1/2"', '4.0': '4"',
};
// Used for the smart GRC default logic
const List<String> pipeSizeOrder = [
  '0.5',
  '0.75',
  '1.0',
  '1.25',
  '1.5',
  '2.0',
  '2.5',
  '3.0',
  '3.5',
  '4.0'
];

final List<Bender> benderDatabase = [
  const Bender(brand: 'Ideal', model: '74-031', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.34, deduct: 5.0, gain: 1.86), // kick_90.dart value
  const Bender(brand: 'Ideal', model: '74-032', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.0, deduct: 6.0, gain: 2.15), // kick_90.dart value
  const Bender(brand: 'Ideal', model: '74-033', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.5, deduct: 8.0, gain: 2.79), // kick_90.dart value
  const Bender(brand: 'Ideal', model: '74-036', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.75, deduct: 11.0, gain: 4.18), // kick_90.dart value

  const Bender(brand: 'Klein', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.625, deduct: 5.0, gain: 2.691), // kick_90.dart value
  const Bender(brand: 'Klein', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 6.0, deduct: 6.0, gain: 2.58), // kick_90.dart value
  const Bender(brand: 'Klein', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 7.0, deduct: 8.0, gain: 3.0), // kick_90.dart value
  const Bender(brand: 'Klein', model: '56211', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.75, deduct: 11.0, gain: 4.18), // kick_90.dart value

  const Bender(brand: 'Gardner Bender', model: '960 Big Ben', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.18, deduct: 4.5, gain: 2.5), // kick_90.dart value
  const Bender(brand: 'Gardner Bender', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 4.74, deduct: 6.0, gain: 2.03), // kick_90.dart value
  const Bender(brand: 'Gardner Bender', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 5.81, deduct: 8.0, gain: 2.49), // kick_90.dart value
  const Bender(brand: 'Gardner Bender', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.75, deduct: 12.0, gain: 4.18), // kick_90.dart value

  const Bender(brand: 'Milwaukee', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.94, deduct: 5.0, gain: 2.75), // kick_90.dart value
  const Bender(brand: 'Milwaukee', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 6.0, deduct: 6.0, gain: 3.283), // kick_90.dart value
  const Bender(brand: 'Milwaukee', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 8.0, deduct: 8.0, gain: 4.167), // kick_90.dart value

  const Bender(brand: 'Greenlee 555', conduitSize: '0.5', conduitType: ConduitType.emt, deduct: 7.5, clr: 4.3125, gain: 2.557), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '0.5', conduitType: ConduitType.rigid, deduct: 7.5, clr: 4.25, gain: 2.664), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '0.75', conduitType: ConduitType.emt, deduct: 9.0, clr: 5.5, gain: 3.283), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '0.75', conduitType: ConduitType.rigid, deduct: 9.0, clr: 5.4375, gain: 3.384), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '1.0', conduitType: ConduitType.emt, deduct: 11.0, clr: 7.0, gain: 4.167), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '1.0', conduitType: ConduitType.rigid, deduct: 11.0, clr: 6.9375, gain: 4.293), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '1.25', conduitType: ConduitType.emt, deduct: 13.625, clr: 8.8125, gain: 5.292), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 13.625, clr: 8.75, gain: 5.416), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '1.5', conduitType: ConduitType.emt, deduct: 14.875, clr: 8.375, gain: 5.336), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 14.875, clr: 8.25, gain: 5.441), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '2.0', conduitType: ConduitType.emt, deduct: 16.375, clr: 9.25, gain: 6.176), // kick_90.dart value
  const Bender(brand: 'Greenlee 555', conduitSize: '2.0', conduitType: ConduitType.rigid, deduct: 16.125, clr: 9.0, gain: 6.238), // kick_90.dart value

  const Bender(brand: 'Greenlee 1818', conduitSize: '0.5', conduitType: ConduitType.rigid, deduct: 6.0, clr: 2.65625, gain: 1.980), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '0.75', conduitType: ConduitType.rigid, deduct: 8.125, clr: 4.50000, gain: 2.981), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.0', conduitType: ConduitType.rigid, deduct: 10.25, clr: 5.87500, gain: 3.837), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 12.375, clr: 7.12500, gain: 4.729), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 15.0, clr: 9.00000, gain: 5.762), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '2.0', conduitType: ConduitType.rigid, deduct: 16.3125, clr: 10.50000, gain: 6.882), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '0.75', conduitType: ConduitType.emt, deduct: 8.6875, clr: 5.09375, gain: 3.106), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.0', conduitType: ConduitType.emt, deduct: 10.25, clr: 6.40625, gain: 3.910), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.25', conduitType: ConduitType.emt, deduct: 12.625, clr: 7.625, gain: 4.786), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '1.5', conduitType: ConduitType.emt, deduct: 12.9375, clr: 8.28125, gain: 5.290), // kick_90.dart value
  const Bender(brand: 'Greenlee 1818', conduitSize: '2.0', conduitType: ConduitType.emt, deduct: 15.0, clr: 9.1875, gain: 6.145), // kick_90.dart value
];

// This helper function calculate 90° gain based on CLR and OD.
// The gainConstant (2 - (pi / 2)) is approximately 0.4292.
// Formula: Gain90 = ((2 - (π / 2)) * CLR) + OD
double calculateGain90(double clr, double od) {
  const double gainConstant = 2 - (math.pi / 2); // Approx. 0.4292
  return (gainConstant * clr) + od;
}

// This helper function calculates the 90° travel for a given CLR.
// Formula: Travel90 = (π * CLR) / 2
double calculateTravel90(double clr) {
  return (math.pi * clr) / 2;
}

const Set<String> mechanicalElectricBenderBrands = {
  'Greenlee 1818',
  'Greenlee 555',
};

// =============================================================================
// Helper functions for Back-to-Back 90 calculations
// =============================================================================

/// Calculates the total linear length of conduit required for a back-to-back 90 bend.
/// This accounts for the desired stub heights, the distance between the bends,
/// and the pipe material saved due to two 90-degree gains.
/// Formula: Cut Length = (Stub 1 + Back to Back Distance + Stub 2) - (2 * Gain)
/// (`cutLength = (s1 + d + s2) - (2 * g)`)
double calculateBtbCutLength(double s1, double d, double s2, double g) {
  return (s1 + d + s2) - (2 * g);
}

/// Determines the first mark (Mark A) on the conduit, measured from the end of the pipe,
/// to achieve the desired Stub 1 height. This accounts for the bender's take-up.
/// Formula: Mark A = Stub 1 - Take-Up
/// (`markA = s1 - t`)
double calculateBtbMarkA(double s1, double t) {
  return s1 - t;
}

/// Calculates the second mark (Mark B) using the "Push Through" method.
/// This mark is measured from the *same end* of the pipe as Mark A, and it accounts
/// for the back-to-back distance and the gain from the second bend.
/// Formula: Mark B (Push Through) = Mark A + (Back to Back Distance - Gain)
/// (`markB = markA + (d - g)`)
double calculateBtbMarkBPushThrough(double markA, double d, double g) {
  return markA + (d - g);
}

/// Calculates the second mark (Mark B) using the "Reverse Bender" method.
/// This mark is also measured from the *same end* of the pipe as Mark A, but it's
/// derived by subtracting the effective length of Stub 2 (after take-up)
/// from the total Cut Length.
/// Formula: Mark B (Reverse Bender) = Cut Length - (Stub 2 - Take-Up)
/// (`markB = cutLength - (s2 - t)`)
double calculateBtbMarkBReverseBender(double cutLength, double s2, double t) {
  return cutLength - (s2 - t);
}
