import 'dart:math' as math;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum BendingMethod { notch, centerline, hook }
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
        model: json['model'] ?? json['brand'],
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

/// Centralized storage for custom benders
class BenderStore {
  static const String _storageKey = 'rack_custom_benders';

  /// Loads the list of custom benders from the phone's memory.
  static Future<List<Bender>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => Bender.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Saves or Updates a bender in the phone's memory.
  static Future<void> save(Bender bender) async {
    final list = await load();

    // Overwrite Logic: Remove any bender with same name, size, and type
    list.removeWhere((b) =>
        b.brand == bender.brand &&
        b.conduitSize == bender.conduitSize &&
        b.conduitType == bender.conduitType);

    list.add(bender);

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// Deletes a bender from memory.
  static Future<void> delete(String nickname) async {
    final list = await load();
    list.removeWhere((b) => b.brand == nickname);

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
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
  // ===========================================================================
  // HAND BENDERS
  // ===========================================================================

  // Gardner Bender (Hand)
  const Bender(brand: 'Gardner Bender', model: '960 Big Ben', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 3.69, deduct: 5.0, gain: 2.29),
  const Bender(brand: 'Gardner Bender', model: '961 Big Ben', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 4.74, deduct: 6.0, gain: 2.96),
  const Bender(brand: 'Gardner Bender', model: '961 Big Ben', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 4.74, deduct: 6.0, gain: 2.87),
  const Bender(brand: 'Gardner Bender', model: '962 Big Ben', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 5.81, deduct: 8.0, gain: 3.66),
  const Bender(brand: 'Gardner Bender', model: '962 Big Ben', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 5.81, deduct: 8.0, gain: 3.54),

  // Greenlee (Hand)
  const Bender(brand: 'Greenlee', model: '840', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.1875, deduct: 5.0, gain: 2.503),
  const Bender(brand: 'Greenlee', model: '841', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.125, deduct: 6.0, gain: 3.122),
  const Bender(brand: 'Greenlee', model: '841', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 5.125, deduct: 6.0, gain: 3.040),
  const Bender(brand: 'Greenlee', model: '842', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.5, deduct: 8.0, gain: 3.953),
  const Bender(brand: 'Greenlee', model: '842', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 6.5, deduct: 8.0, gain: 3.840),
  const Bender(brand: 'Greenlee', model: '843', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.625, deduct: 11.0, gain: 5.641),
  const Bender(brand: 'Greenlee', model: '843', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 9.625, deduct: 11.0, gain: 5.446),

  // Ideal (Hand)
  const Bender(brand: 'Ideal', model: '74-031', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.34375, deduct: 5.0, gain: 2.570),
  const Bender(brand: 'Ideal', model: '74-032', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.203125, deduct: 6.0, gain: 3.155),
  const Bender(brand: 'Ideal', model: '74-032', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 5.203125, deduct: 6.0, gain: 3.073),
  const Bender(brand: 'Ideal', model: '74-033', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 7.0, deduct: 8.0, gain: 4.167),
  const Bender(brand: 'Ideal', model: '74-033', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 7.0, deduct: 8.0, gain: 4.054),
  const Bender(brand: 'Ideal', model: '74-066', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.75, deduct: 11.0, gain: 5.694),
  const Bender(brand: 'Ideal', model: '74-066', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 9.75, deduct: 11.0, gain: 5.499),

  // Klein (Hand)
  const Bender(brand: 'Klein (Iron)', model: '56208', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.3125, deduct: 5.0, gain: 2.557),
  const Bender(brand: 'Klein (Iron)', model: '56209', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.125, deduct: 6.0, gain: 3.122),
  const Bender(brand: 'Klein (Iron)', model: '56209', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 5.125, deduct: 6.0, gain: 3.040),
  const Bender(brand: 'Klein (Iron)', model: '56210', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.5, deduct: 8.0, gain: 3.953),
  const Bender(brand: 'Klein (Iron)', model: '56210', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 6.5, deduct: 8.0, gain: 3.840),
  const Bender(brand: 'Klein (Iron)', model: '56211', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 9.625, deduct: 11.0, gain: 5.641),
  const Bender(brand: 'Klein (Iron)', model: '56211', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 9.625, deduct: 11.0, gain: 5.446),
  const Bender(brand: 'Klein (Aluminum)', model: '56206', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 5.0, deduct: 5.0, gain: 2.854),
  const Bender(brand: 'Klein (Aluminum)', model: '56207', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 6.0, deduct: 6.0, gain: 3.497),
  const Bender(brand: 'Klein (Aluminum)', model: '56207', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 6.0, deduct: 6.0, gain: 3.415),

  // Milwaukee (Hand)
  const Bender(brand: 'Milwaukee', model: '48-22-4080', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.5, deduct: 5.0, gain: 2.637),
  const Bender(brand: 'Milwaukee', model: '48-22-4081', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.25, deduct: 6.0, gain: 3.175),
  const Bender(brand: 'Milwaukee', model: '48-22-4081', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 5.25, deduct: 6.0, gain: 3.093),
  const Bender(brand: 'Milwaukee', model: '48-22-4082', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.5, deduct: 8.0, gain: 3.953),
  const Bender(brand: 'Milwaukee', model: '48-22-4082', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 6.5, deduct: 8.0, gain: 3.840),

  // ===========================================================================
  // MECHANICAL BENDERS
  // ===========================================================================

  // Greenlee 1818
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '0.5', conduitType: ConduitType.rigid, deduct: 6.0, clr: 2.65625, gain: 1.980),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '0.75', conduitType: ConduitType.rigid, deduct: 8.125, clr: 4.50000, gain: 2.981),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '1.0', conduitType: ConduitType.rigid, deduct: 10.25, clr: 5.87500, gain: 3.837),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 12.375, clr: 7.12500, gain: 4.729),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 15.0, clr: 9.00000, gain: 5.762),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '2.0', conduitType: ConduitType.rigid, deduct: 16.3125, clr: 10.50000, gain: 6.882),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '0.75', conduitType: ConduitType.emt, deduct: 8.6875, clr: 5.09375, gain: 3.106),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '1.0', conduitType: ConduitType.emt, deduct: 10.25, clr: 6.40625, gain: 3.910),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '1.25', conduitType: ConduitType.emt, deduct: 12.625, clr: 7.625, gain: 4.786),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '1.5', conduitType: ConduitType.emt, deduct: 12.9375, clr: 8.28125, gain: 5.290),
  const Bender(brand: 'Greenlee 1818', model: '', conduitSize: '2.0', conduitType: ConduitType.emt, deduct: 15.0, clr: 9.1875, gain: 6.145),

  // Gardner Bender Sidewinder
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.25, deduct: 6.5, gain: 2.53),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.375, deduct: 7.875, gain: 3.228),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.75, deduct: 10.75, gain: 4.059),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 8.75, deduct: 13.0, gain: 5.266),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '1.5', conduitType: ConduitType.emt, clr: 8.28125, deduct: 13.0, gain: 5.29),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '2.0', conduitType: ConduitType.emt, clr: 9.1875, deduct: 15.0, gain: 6.145),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 4.375, deduct: 5.0625, gain: 2.718),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 4.5, deduct: 7.5, gain: 2.981),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 5.75, deduct: 8.125, gain: 3.783),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '1.25', conduitType: ConduitType.rigid, clr: 7.25, deduct: 13.0, gain: 4.768),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '1.5', conduitType: ConduitType.rigid, clr: 8.25, deduct: 15.0, gain: 5.441),
  const Bender(brand: 'Gardner Bender Sidewinder', model: '', conduitSize: '2.0', conduitType: ConduitType.rigid, clr: 9.5, deduct: 16.25, gain: 6.452),

  // ===========================================================================
  // ELECTRIC BENDERS
  // ===========================================================================

  // Greenlee 555
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '0.5', conduitType: ConduitType.emt, deduct: 7.25, clr: 4.3125, gain: 2.557),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '0.5', conduitType: ConduitType.rigid, deduct: 7.5, clr: 4.25, gain: 2.664),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '0.75', conduitType: ConduitType.emt, deduct: 9.0, clr: 5.5, gain: 3.283),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '0.75', conduitType: ConduitType.rigid, deduct: 9.0, clr: 5.4375, gain: 3.384),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '1.0', conduitType: ConduitType.emt, deduct: 11.0, clr: 7.0, gain: 4.167),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '1.0', conduitType: ConduitType.rigid, deduct: 11.0, clr: 6.9375, gain: 4.293),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '1.25', conduitType: ConduitType.emt, deduct: 14.0, clr: 8.8125, gain: 5.292),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '1.25', conduitType: ConduitType.rigid, deduct: 14.0, clr: 8.75, gain: 5.416),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '1.5', conduitType: ConduitType.emt, deduct: 12.75, clr: 8.375, gain: 5.336),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '1.5', conduitType: ConduitType.rigid, deduct: 14.25, clr: 8.25, gain: 5.441),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '2.0', conduitType: ConduitType.emt, deduct: 13.375, clr: 9.25, gain: 6.176),
  const Bender(brand: 'Greenlee 555', model: '', conduitSize: '2.0', conduitType: ConduitType.rigid, deduct: 16.125, clr: 9.0, gain: 6.238),

  // Gardner Bender Cyclone
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '0.5', conduitType: ConduitType.emt, clr: 4.375, deduct: 7.625, gain: 2.584),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '0.75', conduitType: ConduitType.emt, clr: 5.375, deduct: 8.5, gain: 3.228),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '1.0', conduitType: ConduitType.emt, clr: 6.5, deduct: 11.0, gain: 3.953),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '1.25', conduitType: ConduitType.emt, clr: 7.84375, deduct: 13.0, gain: 4.877),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '1.5', conduitType: ConduitType.emt, clr: 8.375, deduct: 13.5, gain: 5.336),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '2.0', conduitType: ConduitType.emt, clr: 9.65625, deduct: 15.5, gain: 6.342),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '0.5', conduitType: ConduitType.rigid, clr: 4.375, deduct: 7.75, gain: 2.718),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '0.75', conduitType: ConduitType.rigid, clr: 5.3125, deduct: 9.0, gain: 3.330),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '1.0', conduitType: ConduitType.rigid, clr: 6.21875, deduct: 11.0, gain: 3.984),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '1.25', conduitType: ConduitType.rigid, clr: 7.71875, deduct: 12.75, gain: 4.973),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '1.5', conduitType: ConduitType.rigid, clr: 8.234375, deduct: 13.5, gain: 5.435),
  const Bender(brand: 'Gardner Bender Cyclone B2000', model: '', conduitSize: '2.0', conduitType: ConduitType.rigid, clr: 9.453125, deduct: 15.75, gain: 6.432),

  // ===========================================================================
  // HYDRAULIC BENDERS
  // ===========================================================================

  // Greenlee 881 Cam Track
  const Bender(brand: 'Greenlee 881', model: '', conduitSize: '2.5', conduitType: ConduitType.rigid, clr: 13.5, deduct: 21.5, gain: 8.669),
  const Bender(brand: 'Greenlee 881', model: '', conduitSize: '3.0', conduitType: ConduitType.rigid, clr: 15.0, deduct: 24.25, gain: 9.938),
  const Bender(brand: 'Greenlee 881', model: '', conduitSize: '3.5', conduitType: ConduitType.rigid, clr: 17.5, deduct: 28.25, gain: 11.511),
  const Bender(brand: 'Greenlee 881', model: '', conduitSize: '4.0', conduitType: ConduitType.rigid, clr: 20.875, deduct: 32.5, gain: 13.460),
  const Bender(brand: 'Greenlee 881', model: '', conduitSize: '2.5', conduitType: ConduitType.emt, clr: 13.5, deduct: 21.5, gain: 8.669),
  const Bender(brand: 'Greenlee 881', model: '', conduitSize: '3.0', conduitType: ConduitType.emt, clr: 15.0, deduct: 24.0, gain: 9.938),
  const Bender(brand: 'Greenlee 881', model: '', conduitSize: '3.5', conduitType: ConduitType.emt, clr: 17.5, deduct: 27.75, gain: 11.511),
  const Bender(brand: 'Greenlee 881', model: '', conduitSize: '4.0', conduitType: ConduitType.emt, clr: 20.875, deduct: 32.25, gain: 13.460),

  // Gardner Bender Ultra-E
  const Bender(brand: 'Gardner Bender Ultra-E', model: '', conduitSize: '2.5', conduitType: ConduitType.rigid, clr: 13.5, deduct: 15.625, gain: 8.669),
  const Bender(brand: 'Gardner Bender Ultra-E', model: '', conduitSize: '3.0', conduitType: ConduitType.rigid, clr: 15.875, deduct: 18.25, gain: 10.314),
  const Bender(brand: 'Gardner Bender Ultra-E', model: '', conduitSize: '3.5', conduitType: ConduitType.rigid, clr: 18.5, deduct: 21.25, gain: 11.940),
  const Bender(brand: 'Gardner Bender Ultra-E', model: '', conduitSize: '4.0', conduitType: ConduitType.rigid, clr: 21.0, deduct: 24.125, gain: 13.513),
  const Bender(brand: 'Gardner Bender Ultra-E', model: '', conduitSize: '2.5', conduitType: ConduitType.emt, clr: 13.5, deduct: 15.625, gain: 8.669),
  const Bender(brand: 'Gardner Bender Ultra-E', model: '', conduitSize: '3.0', conduitType: ConduitType.emt, clr: 15.875, deduct: 18.25, gain: 10.314),
  const Bender(brand: 'Gardner Bender Ultra-E', model: '', conduitSize: '3.5', conduitType: ConduitType.emt, clr: 18.5, deduct: 21.25, gain: 11.940),
  const Bender(brand: 'Gardner Bender Ultra-E', model: '', conduitSize: '4.0', conduitType: ConduitType.emt, clr: 21.0, deduct: 24.125, gain: 13.513),
];

// This helper function calculate 90° gain based on CLR and OD.
// The gainConstant (2 - (pi / 2)) is approximately 0.4292.
// Formula: Gain90 = ((2 - (π / 2)) * CLR) + OD
double calculateGain90(double clr, double od) {
  const double gainConstant = 2 - (math.pi / 2); // Approx. 0.4292
  return (gainConstant * clr) + od;
}

// Formula: CLR = (Gain90 - OD) / (2 - (π / 2))
double calculateCLRFromGain(double gain, double od) {
  const double gainConstant = 2 - (math.pi / 2);
  if (od <= 0 || gain <= od) return 0.0;
  return (gain - od) / gainConstant;
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

const Set<String> hydraulicBenderBrands = {
  'Greenlee 881',
  'Gardner Bender Ultra-E',
};

const Set<String> mechanicalElectricBenderBrands = {
  ...mechanicalBenderBrands,
  ...electricBenderBrands,
  ...hydraulicBenderBrands,
};

// =============================================================================
// Centralized Bender Selection Logic
// =============================================================================

/// Returns grouped brand lists for dropdowns (Hand, Mechanical, Electric, Hydraulic).
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

  final hydraulic = benderDatabase
      .where((b) => hydraulicBenderBrands.contains(b.brand))
      .map((b) => b.brand).toSet().toList()..sort();

  return [
    {'type': 'header', 'name': 'HAND BENDERS'},
    ...handBenders.map((name) => {'type': 'bender', 'name': name}),
    {'type': 'header', 'name': 'MECHANICAL BENDERS'},
    ...mechanical.map((name) => {'type': 'bender', 'name': name}),
    {'type': 'header', 'name': 'ELECTRIC BENDERS'},
    ...electric.map((name) => {'type': 'bender', 'name': name}),
    {'type': 'header', 'name': 'HYDRAULIC BENDERS'},
    ...hydraulic.map((name) => {'type': 'bender', 'name': name}),
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
  } else if (brand.contains('881') || brand.contains('Ultra-E')) {
    // Large Hydraulic Benders: 2.5" to 4"
    availableSizes.addAll(['2.5', '3.0', '3.5', '4.0']);
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
// BENDER CLEARANCE / COLLISION CHECK
// =============================================================================

/// Calculates where the 90° curve physically ends on the pipe, measured from
/// the end (0 mark).
///
/// Formula: End of Curve = Stub - (CLR + Pipe OD / 2) + 90° Travel
double calculateCurveEnd({
  required double stub,
  required double clr,
  required double pipeOD,
}) {
  final travel90 = (math.pi * clr) / 2.0;
  return stub - (clr + (pipeOD / 2.0)) + travel90;
}

/// Returns true if the bender shoe has enough "straight" pipe to seat properly
/// after a 90° bend.
///
/// [markB] is the physical mark where the bender hook sits for the next bend.
/// [curveEnd] is the result of calculateCurveEnd().
bool isBenderClearanceSafe({
  required double markB,
  required double curveEnd,
  double buffer = 0.5,
}) {
  // If the hook mark is at or beyond the end of the curve, we are safe.
  return markB >= (curveEnd + buffer);
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
// =============================================================================
// KICK 90 FORMULAS
// =============================================================================
//
// Field Meaning:
//
// A Kick 90 uses:
//
// Mark A = 90° bend mark
// Mark B = kick bend mark
// Mark C = cut length / overall length
//
// All Kick 90 calculations should be centralized here so
// Kick90, Rack Builder, and future rack tools use the same math.
//
// =============================================================================
// ANGLE HELPERS
// =============================================================================

double degreesToRadians(double degrees) {
  return degrees * math.pi / 180.0;
}

double calculateCosecant(double angleDeg) {
  final radians = degreesToRadians(angleDeg);
  final sine = math.sin(radians);
  if (sine == 0) return 0.0;
  return 1.0 / sine;
}

double calculateTangentHalfAngle(double angleDeg) {
  return math.tan(degreesToRadians(angleDeg / 2.0));
}

// =============================================================================
// KICK 90 DISTANCE BETWEEN BENDS
// =============================================================================
//
// Field Meaning:
//
// Distance from the back of the 90 to the center
// of the kick bend.
//
// Formula:
//
// Distance = Kick Height × Cosecant(angle)
//
// Example:
//
// 5" kick @ 30°
// Distance = 5 × 2 = 10"
//
// Used For:
//
// Mark B
//
double calculateKickDistanceBetweenBends({
  required double kickHeight,
  required double angleDeg,
}) {
  return kickHeight * calculateCosecant(angleDeg);
}

// =============================================================================
// KICK 90 SHRINK
// =============================================================================
//
// Field Meaning:
//
// Shrink created by the kick bend.
//
// Formula:
//
// Shrink = Kick Height × tan(angle / 2)
//
// Example:
//
// 5" kick @ 30°
// Shrink = 5 × .268
// Shrink ≈ 1.34"
//
// Used For:
//
// Mark C / Cut Length
//
double calculateKickShrink({
  required double kickHeight,
  required double angleDeg,
}) {
  return kickHeight * calculateTangentHalfAngle(angleDeg);
}

// =============================================================================
// KICK 90 MARK A
// =============================================================================
//
// Field Meaning:
//
// 90° bend location.
//
// Formula:
//
// Mark A = Stub - Take Up
//
double calculateKick90MarkA({
  required double stub,
  required double takeUp,
}) {
  return stub - takeUp;
}

// =============================================================================
// KICK 90 ARROW TO CENTER ADJUSTMENT
// =============================================================================
//
// Field Meaning:
//
// Distance from the bender arrow to the true
// center of the bend.
//
// Formula:
//
// Arrow Adjustment = π × CLR × (Angle / 2) ÷ 180
//
// In field terms:
//
// This is the arc length from the start of the bend
// to the center of the bend.
//
// Used For:
//
// Arrow Method Mark B
//
// Note:
//
// This is still experimental until we field-test
// and calibrate it per bender.
//
// =============================================================================
// KICK 90 CENTERLINE MARK B
// =============================================================================
//
// Field Meaning:
//
// True center-of-bend location.
//
// Formula:
//
// Mark B =
// (Stub - Gain)
// + Distance Between Bends
// + (Pipe OD / 2)
//
// Used For:
//
// Centerline bending
//
double calculateKick90CenterlineMarkB({
  required double stub,
  required double kickHeight,
  required double angleDeg,
  required double gain90,
  required double pipeOD,
}) {
  final centerOf90 = stub - gain90;

  final distanceBetweenBends =
  calculateKickDistanceBetweenBends(
    kickHeight: kickHeight,
    angleDeg: angleDeg,
  );

  return centerOf90 +
      distanceBetweenBends +
      (pipeOD / 2.0);
}

// =============================================================================
// KICK 90 FINAL MARK B
// =============================================================================
//
// Field Meaning:
//
// Returns the actual Mark B used in the field.
//
// Centerline Method:
//
// Uses the true center-of-bend location.
//
// Arrow Method:
//
// Uses the bender arrow and applies the
// arrow-to-center adjustment.
//
// Note:
//
// Centerline is currently the field-tested
// and recommended method.
//
double calculateKick90MarkB({
  required double stub,
  required double kickHeight,
  required double angleDeg,
  required double gain90,
  required double pipeOD,
  required double clr,
  required double deduct,
  required BendingMethod method,
  bool reverse = false,
}) {
  final centerlineMarkB =
  calculateKick90CenterlineMarkB(
    stub: stub,
    kickHeight: kickHeight,
    angleDeg: angleDeg,
    gain90: gain90,
    pipeOD: pipeOD,
  );

  if (method == BendingMethod.centerline) {
    return centerlineMarkB;
  }

  if (method == BendingMethod.hook) {
    return convertCenterMarkToFrontHookMark(
      centerMark: centerlineMarkB,
      deduct: deduct,
      clr: clr,
      pipeOD: pipeOD,
      angleDeg: angleDeg,
      reverse: reverse,
    );
  }

// BendingMethod.notch is now used as:
// USE NOTCH
//
// Pipe & Wire calculates the true centerline mark,
// then translates that mark to the 45° notch / teardrop mark.
  return convertCenterMarkTo45NotchMark(
    centerMark: centerlineMarkB,
    clr: clr,
    angleDeg: angleDeg,
  );
}

// =============================================================================
// KICK 90 CUT LENGTH / MARK C
// =============================================================================
//
// Field Meaning:
//
// Final cut length of the conduit.
//
// Formula:
//
// Cut Length =
// Stub + Leg + Shrink - Gain
//
// Used For:
//
// Mark C
//
double calculateKick90CutLength({
  required double stub,
  required double leg,
  required double kickHeight,
  required double angleDeg,
  required double gain90,
}) {
  final shrink = calculateKickShrink(
    kickHeight: kickHeight,
    angleDeg: angleDeg,
  );

  return stub + leg + shrink - gain90;
}
// =============================================================================
// KICK 90 FORWARD RACK MARK B
// =============================================================================
//
// Field Meaning:
//
// Used when a rack of Kick 90s all kick forward in the same direction.
//
// In this layout:
//
// - Mark A stays the same
// - Mark C / Cut Length stays the same
// - Mark B shifts back toward the 90 side for each pipe
//
// Real-World Measuring:
//
// The tape is started from the 90 / stub side.
// Because each next pipe must stay parallel while kicking forward,
// the kick mark moves closer to Mark A.
//
// Formula:
//
// Mark B = Base Mark B - (Rack Spacing Offset × tan(angle / 2))
//
// Example:
//
// 2" center-to-center spacing @ 30°
// Shift = 2 × tan(15°)
// Shift ≈ 9/16"
//
// Pipe 1 Mark B = 14 15/16"
// Pipe 2 Mark B = 14 3/8"
// Pipe 3 Mark B = 13 13/16"
//
// Used For:
//
// Forward Kick 90 rack layout
//
double calculateKick90ForwardMarkB({
  required double baseMarkB,
  required double spacingOffset,
  required double angleDeg,
}) {
  final markBShift =
      spacingOffset * calculateTangentHalfAngle(angleDeg);

  return baseMarkB - markBShift;
}
// =============================================================================
// KICK 90 SAME ANGLE PLANE-CHANGE RACK FORMULAS
// =============================================================================
//
// Field Meaning:
//
// Used when a rack of Kick 90s changes plane, and every conduit uses
// the same kick angle.
//
// Real-World Layout:
//
// - Every pipe uses the same angle.
// - Stub height increases by rack spacing.
// - Kick height increases by rack spacing.
// - Distance between bends increases.
// - Mark A moves because the stub gets taller.
// - Mark B moves because both the stub and kick distance increase.
// - Mark C / cut length increases because stub and shrink increase.
//
// Formula:
//
// Pipe Stub = Base Stub + Spacing Offset
//
// Pipe Kick Height = Base Kick Height + Spacing Offset
//
// Distance Between Bends = Pipe Kick Height × Cosecant(angle)
//
// Shrink = Pipe Kick Height × tan(angle / 2)
//
// Mark A = Pipe Stub - Take Up
//
// Mark B =
// (Pipe Stub - Gain)
// + Distance Between Bends
// + (Pipe OD / 2)
//
// Cut Length = Pipe Stub + Leg + Shrink - Gain
//
// Example:
//
// 1/2" EMT
// Milwaukee 48-22-4080
// Base Stub = 7 1/4"
// Leg = 30"
// Take Up = 5"
// Gain = 2.637"
// Pipe OD = 0.706"
// Pipe OD / 2 = 0.353"
//
// Base Kick Height = 5"
// Rack Spacing = 2" center-to-center
// Chosen Kick Angle = 30°
// 30° Cosecant = 2
// tan(15°) = 0.268
//
// Pipe 1:
//
// Pipe Stub = 7 1/4"
// Pipe Kick Height = 5"
// Distance Between Bends = 5 × 2 = 10"
// Mark A = 7.25 - 5 = 2.25" ≈ 2 1/4"
// Mark B = (7.25 - 2.637) + 10 + 0.353 = 14.966" ≈ 15"
// Shrink = 5 × 0.268 = 1.340"
// Mark C = 7.25 + 30 + 1.340 - 2.637 = 35.953" ≈ 36"
//
// Pipe 2:
//
// Pipe Stub = 7 1/4" + 2" = 9 1/4"
// Pipe Kick Height = 5" + 2" = 7"
// Distance Between Bends = 7 × 2 = 14"
// Mark A = 9.25 - 5 = 4.25" ≈ 4 1/4"
// Mark B = (9.25 - 2.637) + 14 + 0.353 = 20.966" ≈ 21"
// Shrink = 7 × 0.268 = 1.876"
// Mark C = 9.25 + 30 + 1.876 - 2.637 = 38.489" ≈ 38 1/2"
//
// Pipe 3:
//
// Pipe Stub = 7 1/4" + 4" = 11 1/4"
// Pipe Kick Height = 5" + 4" = 9"
// Distance Between Bends = 9 × 2 = 18"
// Mark A = 11.25 - 5 = 6.25" ≈ 6 1/4"
// Mark B = (11.25 - 2.637) + 18 + 0.353 = 26.966" ≈ 27"
// Shrink = 9 × 0.268 = 2.412"
// Mark C = 11.25 + 30 + 2.412 - 2.637 = 41.025" ≈ 41"
//
// Floor-Test Marks:
//
// Pipe 1: A = 2 1/4"   B = 15"   C = 36"
// Pipe 2: A = 4 1/4"   B = 21"   C = 38 1/2"
// Pipe 3: A = 6 1/4"   B = 27"   C = 41"
//
// Pattern:
//
// Mark A advances by rack spacing.
//
// Mark A Advance = 2"
//
// Mark B advances by:
//
// Rack Spacing + (Rack Spacing × Cosecant(angle))
//
// Mark B Advance = 2 + (2 × 2)
// Mark B Advance = 6"
//
// Mark C advances by:
//
// Rack Spacing + (Rack Spacing × tan(angle / 2))
//
// Mark C Advance = 2 + (2 × 0.268)
// Mark C Advance = 2.536"
// Mark C Advance ≈ 2 1/2"
//
// Used For:
//
// Parallel Kick 90 racks where all conduits use the same angle
// while changing planes.
//
class Kick90SameAnglePlaneChangeResult {
  const Kick90SameAnglePlaneChangeResult({
    required this.pipeIndex,
    required this.spacingOffset,
    required this.stub,
    required this.kickHeight,
    required this.angleDeg,
    required this.distanceBetweenBends,
    required this.shrink,
    required this.markA,
    required this.markB,
    required this.markC,
  });

  final int pipeIndex;
  final double spacingOffset;
  final double stub;
  final double kickHeight;
  final double angleDeg;
  final double distanceBetweenBends;
  final double shrink;
  final double markA;
  final double markB;
  final double markC;
}
Kick90SameAnglePlaneChangeResult
calculateKick90SameAnglePlaneChange({
  required int pipeIndex,
  required double baseStub,
  required double baseKickHeight,
  required double spacingOffset,
  required double angleDeg,
  required double leg,
  required double takeUp,
  required double gain90,
  required double pipeOD,
  required double clr,
  required BendingMethod method,
  bool reverse = false,
}) {
  final double pipeStub = baseStub + spacingOffset;
  final double pipeKickHeight = baseKickHeight + spacingOffset;

  final double distanceBetweenBends =
  calculateKickDistanceBetweenBends(
    kickHeight: pipeKickHeight,
    angleDeg: angleDeg,
  );

  final double shrink = calculateKickShrink(
    kickHeight: pipeKickHeight,
    angleDeg: angleDeg,
  );

  final double markA = calculateKick90MarkA(
    stub: pipeStub,
    takeUp: takeUp,
  );

  // First calculate the true center-of-bend location.
  final double centerlineMarkB =
      (pipeStub - gain90) +
          distanceBetweenBends +
          (pipeOD / 2.0);

  // Then translate that center mark to the selected
  // physical bender reference.
  final double markB = convertCenterMarkToBenderReference(
    centerMark: centerlineMarkB,
    method: method,
    clr: clr,
    deduct: takeUp,
    pipeOD: pipeOD,
    angleDeg: angleDeg,
    reverse: reverse,
  );

  final double markC =
      pipeStub + leg + shrink - gain90;

  return Kick90SameAnglePlaneChangeResult(
    pipeIndex: pipeIndex,
    spacingOffset: spacingOffset,
    stub: pipeStub,
    kickHeight: pipeKickHeight,
    angleDeg: angleDeg,
    distanceBetweenBends: distanceBetweenBends,
    shrink: shrink,
    markA: markA,
    markB: markB,
    markC: markC,
  );
}
// =============================================================================
// KICK 90 SAME START PLANE-CHANGE RACK FORMULAS
// =============================================================================
//
// Field Meaning:
//
// Used when a rack of Kick 90s changes plane, and every conduit uses
// the same start run from the 90 toward the kick.
//
// Real-World Layout:
//
// - Every pipe uses the same same-start run.
// - Stub height increases by rack spacing.
// - Kick height increases by rack spacing.
// - Each pipe gets its own calculated angle.
// - Each pipe gets its own hypotenuse / distance between bends.
// - Mark A moves because the stub gets taller.
// - Mark B moves because the hypotenuse changes.
// - Mark C / cut length changes because stub and shrink both change.
//
// This bend looks simple in the field, but it is not a constant-multiplier bend.
// The app solves the triangle separately for each conduit.
//
// Formula:
//
// Pipe Stub = Base Stub + Spacing Offset
//
// Pipe Kick Height = Base Kick Height + Spacing Offset
//
// Angle = atan(Pipe Kick Height / Same Start Run)
//
// Distance Between Bends / Hypotenuse =
// sqrt((Same Start Run × Same Start Run) +
//      (Pipe Kick Height × Pipe Kick Height))
//
// Shrink = Pipe Kick Height × tan(angle / 2)
//
// Mark A = Pipe Stub - Take Up
//
// Mark B =
// (Pipe Stub - Gain)
// + Distance Between Bends
// + (Pipe OD / 2)
//
// Cut Length = Pipe Stub + Leg + Shrink - Gain
//
// Example:
//
// 1/2" EMT
// Milwaukee 48-22-4080
// Base Stub = 7 1/4"
// Leg = 30"
// Take Up = 5"
// Gain = 2.637"
// Pipe OD = 0.706"
// Pipe OD / 2 = 0.353"
//
// Base Kick Height = 2"
// Kick Height Spacing = 2"
// Same Start Run = 12"
//
// Pipe 1:
//
// Pipe Stub = 7 1/4"
// Pipe Kick Height = 2"
// Angle = atan(2 / 12) = 9.46° ≈ 9 1/2°
// Distance Between Bends = sqrt(12² + 2²) = 12.166" ≈ 12 3/16"
// Mark A = 7.25 - 5 = 2.25" ≈ 2 1/4"
// Mark B = (7.25 - 2.637) + 12.166 + 0.353 = 17.132" ≈ 17 1/8"
// Shrink = 2 × tan(9.46° / 2) = 0.166"
// Mark C = 7.25 + 30 + 0.166 - 2.637 = 34.779" ≈ 34 3/4"
//
// Pipe 2:
//
// Pipe Stub = 7 1/4" + 2" = 9 1/4"
// Pipe Kick Height = 2" + 2" = 4"
// Angle = atan(4 / 12) = 18.43° ≈ 18 1/2°
// Distance Between Bends = sqrt(12² + 4²) = 12.649" ≈ 12 5/8"
// Mark A = 9.25 - 5 = 4.25" ≈ 4 1/4"
// Mark B = (9.25 - 2.637) + 12.649 + 0.353 = 19.615" ≈ 19 5/8"
// Shrink = 4 × tan(18.43° / 2) = 0.649"
// Mark C = 9.25 + 30 + 0.649 - 2.637 = 37.262" ≈ 37 1/4"
//
// Pipe 3:
//
// Pipe Stub = 7 1/4" + 4" = 11 1/4"
// Pipe Kick Height = 2" + 4" = 6"
// Angle = atan(6 / 12) = 26.57° ≈ 26 1/2°
// Distance Between Bends = sqrt(12² + 6²) = 13.416" ≈ 13 7/16"
// Mark A = 11.25 - 5 = 6.25" ≈ 6 1/4"
// Mark B = (11.25 - 2.637) + 13.416 + 0.353 = 22.382" ≈ 22 3/8"
// Shrink = 6 × tan(26.57° / 2) = 1.416"
// Mark C = 11.25 + 30 + 1.416 - 2.637 = 40.029" ≈ 40"
//
// Floor-Test Marks:
//
// Pipe 1: A = 2 1/4"   B = 17 1/8"   C = 34 3/4"   Angle ≈ 9 1/2°
// Pipe 2: A = 4 1/4"   B = 19 5/8"   C = 37 1/4"   Angle ≈ 18 1/2°
// Pipe 3: A = 6 1/4"   B = 22 3/8"   C = 40"       Angle ≈ 26 1/2°
//
// Pattern:
//
// Mark A advances evenly by rack spacing.
//
// Mark B does not advance evenly because the hypotenuse changes.
//
// Mark C does not advance evenly because shrink changes.
//
// Used For:
//
// Plane-change Kick 90 racks where the start run is fixed,
// but every conduit has a different kick height and calculated angle.
//
class Kick90SameStartPlaneChangeResult {
  const Kick90SameStartPlaneChangeResult({
    required this.pipeIndex,
    required this.spacingOffset,
    required this.stub,
    required this.kickHeight,
    required this.sameStartRun,
    required this.angleDeg,
    required this.distanceBetweenBends,
    required this.shrink,
    required this.markA,
    required this.markB,
    required this.markC,
    required this.isPossible,
  });

  final int pipeIndex;
  final double spacingOffset;
  final double stub;
  final double kickHeight;
  final double sameStartRun;
  final double angleDeg;
  final double distanceBetweenBends;
  final double shrink;
  final double markA;
  final double markB;
  final double markC;
  final bool isPossible;
}

Kick90SameStartPlaneChangeResult calculateKick90SameStartPlaneChange({
  required int pipeIndex,
  required double baseStub,
  required double baseKickHeight,
  required double spacingOffset,
  required double sameStartRun,
  required double leg,
  required double takeUp,
  required double gain90,
  required double pipeOD,
}) {
  final pipeStub = baseStub + spacingOffset;
  final pipeKickHeight = baseKickHeight + spacingOffset;

  final markA = calculateKick90MarkA(
    stub: pipeStub,
    takeUp: takeUp,
  );

  if (sameStartRun <= 0 || pipeKickHeight <= 0) {
    return Kick90SameStartPlaneChangeResult(
      pipeIndex: pipeIndex,
      spacingOffset: spacingOffset,
      stub: pipeStub,
      kickHeight: pipeKickHeight,
      sameStartRun: sameStartRun,
      angleDeg: 0.0,
      distanceBetweenBends: 0.0,
      shrink: 0.0,
      markA: markA,
      markB: 0.0,
      markC: pipeStub + leg - gain90,
      isPossible: false,
    );
  }

  final angleRad = math.atan(pipeKickHeight / sameStartRun);
  final angleDeg = angleRad * 180.0 / math.pi;

  final distanceBetweenBends = math.sqrt(
    (sameStartRun * sameStartRun) +
        (pipeKickHeight * pipeKickHeight),
  );

  final shrink = calculateKickShrink(
    kickHeight: pipeKickHeight,
    angleDeg: angleDeg,
  );

  final markB = (pipeStub - gain90) +
      distanceBetweenBends +
      (pipeOD / 2.0);

  final markC = pipeStub + leg + shrink - gain90;

  return Kick90SameStartPlaneChangeResult(
    pipeIndex: pipeIndex,
    spacingOffset: spacingOffset,
    stub: pipeStub,
    kickHeight: pipeKickHeight,
    sameStartRun: sameStartRun,
    angleDeg: angleDeg,
    distanceBetweenBends: distanceBetweenBends,
    shrink: shrink,
    markA: markA,
    markB: markB,
    markC: markC,
    isPossible: true,
  );
}
// =============================================================================
// DEVELOPED LENGTH / TRAVEL
// =============================================================================
//
// Field Meaning:
//
// Developed Length (Travel) is the amount of conduit consumed by the bend.
//
// Formula:
//
// Developed Length = CLR × Angle Multiplier
//
// Common Angle Multipliers:
//
// 10°  = 0.174
// 15°  = 0.262
// 20°  = 0.349
// 22.5° = 0.393
// 25°  = 0.436
// 30°  = 0.524
// 35°  = 0.611
// 40°  = 0.698
// 45°  = 0.785
// 60°  = 1.047
// 90°  = 1.571
//
// Example:
//
// CLR = 5"
//
// 25° bend:
//
// Developed Length = 5 × 0.436
// Developed Length = 2.18"
//
// 90° bend:
//
// Developed Length = 5 × 1.571
// Developed Length = 7.85"
//
// =============================================================================
// RADIUS ADJUSTMENT / CENTER OF BEND
// =============================================================================
//
// Field Meaning:
//
// Radius Adjustment is the distance from the start (or end)
// of the bend to the center of the bend.
//
// Formula:
//
// Radius Adjustment = Developed Length ÷ 2
//
// Example:
//
// CLR = 5"
//
// 25° bend:
//
// Developed Length = 2.18"
// Radius Adjustment = 1.09"
//
// 90° bend:
//
// Developed Length = 7.85"
// Radius Adjustment = 3.93"
//
// Note:
//
// Radius Adjustment is simply half of the developed length.
//
// =============================================================================
// KICK 90 SAME ANGLE SAME-PLANE RACK FORMULAS
// =============================================================================
//
// Field Meaning:
//
// Used when a rack of Kick 90s stays in the same plane, and every conduit uses
// the same kick angle and same kick height.
//
// Real-World Layout:
//
// This is basically parallel 90s with the same kick added to each pipe.
//
// - Every pipe uses the same kick height.
// - Every pipe uses the same kick angle.
// - Stub height increases by rack spacing.
// - Leg length increases by rack spacing.
// - Mark A moves by rack spacing.
// - Mark B moves by rack spacing.
// - Mark C / cut length increases by double the rack spacing.
// - Angle stays the same for every pipe.
//
// Formula:
//
// Pipe Stub = Base Stub + Spacing Offset
//
// Pipe Leg = Base Leg + Spacing Offset
//
// Distance Between Bends = Kick Height × Cosecant(angle)
//
// Shrink = Kick Height × tan(angle / 2)
//
// Mark A = Pipe Stub - Take Up
//
// Mark B =
// (Pipe Stub - Gain)
// + Distance Between Bends
// + (Pipe OD / 2)
//
// Cut Length = Pipe Stub + Pipe Leg + Shrink - Gain
//
// Important:
//
// If USE NOTCH is selected, Pipe & Wire first calculates the true centerline
// Mark B, then translates that mark to the 45° notch / teardrop mark.
//
// That means Mark B may not match a plain centerline hand calculation, but it
// should still advance by rack spacing from pipe to pipe.
//
// Example:
//
// Base Stub = 8"
// Base Leg = 66"
// Kick Height = 3"
// Kick Angle = 15°
// Rack Spacing = 2" center-to-center
//
// Pipe 1:
// Mark A = 3"
// Mark B = 18 1/2" using notch method
// Mark C = 71 3/4"
// Angle = 15°
//
// Pipe 2:
// Mark A = 5"
// Mark B = 20 1/2"
// Mark C = 75 3/4"
// Angle = 15°
//
// Pipe 3:
// Mark A = 7"
// Mark B = 22 1/2"
// Mark C = 79 3/4"
// Angle = 15°
//
// Used For:
//
// Same Plane - Same Angle Kick 90 rack layout
//
class Kick90SameAngleSamePlaneResult {
  const Kick90SameAngleSamePlaneResult({
    required this.pipeIndex,
    required this.spacingOffset,
    required this.stub,
    required this.leg,
    required this.kickHeight,
    required this.angleDeg,
    required this.markA,
    required this.markB,
    required this.markC,
  });

  final int pipeIndex;
  final double spacingOffset;
  final double stub;
  final double leg;
  final double kickHeight;
  final double angleDeg;
  final double markA;
  final double markB;
  final double markC;
}

Kick90SameAngleSamePlaneResult calculateKick90SameAngleSamePlane({
  required int pipeIndex,
  required double baseStub,
  required double baseLeg,
  required double kickHeight,
  required double spacingOffset,
  required double angleDeg,
  required double takeUp,
  required double gain90,
  required double pipeOD,
  required double clr,
  required BendingMethod method,
}) {
  final pipeStub = baseStub + spacingOffset;
  final pipeLeg = baseLeg + spacingOffset;

  final markA = calculateKick90MarkA(
    stub: pipeStub,
    takeUp: takeUp,
  );

  final markB = calculateKick90MarkB(
    stub: pipeStub,
    kickHeight: kickHeight,
    angleDeg: angleDeg,
    gain90: gain90,
    pipeOD: pipeOD,
    clr: clr,
    deduct: takeUp,
    method: method,
  );

  final markC = calculateKick90CutLength(
    stub: pipeStub,
    leg: pipeLeg,
    kickHeight: kickHeight,
    angleDeg: angleDeg,
    gain90: gain90,
  );

  return Kick90SameAngleSamePlaneResult(
    pipeIndex: pipeIndex,
    spacingOffset: spacingOffset,
    stub: pipeStub,
    leg: pipeLeg,
    kickHeight: kickHeight,
    angleDeg: angleDeg,
    markA: markA,
    markB: markB,
    markC: markC,
  );
}
// =============================================================================
// KICK 90 SAME START / MATCH BEND SAME-PLANE RACK FORMULAS
// =============================================================================
//
// Field Meaning:
//
// Used when a rack of Kick 90s stays in the same plane, and every conduit
// kicks to the same height but matches a farther bend location as the rack grows.
//
// Real-World Layout:
//
// This is like parallel 90s with a kick after the 90, but instead of using the
// same kick angle on every pipe, the user gives the first 90-to-match-bend
// distance.
//
// - Every pipe uses the same kick height.
// - Stub height increases by rack spacing.
// - Leg length increases by rack spacing.
// - Distance between bends increases by rack spacing.
// - Mark A moves by rack spacing.
// - Mark B moves by stub spacing plus the added bend distance.
// - Mark C / cut length increases by stub spacing + leg spacing, with shrink
//   changing because the angle changes.
// - Angle changes for each pipe.
//
// Formula:
//
// Pipe Stub = Base Stub + Spacing Offset
//
// Pipe Leg = Base Leg + Spacing Offset
//
// Pipe Distance Between Bends = Base Match Bend Distance + Spacing Offset
//
// Angle = asin(Kick Height / Pipe Distance Between Bends)
//
// Shrink = Kick Height × tan(angle / 2)
//
// Mark A = Pipe Stub - Take Up
//
// Mark B =
// (Pipe Stub - Gain)
// + Pipe Distance Between Bends
// + (Pipe OD / 2)
//
// Cut Length = Pipe Stub + Pipe Leg + Shrink - Gain
//
// Important:
//
// If Kick Height is greater than the pipe distance between bends, the geometry
// is impossible because asin() cannot calculate that angle.
//
// If USE NOTCH is selected, Pipe & Wire first calculates the true centerline
// Mark B, then translates that mark to the 45° notch / teardrop mark.
//
// Used For:
//
// Same Plane - 90 to Match Bend Kick 90 rack layout
//

double calculateKick90NotchMarkFromCenterline({
  required double centerlineMark,
  required double angleDeg,
  required double clr,
}) {
  if (clr <= 0 || angleDeg <= 0) {
    return centerlineMark;
  }

  final notchAngleOffset = 45.0 - (angleDeg / 2.0);
  final arcAdjustment =
      clr * 2 * math.pi * (notchAngleOffset / 360.0);

  return centerlineMark - arcAdjustment;
}
double calculateKick90MarkBFromDistanceBetweenBends({
  required double stub,
  required double distanceBetweenBends,
  required double angleDeg,
  required double gain90,
  required double pipeOD,
  required double clr,
  required double deduct,
  required BendingMethod method,
  bool reverse = false,
}) {
  final double centerlineMarkB =
      (stub - gain90) +
          distanceBetweenBends +
          (pipeOD / 2.0);

  return convertCenterMarkToBenderReference(
    centerMark: centerlineMarkB,
    method: method,
    clr: clr,
    deduct: deduct,
    pipeOD: pipeOD,
    angleDeg: angleDeg,
    reverse: reverse,
  );
}
class Kick90SameStartSamePlaneResult {
  const Kick90SameStartSamePlaneResult({
    required this.pipeIndex,
    required this.spacingOffset,
    required this.stub,
    required this.leg,
    required this.kickHeight,
    required this.distanceBetweenBends,
    required this.angleDeg,
    required this.markA,
    required this.markB,
    required this.markC,
  });

  final int pipeIndex;
  final double spacingOffset;
  final double stub;
  final double leg;
  final double kickHeight;
  final double distanceBetweenBends;
  final double angleDeg;
  final double markA;
  final double markB;
  final double markC;
}

Kick90SameStartSamePlaneResult calculateKick90SameStartSamePlane({
  required int pipeIndex,
  required double baseStub,
  required double baseLeg,
  required double kickHeight,
  required double baseMatchBendDistance,
  required double spacingOffset,
  required double takeUp,
  required double gain90,
  required double pipeOD,
  required double clr,
  required BendingMethod method,
}) {
  final pipeStub = baseStub + spacingOffset;
  final pipeLeg = baseLeg + spacingOffset;
  final pipeDistanceBetweenBends =
      baseMatchBendDistance + spacingOffset;

  if (pipeDistanceBetweenBends <= 0 ||
      kickHeight > pipeDistanceBetweenBends) {
    return Kick90SameStartSamePlaneResult(
      pipeIndex: pipeIndex,
      spacingOffset: spacingOffset,
      stub: pipeStub,
      leg: pipeLeg,
      kickHeight: kickHeight,
      distanceBetweenBends: pipeDistanceBetweenBends,
      angleDeg: 0,
      markA: 0,
      markB: 0,
      markC: 0,
    );
  }

  final angleRad =
  math.asin(kickHeight / pipeDistanceBetweenBends);
  final angleDeg = angleRad * 180 / math.pi;

  final markA = calculateKick90MarkA(
    stub: pipeStub,
    takeUp: takeUp,
  );

  final markB = calculateKick90MarkBFromDistanceBetweenBends(
    stub: pipeStub,
    distanceBetweenBends: pipeDistanceBetweenBends,
    angleDeg: angleDeg,
    gain90: gain90,
    pipeOD: pipeOD,
    clr: clr,
    deduct: takeUp,
    method: method,
  );

  final markC = calculateKick90CutLength(
    stub: pipeStub,
    leg: pipeLeg,
    kickHeight: kickHeight,
    angleDeg: angleDeg,
    gain90: gain90,
  );

  return Kick90SameStartSamePlaneResult(
    pipeIndex: pipeIndex,
    spacingOffset: spacingOffset,
    stub: pipeStub,
    leg: pipeLeg,
    kickHeight: kickHeight,
    distanceBetweenBends: pipeDistanceBetweenBends,
    angleDeg: angleDeg,
    markA: markA,
    markB: markB,
    markC: markC,
  );
}
// ============================================================
// RADIUS ADJUSTMENT (CENTER OF BEND)
// ============================================================
//
// Radius Adjustment is the distance from the beginning of a bend
// to the center of the bend, measured along the bend itself.
//
// It is simply one-half of the developed length for the selected
// bend angle and bender centerline radius (CLR).
//
// Formula:
//
//   Developed Length = CLR × Angle × π / 180
//
//   Radius Adjustment = Developed Length ÷ 2
//
// or:
//
//   Radius Adjustment = CLR × Angle × π / 360
//
// This value has two primary uses:
//
// 1. Geometry / Layout
//    Used when positioning the center of a bend relative to an
//    obstruction (offsets, kicks, saddles, segmented bends, etc.).
//    It ensures the center of the bend lands at the intended
//    location rather than the beginning of the bend.
//
// 2. Bending Method Translation
//    Used to translate center-of-bend measurements to another
//    reference mark on the bender, such as the 45° notch/teardrop.
//
// Radius Adjustment is independent of the bending method.
// It always represents the true center of the bend.
//
// ------------------------------------------------------------
// Example
// ------------------------------------------------------------
//
// Bender CLR = 4.5"
// Bend Angle = 30°
//
// Developed Length
//
//   = 4.5 × 30 × π ÷ 180
//   = 2.356"
//
// Radius Adjustment
//
//   = 2.356 ÷ 2
//   = 1.178"
//
// Therefore:
//
// The center of the bend is located 1.178" from the beginning
// of the bend (measured along the arc). This value is then used
// either:
//
// • to correctly position the bend around an obstruction
//   (geometry/layout), or
//
// • to translate the center-of-bend measurement to the selected
//   bending reference (such as the 45° notch/teardrop).

// =============================================================================
// FRONT OF HOOK ADJUSTMENT
// =============================================================================

// Field Meaning:
//
// Used for mechanical, electric, and future hydraulic benders that reference
// the FRONT OF THE HOOK instead of the hand-bender 45° notch / teardrop.
//
// Pipe & Wire first calculates the true center-of-bend mark, then translates
// that center mark to the correct FRONT OF HOOK mark.
//
// This section is intentionally separate from the 45° notch / teardrop method
// so it can be field-tested and adjusted without changing the hand-bender logic.
//
// =============================================================================
// THEORY
// =============================================================================
//
// The bender's deduct / take-up mark is based on the outside of the finished 90.
// To find the true start of bend from that reference:
//
// Start Adjustment = Deduct - (CLR + Pipe OD / 2)
//
// where:
//
// CLR = Centerline Radius of the bender
// Pipe OD / 2 = Outside radius of the conduit
//
// Once the true start of bend is known, the center of any bend is found by using
// the Radius Adjustment:
//
// Radius Adjustment = Developed Length / 2
//
// Developed Length = CLR × Angle × π / 180
//
// So:
//
// Front Hook Adjustment = Start Adjustment + Radius Adjustment
//
// For this first version, Pipe & Wire places the front-of-hook mark AFTER the
// true center mark:
//
// Front Hook Mark = Center Mark + Front Hook Adjustment
//
// User instruction:
//
// Place the FRONT OF THE HOOK on the calculated mark.
//
// =============================================================================
// EXAMPLE
// =============================================================================
//
// Greenlee / Chicago 1818
// 1" Rigid
//
// CLR = 5 7/8" = 5.875"
// Deduct = 10 1/4" = 10.25"
// Pipe OD = 1.315"
// Angle = 45°
//
// Start Adjustment:
//
//   10.25 - (5.875 + 1.315 / 2)
//   10.25 - (5.875 + 0.6575)
//   10.25 - 6.5325
//   3.7175"
//   ≈ 3 11/16"
//
// Radius Adjustment for 45°:
//
//   Developed Length = 5.875 × 45 × π / 180
//   Developed Length ≈ 4.614"
//
//   Radius Adjustment = 4.614 / 2
//   Radius Adjustment ≈ 2.307"
//   ≈ 2 5/16"
//
// Front Hook Adjustment:
//
//   3.7175 + 2.307
//   6.0245"
//   ≈ 6"
//
// If the true center mark is 25":
//
//   Front Hook Mark = 25 + 6
//   Front Hook Mark = 31"
//
// The user marks 31" on the pipe and places the FRONT OF THE HOOK on that mark.

double calculateFrontHookStartAdjustment({
  required double deduct,
  required double clr,
  required double pipeOD,
}) {
  return deduct - (clr + (pipeOD / 2.0));
}

double calculateFrontHookAdjustment({
  required double deduct,
  required double clr,
  required double pipeOD,
  required double angleDeg,
}) {
  final startAdjustment = calculateFrontHookStartAdjustment(
    deduct: deduct,
    clr: clr,
    pipeOD: pipeOD,
  );

  final radiusAdjustment = calculateRadiusAdjustment(
    clr: clr,
    angleDeg: angleDeg,
  );

  return startAdjustment + radiusAdjustment;
}

double convertCenterMarkToFrontHookMark({
  required double centerMark,
  required double deduct,
  required double clr,
  required double pipeOD,
  required double angleDeg,
  bool reverse = false,
}) {
  final frontHookAdjustment = calculateFrontHookAdjustment(
    deduct: deduct,
    clr: clr,
    pipeOD: pipeOD,
    angleDeg: angleDeg,
  );

  // Normal orientation:
  // The front of the hook is farther along the tape than the true center mark.
  //
  // Reverse orientation:
  // The bender is turned around, so the hook mark falls before the center mark.
  return reverse
      ? centerMark - frontHookAdjustment
      : centerMark + frontHookAdjustment;
}
// =============================================================================
// 45° NOTCH / TEARDROP METHOD
// =============================================================================
//
// Field Meaning:
//
// Uses the bender's 45° notch, teardrop, or saved 45° mark
// instead of the arrow.
//
// Formula:
//
// Notch Correction =
//
// Radius Adjustment (45°)
//
// minus
//
// Radius Adjustment (Desired Angle)
//
// Angles Less Than 45°
//
// ADD correction to center mark.
//
// Angles Greater Than 45°
//
// SUBTRACT correction from center mark.
//
// Example:
//
// CLR = 5"
//
// 45° Radius Adjustment:
//
// 5 × 0.785 ÷ 2
// = 1.96"
//
// 25° Radius Adjustment:
//
// 5 × 0.436 ÷ 2
// = 1.09"
//
// Correction:
//
// 1.96 - 1.09
// = 0.87"
//
// Therefore:
//
// A 25° bend using the 45° notch
// requires a mark approximately 7/8"
// beyond the true center mark.
//
// ============================================================================
// =============================================================================
// DEVELOPED LENGTH / RADIUS ADJUSTMENT / 45° NOTCH HELPERS
// =============================================================================

double calculateDevelopedLength({
  required double clr,
  required double angleDeg,
}) {
  return clr * degreesToRadians(angleDeg);
}

double calculateRadiusAdjustment({
  required double clr,
  required double angleDeg,
}) {
  return calculateDevelopedLength(
    clr: clr,
    angleDeg: angleDeg,
  ) /
      2.0;
}

double calculate45NotchCorrection({
  required double clr,
  required double angleDeg,
}) {
  final radiusAdjustment45 = calculateRadiusAdjustment(
    clr: clr,
    angleDeg: 45.0,
  );

  final radiusAdjustmentDesired = calculateRadiusAdjustment(
    clr: clr,
    angleDeg: angleDeg,
  );

  return (radiusAdjustment45 - radiusAdjustmentDesired).abs();
}

double convertCenterMarkTo45NotchMark({
  required double centerMark,
  required double clr,
  required double angleDeg,
  bool reverse = false,
}) {
  final correction = calculate45NotchCorrection(
    clr: clr,
    angleDeg: angleDeg,
  );

  if (angleDeg < 45.0) {
    return reverse ? centerMark - correction : centerMark + correction;
  }

  if (angleDeg > 45.0) {
    return reverse ? centerMark + correction : centerMark - correction;
  }

  return centerMark;
}
// =============================================================================
// CENTER MARK TO SELECTED BENDER REFERENCE
// =============================================================================
//
// Every calculation should first determine the TRUE CENTER-OF-BEND mark.
//
// This helper then converts that true center mark into the physical reference
// the user will place on the conduit:
//
// CENTERLINE:
//   Returns the true center mark unchanged.
//
// NOTCH:
//   Converts the true center mark to the 45° notch / teardrop.
//
// HOOK:
//   Converts the true center mark to the front of the machine-bender hook.
//
// Normal orientation uses the standard measuring direction.
// Reverse orientation turns the bender around and reverses the translation.
//
// =============================================================================

double convertCenterMarkToBenderReference({
  required double centerMark,
  required BendingMethod method,
  required double clr,
  required double deduct,
  required double pipeOD,
  required double angleDeg,
  bool reverse = false,
}) {
  switch (method) {
    case BendingMethod.centerline:
      return centerMark;

    case BendingMethod.notch:
      return convertCenterMarkTo45NotchMark(
        centerMark: centerMark,
        clr: clr,
        angleDeg: angleDeg,
        reverse: reverse,
      );

    case BendingMethod.hook:
      return convertCenterMarkToFrontHookMark(
        centerMark: centerMark,
        deduct: deduct,
        clr: clr,
        pipeOD: pipeOD,
        angleDeg: angleDeg,
        reverse: reverse,
      );
  }
}
// =============================================================================
// 3-POINT SADDLE CALCULATIONS (PUSH-THROUGH METHOD)
// =============================================================================

// =============================================================================
// 3-POINT SADDLE DISTANCE BETWEEN MARKS
// =============================================================================
//
// Field Meaning:
//
// This is the distance between your center mark and your outside marks.
// We add the pipe width to this measurement to make sure the saddle
// clears the corners of the obstruction and to account for the
// bender facing the same direction for all three bends.
//
// Formula:
//
// Distance Between Marks = (Obstruction Height × Multiplier) + Pipe OD
//
// Multipliers for common angles:
// - 22.5 degrees = 2.6
// - 30 degrees = 2.0
// - 45 degrees = 1.4
//
// Example:
//
// If you have a 2 inch obstruction and you are using 30 degree
// outside angles:
// (2 inches × 2.0) + Pipe OD = 4 inches + Pipe OD.
//
// Used For:
//
// Finding the locations of Mark A and Mark C relative to Mark B.
//
double calculateSaddle3PointGap({
  required double height,
  required double angleDeg,
  required double pipeOD,
}) {
  final cosecant = 1.0 / math.sin(angleDeg * math.pi / 180.0);
  return (height * cosecant) + pipeOD;
}

// =============================================================================
// 3-POINT SADDLE SHRINK PER OFFSET
// =============================================================================
//
// Field Meaning:
//
// This is how much the pipe will shorten during the first half of the saddle
// (getting to the top of the obstruction). This must be added to your 
// distance measurement to find the true center mark.
//
// Formula:
//
// Shrink = Obstruction Height × tan(Outside Angle / 2)
//
// Used For:
//
// Mark B (Center Mark)
//
double calculateSaddle3PointShrinkPerOffset({
  required double height,
  required double angleDeg,
}) {
  return height * math.tan((angleDeg / 2.0) * math.pi / 180.0);
}

// =============================================================================
// 3-POINT SADDLE TOTAL SHRINK
// =============================================================================
//
// Field Meaning:
//
// This is the combined shrink from both halves of the saddle.
//
// Formula:
//
// Total Shrink = 2 × (Obstruction Height × tan(Outside Angle / 2))
//
// Used For:
//
// Mark D (Cut Length)
//
double calculateSaddle3PointTotalShrink({
  required double height,
  required double angleDeg,
}) {
  final individualShrink = calculateSaddle3PointShrinkPerOffset(height: height, angleDeg: angleDeg);
  return individualShrink * 2.0;
}

// =============================================================================
// 3-POINT SADDLE MARKS (PUSH-THROUGH)
// =============================================================================
//
// Field Meaning:
//
// These are the three marks on your pipe where you will place
// your bender notch.
//
// Step 1: Mark B is the Center of Bend (Distance + Shrink).
// Step 2: Outside Marks are placed at Mark B +/- the Gap.
//
// Pro Method (Push-Through):
//
// Use the NOTCH on your bender for all three marks.
// Bend Mark A (1st Bend) to the outside angle.
// Push the pipe forward through the bender and bend Mark B (2nd Bend) to double that angle.
// Push the pipe forward through the bender and bend Mark C (3rd Bend) to the outside angle.
//
// The app automatically determines which mark (Nearest or Furthest) 
// should be Mark A to maximize your leverage on the pipe.
//
double calculateSaddle3PointMark({
  required double centerDistance,
  required double height,
  required double angleDeg,
  required double pipeOD,
  required double clr,
  required double deduct,
  required String markType, // 'A', 'B', or 'C'
  bool reverse = false,
  BendingMethod method = BendingMethod.notch,
}) {
  final individualShrink = calculateSaddle3PointShrinkPerOffset(height: height, angleDeg: angleDeg);
  final gap = calculateSaddle3PointGap(height: height, angleDeg: angleDeg, pipeOD: pipeOD);

  final centerlineMarkB = centerDistance + individualShrink;
  double centerlineMark = 0.0;

  if (markType == 'A') {
    centerlineMark = centerlineMarkB - gap;
  } else if (markType == 'B') {
    centerlineMark = centerlineMarkB;
  } else {
    centerlineMark = centerlineMarkB + gap;
  }

  if (method == BendingMethod.centerline) {
    return centerlineMark;
  }

  if (method == BendingMethod.hook) {
    // Mark B uses double the angle for the center bend
    final targetAngle = (markType == 'B') ? (angleDeg * 2.0) : angleDeg;
    return convertCenterMarkToFrontHookMark(
      centerMark: centerlineMark,
      deduct: deduct,
      clr: clr,
      pipeOD: pipeOD,
      angleDeg: targetAngle,
      reverse: reverse,
    );
  }

  // Always translate to the notch for push-through convenience
  // Mark B uses the center angle (double the outside angle)
  final targetAngle = (markType == 'B') ? (angleDeg * 2.0) : angleDeg;

  return convertCenterMarkTo45NotchMark(
    centerMark: centerlineMark,
    clr: clr,
    angleDeg: targetAngle,
    reverse: reverse,
  );
}

// =============================================================================
// 3-POINT SADDLE CUT LENGTH / MARK D
// =============================================================================
//
// Field Meaning:
//
// This is the total length of pipe you need to cut before bending.
//
// Formula:
//
// Cut Length = Total Run Length + Total Shrink
//
double calculateSaddle3PointCutLength({
  required double runLength,
  required double height,
  required double angleDeg,
}) {
  final totalShrink = calculateSaddle3PointTotalShrink(height: height, angleDeg: angleDeg);
  return runLength + totalShrink;
}

class Saddle3PointResult {
  final double markA;
  final double markB;
  final double markC;
  final double cutLength;
  Saddle3PointResult({required this.markA, required this.markB, required this.markC, required this.cutLength});
}

Saddle3PointResult calculateSaddle3Point({
  required double centerDistance,
  required double height,
  required double angleDeg,
  required double pipeOD,
  required double clr,
  required double deduct,
  required double runLength,
  BendingMethod method = BendingMethod.notch,
}) {
  // Leverage-First Logic:
  // If the center is more than half the pipe length away,
  // we start at the furthest mark and push back toward the start.
  final bool isLong = centerDistance > (runLength / 2.0);

  double mA, mC;
  if (isLong) {
    mA = calculateSaddle3PointMark(centerDistance: centerDistance, height: height, angleDeg: angleDeg, pipeOD: pipeOD, clr: clr, deduct: deduct, markType: 'C', reverse: true, method: method);
    mC = calculateSaddle3PointMark(centerDistance: centerDistance, height: height, angleDeg: angleDeg, pipeOD: pipeOD, clr: clr, deduct: deduct, markType: 'A', reverse: true, method: method);
  } else {
    mA = calculateSaddle3PointMark(centerDistance: centerDistance, height: height, angleDeg: angleDeg, pipeOD: pipeOD, clr: clr, deduct: deduct, markType: 'A', reverse: false, method: method);
    mC = calculateSaddle3PointMark(centerDistance: centerDistance, height: height, angleDeg: angleDeg, pipeOD: pipeOD, clr: clr, deduct: deduct, markType: 'C', reverse: false, method: method);
  }

  final mB = calculateSaddle3PointMark(centerDistance: centerDistance, height: height, angleDeg: angleDeg, pipeOD: pipeOD, clr: clr, deduct: deduct, markType: 'B', reverse: isLong, method: method);
  final mD = calculateSaddle3PointCutLength(runLength: runLength, height: height, angleDeg: angleDeg);

  return Saddle3PointResult(markA: mA, markB: mB, markC: mC, cutLength: mD);
}

// =============================================================================
// 4-POINT SADDLE CALCULATIONS (PUSH-THROUGH METHOD)
// =============================================================================

// =============================================================================
// 4-POINT SADDLE RISER DISTANCE
// =============================================================================
//
// Field Meaning:
//
// This is the distance between the two marks on each side of the saddle.
// It is the hypotenuse of the riser triangle.
//
// Formula:
//
// Riser Distance = Obstruction Height × Cosecant(Angle)
//
// Used For:
//
// Finding the locations of Mark A (relative to B) and Mark D (relative to C).
//
double calculateSaddle4PointRiserDistance({
  required double height,
  required double angleDeg,
}) {
  final cosecant = 1.0 / math.sin(angleDeg * math.pi / 180.0);
  return height * cosecant;
}

// =============================================================================
// 4-POINT SADDLE SHRINK
// =============================================================================
//
// Field Meaning:
//
// This is how much the pipe will shorten to reach the top of the obstruction.
// This must be added to your center distance to find the "True Center" mark.
//
// Formula:
//
// Shrink = Obstruction Height × tan(Angle / 2)
//
// Used For:
//
// Finding the True Center of the saddle on the straight pipe.
//
double calculateSaddle4PointShrinkPerOffset({
  required double height,
  required double angleDeg,
}) {
  return height * math.tan((angleDeg / 2.0) * math.pi / 180.0);
}

// =============================================================================
// 4-POINT SADDLE MARKS (PUSH-THROUGH)
// =============================================================================
//
// Field Meaning:
//
// These are the four marks on your pipe where you will place
// your bender notch.
//
// Step 1: Find True Center = Distance to Center + Shrink.
// Step 2: Offset marks B and C from center by (Half Width + Radius Adjustment).
// Step 3: Offset marks A and D from B and C by the Riser Distance.
//
// Radius Adjustment:
//
// We add the Radius Adjustment to move the centers of bends B and C 
// slightly outside the edges of the box. This ensures the "flat" part 
// of the riser clears the corners of the obstruction perfectly.
//
// Pro Method:
//
// Use the NOTCH on your bender for all four marks.
// Bend A, push to B, push to C, push to D.
//
// Example (Textbook):
//
// 14" Height, 24" Width, 30° Angle, 60" to Center, 4" Radius Adjustment.
// Shrink = 14 × 0.268 = 3.75"
// Riser = 14 × 2.0 = 28"
// True Center = 60 + 3.75 = 63.75"
// Half Width + Rad Adj = 12 + 4 = 16"
//
// Mark B = 63.75 - 16 = 47.75"
// Mark C = 63.75 + 16 = 79.75"
// Mark A = 47.75 - 28 = 19.75"
// Mark D = 79.75 + 28 = 107.75"
//
class Saddle4PointResult {
  final double markA;
  final double markB;
  final double markC;
  final double markD;
  final double cutLength;
  Saddle4PointResult({required this.markA, required this.markB, required this.markC, required this.markD, required this.cutLength});
}

Saddle4PointResult calculateSaddle4Point({
  required double distToCenter,
  required double height,
  required double angleDeg,
  required double obstructionLength,
  required double pipeOD,
  required double clr,
  required double deduct,
  required double runLength,
  BendingMethod method = BendingMethod.notch,
}) {
  final shrink = calculateSaddle4PointShrinkPerOffset(height: height, angleDeg: angleDeg);
  final riser = calculateSaddle4PointRiserDistance(height: height, angleDeg: angleDeg);
  final radAdj = calculateRadiusAdjustment(clr: clr, angleDeg: angleDeg);

  final trueCenter = distToCenter + shrink;
  final halfWidthOffset = (obstructionLength / 2.0) + radAdj;

  final centerlineB = trueCenter - halfWidthOffset;
  final centerlineC = trueCenter + halfWidthOffset;
  final centerlineA = centerlineB - riser;
  final centerlineD = centerlineC + riser;

  // Leverage Logic
  // If the center is more than half the pipe length away,
  // we start at the furthest mark and push forward (reverse=true).
  final bool isLong = distToCenter > (runLength / 2.0);

  double rA, rB, rC, rD;
  if (isLong) {
    // START AT THE FURTHEST MARK (centerlineD) and push forward through C, B, A
    if (method == BendingMethod.hook) {
      rA = convertCenterMarkToFrontHookMark(centerMark: centerlineD, deduct: deduct, clr: clr, pipeOD: pipeOD, angleDeg: angleDeg, reverse: true);
      rB = convertCenterMarkToFrontHookMark(centerMark: centerlineC, deduct: deduct, clr: clr, pipeOD: pipeOD, angleDeg: angleDeg, reverse: true);
      rC = convertCenterMarkToFrontHookMark(centerMark: centerlineB, deduct: deduct, clr: clr, pipeOD: pipeOD, angleDeg: angleDeg, reverse: true);
      rD = convertCenterMarkToFrontHookMark(centerMark: centerlineA, deduct: deduct, clr: clr, pipeOD: pipeOD, angleDeg: angleDeg, reverse: true);
    } else {
      rA = convertCenterMarkTo45NotchMark(centerMark: centerlineD, clr: clr, angleDeg: angleDeg, reverse: true);
      rB = convertCenterMarkTo45NotchMark(centerMark: centerlineC, clr: clr, angleDeg: angleDeg, reverse: true);
      rC = convertCenterMarkTo45NotchMark(centerMark: centerlineB, clr: clr, angleDeg: angleDeg, reverse: true);
      rD = convertCenterMarkTo45NotchMark(centerMark: centerlineA, clr: clr, angleDeg: angleDeg, reverse: true);
    }
  } else {
    // START AT THE NEAREST MARK (centerlineA) and push forward through B, C, D
    if (method == BendingMethod.hook) {
      rA = convertCenterMarkToFrontHookMark(centerMark: centerlineA, deduct: deduct, clr: clr, pipeOD: pipeOD, angleDeg: angleDeg, reverse: false);
      rB = convertCenterMarkToFrontHookMark(centerMark: centerlineB, deduct: deduct, clr: clr, pipeOD: pipeOD, angleDeg: angleDeg, reverse: false);
      rC = convertCenterMarkToFrontHookMark(centerMark: centerlineC, deduct: deduct, clr: clr, pipeOD: pipeOD, angleDeg: angleDeg, reverse: false);
      rD = convertCenterMarkToFrontHookMark(centerMark: centerlineD, deduct: deduct, clr: clr, pipeOD: pipeOD, angleDeg: angleDeg, reverse: false);
    } else {
      rA = convertCenterMarkTo45NotchMark(centerMark: centerlineA, clr: clr, angleDeg: angleDeg, reverse: false);
      rB = convertCenterMarkTo45NotchMark(centerMark: centerlineB, clr: clr, angleDeg: angleDeg, reverse: false);
      rC = convertCenterMarkTo45NotchMark(centerMark: centerlineC, clr: clr, angleDeg: angleDeg, reverse: false);
      rD = convertCenterMarkTo45NotchMark(centerMark: centerlineD, clr: clr, angleDeg: angleDeg, reverse: false);
    }
  }

  if (method == BendingMethod.centerline) {
    if (isLong) {
      rA = centerlineD; rB = centerlineC; rC = centerlineB; rD = centerlineA;
    } else {
      rA = centerlineA; rB = centerlineB; rC = centerlineC; rD = centerlineD;
    }
  }

  final totalShrink = shrink * 2.0;
  final cutLength = runLength + totalShrink;

  return Saddle4PointResult(markA: rA, markB: rB, markC: rC, markD: rD, cutLength: cutLength);
}

/// RACK SUPPORT PLANNING FORMULA
/// Goal: Zero-fraction, field-logical supports placed relative to 90° bends.
/// 
/// Field Standard (The 24-inch Rule):
/// Struts are placed exactly 24" (2ft) on BOTH sides of the 90° corner (Back of 90).
/// This provides stable anchoring and ensures the strut doesn't interfere with the bend radius.
/// 
/// Calculation Method:
/// 1. Next Support (Before Turn): Measure back 24" from the Back of 90 mark.
/// 2. Next Support (After Turn): Measure forward 24" from the Back of 90 mark.
/// 
/// Note: We do NOT measure around the curve. We measure from the theoretical corner
/// (the Back of 90) along the straight legs of the pipe.
/// 
/// Rounding: All support positions are rounded to whole inches (no fractions).
Map<String, double> calculate90TurnSupports({
  required double startPos, 
  required double stub,
}) {
  final double corner = startPos + stub;
  return {
    'Next Support (Before Turn)': (corner - 24.0).roundToDouble(),
    'Next Support (After Turn)': (corner + 24.0).roundToDouble(),
  };
}


