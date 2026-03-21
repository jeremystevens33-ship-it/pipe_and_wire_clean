import 'dart:math' as math;

enum BendingMethod { arrow, centerline }
enum ConduitType { emt, imc, rigid, pvc }
enum MarkBMethod { pushThrough, reverseBender } // Kept as it's already in bending_data.dart

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
  const Bender(brand: 'IDEAL', model: '74-031', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.34, deduct: 5.0, gain: 1.86), // kick_90.dart value
  const Bender(brand: 'IDEAL', model: '74-032', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.0, deduct: 6.0, gain: 2.15), // kick_90.dart value
  const Bender(brand: 'IDEAL', model: '74-033', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.5, deduct: 8.0, gain: 2.79), // kick_90.dart value
  const Bender(brand: 'IDEAL', model: '74-036', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.75, deduct: 11.0, gain: 4.18), // kick_90.dart value

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

  const Bender(brand: 'Greenlee 881', conduitSize: '2.5', conduitType: ConduitType.rigid, deduct: 15.0, clr: 13.5, gain: 5.8), // kick_90.dart value
  const Bender(brand: 'Greenlee 881', conduitSize: '3.0', conduitType: ConduitType.rigid, deduct: 19.0, clr: 16.0, gain: 6.87), // kick_90.dart value
  const Bender(brand: 'Greenlee 881', conduitSize: '3.5', conduitType: ConduitType.rigid, deduct: 22.25, clr: 18.625, gain: 8.0), // kick_90.dart value
  const Bender(brand: 'Greenlee 881', conduitSize: '4.0', conduitType: ConduitType.rigid, deduct: 25.5, clr: 20.875, gain: 8.96), // kick_90.dart value

  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 13.0, clr: 7.25, gain: 3.11), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 15.0, clr: 8.25, gain: 3.54), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '2.0', conduitType: ConduitType.rigid, deduct: 16.25, clr: 9.5, gain: 4.08), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '2.5', conduitType: ConduitType.rigid, deduct: 19.5, clr: 12.5, gain: 5.36), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '3.0', conduitType: ConduitType.rigid, deduct: 22.0, clr: 15.0, gain: 6.44), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '3.5', conduitType: ConduitType.rigid, deduct: 25.0, clr: 17.5, gain: 7.51), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '4.0', conduitType: ConduitType.rigid, deduct: 28.0, clr: 20.0, gain: 8.58), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '0.5', conduitType: ConduitType.pvc, deduct: 8.5, clr: 4.5, gain: 1.93), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '0.75', conduitType: ConduitType.pvc, deduct: 10.0, clr: 5.4375, gain: 2.33), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.0', conduitType: ConduitType.pvc, deduct: 12.625, clr: 6.9375, gain: 2.98), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.25', conduitType: ConduitType.pvc, deduct: 13.0, clr: 7.25, gain: 3.11), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '1.5', conduitType: ConduitType.pvc, deduct: 15.0, clr: 8.25, gain: 3.54), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '2.0', conduitType: ConduitType.pvc, deduct: 16.25, clr: 9.5, gain: 4.08), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '2.5', conduitType: ConduitType.pvc, deduct: 19.5, clr: 11.4375, gain: 4.91), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '3.0', conduitType: ConduitType.pvc, deduct: 22.0, clr: 13.75, gain: 5.9), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '3.5', conduitType: ConduitType.pvc, deduct: 25.0, clr: 16.0, gain: 6.86), // kick_90.dart value
  const Bender(brand: 'Greenlee 884/885', conduitSize: '4.0', conduitType: ConduitType.pvc, deduct: 28.0, clr: 18.25, gain: 7.83), // kick_90.dart value
];

// This helper function calculate 90° gain based on CLR and OD.
// The gainConstant (2 - (pi / 2)) is approximately 0.4292.
double calculateGain90(double clr, double od) {
  const double gainConstant = 2 - (math.pi / 2); // Approx. 0.4292
  return (gainConstant * clr) + od;
}

// This helper function calculates the 90° travel for a given CLR.
double calculateTravel90(double clr) {
  return (math.pi * clr) / 2;
}

const Set<String> mechanicalElectricBenderBrands = {
  'Greenlee 1818',
  'Greenlee 555',
  'Greenlee 881',
  'Greenlee 884/885',
};