import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'dart:math' as math;
import 'dart:async'; // Added for Timer
import 'package:pipe_and_wire_clean/keypad_volt_drop.dart';
import 'package:flutter/services.dart';
import 'package:pipe_and_wire_clean/code_sections/junction_box_sizing_code_screen.dart';
import 'package:pipe_and_wire_clean/code_sections/neutral_ccc_code_screen.dart';
import 'package:pipe_and_wire_clean/code_sections/ampacity_derating_code_screen.dart';
import 'package:pipe_and_wire_clean/code_sections/box_fill_basics_code_screen.dart';
import 'package:pipe_and_wire_clean/code_sections/conduit_fill_code_screen.dart';
import 'package:pipe_and_wire_clean/code_sections/voltage_drop_code_screen.dart';
import 'package:pipe_and_wire_clean/wire_data.dart';
import 'main_menu_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const PipeAndBoxFill(),
    ),
  );
}


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

enum VoltDropField { none, length, voltage, load }

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

class PipeAndBoxFill extends StatefulWidget {
  const PipeAndBoxFill({super.key});

  @override
  State<PipeAndBoxFill> createState() =>
      _PipeAndBoxFillState();
}

class _PipeAndBoxFillState extends State<PipeAndBoxFill>
    with TickerProviderStateMixin {
  static const String _customBoxKey = "__CUSTOM__";
  static const String _moreBoxKey = "__MORE__";
  static const String _moreWiresKey = "__MORE_WIRES__"; // Added for wire selection

  CalculatorStep _currentStep = CalculatorStep.pipe;
  bool _isInitialSetupComplete = false;
  bool _hasInteractedWithPipeOrBoxInFreeState = false; // NEW: Controls glowing behavior after interaction

  bool _hasViewedInfo = false;

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
  int _terminalBlockCount = 0; // NEW: For Terminal Blocks
  String? _selectedAmbientTempKey;
  bool _hasShownNeutralDialog = false;
  bool _isNeutralCCC = false;
  bool _showPullThroughBoxInfoBar = false;

  double _length = 0.0;
  double _voltage = 120.0;
  double _loadAmps = 0.0;
  bool _isThreePhase = false;
  String? _voltageDropInfoMessage;
  Timer? _voltageDropInfoTimer;
  
  final FixedExtentScrollController _voltageScrollController = FixedExtentScrollController();
  final FixedExtentScrollController _lengthScrollController = FixedExtentScrollController();
  final FixedExtentScrollController _loadScrollController = FixedExtentScrollController();

  late AnimationController _borderAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _infoBarAnimationController;
  late AnimationController _stepperHighlightController; // NEW: Sequential glow
  late Animation<double> _infoBarAnimation;
  late Animation<Color?> _infoBarBorderColorAnimation;

  late Animation<double> _hotGlow; // NEW
  late Animation<double> _neutralGlow; // NEW
  late Animation<double> _groundGlow; // NEW

  @override
  void initState() {
    super.initState();
    _dynamicBoxVolumes = Map.from(ConduitDB.boxVolumes);
    _borderAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 20000))
      ..repeat();
    _glowAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    
    _infoBarAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200)); // Slowed down for noticeable slide
    
    _infoBarAnimation = CurvedAnimation(
        parent: _infoBarAnimationController, 
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut)); // Slide finishes earlier

    _infoBarBorderColorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        weight: 70.0, // Stays normal during most of the slide
        tween: ConstantTween<Color?>(kSilver.withAlpha(180)),
      ),
      TweenSequenceItem(
        weight: 15.0, // Flashes to white
        tween: ColorTween(begin: kSilver.withAlpha(180), end: kLight),
      ),
      TweenSequenceItem(
        weight: 15.0, // Back to normal
        tween: ColorTween(begin: kLight, end: kSilver.withAlpha(180)),
      ),
    ]).animate(_infoBarAnimationController);

    // sequential highlight setup
    _stepperHighlightController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));

    _hotGlow = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10), // 1 (H)
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 60), // Wait for N, G, N
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10), // 1 (H) final
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
    ]).animate(_stepperHighlightController);

    _neutralGlow = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20), // Wait for H
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10), // 2 (N)
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20), // Wait for G
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10), // 2 (N)
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20), // Wait for final H
    ]).animate(_stepperHighlightController);

    _groundGlow = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40), // Wait for H, N
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10), // 3 (G)
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40), // Wait for N, H
    ]).animate(_stepperHighlightController);

    _infoBarAnimationController.forward();
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _glowAnimationController.dispose();
    _infoBarAnimationController.dispose();
    _stepperHighlightController.dispose();
    _voltageScrollController.dispose();
    _lengthScrollController.dispose();
    _loadScrollController.dispose();
    super.dispose();
  }

  Pipe get _activePipe => _pipes[_activePipeIndex];

  List<Wire> get _allWires => _pipes.expand((p) => p.wires).toList();

  void _showVoltageDropScrollHint() {
    _voltageDropInfoTimer?.cancel();
    setState(() {
      _voltageDropInfoMessage = "Scroll dials to test different voltage drop scenarios";
    });
    _voltageDropInfoTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _voltageDropInfoMessage = null);
    });
  }

  void _addWire(String type, String size, String insulation) {
    setState(() {
      if (type == 'Hot') {
        _activePipe.wires.add(Wire(
          size: size,
          insulation: insulation,
          material: _selectedMaterial,
          isCurrentCarrying: true,
        ));
      } else if (type == 'Neutral') {
        if (!_hasShownNeutralDialog) {
          _showOneTimeNeutralDialog(size, insulation);
          return; // dialog will handle the add decision
        } else {
          _activePipe.wires.add(Wire(
            size: size,
            insulation: insulation,
            material: _selectedMaterial,
            isNeutral: true,
            isCurrentCarrying: _isNeutralCCC,
          ));
        }
      } else if (type == 'Ground') {
        _activePipe.wires.add(Wire(
          size: size,
          insulation: insulation,
          material: _selectedMaterial,
          isGround: true,
          isCurrentCarrying: false,
        ));
      }
    });

    // ✅ After adding any wire, re-evaluate the workflow step.
    // This will move you from boxSetup ("Add Wires...") to free ("Tap Pipe or Box...")
    // once any pipe has wires.
    if (_isInitialSetupComplete) {
      Future.delayed(const Duration(seconds: 10), () {
        if (!mounted) return;
        _advanceToNextIncompleteStep();
      });
    } else {
      _advanceToNextIncompleteStep();
    }

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
                "Select Neutral Type",
                style: TextStyle(color: kLight, fontSize: 24)),
            // <--- Increased title font size
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                      Icons.radio_button_unchecked, color: Colors.green),
                  title: const Text(
                      "Shared Neutral (MWBC)",
                      style: TextStyle(color: kLight, fontSize: 18)),
                  // <--- Increased title font size
                  subtitle: const Text("Does NOT count toward derating.",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  // <--- Increased subtitle font size
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
                  leading: const Icon(
                      Icons.radio_button_unchecked, color: Colors.green),
                  title: const Text("Dedicated Neutral (2-Wire)",
                      style: TextStyle(color: kLight, fontSize: 18)),
                  // <--- Increased title font size
                  subtitle: const Text("ADDS to derating calculation.",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  // <--- Increased subtitle font size
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
                Text( // <--- Made Text non-const to modify style
                  "After this, use the 'CC' toggle on the stepper to change the neutral type.",
                  style: TextStyle( // <--- Increased font size for this text
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                      fontSize: 18),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text(
                    "NEC: Learn More",
                    style: TextStyle(color: kRed, fontSize: 20)),
                // <--- Increased action button font size
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

    // If no main selectors are chosen, return default unready state.
    if (_activePipe.size == null && _selectedBoxSize == null &&
        _selectedWireSize == null) {
      return {...defaultResults, ...boxSizing};
    }

    // --- CONDUIT FILL LOGIC ---
    double? maxArea;
    int maxWires = 0;
    if (_activePipe.size != null) {
      final totalAreaMap = _activePipe.pipeType == PipeType.emt ? ConduitDB
          .emtTotalArea : ConduitDB.rmcTotalArea;
      final double totalArea = totalAreaMap[_activePipe.size!]!;
      final int wireCountInActivePipe = activePipeWires.length;
      double fillFactor;
      if (wireCountInActivePipe == 1) {
        fillFactor = 0.53; // 53% for 1 wire
      } else if (wireCountInActivePipe == 2) {
        fillFactor = 0.31; // 31% for 2 wires
      } else {
        fillFactor = 0.40; // 40% for over 2 wires
      }
      maxArea = totalArea * fillFactor;

      // Max Wires Calculation (based on 40% fill)
      final double maxAreaForMaxWires = totalAreaMap[_activePipe.size!]! * 0.40;
      // Use selected wire for hypothetical max wires if active pipe is empty
      final wireSizeForMaxWires = activePipeWires.isNotEmpty ? activePipeWires
          .first.size : _selectedWireSize;
      final insulationForMaxWires = activePipeWires.isNotEmpty ? activePipeWires
          .first.insulation : _selectedInsulation;

      if (wireSizeForMaxWires != null && insulationForMaxWires != null) {
        final double? wireArea = ConduitDB
            .wireAreas[wireSizeForMaxWires]?[insulationForMaxWires];
        if (wireArea != null && wireArea > 0) {
          maxWires = (maxAreaForMaxWires / wireArea).floor();
        }
      }
    }

    // --- BOX FILL LOGIC ---
    double conductorVolume = allWires.where((w) => !w.isGround).fold(
        0.0, (sum, w) => sum + (ConduitDB.wireVolumes[w.size] ?? 0.0));
    double clampVolume = 0;
    double supportFittingVolume = 0;
    double deviceVolume = 0;
    double groundingVolume = 0;

    // Determine the wire size to use for allowances (largest physical wire for volume)
    Wire? largestNonGroundConductor = allWires
        .where((w) => !w.isGround)
        .toList()
        .fold(
        null, (largest, current) {
      if (largest == null) return current;
      final largestComparableSize = _getComparableWireSizeValue(largest.size);
      final currentComparableSize = _getComparableWireSizeValue(current.size);
      return currentComparableSize > largestComparableSize ? current : largest;
    });

    String? allowanceWireSize;
    if (largestNonGroundConductor != null) {
      allowanceWireSize = largestNonGroundConductor.size;
    } else if (allWires.isEmpty && _selectedWireSize != null) {
      allowanceWireSize = _selectedWireSize;
    }

    if (allowanceWireSize != null) {
      final double? allowance = ConduitDB.wireVolumes[allowanceWireSize];
      if (allowance != null) {
        clampVolume = (_clampCount > 0 ? 1 : 0) * allowance; // NEC 314.16(B)(2) one or more = 1 allowance
        supportFittingVolume = _supportFittingCount * allowance;
        deviceVolume = _deviceCount * 2 * allowance;
      }
    }

    final groundWires = allWires.where((w) => w.isGround).toList();
    Wire? largestGround = groundWires.fold(null, (largest, current) {
      if (largest == null) return current;
      final largestComparableSize = _getComparableWireSizeValue(largest.size);
      final currentComparableSize = _getComparableWireSizeValue(current.size);
      return currentComparableSize > largestComparableSize ? current : largest;
    });

    if (largestGround != null) {
      final double groundAllowance = ConduitDB.wireVolumes[largestGround
          .size] ?? 0.0;
      // 2020/2023 NEC 314.16(B)(5): 1 allowance for first 4, 1/4 for each additional
      if (groundWires.length <= 4) {
        groundingVolume = groundAllowance;
      } else {
        groundingVolume = groundAllowance + (groundAllowance * 0.25 * (groundWires.length - 4));
      }
    }

    int boxWireAllowanceCount = allWires
        .where((w) => !w.isGround)
        .length;
    if (groundWires.isNotEmpty) {
      boxWireAllowanceCount += 1;
    }

    int maxBoxWires = 0;
    if (_selectedBoxSize != null && _selectedWireSize != null) {
      final double? boxVolume = _dynamicBoxVolumes[_selectedBoxSize];
      final double? wireVolume = ConduitDB.wireVolumes[_selectedWireSize];

      if (boxVolume != null && wireVolume != null && wireVolume > 0) {
        double totalAvailableVolume = boxVolume;
        if (_selectedMudRing != null) {
          totalAvailableVolume +=
              ConduitDB.mudRingVolumes[_selectedMudRing!] ?? 0.0;
        }
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

    // --- AMPACITY DERATING CALCULATIONS (for the CURRENTLY SELECTED wire type) ---
    // These calculations reflect the properties of the wire selected in the dropdowns.
    String? currentSelectedWireSize = _selectedWireSize;
    ConductorMaterial currentSelectedMaterial = _selectedMaterial;

    int startingAmpacity = 0;
    if (currentSelectedWireSize != null) {
      final ampacitiesMap = currentSelectedMaterial == ConductorMaterial.copper
          ? ConduitDB.copperAmpacities
          : ConduitDB.aluminumAmpacities;
      startingAmpacity = ampacitiesMap[currentSelectedWireSize]?["90C"] ?? 0;
    }

    // Determine the number of current-carrying conductors for derating factor.
    // This *still depends on all wires in the active pipe*.
    int cccCount = activePipeWires
        .where((w) => w.isCurrentCarrying)
        .length;
    // If no actual CCC wires in the pipe, but a wire size is selected in dropdown for display,
    // assume 1 for initial adjustment factor calculation.
    if (cccCount == 0 && currentSelectedWireSize != null &&
        _selectedInsulation != null) {
      cccCount = 1;
    }

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

    final double newAmpacity = startingAmpacity * adjustmentFactor *
        tempCorrectionFactor;

    // Safely get the 75C ampacity, defaulting to 0 if not found
    final Map<String,
        Map<String, int>> ampacitiesMapForCap = currentSelectedMaterial ==
        ConductorMaterial.copper
        ? ConduitDB.copperAmpacities
        : ConduitDB.aluminumAmpacities;

    final int capAmps75 = currentSelectedWireSize != null
        ? (ampacitiesMapForCap[currentSelectedWireSize]?["75C"] ?? 0)
        : 0;
    final double finalAmps = math.min(newAmpacity, capAmps75.toDouble());

    int overcurrentLimit = 1000; // A high default
    if (currentSelectedWireSize != null) {
      if (currentSelectedMaterial == ConductorMaterial.copper) {
        if (currentSelectedWireSize == "18 AWG") {
          overcurrentLimit = 7;
        } else if (currentSelectedWireSize == "16 AWG") {
          overcurrentLimit = 10;
        } else if (currentSelectedWireSize == "14 AWG") {
          overcurrentLimit = 15;
        } else if (currentSelectedWireSize == "12 AWG") {
          overcurrentLimit = 20;
        } else if (currentSelectedWireSize == "10 AWG") {
          overcurrentLimit = 30;
        }
      } else {
        // Aluminum limits per 240.4(D)
        if (currentSelectedWireSize == "12 AWG") {
          overcurrentLimit = 15;
        } else if (currentSelectedWireSize == "10 AWG") {
          overcurrentLimit = 25;
        }
      }
    }

    int finalBreakerSize = ConduitDB.standardBreakerSizes.lastWhere((s) =>
    s <= finalAmps, orElse: () => 0);
    finalBreakerSize = math.min(overcurrentLimit, finalBreakerSize);

    // --- VOLTAGE DROP CALCULATIONS ---
    double voltageDrop = 0.0;
    double voltageDropPercent = 0.0;
    if (_length > 0 && _voltage > 0 && currentSelectedWireSize != null) {
      final double kValue = currentSelectedMaterial == ConductorMaterial.copper
          ? ConduitDB.copperK
          : ConduitDB.aluminumK;
      final int cma = ConduitDB.wireCMA[currentSelectedWireSize] ?? 1;

      // Use loadAmps if entered (>0), otherwise fallback to finalBreakerSize
      final double effectiveLoad = _loadAmps > 0 ? _loadAmps : finalBreakerSize.toDouble();
      final double phaseMultiplier = _isThreePhase ? 1.732 : 2.0;

      if (effectiveLoad > 0) {
        voltageDrop = (phaseMultiplier * kValue * _length * effectiveLoad) / cma;
        voltageDropPercent = (voltageDrop / _voltage) * 100;
      }
    }

    final String groundWireSize = _getGroundWireSize(finalBreakerSize);

    return {
      "isReady": _selectedWireSize != null && _selectedInsulation != null,
      // Ready if wire selected
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

  // Helper method to get a comparable numeric value for wire sizes (larger number for larger wire)
  // This helps in finding the physically largest wire for volume allowances.
  int _getComparableWireSizeValue(String wireSize) {
    if (wireSize.contains("AWG")) {
      final String awgPart = wireSize.replaceAll(" AWG", "");
      if (awgPart.contains("/")) { // Handles 1/0, 2/0, etc.
        // Convert X/0 AWG to a negative number for comparison, e.g., 1/0 = -10, 2/0 = -20
        // This makes larger actual wires (smaller AWG number, or X/0) result in a larger comparative value here.
        final int numerator = int.tryParse(awgPart.split('/')[0]) ?? 0;
        return -numerator *
            100; // Multiply by 100 to clearly separate from positive AWG
      }
      // For standard AWG, smaller number means larger wire, so invert for comparable value.
      return (int.tryParse(awgPart) ?? 40) *
          -1; // e.g., 14 AWG -> -14, 12 AWG -> -12
    } else if (wireSize.contains("KCMIL")) {
      // KCMIL values are directly comparable; larger number means larger wire.
      // Offset by a large number to place them distinct from AWG.
      return (int.tryParse(wireSize.replaceAll(" KCMIL", "")) ?? 0) + 10000;
    }
    return 0; // Default or unknown
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
    // If we’re past initial setup, we STILL need to manage the final phases
    // based on whether wires exist.
    if (_isInitialSetupComplete) {
      final bool hasAnyWires = _pipes.any((p) => p.wires.isNotEmpty);

      setState(() {
        _currentStep =
        hasAnyWires ? CalculatorStep.free : CalculatorStep.boxSetup;
        _infoBarAnimationController.reset();
        _infoBarAnimationController.forward();
      });
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
      final bool hasAnyWires = _pipes.any((p) => p.wires.isNotEmpty);

      setState(() {
        _isInitialSetupComplete = true;
        _currentStep =
        hasAnyWires ? CalculatorStep.free : CalculatorStep.boxSetup;
        _infoBarAnimationController.reset();
        _infoBarAnimationController.forward();
        
        // Trigger sequential stepper highlight
        if (_currentStep == CalculatorStep.boxSetup) {
          _stepperHighlightController.forward(from: 0.0);
        }
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
    final bool wasTapOptionsStep = _currentStep == CalculatorStep.free;

    // NEW: Set interaction flag if in free state
    setState(() {
      if (_currentStep == CalculatorStep.free) {
        _hasInteractedWithPipeOrBoxInFreeState = true;
      }
      _showPullThroughBoxInfoBar = false; // Clear pull-through specific message
      _infoBarAnimationController.reset();
      _infoBarAnimationController.forward();
    });


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
              terminalBlockCount: _terminalBlockCount,
              // NEW: Pass terminal block count
              onTerminalBlockCountChanged: (c) =>
                  setState(() => _terminalBlockCount = c),
              // NEW: Pass terminal block callback
              onPullTypeChanged: (pipeId, pullType, entrySide) {
                setState(() {
                  final pipeToUpdate = _pipes.firstWhere((p) => p.id == pipeId);
                  pipeToUpdate.pullType = pullType;
                  if (entrySide != null) pipeToUpdate.entrySide = entrySide;
                });
              },
              pullThroughWireCount: _pullThroughWireCount,
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
    if (wasTapOptionsStep) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _currentStep == CalculatorStep.free) {
          setState(() {
            // _showAlternateInfoMessage = true; // REMOVED: No longer needed
          });
        }
      });
    }
  }


  void _togglePipeUI() {
    // NEW: Set interaction flag if in free state
    setState(() {
      if (_currentStep == CalculatorStep.free) {
        _hasInteractedWithPipeOrBoxInFreeState = true;
      }
    });

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
              void removePipeAndRefresh() {
                if (_pipes.length <= 1) return;

                _pipes.removeAt(_activePipeIndex);

                if (_activePipeIndex >= _pipes.length) {
                  _activePipeIndex = _pipes.length - 1;
                }

                setState(() {});
              }

              void addWireAndRefresh(Wire wire) {
                _pipes[_activePipeIndex].wires.add(wire);
                setState(() {});
              }

              void removeWireAndRefresh(Wire wire) {
                final wires = _pipes[_activePipeIndex].wires;

                final index = wires.indexWhere((w) =>
                w.size == wire.size &&
                    w.insulation == wire.insulation &&
                    w.material == wire.material &&
                    w.isGround == wire.isGround &&
                    w.isNeutral == wire.isNeutral &&
                    w.isCurrentCarrying == wire.isCurrentCarrying);

                if (index != -1) {
                  wires.removeAt(index);
                }

                setState(() {});
                _advanceToNextIncompleteStep();
              }

              void resizeWireGroupAndRefresh(Wire targetWire, bool up) {
                final activePipe = _pipes[_activePipeIndex];
                final List<String> sizes = ConduitDB.wireVolumes.keys.toList();

                // 1. Capture properties BEFORE modifying anything
                final String oldSize = targetWire.size;
                final String insulation = targetWire.insulation;
                final ConductorMaterial material = targetWire.material;
                final bool isGround = targetWire.isGround;
                final bool isNeutral = targetWire.isNeutral;

                final currentIndex = sizes.indexOf(oldSize);
                if (currentIndex == -1) return;

                final newIndex = up ? currentIndex + 1 : currentIndex - 1;
                if (newIndex < 0 || newIndex >= sizes.length) return;

                final newSize = sizes[newIndex];

                // ✅ Parent Sync: Update the main dashboard's dropdown selections
                // if we are resizing a non-ground wire.
                if (!isGround) {
                  this.setState(() {
                    _selectedWireSize = newSize;
                    _selectedMaterial = material;
                  });
                }

                // 2. Update all matching wires in the active pipe using captured properties
                for (var wire in activePipe.wires) {
                  if (wire.size == oldSize &&
                      wire.insulation == insulation &&
                      wire.material == material &&
                      wire.isGround == isGround &&
                      wire.isNeutral == isNeutral) {
                    wire.size = newSize;
                  }
                }
                setState(() {});
              }

              void resizePipeAndRefresh(bool up) {
                final activePipe = _pipes[_activePipeIndex];
                final List<String> sizes = ConduitDB.tradeSizesInches.keys.toList();
                final currentIndex = sizes.indexOf(activePipe.size ?? "");
                if (currentIndex == -1) return;

                final newIndex = up ? currentIndex + 1 : currentIndex - 1;
                if (newIndex >= 0 && newIndex < sizes.length) {
                  activePipe.size = sizes[newIndex];
                  // ✅ Sync back to main screen
                  this.setState(() {});
                }
                setState(() {});
              }

              return _PipeUIDetailView(
                pipes: _pipes,
                activePipeIndex: _activePipeIndex,
                onAddPipe: addPipeAndRefresh,
                onRemovePipe: removePipeAndRefresh,
                onSetActivePipe: setActivePipeAndRefresh,
                onResizePipe: resizePipeAndRefresh,
                onAddWire: addWireAndRefresh,
                onRemoveWire: removeWireAndRefresh,
                onResizeWireGroup: resizeWireGroupAndRefresh,
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
      _hasInteractedWithPipeOrBoxInFreeState =
      false; // NEW: Reset interaction flag
      _deviceCount = 0;
      _clampCount = 0;
      _supportFittingCount = 0;
      _terminalBlockCount = 0; // NEW: Reset terminal block count
      _selectedAmbientTempKey = null;
      _hasShownNeutralDialog = false;
      _isNeutralCCC = false;
      _length = 0.0;
      _voltage = 0.0;
      _loadAmps = 0.0;
      _isThreePhase = false;
      _voltageDropInfoMessage = null;
      _voltageScrollController.jumpToItem(0);
      _lengthScrollController.jumpToItem(0);
      _loadScrollController.jumpToItem(0);
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
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 18),
          backgroundColor: const Color(0xFF1F2323),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: kSilver.withAlpha(120), width: 1.2),
          ),
          title: const Center(
            child: Text(
              "Select a Box",
              style: TextStyle(
                color: kLight,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
    const bg = Color(0xFF212121);
    const bodyStyle = TextStyle(color: kLight, fontSize: 16, height: 1.45);

    showDialog(
      context: context,
      builder: (context) {
        String? openSection;

        return StatefulBuilder(
          builder: (context, setState) {
            Widget gap([double h = 8]) => SizedBox(height: h);
            Widget bullet(String text) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: bodyStyle),
                      Expanded(child: Text(text, style: bodyStyle)),
                    ],
                  ),
                );

            Widget sectionTile({required String id, required String title, required List<Widget> children}) {
              return Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  key: PageStorageKey(id),
                  onExpansionChanged: (exp) => setState(() => openSection = exp ? id : null),
                  tilePadding: EdgeInsets.zero,
                  iconColor: kLight,
                  collapsedIconColor: kLight,
                  title: Text(title, style: const TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 17)),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  children: openSection == id ? children : [],
                ),
              );
            }

            return AlertDialog(
              backgroundColor: bg,
              insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
              ),
              title: const Text(
                'Pipe and Box Fill Help',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTile(
                        id: 'purpose',
                        title: 'What This Tool Is Designed To Do',
                        children: [
                          const Text(
                            'Pipe fill may look acceptable at first, but once bundling and temperature correction are applied, '
                                'reduced ampacity can force conductor upsizing.',
                            style: bodyStyle,
                          ),
                          gap(),
                          const Text(
                            'Larger conductors reduce how many fit inside the conduit and take up more space inside the box.',
                            style: bodyStyle,
                          ),
                          gap(),
                          const Text(
                            'At that point, your options become clear: upsize the conduit to accommodate the larger wire size, '
                                'or add additional conduit runs to maintain the current wire size.',
                            style: bodyStyle,
                          ),
                          gap(),
                          const Text(
                            'This tool is built to show you those trade-offs in real time as you build your run.',
                            style: bodyStyle,
                          ),
                        ],
                      ),

                      sectionTile(
                        id: 'auto',
                        title: 'Calculates Automatically',
                        children: [
                          bullet('Conduit fill percentage limits (100% = NEC Max Allowable)'),
                          bullet('Bundling derating (current-carrying conductors)'),
                          bullet('Ambient temperature correction'),
                          bullet('Adjusted ampacity calculations'),
                          bullet('Small conductor rule'),
                          bullet('Standard breaker sizing'),
                          bullet('75°C Terminal Limitation (limits ampacity)'),
                          bullet('Box fill volume allowances'),
                          bullet('Voltage drop (when values are provided)'),
                          gap(6),
                          const Text(
                            'Ampacity updates automatically as conductors are added.',
                            style: bodyStyle,
                          ),
                          gap(6),
                          const Text(
                            'Note: Conduit Fill % is scaled to the NEC maximums (53% for 1 wire, 31% for 2, 40% for 3+). 100% in the app means you have reached the legal limit.',
                            style: bodyStyle,
                          ),
                          gap(6),
                          const Text(
                            'Note: Even with 90°C conductors, the final allowable ampacity and breaker size are often limited by the 75°C rating of terminals and equipment, per NEC 110.14(C).',
                            style: bodyStyle,
                          ),
                        ],
                      ),

                      sectionTile(
                        id: 'workflow',
                        title: 'Calculator Workflow',
                        children: [
                          bullet('1) Select Pipe Size, Box Size, Wire Size, Insulation Type, and Ambient Temperature.'),
                          bullet('2) Use the H, N, and G steppers to add conductors to the active pipe.'),
                          const Padding(
                            padding: EdgeInsets.only(left: 22.0, bottom: 6),
                            child: Text(
                              'Use the CC button to indicate whether a Neutral is a current-carrying conductor.',
                              style: bodyStyle,
                            ),
                          ),
                          bullet('3) Watch live updates to ampacity, derating, conduit fill, and box fill.'),
                          bullet('4) Enter voltage drop values if desired (optional).'),
                        ],
                      ),

                      sectionTile(
                        id: 'pipe',
                        title: 'Pipe Dashboard (Tap the Pipe)',
                        children: [
                          bullet('Add additional pipes or switch between existing pipes.'),
                          bullet('Each pipe contributes to the currently selected box.'),
                          bullet('Add or remove conductors from the full scrollable wire list.'),
                        ],
                      ),

                      sectionTile(
                        id: 'box',
                        title: 'Box Design (Tap the Box)',
                        children: [
                          bullet('Add devices, internal clamps, support fittings, mud rings, and extension rings.'),
                          bullet('View all conductors currently contributing to box fill.'),
                          bullet('Define pull types.'),
                          bullet('Perform junction box sizing for #4 AWG and larger conductors.'),
                          bullet('After adding multiple pipes, the Pull-Through Wires stepper becomes available.'),
                        ],
                      ),

                      sectionTile(
                        id: 'vdrop',
                        title: 'Voltage Drop (Optional)',
                        children: [
                          const Text(
                            'Voltage drop determines if the currently selected wire size and length allows for more loss than is desired.',
                            style: bodyStyle,
                          ),
                          gap(),
                          bullet('Limit Recommendation: NEC recommends max 3% for branch circuits, or 5% for the total system.'),
                          bullet('1Ø (Single Phase): Use for standard 120V/277V circuits where current returns on a Neutral.'),
                          bullet('3Ø (Three Phase): Use for balanced loads like 3-phase motors or heaters. Math uses the 1.732 multiplier.'),
                          bullet('Auto Load: Leaving Load at "0 (Auto)" uses the calculated Breaker Size. Enter specific Amps for more realism.'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            );
          },
        );
      },
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
                      'When is conductor ampacity derating required?',
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
                        builder: (context) =>  ConduitFillCodeScreen()));
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
                        builder: (context) =>  BoxFillBasicsCodeScreen()));
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
    final bool canPipeGlowMeaningfully = (_activePipe.size != null &&
        _pipes.any((p) => p.wires.isNotEmpty));


    return Scaffold(
        backgroundColor: kBlack,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F1F1F),
          foregroundColor: kLight,
          leadingWidth: 110,
          leading: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                    (route) => false,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  _reset();
                },
              ),
            ],
          ),
          title: const Text('Pipe and Box Fill',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          centerTitle: true,
          elevation: 0.5,
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (!_hasViewedInfo)
                  RotationTransition(
                    turns: _glowAnimationController,
                    child: AnimatedBuilder(
                      animation: _glowAnimationController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (rect) {
                            return SweepGradient(
                              colors: [
                                kLight.withValues(alpha: 0.0),
                                kLight.withValues(alpha: 0.2 +
                                    (0.7 *
                                        (0.5 +
                                            0.5 *
                                                math.sin(_glowAnimationController.value *
                                                    2 *
                                                    math.pi)))),
                                kLight.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(rect);
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: kLight, width: 2.0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    setState(() => _hasViewedInfo = true);
                    _showInfoDialog(context);
                  },
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showNecCodeDialog(context),
              child: const Padding(
                padding: EdgeInsets.only(left: 4.0, right: 12.0),
                child: Center(
                  child: Text('NEC', style: TextStyle(
                      color: kLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        body: PulsingGlowBorder(
          animationController: _borderAnimationController,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
          isPulsing: false,
          clockwise: false,
          // You can change this to 'true' if you want it to rotate clockwise
          sweepColors: [
            kRed.withValues(alpha: 0.5), // Start with red
            kLight.withValues(alpha: 0.8), // Transition to white
            kSilver.withValues(alpha: 0.7), // Transition to silver
            kRed.withValues(alpha: 0.5), // Fade back to red to complete the loop
          ],
          sweepStops: const [0.0, 0.33, 0.66, 1.0],
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
                        _buildVisualsColumn(results),
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
        ) // NOTE: No 'body:' prefix here, and this should be followed by a comma ',' in your Scaffold.
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
          Expanded(
              child: _StyledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showPipeSelectionGrid();
                },
                label: _activePipe.size != null
                    ? '(${_activePipeIndex + 1}) ${_activePipe.size}" ${_activePipe.pipeType
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
              HapticFeedback.mediumImpact();
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
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showWireSelectionGrid();
            },

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
              HapticFeedback.mediumImpact();
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
            child: AnimatedBuilder(
              animation: _hotGlow,
              builder: (context, child) => _WireStepper(
                label: 'H',
                count: hotCount,
                color: kRed,
                glowValue: _hotGlow.value,
                onAdd: canAdd
                    ? () {
                  HapticFeedback.lightImpact();
                  _addWire('Hot', _selectedWireSize!, _selectedInsulation!);
                }
                    : null,
                onRemove: () {
                  HapticFeedback.lightImpact();
                  _removeLastWireOfType('Hot');
                },
              ),
            ),
          ),
          const SizedBox(width: spacing),

          Expanded(
            child: AnimatedBuilder(
              animation: _neutralGlow,
              builder: (context, child) => _WireStepper(
                label: 'N',
                count: neutralCount,
                color: Colors.white,
                glowValue: _neutralGlow.value,
                onAdd: canAdd
                    ? () {
                  HapticFeedback.lightImpact();
                  _addWire('Neutral', _selectedWireSize!, _selectedInsulation!);
                }
                    : null,
                onRemove: () {
                  HapticFeedback.lightImpact();
                  _removeLastWireOfType('Neutral');
                },
              ),
            ),
          ),
          const SizedBox(width: spacing),

          Expanded(
            child: AnimatedBuilder(
              animation: _groundGlow,
              builder: (context, child) => _WireStepper(
                label: 'G',
                count: groundCount,
                color: Colors.green,
                glowValue: _groundGlow.value,
                onAdd: canAdd
                    ? () {
                  HapticFeedback.lightImpact();
                  _addWire('Ground', _selectedWireSize!, _selectedInsulation!);
                }
                    : null,
                onRemove: () {
                  HapticFeedback.lightImpact();
                  _removeLastWireOfType('G_rounded');
                },
              ),
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

  Widget _buildVisualsColumn(Map<String, dynamic> results) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPipeVisual(results),

          // 👇 This stops the yellow overflow flash during the shrink animation
          ClipRect(
            child: _buildBoxVisual(results),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeVisual(Map<String, dynamic> results) {
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
    // NEW: shouldGlowPipe logic: only glows if in free state, NOT interacted with, AND there's a pipe size or wires to make it meaningful.
    final bool canPipeGlowMeaningfully = (_activePipe.size != null &&
        _pipes.any((p) => p.wires.isNotEmpty));
    final bool shouldGlowPipe = _currentStep == CalculatorStep.free &&
        !_hasInteractedWithPipeOrBoxInFreeState && canPipeGlowMeaningfully;


    final pipeContent = Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[800],
        border: shouldGlowPipe ? null : Border.all(

            color: conduitStatusColor, width: 8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_activePipe.size != null ? "(${_activePipeIndex + 1}) ${_activePipe.size}\"" : "Pipe", style: const TextStyle(
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
      width: 180,
      height: 180,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _togglePipeUI();
        },
        child: Hero(
          tag: 'pipe-hero',
          child: Material(
            type: MaterialType.transparency,
            child: shouldGlowPipe // Only glow if shouldGlowPipe is true
                ? PulsingGlowBorder(
              animationController: _glowAnimationController,
              shape: BoxShape.circle,
              isPulsing: true,
              borderWidth: 8.0,

              // Set glow colors to green/white
              startColor: Colors.green.withOpacity(0.35),
              // Start with green glow
              endColor: kLight.withOpacity(0.85),
              // Transition to white

              child: pipeContent,
            )
                : PulsingGlowBorder( // Always use PulsingGlowBorder for consistent solid border
              animationController: _glowAnimationController,
              // Still need a controller, but it won't animate
              shape: BoxShape.circle,
              isPulsing: false,
              // Don't pulse
              borderWidth: 2.0,
              startColor: conduitStatusColor.withOpacity(0.85),
              // Solid status color
              endColor: conduitStatusColor.withOpacity(0.85),
              // Solid status color
              child: pipeContent,
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
    final bool isBoxWarning = boxFill > 90.0 && !isBoxViolation;

    final Color boxStatusColor = !isReady || _selectedBoxSize == null
        ? Colors.grey
        : (isBoxViolation
        ? kRed
        : (isBoxWarning ? Colors.yellow : Colors.green));

    final int boxWireAllowanceCount = results['boxWireAllowanceCount'] ?? 0;
    final wireTypes = _allWires.map((w) => '${w.size}-${w.insulation}').toSet();
    final bool showMaxBoxWires = wireTypes.length <= 1 || _allWires.isEmpty;

    // NEW: shouldGlowBox logic: only glows if in free state, NOT interacted with, AND a box is selected (or pipes exist)
    final bool canBoxGlowMeaningfully = (_selectedBoxSize != null ||
        _pipes.any((p) => p.wires.isNotEmpty));
    final bool shouldGlowBox = _currentStep == CalculatorStep.free &&
        !_hasInteractedWithPipeOrBoxInFreeState && canBoxGlowMeaningfully;

    final boxContent = LayoutBuilder(
      builder: (context, constraints) {
        // During Hero reverse-flight, constraints can temporarily be smaller than 170.
        final maxW = constraints.hasBoundedWidth ? constraints.maxWidth : 170.0;
        final maxH = constraints.hasBoundedHeight ? constraints.maxHeight : 170.0;
        final dim = math.min(170.0, math.min(maxW, maxH));

        return SizedBox(
          width: dim,
          height: dim,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.grey[800],
              border: shouldGlowBox
                  ? null
                  : Border.all(
                color: boxStatusColor,
                width: 2.0,
              ),
            ),
            child: Center(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedBoxSize ?? "Box",
                          style: const TextStyle(
                            color: kLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !isReady || _selectedBoxSize == null
                              ? "-- Wires\n--% Fill"
                              : "$boxWireAllowanceCount Wires\n${boxFill.toStringAsFixed(1)}% Fill",
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _toggleBox();
      },
      child: Hero(
        tag: 'box-hero',
        flightShuttleBuilder: (flightContext, animation, flightDirection, fromContext, toContext) {
          if (flightDirection == HeroFlightDirection.pop) {
            // When popping (coming back), completely skip the morphing animation.
            // We return an empty, transparent box. The page's standard transition
            // (like your FadeTransition) will handle the return animation.
            return const SizedBox.shrink();
          } else {
            // When pushing (going to the detail screen), perform the smooth morphing.
            // The ClipRect here is to prevent overflow during the expansion.
            final Widget shuttle = toContext.widget;
            return ClipRect(child: shuttle);
          }
        },
        child: ClipRect(
          child: shouldGlowBox
              ? PulsingGlowBorder(
            animationController: _glowAnimationController,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12.0),
            isPulsing: true,
            borderWidth: 8.0,
            startColor: Colors.green.withOpacity(0.35),
            endColor: kLight.withOpacity(0.85),
            child: boxContent,
          )
              : PulsingGlowBorder(
            animationController: _glowAnimationController,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12.0),
            isPulsing: false,
            borderWidth: 8.0,
            startColor: boxStatusColor.withOpacity(0.85),
            endColor: boxStatusColor.withOpacity(0.85),
            child: boxContent,
          ),
        ),
      ),
    );
  }


  Widget _buildInfoBar() {
    String text = "";
    if (_voltageDropInfoMessage != null) {
      text = _voltageDropInfoMessage!;
    } else if (_showPullThroughBoxInfoBar) {
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
          text = "Add Wires to See Calculations";
          break;
        case CalculatorStep.free:
          text = "Tap Pipe or Box for more options";
          break;
      }
    }

    return FadeTransition(
      opacity: _infoBarAnimationController.drive(CurveTween(curve: const Interval(0.0, 0.5))), // Fade in early
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.08, 0), // Slightly longer slide distance
          end: Offset.zero,
        ).animate(_infoBarAnimation),
        child: AnimatedBuilder(
          animation: _infoBarBorderColorAnimation,
          builder: (context, child) {
            return Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3030),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _infoBarBorderColorAnimation.value ?? kSilver.withAlpha(180),
                  width: _infoBarBorderColorAnimation.value == kLight ? 1.5 : 1.0, // Slight thicken during flash
                ),
              ),
              child: child,
            );
          },
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: kLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
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
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, 0.75),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: Colors.white54)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Text("Derating", style: Theme
                .of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: kLight, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            _StyledDropdown(
              value: _selectedAmbientTempKey,
              hint: "Ambient Temp °F",
              items: ConduitDB.temperatureCorrectionFactors["90C"]!.keys
                  .map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (v) {
                HapticFeedback.mediumImpact();
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
            const SizedBox(height: 10),
            Text("Starting Ampacity: ${isReady ? startingAmpacity : '--'}A",
                style: const TextStyle(color: kLight, fontSize: 14)),
            const SizedBox(height: 6),
            Text("Temp Factor: ${isReady ? (tempCorrectionFactor * 100).toStringAsFixed(0) : '--'}%",
                style: const TextStyle(color: kLight, fontSize: 14)),
            const SizedBox(height: 6),
            Text("Bundle Factor: ${isReady ? (adjustmentFactor * 100).toStringAsFixed(0) : '--'}%",
                style: const TextStyle(color: kLight, fontSize: 14)),
            const SizedBox(height: 6),
            Text("New Ampacity: ${isReady ? newAmpacity.toStringAsFixed(1) : '--'}A",
                style: const TextStyle(color: kLight, fontSize: 14)),
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
            const SizedBox(height: 10),
            Text(
              "Required Ground:\n${isReady ? groundWireSize : 'N/A'}",
              textAlign: TextAlign.left,
              style: TextStyle(
                color: hasCalculationRun ? Colors.green : kLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white24, height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Voltage Drop", style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: kLight, fontWeight: FontWeight.bold, fontSize: 20)),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isThreePhase = !_isThreePhase);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isThreePhase ? const Color(0xFFE53935) : Colors.grey[850],
                      shape: BoxShape.circle,
                      border: Border.all(color: kSilver.withAlpha(150), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _isThreePhase ? "3Ø" : "1Ø",
                        style: const TextStyle(color: kLight, fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${voltageDrop.toStringAsFixed(1)}V (${voltageDropPercent.toStringAsFixed(1)}%)",
              style: TextStyle(
                color: isVoltageDropViolation ? kRed : Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _buildInlineDial(
              label: "Voltage",
              unit: "Volts",
              controller: _voltageScrollController,
              items: ["120", "208", "240", "277", "480"],
              onChanged: (val) {
                final list = [120.0, 208.0, 240.0, 277.0, 480.0];
                setState(() => _voltage = list[val]);
                _showVoltageDropScrollHint();
              },
            ),
            const SizedBox(height: 4),
            _buildInlineDial(
              label: "Length",
              unit: "ft",
              controller: _lengthScrollController,
              items: List.generate(101, (i) => (i * 5).toString()), // 0 to 500
              onChanged: (val) {
                setState(() => _length = val.toDouble() * 5);
                _showVoltageDropScrollHint();
              },
            ),
            const SizedBox(height: 4),
            _buildInlineDial(
              label: "Load",
              unit: "Amps",
              controller: _loadScrollController,
              items: List.generate(201, (i) => i == 0 ? "Auto" : i.toString()),
              onChanged: (val) {
                setState(() => _loadAmps = val.toDouble());
                _showVoltageDropScrollHint();
              },
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineDial({
    required String label,
    required String unit,
    required FixedExtentScrollController controller,
    required List<String> items,
    required ValueChanged<int> onChanged,
  }) {
    return GestureDetector(
      onTap: _showVoltageDropScrollHint,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1.2),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 28,
                perspective: 0.008,
                diameterRatio: 1.0,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  HapticFeedback.selectionClick();
                  onChanged(index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: items.length,
                  builder: (context, index) {
                    return Center(
                      child: Text(
                        items[index],
                        style: const TextStyle(color: kLight, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_drop_up, color: Colors.white, size: 16),
                  Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                ],
              ),
            ),
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
  final VoidCallback onRemovePipe; 
  final ValueChanged<int> onSetActivePipe;
  final Function(bool) onResizePipe;
  final ValueChanged<Wire> onAddWire; 
  final ValueChanged<Wire> onRemoveWire; 
  final Function(Wire, bool) onResizeWireGroup;
  final Map<String, dynamic> results;
  final String? selectedBoxSize;

  const _PipeUIDetailView({
    super.key,
    required this.pipes,
    required this.activePipeIndex,
    required this.onAddPipe,
    required this.onRemovePipe, 
    required this.onSetActivePipe,
    required this.onResizePipe,
    required this.onAddWire, 
    required this.onRemoveWire, 
    required this.onResizeWireGroup,
    required this.results,
    required this.selectedBoxSize,
  });

  @override
  State<_PipeUIDetailView> createState() => _PipeUIDetailViewState();
}

class _PipeUIDetailViewState extends State<_PipeUIDetailView>
    with TickerProviderStateMixin {

  late int _localActivePipeIndex;
  String? _selectedWireSummaryKey;
  bool _hasViewedInfo = false;

  // --- VERTICAL POSITIONING CONTROLS ---
  // Adjust these numbers to move groups up and down within the circle.
  
  // 1. PUSH ALL GROUPS DOWN: Increase to move everything away from the top arc.
  final double _pushEverythingDownFactor = 0.25;

  // 2. TOP SECTION GAP: Space between the Pipe Info and the Top Line.
  final double _gapInsideTopSection = 10.0;

  // 3. MIDDLE GAP: Space between the Top Line and the Wire Summary wheel.
  final double _gapAboveMiddleSection = 10.0;

  // 4. BOTTOM GAP: Space between the Summary wheel and the Bottom Line.
  final double _gapAboveBottomSection = 30.0;

  // 5. FOOTER GAP: Space between the Bottom Line and the Conduit Fill text.
  final double _gapInsideBottomSection = 25.0;
  // -------------------------------------

  final PageController _wireSummaryPageController = PageController(
    viewportFraction: 0.40,
  );

  late final AnimationController _pipeBorderController;
  late final AnimationController _glowAnimationController;

  @override
  void initState() {
    super.initState();

    _pipeBorderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )
      ..repeat();

    _glowAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();

    _localActivePipeIndex = widget.activePipeIndex;
    _updateSelectedWireSummary();
  }

  @override
  void dispose() {
    _pipeBorderController.dispose();
    _glowAnimationController.dispose();
    _wireSummaryPageController.dispose();
    super.dispose();
  }

  void _showPipeDetailInfoDialog(BuildContext context) {
    const bodyStyle = TextStyle(
      color: Colors.white,
      fontSize: 18.5,
      height: 1.45,
      letterSpacing: 0.2,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: const Text(
          "Pipe Dashboard screen help",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kLight),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "This is where you edit the pipe details you created on the main screen. "
                  "You can add additional pipes and switch between them using the selector. "
                  "Note: To add a new type of wire that isn't already in your selection, return to the main dashboard.",
                  style: bodyStyle,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: bodyStyle),
                    Expanded(child: Text("Add or remove wires from the current selection.", style: bodyStyle)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: bodyStyle),
                    Expanded(child: Text("Use the selector to switch the active pipe.", style: bodyStyle)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: bodyStyle),
                    Expanded(child: Text("Use the Up/Down arrows to test different wire sizes instantly.", style: bodyStyle)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: bodyStyle),
                    Expanded(child: Text("Adding a second pipe enables Pull-Through wires in the Box Design menu.", style: bodyStyle)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: bodyStyle),
                    Expanded(child: Text("Use the Up/Down arrows next to Conduit Fill to test different pipe sizes instantly.", style: bodyStyle)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: bodyStyle),
                    Expanded(child: Text("All pipes shown feed into the currently selected box.", style: bodyStyle)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConduitFillCodeScreen()),
              );
            },
            child: const Text(
              "NEC: Learn More",
              style: TextStyle(color: kRed, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: kLight, fontSize: 16)),
          ),
        ],
      ),
    );
  }


  @override
  void didUpdateWidget(covariant _PipeUIDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool pipeIndexChanged = widget.activePipeIndex !=
        _localActivePipeIndex;
    final bool pipeCountChanged = widget.pipes.length != oldWidget.pipes.length;

    bool wiresChanged = false;
    if (widget.pipes.isNotEmpty &&
        oldWidget.pipes.isNotEmpty &&
        _localActivePipeIndex < widget.pipes.length &&
        _localActivePipeIndex < oldWidget.pipes.length) {
      // Content OR length change
      wiresChanged = true;
    }

    if (pipeIndexChanged || pipeCountChanged) {
      setState(() {
        _localActivePipeIndex = widget.activePipeIndex;

        // If a new pipe was added and parent moved index, snap to last pipe safely
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

  Pipe get _activePipe => widget.pipes[_localActivePipeIndex];

  void _updateSelectedWireSummary() {
    if (_activePipe.wires.isEmpty) {
      _selectedWireSummaryKey = null;
      return;
    }

    final summaryMap = _getDeratingSummaryForPipe(_activePipe);
    if (summaryMap.isEmpty) {
      _selectedWireSummaryKey = null;
      return;
    }

    final sortedKeys = summaryMap.keys.toList();
    sortedKeys.sort((a, b) {
      // Helper to get role priority: Hot (0), Neutral (1), Ground (2)
      int getRolePriority(String key) {
        if (key.startsWith("H ")) return 0; // Hot first
        if (key.startsWith("N ")) return 1; // Neutral second
        if (key.startsWith("G ")) return 2; // Ground third
        return 3; // Fallback for unknown
      }

      final rolePriorityA = getRolePriority(a);
      final rolePriorityB = getRolePriority(b);

      // Primary sort: by role (Hot, Neutral, Ground)
      if (rolePriorityA != rolePriorityB) {
        return rolePriorityA.compareTo(rolePriorityB);
      }

      // Secondary sort: if roles are the same, sort by wire size
      // Extract wire size string (e.g., "12 AWG", "1/0 AWG", "250 KCMIL")
      String extractWireSizeString(String key) {
        final parts = key.split(' ');
        // Reconstruct the full wire size string like "14 AWG" or "250 KCMIL"
        // This assumes wire.size is always two components (like "14 AWG" or "250 KCMIL")
        if (parts.length >= 3 && (parts[2] == "AWG" || parts[2] == "KCMIL")) {
          return "${parts[1]} ${parts[2]}";
        } else if (parts.length >= 2) {
          // Fallback if size is a single word, though not expected from ConduitDB structure
          return parts[1];
        }
        return ""; // Should not happen with well-formed keys
      }

      final wireSizeA = extractWireSizeString(a);
      final wireSizeB = extractWireSizeString(b);

      final comparableSizeA = _getComparableWireSizeValueLocal(wireSizeA);
      final comparableSizeB = _getComparableWireSizeValueLocal(wireSizeB);

      // Sort by physical size: Larger wires first (e.g., 1/0 AWG before 1 AWG, 250 KCMIL before 300 KCMIL)
      return comparableSizeB.compareTo(comparableSizeA);
    });

    // Try to preserve current selection if possible
    if (_selectedWireSummaryKey != null && sortedKeys.contains(_selectedWireSummaryKey)) {
      // Keep it
    } else if (sortedKeys.isNotEmpty) {
      // If old key is gone (maybe resized), try to find a key with same role
      final String? oldKey = _selectedWireSummaryKey;
      if (oldKey != null) {
        final rolePrefix = oldKey.substring(0, 2); // e.g. "H ", "N ", "G "
        
        // Try to match role and insulation first
        final parts = oldKey.split(' ');
        final String? insulation = parts.length >= 4 ? parts.sublist(3).join(' ') : null;
        
        String? matchingKey;
        if (insulation != null) {
          matchingKey = sortedKeys.firstWhereOrNull((k) => k.startsWith(rolePrefix) && k.contains(insulation));
        }
        
        // Fallback to just role
        matchingKey ??= sortedKeys.firstWhereOrNull((k) => k.startsWith(rolePrefix));

        if (matchingKey != null) {
          _selectedWireSummaryKey = matchingKey;
        } else {
          _selectedWireSummaryKey = sortedKeys.first;
        }
      } else {
        _selectedWireSummaryKey = sortedKeys.first;
      }
    } else {
      _selectedWireSummaryKey = null;
    }

    // Sync PageController to the selected key's index
    if (_selectedWireSummaryKey != null && _wireSummaryPageController.hasClients) {
      final index = sortedKeys.indexOf(_selectedWireSummaryKey!);
      if (index != -1 && _wireSummaryPageController.page?.round() != index) {
        _wireSummaryPageController.jumpToPage(index);
      }
    }
  }

  // Local helper method to get a comparable numeric value for wire sizes
  // (larger number for physically larger wire)
  int _getComparableWireSizeValueLocal(String wireSize) {
    if (wireSize.contains("AWG")) {
      final String awgPart = wireSize.replaceAll(" AWG", "");
      if (awgPart.contains("/")) { // Handles 1/0, 2/0, etc.
        // Convert X/0 AWG to a negative number for comparison, e.g., 1/0 = -10, 2/0 = -20
        // This makes larger actual wires (smaller AWG number, or X/0) result in a larger comparative value here.
        final int numerator = int.tryParse(awgPart.split('/')[0]) ?? 0;
        return -numerator *
            100; // Multiply by 100 to clearly separate from positive AWG
      }
      // For standard AWG, smaller number means larger wire, so invert for comparable value.
      return (int.tryParse(awgPart) ?? 40) *
          -1; // e.g., 14 AWG -> -14, 12 AWG -> -12
    } else if (wireSize.contains("KCMIL")) {
      // KCMIL values are directly comparable; larger number means larger wire.
      // Offset by a large number to place them distinct from AWG.
      return (int.tryParse(wireSize.replaceAll(" KCMIL", "")) ?? 0) + 10000;
    }
    return 0; // Default or unknown
  }

  Map<String, Map<String, dynamic>> _getDeratingSummaryForPipe(Pipe pipe) {
    if (pipe.wires.isEmpty) return {};

    final wireGroups = <String, List<Wire>>{};
    for (final wire in pipe.wires) {
      final role = wire.isGround ? "G" : (wire.isNeutral ? "N" : "H");
      final key = "$role ${wire.size} ${wire.insulation}";

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
        final finalAmps = math.min(newAmpacity, capAmps75.toDouble());

        int overcurrentLimit = 1000;
        if (firstWire.size == "18 AWG") {
          overcurrentLimit = 10;
        } else if (firstWire.size == "14 AWG") {
          overcurrentLimit = 15;
        } else if (firstWire.size == "12 AWG") {
          overcurrentLimit = 20;
        } else if (firstWire.size == "10 AWG") {
          overcurrentLimit = 30;
        }

        finalBreakerSize = ConduitDB.standardBreakerSizes.lastWhere(
              (s) => s <= finalAmps,
          orElse: () => 0,
        );

        finalBreakerSize = math.min(overcurrentLimit, finalBreakerSize);
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
    if (pipe.size == null) return 0.0;

    final double totalArea = (pipe.pipeType == PipeType.emt
        ? ConduitDB.emtTotalArea
        : ConduitDB.rmcTotalArea)[pipe.size!]!;

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

    final double totalWireArea = pipe.wires.fold(
      0.0,
          (sum, w) => sum + (ConduitDB.wireAreas[w.size]?[w.insulation] ?? 0.0),
    );

    return totalWireArea.isFinite && maxArea > 0 ? (totalWireArea / maxArea) *
        100 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xD8000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        title: const Text(
          'Pipe Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!_hasViewedInfo)
                  AnimatedBuilder(
                    animation: _glowAnimationController,
                    builder: (context, child) {
                      return Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2 + (0.7 * _glowAnimationController.value)),
                            width: 1.2,
                          ),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    setState(() => _hasViewedInfo = true);
                    _showPipeDetailInfoDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: 'pipe-hero',
          child: Material(
            color: kBlack,
            child: Center(
              child: PulsingGlowBorder(
                animationController: _pipeBorderController,
                shape: BoxShape.circle,
                endColor: kSilver,
                isPulsing: false,
                clockwise: true,
                sweepColors: [
                  kSilver.withOpacity(0.80),
                  kRed.withOpacity(0.80),
                  const Color(0xFFFFD54F).withOpacity(0.95),
                  kLight.withOpacity(0.95),
                  kSilver.withOpacity(0.80),
                ],
                sweepStops: const [0.0, 0.45, 0.65, 0.78, 1.0],
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kBlack,
                  ),
                  child: _buildPipeDashboard(),
                ),
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // --- PUSH DOWN ---
                  SizedBox(height: MediaQuery.of(context).size.height * _pushEverythingDownFactor),

                  // --- GROUP A: TOP SECTION (Pipe Info + Top Line) ---
                  _buildPipeInfoSection(),
                  SizedBox(height: _gapInsideTopSection),
                  _buildDivider(),

                  // --- SPACE TO MIDDLE ---
                  SizedBox(height: _gapAboveMiddleSection),

                  // --- GROUP B: MIDDLE SECTION (Wire Summary Wheel) ---
                  KeyedSubtree(
                    key: ValueKey('wireSummary_${widget.activePipeIndex}'),
                    child: _buildWireSummarySection(),
                  ),

                  // --- SPACE TO BOTTOM ---
                  SizedBox(height: _gapAboveBottomSection),

                  // --- GROUP C: BOTTOM SECTION (Bottom Line + Fill Results) ---
                  _buildDivider(),
                  SizedBox(height: _gapInsideBottomSection),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Text(
                          "Conduit Fill",
                          style: TextStyle(
                              color: kLight, fontWeight: FontWeight.bold, fontSize: 26),
                        ),
                      ),
                      _buildSummaryButton(
                        icon: Icons.keyboard_arrow_down,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onResizePipe(false);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryButton(
                        icon: Icons.keyboard_arrow_up,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onResizePipe(true);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${fillPercent.toStringAsFixed(1)}%",
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
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
              onPressed: () => Navigator.of(context).pop(),
              label: "Done",
            ),
          ),
        ),
      ],
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
      infoText += " to $boxSize (Box Fill: ${boxFill.toStringAsFixed(1)}%)";
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSummaryButton(
                icon: Icons.remove,
                onTap: widget.pipes.length > 1 ? widget.onRemovePipe : null,
              ),

              const SizedBox(width: 8),

              _buildSummaryButton(
                icon: Icons.add,
                onTap: widget.onAddPipe,
              ),

              const SizedBox(width: 12),

              SizedBox(width: 140, child: _buildPipeSelectorDropdown()),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          infoText,
          style: const TextStyle(color: Colors.white70, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummaryButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.35,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: kLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: kBlack,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildWireSummarySection() {
    if (_activePipe.wires.isEmpty) {
      return _buildInfoSection("Wire Summary", "Empty");
    }

    final summaryMap = _getDeratingSummaryForPipe(_activePipe);
    if (summaryMap.isEmpty) {
      return _buildInfoSection("Wire Summary", "Empty");
    }

    // If only one wire type, show text + add/remove/resize buttons for that single wire.
    if (summaryMap.length == 1) {
      final onlyEntry = summaryMap.entries.first;
      final data = onlyEntry.value;
      final count = data['count'];
      final wire = data['wire'] as Wire;
      final breaker = data['finalBreakerSize'];

      final role = wire.isGround ? "G" : (wire.isNeutral ? "N" : "H");

      String summaryText =
          "($count) $role #${wire.size.replaceAll(" AWG", "")} ${wire
          .insulation}";

      if (!wire.isGround && !wire.isNeutral && breaker > 0) {
        summaryText += "  ${breaker}A";
      }

      return Column(
        children: [
          const Text(
            "Wire Summary",
            style: TextStyle(
                color: kLight, fontWeight: FontWeight.bold, fontSize: 26),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LEFT COLUMN: Qty [-] and Gauge [v]
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSummaryButton(
                    icon: Icons.remove,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onRemoveWire(wire);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryButton(
                    icon: Icons.keyboard_arrow_down,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onResizeWireGroup(wire, false);
                    },
                  ),
                ],
              ),

              const SizedBox(width: 12),

              Flexible(
                child: Text(
                  summaryText,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 12),

              // RIGHT COLUMN: Qty [+] and Gauge [^]
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSummaryButton(
                    icon: Icons.add,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onAddWire(wire);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryButton(
                    icon: Icons.keyboard_arrow_up,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onResizeWireGroup(wire, true);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    // Multiple wire types: dropdown + add/remove/resize for selected type
    final selectedKey = _selectedWireSummaryKey;
    final selectedData = selectedKey != null ? summaryMap[selectedKey] : null;
    final selectedWire = selectedData?['wire'] as Wire?;

    return Column(
      children: [
        const Text(
          "Wire Summary",
          style: TextStyle(
              color: kLight, fontWeight: FontWeight.bold, fontSize: 26),
        ),
        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LEFT COLUMN: Qty [-] and Gauge [v]
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSummaryButton(
                  icon: Icons.remove,
                  onTap: selectedWire == null
                      ? null
                      : () {
                    HapticFeedback.lightImpact();
                    widget.onRemoveWire(selectedWire);
                  },
                ),
                const SizedBox(height: 12),
                _buildSummaryButton(
                  icon: Icons.keyboard_arrow_down,
                  onTap: selectedWire == null
                      ? null
                      : () {
                    HapticFeedback.mediumImpact();
                    widget.onResizeWireGroup(selectedWire, false);
                  },
                ),
              ],
            ),

            const SizedBox(width: 18),

            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF343838),
                      Color(0xFF262A2A),
                    ],
                  ),

                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kSilver.withAlpha(128)),
                ),
                child: SizedBox(
                  height: 84, // ✅ Increased height for a less cramped look
                  child: Builder(
                    builder: (context) {
                      // Build a stable list of keys in the desired display order.
                      final keys = summaryMap.keys.toList();

                      int rolePriority(String key) {
                        // Prefer to derive role from the Wire in summaryMap (more reliable than string parsing)
                        final data = summaryMap[key];
                        if (data == null) return 3;
                        final wire = data['wire'] as Wire;
                        if (wire.isGround) return 2;     // G last
                        if (wire.isNeutral) return 1;    // N middle
                        return 0;                        // H first
                      }

                      String extractWireSizeStringFromKey(String key) {
                        // If your keys include size like "H 12 AWG", this will work.
                        // If not, we fall back to the Wire.size below.
                        final parts = key.split(' ');
                        if (parts.length >= 3 && (parts[2] == "AWG" || parts[2] == "KCMIL")) {
                          return "${parts[1]} ${parts[2]}";
                        }
                        return "";
                      }

                      int comparableSizeForKey(String key) {
                        // Prefer Wire.size (most reliable)
                        final data = summaryMap[key];
                        if (data != null) {
                          final wire = data['wire'] as Wire;
                          return _getComparableWireSizeValueLocal(wire.size);
                        }
                        // Fallback: attempt parse from key string
                        final sizeStr = extractWireSizeStringFromKey(key);
                        return _getComparableWireSizeValueLocal(sizeStr);
                      }

                      keys.sort((a, b) {
                        // 1) Primary: wire size (larger first)
                        final sa = comparableSizeForKey(a);
                        final sb = comparableSizeForKey(b);
                        if (sa != sb) return sb.compareTo(sa);

                        // 2) Secondary: role within same size (H, N, G)
                        final ra = rolePriority(a);
                        final rb = rolePriority(b);
                        return ra.compareTo(rb);
                      });

                      final initialIndex = (_selectedWireSummaryKey == null)
                          ? 0
                          : keys.indexOf(_selectedWireSummaryKey!);

                      final safeInitialIndex = (initialIndex >= 0) ? initialIndex : 0;

                      return PageView.builder(
                        controller: _wireSummaryPageController,
                        physics: const ClampingScrollPhysics(), // Prevents bouncing/graying out
                        scrollDirection: Axis.vertical,
                        itemCount: keys.length,
                        onPageChanged: (index) {
                          final key = keys[index];
                          setState(() => _selectedWireSummaryKey = key);
                        },
                        itemBuilder: (context, index) {
                          final key = keys[index];
                          final summaryData = summaryMap[key]!;
                          final count = summaryData['count'];
                          final wire = summaryData['wire'] as Wire;
                          final breaker = summaryData['finalBreakerSize'];

                          final role = wire.isGround ? "G" : (wire.isNeutral ? "N" : "H");
                          final shortInsulation = wire.insulation.length > 4
                              ? wire.insulation.substring(0, 4)
                              : wire.insulation;

                          String summaryText =
                              "($count) $role #${wire.size.replaceAll(" AWG", "")} $shortInsulation";
                          if (!wire.isGround && !wire.isNeutral && breaker > 0) {
                            summaryText += "  ${breaker}A";
                          }

                          final isSelected = key == _selectedWireSummaryKey;

                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 120),
                              style: TextStyle(
                                color: isSelected ? kLight : Colors.white54,
                                fontSize: isSelected ? 19 : 16,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                letterSpacing: 0.3,
                                height: 1.35,
                              ),
                              child: Text(summaryText, textAlign: TextAlign.center),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(width: 18),

            // RIGHT COLUMN: Qty [+] and Gauge [^]
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSummaryButton(
                  icon: Icons.add,
                  onTap: selectedWire == null
                      ? null
                      : () {
                    HapticFeedback.lightImpact();
                    widget.onAddWire(selectedWire);
                  },
                ),
                const SizedBox(height: 12),
                _buildSummaryButton(
                  icon: Icons.keyboard_arrow_up,
                  onTap: selectedWire == null
                      ? null
                      : () {
                    HapticFeedback.mediumImpact();
                    widget.onResizeWireGroup(selectedWire, true);
                  },
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildDivider() {
    return SizedBox(
      width: MediaQuery
          .of(context)
          .size
          .width * 0.6,
      child: const Divider(color: kSilver, height: 1),
    );
  }

  Widget _buildInfoSection(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
              color: kLight, fontWeight: FontWeight.bold, fontSize: 26),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 18),
          textAlign: TextAlign.center,
        ),
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
  final int terminalBlockCount; // NEW
  final ValueChanged<int> onTerminalBlockCountChanged; // NEW
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
    required this.terminalBlockCount, // NEW
    required this.onTerminalBlockCountChanged, // NEW
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
  late int _terminalBlockCountLocal; // NEW
  // --- NEW: State for Expansion Tiles ---
  late bool _isVolumeDetailsExpanded; // Renamed from _isDetailedVolumeExpanded
  late bool _isJunctionBoxSizingExpanded;

  // --- NEW: Local state for Junction Box Sizing calculations ---
  double _localMinStraight = 0.0;
  double _localMinAngleLength = 0.0; // Separate for angle pulls
  double _localMinAngleWidth = 0.0; // Separate for angle pulls
  double _localMinEntryDistance = 0.0; // NEW: 6x distance between entries

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
    _terminalBlockCountLocal =
        widget.terminalBlockCount; // NEW: Initialize local terminal block count
    // --- NEW: Initialize Expansion States based on wire size AND box size ---
    _isJunctionBoxSizingExpanded =
        _hasLargeWires; // If large wires, JBS is expanded
    _isVolumeDetailsExpanded = !_hasLargeWires &&
        _isSmallBox; // If no large wires AND small box, Volume Details is expanded

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
    _terminalBlockCountLocal =
        widget.terminalBlockCount; // NEW: Update local terminal block count

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
        if (_terminalBlockCountLocal > 0) { // NEW: Clear terminal block count
          _terminalBlockCountLocal = 0;
          widget.onTerminalBlockCountChanged(0);
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
      double largestLeft = leftWallConduits.reduce(math.max);
      double sumOthersLeft = leftWallConduits.fold(
          0.0, (sum, val) => sum + val) - largestLeft;
      maxLeftRightDimension =
          math.max(maxLeftRightDimension, (largestLeft * 6) + sumOthersLeft);
    }
    if (rightWallConduits.isNotEmpty) {
      double largestRight = rightWallConduits.reduce(math.max);
      double sumOthersRight = rightWallConduits.fold(
          0.0, (sum, val) => sum + val) - largestRight;
      maxLeftRightDimension =
          math.max(maxLeftRightDimension, (largestRight * 6) + sumOthersRight);
    }
    double minAngleLength = maxLeftRightDimension; // Initialize minAngleLength

    // Calculate width requirement (top/bottom walls)
    double maxTopBottomDimension = 0.0;
    List<double> topWallConduits = anglePullConduitsByWall[EntrySide.top] ?? [];
    List<double> bottomWallConduits = anglePullConduitsByWall[EntrySide
        .bottom] ?? [];

    if (topWallConduits.isNotEmpty) {
      double largestTop = topWallConduits.reduce(math.max);
      double sumOthersTop = topWallConduits.fold(0.0, (sum, val) => sum + val) -
          largestTop;
      maxTopBottomDimension =
          math.max(maxTopBottomDimension, (largestTop * 6) + sumOthersTop);
    }
    if (bottomWallConduits.isNotEmpty) {
      double largestBottom = bottomWallConduits.reduce(math.max);
      double sumOthersBottom = bottomWallConduits.fold(
          0.0, (sum, val) => sum + val) - largestBottom;
      maxTopBottomDimension =
          math.max(maxTopBottomDimension, (largestBottom * 6) + sumOthersBottom);
    }
    double minAngleWidth = maxTopBottomDimension; // Initialize minAngleWidth

    // Find the largest angle pull conduit from the back wall
    double largestBackWallAngleConduit = 0.0;
    List<double> backWallConduits = anglePullConduitsByWall[EntrySide.back] ??
        [];
    if (backWallConduits.isNotEmpty) {
      largestBackWallAngleConduit = backWallConduits.reduce(math.max);
    }

    // If there's a largest angle pull conduit from the back, it requires 6x its size
    // in both the length and width dimensions to accommodate the turn.
    if (largestBackWallAngleConduit > 0) {
      minAngleLength = math.max(minAngleLength, largestBackWallAngleConduit * 6);
      minAngleWidth = math.max(minAngleWidth, largestBackWallAngleConduit * 6);
    }

    // NEW: Calculate the 6x distance requirement between entries enclosing same conductor
    // Find the largest conduit involved in ANY angle pull
    double largestAngleTradeSize = 0.0;
    for (final list in anglePullConduitsByWall.values) {
      if (list.isNotEmpty) {
        double wallMax = list.reduce(math.max);
        if (wallMax > largestAngleTradeSize) largestAngleTradeSize = wallMax;
      }
    }

    setState(() {
      _localMinStraight = largestStraightTradeSize * 8;
      _localMinAngleLength = minAngleLength;
      _localMinAngleWidth = minAngleWidth;
      _localMinEntryDistance = largestAngleTradeSize * 6;
    });
  }

  bool _isJunctionBoxViolation() {
    if (widget.selectedBoxSize == null) return false;

    double boxL = 0, boxW = 0;
    final name = widget.selectedBoxSize!;

    // 1. Try to parse "LxWxD" format (standard or custom)
    final reg = RegExp(r'(\d+\.?\d*)x(\d+\.?\d*)x(\d+\.?\d*)');
    final match = reg.firstMatch(name);
    if (match != null) {
      boxL = double.tryParse(match.group(1)!) ?? 0;
      boxW = double.tryParse(match.group(2)!) ?? 0;
    } else {
      // 2. Handle small boxes (4s, 5s) - they generally don't meet JBS requirements for 4AWG anyway
      if (name.startsWith("4s")) { boxL = 4.0; boxW = 4.0; }
      else if (name.startsWith("5s")) { boxL = 4.68; boxW = 4.68; }
      else if (name.startsWith("4o")) { boxL = 4.0; boxW = 4.0; }
    }

    if (boxL == 0 || boxW == 0) return false;

    // Check against requirements
    if (_localMinStraight > 0 && (boxL < _localMinStraight && boxW < _localMinStraight)) return true;
    if (_localMinAngleLength > 0 && (boxL < _localMinAngleLength && boxW < _localMinAngleLength)) return true;
    // Note: This is simplified. NEC 314.28 requires the specific dimension (length vs width) 
    // to match the entry wall. Since we allow the user to pick "Side", we'll check if ANY 
    // dimension fails the largest requirement.
    
    return false;
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
    final int effectivePullThroughCount = math.min(
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
      // 2020/2023 NEC 314.16(B)(5): 1 allowance for first 4, 1/4 for each additional
      if (groundWires.length <= 4) {
        groundingVolume = groundAllowance;
      } else {
        groundingVolume = groundAllowance + (groundAllowance * 0.25 * (groundWires.length - 4));
      }
    }

    // Calculate allowance volumes for devices, clamps, support fittings
    final double clampVolume = (_clampCount > 0 ? 1 : 0) *
        allowanceVolumePerWire; // NEC 314.16(B)(2) one or more = 1 allowance
    final double supportFittingVolume = _supportFittingCount *
        allowanceVolumePerWire; // NEC 314.16(B)(3)
    final double deviceVolume = _deviceCount * 2 *
        allowanceVolumePerWire; // NEC 314.16(B)(4) (2 allowances per yoke)
    final double terminalBlockVolume = _terminalBlockCountLocal *
        allowanceVolumePerWire; // NEW: NEC 314.16(B)(1) (1 allowance per terminal block)


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
        clampVolume + supportFittingVolume + deviceVolume +
        terminalBlockVolume; // NEW: Add terminal block volume

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
      'terminalBlockVolume': terminalBlockVolume, // NEW
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
    const bg = Color(0xFF212121);
    const bodyStyle = TextStyle(color: kLight, fontSize: 16, height: 1.45);

    showDialog(
      context: context,
      builder: (context) {
        String? openSection;

        return StatefulBuilder(
          builder: (context, setState) {
            Widget gap([double h = 8]) => SizedBox(height: h);
            Widget bullet(String text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: bodyStyle),
                  Expanded(child: Text(text, style: bodyStyle)),
                ],
              ),
            );

            Widget sectionTile({required String id, required String title, required List<Widget> children}) {
              return Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  key: PageStorageKey(id),
                  onExpansionChanged: (exp) => setState(() => openSection = exp ? id : null),
                  tilePadding: EdgeInsets.zero,
                  iconColor: kLight,
                  collapsedIconColor: kLight,
                  title: Text(title, style: const TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 17)),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  children: openSection == id ? children : [],
                ),
              );
            }

            return AlertDialog(
              backgroundColor: bg,
              insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
              ),
              title: const Text(
                'Box Design Help',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTile(
                        id: 'sizing_4awg',
                        title: 'Pull & Junction Box Sizing (4 AWG+)',
                        children: [
                          const Text(
                            'Required when any conductor is #4 AWG or larger. Calculated based on raceway entries per NEC 314.28.',
                            style: bodyStyle,
                          ),
                          gap(),
                          bullet('Straight Pull: The box dimension opposite the entry must be 8x the trade size of the largest conduit.'),
                          bullet('Angle/U-Pull: The box dimension on the wall entries enter must be 6x the largest conduit + sum of others on same wall.'),
                          bullet('Distance Rule: Distance between entries enclosing the same conductor must be 6x the trade size.'),
                          gap(),
                          const Text(
                            'The "Min Entry Distance" is the diagonal measurement required between conduit bushings.',
                            style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 15),
                          ),
                        ],
                      ),
                      sectionTile(
                        id: 'sizing_small',
                        title: 'Box Fill (5S and Smaller)',
                        children: [
                          const Text(
                            'Calculated based on volume allowances per NEC 314.16.',
                            style: bodyStyle,
                          ),
                          gap(),
                          bullet('1 allowance per conductor (#14-#6 AWG).'),
                          bullet('1 allowance (largest ground) for the first 4 grounds; 1/4 allowance for each extra ground.'),
                          bullet('2 allowances for each device yoke.'),
                          bullet('1 allowance for internal clamps (one or more).'),
                          bullet('1 allowance for each terminal block.'),
                        ],
                      ),
                      sectionTile(
                        id: 'accessories',
                        title: 'Rings and Pass-Through',
                        children: [
                          bullet('Mud Rings: Adds specific volume to the total available.'),
                          bullet('Extension Rings: Stacks volume; specific to box type (4S vs 5S).'),
                          bullet('Pull-Through Wires: When wires pass through without splice, they count as 0 volume allowances in this calculator.'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => _hasLargeWires ? const JunctionBoxSizingCodeScreen() : BoxFillBasicsCodeScreen()),
                    );
                  },
                  child: const Text("NEC: Learn More", style: TextStyle(color: kRed, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: kLight, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
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
    final terminalBlockVolume = localBoxFillResults['terminalBlockVolume'] as double? ??
        0.0; // NEW
    final extensionRingTotalVolume = localBoxFillResults['extensionRingTotalVolume'] as double? ??
        0.0;

    final bool isJunctionViolation = _hasLargeWires && _isJunctionBoxViolation();
    final int totalNonGroundWires = widget.allWires
        .where((w) => !w.isGround)
        .length; // NEW

    const screenBg = Color(0xFF0E0E0E);
    const appBarBg = Colors.black;
    const cardBg = Color(0xFF242424); // same vibe as info dialogs
    const cardRadius = 18.0; // a little rounder than 12
    const titleTextStyle = TextStyle(
      color: kLight,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.2,
    );

    return Scaffold(
      backgroundColor: screenBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: kLight,
        elevation: 0,
        centerTitle: true,
        title: const Text('Box Design', style: titleTextStyle),
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
            // ... keep your margin and dimensions exactly as you already have ...
            child: Material(
              color: Colors.transparent, // IMPORTANT: we paint our own card
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: Border.all(color: const Color(0xFF5A5A5A), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: Offset(0, 10),
                      color: Color(0x66000000),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // keeps bottom of card always reachable/visible
                      maxHeight: MediaQuery
                          .of(context)
                          .size
                          .height * 0.86,
                      maxWidth: 560, // optional: keeps it from getting too wide on tablets
                    ),
                    child: Column(
                      children: [
                        // SCROLLING CONTENT (everything except Done)
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // --- Box Fill Summary (Always Visible) ---
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF242424), // slightly lighter top
                                        Color(0xFF181818), // darker bottom
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),

                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.45),
                                        blurRadius: 14,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.03),
                                        blurRadius: 8,
                                        spreadRadius: -4,
                                      ),
                                    ],


                                    border: Border.all(
                                      color: const Color(0xFF2E2E2E),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left accent stripe
                                      Container(
                                        width: 1,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Main content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _hasLargeWires
                                                        ? "Sizing: Dimensional (314.28)"
                                                        : "Box Fill: ${widget.selectedBoxSize ?? 'N/A'}",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    softWrap: false,
                                                    style: const TextStyle(
                                                      color: kLight,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  _hasLargeWires
                                                      ? (isJunctionViolation ? "VIOLATION" : "Compliant")
                                                      : "${totalVolume.toStringAsFixed(2)} / ${maxBoxVolume.toStringAsFixed(2)} in³",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  softWrap: false,
                                                  style: TextStyle(
                                                    color: (_hasLargeWires ? isJunctionViolation : isViolation) ? kRed : Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                              if (_hasLargeWires) ...[
                                              if (_localMinStraight > 0)
                                                _buildDetailRow("Min Straight Pull", _localMinStraight, prefix: '>', unit: '"'),
                                              if (_localMinAngleLength > 0)
                                                _buildDetailRow("Min Angle Length", _localMinAngleLength, prefix: '>', unit: '"'),
                                              if (_localMinAngleWidth > 0)
                                                _buildDetailRow("Min Angle Width", _localMinAngleWidth, prefix: '>', unit: '"'),
                                              if (_localMinEntryDistance > 0)
                                                _buildDetailRow("Min Distance Between", _localMinEntryDistance, prefix: '>', unit: '"'),
                                            ] else ...[
                                              _buildDetailRow("Conductors", conductorVolume, prefix: '-'),
                                              if (groundingVolume > 0)
                                                _buildDetailRow("Grounding", groundingVolume, prefix: '-'),
                                              if (deviceVolume > 0)
                                                _buildDetailRow("Devices ($_deviceCount)", deviceVolume, prefix: '-'),
                                              if (clampVolume > 0)
                                                _buildDetailRow("Clamps ($_clampCount)", clampVolume, prefix: '-'),
                                              if (supportFittingVolume > 0)
                                                _buildDetailRow(
                                                  "Support Fittings ($_supportFittingCount)",
                                                  supportFittingVolume,
                                                  prefix: '-',
                                                ),
                                              if (terminalBlockVolume > 0)
                                                _buildDetailRow(
                                                  "Terminal Blocks ($_terminalBlockCountLocal)",
                                                  terminalBlockVolume,
                                                  prefix: '-',
                                                ),
                                              if (_selectedMudRing != null)
                                                _buildDetailRow(
                                                  "Mud Ring ($_selectedMudRing)",
                                                  ConduitDB.mudRingVolumes[_selectedMudRing!] ?? 0.0,
                                                  prefix: '+',
                                                ),
                                              if (extensionRingTotalVolume > 0)
                                                _buildDetailRow(
                                                  "Extension Rings ($_extensionRingCount x "
                                                      "${_selectedExtensionRingType?.split(" ")[1] ?? ''} "
                                                      "${_selectedExtensionRingType?.split(" ")[2] ?? ''})",
                                                  extensionRingTotalVolume,
                                                  prefix: '+',
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // --- ExpansionTile: Pull and Junction Box Sizing (#4 AWG or larger) ---
                                ExpansionTile(
                                  key: const PageStorageKey('junctionBoxSizingTile'),
                                  tilePadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  childrenPadding: EdgeInsets.zero,
                                  trailing: const SizedBox.shrink(),
                                  initiallyExpanded: _isJunctionBoxSizingExpanded,
                                  onExpansionChanged: (expanded) {
                                    setState(() {
                                      if (_hasLargeWires) {
                                        _isJunctionBoxSizingExpanded = expanded;
                                        if (expanded) { _isVolumeDetailsExpanded = false; }
                                      } else {
                                        _isJunctionBoxSizingExpanded = false;
                                      }
                                    });
                                  },
                                  title: Padding(
                                    padding: const EdgeInsets.only(left: 35),
                                    child: Center(
                                      child: _buildExpansionTileTitle(
                                        "Pull and Junction Box Sizing",
                                        isEnabled: _hasLargeWires,
                                        disabledMessage: !_hasLargeWires ? "Only applicable for #4 AWG and larger wires" : null,
                                      ),
                                    ),
                                  ),
                                  children: _hasLargeWires
                                      ? [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "NEC 314.28 Requirements:",
                                                  style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  "Set the 'Pull Type' for each pipe to calculate minimum box dimensions.",
                                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                                                ),
                                                const SizedBox(height: 16),
                                                ...widget.pipes.asMap().entries.map((entry) {
                                                  return _buildPullTypeAndEntrySideSelector(entry.value, entry.key, isEnabled: true);
                                                }).toList(),
                                                const Divider(color: Colors.white24, height: 32),
                                                const Text(
                                                  "Calculated Minimums:",
                                                  style: TextStyle(color: kLight, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 8),
                                                if (_localMinStraight > 0)
                                                  _buildDetailRow("Min Straight Pull Length", _localMinStraight, prefix: '>', unit: '"'),
                                                if (_localMinAngleLength > 0)
                                                  _buildDetailRow("Min Angle/U-Pull Length", _localMinAngleLength, prefix: '>', unit: '"'),
                                                if (_localMinAngleWidth > 0)
                                                  _buildDetailRow("Min Angle/U-Pull Width", _localMinAngleWidth, prefix: '>', unit: '"'),
                                                if (_localMinEntryDistance > 0)
                                                  _buildDetailRow("Min Entry Distance", _localMinEntryDistance, prefix: '>', unit: '"'),
                                              ],
                                            ),
                                          ),
                                        ]
                                      : [],
                                ),

                                const SizedBox(height: 12),

                                // --- ExpansionTile: Volume Details (5S and smaller) ---
                                ExpansionTile(
                                  key: const PageStorageKey(
                                      'volumeDetailsTile'),
                                  tilePadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity
                                      .trailing,
                                  childrenPadding: EdgeInsets.zero,
                                  trailing: const SizedBox.shrink(),
                                  // Custom trailing controlled by title
                                  initiallyExpanded: _isVolumeDetailsExpanded,
                                  onExpansionChanged: (expanded) {
                                    setState(() {
                                      final bool shouldEnable = !_hasLargeWires &&
                                          _isSmallBox;
                                      if (shouldEnable) { // Only expand if it's applicable
                                        _isVolumeDetailsExpanded = expanded;
                                        if (expanded) {
                                          _isJunctionBoxSizingExpanded =
                                          false;
                                        }
                                      } else {
                                        _isVolumeDetailsExpanded =
                                        false; // Force collapsed if not applicable
                                      }
                                    });
                                  },
                                  title: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 35),
                                    child: Center(
                                      child: Builder( // Using Builder to use context for `Theme`
                                          builder: (context) {
                                            final bool shouldEnable = !_hasLargeWires &&
                                                _isSmallBox;
                                            String disabledMessage = "";
                                            if (_hasLargeWires) {
                                              disabledMessage =
                                              "Not applicable for #4 AWG and larger wires";
                                            } else if (!_isSmallBox) {
                                              disabledMessage =
                                              "Not applicable for large boxes with small wires";
                                            }

                                            return _buildExpansionTileTitle(
                                              "5S and Smaller Boxes",
                                              isEnabled: shouldEnable,
                                              disabledMessage: disabledMessage,

                                            );
                                          }
                                      ),
                                    ),
                                  ),
                                  children: (!_hasLargeWires && _isSmallBox)
                                      ? [
                                    // Pull-Through Wires (only if multiple pipes)
                                    if (totalNonGroundWires > 0 &&
                                        widget.pipes.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 6, 12, 0),
                                        child: _buildAllowanceStepper(
                                          "Pull-Through Wires (total non-ground: $totalNonGroundWires)",
                                          _pullThroughWireCountLocal,
                                              (c) {
                                            setState(() =>
                                            _pullThroughWireCountLocal = c);
                                            widget
                                                .onPullThroughCountChanged(
                                                c);
                                          },
                                          max: totalNonGroundWires,
                                          isEnabled: true,
                                        ),
                                      ),
                                    if (totalNonGroundWires > 0 &&
                                        widget.pipes.length > 1)
                                      const Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            16, 0, 16, 10),
                                        child: Text(
                                          "Use this when conductors pass through without splice or termination.",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),

                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 0, 12, 0),
                                      child: _buildMudRingSelector(
                                          isEnabled: true),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 0, 12, 0),
                                      child: _buildExtensionRingSelectionAndStepper(
                                          isEnabled: true),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 0, 12, 0),
                                      child: _buildAllowanceStepper(
                                        "Devices (switches/outlets)",
                                        _deviceCount,
                                            (c) {
                                          setState(() => _deviceCount = c);
                                          widget.onDeviceCountChanged(c);
                                        },
                                        isEnabled: true,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 0, 12, 0),
                                      child: _buildAllowanceStepper(
                                        "Internal Cable Clamps",
                                        _clampCount,
                                            (c) {
                                          setState(() => _clampCount = c);
                                          widget.onClampCountChanged(c);
                                        },
                                        max: 1,
                                        isEnabled: true,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 0, 12, 0),
                                      child: _buildAllowanceStepper(
                                        "Support Fittings (studs/hickeys)",
                                        _supportFittingCount,
                                            (c) {
                                          setState(() =>
                                          _supportFittingCount = c);
                                          widget
                                              .onSupportFittingCountChanged(
                                              c);
                                        },
                                        isEnabled: true,
                                      ),
                                    ),
                                    Padding( // NEW: Terminal Blocks Stepper
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 0, 12, 12),
                                      child: _buildAllowanceStepper(
                                        "Terminal Blocks",
                                        _terminalBlockCountLocal,
                                            (c) {
                                          setState(() =>
                                          _terminalBlockCountLocal = c);
                                          widget
                                              .onTerminalBlockCountChanged(c);
                                        },
                                        isEnabled: true,
                                      ),
                                    ),
                                    // NEW
                                  ]
                                      : const <Widget>[],
                                ),

                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),


                        // PINNED BOTTOM EDGE + DONE BUTTON (ALWAYS VISIBLE)
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            border: Border(
                              top: BorderSide(
                                  color: Color(0xFF3A3A3A), width: 1.2),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: SafeArea(
                            top: false,
                            child: SizedBox(
                              width: double.infinity,
                              child: _StyledButton(
                                onPressed: () => Navigator.of(context).pop(),
                                label: "Done",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
  Widget _buildExpansionTileTitle(String title, {
    required bool isEnabled,
    String? disabledMessage,
  }) {
    final titleColor = isEnabled ? kLight : Colors.grey[600];
    final subColor = Colors.grey[600];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF202020), // header bar
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
          if (!isEnabled && disabledMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                disabledMessage,
                style: TextStyle(
                  color: subColor,
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
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

  List<Widget> _buildConductorDetails(List<Wire> allWires,
      {String prefix = '-'}) {
    if (allWires.isEmpty) return [];

    final wireGroups = <String, int>{};
    for (final wire in allWires) {
      if (!wire
          .isGround) { // Only count non-ground conductors for this detail list
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
      final volume = count *
          allowanceVolumePerWire; // Calculate volume for display
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 2, bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("  - ($count) $description",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text("${prefix}${volume.toStringAsFixed(2)} in³",
                // Display volume with prefix
                style: const TextStyle(
                    color: kLight, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }).toList();
  }


  Widget _buildDetailRow(String label, double? value, {String? prefix, String unit = "in³"}) {
    if (value == null || value == 0) return const SizedBox.shrink();

    final p = (prefix ?? '').trim();
    final Color valueColor = kLight;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 4.0, top: 6, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                color: Color(0xFFE2E2E2),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              '$p${value.toStringAsFixed(2)} $unit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class PulsingGlowBorder extends StatelessWidget {
  final AnimationController animationController;
  final BoxShape shape;
  final Widget child;

  // Existing params
  final Color startColor;
  final Color? endColor;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final bool isPulsing;

  // Optional per-call sweep override (pipe detail)
  final List<Color>? sweepColors;
  final List<double>? sweepStops;

  // NEW: rotation direction control (pipe detail can be clockwise)
  final bool clockwise;

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
    this.sweepColors,
    this.sweepStops,
    this.clockwise = false, // keep old behavior by default
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEnd = endColor ?? startColor;

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        final rotation = (clockwise ? 1.0 : -1.0) * animationController.value *
            2 * math.pi;

        // ✅ DEFAULT is back to simple start/end/start (NO yellow unless you pass it)
        final List<Color> colors = sweepColors ??
            <Color>[
              startColor,
              effectiveEnd,
              startColor,
            ];

        final List<double> stops = sweepStops ?? const <double>[0.0, 0.7, 1.0];
        final bool validStops = stops.length == colors.length;

        final double pulse = isPulsing
            ? (0.55 +
            0.45 * (0.5 + 0.5 * math.sin(animationController.value * 2 * math.pi)))
            : 0.65;

        return Container(
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : borderRadius,
            gradient: SweepGradient(
              colors: validStops ? colors : <Color>[
                startColor,
                effectiveEnd,
                startColor
              ],
              stops: validStops ? stops : const <double>[0.0, 0.7, 1.0],
              transform: GradientRotation(rotation),
            ),
          ),
          child: Container(
            margin: EdgeInsets.all(borderWidth),
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: shape == BoxShape.circle ? null : borderRadius,
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  spreadRadius: 1,
                  color: effectiveEnd.withOpacity(0.35 * pulse),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}


class _WireStepper extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final double glowValue; // NEW
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const _WireStepper({
    required this.label,
    required this.count,
    required this.color,
    this.glowValue = 0.0,
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
        border: Border.all(
          color: Color.lerp(color, kLight, glowValue) ?? color,
          width: 1.0 + (glowValue * 1.5), // Subtle thickening during glow
        ),
        boxShadow: [
          if (glowValue > 0)
            BoxShadow(
              color: color.withOpacity(0.5 * glowValue),
              blurRadius: 8 * glowValue,
              spreadRadius: 1 * glowValue,
            )
        ],
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

  const _StyledDropdown({
    this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.isActive = false,
    this.isEnabled = true,
    this.iconColor,
    this.hintColor,
  });

  String _labelFor(String? v) {
    if (v == null) return "";
    // Try to find the matching item and extract its Text label if possible
    for (final it in items) {
      if (it.value == v) {
        final child = it.child;
        if (child is Text) return child.data ?? v;
        return v;
      }
    }
    return v;
  }

  Future<void> _openMenu(BuildContext context) async {
    if (!isEnabled || onChanged == null) return;

    // ✅ haptic BEFORE opening
    HapticFeedback.mediumImpact();

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Overlay
        .of(context)
        .context
        .findRenderObject() as RenderBox;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      elevation: 10,
      color: const Color(0xFF1F2323),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: kSilver.withAlpha(120), width: 1.2),
      ),
      items: items.map((it) {
        final v = it.value;
        final isSel = (v == value);
        final label = _labelFor(v);

        Color textColor; // Declare textColor here

        if (v ==
            "78-86°F") { // This is the specific item we want to always be green
          textColor = Colors.green; // ALWAYS GREEN FOR THIS ITEM
        } else {
          // For all other items, apply the selection color logic
          textColor = isSel ? kLight : Colors.white70;
        }

        return PopupMenuItem<String>(
          value: v,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label.isEmpty ? (v ?? "") : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor, // Use the dynamically determined color
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isSel) const Icon(Icons.check, size: 18, color: kLight),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      // ✅ haptic on selection
      HapticFeedback.selectionClick();
      onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText =
    (value == null || value!.isEmpty) ? hint : _labelFor(value);

    // Closed field stays the same vibe as your original
    return SizedBox(
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: isEnabled ? () => _openMenu(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isEnabled
                    ? (isActive
                    ? [kRed, const Color(0xFFD43D37)]
                    : const [Color(0xFF4E4E52), Color(0xFF2C3030)])
                    : [Colors.grey[800]!, Colors.grey[850]!],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kSilver.withAlpha(128), width: 1.1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: (value == null || value!.isEmpty)
                          ? (isEnabled
                          ? (hintColor ?? Colors.white70)
                          : Colors.grey[600])
                          : kLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: isEnabled ? (iconColor ?? kLight) : Colors.grey[600],
                ),
              ],
            ),
          ),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      backgroundColor: const Color(0xFF1F2323),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: kSilver.withAlpha(120), width: 1.2),
      ),
      title: const Center(
        child: Text(
          "Select Pipe Size & Type",
          style: TextStyle(
            color: kLight,
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      buttonPadding: EdgeInsets.zero,
      actionsAlignment: MainAxisAlignment.end,
      backgroundColor: const Color(0xFF1F2323),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: kSilver.withAlpha(120), width: 1.2),
      ),

      title: Center(child: Text(
          widget.isMoreWiresScreen
              ? "Select KCMIL Wire & Material"
              : "Select Wire Size & Material",
          style: const TextStyle(color: kLight)
      )),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery
            .of(context)
            .size
            .height * 0.55, // <- shrink/raise this (0.55, 0.50, etc.)
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Material Toggles (Copper / Aluminum)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F2F),
                // optional: slightly darker than before
                borderRadius: BorderRadius.circular(10),
              ),
              child: ToggleButtons(
                isSelected: [
                  _selectedMaterial == ConductorMaterial.copper,
                  _selectedMaterial == ConductorMaterial.aluminum,
                ],
                onPressed: (index) {
                  setState(() {
                    _selectedMaterial =
                    index == 0 ? ConductorMaterial.copper : ConductorMaterial
                        .aluminum;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                selectedColor: kLight,
                color: Colors.white70,
                fillColor: kRed,
                selectedBorderColor: kRed,
                borderColor: kSilver,
                constraints: const BoxConstraints(minHeight: 38, minWidth: 98),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Copper", style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Aluminum", style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],

              ),
            ),


            const SizedBox(height: 8),
            const Divider(color: kSilver),

            // ✅ Scrollable list lives here (no shrinkWrap, no SingleChildScrollView)
            Expanded(
              child: ListView.builder(
                itemCount: widget.sizes.length,
                itemBuilder: (context, index) {
                  final size = widget.sizes[index];

                  final hasDataForMaterial =
                      (_selectedMaterial == ConductorMaterial.copper &&
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
                                .grey[600],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: IconButton(
                            icon: Icon(
                              Icons.circle_outlined,
                              color: hasDataForMaterial
                                  ? Colors.green
                                  : Colors.grey[700],
                            ),
                            onPressed: hasDataForMaterial
                                ? () =>
                                widget.onSelect(size, _selectedMaterial)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 🔻 Bottom Action Area
            if (!widget.isMoreWiresScreen) ...[
              const Divider(color: kSilver),

              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: widget.onShowMoreWires,
                        child: const Text(
                          "More wires…",
                          style: TextStyle(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: kLight,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              ...[
                const Divider(color: kSilver),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Back",
                      style: TextStyle(
                        color: kLight,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}