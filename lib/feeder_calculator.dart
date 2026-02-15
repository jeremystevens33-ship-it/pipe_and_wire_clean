import 'package:flutter/material.dart';
import 'dart:math';

import 'package:pipe_and_wire_clean/junction_box_sizing_code_screen.dart';
import 'package:pipe_and_wire_clean/keypad_volt_drop.dart';
import 'package:pipe_and_wire_clean/neutral_ccc_code_screen.dart';
import 'ampacity_derating_code_screen.dart';
import 'box_sizing_code_screen.dart';
import 'conduit_fill_code_screen.dart';
import 'voltage_drop_code_screen.dart';

// Extension to capitalize the first letter of a string for dropdown display
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// --- STYLE CONSTANTS ---
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kSilver = Color(0xFF9E9E9E);

// --- ENUMS for State Management ---
enum CalculatorStep { pipe, box, wire, insulation, ambientTemp, boxSetup, free }
enum PullType { straight, angle }
enum PipeType { emt, rmc }
enum ConductorMaterial { copper, aluminum }
enum EntrySide {
  top,
  bottom,
  left,
  right,
  back
} // NEW: For Junction Box Sizing

// --- DATA MODELS & DATABASE ---
class ConduitDB {
  // Conductor volumes from NEC Table 314.16(B) in cubic inches
  static const Map<String, double> wireVolumes = {
    "18 AWG": 1.75, // Added 18 AWG
    "14 AWG": 2.00,
    "12 AWG": 2.25,
    "10 AWG": 2.50,
    "8 AWG": 3.00,
    "6 AWG": 5.00,
    "4 AWG": 5.00,
    "3 AWG": 5.00,
    "2 AWG": 5.00,
    "1 AWG": 5.00,
    "1/0 AWG": 6.00, // Estimated
    "2/0 AWG": 7.00, // Estimated
    "3/0 AWG": 8.00, // Estimated
    "4/0 AWG": 9.00, // Estimated
    "250 KCMIL": 10.0, // Estimated
    "300 KCMIL": 11.0, // Estimated
    "350 KCMIL": 12.0, // Estimated
    "400 KCMIL": 13.0, // Estimated
    "500 KCMIL": 14.0, // Estimated
  };

  // Standard box volumes in cubic inches from NEC Table 314.16(A)
  static const Map<String, double> boxVolumes = {
    "4o Shallow": 12.5,
    "4o": 15.5,
    "4o Deep": 21.5,
    "4s Shallow": 18.0,
    "4s": 21.0,
    "4s Deep": 30.3,
    "5s Shallow": 25.5,
    "5s": 29.5,
    "5s Deep": 42.0,
    "Device 3x2x1.5": 7.5,
    "Device 3x2x2": 10.0,
    "Device 3x2x2.25": 10.5,
    "Device 3x2x2.5": 12.5,
    "Device 3x2x2.75": 14.0,
    "Device 3x2x3.5": 18.0,
    "Device 4x2.125x1.5": 10.3,
    "Device 4x2.125x1.875": 13.0,
    "Device 4x2.125x2.125": 14.5,
    "Masonry 3.75x2x2.5": 14.0,
    "Masonry 3.75x2x3.5": 21.0,
    "FS Single Gang": 13.5,
    "FD Single Gang": 18.0,
    "FS Multi Gang": 18.0,
    "FD Multi Gang": 24.0,
    "6x6x4": 144.0,
    "8x8x4": 256.0,
    "10x10x4": 400.0,
    "12x12x4": 576.0,
    "12x12x6": 864.0,
  };

  // --- REORDERED POPULAR BOX SIZES ---
  // (Order changed as per user request: 4s, 4s Deep, 5s, 5s Deep, 4o, 4o Deep, then larger general purpose)
  static const List<String> popularBoxSizes = [
    "4s", "4s Deep", "5s", "5s Deep", "4o", "4o Deep",
    "6x6x4", "8x8x4", "10x10x4", "12x12x4",
  ];

  static const Map<String, double> mudRingVolumes = {
    "Flat": 0.0,
    "1/4\"": 2.5,
    "1/2\"": 5.0,
    "5/8\"": 5.5,
    "3/4\"": 6.0,
    "1\"": 7.5,
  };

  // NEW: Extension Ring Volumes with accurate data
  static const Map<String, double> extensionRingVolumes = {
    // 4S Extension Rings (for 4-inch square boxes)
    "4S 1-1/2 inch": 21.0,
    "4S 2-1/8 inch": 30.3,
    "4S 2-1/2 inch": 34.0,
    // 5S Extension Rings (for 4-11/16 inch square boxes)
    "5S 1-1/2 inch": 30.3,
    "5S 2-1/8 inch": 42.0,
    "5S 2-1/2 inch": 49.5,
  };

  static const Map<String, Map<String, int>> copperAmpacities = {
    "18 AWG": {"60C": 10, "75C": 14, "90C": 18}, // Added 18 AWG
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

  // NEW: Aluminum Ampacities
  static const Map<String, Map<String, int>> aluminumAmpacities = {
    "18 AWG": {"60C": 8, "75C": 10, "90C": 14},
    // Estimated
    "14 AWG": {"60C": 15, "75C": 15, "90C": 20},
    // 14 AWG Aluminum generally not allowed for 15A
    "12 AWG": {"60C": 15, "75C": 20, "90C": 25},
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


  static const Map<String, Map<String, double>> wireAreas = {
    "18 AWG": {
      "THHN": 0.0075,
      "THWN-2": 0.0075,
      "THW": 0.0100,
      "USE-2": 0.0100,
      "XHHW-2": 0.0100,
      "RHH/RHW-2": 0.0100
    }, // Added 18 AWG
    "14 AWG": {
      "THHN": 0.0097,
      "THWN-2": 0.0097,
      "THW": 0.0139,
      "USE-2": 0.0139,
      "XHHW-2": 0.0139,
      "RHH/RHW-2": 0.0139
    },
    "12 AWG": {
      "THHN": 0.0133,
      "THWN-2": 0.0133,
      "THW": 0.0181,
      "USE-2": 0.0181,
      "XHHW-2": 0.0181,
      "RHH/RHW-2": 0.0181
    },
    "10 AWG": {
      "THHN": 0.0211,
      "THWN-2": 0.0211,
      "THW": 0.0278,
      "USE-2": 0.0278,
      "XHHW-2": 0.0278,
      "RHH/RHW-2": 0.0278
    },
    "8 AWG": {
      "THHN": 0.0366,
      "THWN-2": 0.0366,
      "THW": 0.0437,
      "USE-2": 0.0437,
      "XHHW-2": 0.0437,
      "RHH/RHW-2": 0.0437
    },
    "6 AWG": {
      "THHN": 0.0507,
      "THWN-2": 0.0507,
      "THW": 0.0590,
      "USE-2": 0.0590,
      "XHHW-2": 0.0590,
      "RHH/RHW-2": 0.0590
    },
    "4 AWG": {
      "THHN": 0.0824,
      "THWN-2": 0.0824,
      "THW": 0.0955,
      "USE-2": 0.0955,
      "XHHW-2": 0.0955,
      "RHH/RHW-2": 0.0955
    },
    "3 AWG": {
      "THHN": 0.0973,
      "THWN-2": 0.0973,
      "THW": 0.1112,
      "USE-2": 0.1112,
      "XHHW-2": 0.1112,
      "RHH/RHW-2": 0.1112
    },
    "2 AWG": {
      "THHN": 0.1158,
      "THWN-2": 0.1158,
      "THW": 0.1332,
      "USE-2": 0.1332,
      "XHHW-2": 0.1332,
      "RHH/RHW-2": 0.1332
    },
    "1 AWG": {
      "THHN": 0.1562,
      "THWN-2": 0.1562,
      "THW": 0.1771,
      "USE-2": 0.1771,
      "XHHW-2": 0.1771,
      "RHH/RHW-2": 0.1771
    },
    "1/0 AWG": {
      "THHN": 0.1986,
      "THWN-2": 0.1986,
      "THW": 0.2241,
      "USE-2": 0.2241,
      "XHHW-2": 0.2241,
      "RHH/RHW-2": 0.2241
    },
    "2/0 AWG": {
      "THHN": 0.2371,
      "THWN-2": 0.2371,
      "THW": 0.2678,
      "USE-2": 0.2678,
      "XHHW-2": 0.2678,
      "RHH/RHW-2": 0.2678
    },
    "3/0 AWG": {
      "THHN": 0.2858,
      "THWN-2": 0.2858,
      "THW": 0.3230,
      "USE-2": 0.3230,
      "XHHW-2": 0.3230,
      "RHH/RHW-2": 0.3230
    },
    "4/0 AWG": {
      "THHN": 0.3424,
      "THWN-2": 0.3424,
      "THW": 0.3868,
      "USE-2": 0.3868,
      "XHHW-2": 0.3868,
      "RHH/RHW-2": 0.3868
    },
    "250 KCMIL": {
      "THHN": 0.4079,
      "THWN-2": 0.4079,
      "THW": 0.4608,
      "USE-2": 0.4608,
      "XHHW-2": 0.4608,
      "RHH/RHW-2": 0.4608
    },
    "300 KCMIL": {
      "THHN": 0.4674,
      "THWN-2": 0.4674,
      "THW": 0.5284,
      "USE-2": 0.5284,
      "XHHW-2": 0.5284,
      "RHH/RHW-2": 0.5284
    },
    "350 KCMIL": {
      "THHN": 0.5303,
      "THWN-2": 0.5303,
      "THW": 0.5992,
      "USE-2": 0.5992,
      "XHHW-2": 0.5992,
      "RHH/RHW-2": 0.5992
    },
    "400 KCMIL": {
      "THHN": 0.5932,
      "THWN-2": 0.5932,
      "THW": 0.6700,
      "USE-2": 0.6700,
      "XHHW-2": 0.6700,
      "RHH/RHW-2": 0.6700
    },
    "500 KCMIL": {
      "THHN": 0.7289,
      "THWN-2": 0.7289,
      "THW": 0.8236,
      "USE-2": 0.8236,
      "RHH/RHW-2": 0.8236
    },
  };

  // Total Internal Area of Conduit (100% Fill) from NEC Chapter 9, Table 4
  static const Map<String, double> emtTotalArea = {
    "1/2": 0.304,
    "3/4": 0.533,
    "1": 0.864,
    "1-1/4": 1.496,
    "1-1/2": 2.036,
    "2": 3.356,
    "2-1/2": 4.788,
    "3": 7.313,
    "3-1/2": 9.728,
    "4": 12.513,
  };

  static const Map<String, double> rmcTotalArea = {
    "1/2": 0.314,
    "3/4": 0.556,
    "1": 0.897,
    "1-1/4": 1.557,
    "1-1/2": 2.114,
    "2": 3.459,
    "2-1/2": 4.953,
    "3": 7.601,
    "3-1/2": 10.08,
    "4": 12.93,
  };

  static const Map<String, double> tradeSizesInches = {
    "1/2": 0.5, "3/4": 0.75, "1": 1.0, "1-1/4": 1.25, "1-1/2": 1.5, "2": 2.0,
    "2-1/2": 2.5, "3": 3.0, "3-1/2": 3.5, "4": 4.0,
  };

  static const Map<String, Map<String, double>> temperatureCorrectionFactors = {
    "75C": {
      "70-77": 1.04, "78-86": 1.00, "87-95": 0.96, "96-104": 0.91,
      "105-113": 0.87, "114-122": 0.82, "123-131": 0.76, "132-140": 0.71,
    },
    "90C": {
      "70-77°F": 1.04,
      "78-86°F": 1.00,
      "87-95°F": 0.96,
      "96-104°F": 0.91,
      "105-113°F": 0.87,
      "114-122°F": 0.82,
      "123-131°F": 0.76,
      "132-140°F": 0.71,
    }
  };

  static const Map<String, double> wireResistance = {
    "18 AWG": 4.9, // Added 18 AWG
    "14 AWG": 3.07,
    "12 AWG": 1.93,
    "10 AWG": 1.21,
    "8 AWG": 0.778,
    "6 AWG": 0.491,
    "4 AWG": 0.308,
    "3 AWG": 0.245,
    "2 AWG": 0.194,
    "1 AWG": 0.154,
  };

  static const List<int> standardBreakerSizes = [
    15,
    20,
    25,
    30,
    40,
    45,
    50,
    60,
    70,
    80,
    90,
    100,
    110,
    125,
    150,
    175,
    200
  ];

  static const Map<int, String> groundWireSizes = {
    15: "14 AWG", 20: "12 AWG", 60: "10 AWG", 100: "8 AWG", 200: "6 AWG",
  };
}

class Wire {
  final String id = UniqueKey().toString();
  String size;
  String insulation;
  ConductorMaterial material;
  bool isGround;
  bool isNeutral;
  bool isCurrentCarrying;

  Wire(
      { required this.size, required this.insulation, this.material = ConductorMaterial
          .copper, this.isGround = false, this.isNeutral = false, this.isCurrentCarrying = true });
}

class Pipe {
  final String id = UniqueKey().toString();
  String? size;
  PullType pullType;
  EntrySide entrySide; // NEW: default to top, can be changed
  List<Wire> wires = [];
  PipeType pipeType;

  Pipe({this.size, this.pullType = PullType.straight, this.pipeType = PipeType
      .emt, this.entrySide = EntrySide.top});
}

class UnifiedFeederCalculator extends StatefulWidget {
  const UnifiedFeederCalculator({super.key});

  @override
  State<UnifiedFeederCalculator> createState() =>
      _UnifiedFeederCalculatorState();
}

class _UnifiedFeederCalculatorState extends State<UnifiedFeederCalculator>
    with TickerProviderStateMixin {
  static const String _customBoxKey = "__CUSTOM__";
  static const String _moreBoxKey = "__MORE__";
  static const String _moreWiresKey = "__MORE_WIRES__"; // Added for wire selection

  CalculatorStep _currentStep = CalculatorStep.pipe;
  bool _isInitialSetupComplete = false;
  bool _showAlternateInfoMessage = false;

  List<Pipe> _pipes = [Pipe()];
  int _activePipeIndex = 0;

  late Map<String, double> _dynamicBoxVolumes;
  String? _selectedBoxSize;
  String? _selectedWireSize;
  ConductorMaterial _selectedMaterial = ConductorMaterial.copper;
  String? _selectedInsulation;
  String? _selectedMudRing;
  String? _selectedExtensionRingType; // Renamed to hold the selected type
  int _extensionRingCount = 0; // New variable for the quantity of the selected type

  int _deviceCount = 0;
  int _clampCount = 0;
  int _supportFittingCount = 0;
  int _pullThroughWireCount = 0;

  String? _selectedAmbientTempKey;
  bool _hasShownNeutralDialog = false;
  bool _isNeutralCCC = false;
  bool _showPullThroughBoxInfoBar = false;
  // PipeType _selectedPipeType = PipeType.emt; // This will be managed per pipe

  double _length = 0.0;
  double _voltage = 0.0;

  late AnimationController _borderAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _infoBarAnimationController;
  late Animation<double> _infoBarAnimation;

  // --- TESTING HOOKS ---
  Map<String, dynamic> get resultsForTesting => _calculateResults();

  void setSelectedBoxSizeForTesting(String? size) =>
      setState(() => _selectedBoxSize = size);

  void setSelectedWireSizeForTesting(String? size) =>
      setState(() => _selectedWireSize = size);

  void setSelectedInsulationForTesting(String? insulation) =>
      setState(() => _selectedInsulation = insulation);

  void addWireForTesting(String type) {
    if (_selectedWireSize == null || _selectedInsulation == null) return;
    setState(() {
      if (type == 'Hot') {
        _activePipe.wires.add(Wire(size: _selectedWireSize!,
            insulation: _selectedInsulation!,
            isCurrentCarrying: true));
      } else if (type == 'Ground') {
        _activePipe.wires.add(Wire(size: _selectedWireSize!,
            insulation: _selectedInsulation!,
            isGround: true,
            isCurrentCarrying: false));
      }
    });
  }

  void setDeviceCountForTesting(int count) =>
      setState(() => _deviceCount = count);

  void setClampCountForTesting(int count) =>
      setState(() => _clampCount = count);

  void setSupportFittingCountForTesting(int count) =>
      setState(() => _supportFittingCount = count);

  // ---------------------

  @override
  void initState() {
    super.initState();
    _dynamicBoxVolumes = Map.from(ConduitDB.boxVolumes);
    _borderAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 20000))
      ..repeat();
    _glowAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _infoBarAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _infoBarAnimation = CurvedAnimation(
        parent: _infoBarAnimationController, curve: Curves.easeIn);
    _infoBarAnimationController.forward();
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _glowAnimationController.dispose();
    _infoBarAnimationController.dispose();
    super.dispose();
  }

  Pipe get _activePipe => _pipes[_activePipeIndex];

  List<Wire> get _allWires => _pipes.expand((p) => p.wires).toList();

  void _addWire(String type, String size, String insulation) {
    setState(() {
      if (type == 'Hot') {
        _activePipe.wires.add(Wire(size: size,
            insulation: insulation,
            material: _selectedMaterial,
            isCurrentCarrying: true));
      } else if (type == 'Neutral') {
        if (!_hasShownNeutralDialog) {
          _showOneTimeNeutralDialog(size, insulation);
        } else {
          _activePipe.wires.add(Wire(size: size,
              insulation: insulation,
              material: _selectedMaterial,
              isNeutral: true,
              isCurrentCarrying: _isNeutralCCC));
        }
      } else if (type == 'Ground') {
        _activePipe.wires.add(Wire(size: size,
            insulation: insulation,
            material: _selectedMaterial,
            isGround: true,
            isCurrentCarrying: false));
      }
    });
  }

  void _removeLastWireOfType(String type) {
    setState(() {
      int indexToRemove = -1;
      if (type == 'Hot') {
        indexToRemove = _activePipe.wires.lastIndexWhere((w) =>
        !w.isNeutral && !w.isGround);
      } else if (type == 'Neutral') {
        indexToRemove = _activePipe.wires.lastIndexWhere((w) => w.isNeutral);
      } else if (type == 'Ground') {
        indexToRemove = _activePipe.wires.lastIndexWhere((w) => w.isGround);
      }

      if (indexToRemove != -1) {
        _activePipe.wires.removeAt(indexToRemove);
      }
    });
  }

  void _toggleNeutralCCC() {
    setState(() {
      _isNeutralCCC = !_isNeutralCCC;
    });
  }

  void _showOneTimeNeutralDialog(String size, String insulation) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            backgroundColor: const Color(0xFF2C3030),
            title: const Text(
                "Select Neutral Type", style: TextStyle(color: kLight)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text(
                      "Shared Neutral (MWBC)", style: TextStyle(color: kLight)),
                  subtitle: const Text("Does NOT count toward derating.",
                      style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    setState(() {
                      _isNeutralCCC = false;
                      _activePipe.wires.add(Wire(size: size,
                          insulation: insulation,
                          material: _selectedMaterial,
                          isNeutral: true,
                          isCurrentCarrying: false));
                      _hasShownNeutralDialog = true;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text("Dedicated Neutral (2-Wire)",
                      style: TextStyle(color: kLight)),
                  subtitle: const Text("ADDS to derating calculation.",
                      style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    setState(() {
                      _isNeutralCCC = true;
                      _activePipe.wires.add(Wire(size: size,
                          insulation: insulation,
                          material: _selectedMaterial,
                          isNeutral: true,
                          isCurrentCarrying: true));
                      _hasShownNeutralDialog = true;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(color: Colors.white24),
                const Text(
                  "After this, use the 'CC' toggle on the stepper to change the neutral type.",
                  style: TextStyle(
                      color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text(
                    "NEC: Learn More", style: TextStyle(color: kRed)),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const NeutralCccCodeScreen()));
                },
              ),
            ],
          ),
    );
  }

  String _getGroundWireSize(int breakerSize) {
    if (breakerSize <= 15) return ConduitDB.groundWireSizes[15]!;
    if (breakerSize <= 20) return ConduitDB.groundWireSizes[20]!;
    if (breakerSize <= 60) return ConduitDB.groundWireSizes[60]!;
    if (breakerSize <= 100) return ConduitDB.groundWireSizes[100]!;
    if (breakerSize <= 200) return ConduitDB.groundWireSizes[200]!;
    return "N/A";
  }

  Map<String, dynamic> _calculateResults() {
    final Map<String, dynamic> boxSizing = _calculateBoxSizing();
    final allWires = _allWires;
    final activePipeWires = _activePipe.wires;
    int maxWires = 0;
    int maxBoxWires = 0;
    int boxWireAllowanceCount = 0;

    final defaultResults = {
      "isReady": false,
      "conduitFillPercent": 0.0,
      "isConduitFillViolation": false,
      "boxFillPercent": 0.0,
      "isBoxFillViolation": false,
      "startingAmpacity": 0,
      "newAmpacity": 0.0,
      "finalBreakerSize": 0,
      "adjustmentFactor": 1.0,
      "tempCorrectionFactor": 1.0,
      "voltageDrop": 0.0,
      "voltageDropPercent": 0.0,
      "maxWires": 0,
      "maxBoxWires": 0,
      "groundWireSize": "N/A",
      "boxWireAllowanceCount": 0,
      ...boxSizing
    };

    if (_activePipe.size == null && allWires.isEmpty) {
      return {...defaultResults, ...boxSizing};
    }

    // --- NEW DYNAMIC CONDUIT FILL LOGIC ---
    double? maxArea;
    if (_activePipe.size != null) {
      final totalAreaMap = _activePipe.pipeType == PipeType.emt ? ConduitDB
          .emtTotalArea : ConduitDB.rmcTotalArea;
      final double totalArea = totalAreaMap[_activePipe.size!]!;
      final int wireCount = activePipeWires.length;
      double fillFactor;
      if (wireCount == 1) {
        fillFactor = 0.53; // 53% for 1 wire
      } else if (wireCount == 2) {
        fillFactor = 0.31; // 31% for 2 wires
      } else {
        fillFactor = 0.40; // 40% for over 2 wires
      }
      maxArea = totalArea * fillFactor;
    }

    // --- Max Wires Calculation (Stays based on 40% fill as requested) ---
    if (_activePipe.size != null) {
      final totalAreaMap = _activePipe.pipeType == PipeType.emt ? ConduitDB
          .emtTotalArea : ConduitDB.rmcTotalArea;
      final double maxAreaForMaxWires = totalAreaMap[_activePipe.size!]! * 0.40;
      final wireTypes = activePipeWires
          .map((w) => '${w.size}-${w.insulation}')
          .toSet();
      if (wireTypes.length <= 1) {
        final wireSize = activePipeWires.isNotEmpty
            ? activePipeWires.first.size
            : _selectedWireSize;
        final insulation = activePipeWires.isNotEmpty ? activePipeWires.first
            .insulation : _selectedInsulation;

        if (wireSize != null && insulation != null) {
          final double? wireArea = ConduitDB.wireAreas[wireSize]?[insulation];
          if (wireArea != null && wireArea > 0) {
            maxWires = (maxAreaForMaxWires / wireArea).floor();
          }
        }
      }
    }


    // --- Box Calculation Variables ---
    double conductorVolume = allWires.where((w) => !w.isGround).fold(
        0.0, (sum, w) => sum + (ConduitDB.wireVolumes[w.size] ?? 0.0));
    double clampVolume = 0;
    double supportFittingVolume = 0;
    double deviceVolume = 0;
    double groundingVolume = 0;

    // Find largest conductors for allowances
    Wire? largestConductor = allWires.where((w) => !w.isGround).toList().fold(
        null, (largest, current) {
      if (largest == null) return current;
      final largestSize = int.tryParse(largest.size.replaceAll(" AWG", "")) ??
          0;
      final currentSize = int.tryParse(current.size.replaceAll(" AWG", "")) ??
          0;
      return currentSize < largestSize ? current : largest;
    });

    final groundWires = allWires.where((w) => w.isGround).toList();
    Wire? largestGround = groundWires.fold(null, (largest, current) {
      if (largest == null) return current;
      final largestSize = int.tryParse(largest.size.replaceAll(" AWG", "")) ??
          0;
      final currentSize = int.tryParse(current.size.replaceAll(" AWG", "")) ??
          0;
      return currentSize < largestSize ? current : largest;
    });

    // --- NEW LOGIC for calculating allowance volumes ---
    // Determine the wire size to use for allowances. Fallback to selected size if no wires are in the box yet.
    String? allowanceWireSize;
    if (largestConductor != null) {
      allowanceWireSize = largestConductor.size;
    } else if (allWires.isEmpty && _selectedWireSize != null) {
      allowanceWireSize = _selectedWireSize;
    }

    // Calculate allowance volumes based on the determined size.
    if (allowanceWireSize != null) {
      final double? allowance = ConduitDB.wireVolumes[allowanceWireSize];
      if (allowance != null) {
        clampVolume = _clampCount * allowance;
        supportFittingVolume = _supportFittingCount * allowance;
        deviceVolume = _deviceCount * 2 * allowance;
      }
    }

    if (largestGround != null) {
      final double groundAllowance = ConduitDB.wireVolumes[largestGround.size]!;
      // NEC 314.16(B)(5) - 1 allowance for all equipment grounding conductors
      groundingVolume = groundAllowance;
    }

    // --- Box Wire Allowance Count ---
    boxWireAllowanceCount = allWires
        .where((w) => !w.isGround)
        .length;
    if (groundWires.isNotEmpty) {
      boxWireAllowanceCount += 1; // Only one allowance for all grounds
    }

    // Calculate Max Box Wires
    if (_selectedBoxSize != null && _selectedWireSize != null) {
      final double? boxVolume = _dynamicBoxVolumes[_selectedBoxSize];
      final double? wireVolume = ConduitDB.wireVolumes[_selectedWireSize];

      if (boxVolume != null && wireVolume != null && wireVolume > 0) {
        double totalAvailableVolume = boxVolume;
        if (_selectedMudRing != null) {
          totalAvailableVolume +=
              ConduitDB.mudRingVolumes[_selectedMudRing!] ?? 0.0;
        }
        // NEW: Calculate extension ring volume based on type and count
        if (_selectedExtensionRingType != null && _extensionRingCount > 0) {
          final double? singleRingVolume = ConduitDB
              .extensionRingVolumes[_selectedExtensionRingType!];
          if (singleRingVolume != null) {
            totalAvailableVolume += singleRingVolume * _extensionRingCount;
          }
        }

        final double availableBoxVolumeForWires = totalAvailableVolume -
            (clampVolume + supportFittingVolume + deviceVolume +
                groundingVolume);
        if (availableBoxVolumeForWires > 0) {
          maxBoxWires = (availableBoxVolumeForWires / wireVolume).floor();
        } else {
          maxBoxWires = 0;
        }
      }
    }


    if (activePipeWires.isEmpty && allWires.isEmpty) {
      int startingAmpacity = 0;
      if (_selectedWireSize != null) {
        startingAmpacity =
            ConduitDB.copperAmpacities[_selectedWireSize!]?["90C"] ?? 0;
      }
      return {
        ...defaultResults,
        "isReady": true,
        "maxWires": maxWires,
        "maxBoxWires": maxBoxWires,
        "startingAmpacity": startingAmpacity,
        "boxWireAllowanceCount": boxWireAllowanceCount,
        ...boxSizing
      };
    }

    double totalConduitArea = activePipeWires.fold(0.0, (sum, w) =>
    sum + (ConduitDB.wireAreas[w.size]?[w.insulation] ?? 0.0));
    final double conduitFillPercent = totalConduitArea.isFinite &&
        maxArea != null && maxArea > 0
        ? (totalConduitArea / maxArea) * 100
        : 0.0;
    final bool isConduitFillViolation = maxArea != null &&
        totalConduitArea > maxArea;

    double boxFillPercent = 0.0;
    bool isBoxFillViolation = false;
    double totalBoxVolume = 0;
    double maxBoxVolume = 0;

    if (_selectedBoxSize != null) {
      maxBoxVolume = _dynamicBoxVolumes[_selectedBoxSize]!;
      if (_selectedMudRing != null) {
        maxBoxVolume += ConduitDB.mudRingVolumes[_selectedMudRing!] ?? 0.0;
      }
      // NEW: Calculate extension ring volume based on type and count
      if (_selectedExtensionRingType != null && _extensionRingCount > 0) {
        final double? singleRingVolume = ConduitDB
            .extensionRingVolumes[_selectedExtensionRingType!];
        if (singleRingVolume != null) {
          maxBoxVolume += singleRingVolume * _extensionRingCount;
        }
      }
      totalBoxVolume =
          conductorVolume + clampVolume + supportFittingVolume + deviceVolume +
              groundingVolume;
      boxFillPercent =
      totalBoxVolume.isFinite && maxBoxVolume > 0 ? (totalBoxVolume /
          maxBoxVolume) * 100 : 0.0;
      isBoxFillViolation = totalBoxVolume > maxBoxVolume;
    }

    final int cccCount = activePipeWires
        .where((w) => w.isCurrentCarrying)
        .length;
    double adjustmentFactor = 1.0;
    if (cccCount >= 4 && cccCount <= 6) {
      adjustmentFactor = 0.80;
    } else if (cccCount >= 7 && cccCount <= 9) {
      adjustmentFactor = 0.70;
    } else if (cccCount >= 10 && cccCount <= 20) {
      adjustmentFactor = 0.50;
    } else if (cccCount >= 21 && cccCount <= 30) {
      adjustmentFactor = 0.45;
    } else if (cccCount >= 31 && cccCount <= 40) {
      adjustmentFactor = 0.40;
    } else if (cccCount >= 41) {
      adjustmentFactor = 0.35;
    }

    final tempCorrectionFactor = _selectedAmbientTempKey != null
        ? ConduitDB
        .temperatureCorrectionFactors["90C"]![_selectedAmbientTempKey!] ?? 1.0
        : 1.0;

    Wire? smallestCCCWire = activePipeWires
        .where((w) => w.isCurrentCarrying)
        .toList()
        .fold(null, (smallest, current) {
      if (smallest == null) return current;
      final smallestSize = int.tryParse(smallest.size.replaceAll(" AWG", "")) ??
          0;
      final currentSize = int.tryParse(current.size.replaceAll(" AWG", "")) ??
          0;
      return currentSize > smallestSize ? current : smallest;
    });

    int startingAmpacity = 0;
    if (smallestCCCWire != null) {
      final ampacitiesMap = _selectedMaterial == ConductorMaterial.copper
          ? ConduitDB.copperAmpacities
          : ConduitDB.aluminumAmpacities;
      startingAmpacity = ampacitiesMap[smallestCCCWire.size]?["90C"] ?? 0;
    } else if (_selectedWireSize != null) {
      final ampacitiesMap = _selectedMaterial == ConductorMaterial.copper
          ? ConduitDB.copperAmpacities
          : ConduitDB.aluminumAmpacities;
      startingAmpacity = ampacitiesMap[_selectedWireSize!]?["90C"] ?? 0;
    }

    if (smallestCCCWire == null) {
      return {
        ...defaultResults,
        "isReady": true,
        "conduitFillPercent": conduitFillPercent,
        "isConduitFillViolation": isConduitFillViolation,
        "boxFillPercent": boxFillPercent,
        "isBoxFillViolation": isBoxFillViolation,
        "maxWires": maxWires,
        "maxBoxWires": maxBoxWires,
        "startingAmpacity": startingAmpacity,
        "finalBreakerSize": 0,
        "groundWireSize": "N/A",
        "boxWireAllowanceCount": boxWireAllowanceCount,
        ...boxSizing,
      };
    }

    final double newAmpacity = startingAmpacity * adjustmentFactor *
        tempCorrectionFactor;

    // Safely get the 75C ampacity, defaulting to 0 if not found
    final Map<String,
        Map<String, int>> ampacitiesMapForCap = _selectedMaterial ==
        ConductorMaterial.copper
        ? ConduitDB.copperAmpacities
        : ConduitDB.aluminumAmpacities;

    final int capAmps75 = ampacitiesMapForCap[smallestCCCWire.size]?["75C"] ??
        0;
    final double finalAmps = min(newAmpacity, capAmps75.toDouble());

    int overcurrentLimit = 1000;
    if (smallestCCCWire.size == "18 AWG") { // Added 18 AWG
      overcurrentLimit = 10;
    } else if (smallestCCCWire.size == "14 AWG") {
      overcurrentLimit = 15;
    } else if (smallestCCCWire.size == "12 AWG") {
      overcurrentLimit = 20;
    } else if (smallestCCCWire.size == "10 AWG") {
      overcurrentLimit = 30;
    }

    int finalBreakerSize = ConduitDB.standardBreakerSizes.lastWhere((s) =>
    s <= finalAmps, orElse: () => 0);
    finalBreakerSize = min(overcurrentLimit, finalBreakerSize);

    double voltageDrop = 0.0;
    double voltageDropPercent = 0.0;
    if (_length > 0 && _voltage > 0 && finalBreakerSize > 0) {
      final double resistance = ConduitDB.wireResistance[smallestCCCWire
          .size] ?? 0.0;
      voltageDrop = (2 * resistance * _length * finalBreakerSize) / 1000;
      voltageDropPercent = (voltageDrop / _voltage) * 100;
    }

    final String groundWireSize = _getGroundWireSize(finalBreakerSize);

    return {
      "isReady": true,
      "conduitFillPercent": conduitFillPercent,
      "isConduitFillViolation": isConduitFillViolation,
      "boxFillPercent": boxFillPercent,
      "isBoxFillViolation": isBoxFillViolation,
      "startingAmpacity": startingAmpacity,
      "newAmpacity": newAmpacity,
      "finalBreakerSize": finalBreakerSize,
      "adjustmentFactor": adjustmentFactor,
      "tempCorrectionFactor": tempCorrectionFactor,
      "voltageDrop": voltageDrop,
      "voltageDropPercent": voltageDropPercent,
      "maxWires": maxWires,
      "maxBoxWires": maxBoxWires,
      "groundWireSize": groundWireSize,
      "boxWireAllowanceCount": boxWireAllowanceCount,
      ...boxSizing,
      "conductorVolume": conductorVolume,
      "clampVolume": clampVolume,
      "supportFittingVolume": supportFittingVolume,
      "deviceVolume": deviceVolume,
      "groundingVolume": groundingVolume,
      "totalBoxVolume": totalBoxVolume,
      "maxBoxVolume": maxBoxVolume,
    };
  }

  Map<String, double> _calculateBoxSizing() {
    double largestStraight = 0;
    double largestAngle = 0;

    for (final pipe in _pipes) {
      if (pipe.size != null) {
        final double sizeInInches = ConduitDB.tradeSizesInches[pipe.size!] ??
            0.0;
        if (pipe.pullType == PullType.straight &&
            sizeInInches > largestStraight) {
          largestStraight = sizeInInches;
        }
        if (pipe.pullType == PullType.angle && sizeInInches > largestAngle) {
          largestAngle = sizeInInches;
        }
      }
    }
    return { "minStraight": largestStraight * 8, "minAngle": largestAngle * 6};
  }

  void _updateStep(CalculatorStep newStep) {
    // If the initial setup is done, don't change the step, just recalculate state.
    if (_isInitialSetupComplete) {
      setState(() {});
      return;
    }

    setState(() {
      _currentStep = newStep;
      _infoBarAnimationController.reset();
      _infoBarAnimationController.forward();
    });
  }

  void _advanceToNextIncompleteStep() {
    // This is the new "smart" sequence logic.
    if (_isInitialSetupComplete) {
      setState(() {}); // Just trigger a rebuild to update calculations
      return;
    }

    if (_activePipe.size == null) {
      _updateStep(CalculatorStep.pipe);
    } else if (_selectedBoxSize == null) {
      _updateStep(CalculatorStep.box);
    } else if (_selectedWireSize == null) {
      _updateStep(CalculatorStep.wire);
    } else if (_selectedInsulation == null) {
      _updateStep(CalculatorStep.insulation);
    } else if (_selectedAmbientTempKey == null) {
      _updateStep(CalculatorStep.ambientTemp);
    } else {
      // All selections are complete, move to the final phases.
      setState(() {
        _isInitialSetupComplete = true;
        _currentStep =
            CalculatorStep.boxSetup; // This is the "Tap the Box" step
        _infoBarAnimationController.reset();
        _infoBarAnimationController.forward();
      });
    }
  }

  void _addPipe() {
    setState(() {
      _pipes.add(Pipe(size: _activePipe.size));
      _activePipeIndex = _pipes.length - 1;
      // NEW: Show info bar message if a second pipe is added
      if (_pipes.length > 1) {
        _showPullThroughBoxInfoBar = true;
        Future.delayed(const Duration(
            seconds: 7), () { // Message disappears after 7 seconds
          if (mounted && _showPullThroughBoxInfoBar) {
            setState(() {
              _showPullThroughBoxInfoBar = false;
            });
          }
        });
      }
    });
  }

  void _setActivePipe(int index) {
    if (index == _activePipeIndex) return;
    setState(() => _activePipeIndex = index);
  }

  void _toggleBox() async {
    final bool wasBoxSetupStep = _currentStep == CalculatorStep.boxSetup;

    // Immediately turn off the glow and advance the step.
    if (wasBoxSetupStep) {
      setState(() {
        _currentStep = CalculatorStep.free;
        _showPullThroughBoxInfoBar =
        false; // NEW: Hide pull-through message if box is tapped
        _infoBarAnimationController.reset();
        _infoBarAnimationController.forward();
      });
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _BoxUIDetailView(
              results: _calculateResults(),
              deviceCount: _deviceCount,
              clampCount: _clampCount,
              supportFittingCount: _supportFittingCount,
              selectedMudRing: _selectedMudRing,
              selectedExtensionRingType: _selectedExtensionRingType,
              extensionRingCount: _extensionRingCount,
              pipes: _pipes,
              selectedBoxSize: _selectedBoxSize,
              allWires: _allWires,
              onDeviceCountChanged: (c) => setState(() => _deviceCount = c),
              onClampCountChanged: (c) => setState(() => _clampCount = c),
              onSupportFittingCountChanged: (c) =>
                  setState(() => _supportFittingCount = c),
              onMudRingChanged: (s) => setState(() => _selectedMudRing = s),
              onExtensionRingTypeChanged: (s) =>
                  setState(() => _selectedExtensionRingType = s),
              onExtensionRingCountChanged: (c) =>
                  setState(() => _extensionRingCount = c),
              onPullTypeChanged: (pipeId, pullType, entrySide) {
                setState(() {
                  final pipeToUpdate = _pipes.firstWhere((p) => p.id == pipeId);
                  pipeToUpdate.pullType = pullType;
                  if (entrySide != null) pipeToUpdate.entrySide = entrySide;
                });
              },
              pullThroughWireCount: _pullThroughWireCount,
              // NEW
              onPullThroughCountChanged: (c) =>
                  setState(() => _pullThroughWireCount = c), // NEW
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // After the box detail screen is closed, if we just finished the setup,
    // start the timer to show the alternate "tap pipe" message.
    if (wasBoxSetupStep) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _currentStep == CalculatorStep.free) {
          setState(() {
            _showAlternateInfoMessage = true;
          });
        }
      });
    }
  }


  void _togglePipeUI() {
    // Immediately turn off the glow when the pipe is tapped.
    if (_showAlternateInfoMessage) {
      setState(() {
        _showAlternateInfoMessage = false;
      });
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) {
          // Use a StatefulBuilder to give the detail screen its own setState.
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              void addPipeAndRefresh() {
                // Call the main screen's _addPipe method.
                _addPipe();
                // Call the local setState to force the detail screen to rebuild.
                setState(() {});
              }

              void setActivePipeAndRefresh(int index) {
                _setActivePipe(index);
                setState(() {});
              }

              return _PipeUIDetailView(
                // Pass the current state from the main screen.
                pipes: _pipes,
                activePipeIndex: _activePipeIndex,
                // Pass the new refresh function.
                onAddPipe: addPipeAndRefresh,
                onSetActivePipe: setActivePipeAndRefresh,
                animationController: _borderAnimationController,
                results: _calculateResults(),
                selectedBoxSize: _selectedBoxSize,
              );
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }


  void _reset() {
    setState(() {
      _pipes = [Pipe()];
      _activePipeIndex = 0;
      _dynamicBoxVolumes = Map.from(ConduitDB.boxVolumes);
      _selectedBoxSize = null;
      _selectedWireSize = null;
      _selectedInsulation = null;
      _selectedMudRing = null;
      _selectedExtensionRingType = null; // Reset the type
      _extensionRingCount = 0; // Reset the count
      _currentStep = CalculatorStep.pipe;
      _isInitialSetupComplete = false;
      _showAlternateInfoMessage = false;
      _deviceCount = 0;
      _clampCount = 0;
      _supportFittingCount = 0;
      _selectedAmbientTempKey = null;
      _hasShownNeutralDialog = false;
      _isNeutralCCC = false;
      _length = 0.0;
      _voltage = 0.0;
    });
  }

  void _showVoltDropKeypad(
      {required String type, required double initialValue, required Function(double) onConfirm, String? title}) async {
    // Add 'async' here
    final double? result = await showModalBottomSheet<
        double>( // Add 'await' and capture the result
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom),
            child: VoltDropKeypad(
              initialValue: initialValue.toString(),
              onConfirm: (value) => Navigator.pop(context, value),
              // Change to pop with the value
              title: title,
            ),
          ),
    );
    if (result !=
        null) { // Check if a result was returned (i.e., not cancelled)
      onConfirm(result); // Call the provided onConfirm with the result
    }
  }
  // --- MODIFIED: Custom Box Dialog for L/W/D Input ---
  Future<void> _showCustomBoxDialog() async {
    double? length;
    double? width;
    double? depth;

    length = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FractionallySizedBox( // Ensure keypad is concise
            widthFactor: 0.9,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery
                  .of(context)
                  .viewInsets
                  .bottom),
              child: VoltDropKeypad(
                initialValue: "0.0",
                title: "Enter Box Length (inches)",
                onConfirm: (value) => Navigator.pop(context, value),
              ),
            ),
          ),
    );

    if (length == null || length <= 0) return;

    width = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FractionallySizedBox( // Ensure keypad is concise
            widthFactor: 0.9,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery
                  .of(context)
                  .viewInsets
                  .bottom),
              child: VoltDropKeypad(
                initialValue: "0.0",
                title: "Enter Box Width (inches)",
                onConfirm: (value) => Navigator.pop(context, value),
              ),
            ),
          ),
    );

    if (width == null || width <= 0) return;

    depth = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FractionallySizedBox( // Ensure keypad is concise
            widthFactor: 0.9,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery
                  .of(context)
                  .viewInsets
                  .bottom),
              child: VoltDropKeypad(
                initialValue: "0.0",
                title: "Enter Box Depth (inches)",
                onConfirm: (value) => Navigator.pop(context, value),
              ),
            ),
          ),
    );

    if (depth == null || depth <= 0) return;

    setState(() {
      final customVolume = length! * width! * depth!;
      // Corrected: Always use the simple LengthxWidthxDepth in³ format
      String customKey = "${length!.toStringAsFixed(1).replaceAll(
          '.0', '')}x${width!.toStringAsFixed(1).replaceAll('.0', '')}x${depth!
          .toStringAsFixed(1).replaceAll('.0', '')} in³";
      _dynamicBoxVolumes[customKey] = customVolume;
      _selectedBoxSize = customKey;
      _advanceToNextIncompleteStep();
    });
  }

  Future<void> _showMoreBoxesDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        // Filter out popular boxes and any currently selected custom boxes
        final List<String> otherBoxes = ConduitDB.boxVolumes.keys
            .where((boxName) => !ConduitDB.popularBoxSizes.contains(boxName))
            .toList();
        // Sort for consistent display
        otherBoxes.sort();

        return AlertDialog(
          backgroundColor: const Color(0xFF2C3030),
          title: const Text("Select a Box", style: TextStyle(color: kLight)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: otherBoxes.length,
              itemBuilder: (context, index) {
                final boxName = otherBoxes[index];
                return ListTile(
                  title: Text(boxName, style: const TextStyle(color: kLight)),
                  onTap: () {
                    setState(() {
                      _selectedBoxSize = boxName;
                      _advanceToNextIncompleteStep();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: kLight)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF212121),
            title: const Text(
                'Pipe and Box Fill Help', style: TextStyle(color: kLight)),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'Calculator Workflow:',
                    style: TextStyle(color: kLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '1. Selections: Follow the highlighted dropdowns at the bottom of the screen to select Pipe Size, Box Size, Wire Size, and Insulation type. The calculator will guide you step-by-step.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '2. Add Wires: Use the H (Hot), N (Neutral), and G (Ground) steppers at the bottom to add or remove conductors from your active pipe.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '3. Derating: As you add wires, the derating calculations will update automatically based on conductor count and ambient temperature.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '4. Voltage Drop: The voltage drop input fields are optional, but will update with the wires that are added.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Interactive Visuals:',
                    style: TextStyle(color: kLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• Tap the Pipe: Press the circular pipe visual to open the Pipe Dashboard. Here you can add more pipes to your calculation or switch between them. Each subsequent pipe will be added to the current box calculation.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• Tap the Box: Press the square box visual to open the Box Design screen. Here you can add devices, clamps, and fittings to your box fill calculation and set pull types for junction box sizing.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Counting "Pull-Through" Wires:',
                    style: TextStyle(color: kLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'For box fill calculations, conductors passing through a box without splice or termination (e.g., looping from one conduit to another) typically count as one allowance. However, if that same conductor is cut or spliced within the box, it counts as two allowances. Use the "Pull-Through Wires" option in the Box Design screen to specify how many conductors fall into the pull-through category, reducing their box fill contribution.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: kRed)),
              ),
            ],
          ),
    );
  }

  void _showNecCodeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      builder: (context) =>
          SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.flash_on, color: kLight),
                  title: const Text(
                      'When is conductor ampacity adjustment required?',
                      style: TextStyle(color: kLight, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (
                        context) => const AmpacityDeratingCodeScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: kLight),
                  title: const Text(
                      'When is the neutral a current-carrying conductor?',
                      style: TextStyle(color: kLight, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const NeutralCccCodeScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.power_input, color: kLight),
                  title: const Text(
                      'What are the recommended voltage drop limits?',
                      style: TextStyle(color: kLight, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const VoltageDropCodeScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.linear_scale, color: kLight),
                  title: const Text(
                      'How is conduit fill calculated and applied?',
                      style: TextStyle(color: kLight, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const ConduitFillCodeScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(
                      Icons.check_box_outline_blank, color: kLight),
                  title: const Text(
                      'Which components count towards box fill volume?',
                      style: TextStyle(color: kLight, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const BoxSizingCodeScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.fullscreen, color: kLight),
                  title: const Text(
                      'How do I size pull boxes for #4 AWG and larger?',
                      style: TextStyle(color: kLight, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (
                        context) => const JunctionBoxSizingCodeScreen()));
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showPipeSelectionGrid() {
    showDialog(
      context: context,
      builder: (context) =>
          _PipeSelectionGrid(
            onSelect: (String size, PipeType type) {
              setState(() {
                _activePipe.size = size;
                _activePipe.pipeType = type;
                _advanceToNextIncompleteStep();
              });
              Navigator.of(context).pop();
            },
          ),
    );
  }

  void _showWireSelectionGrid() {
    final List<String> popularSizes = ConduitDB.copperAmpacities.keys
        .where((size) {
      // Filter to show 18 AWG down to 1 AWG for the main grid
      if (size.contains("AWG")) {
        final int awgNum = int.tryParse(size.replaceAll(" AWG", "")) ?? 0;
        return awgNum >= 1 && awgNum <= 18;
      }
      return false;
    })
        .toList()
      ..sort((a, b) =>
          (int.tryParse(b.replaceAll(" AWG", "")) ?? 0).compareTo(
              int.tryParse(a.replaceAll(" AWG", "")) ??
                  0)); // Sort descending for AWG

    showDialog(
      context: context,
      builder: (context) =>
          _WireSelectionGrid(
            sizes: popularSizes,
            onSelect: (String size, ConductorMaterial material) {
              setState(() {
                _selectedWireSize = size;
                _selectedMaterial = material;
                // Invalidate insulation if the new wire size doesn't support it
                if (_selectedWireSize != null) {
                  final availableInsulations = ConduitDB
                      .wireAreas[_selectedWireSize]?.keys ?? [];
                  if (_selectedInsulation != null &&
                      !availableInsulations.contains(_selectedInsulation)) {
                    _selectedInsulation = null;
                  }
                } else {
                  _selectedInsulation = null;
                }
                _advanceToNextIncompleteStep();
              });
              Navigator.of(context).pop();
            },
            onShowMoreWires: () {
              Navigator.of(context).pop(); // Close current dialog
              _showMoreWiresDialog();
            },
          ),
    );
  }

  void _showMoreWiresDialog() {
    final List<String> kcmilSizes = ConduitDB.copperAmpacities.keys
        .where((size) =>
    size.contains("KCMIL") || (size.contains("AWG") &&
        (int.tryParse(size.replaceAll(" AWG", "")) ?? 0) < 1)) // 1/0 AWG and up
        .toList()
      ..sort((a, b) {
        // Custom sort for AWG (desc) and KCMIL (asc)
        final bool isAawg = a.contains("AWG");
        final bool isBawg = b.contains("AWG");

        if (isAawg && isBawg) {
          // Both AWG, sort descending (e.g., 4 AWG, 3 AWG, 2 AWG, 1 AWG)
          final int awgA = int.tryParse(a.replaceAll(" AWG", "")) ?? 0;
          final int awgB = int.tryParse(b.replaceAll(" AWG", "")) ?? 0;
          return awgB.compareTo(awgA);
        } else if (!isAawg && !isBawg) {
          // Both KCMIL, sort ascending (e.g., 250 KCMIL, 300 KCMIL)
          final int kcmilA = int.tryParse(a.replaceAll(" KCMIL", "")) ?? 0;
          final int kcmilB = int.tryParse(b.replaceAll(" KCMIL", "")) ?? 0;
          return kcmilA.compareTo(kcmilB);
        } else {
          // Mix of AWG and KCMIL, AWG comes before KCMIL
          return isAawg ? -1 : 1;
        }
      });


    showDialog(
      context: context,
      builder: (context) =>
          _WireSelectionGrid(
            sizes: kcmilSizes,
            onSelect: (String size, ConductorMaterial material) {
              setState(() {
                _selectedWireSize = size;
                _selectedMaterial = material;
                if (_selectedWireSize != null) {
                  final availableInsulations = ConduitDB
                      .wireAreas[_selectedWireSize]?.keys ?? [];
                  if (_selectedInsulation != null &&
                      !availableInsulations.contains(_selectedInsulation)) {
                    _selectedInsulation = null;
                  }
                } else {
                  _selectedInsulation = null;
                }
                _advanceToNextIncompleteStep();
              });
              Navigator.of(context).pop();
            },
            isMoreWiresScreen: true,
          ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final results = _calculateResults();
    final bool showPipeGlow = _currentStep == CalculatorStep.free &&
        _showAlternateInfoMessage;

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        title: const Text('Pipe and Box Fill',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
          GestureDetector(
            onTap: () => _showNecCodeDialog(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text('NEC', style: TextStyle(
                    color: kLight, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: PulsingGlowBorder(
        animationController: _borderAnimationController,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        startColor: kRed.withOpacity(0.3),
        endColor: kSilver.withOpacity(0.7),
        isPulsing: false,
        child: Container(
          margin: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
              color: kBlack, borderRadius: BorderRadius.circular(6)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildSelectorGrid(),
                const Divider(color: Colors.white24, height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVisualsColumn(results, showPipeGlow: showPipeGlow),
                      _buildDeratingData(results),
                    ],
                  ),
                ),
                _buildResetAndSteppersWithCcOverlay(),
                _buildInfoBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorGrid() {
    const spacing = 4.0;
    // The core list of boxes to show initially in the dropdown.
    List<String> visibleBoxNames = [];

    // 1. Add popular boxes.
    visibleBoxNames.addAll(ConduitDB.popularBoxSizes);

    // 2. Add any custom boxes that are currently defined.
    // These are in _dynamicBoxVolumes but not in ConduitDB.boxVolumes.
    visibleBoxNames.addAll(_dynamicBoxVolumes.keys.where((key) =>
    !ConduitDB.boxVolumes.containsKey(key)));

    // 3. Crucially, if _selectedBoxSize is set and it's NOT already in our list (i.e., it was selected from "More Boxes"),
    // then we MUST add it to the list to prevent the "Failed assertion".
    if (_selectedBoxSize != null &&
        !visibleBoxNames.contains(_selectedBoxSize) &&
        ConduitDB.boxVolumes.containsKey(_selectedBoxSize!)) {
      visibleBoxNames.add(_selectedBoxSize!);
    }

    // Ensure uniqueness and sort any custom boxes among themselves.
    visibleBoxNames = visibleBoxNames
        .toSet()
        .toList(); // This handles duplicates and maintains some order.

    // Convert to DropdownMenuItems
    List<DropdownMenuItem<String>> boxItems = visibleBoxNames.map((s) {
      return DropdownMenuItem(value: s, child: Text(s));
    }).toList();


    // Add the special "Enter Custom" item
    boxItems.add(
      const DropdownMenuItem(
        value: _customBoxKey,
        child: Text("Enter Custom Size (LxWxD)...",
            style: TextStyle(fontStyle: FontStyle.italic, color: kSilver)),
      ),
    );

    boxItems.add(
      const DropdownMenuItem(
        value: _moreBoxKey,
        child: Text("More Boxes...",
            style: TextStyle(fontStyle: FontStyle.italic, color: kSilver)),
      ),
    );
    return Column(
      children: [
        Row(children: [
          Expanded(child: _StyledButton(
            onPressed: _showPipeSelectionGrid,
            label: _activePipe.size != null
                ? '${_activePipe.size}" ${_activePipe.pipeType
                .toString()
                .split('.')
                .last
                .toUpperCase()}'
                : "Pipe Size",
            isActive: _currentStep == CalculatorStep.pipe,
            isDropdownStyle: true,
          )),
          const SizedBox(width: spacing),
          Expanded(child: _StyledDropdown(
            value: _selectedBoxSize,
            hint: "Box Size",
            items: boxItems,
            onChanged: (v) async { // Added async here
              if (v == _customBoxKey) {
                await _showCustomBoxDialog(); // Added await
              } else if (v == _moreBoxKey) {
                await _showMoreBoxesDialog(); // Added await
              }
              else {
                setState(() {
                  _selectedBoxSize = v;
                  _advanceToNextIncompleteStep();
                });
              }
            },
            isActive: _currentStep == CalculatorStep.box,
            isEnabled: _currentStep != CalculatorStep.pipe ||
                _isInitialSetupComplete,
          )),
        ]),
        const SizedBox(height: spacing),
        Row(children: [
          Expanded(child: _StyledButton(
            onPressed: _showWireSelectionGrid,
            label: _selectedWireSize != null
                ? '${_selectedWireSize!} ${_selectedMaterial ==
                ConductorMaterial.copper ? "CU" : "AL"}'
                : "Wire Size",
            isActive: _currentStep == CalculatorStep.wire,
            isDropdownStyle: true,
            isEnabled: _currentStep != CalculatorStep.pipe &&
                _currentStep != CalculatorStep.box || _isInitialSetupComplete,
          )),
          const SizedBox(width: spacing),
          Expanded(child: _StyledDropdown(
            value: _selectedInsulation,
            hint: "Insulation",
            items: (_selectedWireSize == null ? <String>[] : ConduitDB
                .wireAreas[_selectedWireSize]!.keys).map((s) =>
                DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedInsulation = v;
                _advanceToNextIncompleteStep();
              });
            },
            isActive: _currentStep == CalculatorStep.insulation,
            isEnabled: _selectedWireSize != null,
          )),
        ]),
      ],
    );
  }

  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 1.0),
      child: _StyledButton(onPressed: _reset, label: "Reset Calculator"),
    );
  }

  // 1) Wire steppers row (NO CC overlay inside here)
  Widget _buildWireSteppers() {
    const spacing = 4.0;
    final hotCount = _activePipe.wires
        .where((w) => !w.isNeutral && !w.isGround)
        .length;
    final neutralCount = _activePipe.wires
        .where((w) => w.isNeutral)
        .length;
    final groundCount = _activePipe.wires
        .where((w) => w.isGround)
        .length;
    final bool canAdd = _selectedWireSize != null &&
        _selectedInsulation != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _WireStepper(
              label: 'H',
              count: hotCount,
              color: kRed,
              onAdd: canAdd
                  ? () =>
                  _addWire('Hot', _selectedWireSize!, _selectedInsulation!)
                  : null,
              onRemove: () => _removeLastWireOfType('Hot'),
            ),
          ),
          const SizedBox(width: spacing),

          Expanded(
            child: _WireStepper(
              label: 'N',
              count: neutralCount,
              color: Colors.white,
              onAdd: canAdd
                  ? () =>
                  _addWire('Neutral', _selectedWireSize!, _selectedInsulation!)
                  : null,
              onRemove: () => _removeLastWireOfType('Neutral'),
            ),
          ),
          const SizedBox(width: spacing),

          Expanded(
            child: _WireStepper(
              label: 'G',
              count: groundCount,
              color: Colors.green,
              onAdd: canAdd
                  ? () =>
                  _addWire('Ground', _selectedWireSize!, _selectedInsulation!)
                  : null,
              onRemove: () => _removeLastWireOfType('Ground'),
            ),
          ),
        ],
      ),
    );
  }

  // 2) CC toggle widget (big hit target, always tappable when visible)
  Widget _buildCcToggle() {
    if (!_hasShownNeutralDialog) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _toggleNeutralCCC,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.all(12), // big invisible hit target
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.0),
          decoration: BoxDecoration(
            color: _isNeutralCCC ? kRed : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isNeutralCCC ? kRed : Colors.white.withAlpha(128),
            ),
          ),
          child: Text(
            "CC",
            style: TextStyle(
              color: _isNeutralCCC ? kLight : Colors.white.withAlpha(128),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 3) Wrapper that pins CC in the "pocket" between Reset and the steppers.
  // IMPORTANT: This Stack wraps BOTH reset and steppers so the CC is inside hit-test bounds.
  Widget _buildResetAndSteppersWithCcOverlay() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Keep reset from becoming full-width
            Align(
              alignment: const Alignment(.89, 0.0),
              // adjust if you want it elsewhere
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 178),
                // tune 160–220
                child: _buildResetButton(),
              ),
            ),

            _buildWireSteppers(),
          ],
        ),

        // CC overlay: anchor to the CENTER of the steppers area, then nudge left
        Positioned(
          bottom: 48, // up/down
          left: 48,
          right: 0,
          child: IgnorePointer(
            ignoring: !_hasShownNeutralDialog,
            child: Opacity(
              opacity: _hasShownNeutralDialog ? 1.0 : 0.0,
              child: Transform.translate(
                offset: const Offset(-70, 0), // <-- move left (try -50 to -90)
                child: Center(child: _buildCcToggle()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualsColumn(Map<String, dynamic> results,
      {required bool showPipeGlow}) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPipeVisual(results, showPipeGlow: showPipeGlow),
          _buildBoxVisual(results),
        ],
      ),
    );
  }

  Widget _buildPipeVisual(Map<String, dynamic> results,
      {required bool showPipeGlow}) {
    final bool isReady = results['isReady'] ?? false;
    final double conduitFill = results['conduitFillPercent'] ?? 0.0;
    final bool isConduitViolation = results['isConduitFillViolation'] ?? false;
    final int maxWires = results['maxWires'] ?? 0;

    final conduitStatusColor = !isReady || _activePipe.size == null ? Colors
        .grey : (isConduitViolation ? kRed : Colors.green);
    final wireTypes = _activePipe.wires
        .map((w) => '${w.size}-${w.insulation}')
        .toSet();
    final bool showMaxWires = wireTypes.length <= 1;

    final pipeContent = Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[800],
        border: showPipeGlow ? null : Border.all(
            color: conduitStatusColor, width: 8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Pipe ${_activePipeIndex + 1}", style: const TextStyle(
                color: kLight, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              !isReady || _activePipe.size == null
                  ? "-- Wires\n--% Fill"
                  : "${_activePipe.wires.length} Wires\n${conduitFill
                  .toStringAsFixed(1)}% Fill",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700,
                  color: isConduitViolation ? kRed : kLight,
                  fontSize: 18),
            ),
            if (isReady && showMaxWires && maxWires > 0) ...[
              const SizedBox(height: 8),
              Text("Max Wires: $maxWires", style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );

    return SizedBox(
      width: 170,
      height: 170,
      child: GestureDetector(
        onTap: _togglePipeUI,
        child: Hero(
          tag: 'pipe-hero',
          child: Material(
            type: MaterialType.transparency,
            child: showPipeGlow
                ? PulsingGlowBorder(
              animationController: _glowAnimationController,
              shape: BoxShape.circle,
              isPulsing: true,
              borderWidth: 8.0,
              child: pipeContent,
            )
                : pipeContent,
          ),
        ),
      ),
    );
  }

  Widget _buildBoxVisual(Map<String, dynamic> results) {
    final bool isReady = results['isReady'] ?? false;
    final double boxFill = results['boxFillPercent'] ?? 0.0;
    final bool isBoxViolation = results['isBoxFillViolation'] ?? false;
    final int maxBoxWires = results['maxBoxWires'] ?? 0;
    final isBoxWarning = boxFill > 90.0 && !isBoxViolation;
    final boxStatusColor = !isReady || _selectedBoxSize == null
        ? Colors.grey
        : (isBoxViolation ? kRed : (isBoxWarning ? Colors.yellow : Colors
        .green));
    final int boxWireAllowanceCount = results['boxWireAllowanceCount'] ?? 0;
    final wireTypes = _allWires.map((w) => '${w.size}-${w.insulation}').toSet();
    final bool showMaxBoxWires = wireTypes.length <= 1 || _allWires.isEmpty;
    final bool isBoxSetupStep = _currentStep == CalculatorStep.boxSetup;

    final boxContent = Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.grey[800],
        border: isBoxSetupStep ? null : Border.all(
            color: boxStatusColor, width: 8.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Box", style: TextStyle(
                color: kLight, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              !isReady || _selectedBoxSize == null
                  ? "-- Wires\n--% Fill"
                  : "$boxWireAllowanceCount Wires\n${boxFill.toStringAsFixed(
                  1)}% Fill",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isBoxViolation ? kRed : kLight,
                fontSize: 18,
              ),
            ),
            if (isReady && showMaxBoxWires && maxBoxWires > 0) ...[
              const SizedBox(height: 8),
              Text(
                "Max Wires: $maxBoxWires",
                style: const TextStyle(color: Colors.white,
                    fontSize: 14,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: _toggleBox,
      child: Hero(
        tag: 'box-hero',
        child: isBoxSetupStep
            ? PulsingGlowBorder(
          animationController: _glowAnimationController,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12.0),
          isPulsing: true,
          borderWidth: 8.0,
          child: boxContent,
        )
            : boxContent,
      ),
    );
  }

  Widget _buildInfoBar() {
    String text;
    if (_showPullThroughBoxInfoBar) { // NEW: Prioritize pull-through message
      text = "Tap the Box to add Pull-Through Wires!";
    } else {
      switch (_currentStep) {
        case CalculatorStep.pipe:
          text = "Select Pipe Size";
          break;
        case CalculatorStep.box:
          text = "Select Box Size";
          break;
        case CalculatorStep.wire:
          text = "Select Wire Size";
          break;
        case CalculatorStep.insulation:
          text = "Select Insulation Type";
          break;
        case CalculatorStep.ambientTemp:
          text = "Select Ambient Temperature";
          break;
        case CalculatorStep.boxSetup:
          text = "Next: Tap the Box to add devices or fittings.";
          break;
        case CalculatorStep.free:
          text = _showAlternateInfoMessage
              ? "Tap Pipe or Box for more options"
              : "Add Wires to Calculate Derating";
          break;
      }
    }

    return FadeTransition(
      opacity: _infoBarAnimation,
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFF2C3030),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kSilver.withAlpha(180))),
        child: Center(child: Text(text, style: const TextStyle(color: kLight,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic))),
      ),
    );
  }

  Widget _buildDeratingData(Map<String, dynamic> results) {
    final bool isReady = results['isReady'] ?? false;
    final adjustmentFactor = (results['adjustmentFactor'] as double? ?? 1.0);
    final tempCorrectionFactor = (results['tempCorrectionFactor'] as double? ??
        1.0);
    final voltageDrop = results['voltageDrop'] as double? ?? 0.0;
    final voltageDropPercent = results['voltageDropPercent'] as double? ?? 0.0;
    final bool isVoltageDropViolation = voltageDropPercent > 3.0;
    final int finalBreakerSize = results['finalBreakerSize'] ?? 0;
    final String groundWireSize = results['groundWireSize'] ?? "N/A";
    final int startingAmpacity = results['startingAmpacity'] ?? 0;
    final double newAmpacity = results['newAmpacity'] as double? ?? 0.0;
    final bool hasCalculationRun = _allWires
        .where((w) => w.isCurrentCarrying)
        .isNotEmpty;

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.75),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: Colors.white54)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Derating", style: Theme
                      .of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: kLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _StyledDropdown(
                    value: _selectedAmbientTempKey,
                    hint: "Ambient Temp °F",
                    items: ConduitDB.temperatureCorrectionFactors["90C"]!.keys
                        .map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedAmbientTempKey = v;
                        _advanceToNextIncompleteStep();
                      });
                    },
                    isActive: _currentStep == CalculatorStep.ambientTemp,
                    isEnabled: _currentStep == CalculatorStep.ambientTemp ||
                        _currentStep == CalculatorStep.free ||
                        _isInitialSetupComplete,
                  ),
                  const SizedBox(height: 16),
                  Text("Starting Ampacity: ${isReady
                      ? startingAmpacity
                      : '--'}A",
                      style: const TextStyle(color: kLight, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("Temp Factor: ${isReady ? (tempCorrectionFactor * 100)
                      .toStringAsFixed(0) : '--'}%",
                      style: const TextStyle(color: kLight, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("Bundle Factor: ${isReady ? (adjustmentFactor * 100)
                      .toStringAsFixed(0) : '--'}%",
                      style: const TextStyle(color: kLight, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    "New Ampacity: ${isReady
                        ? newAmpacity.toStringAsFixed(1)
                        : '--'}A",
                    style: TextStyle(
                      color: hasCalculationRun && newAmpacity < 15.0
                          ? kRed
                          : kLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Final Breaker Size:\n${isReady
                        ? finalBreakerSize
                        : '--'}A",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: hasCalculationRun ? (finalBreakerSize == 0
                          ? kRed
                          : Colors.green) : kLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Required Ground:\n${isReady ? groundWireSize : 'N/A'}",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: hasCalculationRun ? Colors.green : kLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Text("Voltage Drop", style: Theme
                      .of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: kLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    "${voltageDrop.toStringAsFixed(1)}V (${voltageDropPercent
                        .toStringAsFixed(1)}%)",
                    style: TextStyle(
                      color: isVoltageDropViolation ? kRed : Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildTappableBox(
                      "Length (ft)", "${_length.toStringAsFixed(0)}'", () =>
                      _showVoltDropKeypad(type: 'Length',
                          initialValue: _length,
                          onConfirm: (value) => setState(() => _length = value),
                          title: "Enter Length (feet)")),
                  const SizedBox(height: 4),
                  _buildTappableBox(
                      "Voltage", "${_voltage.toStringAsFixed(0)}V", () =>
                      _showVoltDropKeypad(type: 'Voltage',
                          initialValue: _voltage,
                          onConfirm: (value) =>
                              setState(() => _voltage = value),
                          title: "Enter Voltage")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableBox(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4E4E52), Color(0xFF2C3030)],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kSilver.withAlpha(128), width: 1.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
            Text(value, style: const TextStyle(
                color: kLight, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _PipeUIDetailView extends StatefulWidget {
  final List<Pipe> pipes;
  final int activePipeIndex;
  final VoidCallback onAddPipe;
  final ValueChanged<int> onSetActivePipe;
  final AnimationController animationController;
  final Map<String, dynamic> results;
  final String? selectedBoxSize;

  const _PipeUIDetailView({
    required this.pipes,
    required this.activePipeIndex,
    required this.onAddPipe,
    required this.onSetActivePipe,
    required this.animationController,
    required this.results,
    required this.selectedBoxSize,
  });

  @override
  State<_PipeUIDetailView> createState() => _PipeUIDetailViewState();
}

class _PipeUIDetailViewState extends State<_PipeUIDetailView> {
  late int _localActivePipeIndex;
  String? _selectedWireSummaryKey;

  @override
  void initState() {
    super.initState();
    _localActivePipeIndex = widget.activePipeIndex;
    _updateSelectedWireSummary();
  }

  @override
  void didUpdateWidget(covariant _PipeUIDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool wiresChanged = widget.pipes.length > _localActivePipeIndex &&
        oldWidget.pipes.length > _localActivePipeIndex &&
        widget.pipes[_localActivePipeIndex].wires.length !=
            oldWidget.pipes[_localActivePipeIndex].wires.length;
    bool pipeIndexChanged = widget.activePipeIndex != _localActivePipeIndex;
    bool pipeCountChanged = widget.pipes.length != oldWidget.pipes.length;

    if (pipeIndexChanged || pipeCountChanged) {
      setState(() {
        _localActivePipeIndex = widget.activePipeIndex;
        if (pipeCountChanged && widget.pipes.length > oldWidget.pipes.length) {
          _localActivePipeIndex = widget.pipes.length - 1;
        }
        _updateSelectedWireSummary();
      });
    } else if (wiresChanged) {
      setState(() {
        _updateSelectedWireSummary();
      });
    }
  }

  void _updateSelectedWireSummary() {
    final summaryMap = _getDeratingSummaryForPipe(_activePipe);
    if (summaryMap.isNotEmpty) {
      final sortedKeys = summaryMap.keys.toList();
      // Sort to have the smallest wire gauge (largest AWG number) first as the default.
      sortedKeys.sort((a, b) {
        final sizeA = int.tryParse(
            a.split(" ")[0].replaceAll("AWG", "").trim()) ?? 0;
        final sizeB = int.tryParse(
            b.split(" ")[0].replaceAll("AWG", "").trim()) ?? 0;
        return sizeB.compareTo(sizeA);
      });
      final defaultKey = sortedKeys.first;
      if (_selectedWireSummaryKey == null ||
          !summaryMap.containsKey(_selectedWireSummaryKey)) {
        _selectedWireSummaryKey = defaultKey;
      }
    } else {
      _selectedWireSummaryKey = null;
    }
  }


  Pipe get _activePipe => widget.pipes[_localActivePipeIndex];

  Map<String, Map<String, dynamic>> _getDeratingSummaryForPipe(Pipe pipe) {
    if (pipe.wires.isEmpty) {
      return {};
    }

    final wireGroups = <String, List<Wire>>{};
    for (final wire in pipe.wires) {
      final key = "${wire.size} ${wire.insulation}";
      wireGroups.putIfAbsent(key, () => []).add(wire);
    }

    final int cccCount = pipe.wires
        .where((w) => w.isCurrentCarrying)
        .length;
    double adjustmentFactor = 1.0;
    if (cccCount >= 4 && cccCount <= 6) {
      adjustmentFactor = 0.80;
    } else if (cccCount >= 7 && cccCount <= 9) {
      adjustmentFactor = 0.70;
    } else if (cccCount >= 10 && cccCount <= 20) {
      adjustmentFactor = 0.50;
    } else if (cccCount >= 21 && cccCount <= 30) {
      adjustmentFactor = 0.45;
    } else if (cccCount >= 31 && cccCount <= 40) {
      adjustmentFactor = 0.40;
    } else if (cccCount >= 41) {
      adjustmentFactor = 0.35;
    }

    final tempCorrectionFactor = widget
        .results['tempCorrectionFactor'] as double? ?? 1.0;
    final deratingSummary = <String, Map<String, dynamic>>{};

    for (final entry in wireGroups.entries) {
      final key = entry.key;
      final wireGroup = entry.value;
      final firstWire = wireGroup.first;
      final count = wireGroup.length;
      int finalBreakerSize = 0;

      if (firstWire.isCurrentCarrying) {
        final ampacitiesMap = firstWire.material == ConductorMaterial.copper
            ? ConduitDB.copperAmpacities
            : ConduitDB.aluminumAmpacities;
        final startingAmpacity = ampacitiesMap[firstWire.size]?["90C"] ?? 0;
        final newAmpacity = startingAmpacity * adjustmentFactor *
            tempCorrectionFactor;
        final capAmps75 = ampacitiesMap[firstWire.size]?["75C"] ?? 0;
        final finalAmps = min(newAmpacity, capAmps75.toDouble());
        int overcurrentLimit = 1000;
        if (firstWire.size == "18 AWG") { // Added 18 AWG
          overcurrentLimit = 10;
        } else if (firstWire.size == "14 AWG") {
          overcurrentLimit = 15;
        } else if (firstWire.size == "12 AWG") {
          overcurrentLimit = 20;
        } else if (firstWire.size == "10 AWG") {
          overcurrentLimit = 30;
        }
        finalBreakerSize =
            ConduitDB.standardBreakerSizes.lastWhere((s) => s <= finalAmps,
                orElse: () => 0);
        finalBreakerSize = min(overcurrentLimit, finalBreakerSize);
      }
      deratingSummary[key] = {
        'count': count,
        'wire': firstWire,
        'finalBreakerSize': finalBreakerSize,
      };
    }
    return deratingSummary;
  }


  double _calculatePipeFill(Pipe pipe) {
    if (pipe.size == null) {
      return 0.0;
    }
    final double totalArea = (pipe.pipeType == PipeType.emt ? ConduitDB
        .emtTotalArea : ConduitDB.rmcTotalArea)[pipe.size!]!;
    final int wireCount = pipe.wires.length;
    double fillFactor;
    if (wireCount == 1) {
      fillFactor = 0.53;
    } else if (wireCount == 2) {
      fillFactor = 0.31;
    } else {
      fillFactor = 0.40;
    }
    final double maxArea = totalArea * fillFactor;
    final double totalWireArea = pipe.wires.fold(0.0, (sum, w) =>
    sum + (ConduitDB.wireAreas[w.size]?[w.insulation] ?? 0.0));
    return totalWireArea.isFinite && maxArea > 0 ? (totalWireArea / maxArea) *
        100 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: 'pipe-hero',
        child: Material(
          color: kBlack,
          child: Center(
            child: PulsingGlowBorder(
              animationController: widget.animationController,
              shape: BoxShape.circle,
              endColor: kSilver,
              isPulsing: false,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: kBlack),
                child: _buildPipeDashboard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPipeDashboard() {
    final fillPercent = _calculatePipeFill(_activePipe);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 300),
                  _buildPipeInfoSection(),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildWireSummarySection(),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                      "Conduit Fill", "${fillPercent.toStringAsFixed(1)}%"),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 32.0),
          child: SizedBox(
            width: 200,
            child: _StyledButton(
                onPressed: () => Navigator.of(context).pop(), label: "Done"),
          ),
        ),
      ],
    );
  }

  Widget _buildWireSummarySection() {
    if (_activePipe.wires.isEmpty) {
      return _buildInfoSection("Wire Summary", "Empty");
    }
    final summaryMap = _getDeratingSummaryForPipe(_activePipe);

    // If only one type of wire, show the simple text summary.
    if (summaryMap.length <= 1) {
      final summaryData = summaryMap.values.firstOrNull;
      if (summaryData == null)
        return _buildInfoSection("Wire Summary", "Empty");
      final count = summaryData['count'];
      final wire = summaryData['wire'] as Wire;
      String summaryText = "($count) #${wire.size.replaceAll(" AWG", "")} ${wire
          .insulation}";
      return _buildInfoSection("Wire Summary", summaryText);
    }

    // If multiple wire types, build the dropdown.
    return Column(
      children: [
        const Text("Wire Summary", style: TextStyle(
            color: kLight, fontWeight: FontWeight.bold, fontSize: 30)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: const Color(0xFF2C3030),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kSilver.withAlpha(128))
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedWireSummaryKey,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: kLight, size: 36),
              style: const TextStyle(color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              dropdownColor: const Color(0xFF2C3030),
              items: summaryMap.entries.map((entry) {
                final key = entry.key;
                final summaryData = entry.value;
                final count = summaryData['count'];
                final wire = summaryData['wire'] as Wire;
                final breaker = summaryData['finalBreakerSize'];
                final shortInsulation = wire.insulation.length > 4 ? wire
                    .insulation.substring(0, 4) : wire.insulation;
                String summaryText = "($count) #${wire.size.replaceAll(
                    " AWG", "")} $shortInsulation";
                if (breaker > 0) {
                  summaryText += " -> ${breaker}A Breaker";
                }
                return DropdownMenuItem(
                  value: key,
                  child: Center(
                      child: Text(summaryText, textAlign: TextAlign.center,)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedWireSummaryKey = v);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return SizedBox(
      width: MediaQuery
          .of(context)
          .size
          .width * 0.6,
      child: const Divider(color: kSilver, height: 1),
    );
  }

  Widget _buildPipeInfoSection() {
    final String pipeSize = _activePipe.size != null
        ? '${_activePipe.size}"'
        : "N/A";
    String infoText = pipeSize;

    if (widget.selectedBoxSize != null) {
      final boxSize = widget.selectedBoxSize!;
      final boxFill = widget.results['boxFillPercent'] as double? ?? 0.0;
      infoText += " to $boxSize (${boxFill.toStringAsFixed(1)}% Fill)";
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.add_circle, color: kLight, size: 36),
                  onPressed: widget.onAddPipe),
              const SizedBox(width: 4),
              SizedBox(width: 140, child: _buildPipeSelectorDropdown()),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(infoText,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildPipeSelectorDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _localActivePipeIndex.toString(),
        hint: const Text("Select Pipe"),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: kLight, size: 36),
        style: const TextStyle(
            color: kLight, fontSize: 30, fontWeight: FontWeight.bold),
        dropdownColor: const Color(0xFF2C3030),
        items: List.generate(widget.pipes.length, (index) {
          return DropdownMenuItem(
            value: index.toString(),
            child: Center(child: Text("Pipe ${index + 1}")),
          );
        }),
        onChanged: (v) {
          if (v != null) {
            final newIndex = int.parse(v);
            setState(() => _localActivePipeIndex = newIndex);
            widget.onSetActivePipe(newIndex);
          }
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(
            color: kLight, fontWeight: FontWeight.bold, fontSize: 30)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _BoxUIDetailView extends StatefulWidget {
  final Map<String, dynamic> results;
  final int deviceCount;
  final int clampCount;
  final int supportFittingCount;
  final String? selectedMudRing;
  final String? selectedExtensionRingType; // Changed from _selectedExtensionRing
  final int extensionRingCount; // New: for quantity
  final List<Pipe> pipes;
  final String? selectedBoxSize;
  final List<Wire> allWires;
  final ValueChanged<int> onDeviceCountChanged;
  final ValueChanged<int> onClampCountChanged;
  final ValueChanged<int> onSupportFittingCountChanged;
  final ValueChanged<String?> onMudRingChanged;
  final ValueChanged<
      String?> onExtensionRingTypeChanged; // New callback for type
  final ValueChanged<int> onExtensionRingCountChanged; // New callback for count
  final Function(String pipeId, PullType pullType, EntrySide? entrySide) onPullTypeChanged; // Updated signature
  final int pullThroughWireCount; // NEW
  final ValueChanged<int> onPullThroughCountChanged; // NEW
  const _BoxUIDetailView({
    super.key,
    required this.results,
    required this.deviceCount,
    required this.clampCount,
    required this.supportFittingCount,
    required this.selectedMudRing,
    required this.selectedExtensionRingType, // Updated
    required this.extensionRingCount, // Added
    required this.pipes,
    this.selectedBoxSize,
    required this.allWires,
    required this.onDeviceCountChanged,
    required this.onClampCountChanged,
    required this.onSupportFittingCountChanged,
    required this.onMudRingChanged,
    required this.onExtensionRingTypeChanged, // Updated
    required this.onExtensionRingCountChanged, // Added
    required this.onPullTypeChanged,
    required this.pullThroughWireCount, // NEW
    required this.onPullThroughCountChanged, // NEW
  });

  @override
  State<_BoxUIDetailView> createState() => _BoxUIDetailViewState();
}

class _BoxUIDetailViewState extends State<_BoxUIDetailView> {
  late int _deviceCount;
  late int _clampCount;
  late int _supportFittingCount;
  String? _selectedMudRing;
  String? _selectedExtensionRingType; // Updated
  late int _extensionRingCount; // Updated
  late int _pullThroughWireCountLocal; // NEW
  // --- NEW: State for Expansion Tiles ---
  late bool _isVolumeDetailsExpanded; // Renamed from _isDetailedVolumeExpanded
  late bool _isJunctionBoxSizingExpanded;

  // --- NEW: Local state for Junction Box Sizing calculations ---
  double _localMinStraight = 0.0;
  double _localMinAngleLength = 0.0; // Separate for angle pulls
  double _localMinAngleWidth = 0.0; // Separate for angle pulls

  // --- NEW: Getter to check for #4 AWG or larger wires ---
  bool get _hasLargeWires {
    return widget.allWires.any((w) {
      if (w.size.contains("AWG")) {
        // Parse AWG number. Smaller number means larger wire (e.g., 4 AWG is larger than 6 AWG).
        final int awgNum = int.tryParse(w.size.replaceAll(" AWG", "")) ?? 99;
        return awgNum <= 4; // #4 AWG or larger (e.g., 4, 3, 2, 1, 1/0, etc.)
      } else if (w.size.contains("KCMIL")) {
        return true; // All KCMIL wires are considered large
      }
      return false;
    });
  }

  // --- NEW: Getter to check for 5S box or smaller ---
  bool get _isSmallBox {
    if (widget.selectedBoxSize == null) return false;

    final String boxName = widget.selectedBoxSize!;
    // Define the list of "5S and smaller" boxes
    const List<String> smallBoxPrefixes = [
      "4o", "4s", "5s", "Device", "Masonry", "FS", "FD"
    ];

    return smallBoxPrefixes.any((prefix) => boxName.startsWith(prefix));
  }


  @override
  void initState() {
    super.initState();
    _deviceCount = widget.deviceCount;
    _clampCount = widget.clampCount;
    _supportFittingCount = widget.supportFittingCount;
    _selectedMudRing = widget.selectedMudRing;
    _selectedExtensionRingType = widget.selectedExtensionRingType; // Updated
    _extensionRingCount = widget.extensionRingCount; // Updated
    _pullThroughWireCountLocal = widget.pullThroughWireCount;
    // --- NEW: Initialize Expansion States based on wire size AND box size ---
    final bool hasLargeWires = _hasLargeWires;
    final bool isSmallBox = _isSmallBox;

    _isJunctionBoxSizingExpanded =
        hasLargeWires; // If large wires, JBS is expanded
    _isVolumeDetailsExpanded = !hasLargeWires &&
        isSmallBox; // If no large wires AND small box, Volume Details is expanded

    _calculateLocalJunctionBoxSizing(); // Calculate initial JBS values
  }

  @override
  void didUpdateWidget(covariant _BoxUIDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update local state variables from widget props
    _deviceCount = widget.deviceCount;
    _clampCount = widget.clampCount;
    _supportFittingCount = widget.supportFittingCount;
    _selectedMudRing = widget.selectedMudRing;
    _selectedExtensionRingType = widget.selectedExtensionRingType;
    _extensionRingCount = widget.extensionRingCount;
    _pullThroughWireCountLocal = widget.pullThroughWireCount;

    // --- CRITICAL UPDATE: Dynamic clearing of accessories based on new box size ---
    if (widget.selectedBoxSize != oldWidget.selectedBoxSize) {
      final bool newBoxIsLarge = !_isSmallBox; // Check if the NEW selected box is a "large box"

      if (newBoxIsLarge) {
        // Clear all accessories if switching to a large box
        if (_selectedMudRing != null) {
          _selectedMudRing = null;
          widget.onMudRingChanged(null);
        }
        if (_selectedExtensionRingType != null || _extensionRingCount > 0) {
          _selectedExtensionRingType = null;
          _extensionRingCount = 0;
          widget.onExtensionRingTypeChanged(null);
          widget.onExtensionRingCountChanged(0);
        }
        if (_deviceCount > 0) {
          _deviceCount = 0;
          widget.onDeviceCountChanged(0);
        }
        if (_clampCount > 0) {
          _clampCount = 0;
          widget.onClampCountChanged(0);
        }
        if (_supportFittingCount > 0) {
          _supportFittingCount = 0;
          widget.onSupportFittingCountChanged(0);
        }
      } else {
        // If switching to a small box, just ensure compatibility for rings
        if (_selectedMudRing != null &&
            !ConduitDB.mudRingVolumes.containsKey(_selectedMudRing)) {
          _selectedMudRing = null;
          widget.onMudRingChanged(null);
        }
        // Also check extension ring compatibility based on selectedBoxSize
        if (_selectedExtensionRingType != null) {
          String? boxTypePrefix;
          if (widget.selectedBoxSize?.startsWith("4s") == true ||
              widget.selectedBoxSize?.startsWith("4o") == true) {
            boxTypePrefix = "4S";
          } else if (widget.selectedBoxSize?.startsWith("5s") == true) {
            boxTypePrefix = "5S";
          }

          if (boxTypePrefix == null ||
              !_selectedExtensionRingType!.startsWith(boxTypePrefix)) {
            _selectedExtensionRingType = null;
            _extensionRingCount = 0;
            widget.onExtensionRingTypeChanged(null);
            widget.onExtensionRingCountChanged(0);
          }
        }
      }
    }


    // Re-evaluate expansion states and JBS calculations if relevant props change
    final bool hasLargeWiresNow = _hasLargeWires;
    final bool isSmallBoxNow = _isSmallBox;

    bool shouldReevaluateExpansion = (hasLargeWiresNow != _hasLargeWires) ||
        (isSmallBoxNow != _isSmallBox) ||
        (widget.selectedBoxSize != oldWidget.selectedBoxSize);


    if (shouldReevaluateExpansion) {
      setState(() {
        _isJunctionBoxSizingExpanded = hasLargeWiresNow;
        _isVolumeDetailsExpanded = !hasLargeWiresNow && isSmallBoxNow;
      });
    }

    // Re-calculate JBS if pipes or wires change
    bool pipesChanged = oldWidget.pipes.length != widget.pipes.length;
    if (!pipesChanged) {
      for (int i = 0; i < widget.pipes.length; i++) {
        if (i < oldWidget.pipes.length &&
            (widget.pipes[i].pullType != oldWidget.pipes[i].pullType ||
                widget.pipes[i].entrySide != oldWidget.pipes[i].entrySide ||
                widget.pipes[i].size != oldWidget.pipes[i].size)) {
          pipesChanged = true;
          break;
        }
      }
    }

    if (pipesChanged || oldWidget.allWires != widget.allWires) {
      _calculateLocalJunctionBoxSizing();
    }
  }


  // --- NEW: Local JBS calculation for real-time updates ---
  void _calculateLocalJunctionBoxSizing() {
    double largestStraightTradeSize = 0.0;
    Map<EntrySide, List<double>> anglePullConduitsByWall = {
      EntrySide.top: [],
      EntrySide.bottom: [],
      EntrySide.left: [],
      EntrySide.right: [],
      EntrySide.back: []
    };

    for (final pipe in widget.pipes) {
      if (pipe.size != null) {
        final double tradeSizeInInches = ConduitDB.tradeSizesInches[pipe
            .size!] ?? 0.0;

        if (pipe.pullType == PullType.straight) {
          if (tradeSizeInInches > largestStraightTradeSize) {
            largestStraightTradeSize = tradeSizeInInches;
          }
        } else { // Angle Pull
          anglePullConduitsByWall[pipe.entrySide]?.add(tradeSizeInInches);
        }
      }
    }

    // Calculate length requirement (left/right walls)
    double maxLeftRightDimension = 0.0;
    List<double> leftWallConduits = anglePullConduitsByWall[EntrySide.left] ??
        [];
    List<double> rightWallConduits = anglePullConduitsByWall[EntrySide.right] ??
        [];

    if (leftWallConduits.isNotEmpty) {
      double largestLeft = leftWallConduits.reduce(max);
      double sumOthersLeft = leftWallConduits.fold(
          0.0, (sum, val) => sum + val) - largestLeft;
      maxLeftRightDimension =
          max(maxLeftRightDimension, (largestLeft * 6) + sumOthersLeft);
    }
    if (rightWallConduits.isNotEmpty) {
      double largestRight = rightWallConduits.reduce(max);
      double sumOthersRight = rightWallConduits.fold(
          0.0, (sum, val) => sum + val) - largestRight;
      maxLeftRightDimension =
          max(maxLeftRightDimension, (largestRight * 6) + sumOthersRight);
    }
    double minAngleLength = maxLeftRightDimension; // Initialize minAngleLength

    // Calculate width requirement (top/bottom walls)
    double maxTopBottomDimension = 0.0;
    List<double> topWallConduits = anglePullConduitsByWall[EntrySide.top] ?? [];
    List<double> bottomWallConduits = anglePullConduitsByWall[EntrySide
        .bottom] ?? [];

    if (topWallConduits.isNotEmpty) {
      double largestTop = topWallConduits.reduce(max);
      double sumOthersTop = topWallConduits.fold(0.0, (sum, val) => sum + val) -
          largestTop;
      maxTopBottomDimension =
          max(maxTopBottomDimension, (largestTop * 6) + sumOthersTop);
    }
    if (bottomWallConduits.isNotEmpty) {
      double largestBottom = bottomWallConduits.reduce(max);
      double sumOthersBottom = bottomWallConduits.fold(
          0.0, (sum, val) => sum + val) - largestBottom;
      maxTopBottomDimension =
          max(maxTopBottomDimension, (largestBottom * 6) + sumOthersBottom);
    }
    double minAngleWidth = maxTopBottomDimension; // Initialize minAngleWidth

    // Find the largest angle pull conduit from the back wall
    double largestBackWallAngleConduit = 0.0;
    List<double> backWallConduits = anglePullConduitsByWall[EntrySide.back] ??
        [];
    if (backWallConduits.isNotEmpty) {
      largestBackWallAngleConduit = backWallConduits.reduce(max);
    }

    // If there's a largest angle pull conduit from the back, it requires 6x its size
    // in both the length and width dimensions to accommodate the turn.
    if (largestBackWallAngleConduit > 0) {
      minAngleLength = max(minAngleLength, largestBackWallAngleConduit * 6);
      minAngleWidth = max(minAngleWidth, largestBackWallAngleConduit * 6);
    }


    setState(() {
      _localMinStraight = largestStraightTradeSize * 8;
      _localMinAngleLength = minAngleLength;
      _localMinAngleWidth = minAngleWidth;
    });
  }

  // --- NEW: Local Calculation Method for Box Fill Details (identical to _calculateResults part for box fill) ---
  Map<String, dynamic> _calculateLocalBoxFillDetails() {
    final allWires = widget.allWires;

    // Calculate total non-ground wires (used for both label and calculation)
    final int totalNonGroundWires = allWires
        .where((w) => !w.isGround)
        .length;

    // Determine the allowance volume per non-ground wire based on the largest non-ground conductor
    Wire? largestNonGroundConductor = allWires
        .where((w) => !w.isGround)
        .toList()
        .fold(
        null,
            (largest, current) {
          if (largest == null) return current;
          final largestSize = int.tryParse(
              largest.size.replaceAll(RegExp(r' AWG| KCMIL'), '')) ??
              0;
          final currentSize = int.tryParse(
              current.size.replaceAll(RegExp(r' AWG| KCMIL'), '')) ??
              0;
          return currentSize < largestSize ? current : largest;
        });

    double allowanceVolumePerWire = 0;
    if (largestNonGroundConductor != null) {
      allowanceVolumePerWire =
          ConduitDB.wireVolumes[largestNonGroundConductor.size] ?? 0.0;
    }

    // Calculate conductor volume: only "spliced/device" wires contribute 1 allowance.
    // "Pull-through" wires (up to the total non-ground wires) contribute 0 allowances.
    final int effectivePullThroughCount = min(
        _pullThroughWireCountLocal, totalNonGroundWires); // Use local state
    final int splicedWiresCount = totalNonGroundWires -
        effectivePullThroughCount;
    final double conductorVolume = splicedWiresCount * allowanceVolumePerWire;

    // Calculate grounding volume based on the largest ground wire (one allowance)
    double groundingVolume = 0.0;
    final groundWires = allWires.where((w) => w.isGround).toList();
    Wire? largestGround = groundWires.fold(
        null,
            (largest, current) {
          if (largest == null) return current;
          final largestSize = int.tryParse(
              largest.size.replaceAll(RegExp(r' AWG| KCMIL'), '')) ??
              0;
          final currentSize = int.tryParse(
              current.size.replaceAll(RegExp(r' AWG| KCMIL'), '')) ??
              0;
          return currentSize < largestSize ? current : largest;
        });

    if (largestGround != null) {
      final double groundAllowance =
          ConduitDB.wireVolumes[largestGround.size] ?? 0.0;
      // NEC 314.16(B)(5) - 1 allowance for all equipment grounding conductors
      groundingVolume = groundAllowance;
    }
    // NEW: Debugging prints for volumes
    print('DEBUG: allowanceVolumePerWire: $allowanceVolumePerWire');
    print('DEBUG: _deviceCount: $_deviceCount, _clampCount: $_clampCount, _supportFittingCount: $_supportFittingCount');

    // Calculate allowance volumes for devices, clamps, support fittings
    final double clampVolume = _clampCount *
        allowanceVolumePerWire; // NEC 314.16(B)(2)
    final double supportFittingVolume = _supportFittingCount *
        allowanceVolumePerWire; // NEC 314.16(B)(3)
    final double deviceVolume = _deviceCount * 2 *
        allowanceVolumePerWire; // NEC 314.16(B)(4) (2 allowances per yoke)
// NEW: Debugging prints for current ring selections and base box volume
    print('DEBUG: widget.selectedBoxSize: ${widget.selectedBoxSize}');
    print('DEBUG: _selectedMudRing: $_selectedMudRing');
    print('DEBUG: _selectedExtensionRingType: $_selectedExtensionRingType');
    print('DEBUG: _extensionRingCount: $_extensionRingCount');
    // Calculate max box volume including mud rings and extension rings
    double maxBoxVolume =
    widget.selectedBoxSize != null ? (ConduitDB.boxVolumes[widget
        .selectedBoxSize!] ?? 0.0) : 0.0;
    if (_selectedMudRing != null) {
      maxBoxVolume += ConduitDB.mudRingVolumes[_selectedMudRing!] ?? 0.0;
    }
    double extensionRingTotalVolume = 0.0;
    if (_selectedExtensionRingType != null && _extensionRingCount > 0) {
      final double? singleRingVolume =
      ConduitDB.extensionRingVolumes[_selectedExtensionRingType!];
      if (singleRingVolume != null) {
        extensionRingTotalVolume = singleRingVolume * _extensionRingCount;
        maxBoxVolume += extensionRingTotalVolume;
      }
    }

    // Calculate total box volume occupied by all components
    final double totalBoxVolume = conductorVolume + groundingVolume +
        clampVolume +
        supportFittingVolume + deviceVolume;

    // Calculate box fill percentage and violation status
    final double boxFillPercent = totalBoxVolume.isFinite && maxBoxVolume > 0
        ? (totalBoxVolume / maxBoxVolume) * 100
        : 0.0;
    final bool isBoxFillViolation = totalBoxVolume > maxBoxVolume;

    return {
      'conductorVolume': conductorVolume,
      'groundingVolume': groundingVolume,
      'clampVolume': clampVolume,
      'supportFittingVolume': supportFittingVolume,
      'deviceVolume': deviceVolume,
      'totalBoxVolume': totalBoxVolume,
      'maxBoxVolume': maxBoxVolume,
      'boxFillPercent': boxFillPercent,
      'isBoxFillViolation': isBoxFillViolation,
      'extensionRingTotalVolume': extensionRingTotalVolume,
      'totalNonGroundWires': totalNonGroundWires,
      // Include for display in debug/info
    };
  }

  // --- NEW: Info Dialog for Box Design Screen ---
  void _showBoxDesignInfoDialog(BuildContext context) {
    String title;
    String content;
    List<Widget> actions = []; // List to hold dynamic actions

    if (_hasLargeWires) {
      title = "Pull and Junction Box Sizing Help";
      content = '''This section helps determine the minimum required box dimensions for conductors No. 4 AWG and larger.

• What to do:
  - For each pipe connected to this box, select its 'Pull Type' (Straight or Angle) and the 'Entry Side' (Top, Bottom, Left, Right, Back).
  - The calculator uses the largest conduit size for each type of pull.

• What to expect:
  - 'Minimum Straight Pull Length': The box's shortest dimension must be at least 8 times the trade size of the largest straight-pulled raceway.
  - 'Minimum Angle/U-Pull Box Length/Width': The box's dimensions on its face must be at least 6 times the largest angled raceway, plus the sum of other raceways on that wall. Conduits entering the back wall for an angle pull will impose this 6x rule on both length and width.

These calculations ensure adequate space for bending and conductor manipulation, protecting conductors from damage.
''';
      actions.add(
        TextButton(
          child: const Text("NEC: Learn More", style: TextStyle(color: kRed)),
          onPressed: () {
            Navigator.pop(context); // Close the current dialog
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const JunctionBoxSizingCodeScreen()));
          },
        ),
      );
    } else {
      title = "Box Fill Details for 5S and Smaller Boxes";
      content = '''This section guides you in managing the volume of conductors and devices within your chosen box to comply with NEC 314.16.

• What to do:
  - Add devices (switches/outlets), internal cable clamps, and support fittings using the steppers provided. Each adds to the total occupied box volume.
  - Customize your box's available volume by selecting a 'Mud Ring' and choosing 'Extension Rings' (including their quantity) from the respective dropdowns and steppers.
  - If you have multiple pipes connected to the box and conductors pass through without splice or termination, use the 'Pull-Through Wires' stepper to accurately reduce their box fill contribution.

• What to expect:
  - The calculated total volume and fill percentage will update continuously at the top of the screen.
  - The status will indicate compliance (Green) or a violation (Red) based on the box's maximum allowable volume.
''';
      actions.add(
        TextButton(
          child: const Text("NEC: Learn More", style: TextStyle(color: kRed)),
          onPressed: () {
            Navigator.pop(context); // Close the current dialog
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const BoxSizingCodeScreen()));
          },
        ),
      );
    }

    // Add the common "Close" button
    actions.add(
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close', style: TextStyle(color: kLight)),
      ),
    );

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF212121),
            scrollable: true,
            // This is crucial for fixing content cutoff
            title: Text(title, style: const TextStyle(
                color: kLight, fontWeight: FontWeight.bold, fontSize: 20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              // Ensures column only takes up needed space
              children: [
                Text(content,
                    style: const TextStyle(color: kLight, fontSize: 16)),
                const SizedBox(height: 50.0),
                // Generous spacing at the bottom, adjustable as needed
              ],
            ),
            actions: actions,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Call local calculation for real-time updates ---
    final localBoxFillResults = _calculateLocalBoxFillDetails();
    final totalVolume = localBoxFillResults['totalBoxVolume'] as double? ?? 0.0;
    final maxBoxVolume = localBoxFillResults['maxBoxVolume'] as double? ?? 0.0;
    final isViolation = localBoxFillResults['isBoxFillViolation'] as bool? ??
        false;
    final conductorVolume = localBoxFillResults['conductorVolume'] as double? ??
        0.0;
    final groundingVolume = localBoxFillResults['groundingVolume'] as double? ??
        0.0;
    final clampVolume = localBoxFillResults['clampVolume'] as double? ?? 0.0;
    final supportFittingVolume = localBoxFillResults['supportFittingVolume'] as double? ??
        0.0;
    final deviceVolume = localBoxFillResults['deviceVolume'] as double? ?? 0.0;
    final extensionRingTotalVolume = localBoxFillResults['extensionRingTotalVolume'] as double? ??
        0.0;

    final bool hasLargeWires = _hasLargeWires;
    final bool isSmallBox = _isSmallBox;
    final int totalNonGroundWires = widget.allWires
        .where((w) => !w.isGround)
        .length; // NEW

    return Scaffold(
      backgroundColor: const Color(0xD8000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        title: const Text('Box Design',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showBoxDesignInfoDialog(context),
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: 'box-hero',
          child: Container(
            width: double.infinity,
            height: double.infinity,
            margin: const EdgeInsets.all(24),
            child: Material(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Box Fill Summary (Always Visible) ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(

                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Text(
                                    hasLargeWires
                                        ? "Box Fill: Not applicable"
                                        : "Box Fill: ${widget.selectedBoxSize ??
                                        'N/A'}",
                                    style: TextStyle(
                                      color: hasLargeWires
                                          ? Colors.grey[600]
                                          : kLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    hasLargeWires
                                        ? "" // No value when not applicable
                                        : "${totalVolume.toStringAsFixed(
                                        2)} / ${maxBoxVolume
                                        .toStringAsFixed(2)} in³",
                                    style: TextStyle(
                                      color: hasLargeWires
                                          ? Colors.grey[600]
                                          : (isViolation ? kRed : Colors.green),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                          const SizedBox(height: 8),

                              const SizedBox(height: 12),
                              if (!hasLargeWires) ...[ // Correct usage of the spread operator with if
                            _buildDetailRow("Conductors", conductorVolume,
                                prefix: '-'),
                            if (groundingVolume > 0) _buildDetailRow(
                                "Grounding", groundingVolume, prefix: '-'),
                            if (deviceVolume > 0) _buildDetailRow(
                                "Devices (${_deviceCount})", deviceVolume,
                                prefix: '-'),
                            if (clampVolume > 0) _buildDetailRow(
                                "Clamps (${_clampCount})", clampVolume,
                                prefix: '-'),
                            if (supportFittingVolume > 0) _buildDetailRow(
                                "Support Fittings (${_supportFittingCount})",
                                supportFittingVolume, prefix: '-'),
                            if (widget.selectedMudRing != null)
                              _buildDetailRow(
                                  "Mud Ring (${widget.selectedMudRing})",
                                  ConduitDB.mudRingVolumes[widget.selectedMudRing!] ?? 0.0,
                                  prefix: '+'),
                            if (extensionRingTotalVolume > 0) _buildDetailRow(
                                "Extension Rings (${_extensionRingCount} x ${_selectedExtensionRingType
                                    ?.split(" ")[1] ??
                                    ''} ${_selectedExtensionRingType?.split(
                                    " ")[2] ?? ''})", extensionRingTotalVolume,
                                prefix: '+'),
                          ],
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 20),

                      // --- Collapsible Detailed Volume Breakdown (Inputs ONLY) ---
                      ExpansionTile(
                        key: const PageStorageKey('volumeDetailsTile'),
                        initiallyExpanded: _isVolumeDetailsExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isVolumeDetailsExpanded = expanded;
                            if (expanded) {
                              _isJunctionBoxSizingExpanded =
                              false; // Collapse JBS if this expands
                            }
                          });
                        },
                        // NEW TITLE and conditional disabling
                        title: _buildExpansionTileTitle(
                          "Volume Details for 5S and Smaller Boxes",
                          isEnabled: isSmallBox,
                          disabledMessage: "Not applicable for this box size",
                        ),
                        trailing: isSmallBox
                            ? Icon(
                            _isVolumeDetailsExpanded
                                ? Icons.arrow_drop_up
                                : Icons
                                .arrow_drop_down,
                            color: kLight
                        )
                            : Icon(Icons.do_not_disturb_alt,
                            color: Colors.grey[600]),
                        children: [
                          // NEW: Pull-Through Wires Stepper moved to top and highlighted
                          if (totalNonGroundWires > 0 && widget.pipes.length >
                              1 && isSmallBox)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                // Gray background
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                    color: kSilver.withAlpha(128)),
                              ),
                              child: _buildAllowanceStepper(
                                "Pull-Through Wires (total non-ground: ${totalNonGroundWires})",
                                _pullThroughWireCountLocal,
                                    (c) {
                                  setState(() {
                                    _pullThroughWireCountLocal = c;
                                  });
                                  widget.onPullThroughCountChanged(c);
                                },
                                max: totalNonGroundWires,
                                isEnabled: isSmallBox,
                              ),
                            ),
                          // Original inputs for volume contributions (now below pull-through)
                          _buildMudRingSelector(isEnabled: isSmallBox),
                          _buildExtensionRingSelectionAndStepper(
                              isEnabled: isSmallBox),
                          _buildAllowanceStepper(
                              "Devices (switches/outlets)", _deviceCount, (c) {
                            setState(() => _deviceCount = c);
                            widget.onDeviceCountChanged(c); // Notify parent
                          }, isEnabled: isSmallBox),
                          _buildAllowanceStepper(
                              "Internal Cable Clamps", _clampCount, (c) {
                            setState(() => _clampCount = c);
                            widget.onClampCountChanged(c); // Notify parent
                          }, max: 1, isEnabled: isSmallBox),
                          _buildAllowanceStepper(
                              "Support Fittings (studs/hickeys)",
                              _supportFittingCount, (c) {
                            setState(() => _supportFittingCount = c);
                            widget.onSupportFittingCountChanged(
                                c); // Notify parent
                          }, isEnabled: isSmallBox),
                        ],
                      ),

                      // --- Collapsible Pull and Junction Box Sizing (Conditional & Expanded by default) ---
                      ExpansionTile(
                        key: const PageStorageKey('junctionBoxSizingTile'),
                        initiallyExpanded: _isJunctionBoxSizingExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isJunctionBoxSizingExpanded = expanded;
                            if (expanded) { // If JBS expands, collapse detailed volume
                              _isVolumeDetailsExpanded = false;
                            }
                          });
                        },
                        // Conditional disabling for JBS
                        title: _buildExpansionTileTitle(
                          "Pull and Junction Box Sizing (No. 4 AWG or larger)",
                          isEnabled: hasLargeWires,
                          disabledMessage: "Not applicable for small wires",
                        ),
                        trailing: hasLargeWires
                            ? Icon(
                            _isJunctionBoxSizingExpanded
                                ? Icons.arrow_drop_up
                                : Icons
                                .arrow_drop_down,
                            color: kLight
                        )
                            : Icon(Icons.do_not_disturb_alt,
                            color: Colors.grey[600]),
                        children: [
                          const SizedBox(height: 8),
                          Text(
                              "Minimum Straight Pull Length: ${_localMinStraight
                                  .toStringAsFixed(1)}\"",
                              style: TextStyle(
                                  color: hasLargeWires ? Colors.white70 : Colors
                                      .grey[600], fontSize: 16)),
                          Text(
                              "Minimum Angle/U-Pull Box Length: ${_localMinAngleLength
                                  .toStringAsFixed(1)}\"",
                              style: TextStyle(
                                  color: hasLargeWires ? Colors.white70 : Colors
                                      .grey[600], fontSize: 16)),
                          Text(
                              "Minimum Angle/U-Pull Box Width: ${_localMinAngleWidth
                                  .toStringAsFixed(1)}\"",
                              style: TextStyle(
                                  color: hasLargeWires ? Colors.white70 : Colors
                                      .grey[600], fontSize: 16)),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.pipes.length,
                            itemBuilder: (context, index) {
                              final pipe = widget.pipes[index];
                              return _buildPullTypeAndEntrySideSelector(
                                  pipe, index,
                                  isEnabled: hasLargeWires);
                            },
                          ),
                          const Divider(color: Colors.white24, height: 20),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(child: _StyledButton(onPressed: () =>
                          Navigator.of(context).pop(), label: "Done")),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Helper widget to build title with disabled state
  Widget _buildExpansionTileTitle(String title,
      {required bool isEnabled, String? disabledMessage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(
            color: isEnabled ? kLight : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 18)),
        if (!isEnabled && disabledMessage != null)
          Text(disabledMessage, style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic)),
      ],
    );
  }


  // NEW: Combines PullType and EntrySide selection
  Widget _buildPullTypeAndEntrySideSelector(Pipe pipe, int index,
      {required bool isEnabled}) {
    final Color? textColor = isEnabled ? kLight : Colors.grey[600];
    final Color? iconColor = isEnabled ? kLight : Colors.grey[600];
    final Color? toggleFillColor = isEnabled ? kRed : Colors.grey[700];
    final Color? toggleBorderColor = isEnabled ? kRed : Colors.grey[600];
    final Color? dropDownHintColor = isEnabled ? Colors.white70 : Colors
        .grey[600];

    return AbsorbPointer(
      absorbing: !isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Pipe ${index + 1} (${pipe.size ?? 'N/A'})",
                  style: TextStyle(color: textColor, fontSize: 16)),
              Row(
                children: [
                  ToggleButtons(
                    isSelected: [
                      pipe.pullType == PullType.straight,
                      pipe.pullType == PullType.angle
                    ],
                    onPressed: isEnabled ? (int newIndex) {
                      setState(() {
                        pipe.pullType =
                        newIndex == 0 ? PullType.straight : PullType.angle;
                        widget.onPullTypeChanged(pipe.id, pipe.pullType,
                            pipe.entrySide); // Pass updated entrySide
                        _calculateLocalJunctionBoxSizing(); // Recalculate and update JBS locally
                      });
                    } : null,
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: kLight,
                    color: Colors.white70,
                    fillColor: toggleFillColor,
                    selectedBorderColor: toggleBorderColor,
                    borderColor: kSilver,
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("Straight")),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("Angle")),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Spacing between toggle and dropdown
                  SizedBox(
                    width: 100, // Adjust width as needed
                    child: _StyledDropdown(
                      value: pipe.entrySide.toString(),
                      // Store enum as string
                      hint: "Side",
                      items: EntrySide.values.map((side) =>
                          DropdownMenuItem(
                              value: side.toString(),
                              child: Text(side
                                  .toString()
                                  .split('.')
                                  .last
                                  .capitalizeFirst()) // "Top", "Bottom", etc.
                          )).toList(),
                      onChanged: isEnabled ? (v) {
                        if (v != null) {
                          setState(() {
                            pipe.entrySide = EntrySide.values.firstWhere((e) =>
                            e.toString() == v);
                            widget.onPullTypeChanged(pipe.id, pipe.pullType,
                                pipe.entrySide); // Pass updated pullType
                            _calculateLocalJunctionBoxSizing(); // Recalculate
                          });
                        }
                      } : null,
                      isEnabled: isEnabled,
                      // Pass enabled state to dropdown
                      iconColor: iconColor,
                      hintColor: dropDownHintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAllowanceStepper(String title, int count,
      ValueChanged<int> onChanged, {int max = 100, required bool isEnabled}) {
    final Color? textColor = isEnabled ? kLight : Colors.grey[600];
    final Color? buttonColor = isEnabled ? kLight : Colors.grey[600];

    return AbsorbPointer(
      absorbing: !isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(
                  title, style: TextStyle(color: textColor, fontSize: 16))),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF2C3030),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kSilver.withAlpha(128))),
                child: Row(
                  children: [
                    IconButton(icon: Icon(Icons.remove, color: buttonColor),
                        onPressed: count > 0 && isEnabled
                            ? () => onChanged(count - 1)
                            : null),
                    Text('$count', style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                    IconButton(icon: Icon(Icons.add, color: buttonColor),
                        onPressed: count < max && isEnabled
                            ? () => onChanged(count + 1)
                            : null),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMudRingSelector({required bool isEnabled}) {
    final Color? textColor = isEnabled ? kLight : Colors.grey[600];
    final Color? dropDownHintColor = isEnabled ? Colors.white70 : Colors
        .grey[600];
    return AbsorbPointer(
      absorbing: !isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text("Mud Ring / Plaster Ring",
                    style: TextStyle(color: textColor, fontSize: 16)),
              ),
              SizedBox(
                width: 150,
                child: _StyledDropdown(
                  value: _selectedMudRing,
                  hint: "Select Ring",
                  items: ConduitDB.mudRingVolumes.keys.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: isEnabled ? (v) {
                    setState(() => _selectedMudRing = v);
                    widget.onMudRingChanged(v); // Notify parent
                  } : null,
                  isEnabled: isEnabled,
                  hintColor: dropDownHintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtensionRingSelectionAndStepper({required bool isEnabled}) {
    // Determine if the selected box is 4S or 5S to filter extension rings
    String? boxTypePrefix;
    if (widget.selectedBoxSize?.startsWith("4s") == true ||
        widget.selectedBoxSize?.startsWith("4o") == true) {
      boxTypePrefix = "4S";
    } else if (widget.selectedBoxSize?.startsWith("5s") == true) {
      boxTypePrefix = "5S";
    }

    final filteredItems = ConduitDB.extensionRingVolumes.keys
        .where((key) => boxTypePrefix == null || key.startsWith(boxTypePrefix))
        .map((s) =>
        DropdownMenuItem(
          value: s,
          child: Text(s.split(" ")[1] + " " +
              s.split(" ")[2]), // Display only the depth, e.g., "1-1/2 inch"
        ))
        .toList();

    // The displayed value in the dropdown when an item is selected
    String? displayedSelectedExtensionRingType;
    if (_selectedExtensionRingType != null) {
      final parts = _selectedExtensionRingType!.split(" ");
      if (parts.length >= 3) {
        displayedSelectedExtensionRingType = "${parts[1]} ${parts[2]}";
      }
    }

    final Color? textColor = isEnabled ? kLight : Colors.grey[600];
    final Color? dropDownHintColor = isEnabled ? Colors.white70 : Colors
        .grey[600];

    return AbsorbPointer(
      absorbing: !isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text("Extension Ring",
                        style: TextStyle(color: textColor, fontSize: 16)),
                  ),
                  // Dropdown for selecting the ring TYPE
                  SizedBox(
                    width: 150,
                    child: _StyledDropdown(
                      value: _selectedExtensionRingType,
                      hint: "Select Type",
                      items: filteredItems,
                      onChanged: isEnabled ? (v) {
                        setState(() {
                          _selectedExtensionRingType = v;
                          // If type changes, reset count to 1, or 0 if null
                          _extensionRingCount = (v != null) ? 1 : 0;
                        });
                        widget.onExtensionRingTypeChanged(v); // Notify parent
                        widget.onExtensionRingCountChanged(
                            _extensionRingCount); // Notify parent
                      } : null,
                      isEnabled: isEnabled,
                      hintColor: dropDownHintColor,
                    ),
                  ),
                ],
              ),
              if (_selectedExtensionRingType !=
                  null) // Only show stepper if a type is selected
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildAllowanceStepper(
                    // Display the selected type and make it look like other steppers
                    displayedSelectedExtensionRingType ?? "Quantity",
                    _extensionRingCount,
                        (c) {
                      setState(() => _extensionRingCount = c);
                      widget.onExtensionRingCountChanged(c); // Notify parent
                    },
                    max: 10, // Arbitrary max for extension rings
                    isEnabled: isEnabled,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  List<Widget> _buildConductorDetails(List<Wire> allWires, {String prefix = '-'}) {
    if (allWires.isEmpty) return [];

    final wireGroups = <String, int>{};
    for (final wire in allWires) {
      if (!wire.isGround) { // Only count non-ground conductors for this detail list
        final key = "${wire.size} ${wire.insulation}";
        wireGroups[key] = (wireGroups[key] ?? 0) + 1;
      }
    }

    // Calculate allowance volume per wire based on the largest non-ground conductor
    Wire? largestNonGroundConductor = allWires
        .where((w) => !w.isGround)
        .toList()
        .fold(
        null,
            (largest, current) {
          if (largest == null) return current;
          final largestSize = int.tryParse(
              largest.size.replaceAll(RegExp(r' AWG| KCMIL'), '')) ??
              0;
          final currentSize = int.tryParse(
              current.size.replaceAll(RegExp(r' AWG| KCMIL'), '')) ??
              0;
          return currentSize < largestSize ? current : largest;
        });

    double allowanceVolumePerWire = 0;
    if (largestNonGroundConductor != null) {
      allowanceVolumePerWire =
          ConduitDB.wireVolumes[largestNonGroundConductor.size] ?? 0.0;
    }

    return wireGroups.entries.map((entry) {
      final count = entry.value;
      final description = entry.key;
      final volume = count * allowanceVolumePerWire; // Calculate volume for display
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 2, bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("  - ($count) $description",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text("${prefix}${volume.toStringAsFixed(2)} in³", // Display volume with prefix
                style: const TextStyle(color: kLight, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }).toList();
  }



  Widget _buildDetailRow(String label, double? value, {String? prefix}) {
    if (value == null || value == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text("${prefix ?? ''}${value.toStringAsFixed(2)} in³",
              style: const TextStyle(
                  color: kLight, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}


class PulsingGlowBorder extends StatelessWidget {
  final AnimationController animationController;
  final BoxShape shape;
  final Widget child;
  final Color startColor;
  final Color? endColor;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final bool isPulsing;

  const PulsingGlowBorder({
    super.key,
    required this.animationController,
    required this.shape,
    required this.child,
    this.startColor = kRed,
    this.endColor,
    this.borderRadius,
    this.borderWidth = 2.0,
    this.isPulsing = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        final Decoration decoration;
        if (isPulsing) {
          final double t = animationController.value;
          final Color? finalColor;
          // Create a multi-stage transition: Green -> Silver -> White -> Silver -> Green
          if (t < 0.33) {
            finalColor = Color.lerp(Colors.green, kSilver, t * 3);
          } else if (t < 0.66) {
            finalColor = Color.lerp(kSilver, kLight, (t - 0.33) * 3);
          } else {
            finalColor = Color.lerp(kLight, Colors.green, (t - 0.66) * 3);
          }

          decoration = BoxDecoration(
            shape: shape,
            borderRadius: borderRadius,
            border: Border.all(
              width: borderWidth,
              color: finalColor!,
            ),
          );
        } else {
          decoration = BoxDecoration(
            shape: shape,
            borderRadius: borderRadius,
            gradient: SweepGradient(
              colors: [
                endColor ?? startColor,
                startColor,
                endColor ?? startColor,
                startColor, // Add more stops for a smoother, longer gradient
                endColor ?? startColor,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0], // Distribute stops
              transform: GradientRotation(animationController.value * 2 * pi),
            ),
          );
        }

        return Container(
          decoration: decoration,
          child: child,
        );
      },
    );
  }
}


class _WireStepper extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const _WireStepper({
    required this.label,
    required this.count,
    required this.color,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2C3030),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.remove, color: kLight),
                  onPressed: count > 0 ? onRemove : null),
              Text('$count', style: const TextStyle(
                  color: kLight, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.add, color: kLight), onPressed: onAdd),
            ],
          ),
          Positioned(
            top: 1,
            left: 4,
            child: Text(
              label,
              style: TextStyle(color: color.withAlpha(128),
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isActive;
  final bool isDropdownStyle;
  final bool isEnabled;

  const _StyledButton({
    required this.onPressed,
    required this.label,
    this.isActive = false,
    this.isDropdownStyle = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isEnabled ? onPressed : null;
    return GestureDetector(
      onTap: effectiveOnPressed,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isEnabled
                ? (isActive
                ? [kRed, const Color(0xFFD43D37)]
                : [const Color(0xFF4E4E52), const Color(0xFF2C3030)])
                : [Colors.grey[800]!, Colors.grey[850]!],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kSilver.withAlpha(128), width: 1.1),
        ),
        child: isDropdownStyle
            ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              // Match dropdown padding
              child: Text(
                label,
                style: TextStyle(color: isEnabled ? kLight : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: isEnabled ? kLight : Colors.grey[600]),
          ],
        )
            : Center(
          child: Text(
            label,
            style: const TextStyle(
                color: kLight, fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final bool isActive;
  final bool isEnabled;
  final Color? iconColor;
  final Color? hintColor;


  const _StyledDropdown(
      { this.value, required this.hint, required this.items, required this.onChanged, this.isActive = false, this.isEnabled = true, this.iconColor, this.hintColor });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled ? (isActive ? [kRed, const Color(0xFFD43D37)] : [
            const Color(0xFF4E4E52),
            const Color(0xFF2C3030)
          ]) : [Colors.grey[800]!, Colors.grey[850]!],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kSilver.withAlpha(128), width: 1.1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(
              color: isEnabled ? (hintColor ?? Colors.white70) : Colors
                  .grey[600])),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down,
              color: isEnabled ? (iconColor ?? kLight) : Colors.grey[600]),
          style: const TextStyle(
              color: kLight, fontSize: 16, fontWeight: FontWeight.w700),
          dropdownColor: const Color(0xFF2C3030),
          items: items,
          onChanged: isEnabled ? onChanged : null,
        ),
      ),
    );
  }
}

class _PipeSelectionGrid extends StatelessWidget {
  final Function(String, PipeType) onSelect;

  const _PipeSelectionGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final sizes = ConduitDB.tradeSizesInches.keys.toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF2C3030),
      title: const Center(child: Text(
          "Select Pipe Size & Type", style: TextStyle(color: kLight))),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Expanded(child: Center(child: Text("Size", style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)))),
                  Expanded(child: Center(child: Text("EMT", style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)))),
                  Expanded(child: Center(child: Text("RMC", style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)))),
                ],
              ),
              const Divider(color: kSilver),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sizes.length,
                itemBuilder: (context, index) {
                  final size = sizes[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${size}"',
                          style: const TextStyle(color: kLight, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(child: Center(child: IconButton(
                        icon: const Icon(
                            Icons.circle_outlined, color: Colors.green),
                        onPressed: ConduitDB.emtTotalArea.containsKey(size)
                            ? () => onSelect(size, PipeType.emt)
                            : null,
                      ))),
                      Expanded(child: Center(child: IconButton(
                        icon: const Icon(
                            Icons.circle_outlined, color: Colors.green),
                        onPressed: ConduitDB.rmcTotalArea.containsKey(size)
                            ? () => onSelect(size, PipeType.rmc)
                            : null,
                      ))),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel", style: TextStyle(color: kLight)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}


class _WireSelectionGrid extends StatefulWidget {
  final List<String> sizes;
  final Function(String, ConductorMaterial) onSelect;
  final VoidCallback? onShowMoreWires;
  final bool isMoreWiresScreen;

  const _WireSelectionGrid({
    required this.sizes,
    required this.onSelect,
    this.onShowMoreWires,
    this.isMoreWiresScreen = false,
  });

  @override
  State<_WireSelectionGrid> createState() => _WireSelectionGridState();
}

class _WireSelectionGridState extends State<_WireSelectionGrid> {
  ConductorMaterial _selectedMaterial = ConductorMaterial.copper;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C3030),
      title: Center(child: Text(
          widget.isMoreWiresScreen
              ? "Select KCMIL Wire & Material"
              : "Select Wire Size & Material",
          style: const TextStyle(color: kLight)
      )),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Material Toggles (Copper / Aluminum)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4E4E52),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ToggleButtons(
                  isSelected: [
                    _selectedMaterial == ConductorMaterial.copper,
                    _selectedMaterial == ConductorMaterial.aluminum
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedMaterial =
                      index == 0 ? ConductorMaterial.copper : ConductorMaterial
                          .aluminum;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: kLight,
                  color: Colors.white70,
                  fillColor: kRed,
                  selectedBorderColor: kRed,
                  borderColor: kSilver,
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Copper")),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("Aluminum")),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Center(child: Text("Gauge", style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)))),
                  // No CU/AL headers here, handled by toggles above
                ],
              ),
              const Divider(color: kSilver),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.sizes.length,
                itemBuilder: (context, index) {
                  final size = widget.sizes[index];
                  // Check if the selected material has ampacity data for this size
                  final hasDataForMaterial = (_selectedMaterial ==
                      ConductorMaterial.copper &&
                      ConduitDB.copperAmpacities.containsKey(size)) ||
                      (_selectedMaterial == ConductorMaterial.aluminum &&
                          ConduitDB.aluminumAmpacities.containsKey(size));
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          size,
                          style: TextStyle(
                              color: hasDataForMaterial ? kLight : Colors
                                  .grey[600], fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(child: Center(child: IconButton(
                        icon: Icon(
                            Icons.circle_outlined,
                            color: hasDataForMaterial ? Colors.green : Colors
                                .grey[700]),
                        onPressed: hasDataForMaterial
                            ? () => widget.onSelect(size, _selectedMaterial)
                            : null,
                      ))),
                    ],
                  );
                },
              ),
              if (!widget.isMoreWiresScreen &&
                  widget.onShowMoreWires != null) ...[
                const Divider(color: kSilver),
                TextButton(
                  onPressed: widget.onShowMoreWires,
                  child: const Text("More Wires (1/0 AWG and larger)...",
                      style: TextStyle(
                          color: kRed, fontStyle: FontStyle.italic)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel", style: TextStyle(color: kLight)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}