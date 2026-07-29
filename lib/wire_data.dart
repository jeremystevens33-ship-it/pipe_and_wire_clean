// =============================================================================
// WIRE DATA & ELECTRICAL TABLES (Source of Truth)
// =============================================================================
// This file centralizes all National Electrical Code (NEC) tables and 
// calculation formulas for conductor ampacity, box fill, and conduit fill.
// =============================================================================

class ConduitDB {
  
  // ===========================================================================
  // BOX FILL CALCULATIONS (NEC 314.16)
  // ===========================================================================
  // Rule: Total volume in cubic inches must not exceed the box capacity.
  //
  // Formula:
  //   Total Fill = (Conductor Count * Wire Volume)
  //                + (Grounds * Largest Ground Volume) [1st 4 = 1, extra = 0.25 ea]
  //                + (Device Yokes * 2 * Wire Volume)
  //                + (Internal Clamps * 1 * Wire Volume) [one or more = 1]
  //                + (Terminal Blocks * 1 * Wire Volume)
  //
  // Example: 4x #12 Hot/Neutrals + 1x #12 Ground + 1x Outlet
  //   Fill = (4 * 2.25) + (1 * 2.25) + (1 * 2 * 2.25) = 15.75 in³
  // ===========================================================================

  static const Map<String, double> wireVolumes = {
    "18 AWG": 1.50,
    "16 AWG": 1.75,
    "14 AWG": 2.00,
    "12 AWG": 2.25,
    "10 AWG": 2.50,
    "8 AWG": 3.00,
    "6 AWG": 5.00,
    "4 AWG": 6.00, // Estimated (Switch to physical sizing per 314.28)
    "3 AWG": 6.50, // Estimated
    "2 AWG": 7.00, // Estimated
    "1 AWG": 7.50, // Estimated
    "1/0 AWG": 8.00, // Estimated
    "2/0 AWG": 9.00, // Estimated
    "3/0 AWG": 10.0, // Estimated
    "4/0 AWG": 12.0, // Estimated
    "250 KCMIL": 14.0, // Estimated
    "300 KCMIL": 16.0, // Estimated
    "350 KCMIL": 18.0, // Estimated
    "400 KCMIL": 20.0, // Estimated
    "500 KCMIL": 22.0, // Estimated
  };

  static const Map<String, double> boxVolumes = {
    "4o Shallow": 12.5, "4o": 15.5, "4o Deep": 21.5,
    "4s Shallow": 18.0, "4s": 21.0, "4s Deep": 30.3,
    "5s Shallow": 25.5, "5s": 29.5, "5s Deep": 42.0,
    "Device 3x2x1.5": 7.5, "Device 3x2x2": 10.0, "Device 3x2x2.25": 10.5,
    "Device 3x2x2.5": 12.5, "Device 3x2x2.75": 14.0, "Device 3x2x3.5": 18.0,
    "Masonry 3.75x2x2.5": 14.0, "Masonry 3.75x2x3.5": 21.0,
    "FS Single Gang": 13.5, "FD Single Gang": 18.0,
    "6x6x4": 144.0, "8x8x4": 256.0, "10x10x4": 400.0, "12x12x4": 576.0, "12x12x6": 864.0,
  };

  static const List<String> popularBoxSizes = [
    "4s", "4s Deep", "5s", "5s Deep", "4o", "4o Deep", "6x6x4", "8x8x4", "10x10x4", "12x12x4",
  ];

  static const Map<String, double> mudRingVolumes = {
    "Flat": 0.0, "1/4\"": 2.5, "1/2\"": 5.0, "5/8\"": 5.5, "3/4\"": 6.0, "1\"": 7.5,
  };

  static const Map<String, double> extensionRingVolumes = {
    "4S 1-1/2 inch": 21.0, "4S 2-1/8 inch": 30.3, "4S 2-1/2 inch": 34.0,
    "5S 1-1/2 inch": 30.3, "5S 2-1/8 inch": 42.0, "5S 2-1/2 inch": 49.5,
  };

  // ===========================================================================
  // PULL & JUNCTION BOX SIZING (NEC 314.28)
  // ===========================================================================
  // Required for conductors #4 AWG and larger.
  //
  // 1. STRAIGHT PULLS:
  //    Formula: Box Dimension = Largest Trade Size * 8
  //    Example: 2" Conduit = 16" Box Length (minimum)
  //
  // 2. ANGLE / U-PULLS:
  //    Formula: Box Dimension = (Largest Trade Size * 6) + Sum of Others
  //    Example: 2" Conduit + 1" Conduit on same wall
  //    Length = (2 * 6) + 1 = 13" Box Length (minimum)
  //
  // 3. DISTANCE BETWEEN ENTRIES:
  //    Formula: Center-to-Center Distance = Largest Trade Size * 6
  //    Example: 2" Conduit Angle Pull = 12" diagonal spacing between bushings.
  // ===========================================================================

  static const Map<String, double> tradeSizesInches = {
    "1/2": 0.5, "3/4": 0.75, "1": 1.0, "1-1/4": 1.25, "1-1/2": 1.5, "2": 2.0,
    "2-1/2": 2.5, "3": 3.0, "3-1/2": 3.5, "4": 4.0,
  };

  // ===========================================================================
  // AMPACITY & DERATING (NEC 310.15)
  // ===========================================================================
  // Formula: Adjusted Ampacity = Table Ampacity * Bundling Factor * Temp Factor
  //
  // Note: Standard Breaker sizing allows rounding up ONLY if the calculated 
  // load is not a standard size and the next size is not prohibited (NEC 240.4).
  // This app uses the standard breaker size below or equal to final ampacity.
  //
  // Example: 4x #12 Copper THHN in a 90°F Room
  //   1. Base Ampacity (90°C) = 30A
  //   2. Bundling Factor (4-6 CCCs) = 0.80
  //   3. Temp Factor (87-95°F @ 90°C) = 0.96
  //   4. Adjusted Ampacity = 30 * 0.80 * 0.96 = 23.04A
  //   5. Small Conductor Cap (240.4(D)) = 20A
  //   Result: 20A Breaker
  // ===========================================================================

  static const Map<String, Map<String, int>> copperAmpacities = {
    "18 AWG": {"60C": 7, "75C": 7, "90C": 14}, // Cap per 240.4(D)
    "16 AWG": {"60C": 10, "75C": 10, "90C": 18}, // Cap per 240.4(D)
    "14 AWG": {"60C": 15, "75C": 20, "90C": 25},
    "12 AWG": {"60C": 20, "75C": 25, "90C": 30},
    "10 AWG": {"60C": 30, "75C": 35, "90C": 40},
    "8 AWG": {"60C": 40, "75C": 50, "90C": 55},
    "6 AWG": {"60C": 55, "75C": 65, "90C": 75},
    "4 AWG": {"60C": 70, "75C": 85, "90C": 95},
    "3 AWG": {"60C": 85, "75C": 100, "90C": 115},
    "2 AWG": {"60C": 95, "75C": 115, "90C": 130},
    "1 AWG": {"60C": 110, "75C": 130, "90C": 145},
    "1/0 AWG": {"60C": 125, "75C": 150, "90C": 170},
    "2/0 AWG": {"60C": 145, "75C": 175, "90C": 195},
    "3/0 AWG": {"60C": 165, "75C": 200, "90C": 225},
    "4/0 AWG": {"60C": 195, "75C": 230, "90C": 260},
    "250 KCMIL": {"60C": 215, "75C": 255, "90C": 290},
    "300 KCMIL": {"60C": 240, "75C": 285, "90C": 320},
    "350 KCMIL": {"60C": 260, "75C": 310, "90C": 350},
    "400 KCMIL": {"60C": 280, "75C": 335, "90C": 380},
    "500 KCMIL": {"60C": 320, "75C": 380, "90C": 430},
  };

  static const Map<String, Map<String, int>> aluminumAmpacities = {
    "14 AWG": {"60C": 15, "75C": 15, "90C": 20},
    "12 AWG": {"60C": 20, "75C": 20, "90C": 25},
    "10 AWG": {"60C": 25, "75C": 30, "90C": 35},
    "8 AWG": {"60C": 30, "75C": 40, "90C": 45},
    "6 AWG": {"60C": 40, "75C": 50, "90C": 60},
    "4 AWG": {"60C": 55, "75C": 65, "90C": 75},
    "3 AWG": {"60C": 65, "75C": 75, "90C": 85},
    "2 AWG": {"60C": 75, "75C": 90, "90C": 100},
    "1 AWG": {"60C": 85, "75C": 100, "90C": 115},
    "1/0 AWG": {"60C": 100, "75C": 120, "90C": 135},
    "2/0 AWG": {"60C": 115, "75C": 135, "90C": 155},
    "3/0 AWG": {"60C": 130, "75C": 155, "90C": 175},
    "4/0 AWG": {"60C": 150, "75C": 180, "90C": 205},
    "250 KCMIL": {"60C": 170, "75C": 205, "90C": 230},
    "300 KCMIL": {"60C": 190, "75C": 225, "90C": 255},
    "350 KCMIL": {"60C": 205, "75C": 245, "90C": 280},
    "400 KCMIL": {"60C": 220, "75C": 260, "90C": 300},
    "500 KCMIL": {"60C": 255, "75C": 305, "90C": 345},
  };

  static const Map<String, Map<String, double>> temperatureCorrectionFactors = {
    "75C": {
      "70-77": 1.04, "78-86": 1.00, "87-95": 0.96, "96-104": 0.91,
      "105-113": 0.87, "114-122": 0.82, "123-131": 0.76, "132-140": 0.71,
    },
    "90C": {
      "50°F or less": 1.15, "51-59°F": 1.12, "60-68°F": 1.08, "69-77°F": 1.04,
      "78-86°F": 1.00, "87-95°F": 0.96, "96-104°F": 0.91, "105-113°F": 0.87,
      "114-122°F": 0.82, "123-131°F": 0.76, "132-140°F": 0.71,
    }
  };

  static const List<int> standardBreakerSizes = [
    15, 20, 25, 30, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200
  ];

  static const Map<int, String> groundWireSizes = {
    15: "14 AWG", 20: "12 AWG", 60: "10 AWG", 100: "8 AWG", 200: "6 AWG",
  };

  // ===========================================================================
  // VOLTAGE DROP CALCULATIONS
  // ===========================================================================
  // Formula (Single Phase): VD = (2 * K * L * I) / CMA
  // Formula (Three Phase):  VD = (1.732 * K * L * I) / CMA
  //
  // Where:
  //   K = 12.9 (Copper), 21.2 (Aluminum)
  //   L = One-way length in feet
  //   I = Load in Amps
  //   CMA = Circular Mil Area of conductor
  //
  // Example: #12 Copper (CMA 6530), 100ft, 16A load
  //   VD = (2 * 12.9 * 100 * 16) / 6530 = 6.32V
  //   % Drop = (6.32V / 120V) * 100 = 5.27%
  // ===========================================================================

  static const double copperK = 12.9;
  static const double aluminumK = 21.2;

  static const Map<String, int> wireCMA = {
    "18 AWG": 1620, "16 AWG": 2580, "14 AWG": 4110, "12 AWG": 6530,
    "10 AWG": 10380, "8 AWG": 16510, "6 AWG": 26240, "4 AWG": 41740,
    "3 AWG": 52620, "2 AWG": 66360, "1 AWG": 83690, "1/0 AWG": 105600,
    "2/0 AWG": 133100, "3/0 AWG": 167800, "4/0 AWG": 211600,
    "250 KCMIL": 250000, "300 KCMIL": 300000, "350 KCMIL": 350000,
    "400 KCMIL": 400000, "500 KCMIL": 500000,
  };

  static const Map<String, double> wireResistance = {
    "14 AWG": 3.07, "12 AWG": 1.93, "10 AWG": 1.21, "8 AWG": 0.778,
    "6 AWG": 0.491, "4 AWG": 0.308, "3 AWG": 0.245, "2 AWG": 0.194, "1 AWG": 0.154,
  };

  // ===========================================================================
  // CONDUIT FILL CALCULATIONS (NEC Chapter 9, Table 4)
  // ===========================================================================
  // Total Internal Area at 100% capacity.
  // Legal limits applied in calculator logic (40%, 31%, 53%).
  //
  // Formula:
  //   % Fill = (Total Wire Area / (Conduit Internal Area * Fill Factor)) * 100
  //
  // Note: 100% in this app means you have hit the NEC legal limit.
  //
  // Example: 10x #12 THHN in 1/2" EMT
  //   1. Wire Area (#12 THHN) = 0.0133 in²
  //   2. Total Wire Area = 10 * 0.0133 = 0.133 in²
  //   3. 1/2" EMT Internal Area = 0.304 in²
  //   4. 40% Legal Limit (3+ wires) = 0.304 * 0.40 = 0.1216 in²
  //   5. App % Fill = (0.133 / 0.1216) * 100 = 109.3% (VIOLATION)
  // ===========================================================================

  static const Map<String, double> emtTotalArea = {
    "1/2": 0.304, "3/4": 0.533, "1": 0.864, "1-1/4": 1.496, "1-1/2": 2.036,
    "2": 3.356, "2-1/2": 4.788, "3": 7.313, "3-1/2": 9.728, "4": 12.513,
  };

  static const Map<String, double> rmcTotalArea = {
    "1/2": 0.314, "3/4": 0.556, "1": 0.897, "1-1/4": 1.557, "1-1/2": 2.114,
    "2": 3.459, "2-1/2": 4.953, "3": 7.601, "3-1/2": 10.08, "4": 12.93,
  };

  static const Map<String, Map<String, double>> wireAreas = {
    "18 AWG": { "THHN": 0.0059, "THWN-2": 0.0059, "TFN": 0.0059, "TFFN": 0.0059 },
    "16 AWG": { "THHN": 0.0082, "THWN-2": 0.0082, "TFN": 0.0082, "TFFN": 0.0082 },
    "14 AWG": { "THHN": 0.0097, "THWN-2": 0.0097, "THW": 0.0139, "XHHW-2": 0.0139 },
    "12 AWG": { "THHN": 0.0133, "THWN-2": 0.0133, "THW": 0.0181, "XHHW-2": 0.0181 },
    "10 AWG": { "THHN": 0.0211, "THWN-2": 0.0211, "THW": 0.0278, "XHHW-2": 0.0278 },
    "8 AWG":  { "THHN": 0.0366, "THWN-2": 0.0366, "THW": 0.0437, "XHHW-2": 0.0437 },
    "6 AWG":  { "THHN": 0.0507, "THWN-2": 0.0507, "THW": 0.0590, "XHHW-2": 0.0590 },
    "4 AWG":  { "THHN": 0.0824, "THWN-2": 0.0824, "THW": 0.0955, "XHHW-2": 0.0955 },
    "3 AWG":  { "THHN": 0.0973, "THWN-2": 0.0973, "THW": 0.1112, "XHHW-2": 0.1112 },
    "2 AWG":  { "THHN": 0.1158, "THWN-2": 0.1158, "THW": 0.1332, "XHHW-2": 0.1332 },
    "1 AWG":  { "THHN": 0.1562, "THWN-2": 0.1562, "THW": 0.1771, "XHHW-2": 0.1771 },
    "1/0 AWG":{ "THHN": 0.1986, "THWN-2": 0.1986, "THW": 0.2241, "XHHW-2": 0.2241 },
    "2/0 AWG":{ "THHN": 0.2371, "THWN-2": 0.2371, "THW": 0.2678, "XHHW-2": 0.2678 },
    "3/0 AWG":{ "THHN": 0.2858, "THWN-2": 0.2858, "THW": 0.3230, "XHHW-2": 0.3230 },
    "4/0 AWG":{ "THHN": 0.3424, "THWN-2": 0.3424, "THW": 0.3868, "XHHW-2": 0.3868 },
    "250 KCMIL": { "THHN": 0.4079, "THWN-2": 0.4079, "THW": 0.4608, "XHHW-2": 0.4608 },
    "300 KCMIL": { "THHN": 0.4674, "THWN-2": 0.4674, "THW": 0.5284, "XHHW-2": 0.5284 },
    "350 KCMIL": { "THHN": 0.5303, "THWN-2": 0.5303, "THW": 0.5992, "XHHW-2": 0.5992 },
    "400 KCMIL": { "THHN": 0.5932, "THWN-2": 0.5932, "THW": 0.6700, "XHHW-2": 0.6700 },
    "500 KCMIL": { "THHN": 0.7289, "THWN-2": 0.7289, "THW": 0.8236, "XHHW-2": 0.8236 }
  };
}
