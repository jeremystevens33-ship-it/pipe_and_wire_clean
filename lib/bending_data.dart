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

  // Serialization for storing custom benders
  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'displayName': displayName,
        'conduitSize': conduitSize,
        'conduitType': conduitType.toString().split('.').last,
        'clr': clr,
        'deduct': deduct,
        'gain': gain,
      };

  // Deserialization for loading custom benders
  factory Bender.fromJson(Map<String, dynamic> json) => Bender(
        brand: json['brand'],
        model: json['model'],
        displayName: json['displayName'],
        conduitSize: json['conduitSize'],
        conduitType: ConduitType.values.firstWhere(
            (e) => e.toString().split('.').last == json['conduitType'],
            orElse: () => ConduitType.emt),
        clr: (json['clr'] as num).toDouble(),
        deduct: (json['deduct'] as num).toDouble(),
        gain: (json['gain'] as num).toDouble(),
      );
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
  // ===== GARDNER BENDER =====
  const Bender(brand: 'Gardner Bender', model: '960 Big Ben', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 3.69, deduct: 5.0, gain: 2.29),
  const Bender(brand: 'Gardner Bender', model: '961 Big Ben', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 4.74, deduct: 6.0, gain: 2.96),
  const Bender(brand: 'Gardner Bender', model: '961 Big Ben', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 4.74, deduct: 6.0, gain: 2.87),
  const Bender(brand: 'Gardner Bender', model: '962 Big Ben', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 5.81, deduct: 8.0, gain: 3.66),
  const Bender(brand: 'Gardner Bender', model: '962 Big Ben', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 5.81, deduct: 8.0, gain: 3.54),

  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.375, deduct: 7.625, gain: 2.584),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.375, deduct: 8.5, gain: 3.228),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.5, deduct: 11.0, gain: 3.953),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 7.84375, deduct: 13.0, gain: 4.877),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '1.5', conduitType: ConduitType.emt, clr: 8.375, deduct: 13.5, gain: 5.336),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '2.0', conduitType: ConduitType.emt, clr: 9.65625, deduct: 15.5, gain: 6.342),

  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 4.375, deduct: 7.75, gain: 2.718),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 5.3125, deduct: 9.0, gain: 3.330),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 6.21875, deduct: 11.0, gain: 3.984),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '1.25', conduitType: ConduitType.rigid, clr: 7.71875, deduct: 12.75, gain: 4.973),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '1.5', conduitType: ConduitType.rigid, clr: 8.234375, deduct: 13.5, gain: 5.435),
  const Bender(brand: 'Gardner Bender Cyclone B2000', conduitSize: '2.0', conduitType: ConduitType.rigid, clr: 9.453125, deduct: 15.75, gain: 6.432),

  // ===== GARDNER BENDER SIDEWINDER (MECHANICAL) =====
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.25, deduct: 6.5, gain: 2.53),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.375, deduct: 7.875, gain: 3.228),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.75, deduct: 10.75, gain: 4.059),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 8.75, deduct: 13.0, gain: 5.266),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '1.5', conduitType: ConduitType.emt, clr: 8.28125, deduct: 13.0, gain: 5.29),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '2.0', conduitType: ConduitType.emt, clr: 9.1875, deduct: 15.0, gain: 6.145),

  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 4.375, deduct: 5.0625, gain: 2.718),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 4.5, deduct: 7.5, gain: 2.981),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 5.75, deduct: 8.125, gain: 3.783),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '1.25', conduitType: ConduitType.rigid, clr: 7.25, deduct: 13.0, gain: 4.768),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '1.5', conduitType: ConduitType.rigid, clr: 8.25, deduct: 15.0, gain: 5.441),
  const Bender(brand: 'Gardner Bender Sidewinder', conduitSize: '2.0', conduitType: ConduitType.rigid, clr: 9.5, deduct: 16.25, gain: 6.452),

  // ===== GREENLEE =====
  // Site-Rite® Hand Benders (Formula: Gain90 = (0.4292 * CLR) + OD)
  const Bender(brand: 'Greenlee', model: '840', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.1875, deduct: 5.0, gain: 2.503),
  const Bender(brand: 'Greenlee', model: '841', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.125, deduct: 6.0, gain: 3.122),
  const Bender(brand: 'Greenlee', model: '841', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 5.125, deduct: 6.0, gain: 3.040),
  const Bender(brand: 'Greenlee', model: '842', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.5, deduct: 8.0, gain: 3.953),
  const Bender(brand: 'Greenlee', model: '842', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 6.5, deduct: 8.0, gain: 3.840),
  const Bender(brand: 'Greenlee', model: '843', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.625, deduct: 11.0, gain: 5.641),
  const Bender(brand: 'Greenlee', model: '843', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 9.625, deduct: 11.0, gain: 5.446),

  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '0.5', conduitType: ConduitType.emt, deduct: 7.25, clr: 4.3125, gain: 2.557),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '0.5', conduitType: ConduitType.rigid, deduct: 7.5, clr: 4.25, gain: 2.664),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '0.75', conduitType: ConduitType.emt, deduct: 9.0, clr: 5.5, gain: 3.283),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '0.75', conduitType: ConduitType.rigid, deduct: 9.0, clr: 5.4375, gain: 3.384),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '1.0', conduitType: ConduitType.emt, deduct: 11.0, clr: 7.0, gain: 4.167),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '1.0', conduitType: ConduitType.rigid, deduct: 11.0, clr: 6.9375, gain: 4.293),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '1.25', conduitType: ConduitType.emt, deduct: 14.0, clr: 8.8125, gain: 5.292),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 14.0, clr: 8.75, gain: 5.416),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '1.5', conduitType: ConduitType.emt, deduct: 12.75, clr: 8.375, gain: 5.336),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 14.25, clr: 8.25, gain: 5.441),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '2.0', conduitType: ConduitType.emt, deduct: 13.375, clr: 9.25, gain: 6.176),
  const Bender(brand: 'Greenlee 555', model: '555', conduitSize: '2.0', conduitType: ConduitType.rigid, deduct: 16.125, clr: 9.0, gain: 6.238),

  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '0.5', conduitType: ConduitType.rigid, deduct: 6.0, clr: 2.65625, gain: 1.980),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '0.75', conduitType: ConduitType.rigid, deduct: 8.125, clr: 4.50000, gain: 2.981),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '1.0', conduitType: ConduitType.rigid, deduct: 10.25, clr: 5.87500, gain: 3.837),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 12.375, clr: 7.12500, gain: 4.729),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 15.0, clr: 9.00000, gain: 5.762),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '2.0', conduitType: ConduitType.rigid, deduct: 16.3125, clr: 10.50000, gain: 6.882),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '0.75', conduitType: ConduitType.emt, deduct: 8.6875, clr: 5.09375, gain: 3.106),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '1.0', conduitType: ConduitType.emt, deduct: 10.25, clr: 6.40625, gain: 3.910),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '1.25', conduitType: ConduitType.emt, deduct: 12.625, clr: 7.625, gain: 4.786),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '1.5', conduitType: ConduitType.emt, deduct: 12.9375, clr: 8.28125, gain: 5.290),
  const Bender(brand: 'Greenlee 1818', model: '1818', conduitSize: '2.0', conduitType: ConduitType.emt, deduct: 15.0, clr: 9.1875, gain: 6.145),

  // ===== IDEAL =====
  const Bender(brand: 'Ideal', model: '74-031', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.34375, deduct: 5.0, gain: 2.570),
  const Bender(brand: 'Ideal', model: '74-032', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.203125, deduct: 6.0, gain: 3.155),
  const Bender(brand: 'Ideal', model: '74-032', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 5.203125, deduct: 6.0, gain: 3.073),
  const Bender(brand: 'Ideal', model: '74-033', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 7.0, deduct: 8.0, gain: 4.167),
  const Bender(brand: 'Ideal', model: '74-033', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 7.0, deduct: 8.0, gain: 4.054),
  const Bender(brand: 'Ideal', model: '74-036', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.75, deduct: 11.0, gain: 5.694),
  const Bender(brand: 'Ideal', model: '74-036', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 9.75, deduct: 11.0, gain: 5.499),

  // ===== KLEIN (IRON) =====
  const Bender(brand: 'Klein (Iron)', model: '56208', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.3125, deduct: 5.0, gain: 2.557),
  const Bender(brand: 'Klein (Iron)', model: '56209', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.125, deduct: 6.0, gain: 3.122),
  const Bender(brand: 'Klein (Iron)', model: '56209', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 5.125, deduct: 6.0, gain: 3.040),
  const Bender(brand: 'Klein (Iron)', model: '56210', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.5, deduct: 8.0, gain: 3.953),
  const Bender(brand: 'Klein (Iron)', model: '56210', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 6.5, deduct: 8.0, gain: 3.840),
  const Bender(brand: 'Klein (Iron)', model: '56211', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.625, deduct: 11.0, gain: 5.641),
  const Bender(brand: 'Klein (Iron)', model: '56211', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 9.625, deduct: 11.0, gain: 5.446),

  // ===== KLEIN (ALUMINUM) =====
  const Bender(brand: 'Klein (Aluminum)', model: '56206', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 5.0, deduct: 5.0, gain: 2.854),
  const Bender(brand: 'Klein (Aluminum)', model: '56207', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 6.0, deduct: 6.0, gain: 3.497),
  const Bender(brand: 'Klein (Aluminum)', model: '56207', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 6.0, deduct: 6.0, gain: 3.415),

  // ===== MILWAUKEE =====
  const Bender(brand: 'Milwaukee', model: '48-22-4080', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.5, deduct: 5.0, gain: 2.637),
  const Bender(brand: 'Milwaukee', model: '48-22-4081', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.25, deduct: 6.0, gain: 3.175),
  const Bender(brand: 'Milwaukee', model: '48-22-4081', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 5.25, deduct: 6.0, gain: 3.093),
  const Bender(brand: 'Milwaukee', model: '48-22-4082', conduitSize: '1.0', conduitType: ConduitSize.emt, clr: 6.5, deduct: 8.0, gain: 3.953),
  const Bender(brand: 'Milwaukee', model: '48-22-4082', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 6.5, deduct: 8.0, gain: 3.840),
];
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

const Set<String> mechanicalBenderBrands = {
  'Greenlee 1818',
  'Gardner Bender Sidewinder',
};

const Set<String> electricBenderBrands = {
  'Greenlee 555',
  'Gardner Bender Cyclone B2000',
};

const Set<String> mechanicalElectricBenderBrands = {
  ...mechanicalBenderBrands,
  ...electricBenderBrands,
};

// =============================================================================
// Centralized Bender Selection Logic
// =============================================================================

/// Returns grouped brand lists for dropdowns (Hand, Mechanical, Electric).
List<Map<String, String>> getGroupedBenderBrands() {
  final handBenders = benderDatabase
      .where((b) => !mechanicalElectricBenderBrands.contains(b.brand))
      .map((b) => b.brand).toSet().toList()..sort();

  final mechanical = benderDatabase
      .where((b) => mechanicalBenderBrands.contains(b.brand))
      .map((b) => b.brand).toSet().toList()..sort();

  final electric = benderDatabase
      .where((b) => electricBenderBrands.contains(b.brand))
      .map((b) => b.brand).toSet().toList()..sort();

  return [
    {'type': 'header', 'name': 'HAND BENDERS'},
    ...handBenders.map((name) => {'type': 'bender', 'name': name}),
    {'type': 'header', 'name': 'MECHANICAL BENDERS'},
    ...mechanical.map((name) => {'type': 'bender', 'name': name}),
    {'type': 'header', 'name': 'ELECTRIC BENDERS'},
    ...electric.map((name) => {'type': 'bender', 'name': name}),
  ];
}

/// Returns a map of pipe sizes filtered by the capacity of the selected brand.
Map<String, String> getFilteredPipeSizes(String? brand) {
  if (brand == null) return pipeSizes;

  final List<String> availableSizes = [];

  // Rules based on brand names
  if (brand.contains('555') ||
      brand.contains('1818') ||
      brand.contains('Cyclone') ||
      brand.contains('Sidewinder')) {
    // Machine/Electric Benders: Capped at 2"
    final int maxIndex = pipeSizeOrder.indexOf('2.0');
    availableSizes.addAll(pipeSizeOrder.sublist(0, maxIndex + 1));
  } else if (brand.contains('Aluminum')) {
    // Specialized Klein Aluminum: Capped at 3/4"
    final int maxIndex = pipeSizeOrder.indexOf('0.75');
    availableSizes.addAll(pipeSizeOrder.sublist(0, maxIndex + 1));
  } else if (brand.contains('Milwaukee')) {
    // Milwaukee Iron Hand Benders: Capped at 1"
    final int maxIndex = pipeSizeOrder.indexOf('1.0');
    availableSizes.addAll(pipeSizeOrder.sublist(0, maxIndex + 1));
  } else {
    // Standard Hand Benders (Ideal, Greenlee, Klein Iron, Big Ben): Capped at 1-1/4"
    final int maxIndex = pipeSizeOrder.indexOf('1.25');
    availableSizes.addAll(pipeSizeOrder.sublist(0, maxIndex + 1));
  }

  return Map.fromEntries(
    pipeSizes.entries.where((entry) => availableSizes.contains(entry.key)),
  );
}

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
