import 'package:flutter/material.dart';
import 'dart:math';

import 'package:pipe_and_wire_clean/keypad_volt_drop.dart';

// --- STYLE CONSTANTS ---
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kSilver = Color(0xFF9E9E9E);

// --- ENUMS for State Management ---
enum CalculatorStep { pipe, box, wire, insulation, ambientTemp, boxSetup, free }
enum PullType { straight, angle }

// --- DATA MODELS & DATABASE ---
class ConduitDB {
  // Conductor volumes from NEC Table 314.16(B) in cubic inches
  static const Map<String, double> wireVolumes = {
    "14 AWG": 2.00, "12 AWG": 2.25, "10 AWG": 2.50, "8 AWG": 3.00, "6 AWG": 5.00,
    "4 AWG": 5.00, "3 AWG": 5.00, "2 AWG": 5.00, "1 AWG": 5.00,
  };

  // Standard box volumes in cubic inches from NEC Table 314.16(A)
  static const Map<String, double> boxVolumes = {
    "4o Shallow": 12.5, "4o": 15.5, "4o Deep": 21.5,
    "4s Shallow": 18.0, "4s": 21.0, "4s Deep": 30.3,
    "5s Shallow": 25.5, "5s": 29.5, "5s Deep": 42.0,
    "Device 3x2x1.5": 7.5, "Device 3x2x2": 10.0, "Device 3x2x2.25": 10.5,
    "Device 3x2x2.5": 12.5, "Device 3x2x2.75": 14.0, "Device 3x2x3.5": 18.0,
    "Device 4x2.125x1.5": 10.3, "Device 4x2.125x1.875": 13.0, "Device 4x2.125x2.125": 14.5,
    "Masonry 3.75x2x2.5": 14.0, "Masonry 3.75x2x3.5": 21.0,
    "FS Single Gang": 13.5, "FD Single Gang": 18.0,
    "FS Multi Gang": 18.0, "FD Multi Gang": 24.0,
    "6x6x4": 144.0, "8x8x4": 256.0, "10x10x4": 400.0, "12x12x4": 576.0, "12x12x6": 864.0,
  };

  static const List<String> popularBoxSizes = [
    "4s", "4s Deep", "5s", "5s Deep", "4o", "4o Deep",
    "6x6x4", "8x8x4", "10x10x4", "12x12x4",
  ];
  
  static const Map<String, double> mudRingVolumes = {
    "Flat": 0.0, "1/4\"": 2.5, "1/2\"": 5.0, "5/8\"": 5.5, "3/4\"": 6.0, "1\"": 7.5,
  };

  static const Map<String, Map<String, int>> copperAmpacities = {
    "14 AWG": {"60C": 15, "75C": 20, "90C": 25}, "12 AWG": {"60C": 20, "75C": 25, "90C": 30},
    "10 AWG": {"60C": 30, "75C": 35, "90C": 40}, "8 AWG": {"60C": 40, "75C": 50, "90C": 55},
    "6 AWG": {"60C": 55, "75C": 65, "90C": 75}, "4 AWG": {"60C": 70, "75C": 85, "90C": 95},
    "3 AWG": {"60C": 85, "75C": 100, "90C": 115}, "2 AWG": {"60C": 95, "75C": 115, "90C": 130},
    "1 AWG": {"60C": 110, "75C": 130, "90C": 145},
  };

  static const Map<String, Map<String, double>> wireAreas = {
    "14 AWG": {"THHN": 0.0097, "XHHW": 0.0139, "THWN-2": 0.0097}, "12 AWG": {"THHN": 0.0133, "XHHW": 0.0181, "THWN-2": 0.0133},
    "10 AWG": {"THHN": 0.0211, "XHHW": 0.0278, "THWN-2": 0.0211}, "8 AWG": {"THHN": 0.0366, "XHHW": 0.0437, "THWN-2": 0.0366},
    "6 AWG": {"THHN": 0.0507, "XHHW": 0.0590, "THWN-2": 0.0507}, "4 AWG": {"THHN": 0.0824, "XHHW": 0.0955, "THWN-2": 0.0824},
    "3 AWG": {"THHN": 0.0973, "XHHW": 0.1112, "THWN-2": 0.0973}, "2 AWG": {"THHN": 0.1158, "XHHW": 0.1332, "THWN-2": 0.1158},
    "1 AWG": {"THHN": 0.1562, "XHHW": 0.1771, "THWN-2": 0.1562},
  };

  static const Map<String, double> emtMaxFill = {
    "1/2": 0.122, "3/4": 0.213, "1": 0.346, "1-1/4": 0.598, "1-1/2": 0.814, "2": 1.342,
  };

  static const Map<String, double> tradeSizesInches = {
    "1/2": 0.5, "3/4": 0.75, "1": 1.0, "1-1/4": 1.25, "1-1/2": 1.5, "2": 2.0,
  };

  static const Map<String, Map<String, double>> temperatureCorrectionFactors = {
    "75C": {
      "70-77": 1.04, "78-86": 1.00, "87-95": 0.96, "96-104": 0.91,
      "105-113": 0.87, "114-122": 0.82, "123-131": 0.76, "132-140": 0.71,
    },
    "90C": {
      "70-77°F": 1.04, "78-86°F": 1.00, "87-95°F": 0.96, "96-104°F": 0.91,
      "105-113°F": 0.87, "114-122°F": 0.82, "123-131°F": 0.76, "132-140°F": 0.71,
    }
  };

  static const Map<String, double> wireResistance = {
    "14 AWG": 3.07, "12 AWG": 1.93, "10 AWG": 1.21, "8 AWG": 0.778,
    "6 AWG": 0.491, "4 AWG": 0.308, "3 AWG": 0.245, "2 AWG": 0.194, "1 AWG": 0.154,
  };

  static const List<int> standardBreakerSizes = [15, 20, 25, 30, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200];

  static const Map<int, String> groundWireSizes = {
    15: "14 AWG", 20: "12 AWG", 60: "10 AWG", 100: "8 AWG", 200: "6 AWG",
  };
}

class Wire {
  final String id = UniqueKey().toString();
  String size;
  String insulation;
  bool isGround;
  bool isNeutral;
  bool isCurrentCarrying;

  Wire({ required this.size, required this.insulation, this.isGround = false, this.isNeutral = false, this.isCurrentCarrying = true });
}

class Pipe {
  final String id = UniqueKey().toString();
  String? size;
  PullType pullType;
  List<Wire> wires = [];

  Pipe({this.size, this.pullType = PullType.straight});
}

class UnifiedFeederCalculator extends StatefulWidget {
  const UnifiedFeederCalculator({super.key});
  @override
  State<UnifiedFeederCalculator> createState() => _UnifiedFeederCalculatorState();
}

class _UnifiedFeederCalculatorState extends State<UnifiedFeederCalculator> with TickerProviderStateMixin {
  static const String _customBoxKey = "__CUSTOM__";
  static const String _moreBoxKey = "__MORE__";

  CalculatorStep _currentStep = CalculatorStep.pipe;
  bool _isInitialSetupComplete = false;

  List<Pipe> _pipes = [Pipe()];
  int _activePipeIndex = 0;

  late Map<String, double> _dynamicBoxVolumes;
  String? _selectedBoxSize;
  String? _selectedWireSize;
  String? _selectedInsulation;
  String? _selectedMudRing;

  int _deviceCount = 0;
  int _clampCount = 0;
  int _supportFittingCount = 0;

  String? _selectedAmbientTempKey;

  double _length = 0.0;
  double _voltage = 0.0;

  late AnimationController _borderAnimationController;
  late AnimationController _infoBarAnimationController;
  late Animation<double> _infoBarAnimation;

  // --- TESTING HOOKS ---
  Map<String, dynamic> get resultsForTesting => _calculateResults();
  void setSelectedBoxSizeForTesting(String? size) => setState(() => _selectedBoxSize = size);
  void setSelectedWireSizeForTesting(String? size) => setState(() => _selectedWireSize = size);
  void setSelectedInsulationForTesting(String? insulation) => setState(() => _selectedInsulation = insulation);
  void addWireForTesting(String type) {
    if (_selectedWireSize == null || _selectedInsulation == null) return;
    setState(() {
      if (type == 'Hot') {
        _activePipe.wires.add(Wire(size: _selectedWireSize!, insulation: _selectedInsulation!, isCurrentCarrying: true));
      } else if (type == 'Ground') {
        _activePipe.wires.add(Wire(size: _selectedWireSize!, insulation: _selectedInsulation!, isGround: true, isCurrentCarrying: false));
      }
    });
  }
  void setDeviceCountForTesting(int count) => setState(() => _deviceCount = count);
  void setClampCountForTesting(int count) => setState(() => _clampCount = count);
  void setSupportFittingCountForTesting(int count) => setState(() => _supportFittingCount = count);
  // ---------------------

  @override
  void initState() {
    super.initState();
    _dynamicBoxVolumes = Map.from(ConduitDB.boxVolumes);
    _borderAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true);
    _infoBarAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _infoBarAnimation = CurvedAnimation(parent: _infoBarAnimationController, curve: Curves.easeIn);
    _infoBarAnimationController.forward();
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _infoBarAnimationController.dispose();
    super.dispose();
  }

  Pipe get _activePipe => _pipes[_activePipeIndex];
  List<Wire> get _allWires => _pipes.expand((p) => p.wires).toList();

  void _addWire(String type, String size, String insulation) {
    setState(() {
      if (type == 'Hot') {
        _activePipe.wires.add(Wire(size: size, insulation: insulation, isCurrentCarrying: true));
      } else if (type == 'Neutral') {
        _showNeutralDialog(size, insulation);
      } else if (type == 'Ground') {
        _activePipe.wires.add(Wire(size: size, insulation: insulation, isGround: true, isCurrentCarrying: false));
      }
    });
  }

  void _removeLastWireOfType(String type) {
    setState(() {
      int indexToRemove = -1;
      if (type == 'Hot') {
        indexToRemove = _activePipe.wires.lastIndexWhere((w) => !w.isNeutral && !w.isGround);
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

  void _showNeutralDialog(String size, String insulation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C3030),
        title: const Text("Neutral Type?", style: TextStyle(color: kLight)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: const Text("Shared Neutral (MWBC)", style: TextStyle(color: kLight)),
            subtitle: const Text("Does NOT count for heat.", style: TextStyle(color: Colors.white70)),
            onTap: () {
              setState(() => _activePipe.wires.add(Wire(size: size, insulation: insulation, isNeutral: true, isCurrentCarrying: false)));
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text("Dedicated Neutral (2-Wire)", style: TextStyle(color: kLight)),
            subtitle: const Text("ADDS to heat calculation.", style: TextStyle(color: Colors.white70)),
            onTap: () {
              setState(() => _activePipe.wires.add(Wire(size: size, insulation: insulation, isNeutral: true, isCurrentCarrying: true)));
              Navigator.pop(ctx);
            },
          ),
        ]),
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

    final defaultResults = {
      "isReady": false, "conduitFillPercent": 0.0, "isConduitFillViolation": false,
      "boxFillPercent": 0.0, "isBoxFillViolation": false, "startingAmpacity": 0,
      "newAmpacity": 0.0, "finalBreakerSize": 0, "adjustmentFactor": 1.0,
      "tempCorrectionFactor": 1.0, "voltageDrop": 0.0, "voltageDropPercent": 0.0,
      "maxWires": 0, "maxBoxWires": 0, "groundWireSize": "N/A", ...boxSizing
    };

    if (_activePipe.size == null && allWires.isEmpty) {
      return {...defaultResults, ...boxSizing};
    }

    final double? maxArea = _activePipe.size != null ? ConduitDB.emtMaxFill[_activePipe.size!] : null;

    // --- Max Wires Calculation ---
    int maxWires = 0;
    // Only calculate max wires if all wires in the pipe are the same type
    final wireTypes = activePipeWires.map((w) => '${w.size}-${w.insulation}').toSet();
    if (wireTypes.length <= 1) { // Changed to <= 1 to handle empty pipe case
      final wireSize = activePipeWires.isNotEmpty ? activePipeWires.first.size : _selectedWireSize;
      final insulation = activePipeWires.isNotEmpty ? activePipeWires.first.insulation : _selectedInsulation;

      if (wireSize != null && insulation != null) {
        final double? wireArea = ConduitDB.wireAreas[wireSize]?[insulation];
        if (wireArea != null && maxArea != null && wireArea > 0) {
          maxWires = (maxArea / wireArea).floor();
        }
      }
    }

    // --- Box Calculation Variables ---
    double conductorVolume = allWires.fold(0.0, (sum, w) => sum + (ConduitDB.wireVolumes[w.size] ?? 0.0));
    double clampVolume = 0;
    double supportFittingVolume = 0;
    double deviceVolume = 0;
    double groundingVolume = 0;
    int maxBoxWires = 0;

    // Find largest conductors for allowances
    Wire? largestConductor = allWires.where((w) => !w.isGround).toList().fold(null, (largest, current) {
      if (largest == null) return current;
      final largestSize = int.tryParse(largest.size.replaceAll(" AWG", "")) ?? 0;
      final currentSize = int.tryParse(current.size.replaceAll(" AWG", "")) ?? 0;
      return currentSize < largestSize ? current : largest;
    });

    Wire? largestGround = allWires.where((w) => w.isGround).toList().fold(null, (largest, current) {
      if (largest == null) return current;
      final largestSize = int.tryParse(largest.size.replaceAll(" AWG", "")) ?? 0;
      final currentSize = int.tryParse(current.size.replaceAll(" AWG", "")) ?? 0;
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
      groundingVolume = ConduitDB.wireVolumes[largestGround.size]!;
    }

    // Calculate Max Box Wires
    if (_selectedBoxSize != null && _selectedWireSize != null) {
      final double? boxVolume = _dynamicBoxVolumes[_selectedBoxSize];
      final double? wireVolume = ConduitDB.wireVolumes[_selectedWireSize];

      if (boxVolume != null && wireVolume != null && wireVolume > 0) {
        double totalAvailableVolume = boxVolume;
        if (_selectedMudRing != null) {
          totalAvailableVolume += ConduitDB.mudRingVolumes[_selectedMudRing!] ?? 0.0;
        }
        final double availableBoxVolumeForWires = totalAvailableVolume - (clampVolume + supportFittingVolume + deviceVolume + groundingVolume);
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
         startingAmpacity = ConduitDB.copperAmpacities[_selectedWireSize!]?["90C"] ?? 0;
       }
      return {
        ...defaultResults, "isReady": true, "maxWires": maxWires, "maxBoxWires": maxBoxWires, "startingAmpacity": startingAmpacity, ...boxSizing
      };
    }

    double totalConduitArea = activePipeWires.fold(0.0, (sum, w) => sum + (ConduitDB.wireAreas[w.size]?[w.insulation] ?? 0.0));
    final double conduitFillPercent = totalConduitArea.isFinite && maxArea != null && maxArea > 0 ? (totalConduitArea / maxArea) * 100 : 0.0;
    final bool isConduitFillViolation = maxArea != null && totalConduitArea > maxArea;

    double boxFillPercent = 0.0;
    bool isBoxFillViolation = false;
    double totalBoxVolume = 0;
    double maxBoxVolume = 0;

    if (_selectedBoxSize != null) {
      maxBoxVolume = _dynamicBoxVolumes[_selectedBoxSize]!;
      if (_selectedMudRing != null) {
        maxBoxVolume += ConduitDB.mudRingVolumes[_selectedMudRing!] ?? 0.0;
      }
      totalBoxVolume = conductorVolume + clampVolume + supportFittingVolume + deviceVolume + groundingVolume;
      boxFillPercent = totalBoxVolume.isFinite && maxBoxVolume > 0 ? (totalBoxVolume / maxBoxVolume) * 100 : 0.0;
      isBoxFillViolation = totalBoxVolume > maxBoxVolume;
    }

    final int cccCount = activePipeWires.where((w) => w.isCurrentCarrying).length;
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

    final tempCorrectionFactor = _selectedAmbientTempKey != null ? ConduitDB.temperatureCorrectionFactors["90C"]![_selectedAmbientTempKey!] ?? 1.0 : 1.0;

    Wire? smallestCCCWire = activePipeWires.where((w) => w.isCurrentCarrying).toList().fold(null, (smallest, current) {
      if (smallest == null) return current;
      final smallestSize = int.tryParse(smallest.size.replaceAll(" AWG", "")) ?? 0;
      final currentSize = int.tryParse(current.size.replaceAll(" AWG", "")) ?? 0;
      return currentSize > smallestSize ? current : smallest;
    });

    int startingAmpacity = 0;
    if (smallestCCCWire != null) {
      startingAmpacity = ConduitDB.copperAmpacities[smallestCCCWire.size]?["90C"] ?? 0;
    } else if (_selectedWireSize != null) {
      startingAmpacity = ConduitDB.copperAmpacities[_selectedWireSize!]?["90C"] ?? 0;
    }

    if (smallestCCCWire == null) {
      return {
        ...defaultResults, "isReady": true, "conduitFillPercent": conduitFillPercent,
        "isConduitFillViolation": isConduitFillViolation, "boxFillPercent": boxFillPercent,
        "isBoxFillViolation": isBoxFillViolation, "maxWires": maxWires, "maxBoxWires": maxBoxWires,
        "startingAmpacity": startingAmpacity, ...boxSizing,
      };
    }
    
    final double newAmpacity = startingAmpacity * adjustmentFactor * tempCorrectionFactor;
    final int capAmps75 = ConduitDB.copperAmpacities[smallestCCCWire.size]?["75C"] ?? 0;
    final double finalAmps = min(newAmpacity, capAmps75.toDouble());

    int overcurrentLimit = 1000;
    if (smallestCCCWire.size == "14 AWG") {
      overcurrentLimit = 15;
    } else if (smallestCCCWire.size == "12 AWG") {
      overcurrentLimit = 20;
    } else if (smallestCCCWire.size == "10 AWG") {
      overcurrentLimit = 30;
    }

    int finalBreakerSize = ConduitDB.standardBreakerSizes.lastWhere((s) => s <= finalAmps, orElse: () => 0);
    finalBreakerSize = min(overcurrentLimit, finalBreakerSize);

    double voltageDrop = 0.0;
    double voltageDropPercent = 0.0;
    if (_length > 0 && _voltage > 0 && finalBreakerSize > 0) {
      final double resistance = ConduitDB.wireResistance[smallestCCCWire.size] ?? 0.0;
      voltageDrop = (2 * resistance * _length * finalBreakerSize) / 1000;
      voltageDropPercent = (voltageDrop / _voltage) * 100;
    }

    final String groundWireSize = _getGroundWireSize(finalBreakerSize);

    return {
      "isReady": true, "conduitFillPercent": conduitFillPercent, "isConduitFillViolation": isConduitFillViolation,
      "boxFillPercent": boxFillPercent, "isBoxFillViolation": isBoxFillViolation,
      "startingAmpacity": startingAmpacity, "newAmpacity": newAmpacity,
      "finalBreakerSize": finalBreakerSize, "adjustmentFactor": adjustmentFactor,
      "tempCorrectionFactor": tempCorrectionFactor, "voltageDrop": voltageDrop,
      "voltageDropPercent": voltageDropPercent, "maxWires": maxWires, "maxBoxWires": maxBoxWires,
      "groundWireSize": groundWireSize, ...boxSizing,
      "conductorVolume": conductorVolume, "clampVolume": clampVolume, "supportFittingVolume": supportFittingVolume,
      "deviceVolume": deviceVolume, "groundingVolume": groundingVolume, "totalBoxVolume": totalBoxVolume, "maxBoxVolume": maxBoxVolume,
    };
  }

  Map<String, double> _calculateBoxSizing() {
    double largestStraight = 0;
    double largestAngle = 0;

    for (final pipe in _pipes) {
      if (pipe.size != null) {
        final double sizeInInches = ConduitDB.tradeSizesInches[pipe.size!] ?? 0.0;
        if (pipe.pullType == PullType.straight && sizeInInches > largestStraight) {
          largestStraight = sizeInInches;
        }
        if (pipe.pullType == PullType.angle && sizeInInches > largestAngle) {
          largestAngle = sizeInInches;
        }
      }
    }
    return { "minStraight": largestStraight * 8, "minAngle": largestAngle * 6 };
  }

  void _updateStep(CalculatorStep newStep) {
    if (_isInitialSetupComplete && newStep != CalculatorStep.free) {
      // Don't revert to a previous step if setup is complete, unless specifically going to free
      return;
    }
    setState(() {
      _currentStep = newStep;
      _infoBarAnimationController.reset();
      _infoBarAnimationController.forward();
    });
  }

  void _addPipe() {
    setState(() {
      _pipes.add(Pipe(size: _activePipe.size));
      _activePipeIndex = _pipes.length - 1;
    });
  }

  void _setActivePipe(int index) {
    if (index == _activePipeIndex) return;
    setState(() => _activePipeIndex = index);
  }

  void _toggleBox() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) => _BoxUIDetailView(
          results: _calculateResults(),
          deviceCount: _deviceCount,
          clampCount: _clampCount,
          supportFittingCount: _supportFittingCount,
          selectedMudRing: _selectedMudRing,
          pipes: _pipes,
          selectedBoxSize: _selectedBoxSize,
          allWires: _allWires,
          onDeviceCountChanged: (c) => setState(() => _deviceCount = c),
          onClampCountChanged: (c) => setState(() => _clampCount = c),
          onSupportFittingCountChanged: (c) => setState(() => _supportFittingCount = c),
          onMudRingChanged: (s) => setState(() => _selectedMudRing = s),
          onPullTypeChanged: (pipeId, pullType) {
            setState(() {
              final pipeToUpdate = _pipes.firstWhere((p) => p.id == pipeId);
              pipeToUpdate.pullType = pullType;
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // After the box detail screen is closed, move to the final step.
    if (_currentStep == CalculatorStep.boxSetup) {
      setState(() {
        _currentStep = CalculatorStep.free;
        _infoBarAnimationController.reset();
        _infoBarAnimationController.forward();
      });
    }
  }

  void _togglePipeUI() {
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
      _currentStep = CalculatorStep.pipe;
      _isInitialSetupComplete = false;
      _deviceCount = 0;
      _clampCount = 0;
      _supportFittingCount = 0;
      _selectedAmbientTempKey = null;

      _length = 0.0;
      _voltage = 0.0;
    });
  }

  void _showVoltDropKeypad(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: VoltDropKeypad(
          initialValue: type == 'Length' ? _length.toString() : _voltage.toString(),
          onConfirm: (value) {
            setState(() {
              if (type == 'Length') {
                _length = value;
              } else {
                _voltage = value;
              }
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showCustomBoxDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: VoltDropKeypad(
          initialValue: "0.0",
          onConfirm: (value) {
            if (value > 0) {
              setState(() {
                final customKey = "Custom (${value.toStringAsFixed(1)} in³)";
                _dynamicBoxVolumes[customKey] = value;
                _selectedBoxSize = customKey;
                if (!_isInitialSetupComplete) _updateStep(CalculatorStep.wire);
              });
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showMoreBoxesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final otherBoxes = ConduitDB.boxVolumes.keys.where((s) => !ConduitDB.popularBoxSizes.contains(s)).toList();
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
                      if (!_isInitialSetupComplete) _updateStep(CalculatorStep.wire);
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


  @override
  Widget build(BuildContext context) {
    final results = _calculateResults();

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        title: const Text('Pipe and Box Fill', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: PulsingGlowBorder(
        animationController: _borderAnimationController,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        endColor: kSilver,
        child: Container(
          margin: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(color: kBlack, borderRadius: BorderRadius.circular(6)),
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
                      _buildVisualsColumn(results),
                      _buildDeratingData(results),
                    ],
                  ),
                ),
                _buildWireSteppers(),
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

    // Create the list of dropdown items dynamically
    List<DropdownMenuItem<String>> boxItems = ConduitDB.popularBoxSizes.map((s) {
      return DropdownMenuItem(value: s, child: Text(s));
    }).toList();

    // Add the special "Enter Custom" item
    boxItems.add(
      const DropdownMenuItem(
        value: _customBoxKey,
        child: Text("Enter Custom Size...", style: TextStyle(fontStyle: FontStyle.italic, color: kSilver)),
      ),
    );

    boxItems.add(
      const DropdownMenuItem(
        value: _moreBoxKey,
        child: Text("More Boxes...", style: TextStyle(fontStyle: FontStyle.italic, color: kSilver)),
      ),
    );

    return Column(
      children: [
        Row(children: [
          Expanded(child: _StyledDropdown(
            value: _activePipe.size,
            hint: "Pipe Size",
            items: ConduitDB.emtMaxFill.keys.map((s) => DropdownMenuItem(value: s, child: Text("$s\" EMT"))).toList(),
            onChanged: (v) => setState(() {
              _activePipe.size = v;
              if (!_isInitialSetupComplete) _updateStep(CalculatorStep.box);
            }),
            isActive: _currentStep == CalculatorStep.pipe,
            isEnabled: true,
          )),
          const SizedBox(width: spacing),
          Expanded(child: _StyledDropdown(
            value: _selectedBoxSize,
            hint: "Box Size",
            items: boxItems,
            onChanged: (v) {
              if (v == _customBoxKey) {
                _showCustomBoxDialog();
              } else if (v == _moreBoxKey) {
                _showMoreBoxesDialog();
              }
              else {
                setState(() {
                  _selectedBoxSize = v;
                  if (!_isInitialSetupComplete) _updateStep(CalculatorStep.wire);
                });
              }
            },
            isActive: _currentStep == CalculatorStep.box,
            isEnabled: _currentStep != CalculatorStep.pipe || _isInitialSetupComplete,
          )),
        ]),
        const SizedBox(height: spacing),
        Row(children: [
          Expanded(child: _StyledDropdown(
            value: _selectedWireSize,
            hint: "Wire Size",
            items: ConduitDB.copperAmpacities.keys.map((s) => DropdownMenuItem(value:s, child: Text(s))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedWireSize = v;
                if (!_isInitialSetupComplete) _updateStep(CalculatorStep.insulation);
              });
            },
            isActive: _currentStep == CalculatorStep.wire,
            isEnabled: _currentStep != CalculatorStep.pipe && _currentStep != CalculatorStep.box || _isInitialSetupComplete,
          )),
          const SizedBox(width: spacing),
          Expanded(child: _StyledDropdown(
            value: _selectedInsulation,
            hint: "Insulation",
            items: (_selectedWireSize == null ? <String>[] : ConduitDB.wireAreas[_selectedWireSize]!.keys).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedInsulation = v;
                if (!_isInitialSetupComplete) _updateStep(CalculatorStep.ambientTemp);
              });
            },
            isActive: _currentStep == CalculatorStep.insulation,
            isEnabled: _selectedWireSize != null,
          )),
        ]),
      ],
    );
  }


  Widget _buildWireSteppers() {
    const spacing = 4.0;
    final hotCount = _activePipe.wires.where((w) => !w.isNeutral && !w.isGround).length;
    final neutralCount = _activePipe.wires.where((w) => w.isNeutral).length;
    final groundCount = _activePipe.wires.where((w) => w.isGround).length;
    final bool canAdd = _selectedWireSize != null && _selectedInsulation != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: _WireStepper(label: 'H', count: hotCount, color: kRed, onAdd: canAdd ? () => _addWire('Hot', _selectedWireSize!, _selectedInsulation!) : null, onRemove: () => _removeLastWireOfType('Hot'))),
          const SizedBox(width: spacing),
          Expanded(child: _WireStepper(label: 'N', count: neutralCount, color: Colors.white, onAdd: canAdd ? () => _addWire('Neutral', _selectedWireSize!, _selectedInsulation!) : null, onRemove: () => _removeLastWireOfType('Neutral'))),
          const SizedBox(width: spacing),
          Expanded(child: _WireStepper(label: 'G', count: groundCount, color: Colors.green, onAdd: canAdd ? () => _addWire('Ground', _selectedWireSize!, _selectedInsulation!) : null, onRemove: () => _removeLastWireOfType('Ground'))),
        ],
      ),
    );
  }

  Widget _buildVisualsColumn(Map<String, dynamic> results) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPipeVisual(results),
          _buildBoxVisual(results),
        ],
      ),
    );
  }

  Widget _buildPipeVisual(Map<String, dynamic> results) {
    final bool isReady = results['isReady'] ?? false;
    final double conduitFill = results['conduitFillPercent'] ?? 0.0;
    final bool isConduitViolation = results['isConduitFillViolation'] ?? false;
    final int maxWires = results['maxWires'] ?? 0;
    final conduitStatusColor = !isReady || _activePipe.size == null ? Colors.grey : (isConduitViolation ? kRed : Colors.green);
    final wireTypes = _activePipe.wires.map((w) => '${w.size}-${w.insulation}').toSet();
    final bool showMaxWires = wireTypes.length <= 1;

    return SizedBox(
      width: 170,
      height: 170,
      child: GestureDetector(
        onTap: _togglePipeUI,
        child: Hero(
          tag: 'pipe-hero',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[800], border: Border.all(color: conduitStatusColor, width: 8)),
              child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Pipe ${_activePipeIndex + 1}", style: const TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      !isReady || _activePipe.size == null ? "-- Wires\n--% Fill" : "${_activePipe.wires.length} Wires\n${conduitFill.toStringAsFixed(1)}% Fill",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700, color: isConduitViolation ? kRed : kLight, fontSize: 18),
                    ),
                    if (isReady && maxWires > 0 && showMaxWires) ...[
                      const SizedBox(height: 8),
                      Text("Max Wires: $maxWires", style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
                    ]
                  ])),
            ),
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
    final boxStatusColor = _currentStep == CalculatorStep.boxSetup
        ? kRed
        : (!isReady || _selectedBoxSize == null ? Colors.grey : (isBoxViolation ? kRed : (isBoxWarning ? Colors.yellow : Colors.green)));
    final allWires = _allWires;
    final wireTypes = allWires.map((w) => '${w.size}-${w.insulation}').toSet();
    final bool showMaxBoxWires = wireTypes.length <= 1 || allWires.isEmpty;


    return GestureDetector(
      onTap: _toggleBox,
      child: Hero(
        tag: 'box-hero',
        child: Container(
          width: 170, height: 170,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.grey[800],
              border: Border.all(color: boxStatusColor, width: 8.0)
          ),
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Box", style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              !isReady || _selectedBoxSize == null ? "-- Wires\n--% Fill" : "${allWires.length} Wires\n${boxFill.toStringAsFixed(1)}% Fill",
              textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: isBoxViolation ? kRed : kLight, fontSize: 18),
            ),
            if (isReady && maxBoxWires > 0 && showMaxBoxWires) ...[
              const SizedBox(height: 8),
              Text("Max Wires: $maxBoxWires", style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
            ]
          ])),
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    String text;
    switch (_currentStep) {
      case CalculatorStep.pipe: text = "Select Pipe Size"; break;
      case CalculatorStep.box: text = "Select Box Size"; break;
      case CalculatorStep.wire: text = "Select Wire Size"; break;
      case CalculatorStep.insulation: text = "Select Insulation Type"; break;
      case CalculatorStep.ambientTemp: text = "Select Ambient Temperature"; break;
      case CalculatorStep.boxSetup: text = "Next: Tap the Box to add devices or fittings."; break;
      case CalculatorStep.free: text = "Add Wires to Calculate Derating"; break;
    }

    return FadeTransition(
      opacity: _infoBarAnimation,
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFF2C3030), borderRadius: BorderRadius.circular(6), border: Border.all(color: kSilver.withAlpha(180))),
        child: Center(child: Text(text, style: const TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))),
      ),
    );
  }

  Widget _buildDeratingData(Map<String, dynamic> results) {
    final bool isReady = results['isReady'] ?? false;
    final adjustmentFactor = (results['adjustmentFactor'] as double? ?? 1.0);
    final tempCorrectionFactor = (results['tempCorrectionFactor'] as double? ?? 1.0);
    final voltageDrop = results['voltageDrop'] as double? ?? 0.0;
    final voltageDropPercent = results['voltageDropPercent'] as double? ?? 0.0;
    final bool isVoltageDropViolation = voltageDropPercent > 3.0;
    final int finalBreakerSize = results['finalBreakerSize'] ?? 0;
    final String groundWireSize = results['groundWireSize'] ?? "N/A";
    final int startingAmpacity = results['startingAmpacity'] ?? 0;
    final double newAmpacity = results['newAmpacity'] as double? ?? 0.0;
    final bool hasCalculationRun = _allWires.where((w) => w.isCurrentCarrying).isNotEmpty;

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
                  Text("Derating", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _StyledDropdown(
                    value: _selectedAmbientTempKey,
                    hint: "Ambient Temp °F",
                    items: ConduitDB.temperatureCorrectionFactors["90C"]!.keys.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedAmbientTempKey = v;
                        if (!_isInitialSetupComplete) {
                          _updateStep(CalculatorStep.boxSetup);
                          _isInitialSetupComplete = true;
                        }
                      });
                    },
                    isActive: _currentStep == CalculatorStep.ambientTemp,
                    isEnabled: _currentStep == CalculatorStep.ambientTemp || _currentStep == CalculatorStep.free || _isInitialSetupComplete,
                  ),
                  const SizedBox(height: 16),
                  Text("Starting Ampacity: ${isReady ? startingAmpacity : '--'}A", style: const TextStyle(color: kLight, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("Temp Factor: ${isReady ? (tempCorrectionFactor * 100).toStringAsFixed(0) : '--'}%", style: const TextStyle(color: kLight, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("Bundle Factor: ${isReady ? (adjustmentFactor * 100).toStringAsFixed(0) : '--'}%", style: const TextStyle(color: kLight, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    "New Ampacity: ${isReady ? newAmpacity.toStringAsFixed(1) : '--'}A",
                    style: TextStyle(
                      color: hasCalculationRun && newAmpacity < 15.0 ? kRed : kLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Final Breaker Size:\n${isReady ? finalBreakerSize : '--'}A",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: hasCalculationRun ? (finalBreakerSize == 0 ? kRed : Colors.green) : kLight,
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
                  Text("Voltage Drop", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    "${voltageDrop.toStringAsFixed(1)}V (${voltageDropPercent.toStringAsFixed(1)}%)",
                    style: TextStyle(
                      color: isVoltageDropViolation ? kRed : Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildTappableBox("Length (ft)", "${_length.toStringAsFixed(0)}'", () => _showVoltDropKeypad('Length')),
                  const SizedBox(height: 4),
                  _buildTappableBox("Voltage", "${_voltage.toStringAsFixed(0)}V", () => _showVoltDropKeypad('Voltage')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _StyledButton(onPressed: _reset, label: "Reset Calculator"),
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
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(value, style: const TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w700)),
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
    bool wiresChanged = widget.pipes.length > _localActivePipeIndex && oldWidget.pipes.length > _localActivePipeIndex && widget.pipes[_localActivePipeIndex].wires.length != oldWidget.pipes[_localActivePipeIndex].wires.length;
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
        final sizeA = int.tryParse(a.split(" ")[0].replaceAll("AWG", "").trim()) ?? 0;
        final sizeB = int.tryParse(b.split(" ")[0].replaceAll("AWG", "").trim()) ?? 0;
        return sizeB.compareTo(sizeA);
      });
      final defaultKey = sortedKeys.first;
      if (_selectedWireSummaryKey == null || !summaryMap.containsKey(_selectedWireSummaryKey)) {
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

    final int cccCount = pipe.wires.where((w) => w.isCurrentCarrying).length;
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

    final tempCorrectionFactor = widget.results['tempCorrectionFactor'] as double? ?? 1.0;
    final deratingSummary = <String, Map<String, dynamic>>{};

    for (final entry in wireGroups.entries) {
      final key = entry.key;
      final wireGroup = entry.value;
      final firstWire = wireGroup.first;
      final count = wireGroup.length;
      int finalBreakerSize = 0;

      if (firstWire.isCurrentCarrying) {
        final startingAmpacity = ConduitDB.copperAmpacities[firstWire.size]?["90C"] ?? 0;
        final newAmpacity = startingAmpacity * adjustmentFactor * tempCorrectionFactor;
        final capAmps75 = ConduitDB.copperAmpacities[firstWire.size]?["75C"] ?? 0;
        final finalAmps = min(newAmpacity, capAmps75.toDouble());
        int overcurrentLimit = 1000;
        if (firstWire.size == "14 AWG") {
          overcurrentLimit = 15;
        } else if (firstWire.size == "12 AWG") {
          overcurrentLimit = 20;
        } else if (firstWire.size == "10 AWG") {
          overcurrentLimit = 30;
        }
        finalBreakerSize = ConduitDB.standardBreakerSizes.lastWhere((s) => s <= finalAmps, orElse: () => 0);
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
    final double maxArea = ConduitDB.emtMaxFill[pipe.size!] ?? 1.0;
    final double totalArea = pipe.wires.fold(0.0, (sum, w) => sum + (ConduitDB.wireAreas[w.size]?[w.insulation] ?? 0.0));
    return totalArea.isFinite && maxArea > 0 ? (totalArea / maxArea) * 100 : 0.0;
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
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: kBlack),
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
                  _buildInfoSection("Conduit Fill", "${fillPercent.toStringAsFixed(1)}%"),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 32.0),
          child: SizedBox(
            width: 200,
            child: _StyledButton(onPressed: () => Navigator.of(context).pop(), label: "Done"),
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
      if (summaryData == null) return _buildInfoSection("Wire Summary", "Empty");
      final count = summaryData['count'];
      final wire = summaryData['wire'] as Wire;
      String summaryText = "($count) #${wire.size.replaceAll(" AWG", "")} ${wire.insulation}";
      return _buildInfoSection("Wire Summary", summaryText);
    }

    // If multiple wire types, build the dropdown.
    return Column(
      children: [
        const Text("Wire Summary", style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 30)),
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
              style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
              dropdownColor: const Color(0xFF2C3030),
              items: summaryMap.entries.map((entry) {
                final key = entry.key;
                final summaryData = entry.value;
                final count = summaryData['count'];
                final wire = summaryData['wire'] as Wire;
                final breaker = summaryData['finalBreakerSize'];
                final shortInsulation = wire.insulation.length > 4 ? wire.insulation.substring(0, 4) : wire.insulation;
                String summaryText = "($count) #${wire.size.replaceAll(" AWG", "")} $shortInsulation";
                if (breaker > 0) {
                  summaryText += " -> ${breaker}A Breaker";
                }
                return DropdownMenuItem(
                  value: key,
                  child: Center(child: Text(summaryText, textAlign: TextAlign.center,)),
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
      width: MediaQuery.of(context).size.width * 0.6,
      child: const Divider(color: kSilver, height: 1),
    );
  }

  Widget _buildPipeInfoSection() {
    final String pipeSize = _activePipe.size != null ? '${_activePipe.size}"' : "N/A";
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
        style: const TextStyle(color: kLight, fontSize: 30, fontWeight: FontWeight.bold),
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
        Text(title, style: const TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 30)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 18), textAlign: TextAlign.center),
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
  final List<Pipe> pipes;
  final String? selectedBoxSize;
  final List<Wire> allWires;
  final ValueChanged<int> onDeviceCountChanged;
  final ValueChanged<int> onClampCountChanged;
  final ValueChanged<int> onSupportFittingCountChanged;
  final ValueChanged<String?> onMudRingChanged;
  final Function(String pipeId, PullType pullType) onPullTypeChanged;

  const _BoxUIDetailView({
    required this.results,
    required this.deviceCount,
    required this.clampCount,
    required this.supportFittingCount,
    required this.selectedMudRing,
    required this.pipes,
    this.selectedBoxSize,
    required this.allWires,
    required this.onDeviceCountChanged,
    required this.onClampCountChanged,
    required this.onSupportFittingCountChanged,
    required this.onMudRingChanged,
    required this.onPullTypeChanged,
  });

  @override
  State<_BoxUIDetailView> createState() => _BoxUIDetailViewState();
}

class _BoxUIDetailViewState extends State<_BoxUIDetailView> {
  late int _deviceCount;
  late int _clampCount;
  late int _supportFittingCount;
  String? _selectedMudRing;

  @override
  void initState() {
    super.initState();
    _deviceCount = widget.deviceCount;
    _clampCount = widget.clampCount;
    _supportFittingCount = widget.supportFittingCount;
    _selectedMudRing = widget.selectedMudRing;
  }

  @override
  Widget build(BuildContext context) {
    // Recalculate results locally to ensure the UI is responsive.
    final localResults = Map<String, dynamic>.from(widget.results);
    final conductorVolume = localResults['conductorVolume'] ?? 0.0;
    final groundingVolume = localResults['groundingVolume'] ?? 0.0;
    
    double maxBoxVolume = localResults['maxBoxVolume'] ?? 0.0;
    if (_selectedMudRing != null) {
      maxBoxVolume += ConduitDB.mudRingVolumes[_selectedMudRing!] ?? 0.0;
    }

    Wire? largestConductor = widget.allWires.where((w) => !w.isGround).toList().fold(null, (largest, current) {
      if (largest == null) return current;
      final largestSize = int.tryParse(largest.size.replaceAll(" AWG", "")) ?? 0;
      final currentSize = int.tryParse(current.size.replaceAll(" AWG", "")) ?? 0;
      return currentSize < largestSize ? current : largest;
    });

    double allowance = 0;
    if (largestConductor != null) {
      allowance = ConduitDB.wireVolumes[largestConductor.size] ?? 0.0;
    }

    final clampVolume = _clampCount * allowance;
    final supportFittingVolume = _supportFittingCount * allowance;
    final deviceVolume = _deviceCount * 2 * allowance;
    final totalBoxVolume = conductorVolume + groundingVolume + clampVolume + supportFittingVolume + deviceVolume;
    final boxFillPercent = totalBoxVolume.isFinite && maxBoxVolume > 0 ? (totalBoxVolume / maxBoxVolume) * 100 : 0.0;
    final isBoxFillViolation = totalBoxVolume > maxBoxVolume;

    // Update the map for the detail view
    localResults['clampVolume'] = clampVolume;
    localResults['supportFittingVolume'] = supportFittingVolume;
    localResults['deviceVolume'] = deviceVolume;
    localResults['totalBoxVolume'] = totalBoxVolume;
    localResults['boxFillPercent'] = boxFillPercent;
    localResults['isBoxFillViolation'] = isBoxFillViolation;


    return Scaffold(
      backgroundColor: const Color(0xD8000000),
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
                      const Text("Box Design", style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 24)),
                      const Divider(color: Colors.white24, height: 20),
                      if (widget.selectedBoxSize != null) ...[
                        _buildBoxFillDetails(localResults),
                        const Divider(color: Colors.white24, height: 20),
                      ],
                      _buildAllowanceStepper("Devices (switches/outlets)", _deviceCount, (c) {
                        setState(() => _deviceCount = c);
                        widget.onDeviceCountChanged(c);
                      }),
                      _buildAllowanceStepper("Internal Cable Clamps", _clampCount, (c) {
                        setState(() => _clampCount = c);
                        widget.onClampCountChanged(c);
                      }, max: 1),
                      _buildAllowanceStepper("Support Fittings (studs/hickeys)", _supportFittingCount, (c) {
                        setState(() => _supportFittingCount = c);
                        widget.onSupportFittingCountChanged(c);
                      }),
                      _buildMudRingSelector(),
                      const Divider(color: Colors.white24, height: 20),
                      const Text("Junction Box Sizing (NEC 314.28)", style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text("Min. Length for Straight Pulls: ${widget.results['minStraight']?.toStringAsFixed(1) ?? '0.0'}\"", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      Text("Min. Length for Angle Pulls: ${widget.results['minAngle']?.toStringAsFixed(1) ?? '0.0'}\"", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.pipes.length,
                        itemBuilder: (context, index) {
                          final pipe = widget.pipes[index];
                          return _buildPullTypeSelector(pipe, index);
                        },
                      ),
                      const SizedBox(height: 24),
                      Center(child: _StyledButton(onPressed: () => Navigator.of(context).pop(), label: "Done")),
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

  Widget _buildPullTypeSelector(Pipe pipe, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Pipe ${index + 1} (${pipe.size ?? 'N/A'})", style: const TextStyle(color: kLight, fontSize: 16)),
          ToggleButtons(
            isSelected: [pipe.pullType == PullType.straight, pipe.pullType == PullType.angle],
            onPressed: (int newIndex) {
              setState(() {
                widget.onPullTypeChanged(pipe.id, newIndex == 0 ? PullType.straight : PullType.angle);
              });
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: kLight,
            color: Colors.white70,
            fillColor: kRed,
            selectedBorderColor: kRed,
            borderColor: kSilver,
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("Straight")),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("Angle")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllowanceStepper(String title, int count, ValueChanged<int> onChanged, {int max = 100}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: kLight, fontSize: 16))),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF2C3030), borderRadius: BorderRadius.circular(6), border: Border.all(color: kSilver.withAlpha(128))),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.remove, color: kLight), onPressed: count > 0 ? () => onChanged(count - 1) : null),
                Text('$count', style: const TextStyle(color: kLight, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add, color: kLight), onPressed: count < max ? () => onChanged(count + 1) : null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMudRingSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text("Mud Ring / Plaster Ring", style: TextStyle(color: kLight, fontSize: 16)),
          ),
          SizedBox(
            width: 150,
            child: _StyledDropdown(
              value: _selectedMudRing,
              hint: "Select Ring",
              items: ConduitDB.mudRingVolumes.keys.map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (v) {
                setState(() => _selectedMudRing = v);
                widget.onMudRingChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxFillDetails(Map<String, dynamic> results) {
    final totalVolume = results['totalBoxVolume'] as double? ?? 0.0;
    final maxVolume = results['maxBoxVolume'] as double? ?? 0.0;
    final isViolation = results['isBoxFillViolation'] as bool? ?? false;
    final conductorVolume = results['conductorVolume'] as double? ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Box Fill: ${widget.selectedBoxSize}", style: const TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              "${totalVolume.toStringAsFixed(2)} / ${maxVolume.toStringAsFixed(2)} in³",
              style: TextStyle(color: isViolation ? kRed : Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDetailRow("Conductors", conductorVolume),
        if (_clampCount > 0) _buildDetailRow("Clamps ($_clampCount)", results['clampVolume']),
        if (_supportFittingCount > 0) _buildDetailRow("Support Fittings ($_supportFittingCount)", results['supportFittingCount']),
        if (_deviceCount > 0) _buildDetailRow("Devices ($_deviceCount)", results['deviceVolume']),
        if ((results['groundingVolume'] as double? ?? 0.0) > 0) _buildDetailRow("Grounding", results['groundingVolume']),
      ],
    );
  }

  Widget _buildDetailRow(String label, double? value) {
    if (value == null || value == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text("${value.toStringAsFixed(2)} in³", style: const TextStyle(color: kLight, fontSize: 15, fontWeight: FontWeight.w500)),
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
  final Color endColor;
  final BorderRadius? borderRadius;

  const PulsingGlowBorder({
    super.key,
    required this.animationController,
    required this.shape,
    required this.child,
    this.startColor = kRed,
    this.endColor = kSilver,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        final border = Border.all(
          width: 2.0,
          color: Colors.transparent, // Start with a transparent border color
        );

        final decoration = BoxDecoration(
          shape: shape,
          borderRadius: borderRadius,
          border: border,
          gradient: SweepGradient(
            colors: [
              startColor,
              endColor,
              startColor,
            ],
            stops: const [0.0, 0.5, 1.0],
            transform: GradientRotation(animationController.value * 2 * pi),
          ),
        );

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

  const _WireStepper({ required this.label, required this.count, required this.color, this.onAdd, this.onRemove });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: const Color(0xFF2C3030), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
      child: Stack(
        children: [
          Positioned(
            top: 1, left: 4,
            child: Text(label, style: TextStyle(color: color.withAlpha(128), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.remove, color: kLight), onPressed: count > 0 ? onRemove : null),
              Text('$count', style: const TextStyle(color: kLight, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add, color: kLight), onPressed: onAdd),
            ],
          ),
        ],
      ),
    );
  }
}

class _StyledButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _StyledButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kRed, Color(0xFFD43D37)]),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kSilver.withAlpha(128), width: 1.1),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: kLight, fontSize: 18, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final bool isActive;
  final bool isEnabled;

  const _StyledDropdown({ this.value, required this.hint, required this.items, required this.onChanged, this.isActive = false, this.isEnabled = true });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled ? (isActive ? [kRed, const Color(0xFFD43D37)] : [const Color(0xFF4E4E52), const Color(0xFF2C3030)]) : [Colors.grey[800]!, Colors.grey[850]!],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kSilver.withAlpha(128), width: 1.1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: isEnabled ? Colors.white70 : Colors.grey[600])),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: isEnabled ? kLight : Colors.grey[600]),
          style: const TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w700),
          dropdownColor: const Color(0xFF2C3030),
          items: items,
          onChanged: isEnabled ? onChanged : null,
        ),
      ),
    );
  }
}
