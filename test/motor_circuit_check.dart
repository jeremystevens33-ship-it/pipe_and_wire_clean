import '../lib/power_formulas.dart';

// Independent table examples and protection boundaries, not UI snapshots.
void main() {
  var checks = 0;
  void near(double? actual, double expected) {
    if (actual == null || (actual - expected).abs() > 1e-9) {
      throw StateError('Expected $expected, got $actual');
    }
    checks++;
  }
  void rejects(void Function() action) {
    try { action(); } on ArgumentError { checks++; return; }
    throw StateError('Unsupported selection produced a result');
  }
  Map<String, double> solve({double hp = 5, double volts = 230,
      bool three = false, double? nameplate, bool sf = false,
      bool lowRise = false, String type = 'Squirrel Cage',
      String protection = 'Inverse Time Breaker', String design = 'Other'}) =>
      PowerFormulas.solveFullMotorCircuit(hp: hp, volts: volts,
          isThreePhase: three, nameplateFLA: nameplate,
          highServiceFactor: sf, lowTemperatureRise: lowRise,
          motorType: type, protectionType: protection, motorDesign: design);

  final single = solve(nameplate: 23.5, sf: true);
  near(single['flc'], 28);
  near(single['conductor'], 35);
  near(single['breaker'], 70);
  near(single['disconnect'], 32.2);
  near(single['overload'], 29.375);
  near(solve(nameplate: 23.5)['overload'], 27.025);
  near(solve(nameplate: 23.5, lowRise: true)['overload'], 29.375);
  if (solve().containsKey('overload') ||
      solve(hp: 1, nameplate: 8).containsKey('overload')) {
    throw StateError('Invented overload instead of requesting missing information');
  }
  final three = solve(three: true);
  near(three['flc'], 15.2);
  near(three['conductor'], 19);
  near(three['breaker'], 40);
  near(solve(three: true, volts: 480)['flc'], 7.6);
  near(solve(volts: 240)['flc'], 28);
  near(solve(volts: 208)['flc'], 30.8);
  near(solve(three: true, volts: 208)['flc'], 16.7);
  near(solve(three: true, volts: 200)['flc'], 17.5);
  near(solve(three: true, volts: 600)['flc'], 6.1);
  near(solve(hp: 20, three: true, volts: 480)['flc'], 27);

  for (final device in ['Inverse Time Breaker', 'Dual-Element Fuse', 'Non-Time Delay Fuse']) {
    final wound = solve(three: true, type: 'Wound Rotor', protection: device);
    near(wound['protectionMultiplier'], 1.5);
    near(wound['breaker'], 25); // 15.2 x 1.5 = 22.8, next standard 25.
  }
  near(solve(three: true, type: 'Wound Rotor', protection: 'Instantaneous Trip')['breaker'], 121.6);
  near(solve(three: true, protection: 'Instantaneous Trip', design: 'Design B efficient')['breaker'], 167.2);
  near(solve(three: true, protection: 'Instantaneous Trip', design: 'Design B')['breaker'], 121.6);
  near(solve(protection: 'Instantaneous Trip', design: 'Design B efficient')['breaker'], 224);
  near(PowerFormulas.getNextStandardSize(70.0), 70);
  near(PowerFormulas.getNextStandardSize(70.01), 80);
  near(PowerFormulas.getNextStandardSize(2, isFuse: true), 3);
  near(PowerFormulas.getNextStandardSize(2), 10);
  near(PowerFormulas.getNextStandardSize(600.5, isFuse: true), 601);
  near(PowerFormulas.getNextStandardSize(1001), 1200);
  near(solve(hp: 0.5, volts: 480, three: true, protection: 'Dual-Element Fuse')['breaker'], 3);
  near(PowerFormulas.solveMotorAmps(hp: 5, volts: 230, efficiency: 0.85, pf: 0, isThreePhase: false), 0);
  rejects(() => solve(volts: 277));
  rejects(() => solve(hp: 15));
  rejects(() => solve(hp: 3, volts: 120, three: true));
  rejects(() => solve(type: 'Synchronous'));
  rejects(() => solve(type: 'Wound Rotor'));
  rejects(() => solve(hp: 0));
  rejects(() => solve(hp: double.nan));
  rejects(() => solve(nameplate: -1));
  rejects(() => solve(protection: 'Unknown'));
  rejects(() => PowerFormulas.getNextStandardSize(6001));
  print('Motor circuit checks passed ($checks numeric/rejection checks).');
}
