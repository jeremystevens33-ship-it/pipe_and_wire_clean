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
  // The "Master Motor Puzzle" follows a strict sequence to ensure safety 
  // during high-current starting (Locked Rotor) events.
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
  //   - 125% multiplier for Service Factor (S.F.) >= 1.15.
  //   - 115% multiplier for all other motors.
  //
  // STEP 4: Short-Circuit & Ground-Fault (OCPD) - NEC Table 430.52
  //   The multiplier depends on the device type:
  //   - Inverse Time Breaker: 250% (Standard choice)
  //   - Dual-Element Fuse: 175%
  //   - Non-Time-Delay Fuse: 300%
  //   - Instantaneous Trip: 800% (Design B) or 1100% (Others)
  //
  //   Rounding Rule: If the calculated value doesn't match a standard size, 
  //   Exception No. 1 allows rounding UP to the next standard size (per 240.6).
  //
  // EXAMPLE: 5HP, 230V, Single-Phase Motor (FLC = 28A)
  //   1. Wire: 28A * 1.25 = 35A (#8 AWG THWN)
  //   2. Overload (SF 1.15): 28A * 1.25 = 35A
  //   3. Breaker (Inv. Time): 28A * 2.50 = 70A (Standard size)
  // ===========================================================================

  /// Returns the next standard OCPD size (Breaker/Fuse) per NEC 240.6(A)
  static double getNextStandardSize(double calculatedAmps) {
    final List<double> standardSizes = [
      15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 
      175, 200, 225, 250, 300, 350, 400, 450, 500, 600, 700, 800, 1000
    ];
    return standardSizes.firstWhere((s) => s >= calculatedAmps, orElse: () => calculatedAmps);
  }

  /// Master Motor Solver
  /// Orchestrates the 4-step NEC calculation sequence.
  static Map<String, double> solveFullMotorCircuit({
    required double hp,
    required double volts,
    required bool isThreePhase,
    double? nameplateFLA, 
    bool highServiceFactor = true, 
    String protectionType = "Inverse Time Breaker",
    String motorDesign = "Design B",
    String motorType = "Squirrel Cage", // Added motor type
  }) {
    // 1. Get Table FLC
    double flc = 0;
    if (isThreePhase) {
      if (volts >= 440) flc = hp * 1.4; 
      else if (volts >= 220) flc = hp * 2.8; 
      else if (volts >= 200) flc = hp * 3.1; 
      else flc = hp * 3.5;
    } else {
      if (volts >= 220) flc = hp * 8.0; 
      else if (volts >= 110) flc = hp * 16.0; 
      else flc = hp * 20.0;
    }

    // Adjust FLC for Synchronous motors (90% pf vs 80% pf usually)
    if (motorType == "Synchronous") {
      flc = flc * 0.8; // Rough adjustment for power factor benefits
    }
    
    // 2. Conductor (125% per 430.22)
    // Wound Rotor conductors between controller and secondary resistors 
    // are sized differently (430.23), but branch conductors are still 125%.
    double conductorAmpacity = flc * 1.25;

    // 3. Overload (Using Nameplate if provided, fallback to FLC)
    double sourceForOverload = nameplateFLA ?? flc;
    double overloadSize = sourceForOverload * (highServiceFactor ? 1.25 : 1.15);

    // 4. Short-Circuit & Ground-Fault (NEC Table 430.52)
    double multiplier = 2.50; // Default: Inverse Time Breaker
    bool canRoundUp = true;

    if (protectionType == "Dual-Element Fuse") {
      multiplier = 1.75;
    } else if (protectionType == "Non-Time Delay Fuse") {
      multiplier = 3.00;
    } else if (protectionType == "Instantaneous Trip") {
      canRoundUp = false; 
      if (motorType == "Wound Rotor") multiplier = 8.00;
      else multiplier = (motorDesign == "Design B") ? 8.00 : 11.00;
    }
    
    // Wound rotor and Synchronous have different maxes, but Inverse Time is usually same 250%
    if (motorType == "Wound Rotor" && protectionType == "Inverse Time Breaker") {
      multiplier = 1.50; // Special max for wound rotor
    }

    double ocpdCalc = flc * multiplier;
    double ocpdResult = canRoundUp ? getNextStandardSize(ocpdCalc) : ocpdCalc;

    // 5. Disconnect (115% per 430.110)
    double disconnectMin = flc * 1.15;

    return {
      "flc": flc,
      "conductor": conductorAmpacity,
      "overload": overloadSize,
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

  static double solveMotorAmps({
    required double hp,
    required double volts,
    required double efficiency,
    required double pf,
    required bool isThreePhase,
  }) {
    final double phaseMult = isThreePhase ? 1.732 : 1.0;
    if (volts <= 0 || efficiency <= 0) return 0.0;
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
