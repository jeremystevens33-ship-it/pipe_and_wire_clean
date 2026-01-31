
enum ConduitType { emt, imc, rigid, pvc }

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
