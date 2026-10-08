import 'dart:math' as math;

// =============================================================================
// POWER HUB FORMULAS & CALCULATION ENGINE
// =============================================================================
// This file centralizes the mathematical logic for Ohm's Law, Power, 
// and NEC Article 430 Motor Circuit puzzles.
// =============================================================================

class PowerFormulas {

  // ===========================================================================
  // 1. NEC MOTOR CIRCUIT CALCULATION (ARTICLE 430)
  // ===========================================================================
  // Preview for one continuous-duty, normal-speed/normal-torque induction motor.
  // These are separate checks, not a complete installation or wire-size design.
  //
  // STEP 1: FLC (Table Current) - NEC 430.6(A)(1)
  //   We MUST use the Full-Load Current from NEC Tables 430.248 (1Ph) 
  //   or 430.250 (3Ph) to size conductors and breakers.
  //
  // STEP 2: Conductor Sizing - NEC 430.22
  //   Branch circuit conductors must be 125% of the Table FLC.
  //
  // STEP 3: Overload Protection - NEC 430.32
  //   Sized from the NAMEPLATE FLA (Full Load Amps).
  //   - 125% for marked S.F. >= 1.15 OR marked temperature rise <= 40 C.
  //   - 115% multiplier for all other motors.
  //
  // STEP 4: Short-Circuit & Ground-Fault (OCPD) - NEC Table 430.52
  //   The multiplier depends on the device type:
  //   - Inverse Time Breaker: 250% (Standard choice)
  //   - Dual-Element Fuse: 175%
  //   - Non-Time-Delay Fuse: 300%
  //   - Instantaneous Trip: 1100% for three-phase Design B energy-efficient/
  //     premium-efficiency motors; 800% for other supported motors. Use only
  //     with a listed combination motor controller, per 430.52(C)(3).
  //   - Wound rotor: 150% for fuses/inverse time; 800% instantaneous.
  //
  //   Rounding Rule: If the calculated value doesn't match a standard size, 
  //   Exception No. 1 allows rounding UP to the next standard size (per 240.6).
  //
  // EXAMPLE: 5HP, 230V, Single-Phase Motor (FLC = 28A)
  //   1. Minimum conductor ampacity: 28A * 1.25 = 35A. Wire selection still
  //      needs termination temperature, ambient and conductor-count checks.
  //   2. If NAMEPLATE is 23.5A and SF 1.15: 23.5A * 1.25 = 29.375A maximum.
  //   3. Breaker (Inv. Time): 28A * 2.50 = 70A (Standard size)
  //   4. Disconnect minimum ampere rating: 28A * 1.15 = 32.2A (430.110).
  //      Horsepower and locked-rotor suitability must also be checked.
  // Sources: NEC 2023 430.6, 430.22, 430.32, 430.52, 430.110 and 240.6.
  // Numeric table subset cross-checked in NFPA's published 2023-cycle report:
  // https://www.nfpa.org/api/files?path=/files/AboutTheCodes/70/70_A2022_NEC_P11_SD_SRStatements.pdf
  // This report is a revision record, not a substitute for the adopted code.
  // Starting-current exceptions and specialized motors are outside this preview.
  // ===========================================================================

  // Columns: 115, 200, 208, 230 V; then 460 and 575 V for three-phase.
  // Only the horsepower range offered by this screen is included. A null cell
  // is absent from the NEC table; it must never become an interpolated estimate.
  static final _singlePhaseFLC = <double, List<double>>{
    0.5: [9.8, 5.6, 5.4, 4.9],
    0.75: [13.8, 7.9, 7.6, 6.9],
    1: [16, 9.2, 8.8, 8],
    1.5: [20, 11.5, 11, 10],
    2: [24, 13.8, 13.2, 12],
    3: [34, 19.6, 18.7, 17],
    5: [56, 32.2, 30.8, 28],
    7.5: [80, 46, 44, 40],
    10: [100, 57.5, 55, 50],
  };
  static final _threePhaseFLC = <double, List<double?>>{
    0.5: [4.4, 2.5, 2.4, 2.2, 1.1, 0.9],
    0.75: [6.4, 3.7, 3.5, 3.2, 1.6, 1.3],
    1: [8.4, 4.8, 4.6, 4.2, 2.1, 1.7],
    1.5: [12, 6.9, 6.6, 6, 3, 2.4],
    2: [13.6, 7.8, 7.5, 6.8, 3.4, 2.7],
    3: [null, 11, 10.6, 9.6, 4.8, 3.9],
    5: [null, 17.5, 16.7, 15.2, 7.6, 6.1],
    7.5: [null, 25.3, 24.2, 22, 11, 9],
    10: [null, 32.2, 30.8, 28, 14, 11],
    15: [null, 48.3, 46.2, 42, 21, 17],
    20: [null, 62.1, 59.4, 54, 27, 22],
  };

  static double motorTableCurrent({required double hp, required double volts,
      required bool isThreePhase, String motorType = 'Squirrel Cage'}) {
    if (!hp.isFinite || hp <= 0 || !volts.isFinite || volts <= 0) {
      throw ArgumentError('Enter positive horsepower and voltage.');
    }
    if (motorType != 'Squirrel Cage' && motorType != 'Wound Rotor') {
      throw ArgumentError('Synchronous motor tables are not supported by this preview.');
    }
    if (!isThreePhase && motorType == 'Wound Rotor') {
      throw ArgumentError('Select three-phase for a wound-rotor motor.');
    }
    final int column;
    if (volts >= 110 && volts <= 120) { column = 0; }
    else if (volts == 200) { column = 1; }
    else if (volts == 208) { column = 2; }
    else if (volts >= 220 && volts <= 240) { column = 3; }
    else if (isThreePhase && volts >= 440 && volts <= 480) { column = 4; }
    else if (isThreePhase && volts >= 550 && volts <= 600) { column = 5; }
    else { throw ArgumentError('No supported motor-table voltage for $volts V.'); }
    final row = isThreePhase ? _threePhaseFLC[hp] : _singlePhaseFLC[hp];
    final value = row?[column];
    if (value == null) {
      throw ArgumentError('No supported table entry for $hp HP at $volts V in this phase.');
    }
    return value;
  }

  /// Returns the next standard OCPD size (Breaker/Fuse) per NEC 240.6(A)
  static double getNextStandardSize(double calculatedAmps, {bool isFuse = false}) {
    // NEC 2023 added 10 A to Table 240.6(A). Fuse-only sizes also include
    // 1, 3, 6 and 601 A; do not use those ratings for an inverse-time breaker.
    // Confirmed in Eaton's 2023 NEC code updates, publication 11318:
    // https://www.eaton.com/content/dam/eaton/products/electrical-circuit-protection/fuses/code-updates/bus-ele-br-11318-2023-NEC-code-changes.pdf
    final List<double> standardSizes = [
      if (isFuse) ...[1, 3, 6],
      10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150,
      175, 200, 225, 250, 300, 350, 400, 450, 500, 600,
      if (isFuse) 601,
      700, 800, 1000, 1200, 1600, 2000, 2500, 3000, 4000, 5000, 6000
    ];
    if (!calculatedAmps.isFinite || calculatedAmps <= 0) {
      throw ArgumentError('Enter positive protection current.');
    }
    return standardSizes.firstWhere((s) => s >= calculatedAmps - 1e-9,
        orElse: () => throw ArgumentError('Protection exceeds the supported standard-size list.'));
  }

  /// Master Motor Solver
  /// Computes the five separate checks described above; omits overload when
  /// nameplate FLA is missing or the motor needs the <= 1 HP protection rules.
  static Map<String, double> solveFullMotorCircuit({
    required double hp,
    required double volts,
    required bool isThreePhase,
    double? nameplateFLA, 
    bool highServiceFactor = false,
    bool lowTemperatureRise = false,
    String protectionType = "Inverse Time Breaker",
    String motorDesign = "Other",
    String motorType = "Squirrel Cage", // Added motor type
  }) {
    // No horsepower multiplier or power-factor estimate may replace table FLC.
    final flc = motorTableCurrent(hp: hp, volts: volts,
        isThreePhase: isThreePhase, motorType: motorType);
    if (nameplateFLA != null && (!nameplateFLA.isFinite || nameplateFLA <= 0)) {
      throw ArgumentError('Enter positive nameplate amps.');
    }
    
    // 2. Conductor (125% per 430.22)
    // Wound Rotor conductors between controller and secondary resistors 
    // are sized differently (430.23), but branch conductors are still 125%.
    double conductorAmpacity = flc * 1.25;

    // 3. Separate overload maximum for continuous-duty motors over 1 HP,
    // 430.32(A)(1): nameplate FLA x 125% if marked SF >= 1.15 OR marked
    // temperature rise <= 40 C; otherwise 115%. Never substitute table FLC.
    // Motors <= 1 HP need the starting/protection provisions of 430.32(B).
    final overloadMultiplier = highServiceFactor || lowTemperatureRise ? 1.25 : 1.15;

    // 4. Short-Circuit & Ground-Fault (NEC Table 430.52)
    double multiplier = 2.50; // Default: Inverse Time Breaker
    bool canRoundUp = true;

    if (protectionType == "Dual-Element Fuse") {
      multiplier = 1.75;
    } else if (protectionType == "Non-Time Delay Fuse") {
      multiplier = 3.00;
    } else if (protectionType == "Instantaneous Trip") {
      canRoundUp = false; 
      multiplier = isThreePhase && motorType == "Squirrel Cage" &&
          motorDesign == "Design B efficient" ? 11.00 : 8.00;
    } else if (protectionType != "Inverse Time Breaker") {
      throw ArgumentError('Select a supported protection device.');
    }
    
    // Wound-rotor row: 150% for both fuse types and inverse-time breakers;
    // 800% for instantaneous trip (250% belongs to the DC motor row).
    if (motorType == "Wound Rotor" && canRoundUp) {
      multiplier = 1.50;
    }

    double ocpdCalc = flc * multiplier;
    double ocpdResult = canRoundUp
        ? getNextStandardSize(ocpdCalc, isFuse: protectionType.contains('Fuse'))
        : ocpdCalc;

    // 5. Disconnect (115% per 430.110)
    double disconnectMin = flc * 1.15;

    return {
      "flc": flc,
      "conductor": conductorAmpacity,
      if (nameplateFLA != null && hp > 1)
        "overload": nameplateFLA * overloadMultiplier,
      "overloadMultiplier": overloadMultiplier,
      "protectionMultiplier": multiplier,
      "breaker": ocpdResult,
      "disconnect": disconnectMin,
    };
  }

  // ===========================================================================
  // 2. STANDARD POWER CALCULATIONS (VOLTS, WATTS, HP, OHMS, kVA)
  // ===========================================================================

  static double solveAmps({
    required double volts,
    required double watts,
    required double pf,
    required bool isThreePhase,
  }) {
    final double phaseMult = isThreePhase ? 1.732 : 1.0;
    if (volts <= 0 || pf <= 0) return 0.0;
    return watts / (volts * pf * phaseMult);
  }

  static double solveVolts({
    required double watts,
    required double amps,
    required double pf,
    required bool isThreePhase,
  }) {
    final double phaseMult = isThreePhase ? 1.732 : 1.0;
    if (amps <= 0 || pf <= 0) return 0.0;
    return watts / (amps * pf * phaseMult);
  }

  static double solveWatts({
    required double volts,
    required double amps,
    required double pf,
    required bool isThreePhase,
  }) {
    final double phaseMult = isThreePhase ? 1.732 : 1.0;
    return volts * amps * pf * phaseMult;
  }

  static double solveHP({
    required double volts,
    required double amps,
    required double efficiency,
    required double pf,
    required bool isThreePhase,
  }) {
    final double phaseMult = isThreePhase ? 1.732 : 1.0;
    // HP = (V * I * Eff * PF * Phase) / 746
    return (volts * amps * efficiency * pf * phaseMult) / 746;
  }

  static double solveOhms({
    required double volts,
    required double amps,
  }) {
    if (amps <= 0) return 0.0;
    return volts / amps;
  }

  static double solveKVA({
    required double volts,
    required double amps,
    required bool isThreePhase,
  }) {
    final double phaseMult = isThreePhase ? 1.732 : 1.0;
    return (volts * amps * phaseMult) / 1000;
  }

  // Engineering estimate: input current = HP x 746 / (volts x efficiency x
  // power factor x phase multiplier). For example, 5 HP / (230 V, 85% eff,
  // PF 0.9, single-phase) gives about 21.20 A. This estimates running current;
  // it is NOT the NEC table FLC used for conductor and branch protection sizing.
  static double solveMotorAmps({
    required double hp,
    required double volts,
    required double efficiency,
    required double pf,
    required bool isThreePhase,
  }) {
    final double phaseMult = isThreePhase ? 1.732 : 1.0;
    if (volts <= 0 || efficiency <= 0 || pf <= 0) return 0.0;
    return (hp * 746) / (volts * efficiency * pf * phaseMult);
  }

  // ===========================================================================
  // 3. AC CIRCUIT COMPONENTS (Z, XL, XC, f)
  // ===========================================================================

  static double solveImpedance(double resistance, double reactance) {
    return math.sqrt(math.pow(resistance, 2) + math.pow(reactance, 2));
  }

  static double solveInductiveReactance(double frequency, double inductance) {
    return 2 * math.pi * frequency * inductance;
  }

  static double solveInductance(double reactance, double frequency) {
    if (frequency <= 0) return 0.0;
    return reactance / (2 * math.pi * frequency);
  }

  static double solveCapacitance(double frequency, double reactance) {
    if (frequency <= 0 || reactance <= 0) return 0.0;
    return 1 / (2 * math.pi * frequency * reactance);
  }

  static double solveResonantFrequency(double reactance, double inductance) {
    if (inductance <= 0) return 0.0;
    return reactance / (2 * math.pi * inductance);
  }
}
