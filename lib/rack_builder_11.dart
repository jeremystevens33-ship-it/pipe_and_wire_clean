import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'rack_state.dart';
import 'keypad_5.dart';
import 'keypad_6.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_menu_screen.dart';
import 'bender_picker_dialog.dart';
import 'box_layout_mode.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => RackState(),
      child: const RackBuilder11TestApp(),
    ),
  );
}

class RackBuilder11TestApp extends StatelessWidget {
  const RackBuilder11TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rack Builder 11 Test',
      theme: ThemeData.dark(),
      home: const RackBuilderScreen(),
    );
  }
}
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50); // Added kGreen constant

class RackBuilderScreen extends StatefulWidget {
  const RackBuilderScreen({
    super.key,
    this.initialMarkA,
    this.initialMarkB,
    this.initialCut,
    this.initialAngle,
    this.initialGain,
    this.initialTakeup,

    // Offset Starting Point preload
    this.initialDistance,
    this.initialOffsetHeight,
    this.initialHorizontalRoll,
    this.initialOverallLength,
    this.initialSpacing,
    this.initialPipeCount,
    this.initialPipeSizes,
    this.initialFullStick = false,
    this.startInOffsetMode = false,
    this.startInRollingOffsetMode = false,
    this.initialDirection,
    this.initialSpacingIsC2C = true,

    // Box Layout Integration
    this.startFromBoxTransition = false,
    this.boxLayoutPipeSizes,
    this.boxLayoutSpacing,
    this.boxLayoutIsCenterToCenter = false,
    this.boxLayoutConduitType,
  });

  final double? initialMarkA;
  final double? initialMarkB;
  final double? initialCut;
  final double? initialAngle;
  final double? initialGain;
  final double? initialTakeup;

  final double? initialDistance;
  final double? initialOffsetHeight;
  final double? initialHorizontalRoll;
  final double? initialOverallLength;
  final double? initialSpacing;
  final int? initialPipeCount;
  final List<String>? initialPipeSizes;
  final bool initialFullStick;
  final bool startInOffsetMode;
  final bool startInRollingOffsetMode;
  final int? initialDirection;
  final bool initialSpacingIsC2C;

  final bool startFromBoxTransition;
  final List<String>? boxLayoutPipeSizes;
  final double? boxLayoutSpacing;
  final bool boxLayoutIsCenterToCenter;
  final String? boxLayoutConduitType;


  @override
  State<RackBuilderScreen> createState() => _RackBuilderScreenState();
}

class _RackBuilderScreenState extends State<RackBuilderScreen> with TickerProviderStateMixin {
  late final RackState rack;
  final ScrollController _scrollCtl = ScrollController();
  final ScrollController _hubScrollCtl = ScrollController();

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

  static const double designW = 1920, designH = 1080;

  int _currentSet = 0;
  bool _isNextRackMode = false;
  bool _isParallel90sMode = false;
  bool _isOffsetMode = false;
  bool _showInfo = false;
  bool _rollingNeedsDirection = false;
  bool _showOffsetInputs = true;
  bool _offsetMeasurementsExpanded = true;
  bool _showRackSetupStart = true;
  bool _showRackSetupOutput = false;
  bool _isRackSetupExpanded = true;
  bool _isRackBenderExpanded = false;
  bool _isRackBendTypeExpanded = false;
  bool _rackSpacingIsCenterToCenter = false;
  bool _offsetStartedFromRackSetup = false;
  bool _showRackResults = false;
  int _rackPipeCount = 0;
  int _selectedRackPipe = 0;
  String _rackConduitType = 'EMT';
  String _rackDefaultPipeSize = ''; // Clear default
  String? _selectedRackBenderBrand;
  bool _skipRackBenderForNow = false;
  bool _parallel90ShowResults = false;
  bool _showParallel90Measurements = true;
  String _parallel90Direction = 'right';
  bool _isKick90sMode = false;
  bool _showKickMeasurements = true;
  bool _showKickTypeSelector = false;
  bool _choosingNextBend = false;
  bool _isProjectHubVisible = false;
  bool _showHubGuidance = true;
  Timer? _hubGuidanceTimer;

  String _selectedKickStyle = 'Across';
  String _selectedKickType = 'Across';

  bool _hubRecentlyUpdated = false;
  int? _editingSegmentIndex;
  int? _lastTappedSegmentIndex;
  int? _editingSupportIndex;
  final Set<int> _expandedHubIndices = {};
  bool _isAddingStraightSegment = false;
  int _straightSticksCount = 1;
  bool _startingPointFullStick = false;
  bool _skipStartingPoint = false;
  String _startingPointMode = 'Straight'; // 'Straight' or '90Up'

  bool _showKickTypeCard = true;
  bool _kickTypeConfirmed = false;
  bool _kickMeasurementsExpanded = true;
  bool _showKickBendingMethodCard = false;
  bool _showTravelField = false;
  bool _kickBendingMethodConfirmed = false;
  bool _showOffsetBendingMethod = false;
  bool _showOffsetGeometryResults = false;
  bool _spacingInteracted = false;
  bool _spacingErrorGlow = false;
  bool _benderWarningActive = false;
  bool _showKickResultAlternative = false;
  Timer? _kickResultTimer;
  bool get _isRackBenderSetupComplete => _selectedRackBenderBrand != null;

  String _kickDirection = 'right';
  bool _rackNextBendMode = false;
  bending_data.BendingMethod _kickMarkMethod =
      bending_data.BendingMethod.centerline;
  bending_data.Bender? _selectedRackBender;
  String? _rackBenderMatchError;
  final Map<String, bending_data.Bender> _rackBenderByPipeKey = {};
  final List<String> _rackPipeSizes = [];
  String _rackBenderMemoryKey() {
    return '${_rackConduitType}_${_selectedRackPipeSizeKey()}';
  }
  String get _offsetAssetPath {
    if (rack.offsetDirectionSign == -1) {
      return 'assets/images/rack_builder/parallel_offset_left.png';
    } else if (rack.offsetDirectionSign == 1) {
      return 'assets/images/rack_builder/parallel_offset_right.png';
    }
    return ''; // Placeholder for Up/Down
  }
  // --- Custom Bender State ---
  // --- Custom Bender State ---
  bool _isEditMode = false;
  bool _isNewBender = false; // Flag to distinguish between Creating and Editing
  final List<bending_data.Bender> _customBenders = [];
  List<Map<String, String>> _allBrands = [];
  bool _isNameEntryMode = false;
  String _customBenderName = '';
  final TextEditingController _customNameCtl = TextEditingController();

  final TextEditingController rackPipeCountCtl = TextEditingController();
  final TextEditingController runC2C = TextEditingController();
  final TextEditingController boxC2C = TextEditingController();
  final TextEditingController stubCtl = TextEditingController();
  final TextEditingController kickStubCtl = TextEditingController();
  final TextEditingController legCtl = TextEditingController();
  final TextEditingController offsetDistanceCtl = TextEditingController();
  final TextEditingController offsetHeightCtl = TextEditingController();
  final TextEditingController offsetOverallCtl = TextEditingController();
  final TextEditingController offsetAngleCtl = TextEditingController();
  final TextEditingController kickHeightCtl = TextEditingController();
  final TextEditingController kickAngleCtl = TextEditingController();
  final TextEditingController kickMatchBendCtl = TextEditingController();
  final TextEditingController kickLegCtl = TextEditingController();

  // Custom Bender Controllers
  final TextEditingController takeUpCtl = TextEditingController();
  final TextEditingController gainCtl = TextEditingController();
  final TextEditingController radiusCtl = TextEditingController();
  final TextEditingController setbackCtl = TextEditingController();
  final TextEditingController travelCtl = TextEditingController();
  final TextEditingController nextRackDistanceCtl = TextEditingController();
  final TextEditingController straightRunLengthCtl = TextEditingController();
  final TextEditingController supportPosCtl = TextEditingController();
  final TextEditingController distanceFromBoxCtl = TextEditingController();

  final TextEditingController rollingVerticalCtl = TextEditingController();
  final TextEditingController rollingHorizontalCtl = TextEditingController();
  final TextEditingController rollingDistanceCtl = TextEditingController();
  final TextEditingController rollingOverallCtl = TextEditingController();
  final TextEditingController rollingAngleCtl = TextEditingController();
  final TextEditingController startingPointDistanceCtl = TextEditingController();
  final TextEditingController wallToSupportCtl = TextEditingController();
  final TextEditingController firstSupportFromBoxCtl = TextEditingController();
  final TextEditingController rackDefaultPipeSizeCtl = TextEditingController();
  final TextEditingController firstSupportPosCtl = TextEditingController();

  // --- VISUALIZATION TUNING CONTROL CENTER ---
  // Adjust these to align assets perfectly for every direction.

  // 0. GLOBAL (Affects everything: Graphic, Dots, Marks)
  static const double visualGlobalYShift = 30.0;
  static const double dotsAndPipesYShift = -40.0; // Moves dots and main graphic together

  // 1. MAIN GRAPHIC (Large pipe set)
  static const double mainGraphicXShift = 20.0;
  static const double mainGraphicYShift = -200.0;
  static const double mainGraphicScale = 0.95;

  // 2. MEASURE FROM THIS END (Text & Arrow)
  static const double measureTextXShift = 95;

  // 3. LEFT OFFSET (Direction: Left)
  static const double leftOffsetDotShift = 335.0;
  static const double leftOffsetMarkShift = 180.0;
  static const double leftOffsetPipeShift = 350.0;
  static const double leftOffsetPipeScaleX = 0.97;

  // 4. RIGHT OFFSET (Direction: Right)
  static const double rightOffsetDotShift = 0.0;
  static const double rightOffsetMarkShift = 180.0;
  static const double rightOffsetPipeShift = 350.0;
  static const double rightOffsetPipeScaleX = .97;

  // 5. STRAIGHT OFFSET (Direction: Up)
  static const double upOffsetDotShift = 0.0;
  static const double upOffsetMarkShift = 0.0;
  static const double upOffsetPipeShift = 0.0;
  static const double upOffsetPipeScaleX = 0.9;

  // --- BASE COORDINATES (Reference only) ---
  static const double dotX = 15; // Left-side start
  static const double dotXRight = 1740; // Right-side start (90s)
  static const double dotY1 = 565, dotY2 = 375, dotY3 = 190;
  static const double bottomAY = 865,
      bottomBX = 1000,
      bottomAX = 500.0,
      bottomCX = 20;
  static const double kickPipesVerticalOffset = -150.0;
  static const double measurementPipeOffsetY = 80.0;
  static const double pipeVisualizationVerticalOffset = 0.0;
  // -------------------------------------------------------------

  bool _isKeypadVisible = false;
  TextEditingController? _activeController;
  bool _clearOnNextInput = false;
  void _sendPipeProgressionOffsetsToRackState() {
    // Sync _rackPipeSizes with _rackPipeCount first to prevent RangeErrors
    while (_rackPipeSizes.length < _rackPipeCount) {
      _rackPipeSizes.add(_rackDefaultPipeSize.isEmpty ? '1/2"' : _rackDefaultPipeSize);
    }
    if (_rackPipeSizes.length > _rackPipeCount && _rackPipeCount > 0) {
      _rackPipeSizes.removeRange(_rackPipeCount, _rackPipeSizes.length);
    }

    final List<double> offsets = List.generate(_rackPipeCount, (_) => 0.0);
    final Map<int, double> ods = {};

    double running = 0.0;

    for (int i = 0; i < _rackPipeCount; i++) {
      final String sizeStr = _rackPipeSizes[i];
      ods[i] = _rackPipeOd(sizeStr);

      if (i > 0) {
        final enteredSpacing = RackState.parseInches(runC2C.text);
        double gap;

        if (_rackSpacingIsCenterToCenter) {
          gap = enteredSpacing;
        } else {
          final leftOd = _rackPipeOd(_rackPipeSizes[i - 1]);
          final rightOd = _rackPipeOd(_rackPipeSizes[i]);
          gap = enteredSpacing + (leftOd / 2) + (rightOd / 2);
        }

        running += gap;
        offsets[i] = running;
      }
    }

    rack.setPipeODs(ods);
    rack.setPipeProgressionOffsets(offsets, sizes: _rackPipeSizes);

    // AUTOMATIC BENDER SYNC: If a brand is selected, ensure math state has the correct CLR for this size/type
    if (_selectedRackBenderBrand != null) {
      final brand = _selectedRackBenderBrand!;
      final sizeKey = _selectedRackPipeSizeKey();
      final conduitType = _rackBendingConduitType();

      final allBenders = [...bending_data.benderDatabase, ..._customBenders];
      final bender = allBenders.firstWhereOrNull(
        (b) => b.brand == brand && b.conduitSize == sizeKey && b.conduitType == conduitType
      );

      if (bender != null) {
        rack.setParallel90BenderData(
          gain: bender.gain,
          takeup: bender.deduct,
          clr: bender.clr,
          pipeOD: _rackPipeOd(_selectedRackPipeSizeDisplay()),
          brand: brand,
        );
      }
    }
  }
  @override
  void initState() {
    super.initState();
    rack = Provider.of<RackState>(context, listen: false);
    _updateBrandDropdown();
    _loadCustomBenders();

    takeUpCtl.addListener(_updateSetback);
    gainCtl.addListener(_updateSetback);
    gainCtl.addListener(_updateRadiusFromGain);
    radiusCtl.addListener(_updateGainFromRadius);

    // Initial state: Focus on Pipe Count, but hide keypad so user can read info bar
    _activeController = rackPipeCountCtl;
    _isKeypadVisible = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.startFromBoxTransition) {
        setState(() {
          _rackPipeCount = widget.boxLayoutPipeSizes?.length ?? 0;
          _rackPipeSizes.clear();
          if (widget.boxLayoutPipeSizes != null) {
            _rackPipeSizes.addAll(widget.boxLayoutPipeSizes!);
          }
          _rackDefaultPipeSize = _rackPipeSizes.isNotEmpty ? _rackPipeSizes.first : '1/2"';
          
          final double spacing = widget.boxLayoutSpacing ?? 0.0;
          runC2C.text = RackState.inchFmt(spacing);
          _rackSpacingIsCenterToCenter = widget.boxLayoutIsCenterToCenter;
          _rackConduitType = widget.boxLayoutConduitType ?? 'EMT';
          
          rackPipeCountCtl.text = _rackPipeCount.toString();
          rackDefaultPipeSizeCtl.text = _rackDefaultPipeSize;
          distanceFromBoxCtl.text = '0"';

          rack.initializeFromBoxLayout(
            pipeSizes: _rackPipeSizes,
            spacing: spacing,
            isCenterToCenter: _rackSpacingIsCenterToCenter,
            conduitType: _rackConduitType,
          );
          
          _showRackSetupOutput = true;
          _isRackSetupExpanded = false;
          _isRackBenderExpanded = true;
          _isRackBendTypeExpanded = false;
        });
        _sendPipeProgressionOffsetsToRackState();
      }

      // Offset Starting Point preload path.
      if (widget.startInOffsetMode || widget.startInRollingOffsetMode) {
        _showRackSetupStart = false;

        _isOffsetMode = true;
        _isNextRackMode = true;
        _showRackSetupOutput = true; 
        
        _rackConduitType = widget.boxLayoutConduitType ?? 'EMT';
        if (_rackConduitType == 'Rigid') _rackConduitType = 'RMC';
        rack.setConduitType(_rackConduitType);

        _rackSpacingIsCenterToCenter = widget.initialSpacingIsC2C;
        if (widget.initialDirection == -1) {
          rack.startOffsetLeft();
        } else if (widget.initialDirection == 1) {
          rack.startOffsetRight();
        } else if (widget.initialDirection == 2) {
          rack.startOffsetDown();
        } else {
          rack.startOffsetUp();
        }

        setState(() {
          _rackPipeCount = widget.initialPipeCount ?? 3;
          _rackPipeSizes.clear();
          _rackPipeSizes.addAll(widget.initialPipeSizes ?? []);
          
          // Guard: Sync sizes list immediately
          while (_rackPipeSizes.length < _rackPipeCount) {
            _rackPipeSizes.add(_rackDefaultPipeSize.isEmpty ? '1/2"' : _rackDefaultPipeSize);
          }

          runC2C.text = RackState.inchFmt(widget.initialSpacing ?? 2.0);
          
          _showRackResults = true;
          _showOffsetInputs = false;
        });

        if (widget.startInRollingOffsetMode) {
          _rollingNeedsDirection = true;
          rack.setFullStick(widget.initialFullStick);

          rack.setRollingOffsetInputs(
            distanceToObstruction: widget.initialDistance ?? 0,
            verticalOffset: widget.initialOffsetHeight ?? 0,
            horizontalOffset: widget.initialHorizontalRoll ?? 0,
            overallLengthValue: widget.initialOverallLength ?? 0,
            bendAngleValue: widget.initialAngle ?? 0,
          );
        } else {
          rack.setFullStick(widget.initialFullStick);
          rack.setOffsetInputs(
            distanceToObstruction: widget.initialDistance ?? 0,
            offsetHeightValue: widget.initialOffsetHeight ?? 0,
            overallLengthValue: widget.initialOverallLength ?? 0,
            bendAngleValue: widget.initialAngle ?? 0,
          );
        }
      }

      if (widget.initialSpacing != null) {
        runC2C.text = RackState.inchFmt(widget.initialSpacing!);
        rack.setSpacing(widget.initialSpacing!);
      }

      if (widget.initialDistance != null) {
        offsetDistanceCtl.text = RackState.inchFmt(widget.initialDistance!);
      }

      if (widget.initialOffsetHeight != null) {
        offsetHeightCtl.text = RackState.inchFmt(widget.initialOffsetHeight!);
      }

      if (widget.initialOverallLength != null) {
        offsetOverallCtl.text = RackState.inchFmt(widget.initialOverallLength!);
      }

      if (widget.initialAngle != null && widget.initialAngle! > 0) {
        offsetAngleCtl.text = widget.initialAngle!.toString().replaceAll('.0', '');
      }


      _updateTextControllers();
      _sendPipeProgressionOffsetsToRackState(); // Force sync of multi-pipe data
      _clearRackBenderIfPipeChanged();
    });
    _updateTextControllers();
    rack.addListener(_onRackStateChanged);
    stubCtl.addListener(() => setState(() {}));
    legCtl.addListener(() => setState(() {}));
    runC2C.addListener(() => setState(() {}));
    distanceFromBoxCtl.addListener(_syncStartingPointCalculations);
    wallToSupportCtl.addListener(_syncStartingPointCalculations);
    firstSupportPosCtl.addListener(_syncStartingPointCalculations);

    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    _kickResultTimer?.cancel();
    rack.removeListener(_onRackStateChanged);

    rackPipeCountCtl.dispose();
    runC2C.dispose();
    boxC2C.dispose();
    stubCtl.dispose();
    kickStubCtl.dispose();
    legCtl.dispose();

    kickHeightCtl.dispose();
    kickAngleCtl.dispose();
    kickMatchBendCtl.dispose();
    kickLegCtl.dispose();

    offsetDistanceCtl.dispose();
    offsetHeightCtl.dispose();
    offsetOverallCtl.dispose();
    offsetAngleCtl.dispose();
    rollingVerticalCtl.dispose();
    rollingHorizontalCtl.dispose();
    rollingDistanceCtl.dispose();
    rollingOverallCtl.dispose();
    rollingAngleCtl.dispose();
    rackDefaultPipeSizeCtl.dispose();
    _customNameCtl.dispose();
    takeUpCtl.dispose();
    gainCtl.dispose();
    radiusCtl.dispose();
    setbackCtl.dispose();
    travelCtl.dispose();
    distanceFromBoxCtl.dispose();
    startingPointDistanceCtl.dispose();
    straightRunLengthCtl.dispose();
    supportPosCtl.dispose();
    nextRackDistanceCtl.dispose();
    wallToSupportCtl.dispose();
    firstSupportFromBoxCtl.dispose();
    firstSupportPosCtl.dispose();

    super.dispose();
  }
  bool get _isMixedSizes {
    if (_rackPipeSizes.isEmpty) return false;
    final first = _rackPipeSizes.first;
    return _rackPipeSizes.any((s) => s != first);
  }

  String get _rackSetupInfoText {
    if (_isParallel90sMode && !_parallel90ShowResults) {
      return 'Building from INSIDE 90. Outer pipes grow to maintain spacing. Tap MAX PIPE to calculate the longest possible run for a 120" stick.';
    }
    if (_choosingNextBend || (!_shouldShowStartingPointMenu && _isRackBendTypeExpanded)) {
      return 'Select your next segment. You can add straight 10ft sticks, choose a new bend type, and plan your supports at the bottom. Use the H icon to view your Hub history.';
    }

    if (_isRackBenderExpanded) {
      if (_benderWarningActive) {
        final missing = _getUnassignedSizes();
        return 'Only one bender selected. Do you wish to select another bender for the ${missing.join(", ")} pipe? Tap a pipe circle to select, or press Continue Anyway.';
      }
      return 'Select the bender you will use for each different pipe size. You can also create or edit a custom bender.\n(Note: Hand benders for Rigid pipe are typically one size larger.)';
    }

    if (_isRackBendTypeExpanded) {
      return 'This is where you get to the rack. Choose a straight section or a 90° up from your first box. Measure from the top of the box to the landing point on your rack (top or bottom).Then measure horizontally fom the wall or you can choose to use the remaining pipe to complete the bend';
    }

    if (!_showRackSetupOutput) {
      return 'Initialize your rack. Choose your pipe count, type, and size, then enter the spacing. Tap (i) for field guides. The Hub (H) will track your materials as you add bends.';
    }

    if (_rackSpacingIsCenterToCenter && _isMixedSizes) {
      return 'Mixed sizes detected: Would you like to switch to "Space Between" for even gaps between pipes?';
    }

    return 'Review your rack configuration. Tap any pipe circle to change its size, or press Continue to select your bender and starting point.';
  }
  List<String> _getUnassignedSizes() {
    final allUniqueSizes = _rackPipeSizes.toSet();
    final List<String> unassigned = [];
    
    for (var size in allUniqueSizes) {
      final key = '${_rackConduitType}_${_rackPipeSizeKey(size)}';
      if (!_rackBenderByPipeKey.containsKey(key)) {
        unassigned.add(size);
      }
    }
    return unassigned;
  }

  void _applyBenderToAllPipes() {
    if (_selectedRackBender == null) return;
    final b = _selectedRackBender!;
    
    for (int i = 0; i < rack.allConduits.length; i++) {
      if (i >= _rackPipeSizes.length) break;
      final pipe = rack.allConduits[i];
      final sizeDisplay = _rackPipeSizes[i];
      
      // Save to local persistence map so UI stays in sync
      final key = '${_rackConduitType}_${_rackPipeSizeKey(sizeDisplay)}';
      _rackBenderByPipeKey[key] = b;
      
      // Force individual bender math onto the conduit
      pipe.benderBrand = b.brand;
      pipe.benderGain = b.gain;
      pipe.benderTakeup = b.deduct;
      pipe.benderCLR = b.clr;
      pipe.pipeOD = _rackPipeOd(sizeDisplay);
      pipe.benderOverridden = true;
    }
    
    setState(() {
      _benderWarningActive = false;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = true;
    });
    
    rack.forceRefresh(); // Force recalculate with overridden values
  }

  void _updateWallFromSupport() {
    final supportVal = RackState.parseInches(firstSupportPosCtl.text);
    if (supportVal > 0) {
      final wallVal = supportVal + rack.supportDepth;
      wallToSupportCtl.text = RackState.inchFmt(wallVal).replaceAll('"', '');
    }
  }

  void _updateSupportFromWall() {
    final wallVal = RackState.parseInches(wallToSupportCtl.text);
    if (wallVal > 0) {
      final supportVal = math.max(0.0, wallVal - rack.supportDepth);
      firstSupportPosCtl.text = RackState.inchFmt(supportVal).replaceAll('"', '');
    }
  }

  void _syncStartingPointCalculations() {
    setState(() {});
  }

  void _resetRackSetup() {
    _hideKeypad();

    setState(() {
      rackPipeCountCtl.clear();
      rackDefaultPipeSizeCtl.text = '0"';
      runC2C.clear();
      boxC2C.clear();

      stubCtl.clear();
      legCtl.clear();

      offsetHeightCtl.clear();
      offsetAngleCtl.clear();
      offsetDistanceCtl.clear();
      offsetOverallCtl.clear();

      rollingVerticalCtl.clear();
      rollingHorizontalCtl.clear();
      rollingAngleCtl.clear();
      rollingDistanceCtl.clear();
      rollingOverallCtl.clear();

      kickStubCtl.clear();
      kickHeightCtl.clear();
      kickAngleCtl.clear();
      kickMatchBendCtl.clear();
      kickLegCtl.clear();
      _selectedRackPipe = 0;
      _currentSet = 0;
      _rackDefaultPipeSize = '0"';
      _rackPipeSizes.clear();

      _showRackSetupOutput = false;
      _rackSpacingIsCenterToCenter = false;

      _rackBenderByPipeKey.clear();
      _selectedRackBender = null;
      _selectedRackBenderBrand = null;
      _skipRackBenderForNow = false;
      _syncControllersToBender(null);

      _choosingNextBend = false;
      _rackNextBendMode = false;

      _isOffsetMode = false;
      _isParallel90sMode = false;
      _isNextRackMode = false;
      _isKick90sMode = false;

      _parallel90ShowResults = false;
      _showParallel90Measurements = true;

      _showKickMeasurements = true;
      _showKickTypeSelector = false;
      _kickMeasurementsExpanded = true;
      _kickBendingMethodConfirmed = false;

      _showRackResults = false;
      _rollingNeedsDirection = false;
      _skipStartingPoint = false;

      _showRackSetupStart = true;
      _isRackSetupExpanded = true;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = false;

      _activeController = rackPipeCountCtl;
      _isKeypadVisible = false;
      _clearOnNextInput = true;
      _spacingInteracted = false;
      _showHubGuidance = true; // Reset guidance for new run
    });

    rack.clearRunSequence();
    rack.setSpacing(0);
    rack.setIsFromBox(false);
    rack.setPipeProgressionOffsets([]); // This now ensures at least one pipe remains
    rack.setParallel90BenderData(gain: 0, takeup: 0);
    rack.setStubLength(0);
    rack.setLegLength(0);

    rack.setOffsetInputs(
      distanceToObstruction: 0,
      offsetHeightValue: 0,
      overallLengthValue: 0,
      bendAngleValue: 0,
    );

    rack.setRollingOffsetInputs(
      distanceToObstruction: 0,
      verticalOffset: 0,
      horizontalOffset: 0,
      overallLengthValue: 0,
      bendAngleValue: 0,
    );

    rack.setKick90Inputs(
      stub: 0,
      height: 0,
      leg: 0,
      angle: 0,
      matchBendDistance: 0,
      gain: 0,
      takeup: 0,
      pipeOD: 0,
      clr: 0,

      method: _kickMarkMethod,
      style: Kick90RackStyle.parallel,
    );
  }

  void _resetRackBender() {
    _hideKeypad();

    setState(() {
      _rackBenderByPipeKey.remove(_rackBenderMemoryKey());
      _selectedRackBender = null;
      _selectedRackBenderBrand = null;
      _skipRackBenderForNow = false;

      _isEditMode = false;
      _isNameEntryMode = false;
      _customBenderName = '';
      _choosingNextBend = false;
      _rackNextBendMode = false;

      _syncControllersToBender(null);
    });

    rack.setParallel90BenderData(
      gain: 0,
      takeup: 0,
      clr: 0,
      pipeOD: 0,
    );
  }

  void _resetBendType() {
    _hideKeypad();

    setState(() {
      _isOffsetMode = false;
      _isParallel90sMode = false;
      _isNextRackMode = false;
      _isKick90sMode = false;

      _parallel90ShowResults = false;
      _showParallel90Measurements = true;

      _showOffsetInputs = true;
      _showRackResults = false;
      _rollingNeedsDirection = true;
      _skipStartingPoint = false;

      // Clear starting point inputs
      startingPointDistanceCtl.clear();
      distanceFromBoxCtl.clear();
      wallToSupportCtl.clear();
      firstSupportPosCtl.clear();
      _startingPointFullStick = false;
      _startingPointMode = 'Straight';
    });

    // Clear starting point segments from Hub to restore the view
    final toRemove = <int>[];
    for (int i = 0; i < rack.runSequence.length; i++) {
      final seg = rack.runSequence[i];
      if (seg.label.contains('90° Up') || seg.label.contains('Initial Run')) {
        toRemove.add(i);
      }
    }
    for (final i in toRemove.reversed) {
      rack.removeSegment(i);
    }
  }

  void _resetParallel90s() {
    _hideKeypad();

    setState(() {
      stubCtl.clear();
      legCtl.clear();

      _parallel90ShowResults = false;
      _showParallel90Measurements = true;
      _parallel90Direction = 'right';

      _activeController = stubCtl;
      _isKeypadVisible = false;
      _clearOnNextInput = true;
      _spacingInteracted = false;
    });

    rack.setStubLength(0);
    rack.setLegLength(0);
  }
  void _resetKickMeasurements() {
    _hideKeypad();

    setState(() {
      kickStubCtl.clear();
      kickHeightCtl.clear();
      kickAngleCtl.clear();
      kickMatchBendCtl.clear();
      kickLegCtl.clear();

      _showKickMeasurements = true;
      _showKickTypeSelector = false;
      _kickMeasurementsExpanded = true;
      _kickBendingMethodConfirmed = false;

      _activeController = kickStubCtl;
      _isKeypadVisible = false;
      _clearOnNextInput = true;
      _spacingInteracted = false;
    });
  }
  void _resetOffsetInputsOnly() {
    offsetHeightCtl.clear();
    offsetAngleCtl.clear();
    offsetDistanceCtl.clear();
    offsetOverallCtl.clear();

    rollingVerticalCtl.clear();
    rollingHorizontalCtl.clear();
    rollingAngleCtl.clear();
    rollingDistanceCtl.clear();
    rollingOverallCtl.clear();

    _showOffsetInputs = true;
    _showRackResults = false;
    _rollingNeedsDirection = true;
    _activeController = offsetHeightCtl;
    _isKeypadVisible = false;
    _clearOnNextInput = true;
  }

  void _resetKickInputsOnly() {
    kickStubCtl.clear();
    kickHeightCtl.clear();
    kickAngleCtl.clear();
    kickMatchBendCtl.clear();
    kickLegCtl.clear();

    _showKickMeasurements = true;
    _showKickTypeSelector = false;
    _kickMeasurementsExpanded = true;
    _activeController = kickStubCtl;
    _isKeypadVisible = false;
    _clearOnNextInput = true;
  }
  void _align90Ends() {
    final double stub = RackState.parseInches(stubCtl.text);
    final int count = _rackPipeCount;
    if (count <= 0) return;

    // Growth only happens for Side-to-Side racks (Left/Right)
    final bool isGraduated = _parallel90Direction == 'left' || _parallel90Direction == 'right';
    final double spacing = RackState.parseInches(runC2C.text);
    final double totalGrowth = isGraduated ? (count - 1) * (2 * spacing) : 0.0;
    
    final double gain = _selectedRackBender?.gain ?? rack.benderGain;

    // We want: Last Pipe Total Length = 120"
    // Last Pipe OL = 120 - Gain
    // Outer OL = Stub + spacingOffset + Leg + spacingOffset - Gain
    // For outer pipe: OL = (Stub + growth) + (Leg + growth) - Gain
    // Wait, growth math for 90s: each pipe is 2*spacing longer than the previous.
    // So Outer OL = Pipe 1 OL + TotalGrowth
    // Pipe 1 OL = 120 - TotalGrowth
    // Stub + Leg - Gain = 120 - TotalGrowth
    // Leg = 120 - TotalGrowth - Stub + Gain
    final double optimizedTail = 120.0 - totalGrowth - stub + gain;

    setState(() {
      legCtl.text = RackState.inchFmt(math.max(0.0, optimizedTail)).replaceAll('"', '');
    });
    
    // Force immediate update of RackState
    rack.setStubLength(stub);
    rack.setLegLength(RackState.parseInches(legCtl.text));
  }

  Widget _buildParallel90sInputs() {
    final double stub = RackState.parseInches(stubCtl.text);
    final double tail = RackState.parseInches(legCtl.text);
    final double spacing = RackState.parseInches(runC2C.text);
    final double gain = _selectedRackBender?.gain ?? rack.benderGain;
    final int count = _rackPipeCount;

    final double totalGrowth = (count - 1) * (2 * spacing);
    final double lastPipeLength = (stub + tail - gain) + totalGrowth;
    final bool exceeds10ft = lastPipeLength > 120.1;

    return Column(
      children: [
        if (_isParallel90sMode && (!_parallel90ShowResults || _showParallel90Measurements)) ...[
          _Parallel90MeasurementsCard(
            stubCtl: stubCtl,
            legCtl: legCtl,
            spacingCtl: runC2C,
            activeController: _activeController,
            isCenterToCenter: _rackSpacingIsCenterToCenter,
            onStubTap: () => _showKeypad(stubCtl),
            onLegTap: () => _showKeypad(legCtl),
            onSpacingTap: () => _showKeypad(runC2C),
            onAlignEnds: () {
              _align90Ends(); // Use the original proven logic
              _saveStateFromActiveController();
            },
            onSpaceBetweenTap: () {
              setState(() {
                _rackSpacingIsCenterToCenter = false;
              });
              _sendPipeProgressionOffsetsToRackState();
            },
            onCenterToCenterTap: () {
              setState(() {
                _rackSpacingIsCenterToCenter = true;
              });
              _sendPipeProgressionOffsetsToRackState();
            },
            isFromBox: rack.isFromBox,
            distanceFromBoxCtl: distanceFromBoxCtl,
            onDistanceFromBoxTap: () => _showKeypad(distanceFromBoxCtl),
            measureToTop: rack.measureToTop,
            onToggleStrut: () => setState(() => rack.setMeasureToTop(!rack.measureToTop)),
            spacingValue: _rackSpacingIsCenterToCenter
                ? RackState.inchFmt(math.max(0, RackState.parseInches(runC2C.text) - _rackPipeOd(_rackDefaultPipeSize)))
                : RackState.inchFmt(RackState.parseInches(runC2C.text)),
            c2cValue: _rackSpacingIsCenterToCenter
                ? RackState.inchFmt(RackState.parseInches(runC2C.text))
                : RackState.inchFmt(
              _rackPipeOd(_rackPipeSizes.first) / 2 +
                  RackState.parseInches(runC2C.text) +
                  (_rackPipeCount > 1 ? _rackPipeOd(_rackPipeSizes[1]) / 2 : _rackPipeOd(_rackPipeSizes.first) / 2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _BeveledButton(
                  active: _parallel90Direction == 'left',
                  onTap: () {
                    setState(() {
                      _parallel90Direction = 'left';
                      rack.setParallel90Direction('left');
                    });
                  },
                  child: const RotatedBox(
                    quarterTurns: 2,
                    child: Text("➜", style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BeveledButton(
                  active: _parallel90Direction == 'up',
                  onTap: () {
                    setState(() {
                      _parallel90Direction = 'up';
                      rack.setParallel90Direction('up');
                    });
                  },
                  child: const RotatedBox(
                    quarterTurns: -1,
                    child: Text("➜", style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BeveledButton(
                  active: _parallel90Direction == 'down',
                  onTap: () {
                    setState(() {
                      _parallel90Direction = 'down';
                      rack.setParallel90Direction('down');
                    });
                  },
                  child: const RotatedBox(
                    quarterTurns: 1,
                    child: Text("➜", style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BeveledButton(
                  active: _parallel90Direction == 'right',
                  onTap: () {
                    setState(() {
                      _parallel90Direction = 'right';
                      rack.setParallel90Direction('right');
                    });
                  },
                  child: const Text("➜", style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (exceeds10ft && stub > 0 && tail > 0)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3D2E00),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber, width: 1.2),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '⚠️ Last pipe exceeds 10ft. Ends will be staggered.',
                      style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _BeveledButton(
                    width: 100,
                    height: 32,
                    active: true,
                    onTap: _align90Ends,
                    child: const Text('ALIGN ENDS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildRackSetupStartScreen() {
    Widget stepShell({
      required Widget child,
    }) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFC0C0C0),
            width: 1.5,
          ),
        ),
        child: child,
      );
    }

    return Expanded(
      child: ListView(
        controller: _scrollCtl,
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          if (!_choosingNextBend) ...[
            _buildRackSetupSection(),
            const SizedBox(height: 6),
            _buildRackBenderSection(),
            const SizedBox(height: 6),
            _buildRackBendTypeSection(),
          ] else ...[
            _buildChooseNextBendSection(),
          ],
          
          // Provide extra scroll room when keypad is up
          if (_isKeypadVisible)
             const SizedBox(height: 390),
        ],
      ),
    );
  }

  String _addInchIfMissing(String value) {
    if (value.isEmpty) return '';
    if (value.endsWith('"')) {
      return value;
    }
    return '$value"';
  }

  Widget _buildRackSetupSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          _SectionTitleButton(
            label: '1. RACK SETUP',
            fontSize: 19,
            height: 60,
            isActive: _isRackSetupExpanded,
            onReset: _resetRackSetup,
            onTap: () {
              setState(() {
                _isRackSetupExpanded = !_isRackSetupExpanded;
                if (_isRackSetupExpanded) {
                  _isRackBenderExpanded = false;
                  _isRackBendTypeExpanded = false;
                }
              });
            },
          ),

          if (!_isRackSetupExpanded && _showRackSetupOutput && !_isRackBenderExpanded && !_isRackBendTypeExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  _buildRackPreview(showSizeButtons: true),
                  const SizedBox(height: 6),
                  _buildRackWidthResult(),
                  const SizedBox(height: 12),
                  _BeveledButton(
                    active: true,
                    onTap: () {
                      setState(() {
                        _isRackBenderExpanded = true;
                      });
                      _scrollCtl.animateTo(140, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    },
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),

          if (_isRackSetupExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  _rackSetupInfoRow(
                    'Pipe Count',
                    _activeController == rackPipeCountCtl
                        ? rackPipeCountCtl.text
                        : (_rackPipeCount <= 0 ? '' : '$_rackPipeCount'),
                    onTap: () => _showKeypad(rackPipeCountCtl),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _BeveledButton(
                          active: _rackConduitType == 'EMT',
                          onTap: () {
                            setState(() {
                              _rackConduitType = 'EMT';
                            });
                            rack.setConduitType('EMT');
                          },
                          child: const Text(
                            'EMT',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BeveledButton(
                          active: _rackConduitType == 'RMC',
                          onTap: () {
                            setState(() {
                              _rackConduitType = 'RMC';
                            });
                            rack.setConduitType('RMC');
                          },
                          child: const Text(
                            'RMC',
                            style: TextStyle(
                              color: kLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDefaultPipeSizeRow(),
                  const SizedBox(height: 8),
                  _buildDualSpacingCard(),
                  if (_spacingInteracted && runC2C.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _BeveledButton(
                      active: true,
                      onTap: () {
                        _saveStateFromActiveController();
                        _hideKeypad();
                        setState(() {
                          _showRackSetupOutput = true;
                          _isRackSetupExpanded = false; // Fold up
                          _spacingErrorGlow = false;
                        });
                        _scrollCtl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      },
                      child: const Text(
                        'Next ➜',
                        style: TextStyle(
                          color: kLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildDefaultPipeSizeRow() {
    final bool isActive = _activeController == rackDefaultPipeSizeCtl;
    final String displaySize = _addInchIfMissing(_rackDefaultPipeSize);
    final Map<String, String> sizeOptions = bending_data.pipeSizes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Default Pipe Size (Temporary)',
              style: TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 45),
              color: const Color(0xFF151515),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFC8C8C8), width: 1.5),
              ),
              onSelected: (String newValue) {
                if (_activeController != null) {
                  _saveStateFromActiveController();
                }
                setState(() {
                  _rackDefaultPipeSize = newValue;
                  rackDefaultPipeSizeCtl.text = newValue;
                  
                  for (int i = 0; i < _rackPipeSizes.length; i++) {
                    _rackPipeSizes[i] = _rackDefaultPipeSize;
                  }
                  
                  _sendPipeProgressionOffsetsToRackState();
                  _clearRackBenderIfPipeChanged();
                  
                  _activeController = runC2C;
                  _isKeypadVisible = true;
                  _spacingInteracted = false; // Next step: show card border green
                  runC2C.clear();
                });
              },
              itemBuilder: (context) {
                return sizeOptions.values.map((String value) {
                  final bool selected = value == _rackDefaultPipeSize;
                  return PopupMenuItem<String>(
                    value: value,
                    height: 44,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: selected
                              ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)]
                              : [const Color(0xFF3A3A3A), const Color(0xFF1E1E1E)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(color: kLight, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                }).toList();
              },
              child: Container(
                width: 92,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1A0A0A) : const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive ? kGreen : Colors.white60,
                    width: isActive ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  displaySize.isEmpty ? '—' : displaySize,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bending_data.ConduitType _rackBendingConduitType() {
    return _rackConduitType == 'RMC'
        ? bending_data.ConduitType.rigid
        : bending_data.ConduitType.emt;
  }

  String _selectedRackPipeSizeDisplay() {
    if (_rackPipeSizes.isEmpty ||
        _selectedRackPipe < 0 ||
        _selectedRackPipe >= _rackPipeSizes.length) {
      return '0"';
    }

    return _rackPipeSizes[_selectedRackPipe];
  }

  String _selectedRackPipeSizeKey() {
    return _rackPipeSizeKey(_selectedRackPipeSizeDisplay());
  }

  void _selectRackBender(String? brand) {
    if (brand == null) return;

    final String sizeKey = _selectedRackPipeSizeKey();
    final conduitType = _rackBendingConduitType();

    final allBenders = [
      ...bending_data.benderDatabase,
      ..._customBenders,
    ];

    bending_data.Bender? found;
    try {
      found = allBenders.firstWhere(
            (b) =>
        b.brand == brand &&
            b.conduitSize == sizeKey &&
            b.conduitType == conduitType,
      );
    } catch (_) {
      found = null;
    }

    if (found != null) {
      setState(() {
        _rackBenderMatchError = null;
        _skipRackBenderForNow = false;
        _selectedRackBenderBrand = brand;
        _selectedRackBender = found;
        _rackBenderByPipeKey[_rackBenderMemoryKey()] = found!;
        _syncControllersToBender(found);
        _showTravelField = bending_data.mechanicalElectricBenderBrands.contains(found.brand);
      });

      rack.setRackBenderBrand(brand);
      rack.setParallel90BenderData(
        gain: found.gain,
        takeup: found.deduct,
        clr: found.clr,
        pipeOD: _rackPipeOd(_selectedRackPipeSizeDisplay()),
        brand: brand,
      );
    } else {
      // No entry found for this size/brand combo
      setState(() {
        _selectedRackBenderBrand = brand;
        _selectedRackBender = null;
        _rackBenderMatchError = 'Bender not found for this size/type';
        _syncControllersToBender(null);
      });
      // Clear mathematical inputs if no bender found
      rack.setParallel90BenderData(gain: 0, takeup: 0, clr: 0, pipeOD: 0);
    }
  }

  void _clearRackBenderIfPipeChanged() {
    final saved = _rackBenderByPipeKey[_rackBenderMemoryKey()];

    if (saved != null) {
      _selectedRackBender = saved;
      _selectedRackBenderBrand = saved.brand;
      _syncControllersToBender(saved);

      // FORCE STATE SYNC: Push the saved bender's data into the math engine
      rack.setParallel90BenderData(
        gain: saved.gain,
        takeup: saved.deduct,
        clr: saved.clr,
        pipeOD: _rackPipeOd(_selectedRackPipeSizeDisplay()),
      );
      return;
    }

    _selectedRackBender = null;
    _selectedRackBenderBrand = null;
    _syncControllersToBender(null);

    // RESET STATE: Clear math engine numbers if no bender is selected
    rack.setParallel90BenderData(gain: 0, takeup: 0);
  }

  void _updateBrandDropdown() {
    final Set<String> uniqueCustomNames = _customBenders.map((b) => b.brand).toSet();
    
    setState(() {
      _allBrands = [
        ...bending_data.getGroupedBenderBrands(),
        {'type': 'header', 'name': 'SAVED BENDERS'},
        ...uniqueCustomNames.map((name) => {
          'type': 'custom_bender',
          'name': name,
        }),
      ];
    });
  }

  void _syncControllersToBender(bending_data.Bender? bender) {
    if (bender == null) {
      takeUpCtl.text = '';
      gainCtl.text = '';
      radiusCtl.text = '';
      setbackCtl.text = '';
      travelCtl.text = '';
      return;
    }

    takeUpCtl.text = RackState.inchFmt(bender.deduct);
    gainCtl.text = RackState.inchFmt(bender.gain);
    radiusCtl.text = RackState.inchFmt(bender.clr);
    setbackCtl.text = RackState.inchFmt(bender.deduct - bender.gain);
    travelCtl.text = RackState.inchFmt(bending_data.calculateTravel90(bender.clr));
  }

  void _updateSetback() {
    final t = RackState.parseInches(takeUpCtl.text);
    final g = RackState.parseInches(gainCtl.text);
    if (t > 0 && g > 0) {
      setbackCtl.text = RackState.inchFmt(t - g);
    }
  }

  void _updateRadiusFromGain() {
    if (!_isEditMode || _activeController != gainCtl) return;

    final gainText = gainCtl.text.trim();
    if (gainText.isEmpty) {
      radiusCtl.text = '';
      return;
    }

    final gain = RackState.parseInches(gainText);
    final pipeOD = _rackPipeOd(_selectedRackPipeSizeDisplay());

    if (pipeOD <= 0 || gain <= pipeOD) {
      radiusCtl.text = '';
      return;
    }

    final clr = bending_data.calculateCLRFromGain(gain, pipeOD);
    radiusCtl.text = RackState.inchFmt(clr);

    // Also update travel
    travelCtl.text = RackState.inchFmt(bending_data.calculateTravel90(clr));
  }

  void _updateGainFromRadius() {
    if (!_isEditMode || _activeController != radiusCtl) return;

    final radiusText = radiusCtl.text.trim();
    if (radiusText.isEmpty) {
      gainCtl.text = '';
      return;
    }

    final radius = RackState.parseInches(radiusText);
    final pipeOD = _rackPipeOd(_selectedRackPipeSizeDisplay());

    if (pipeOD <= 0 || radius <= 0) {
      gainCtl.text = '';
      return;
    }

    final gain = bending_data.calculateGain90(radius, pipeOD);
    gainCtl.text = RackState.inchFmt(gain);

    // Also update travel
    travelCtl.text = RackState.inchFmt(bending_data.calculateTravel90(radius));
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _isNewBender = true;
        _selectedRackBenderBrand = null;
        _selectedRackBender = null;
        _customBenderName = '';
        _syncControllersToBender(null);
        _updateBrandDropdown();
        
        // Guided Flow: Automatically pop keypad for Take Up
        _showKeypad(takeUpCtl);
      } else {
        _syncControllersToBender(_selectedRackBender);
      }
    });
  }

  void _cancelEditMode() {
    setState(() {
      _isEditMode = false;
      _syncControllersToBender(_selectedRackBender);
    });
  }
  Future<void> _loadCustomBenders() async {
    final benders = await bending_data.BenderStore.load();
    setState(() {
      _customBenders.clear();
      _customBenders.addAll(benders);
      _updateBrandDropdown();
    });
  }

  Future<void> _saveCustomBendersToDevice() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _customBenders.map((b) {
        return {
          'brand': b.brand,
          'model': b.model,
          'conduitSize': b.conduitSize,
          'conduitType': b.conduitType == bending_data.ConduitType.rigid
              ? 'rigid'
              : 'emt',
          'clr': b.clr,
          'deduct': b.deduct,
          'gain': b.gain,
        };
      }).toList(),
    );

    await prefs.setString('rack_custom_benders', encoded);
  }

  void _saveCustomBender() {
    final name = _customBenderName.trim();
    if (name.isEmpty) return;

    final sizeKey = _selectedRackPipeSizeKey();
    final conduitType = _rackBendingConduitType();

    final newBender = bending_data.Bender(
      brand: name,
      model: name,
      conduitSize: sizeKey,
      conduitType: conduitType,
      clr: RackState.parseInches(radiusCtl.text),
      deduct: RackState.parseInches(takeUpCtl.text),
      gain: RackState.parseInches(gainCtl.text),
    );

    setState(() {
      // OVERWRITE LOGIC: Remove any existing bender with same name/size/type
      _customBenders.removeWhere((b) =>
          b.brand == name &&
          b.conduitSize == sizeKey &&
          b.conduitType == conduitType);

      _customBenders.add(newBender);
      bending_data.BenderStore.save(newBender);
      _updateBrandDropdown();

      _selectedRackBenderBrand = name;
      _selectedRackBender = newBender;
      _rackBenderByPipeKey[_rackBenderMemoryKey()] = newBender;

      _isNameEntryMode = false;
      _isEditMode = false;
      _customBenderName = '';
      _syncControllersToBender(newBender);
    });

    rack.setParallel90BenderData(
      gain: newBender.gain,
      takeup: newBender.deduct,
    );

    _hideKeypad();
  }

  void _onNameKeyTap(String value) {
    setState(() {
      if (value == '⌫') {
        if (_customBenderName.isNotEmpty) {
          _customBenderName =
              _customBenderName.substring(0, _customBenderName.length - 1);
        }
        return;
      }
      if (value == '✔') {
        if (_customBenderName.trim().isNotEmpty) {
          _saveCustomBender();
        }
        return;
      }
      _customBenderName += value;
    });
  }
  void _showRackBenderPicker() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(220),
      builder: (context) => BenderPickerDialog(
        allBrands: _allBrands,
        selectedBrand: _selectedRackBenderBrand,
        onSelected: (name) {
          _selectRackBender(name);
        },
        onDelete: (name) {
          setState(() {
            _customBenders.removeWhere((b) => b.brand == name);
            bending_data.BenderStore.delete(name);
            _updateBrandDropdown();
            if (_selectedRackBenderBrand == name) {
              _selectedRackBenderBrand = null;
              _selectedRackBender = null;
              _rackBenderMatchError = null;
              _syncControllersToBender(null);
            }
          });
        },
        onEdit: (name) {
          final bender = _customBenders.firstWhereOrNull((b) => b.brand == name);
          if (bender != null) {
            setState(() {
              _isEditMode = true;
              _isNewBender = false;
              _selectedRackBenderBrand = null;
              _selectedRackBender = null;
              _rackBenderMatchError = null;

              // Force the rack to match the bender being edited
              _rackConduitType = bender.conduitType == bending_data.ConduitType.rigid ? 'Rigid' : 'EMT';
              if (_selectedRackPipe >= 0 && _selectedRackPipe < _rackPipeSizes.length) {
                _rackPipeSizes[_selectedRackPipe] = bender.conduitSize;
              }

              _syncControllersToBender(bender);
              _customBenderName = bender.brand;
            });
            _showKeypad(takeUpCtl);
          }
        },
      ),
    );
  }
  Widget _buildRackBenderSection() {
    final selectedPipeText =
        'P${_selectedRackPipe + 1} — ${_selectedRackPipeSizeDisplay()} $_rackConduitType';

    final bender = _selectedRackBender;
    final gain90 = bender == null ? 0.0 : bender.gain;

    final travel90 = bender == null
        ? 0.0
        : bending_data.calculateTravel90(bender.clr);

    return _buildGroupContainer(
      child: Column(
        children: [
          _SectionTitleButton(
            label: '2. BENDER & CONDUIT SIZE',
            fontSize: 19,
            height: 60,
            isActive: _isRackBenderExpanded,
            onReset: _resetRackBender,
            onTap: () {
              setState(() {
                _isRackBenderExpanded = !_isRackBenderExpanded;
                if (_isRackBenderExpanded) {
                  _isRackSetupExpanded = false;
                  _isRackBendTypeExpanded = false;
                }
              });
            },
          ),

          if (_isRackBenderExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                children: [
                  _buildRackPreview(showSizeButtons: true),
                  if (bender == null && !_isEditMode) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.0),
                      ),
                      child: Center(
                        child: Text(
                          'Assigning bender to: ${_selectedRackPipeSizeDisplay()} pipes',
                          style: const TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showRackBenderPicker,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (bender == null && !_isEditMode) ? kGreen : const Color(0xFFC0C0C0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isEditMode
                                  ? (_isNewBender ? 'Custom' : 'Editing: $_customBenderName')
                                  : (bender == null
                                      ? 'Select Bender Brand'
                                      : (bender.brand == bender.model || bender.model == null || bender.model!.isEmpty
                                          ? bender.brand
                                          : '${bender.brand} ${bender.model}')),
                              style: const TextStyle(
                                color: kLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 28),
                        ],
                      ),
                    ),
                  ),

                  if (_rackBenderMatchError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _rackBenderMatchError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                  if (bender == null && !_isEditMode) ...[
                    const SizedBox(height: 4),
                  ],
                  
                  if (!_isEditMode && !_isRackBenderSetupComplete) ...[
                    const SizedBox(height: 4),
                    _SectionTitleButton(
                      label: 'Create / Edit Custom Bender',
                      onTap: _toggleEditMode,
                    ),
                  ],

                  if (_isRackBenderSetupComplete || _isEditMode) ...[
                    const SizedBox(height: 4),
                    
                    if (_showTravelField)
                      _rackBenderResultRow(
                        '90° Travel',
                        RackState.inchFmt(travel90),
                      ),

                    _rackBenderResultRow(
                      'Take Up',
                      _isEditMode ? takeUpCtl.text : (bender == null ? '—' : RackState.inchFmt(bender.deduct)),
                      onTap: _isEditMode ? () => _showKeypad(takeUpCtl) : null,
                    ),
                    _rackBenderResultRow(
                      'Gain90',
                      _isEditMode ? gainCtl.text : (bender == null ? '—' : RackState.inchFmt(gain90)),
                      onTap: _isEditMode ? () => _showKeypad(gainCtl) : null,
                    ),
                    _rackBenderResultRow(
                      'Radius / CLR',
                      _isEditMode ? radiusCtl.text : (bender == null ? '—' : RackState.inchFmt(bender.clr)),
                      onTap: _isEditMode ? () => _showKeypad(radiusCtl) : null,
                    ),

                    const SizedBox(height: 4),

                    if (_isEditMode) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _SectionTitleButton(
                              isActive: true,
                              onTap: () {
                                setState(() {
                                  _isNameEntryMode = true;
                                  _customBenderName = '';
                                  _isKeypadVisible = false;
                                  _activeController = null;
                                });
                              },
                              label: 'Save Custom Bender',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SectionTitleButton(
                              onTap: _cancelEditMode,
                              label: 'Cancel',
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 4),

                    _SectionTitleButton(
                      isActive: true,
                      isCheckmark: true,
                      onTap: (bender == null && !_skipRackBenderForNow)
                          ? null
                          : () {
                              if (_benderWarningActive || _getUnassignedSizes().isEmpty || _skipRackBenderForNow) {
                                setState(() {
                                  _benderWarningActive = false;
                                  _isRackBenderExpanded = false;
                                  _isRackBendTypeExpanded = true;
                                });
                              } else {
                                setState(() {
                                  _benderWarningActive = true;
                                });
                              }
                            },
                      label: _benderWarningActive ? 'Continue Anyway' : 'Done',
                    ),
                    if (_benderWarningActive && _selectedRackBenderBrand != null) ...[
                      const SizedBox(height: 8),
                      _BeveledButton(
                        active: true,
                        onTap: _applyBenderToAllPipes,
                        child: Text(
                          'Apply $_selectedRackBenderBrand to Entire Rack',
                          style: const TextStyle(
                            color: kLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: You can also Create a "Custom Bender" with your specific measurements if it is not on the list.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
  Widget _rackBenderResultRow(String label, String value, {VoidCallback? onTap}) {
    final bool isActive = _activeController != null && (
        (_activeController == takeUpCtl && label == 'Take Up') ||
            (_activeController == gainCtl && label == 'Gain90') ||
            (_activeController == radiusCtl && label == 'Radius / CLR')
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      decoration: BoxDecoration(
        color: kBlack.withAlpha(160),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onTap != null ? Colors.white38 : const Color(0xFFC0C0C0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 118,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: kBlack.withAlpha(160),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? kGreen : Colors.white60,
                  width: isActive ? 1.8 : 1.0,
                ),
              ),
              child: Text(
                value.isEmpty ? '0"' : (value.endsWith('"') ? value : '$value"'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  bool get _shouldShowStartingPointMenu {
    if (_skipStartingPoint) return false;
    if (rack.runSequence.isEmpty) return true;

    // Check if any segment in the hub is NOT a starting point segment
    final hasRealBends = rack.runSequence.any((seg) =>
    !seg.label.contains('90° Up') && !seg.label.contains('Initial Run'));

    return !hasRealBends;
  }

  Widget _buildRackBendTypeSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          _SectionTitleButton(
            label: _shouldShowStartingPointMenu ? '3. BEND TYPE' : '4. NEXT BEND',
            fontSize: 19,
            height: 60,
            isActive: _isRackBendTypeExpanded,
            onReset: _resetBendType,
            onTap: () {
              setState(() {
                _isRackBendTypeExpanded = !_isRackBendTypeExpanded;

                if (_isRackBendTypeExpanded) {
                  _isRackSetupExpanded = false;
                  _isRackBenderExpanded = false;
                  
                  // Auto-scroll to top of Step 3
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollCtl.hasClients) {
                      _scrollCtl.animateTo(140, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  });
                }
              });
            },
          ),

          if (_isRackBendTypeExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  if (_shouldShowStartingPointMenu) ...[
                    _buildStartingPointSection(),
                    const SizedBox(height: 12),
                    _BeveledButton(
                      height: 38,
                      subtle: true,
                      onTap: () => setState(() => _skipStartingPoint = true),
                      child: const Text(
                        'SKIP STARTING POINT ➜',
                        style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ),
                  ] else ...[
                    // ADD STRAIGHT STICKS SECTION
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withAlpha(100), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ADD STRAIGHTS', style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                                Text('10ft (120") Sticks', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BeveledButton(
                                width: 40, height: 40,
                                onTap: () => setState(() => _straightSticksCount = math.max(1, _straightSticksCount - 1)),
                                child: const Text('-', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                width: 45,
                                alignment: Alignment.center,
                                child: Text('$_straightSticksCount', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                              ),
                              _BeveledButton(
                                width: 40, height: 40,
                                onTap: () => setState(() => _straightSticksCount++),
                                child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              _BeveledButton(
                                width: 80, height: 40,
                                active: true,
                                onTap: () {
                                  rack.addStraightSegment(_straightSticksCount * 120.0, multiplier: _rackPipeCount);
                                  _triggerHubFlash();
                                  setState(() => _straightSticksCount = 1);
                                },
                                child: const Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _BeveledButton(
                            onTap: () {
                              rack.setCalcMode(RackCalcMode.parallel90);
                              rack.setIsFromBox(false); // Generic 90s DO use graduation math
                              setState(() {
                                _showRackSetupStart = false;

                                _isOffsetMode = false;
                                _isNextRackMode = true;
                                _isParallel90sMode = true;
                                stubCtl.clear();
                                legCtl.clear();

                                rack.setStubLength(0);
                                rack.setLegLength(0);

                                _parallel90ShowResults = false;
                                _showParallel90Measurements = true;

                                _activeController = stubCtl;
                                _isKeypadVisible = false;
                                _clearOnNextInput = true;
                              });
                            },
                            child: const Text(
                              '90s',
                              style: TextStyle(
                                color: kLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: _BeveledButton(
                            onTap: () {
                              rack.startOffsetUp();
                              setState(() {
                                _offsetStartedFromRackSetup = true;

                                _showRackSetupStart = false;

                                _isOffsetMode = true;
                                _isNextRackMode = false;
                                _isParallel90sMode = false;

                                _showOffsetInputs = true;
                                _showRackResults = false;

                                _rollingNeedsDirection = true;

                                _activeController = stubCtl;
                                _isKeypadVisible = false;
                                _clearOnNextInput = true;
                                stubCtl.clear();
                                legCtl.clear();
                              });

                              rack.startOffsetUp();
                            },
                            child: const Text(
                              'Offsets',
                              style: TextStyle(
                                color: kLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _BeveledButton(
                            onTap: () {
                              _resetKickInputsOnly();

                              setState(() {
                                _showRackSetupStart = false;

                                _isOffsetMode = false;
                                _isNextRackMode = false;
                                _isParallel90sMode = false;
                                _isKick90sMode = true;

                                _showRackResults = false;
                                _showOffsetInputs = true;

                                _showKickMeasurements = true;
                                _showKickTypeSelector = false;
                                _kickMeasurementsExpanded = true;

                                _activeController = kickStubCtl;
                                _isKeypadVisible = false;
                                _clearOnNextInput = true;
                              });

                              rack.setCalcMode(RackCalcMode.kick90);
                              rack.setKick90RackStyle(Kick90RackStyle.perpendicular);
                            },
                            child: const Text(
                              'Kick 90s',
                              style: TextStyle(
                                color: kLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _calculateStartingPointStub() {
    final distBoxRaw = RackState.parseInches(distanceFromBoxCtl.text);
    final od = _rackPipeOd(_rackDefaultPipeSize.isEmpty ? '0.5' : _rackDefaultPipeSize);
    
    // Vertical Rise component (including Top/Bot landing adjustment)
    final verticalRise = rack.measureToTop ? (distBoxRaw + od) : distBoxRaw;

    return verticalRise;
  }

  double _calculateStartingPointLeg() {
    final distBoxRaw = RackState.parseInches(distanceFromBoxCtl.text);
    final od = _rackPipeOd(_rackDefaultPipeSize.isEmpty ? '0.5' : _rackDefaultPipeSize);
    final verticalRise = rack.measureToTop ? (distBoxRaw + od) : distBoxRaw;

    if (_startingPointFullStick) {
      final gain = _selectedRackBender?.gain ?? rack.benderGain;
      final horizontalRun = 120.0 - verticalRise + gain;
      return horizontalRun;
    }

    final distWallRaw = RackState.parseInches(wallToSupportCtl.text);
    final horizontalRun = math.max(0.0, distWallRaw - rack.supportDepth);
    
    return horizontalRun;
  }

  Widget _buildStartingPointSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'STARTING POINT (OPTIONAL)',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ),
            if (rack.runSequence.isEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _startingPointMode = 'Straight';
                    startingPointDistanceCtl.clear();
                    distanceFromBoxCtl.clear();
                    wallToSupportCtl.clear();
                    stubCtl.clear();
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 4, bottom: 8),
                  child: Text('RESET', style: TextStyle(color: kRed, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        ),
        
        Row(
          children: [
            Expanded(
              child: _BeveledButton(
                height: 34,
                active: _startingPointMode == 'Straight',
                onTap: () => setState(() => _startingPointMode = 'Straight'),
                child: const Text('Straight', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BeveledButton(
                height: 34,
                active: _startingPointMode == '90Up',
                onTap: () => setState(() => _startingPointMode = '90Up'),
                child: const Text('90 Up from Box', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_startingPointMode == 'Straight') ...[
          _rackSetupInfoRow(
            'Distance from Box',
            _addInchIfMissing(startingPointDistanceCtl.text),
            onTap: () => _showKeypad(startingPointDistanceCtl),
          ),
          if (startingPointDistanceCtl.text.isNotEmpty && startingPointDistanceCtl.text != '0"') ...[
            const SizedBox(height: 8),
            _BeveledButton(
              height: 40,
              active: false,
              redOutline: true,
              onTap: () {
                final dist = RackState.parseInches(startingPointDistanceCtl.text);
                rack.addStraightSegment(dist, multiplier: _rackPipeCount, customLabel: 'Initial Run');
                _triggerHubFlash();
                _hideKeypad();
                startingPointDistanceCtl.clear();
                _goToChooseNextBend();
              },
              child: const Text(
                'ADD INITIAL RUN TO HUB',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ],
        ] else ...[
          // VERTICAL TRANSITION BLOCK
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(180),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC0C0C0), width: 1.2),
            ),
            child: Column(
              children: [
                _rackSetupInfoRow(
                  'Vertical (Box to Rack)',
                  _addInchIfMissing(distanceFromBoxCtl.text),
                  onTap: () => _showKeypad(distanceFromBoxCtl),
                  noBorder: true,
                  leadingInput: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => rack.setMeasureToTop(!rack.measureToTop));
                    },
                    child: Container(
                      width: 50,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8A1010), Color(0xFFD12A2A)]),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Center(
                        child: Text(
                          rack.measureToTop ? 'TOP' : 'BOT',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                _rackSetupInfoRow(
                  'Vertical Support (from Box)',
                  _addInchIfMissing(firstSupportFromBoxCtl.text),
                  onTap: () => _showKeypad(firstSupportFromBoxCtl),
                  noBorder: true,
                ),
                const Divider(color: Colors.white24, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Support Type:',
                          style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BeveledButton(
                            width: 70,
                            height: 30,
                            active: rack.supportDepth == 1.625,
                            onTap: () {
                              setState(() {
                                rack.setSupportDepth(1.625);
                                _updateWallFromSupport();
                              });
                            },
                            child: const Text('1-5/8"', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          _BeveledButton(
                            width: 70,
                            height: 30,
                            active: rack.supportDepth == 0.875,
                            onTap: () {
                              setState(() {
                                rack.setSupportDepth(0.875);
                                _updateWallFromSupport();
                              });
                            },
                            child: const Text('7/8"', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // HORIZONTAL RUN BLOCK
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(180),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC0C0C0), width: 1.2),
            ),
            child: Column(
              children: [
                _rackSetupInfoRow(
                  'Horizontal (Off Wall)',
                  _addInchIfMissing(wallToSupportCtl.text),
                  onTap: _startingPointFullStick ? null : () => _showKeypad(wallToSupportCtl),
                  noBorder: true,
                  trailingSide: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'FULL\nSTICK?',
                        style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 6),
                      _FullStickToggle(
                        useLetters: true,
                        value: _startingPointFullStick,
                        onChanged: (val) {
                          setState(() {
                            _startingPointFullStick = val;
                            if (val) {
                              final distBoxRaw = RackState.parseInches(distanceFromBoxCtl.text);
                              final od = _rackPipeOd(_rackDefaultPipeSize.isEmpty ? '0.5' : _rackDefaultPipeSize);
                              final verticalComponent = rack.measureToTop ? (distBoxRaw + od) : distBoxRaw;
                              final gain = _selectedRackBender?.gain ?? 0.0;
                              final horizontalComponent = 120.0 - verticalComponent + gain;
                              wallToSupportCtl.text = RackState.inchFmt(horizontalComponent).replaceAll('"', '');
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                _rackSetupInfoRow(
                  'First Support (from Wall)',
                  _addInchIfMissing(firstSupportPosCtl.text),
                  onTap: () {
                    _showKeypad(firstSupportPosCtl);
                  },
                  noBorder: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _BeveledButton(
                  height: 40,
                  subtle: true,
                  onTap: () {
                    final stub = _calculateStartingPointStub();
                    final distBox = RackState.parseInches(distanceFromBoxCtl.text);
                    final distWall = _calculateStartingPointLeg();
                    
                    // Transition results then to kicks
                    rack.setStubLength(stub);
                    rack.setDistanceFromBox(distBox);
                    rack.setDistanceFromWall(distWall);
                    
                    setState(() {
                      _isKick90sMode = true;
                      _showKickMeasurements = true;
                      _showRackSetupStart = false;
                    });
                    
                    rack.setCalcMode(RackCalcMode.kick90);
                    rack.setKick90RackStyle(Kick90RackStyle.perpendicular);
                  },
                  child: const Text('KICK THIS 90?', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BeveledButton(
                  height: 40,
                  active: true,
                  onTap: () {
                    final stub = _calculateStartingPointStub();
                    final leg = _calculateStartingPointLeg();
                    
                    if (stub > 0 && leg > 0) {
                      _saveStateFromActiveController(); 

                      // Clear any existing starting supports to prevent duplicates
                      rack.removeSupportsByLabel('Vertical (from Box)');
                      rack.removeSupportsByLabel('Horizontal (off Wall)');

                      // Transition state to 90s results page
                      rack.setStubLength(stub);
                      rack.setLegLength(leg);
                      rack.setIsFromBox(true); // Mark as Box Transition to disable graduation math
                      
                      // Add starting supports
                      // 1. Vertical support (from Box)
                      final distBoxSupport = RackState.parseInches(firstSupportFromBoxCtl.text);
                      if (distBoxSupport > 0) {
                         rack.addSupport(distBoxSupport, label: 'Vertical (from Box) | ${RackState.inchFmt(distBoxSupport)}');
                      } else {
                         // Default to 36" if zero/empty to match field standard
                         rack.addSupport(36.0, label: 'Vertical (from Box) | 36"');
                      }
                      
                      // 2. Horizontal support (the user entered 'First Support (from Wall)')
                      final firstSupFromWall = RackState.parseInches(firstSupportPosCtl.text);
                      if (firstSupFromWall > 0) {
                        // Position is Rise + Support distance off wall
                        rack.addSupport(stub + firstSupFromWall, label: 'Horizontal (off Wall) | ${RackState.inchFmt(firstSupFromWall)}');
                      }

                      setState(() {
                        _showRackSetupStart = false;

                        _isOffsetMode = false;
                        _isNextRackMode = true;
                        _isParallel90sMode = true;
                        _parallel90ShowResults = true;
                        _showParallel90Measurements = false;
                        
                        _activeController = null;
                        _isKeypadVisible = false;
                        _clearOnNextInput = false;
                      });
                    }
                  },
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildChooseNextBendSection() {
    return _buildGroupContainer(
      child: Column(
        children: [
          _SectionTitleButton(
            label: '4. CHOOSE NEXT BEND',
            fontSize: 19,
            height: 60,
            isActive: true,
            onTap: () {},
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _BeveledButton(
                  onTap: () {
                    _resetParallel90s();
                    setState(() {
                      _choosingNextBend = false;
                      _rackNextBendMode = true;
                      _showRackSetupStart = false;

                      _isOffsetMode = false;
                      _isKick90sMode = false;
                      _isNextRackMode = true;
                      _isParallel90sMode = true;

                      _showRackResults = false;
                      _showOffsetInputs = true;
                    });
                  },
                  child: const Text('90s', style: TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _BeveledButton(
                  onTap: () {
                    _resetOffsetInputsOnly();
                    setState(() {
                      _choosingNextBend = false;
                      _rackNextBendMode = true;
                      _offsetStartedFromRackSetup = true;
                      _showRackSetupStart = false;

                      _isOffsetMode = true;
                      _isNextRackMode = false;
                      _isParallel90sMode = false;
                      _isKick90sMode = false;
                    });

                    rack.startOffsetUp();
                  },
                  child: const Text('Offsets', style: TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _BeveledButton(
                  onTap: () {
                    _resetKickInputsOnly();
                    setState(() {
                      _choosingNextBend = false;
                      _rackNextBendMode = true;
                      _showRackSetupStart = false;

                      _isKick90sMode = true;
                      _isParallel90sMode = false;
                      _isOffsetMode = false;
                      _isNextRackMode = false;

                      _showRackResults = false;
                    });

                    rack.setCalcMode(RackCalcMode.kick90);
                    rack.setKick90RackStyle(Kick90RackStyle.perpendicular);
                  },
                  child: const Text('Kick 90s', style: TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildCompactStraightAdder(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCompactStraightAdder({int? insertIndex}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('ADD STRAIGHTS (10ft Sticks)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        Row(
          children: [
            // Shorter Counter
            _BeveledButton(
              width: 32, height: 36,
              onTap: () {
                setState(() {
                  _straightSticksCount = math.max(1, _straightSticksCount - 1);
                  straightRunLengthCtl.text = (_straightSticksCount * 120).toString();
                });
              },
              child: const Text('-', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              width: 28,
              alignment: Alignment.center,
              child: Text('$_straightSticksCount', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            ),
            _BeveledButton(
              width: 32, height: 36,
              onTap: () {
                setState(() {
                  _straightSticksCount++;
                  straightRunLengthCtl.text = (_straightSticksCount * 120).toString();
                });
              },
              child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            
            const SizedBox(width: 8),
            
            // Input
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (straightRunLengthCtl.text.isEmpty || straightRunLengthCtl.text == '0') {
                     straightRunLengthCtl.text = (_straightSticksCount * 120).toString();
                  }
                  _showKeypad(straightRunLengthCtl);
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _activeController == straightRunLengthCtl ? kGreen : const Color(0xFF8C8C8C),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      straightRunLengthCtl.text.isEmpty ? '${_straightSticksCount * 120}"' : '${straightRunLengthCtl.text}"',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // ADD button
            _BeveledButton(
              width: 70, height: 36,
              onTap: () {
                final length = straightRunLengthCtl.text.isEmpty 
                    ? (_straightSticksCount * 120.0) 
                    : RackState.parseInches(straightRunLengthCtl.text);
                
                rack.addStraightSegment(length, multiplier: _rackPipeCount, atIndex: insertIndex);
                _triggerHubFlash();
                
                setState(() {
                  _straightSticksCount = 1;
                  straightRunLengthCtl.clear();
                  _hideKeypad();
                });
              },
              child: const Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  void _showAdjustSubsequentDialog(int segIndex, double inVal, double outVal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Adjust Run?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text(
          'Would you like to adjust all subsequent supports based on this change, or just update this one corner?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                final seg = rack.runSequence[segIndex];
                seg.inSupportOffset = inVal;
                seg.outSupportOffset = outVal;
                // Don't recalculate others
              });
              Navigator.pop(context);
            },
            child: const Text('JUST THIS ONE', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final seg = rack.runSequence[segIndex];
                seg.inSupportOffset = inVal;
                seg.outSupportOffset = outVal;
                rack.recalculateSupports(); // Sync everything after
              });
              Navigator.pop(context);
            },
            child: const Text('ADJUST ALL', style: TextStyle(color: kGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: child,
    );
  }
  Widget _rackSetupInfoRow(String label, String value, {VoidCallback? onTap, Widget? leadingInput, Widget? trailingBottom, Widget? trailingSide, bool noBorder = false}) {
    final bool isActive =
        (label == 'Pipe Count' && _activeController == rackPipeCountCtl) ||
            (label == 'Default Pipe Size (Temporary)' && _activeController == rackDefaultPipeSizeCtl) ||
            (label == 'Spacing' && _activeController == runC2C) ||
            (label == 'Vertical (Box to Rack)' && _activeController == distanceFromBoxCtl) ||
            (label == 'Vertical Support (from Box)' && _activeController == firstSupportFromBoxCtl) ||
            (label == 'Horizontal (Off Wall)' && _activeController == wallToSupportCtl) ||
            (label == 'First Support (from Wall)' && _activeController == firstSupportPosCtl);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: noBorder ? Colors.transparent : Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: noBorder ? null : Border.all(
            color: const Color(0xFFC0C0C0),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (leadingInput != null) ...[
              leadingInput,
              const SizedBox(width: 8),
            ],
            if (trailingSide != null) ...[
              trailingSide,
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 92,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF1A0A0A) : const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive ? kGreen : Colors.white60,
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    value.isEmpty ? '' : value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: kLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailingBottom != null) ...[
                  const SizedBox(height: 6),
                  SizedBox(width: 92, child: trailingBottom),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  String _rackPipeSizeKey(String displaySize) {
    final s = displaySize.replaceAll('"', '').trim();

    switch (s) {
      case '1/2': return '0.5';
      case '3/4': return '0.75';
      case '1': return '1.0';
      case '1 1/4': return '1.25';
      case '1 1/2': return '1.5';
      case '2': return '2.0';
      case '2 1/2': return '2.5';
      case '3': return '3.0';
      case '3 1/2': return '3.5';
      case '4': return '4.0';
      default:
        final d = double.tryParse(s);
        if (d != null) {
          return d.toString().contains('.') ? d.toString() : '${d.toString()}.0';
        }
        return '0.5';
    }
  }

  double _rackPipeOd(String displaySize) {
    final key = _rackPipeSizeKey(displaySize);

    if (_rackConduitType == 'RMC') {
      return bending_data.grcOD[key] ?? 0.0;
    }

    return bending_data.emtOD[key] ?? 0.0;
  }
  String? _rackSpacingErrorText() {
    final int count = _rackPipeCount;
    if (count <= 1) return null;

    while (_rackPipeSizes.length < count) {
      _rackPipeSizes.add(_rackDefaultPipeSize);
    }

    final spacing = RackState.parseInches(runC2C.text);
    if (spacing <= 0) return null;

    for (int i = 1; i < count; i++) {
      final previousOd = _rackPipeOd(_rackPipeSizes[i - 1]);
      final currentOd = _rackPipeOd(_rackPipeSizes[i]);

      final clearSpace = _rackSpacingIsCenterToCenter
          ? spacing - (previousOd / 2) - (currentOd / 2)
          : spacing;

      if (clearSpace < 0) {
        return 'Spacing is smaller than pipe OD.';
      }

      if (clearSpace < 1.0) {
        return 'Less than 1" clear — fittings may interfere.';
      }
    }

    return null;
  }

  double _rackWidthNeeded() {
    final int count = _rackPipeCount;
    if (count <= 0) return 0.0;

    while (_rackPipeSizes.length < count) {
      _rackPipeSizes.add(_rackDefaultPipeSize);
    }

    final spacing = RackState.parseInches(runC2C.text);

    if (count == 1) {
      return _rackPipeOd(_rackPipeSizes.first);
    }

    if (_rackSpacingIsCenterToCenter) {
      final firstOd = _rackPipeOd(_rackPipeSizes.first);
      final lastOd = _rackPipeOd(_rackPipeSizes[count - 1]);
      return (firstOd / 2) + (spacing * (count - 1)) + (lastOd / 2);
    }

    double total = 0.0;
    for (int i = 0; i < count; i++) {
      total += _rackPipeOd(_rackPipeSizes[i]);
    }

    total += spacing * (count - 1);
    return total;
  }
  Widget _buildRackPreview({
    bool showSizeButtons = true,
  }) {
    final int pipeCount = _rackPipeCount;
    if (pipeCount <= 0) return const SizedBox.shrink();

    // Guard: Ensure sizes list matches count before building UI
    while (_rackPipeSizes.length < pipeCount) {
      _rackPipeSizes.add(_rackDefaultPipeSize.isEmpty ? '1/2"' : _rackDefaultPipeSize);
    }
    if (_rackPipeSizes.length > pipeCount) {
      _rackPipeSizes.removeRange(pipeCount, _rackPipeSizes.length);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C8C8), width: 1.2),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const int visibleSlots = 6;
              final double slotWidth = constraints.maxWidth / visibleSlots;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(pipeCount, (visualIndex) {
                    final bool flipRight = (_isKick90sMode && _kickDirection == 'right') ||
                        (_isOffsetMode && rack.offsetDirectionSign == 1) ||
                        (_isParallel90sMode && _parallel90Direction == 'right');

                    final int index = flipRight
                        ? pipeCount - 1 - visualIndex
                        : visualIndex;

                    final bool selected = index == _selectedRackPipe;

                    return SizedBox(
                      width: slotWidth,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRackPipe = index;
                            _currentSet = (index / 3).floor();
                            _benderWarningActive = false;
                          });

                          rack.select(index);
                          _clearRackBenderIfPipeChanged();
                        },
                        child: Column(
                          children: [
                            Text(
                              'P${index + 1}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                border: Border.all(
                                  color: selected ? kRed : const Color(0xFFC8C8C8),
                                  width: selected ? 2.8 : 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  index < _rackPipeSizes.length ? _addInchIfMissing(_rackPipeSizes[index]) : '—',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: kLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          Container(
            height: 9,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0E0E0),
                  Color(0xFF8E8E8E),
                  Color(0xFF4E4E4E),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
            ),
          ),

          if (showSizeButtons) ...[
            if (showSizeButtons) ...[
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _rackSizeButtonFixed('1/2"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('3/4"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('1"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('1 1/4"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('1 1/2"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('2"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('2 1/2"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('3"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('3 1/2"'),
                    const SizedBox(width: 3),
                    _rackSizeButtonFixed('4"'),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
  Widget _buildDualSpacingCard() {
    final bool hasInput = runC2C.text.trim().isNotEmpty;
    final double spacingVal = hasInput ? RackState.parseInches(runC2C.text) : 0.0;
    
    // Only use OD if default pipe size has been set to something other than 0/empty
    final bool hasPipeSize = _rackDefaultPipeSize.isNotEmpty && _rackDefaultPipeSize != '0"';
    final double od = hasPipeSize ? _rackPipeOd(_rackDefaultPipeSize) : 0.0;
    
    String spaceBetweenDisp = "—";
    String centerToCenterDisp = "—";

    if (hasInput) {
      if (_rackSpacingIsCenterToCenter) {
        centerToCenterDisp = RackState.inchFmt(spacingVal);
        spaceBetweenDisp = hasPipeSize ? RackState.inchFmt(math.max(0, spacingVal - od)) : "—";
      } else {
        spaceBetweenDisp = RackState.inchFmt(spacingVal);
        centerToCenterDisp = hasPipeSize ? RackState.inchFmt(spacingVal + od) : "—";
      }
    } else {
      // If we are actively editing spacing, show a 0 in the targeted row
      if (_activeController == runC2C) {
        if (_rackSpacingIsCenterToCenter) {
          centerToCenterDisp = "0\"";
          spaceBetweenDisp = "0\"";
        } else {
          spaceBetweenDisp = "0\"";
          centerToCenterDisp = "0\"";
        }
      }
    }

    final bool isMixedWarning = _rackSpacingIsCenterToCenter && _isMixedSizes;
    // Border is green ONLY when we have focus on Spacing but haven't clicked a button yet
    final bool cardGlowGreen = (_activeController == runC2C && !_spacingInteracted) || _spacingErrorGlow;
    final bool spacingIsActiveInput = (_activeController == runC2C && _spacingInteracted);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Border is green ONLY when waiting for user to click a row (Next Step)
          color: cardGlowGreen ? kGreen : (isMixedWarning ? kRed : const Color(0xFFC0C0C0)),
          width: (cardGlowGreen || isMixedWarning) ? 2.0 : 1.2,
        ),
      ),
      child: Column(
        children: [
          _dualSpacingRow(
            label: 'Space Between',
            value: spaceBetweenDisp,
            isActive: !_rackSpacingIsCenterToCenter,
            // Individual button glows green ONLY when it is actively being edited
            isGlow: (spacingIsActiveInput && !_rackSpacingIsCenterToCenter),
            onTap: () {
              setState(() {
                _spacingInteracted = true; // Turn off card border, turn on button border
                if (_rackSpacingIsCenterToCenter) {
                  _rackSpacingIsCenterToCenter = false;
                  runC2C.clear();
                  rack.setSpacing(0);
                  _sendPipeProgressionOffsetsToRackState();
                }
                _showKeypad(runC2C);
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              "— OR —",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
          _dualSpacingRow(
            label: 'Center to Center',
            value: centerToCenterDisp,
            isActive: _rackSpacingIsCenterToCenter,
            // Individual row button glows green ONLY when it is actively being edited
            isGlow: (spacingIsActiveInput && _rackSpacingIsCenterToCenter),
            onTap: () {
              setState(() {
                _spacingInteracted = true; // Turn off card border, turn on button border
                if (!_rackSpacingIsCenterToCenter) {
                  _rackSpacingIsCenterToCenter = true;
                  runC2C.clear();
                  rack.setSpacing(0);
                  _sendPipeProgressionOffsetsToRackState();
                }
                _showKeypad(runC2C);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _dualSpacingRow({
    required String label,
    required String value,
    required bool isActive,
    required bool isGlow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            // Row border is green ONLY when actively editing that specific row
            color: isGlow ? kGreen : Colors.white38,
            width: isGlow ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRackWidthResult() {
    final spacingError = _rackSpacingErrorText();
    final widthNeeded = _rackWidthNeeded();
    final bool hasError = spacingError != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError ? kRed : const Color(0xFFC8C8C8),
          width: hasError ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasError ? spacingError : 'Edge to Edge Distance of Pipes',
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasError
                    ? const [Color(0xFF5A1010), Color(0xFFE53935)]
                    : const [Color(0xFF8A1010), Color(0xFFD12A2A)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD0D0D0), width: 1.1),
            ),
            child: Text(
              hasError ? 'Too Tight' : RackState.inchFmt(widthNeeded),
              style: const TextStyle(
                color: kLight,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportPlanningBar() {
    final double lastSup = rack.supportPositions.isEmpty ? 0.0 : rack.supportPositions.last;
    final double runLen = rack.totalRunLength;
    
    // Proactive Suggestion Logic:
    // User requested standard 10ft (120") default intervals.
    double suggestionValue = 120.0;
    String suggestionLabel = "";
    
    if (rack.supportPositions.isEmpty) {
      suggestionValue = 36.0; // Standard start from box
      suggestionLabel = 'Initial support suggested at 36" from box';
    } else {
      final double nextCouplingAt = ((runLen / 120.0).floor() + 1) * 120.0;
      final double distToCoupling = nextCouplingAt - runLen;
      
      // If we are very close to a coupling, suggest a support just before it.
      if (distToCoupling < 12) {
         suggestionValue = distToCoupling - 2.0;
         suggestionLabel = 'Coupling coming up! Support suggested at ${RackState.inchFmt(suggestionValue)}';
      } else {
         suggestionValue = 120.0; // Default to 10ft gap
         suggestionLabel = 'Next interval suggested at 10ft (120")';
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreen.withAlpha(150), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten, color: kGreen, size: 18),
              const SizedBox(width: 8),
              const Text(
                'SUPPORT PLANNER',
                style: TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: kGreen.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kGreen.withAlpha(100), width: 1),
                ),
                child: Text(
                  '${rack.supportPositions.length}',
                  style: const TextStyle(color: kLight, fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestionLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _BeveledButton(
                      height: 38,
                      onTap: () {
                        nextRackDistanceCtl.text = RackState.inchFmt(suggestionValue).replaceAll('"', '');
                        _showKeypad(nextRackDistanceCtl);
                      },
                      child: Text(
                        nextRackDistanceCtl.text.isEmpty ? RackState.inchFmt(suggestionValue) : nextRackDistanceCtl.text,
                        style: const TextStyle(color: kLight, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _BeveledButton(
                    width: 100,
                    height: 38,
                    active: true,
                    onTap: () {
                      final enteredGap = nextRackDistanceCtl.text.isEmpty ? suggestionValue : RackState.parseInches(nextRackDistanceCtl.text);
                      // Add relative to last support
                      rack.addSupport(lastSup + enteredGap);
                      nextRackDistanceCtl.clear();
                      _triggerHubFlash();
                      setState(() {});
                    },
                    child: const Text(
                      'ADD +',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onRackStateChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateTextControllers();
          setState(() {});
        }
      });
    }
  }

  Widget _rackSizeButtonFixed(String size) {
    if (_rackPipeSizes.isEmpty || _selectedRackPipe < 0 || _selectedRackPipe >= _rackPipeSizes.length) {
      return const SizedBox.shrink();
    }
    final bool active = _rackPipeSizes[_selectedRackPipe] == size;

    return SizedBox(
      width: 61,
      height: 36,
      child: _BeveledButton(
        active: active,
        onTap: () {
          setState(() {
            if (_selectedRackPipe >= 0 && _selectedRackPipe < _rackPipeSizes.length) {
              _rackPipeSizes[_selectedRackPipe] = size;
            }
          });

          _sendPipeProgressionOffsetsToRackState();
          _clearRackBenderIfPipeChanged();
        },
        child: Text(
          size,
          style: const TextStyle(
            color: kLight,
            fontSize: 11, // ⬅️ smaller text
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
  void _updateTextControllers() {
    final formattedRun = RackState.inchFmt(rack.c2cSpacing);
    if (_activeController != runC2C && runC2C.text != formattedRun) {
      runC2C.text = formattedRun;
    }

    final formattedBox = RackState.inchFmt(rack.boxSpacingDisplayValue);
    if (_activeController != boxC2C && boxC2C.text != formattedBox) {
      boxC2C.text = formattedBox;
    }

    final formattedStub = RackState.inchFmt(rack.stubLength);
    if (_activeController != stubCtl && stubCtl.text != formattedStub) {
      stubCtl.text = formattedStub;
    }

    final formattedLeg = RackState.inchFmt(rack.legLength);
    if (_activeController != legCtl && legCtl.text != formattedLeg) {
      legCtl.text = formattedLeg;
    }
  }
  Widget _buildDefaultPipeSizeStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _defaultPipeSizeButton('1/2"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('3/4"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('1"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('1 1/4"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('1 1/2"'),
          const SizedBox(width: 2),
          _defaultPipeSizeButton('2"'),
        ],
      ),
    );
  }

  Widget _defaultPipeSizeButton(String size) {
    final bool active = _rackDefaultPipeSize == size;

    return SizedBox(
      width: 58,
      height: 36,
      child: _BeveledButton(
        active: active,
        onTap: () {
          setState(() {
            _rackDefaultPipeSize = size;

            for (int i = 0; i < _rackPipeSizes.length; i++) {
              _rackPipeSizes[i] = size;
            }
          });
        },
        child: Text(
          size,
          style: const TextStyle(
            color: kLight,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _onOffsetInputSubmitted() {
    setState(() {
       final int? newCount = int.tryParse(rackPipeCountCtl.text);
       if (newCount != null) {
         _rackPipeCount = newCount;
       }
    });

    _sendPipeProgressionOffsetsToRackState();

    rack.setOffsetInputs(
      distanceToObstruction: RackState.parseInches(offsetDistanceCtl.text),
      offsetHeightValue: RackState.parseInches(offsetHeightCtl.text),
      overallLengthValue: RackState.parseInches(offsetOverallCtl.text),
      bendAngleValue: RackState.parseInches(offsetAngleCtl.text),
    );
  }
  void _onRollingInputSubmitted() {
    setState(() {
       final int? newCount = int.tryParse(rackPipeCountCtl.text);
       if (newCount != null) {
         _rackPipeCount = newCount;
       }
    });

    _sendPipeProgressionOffsetsToRackState();

    rack.setRollingOffsetInputs(
      distanceToObstruction: RackState.parseInches(rollingDistanceCtl.text),
      verticalOffset: RackState.parseInches(rollingVerticalCtl.text),
      horizontalOffset: RackState.parseInches(rollingHorizontalCtl.text),
      overallLengthValue: RackState.parseInches(rollingOverallCtl.text),
      bendAngleValue: RackState.parseInches(rollingAngleCtl.text),
    );
  }

  void _onRunSpacingSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double spacingValue = RackState.parseInches(value);
    rack.setSpacing(spacingValue);
  }

  void _onBoxSpacingSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double spacingValue = RackState.parseInches(value);
    rack.setBoxSpacing(spacingValue);
  }

  void _onStubSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double parsedValue = RackState.parseInches(value);
    rack.setStubLength(parsedValue);
  }

  void _onLegSubmitted(String value) {
    if (value.trim().isEmpty) return;
    final double parsedValue = RackState.parseInches(value);
    rack.setLegLength(parsedValue);
  }

  void _select(int i) {
    final trueIndex = (_currentSet * 3) + i;

    if (trueIndex < 0 || trueIndex >= _rackPipeCount) {
      return;
    }

    setState(() {
      _selectedRackPipe = trueIndex;
    });

    rack.select(trueIndex);
    _clearRackBenderIfPipeChanged();
  }


  void _saveStateFromActiveController() {
    if (_activeController == null) return;
    final controller = _activeController!;
    final String value = controller.text.trim();

    if (value.isEmpty) return;

    final parsed = RackState.parseInches(value);
    final formatted = RackState.inchFmt(parsed);

    if (controller == rackPipeCountCtl) {
      final count = int.tryParse(value) ?? 0;
      _rackPipeCount = count.clamp(1, 24);
      rackPipeCountCtl.text = _rackPipeCount.toString();
      
      // Update sizes list to match count
      while (_rackPipeSizes.length < _rackPipeCount) {
        _rackPipeSizes.add(_rackDefaultPipeSize);
      }
      if (_rackPipeSizes.length > _rackPipeCount) {
        _rackPipeSizes.removeRange(_rackPipeCount, _rackPipeSizes.length);
      }
      _selectedRackPipe = 0;
    } else if (controller == rackDefaultPipeSizeCtl) {
      _rackDefaultPipeSize = formatted;
      rackDefaultPipeSizeCtl.text = formatted;
      for (int i = 0; i < _rackPipeSizes.length; i++) {
        _rackPipeSizes[i] = formatted;
      }
    } else if (controller == runC2C) {
      runC2C.text = formatted;
      rack.setSpacing(parsed);
      _sendPipeProgressionOffsetsToRackState();
      _showRackSetupOutput = _rackPipeCount > 0 && runC2C.text.trim().isNotEmpty;
    } else if (controller == stubCtl) {
      stubCtl.text = formatted;
      rack.setStubLength(parsed);
    } else if (controller == legCtl) {
      legCtl.text = formatted;
      rack.setLegLength(parsed);
    } else if (controller == takeUpCtl) {
      takeUpCtl.text = formatted;
      _updateSetback();
    } else if (controller == gainCtl) {
      gainCtl.text = formatted;
      _updateSetback();
    } else if (controller == radiusCtl) {
      radiusCtl.text = formatted;
      final r = RackState.parseInches(radiusCtl.text);
      travelCtl.text = RackState.inchFmt(bending_data.calculateTravel90(r));
    } else if (controller == startingPointDistanceCtl) {
      startingPointDistanceCtl.text = formatted;
    } else if (controller == distanceFromBoxCtl) {
      distanceFromBoxCtl.text = formatted;
      rack.setDistanceFromBox(parsed);
    } else if (controller == wallToSupportCtl) {
      wallToSupportCtl.text = formatted;
    } else if (controller == supportPosCtl) {
      supportPosCtl.text = formatted;
      if (_editingSupportIndex != null) {
        // We are editing a gap. Calculate new absolute position based on previous support.
        double prevPos = 0.0;
        if (_editingSupportIndex! > 0) {
          prevPos = rack.supportPositions[_editingSupportIndex! - 1];
        }
        final newAbsPos = prevPos + parsed;
        rack.updateSupport(_editingSupportIndex!, newAbsPos);
        _editingSupportIndex = null;
      } else {
        // Adding a new support at the end or relative to selection
        double prevPos = rack.supportPositions.isEmpty ? 0.0 : rack.supportPositions.last;
        rack.addSupport(prevPos + parsed);
      }
    } else if (controller == straightRunLengthCtl) {
      straightRunLengthCtl.text = formatted;
      if (_editingSegmentIndex != null) {
        rack.updateSegment(_editingSegmentIndex!, length: parsed);
        _editingSegmentIndex = null;
      } else if (_isAddingStraightSegment) {
        rack.addStraightSegment(parsed, multiplier: _rackPipeCount, atIndex: _lastTappedSegmentIndex);
        _isAddingStraightSegment = false;
      }
      _triggerHubFlash();
    }
  }

  void _showKeypad(TextEditingController controller) {
    if (_activeController != null && _activeController != controller) {
      _saveStateFromActiveController();
    }

    setState(() {
      final bool isNewFocus = _activeController != controller;
      _activeController = controller;
      _isKeypadVisible = true;

      if (isNewFocus) {
        if (controller == runC2C) {
          _spacingErrorGlow = false;
        }
        
        _clearOnNextInput = true; 
        
        // Immediate visual feedback: Clear supports to 0" so they are "ready"
        if (controller == supportPosCtl || controller == nextRackDistanceCtl) {
          controller.text = '0"';
        }
        
        if (controller == rackPipeCountCtl ||
            controller == rackDefaultPipeSizeCtl ||
            controller == runC2C) {
          _showRackSetupOutput = false;
        }
      }
    });
  }

  void _hideKeypad() {
    setState(() {
      _activeController = null;
      _isKeypadVisible = false;
    });
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final controller = _activeController!;

    if (value == '⌫') {
      setState(() {
        final bool needsInch = (controller == stubCtl || controller == legCtl || 
                                controller == distanceFromBoxCtl || controller == wallToSupportCtl ||
                                controller == firstSupportPosCtl || controller == startingPointDistanceCtl ||
                                controller == supportPosCtl || controller == nextRackDistanceCtl);
        if (controller.text.isNotEmpty) {
          String t = controller.text;
          if (needsInch && t.endsWith('"')) t = t.substring(0, t.length - 1);
          if (t.isNotEmpty) {
            t = t.substring(0, t.length - 1);
            controller.text = needsInch ? t + '"' : t;
            if (controller.text == '"') controller.text = '0"';
          }
        }
      });
      return;
    }

    if (value == '✔') {
      _saveStateFromActiveController();
      
      // Sequential advance for Setup
      if (controller == rackPipeCountCtl) {
        _hideKeypad();
        _showRackBenderPicker(); 
        return;
      }

      // Sequential advance for 90s
      if (controller == stubCtl) {
        _showKeypad(legCtl);
        return;
      }

      if (controller == supportPosCtl) {
         // Auto-add new support on checkmark if in staging mode
         if (_editingSupportIndex == null) {
            final lastPos = rack.supportPositions.isEmpty ? 0.0 : rack.supportPositions.last;
            final gap = supportPosCtl.text.isEmpty ? 120.0 : RackState.parseInches(supportPosCtl.text);
            rack.addSupport(lastPos + gap);
         }
      }

      _hideKeypad();
      return;
    }

    setState(() {
      // Logic for Start Point and 90s: automatic inches
      final bool needsInch = (controller == stubCtl || controller == legCtl || 
                              controller == distanceFromBoxCtl || controller == wallToSupportCtl ||
                              controller == firstSupportPosCtl || controller == startingPointDistanceCtl ||
                              controller == supportPosCtl || controller == nextRackDistanceCtl);

      // Clear if it's a fresh focus, zero, or flagged
      if (_clearOnNextInput || controller.text == '0"' || controller.text == '0') {
        controller.text = needsInch ? '"' : ''; // Keep the inch mark if needed
        _clearOnNextInput = false;
      }

      String valToAppend = value;
      if (value.contains('/')) {
        if (controller.text.isNotEmpty && !controller.text.endsWith(' ') && !controller.text.endsWith('"')) {
          valToAppend = ' ' + value;
        }
      }

      // Append text while preserving the inch mark at the end
      String current = controller.text.replaceAll('"', '');
      String next = current + valToAppend;
      controller.text = needsInch ? next + '"' : next;
    });
  }
  void _triggerHubFlash() {
    setState(() {
      _hubRecentlyUpdated = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _hubRecentlyUpdated = false;
        });
      }
    });
  }

  void _startKickResultCycle() {
    _kickResultTimer?.cancel();
    _showKickResultAlternative = false;
    _kickResultTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _showKickResultAlternative = !_showKickResultAlternative;
        });
      }
    });
  }

  void _applyKickRackInputsToState() {
    final stub = RackState.parseInches(kickStubCtl.text);
    final kickHeight = RackState.parseInches(kickHeightCtl.text);
    final leg = RackState.parseInches(kickLegCtl.text);
    final angle = double.tryParse(
      kickAngleCtl.text.replaceAll('°', '').trim(),
    ) ??
        30.0;
    final matchBendDistance =
    RackState.parseInches(kickMatchBendCtl.text);

    final bender = _selectedRackBender;
    final gain = bender?.gain ?? rack.benderGain;
    final takeup = bender?.deduct ?? rack.benderTakeup;
    final clr = bender?.clr ?? 0.0;
    final pipeOD = _rackPipeOd(_selectedRackPipeSizeDisplay());

    rack.setKick90Inputs(
      stub: stub,
      height: kickHeight,
      leg: leg,
      angle: angle,
      matchBendDistance: matchBendDistance,
      gain: gain,
      takeup: takeup,
      pipeOD: pipeOD,
      clr: clr,
      size: _selectedRackPipeSizeDisplay(),
      method: rack.bendingMethod,
      style: _selectedKickStyle == 'Across'
          ? Kick90RackStyle.parallel
          : _selectedKickStyle == 'Forward'
          ? Kick90RackStyle.perpendicular
          : _selectedKickStyle == 'Same Angle'
          ? Kick90RackStyle.sameAngle
          : _selectedKickStyle == '90 → Match Bend'
          ? Kick90RackStyle.sameStart
          : _selectedKickStyle == 'Same Angle 2'
          ? Kick90RackStyle.sameAngleSamePlane
          : _selectedKickStyle == '90 → Match Bend 2'
          ? Kick90RackStyle.sameStartSamePlane
          : Kick90RackStyle.perpendicular,
    );
  }
  bool get _kickUsesMatchBendInput {
    return _selectedKickStyle == '90 → Match Bend' ||
        _selectedKickStyle == '90 → Match Bend 2';
  }

  bool get _kickUsesAngleInput {
    return !_kickUsesMatchBendInput;
  }
  Widget _buildKickDirectionRow() {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Expanded(
            child: _BeveledButton(
              active: _kickDirection == 'left',
              onTap: () {
                setState(() {
                  _kickDirection = 'left';
                });
              },
              child: const RotatedBox(
                quarterTurns: 2,
                child: Text(
                  '➜',
                  style: TextStyle(
                    color: kLight,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BeveledButton(
              active: _kickDirection == 'right',
              onTap: () {
                setState(() {
                  _kickDirection = 'right';
                });
              },
              child: const Text(
                '➜',
                style: TextStyle(
                  color: kLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  double _kickRunCenterToCenterDisplay() {
    final enteredSpacing = RackState.parseInches(runC2C.text);

    if (_rackSpacingIsCenterToCenter) {
      return enteredSpacing;
    }

    final pipeSize = _selectedRackPipeSizeDisplay();
    final od = _rackPipeOd(pipeSize);

    return enteredSpacing + od;
  }

  double _kickBoxCenterToCenterDisplay() {
    final runCenterToCenter = _kickRunCenterToCenterDisplay();

    if (_selectedKickStyle == 'Across') {
      return runCenterToCenter *
          bending_data.calculateCosecant(rack.kickAngle);
    }

    return runCenterToCenter;
  }
  Widget _buildKickTypeCard() {
    Widget typeButton(String label, {String? value}) {
      final String buttonValue = value ?? label;
      final bool active = _selectedKickType == buttonValue;

      return Expanded(
        child: _BeveledButton(
          active: active,
          onTap: () {
            setState(() {
              _selectedKickType = buttonValue;
              _selectedKickStyle = buttonValue;


              if (buttonValue == 'Across') {
                rack.setKick90RackStyle(Kick90RackStyle.parallel);

              } else if (buttonValue == 'Forward') {
                rack.setKick90RackStyle(Kick90RackStyle.perpendicular);

              } else if (buttonValue == 'Same Angle') {
                rack.setKick90RackStyle(Kick90RackStyle.sameAngle);

              } else if (buttonValue == '90 → Match Bend') {
                rack.setKick90RackStyle(Kick90RackStyle.sameStart);

              } else if (buttonValue == 'Same Angle 2') {
                rack.setKick90RackStyle(Kick90RackStyle.sameAngleSamePlane);

              } else if (buttonValue == '90 → Match Bend 2') {
                rack.setKick90RackStyle(Kick90RackStyle.sameStartSamePlane);

              } else {
                rack.setKick90RackStyle(Kick90RackStyle.perpendicular);
              }
            });
          },
          child: label == '90 → Match Bend'
              ? const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '90',
                style: TextStyle(
                  color: kLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '➜',
                style: TextStyle(
                  color: kLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Match Bend',
                style: TextStyle(
                  color: kLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          )
              : Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kLight,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          if (_showKickTypeCard) ...[
    const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CHANGE PLANE',
              style: TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              typeButton('Across'),
              const SizedBox(width: 4),
              typeButton('Forward'),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              typeButton('Same Angle'),
              const SizedBox(width: 4),
              typeButton('90 → Match Bend', value: '90 → Match Bend'),
            ],
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              height: 1,
              width: double.infinity,
              color: Colors.white38,
            ),
          ),

          const SizedBox(height: 12),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SAME PLANE',
              style: TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              typeButton('Same Angle 2'),
              const SizedBox(width: 4),
              typeButton('90 → Match Bend', value: '90 → Match Bend 2'),
            ],
          ),

          const SizedBox(height: 8),

          _BeveledButton(
            active: false,
            redOutline: true,
            subtle: true,
            onTap: () {
              setState(() {
                _kickTypeConfirmed = true;
                _showKickTypeCard = false;
              });
            },
            child: const Text(
              'Continue',
              style: TextStyle(
                color: kLight,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
  Widget _buildUniversalBendingMethodCard() {
    final bool isMachineBender = bending_data.mechanicalElectricBenderBrands.contains(_selectedRackBenderBrand);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Center(
              child: Text(
                'BENDING METHOD',
                style: TextStyle(
                  color: kLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _BeveledButton(
                  active: rack.isArrowMethod,
                  onTap: () {
                    setState(() {
                      rack.setBendingMethod(bending_data.BendingMethod.centerline, arrow: true);
                    });
                  },
                  child: const Text('ARROW', style: TextStyle(color: kLight, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _BeveledButton(
                  active: !rack.isArrowMethod && (rack.bendingMethod == bending_data.BendingMethod.notch || rack.bendingMethod == bending_data.BendingMethod.hook),
                  onTap: () {
                    setState(() {
                      final m = isMachineBender ? bending_data.BendingMethod.hook : bending_data.BendingMethod.notch;
                      _kickMarkMethod = m;
                      rack.setBendingMethod(m, arrow: false);
                    });
                  },
                  child: Text(isMachineBender ? 'HOOK' : 'NOTCH', style: const TextStyle(color: kLight, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _BeveledButton(
                  active: !rack.isArrowMethod && rack.bendingMethod == bending_data.BendingMethod.centerline,
                  onTap: () {
                    setState(() {
                      _kickMarkMethod = bending_data.BendingMethod.centerline;
                      rack.setBendingMethod(bending_data.BendingMethod.centerline, arrow: false);
                    });
                  },
                  child: const Text('℄ LINE', style: TextStyle(color: kLight, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          if (!rack.isArrowMethod) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Orientation:',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                _BeveledButton(
                  width: 90, height: 34,
                  active: !rack.isBenderDirectionReversed,
                  onTap: () => setState(() => rack.setBendingMethod(rack.bendingMethod, reverse: false)),
                  child: const Text('FORWARD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                _BeveledButton(
                  width: 90, height: 34,
                  active: rack.isBenderDirectionReversed,
                  onTap: () => setState(() => rack.setBendingMethod(rack.bendingMethod, reverse: true)),
                  child: const Text('REVERSE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _getBendingMethodExplanation(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKickBendingMethodCard() {
    final bool isMachineBender = bending_data.mechanicalElectricBenderBrands.contains(_selectedRackBenderBrand);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            'BENDING METHOD',
            style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BeveledButton(
                  active: rack.bendingMethod == (isMachineBender ? bending_data.BendingMethod.hook : bending_data.BendingMethod.notch),
                  onTap: () {
                    setState(() {
                      rack.setBendingMethod(isMachineBender ? bending_data.BendingMethod.hook : bending_data.BendingMethod.notch, arrow: false);
                    });
                  },
                  child: Text(isMachineBender ? 'USE HOOK' : 'USE NOTCH', style: const TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BeveledButton(
                  active: rack.bendingMethod == bending_data.BendingMethod.centerline,
                  onTap: () {
                    setState(() {
                      rack.setBendingMethod(bending_data.BendingMethod.centerline, arrow: false);
                    });
                  },
                  child: const Text('USE CENTERLINE', style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Text(
              rack.bendingMethod == bending_data.BendingMethod.centerline
                  ? "Choose this if your bender has center of bend markings for the angle you require."
                  : (isMachineBender 
                      ? "HOOK: Align the front edge of the hook with your mark."
                      : "NOTCH: Use the 45° notch for all marks. The app adjusts measurements automatically."),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  String _getBendingMethodExplanation() {
    if (rack.isArrowMethod) {
      return "Standard Hand Bending: Place the bender's ARROW on your marks.";
    }
    switch (rack.bendingMethod) {
      case bending_data.BendingMethod.notch:
        return "Notch Method: Use the 45° notch or teardrop for all marks. The app adjusts measurements automatically.";
      case bending_data.BendingMethod.hook:
        return "Machine Bending: Align the FRONT EDGE of the hook with your calculated marks.";
      case bending_data.BendingMethod.centerline:
        return "Center-of-Bend: Align the center of the bender shoe with your calculated marks.";
    }
  }

  Widget _buildOffsetGeometryResultsCard() {
    final double offsetVal = rack.calcMode == RackCalcMode.rollingOffset 
        ? math.sqrt(math.pow(rack.offsetHeight, 2) + math.pow(rack.offsetHorizontal, 2))
        : rack.offsetHeight;
    final double angle = rack.bendAngle;
    
    // PULL DATA FROM THE ACTUAL SELECTED BENDER/CONDUIT DATA in RackState
    final pipe = rack.allConduits.first;
    final double clr = pipe.benderCLR ?? rack.kickCLR;
    final double pipeOD = pipe.pipeOD ?? rack.kickPipeOD;
    final double takeUp = pipe.benderTakeup ?? rack.benderTakeup;

    final double shrink = offsetVal * math.tan((angle * math.pi / 180.0) / 2.0);
    final double travel = offsetVal / math.sin(angle * math.pi / 180.0);
    final double ol = rack.isFullStick ? 120.0 : rack.overallLength; 

    double radAdj = 0.0;
    double refAdj = 0.0;
    String refLabel = 'Reference Adjustment';

    if (!rack.isArrowMethod && clr > 0) {
      radAdj = bending_data.calculateRadiusAdjustment(clr: clr, angleDeg: angle);
      if (rack.bendingMethod == bending_data.BendingMethod.notch) {
        refAdj = bending_data.calculate45NotchCorrection(clr: clr, angleDeg: angle);
        refLabel = 'Notch Adjustment';
      } else if (rack.bendingMethod == bending_data.BendingMethod.hook) {
        refAdj = bending_data.calculateFrontHookAdjustment(deduct: takeUp, clr: clr, pipeOD: pipeOD, angleDeg: angle);
        refLabel = 'Front Hook Adjustment';
      }
    }

    Widget resRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 15, fontWeight: FontWeight.w700))),
            Container(
              width: 185,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5A5A5F), Color(0xFF2C3030)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD0D0D0), width: 1.2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('GEOMETRY RESULTS', style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          resRow('Travel (BTW Bends)', RackState.inchFmt(travel)),
          resRow('Shrink', RackState.inchFmt(shrink)),
          resRow('Overall Length', RackState.inchFmt(ol)),
          resRow('Radius Adjustment', rack.isArrowMethod ? '—' : RackState.inchFmt(radAdj)),
          resRow(refLabel, (rack.isArrowMethod || rack.bendingMethod == bending_data.BendingMethod.centerline) ? '—' : RackState.inchFmt(refAdj)),
        ],
      ),
    );
  }
  Widget _buildKickResultsCard() {
    final selectedPipeIndex = _selectedRackPipe;
    
    if (rack.allConduits.isEmpty || selectedPipeIndex < 0 || selectedPipeIndex >= rack.allConduits.length) {
      return const SizedBox.shrink();
    }

    final conduit = rack.allConduits[selectedPipeIndex];

    final shift = selectedPipeIndex <= 0
        ? '0'
        : RackState.inchFmt(rack.graduationForPipe(selectedPipeIndex));

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: kLight,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [

          row('Mark A', RackState.inchFmt(conduit.markA)),
          row('Mark B', RackState.inchFmt(conduit.markB)),
          row('Mark C / Cut', RackState.inchFmt(conduit.ol)),

          row(
            'Angle',
            '${conduit.angle.toStringAsFixed(conduit.angle % 1 == 0 ? 0 : 1)}°',
          ),

          const SizedBox(height: 10),

          if (!rack.isFromBox)
            _BeveledButton(
              height: 40,
              subtle: true,
              onTap: () {
                double exportSpacing = rack.centerToCenterSpacing;
                if (rack.calcMode == RackCalcMode.kick90 &&
                    (rack.kick90RackStyle == Kick90RackStyle.sameAngle ||
                        rack.kick90RackStyle == Kick90RackStyle.sameStart)) {
                  // Plane Change / Cross Kick effective spacing calculation
                  final angleRad = rack.kickAngle * math.pi / 180.0;
                  if (math.cos(angleRad).abs() > 0.1) {
                    exportSpacing = rack.centerToCenterSpacing / math.cos(angleRad);
                  }
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BoxLayoutModeScreen(
                      prePopulatedConduits: rack.allConduits,
                      preCalculatedCenterToCenter: exportSpacing,
                      preCalculatedCenterMarks: rack.boxCenterMarks, // ADDED
                      showBackButton: true,
                    ),
                  ),
                );
              },
              child: const Text(
                'EXPORT TO BOX LAYOUT (Optional)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKickMarkedPipeCard() {
    final conduit = rack.current;

    return Container(
      height: 88,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 4,
            right: 4,
            bottom: 2,
            height: 20,
            child: Image.asset(
              'assets/images/rack_builder/pipe_5_straight.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          _downMark(30, 20, 'A', RackState.inchFmt(conduit.markA)),
          _downMark(100, 20, 'B', RackState.inchFmt(conduit.markB)),
          _downMark(300, 20, 'C', RackState.inchFmt(conduit.ol)),


        ],
      ),
    );
  }
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: const Text(
          'Rack Builder Help',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Build complex parallel conduit runs with precise alignment.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Workflow:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Start by entering the measurements for your first pipe (the inside of the turn). The app automatically adjusts stubs, legs, and kick heights for subsequent pipes to maintain perfectly parallel spacing.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Notch:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Standard for hand benders. Translates center-of-bend measurements to the 45° notch / teardrop.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Hook:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Standard for machine benders. Translates center-of-bend measurements to the front edge of the hook.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Centerline:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose this if you have marked your own center-of-bend lines on the shoe.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleParallel90sMode() {
    setState(() {
      _isParallel90sMode = !_isParallel90sMode;
      if (_isParallel90sMode) {
        final hasKick90Data = widget.initialMarkA != null &&
            widget.initialMarkB != null &&
            widget.initialCut != null;

        if (!hasKick90Data) {
          rack.resetParallel90sState();
        }

        _activeController = hasKick90Data ? null : stubCtl;
        _isKeypadVisible = false;
      } else {
        _hideKeypad();
      }
    });
  }
  Widget _buildResultsRackStrip({
    required int selectedIndex,
  }) {
    final int count = _rackPipeCount;

    return SizedBox(
      height: 58,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final bool selected = i == selectedIndex;
            final String size = i < _rackPipeSizes.length
                ? _rackPipeSizes[i]
                : _rackDefaultPipeSize;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRackPipe = i;
                  _currentSet = (i / 3).floor();
                });
                rack.select(i);
                _clearRackBenderIfPipeChanged();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'P${i + 1}',
                      style: TextStyle(
                        color: selected ? kRed : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? kRed : const Color(0xFF202020),
                        border: Border.all(
                          color: const Color(0xFFC8C8C8),
                          width: selected ? 2.0 : 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _addInchIfMissing(size),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: kLight,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  Widget _buildPipeSelectorRow({
    required List<int> labels,
    required int selectedPipeIndexInSet,
    required double spacing,
  }) {
    final int maxSet = ((_rackPipeCount - 1) / 3).floor();

    Widget pipeButton(int localIndex) {
      final trueIndex = (_currentSet * 3) + localIndex;
      final bool exists = trueIndex >= 0 && trueIndex < _rackPipeCount;

      if (!exists) {
        return Expanded(
          flex: 3,
          child: Opacity(
            opacity: 0.25,
            child: _BeveledButton(
              onTap: null,
              child: const Text(
                '—',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      }

      final bool selected =
          rack.allConduits.indexOf(rack.current) == trueIndex;

      return Expanded(
        flex: 3,
        child: _StyledPipeChip(
          label: 'Pipe ${trueIndex + 1}',
          selected: selected,
          onTap: () => _select(localIndex),
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: _BeveledButton(
            onTap: _currentSet <= 0
                ? null
                : () {
              setState(() {
                _currentSet--;
              });

              final newIndex = _currentSet * 3;
              if (newIndex < _rackPipeCount) {
                rack.select(newIndex);
              }
            },
            child: const RotatedBox(
              quarterTurns: 2,
              child: Text(
                "➜",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: spacing),

        pipeButton(0),

        SizedBox(width: spacing),

        pipeButton(1),

        SizedBox(width: spacing),

        pipeButton(2),

        SizedBox(width: spacing),

        Expanded(
          flex: 2,
          child: _BeveledButton(
            onTap: _currentSet >= maxSet
                ? null
                : () {
              setState(() {
                _currentSet++;
              });

              final newIndex = _currentSet * 3;
              if (newIndex < _rackPipeCount) {
                rack.select(newIndex);
              }
            },
            child: const Text(
              "➜",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
  void _finishOffsetIfPossible() {
    bool complete = false;
    if (rack.isRollingMode) {
      complete = rollingVerticalCtl.text.isNotEmpty &&
          rollingHorizontalCtl.text.isNotEmpty &&
          rollingAngleCtl.text.isNotEmpty &&
          rollingDistanceCtl.text.isNotEmpty &&
          rollingOverallCtl.text.isNotEmpty;
      if (complete) _onRollingInputSubmitted();
    } else {
      complete = offsetHeightCtl.text.isNotEmpty &&
          offsetAngleCtl.text.isNotEmpty &&
          offsetDistanceCtl.text.isNotEmpty &&
          offsetOverallCtl.text.isNotEmpty;
      if (complete) _onOffsetInputSubmitted();
    }

    if (complete) {
      setState(() {
        _showRackResults = true;
        _showOffsetInputs = false;
        _hideKeypad();
      });
    }
  }

  Widget _buildBottomButtons() {
    const spacing = 4.0;

    if (_isOffsetMode) {
      return Row(
        children: [
          // LEFT
          Expanded(
            child: _BeveledButton(
              active: rack.offsetDirectionSign == -1,
              onTap: () {
                rack.startOffsetLeft();
                setState(() => _rollingNeedsDirection = false);
              },
              child: const RotatedBox(
                quarterTurns: 2,
                child: Text("➜", style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(width: spacing),

          // UP
          Expanded(
            child: _BeveledButton(
              active: rack.offsetDirectionSign == 0,
              onTap: () {
                rack.startOffsetUp();
                setState(() => _rollingNeedsDirection = false);
              },
              child: const RotatedBox(
                quarterTurns: -1,
                child: Text("➜", style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(width: spacing),

          // DOWN
          Expanded(
            child: _BeveledButton(
              active: rack.offsetDirectionSign == 2,
              onTap: () {
                rack.startOffsetDown();
                setState(() => _rollingNeedsDirection = false);
              },
              child: const RotatedBox(
                quarterTurns: 1,
                child: Text("➜", style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(width: spacing),

          // RIGHT
          Expanded(
            child: _BeveledButton(
              active: rack.offsetDirectionSign == 1,
              onTap: () {
                rack.startOffsetRight();
                setState(() => _rollingNeedsDirection = false);
              },
              child: const Text("➜", style: TextStyle(color: kLight, fontSize: 24, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      );
    }

    if (_isNextRackMode) {
      return Row(
        children: [
          Expanded(
            child: _BeveledButton(
              onTap: _toggleParallel90sMode,
              child: Text(
                _isParallel90sMode ? "Back" : "90s",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (!_isParallel90sMode) ...[
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {
                  setState(() {
                    _isOffsetMode = true;
                    _isParallel90sMode = false;
                    _activeController = offsetDistanceCtl;
                    _isKeypadVisible = false;
                  });
                  rack.startOffsetUp();
                },
                child: const Text(
                  "Offsets",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {},
                child: const Text(
                  "Saddles",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _BeveledButton(
                onTap: () {
                  setState(() {
                    _showRackSetupStart = false;

                    _isKick90sMode = true;
                    _isParallel90sMode = false;
                    _isOffsetMode = false;
                    _isNextRackMode = false;

                    _showRackResults = false;

                    _activeController = kickStubCtl;
                    _isKeypadVisible = false;
                    _clearOnNextInput = true;
                    _showKickMeasurements = true;
                    _showKickTypeSelector = false;
                    _kickMeasurementsExpanded = true;
                  });

                  rack.setCalcMode(RackCalcMode.kick90);
                  rack.setKick90RackStyle(Kick90RackStyle.perpendicular);
                },
                child: const Text(
                  "Kicks",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _BeveledButton(
            onTap: () {
              setState(() {
                _isNextRackMode = true;
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: 2,
                  child: Text(
                    "➜",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "Next Rack",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: spacing),
        Expanded(
          child: _BeveledButton(
            onTap: () {},
            child: const Text(
              "Optimize",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
  void _returnToBenderScreen() {
    _hideKeypad();

    setState(() {
      _isOffsetMode = false;
      _isParallel90sMode = false;
      _isNextRackMode = false;
      _isKick90sMode = false;

      _showKickMeasurements = true;
      _showKickTypeSelector = false;

      _showRackSetupStart = true;
      _isRackSetupExpanded = false;
      _isRackBenderExpanded = true;
      _isRackBendTypeExpanded = false;
    });
  }
  void _goToChooseNextBend() {
    _hideKeypad();
    FocusScope.of(context).unfocus();

    rack.setIsFromBox(false); // Move out of transition mode for subsequent bends

    setState(() {
      _isProjectHubVisible = false; // Hide Hub to show the menu
      _showRackSetupStart = true;
      _choosingNextBend = true;
      _rackNextBendMode = true;
      _straightSticksCount = 1;

      // Collapse all setup steps
      _isRackSetupExpanded = false;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = false;

      _isKick90sMode = false;
      _showKickMeasurements = true;
      _showKickTypeSelector = false;

      _isParallel90sMode = false;
      _parallel90ShowResults = false;
      _showParallel90Measurements = true;

      _isOffsetMode = false;
      _showOffsetInputs = true;
      _showRackResults = false;
    });
  }
  void _topLeftArrowTap() {
    _hideKeypad();
    FocusScope.of(context).unfocus();

    if (widget.startInOffsetMode || widget.startInRollingOffsetMode) {
      Navigator.pop(context);
      return;
    }

    // Parallel 90 Results -> Construction Hub
    if (_isParallel90sMode && _parallel90ShowResults) {
      final label = rack.isFromBox ? '90° Up (Box Transition)' : '90° Rack';
      final gain = _selectedRackBender?.gain ?? rack.benderGain;
      final takeup = _selectedRackBender?.deduct ?? rack.benderTakeup;
      
      // Add to Hub with 90-specific metadata
      rack.addBendSegment(
        label, 
        90.0, 
        rack.stubLength + rack.legLength - gain, 
        multiplier: _rackPipeCount,
        stub: rack.stubLength,
        leg: rack.legLength,
        gain: gain,
        takeup: takeup,
      );
      _triggerHubFlash();

      _goToChooseNextBend();
      return;
    }

    // Kick Results -> Construction Hub
    if (_isKick90sMode && _showKickTypeSelector) {
      // Add to Hub (Kick 90 run is roughly Stub + Leg)
      rack.addBendSegment(
        'Kick 90', 
        90.0 + rack.kickAngle, 
        rack.kickStubLength + rack.kickLegLength, 
        multiplier: _rackPipeCount,
        stub: rack.kickStubLength,
      );
      _triggerHubFlash();

      _goToChooseNextBend();
      return;
    }

    // Offset Results -> Construction Hub
    if (_isOffsetMode && _showRackResults) {
      final label = rack.isRollingMode ? 'Rolling Offset' : 'Offset';
      rack.addBendSegment(
        label, 
        rack.bendAngle * 2, 
        rack.isFullStick ? 120.0 : rack.overallLength, 
        multiplier: _rackPipeCount,
      );
      _triggerHubFlash();

      _goToChooseNextBend();
      return;
    }

    _returnToBendTypeScreen();
  }

  void _topRightArrowTap() {
    _hideKeypad();
    FocusScope.of(context).unfocus();

    if (widget.startInOffsetMode || widget.startInRollingOffsetMode) {
      if (_isProjectHubVisible) {
        setState(() => _isProjectHubVisible = false);
        return;
      }
      Navigator.pop(context);
      return;
    }

    // Phase 1: Go from Results back to Measurements
    if (_showRackResults || _parallel90ShowResults || (_isKick90sMode && _showKickTypeSelector)) {
      if (rack.isFromBox && _parallel90ShowResults) {
        setState(() {
          _showRackSetupStart = true;
          _isRackSetupExpanded = false;
          _isRackBenderExpanded = false;
          _isRackBendTypeExpanded = true;
          _parallel90ShowResults = false;
          _isParallel90sMode = false; // Reset to prevent redundant info bars
        });
        return;
      }
      setState(() {
        _showRackResults = false;
        _showOffsetInputs = true;
        _parallel90ShowResults = false;
        _showParallel90Measurements = true;
        _showKickTypeSelector = false;
        _showKickMeasurements = true;
      });
      return;
    }

    // Phase 2: Sequential Back inside Kick Measurements
    if (_isKick90sMode) {
      if (_showKickBendingMethodCard) {
        setState(() {
          _showKickBendingMethodCard = false;
          _kickTypeConfirmed = true;
        });
        return;
      }
      if (_kickTypeConfirmed) {
        setState(() {
          _kickTypeConfirmed = false;
          _showKickTypeCard = true;
        });
        return;
      }
    }

    // Phase 3: Sequential Back inside Offset Measurements
    if (_isOffsetMode) {
      if (_showOffsetGeometryResults) {
        setState(() {
          _showOffsetGeometryResults = false;
          _showOffsetBendingMethod = true;
        });
        return;
      }
      if (_showOffsetBendingMethod) {
        setState(() {
          _showOffsetBendingMethod = false;
        });
        return;
      }
    }

    setState(() {
      _returnToBenderScreen();
    });
  }
  void _returnToBendTypeScreen() {
    _hideKeypad();

    setState(() {
      if (_isKick90sMode && _showKickTypeSelector) {
        _showKickMeasurements = true;
        _showKickTypeSelector = false;
        _kickMeasurementsExpanded = true;
        _activeController = kickStubCtl;
        return;
      }

      _isOffsetMode = false;
      _isParallel90sMode = false;
      _isNextRackMode = false;
      _isKick90sMode = false;

      _showKickMeasurements = true;
      _showKickTypeSelector = false;

      _showRackSetupStart = true;
      _isRackSetupExpanded = false;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = true;
    });
  }

  void _toggleProjectHub() {
    setState(() {
      _isProjectHubVisible = !_isProjectHubVisible;
      if (_isProjectHubVisible) {
        // Show guidance initially and start 30-second fade timer
        _showHubGuidance = true;
        _hubGuidanceTimer?.cancel();
        _hubGuidanceTimer = Timer(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() => _showHubGuidance = false);
          }
        });
      } else {
        _hubGuidanceTimer?.cancel();
      }
    });
  }

  Widget _buildProjectHub() {
    int totalSticks = 0;
    for (var seg in rack.runSequence) {
      totalSticks += seg.materials['stick'] ?? 0;
    }

    final totalPipeFeet = totalSticks * 10.0;
    final totalDeg = rack.totalRunDegrees;
    final bool warning = totalDeg >= 360;

    return Positioned(
      top: 0, left: 0, right: 0,
      bottom: 110, // SOLID GAP: Maintains 22px clearance above Info Bar at all times
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          // Swipe Up anywhere on the console to close
          if (details.primaryDelta! < -7) {
            setState(() => _isProjectHubVisible = false);
          }
        },
        child: Material(
          color: kBlack, // SOLID BLACK curtain stops exactly here
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 10), // Balanced machine case margins
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC0C0C0), width: 2.0),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(200), blurRadius: 15, spreadRadius: 2),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias, // Ensures internal gray bar follows the rounded SILVER border
                  child: Column(
                    children: [
                      // TOP DASHBOARD: Machined Metal Look
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                          ),
                          // Matches the machine case curve precisely (20px - 2px border = 18px)
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _materialMiniItem('Sticks', '$totalSticks'),
                            _materialMiniItem('Pipe Footage', '${totalPipeFeet.toInt()} ft'),
                            _materialMiniItem('Run Dist', RackState.feetInchFmt(rack.totalRunLength)),
                            _materialMiniItem('Degrees', '${totalDeg.toInt()}°', valueColor: warning ? kRed : kLight),
                          ],
                        ),
                      ),
                      // Silver divider below header
                      Container(height: 1.5, color: const Color(0xFFC0C0C0)),

                      if (warning)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: kRed,
                          child: const Text('⚠️ NEC 360° LIMIT EXCEEDED', textAlign: TextAlign.center, style: TextStyle(color: kLight, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),

                      Expanded(
                        child: ListView(
                          controller: _hubScrollCtl,
                          padding: const EdgeInsets.all(12),
                          children: [
                            ...() {
                              final List<Widget> items = [];
                              for (int i = 0; i < rack.runSequence.length; i++) {
                                items.add(_buildSegmentCard(i + 1, rack.runSequence[i], index: i));
                              }
                              return items;
                            }(),

                            if (_isAddingStraightSegment)
                              _buildStraightPipeAdder(isHub: true, insertIndex: _lastTappedSegmentIndex),

                            if (_activeController == supportPosCtl && _editingSupportIndex == null)
                              _buildSupportAdder(),

                            if (rack.runSequence.isEmpty && !_isAddingStraightSegment)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 40.0),
                                  child: Text(
                                    'No segments added. Start below.',
                                    style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ADD NEW SUPPORT',
                                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      if (_editingSupportIndex != null && _editingSupportIndex! < rack.supportPositions.length) {
                                        final prevPos = rack.supportPositions[_editingSupportIndex!];
                                        rack.addSupport(prevPos + 120.0, label: 'Support (${RackState.feetInchFmt(120.0)} from last)');
                                      } else if (rack.supportPositions.isNotEmpty) {
                                        rack.addSupport(rack.supportPositions.last + 120.0, label: 'Support (${RackState.feetInchFmt(120.0)} from last)');
                                      } else {
                                        rack.addSupport(36.0, label: 'Vertical (from Box)');
                                      }
                                      
                                      supportPosCtl.text = '120"';
                                      _editingSupportIndex = null;
                                      _clearOnNextInput = true;
                                    });
                                    _showKeypad(supportPosCtl);
                                    
                                    _hubScrollCtl.animateTo(
                                      _hubScrollCtl.position.maxScrollExtent + 500,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: kGreen.withAlpha(40),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: kGreen.withAlpha(100)),
                                    ),
                                    child: const Text('+ SUPPORT', style: TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ],
                            ),
                            if (_isKeypadVisible)
                               const SizedBox(height: 450),
                          ],
                        ),
                      ),
                      
                      // BOTTOM ACTION CONSOLE (Moved inside the rounded box)
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                          ),
                          border: Border(top: BorderSide(color: Color(0xFFC0C0C0), width: 1.5)),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _BeveledButton(
                                    height: 52, // Taller
                                    primary: true, // Bright Silver Pop
                                    onTap: () {
                                      setState(() {
                                        _isAddingStraightSegment = true;
                                        _editingSegmentIndex = null;
                                        straightRunLengthCtl.clear();
                                      });
                                      _showKeypad(straightRunLengthCtl);
                                    },
                                    child: const Text('+ STRAIGHT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _BeveledButton(
                                    height: 52,
                                    primary: true,
                                    onTap: _goToChooseNextBend,
                                    child: const Text('+ BEND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _BeveledButton(
                                    height: 52,
                                    primary: true,
                                    onTap: () {
                                      rack.addFittingSegment('Pull Box', 0.0, atIndex: _lastTappedSegmentIndex);
                                      _triggerHubFlash();
                                    },
                                    child: const Text('+ PULL POINT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Visual Pull Handle
                            Container(
                              width: 45,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportAdder() {
    const accent = kGreen;
    final String currentVal = supportPosCtl.text;
    final lastPos = rack.supportPositions.isEmpty ? 0.0 : rack.supportPositions.last;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(120), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten, color: accent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'NEXT SUPPORT',
                  style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => _hideKeypad(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showKeypad(supportPosCtl),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kGreen, width: 2.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          currentVal.isEmpty ? '120"' : '$currentVal"',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _BeveledButton(
                width: 100,
                height: 44,
                active: false,
                redOutline: true,
                onTap: () {
                  final gap = supportPosCtl.text.isEmpty ? 120.0 : RackState.parseInches(supportPosCtl.text);
                  rack.addSupport(lastPos + gap);
                  _hideKeypad();
                  _triggerHubFlash();
                },
                child: const Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Suggests 120" (10ft) from last support.',
            style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _materialMiniItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700)),
        Text(value, style: TextStyle(color: valueColor ?? kLight, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildStraightPipeAdder({bool isHub = false, int? insertIndex}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.linear_scale, color: Colors.white54, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHub ? 'STRAIGHT PIPES' : 'ADD STRAIGHT PIPES',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                    ),
                    Text(
                      '10ft (120") Sticks',
                      style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (isHub)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _isAddingStraightSegment = false),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Stick Counter area (left)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BeveledButton(
                    width: 38, height: 38,
                    onTap: () {
                      setState(() {
                        _straightSticksCount = math.max(1, _straightSticksCount - 1);
                        straightRunLengthCtl.text = (_straightSticksCount * 120).toString();
                      });
                    },
                    child: const Text('-', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    width: 36,
                    alignment: Alignment.center,
                    child: Text('$_straightSticksCount', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                  ),
                  _BeveledButton(
                    width: 38, height: 38,
                    onTap: () {
                      setState(() {
                        _straightSticksCount++;
                        straightRunLengthCtl.text = (_straightSticksCount * 120).toString();
                      });
                    },
                    child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // ADD button (above the input field visually in the final result)
              _BeveledButton(
                width: 100,
                height: 38,
                active: false,
                redOutline: true,
                onTap: () {
                  final length = straightRunLengthCtl.text.isEmpty 
                      ? (_straightSticksCount * 120.0) 
                      : RackState.parseInches(straightRunLengthCtl.text);
                  
                  rack.addStraightSegment(length, multiplier: _rackPipeCount, atIndex: insertIndex);
                  _triggerHubFlash();
                  
                  setState(() {
                    _isAddingStraightSegment = false;
                    _straightSticksCount = 1;
                    straightRunLengthCtl.clear();
                    _hideKeypad();
                  });
                },
                child: const Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Custom Length Input (Matches ADD button size and sits below it)
          Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (straightRunLengthCtl.text.isEmpty || straightRunLengthCtl.text == '0') {
                     straightRunLengthCtl.text = (_straightSticksCount * 120).toString();
                  }
                  _showKeypad(straightRunLengthCtl);
                },
                child: Container(
                  width: 100,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _activeController == straightRunLengthCtl ? kGreen : Colors.white24,
                      width: _activeController == straightRunLengthCtl ? 2.0 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      straightRunLengthCtl.text.isEmpty ? '${_straightSticksCount * 120}"' : '${straightRunLengthCtl.text}"',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(int num, RunSegment seg, {required int index}) {
    Color accent;
    IconData icon;
    switch (seg.type) {
      case RunSegmentType.straight: accent = Colors.blueAccent; icon = Icons.linear_scale; break;
      case RunSegmentType.bend: accent = kRed; icon = Icons.architecture; break;
      case RunSegmentType.fitting: accent = kGreen; icon = Icons.crop_square; break;
    }

    final bool isEditing = _editingSegmentIndex == index;
    final bool isExpanded = _expandedHubIndices.contains(index);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _lastTappedSegmentIndex = index;
              if (isExpanded) {
                _expandedHubIndices.remove(index);
              } else {
                _expandedHubIndices.add(index);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isEditing ? accent : accent.withAlpha(80), width: isEditing ? 2.0 : 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: accent.withAlpha(40), shape: BoxShape.circle),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STAGE $num', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w900)),
                      if (isEditing && seg.type == RunSegmentType.straight)
                         Text('${straightRunLengthCtl.text}"', style: const TextStyle(color: kLight, fontSize: 17, fontWeight: FontWeight.w900))
                      else
                         Text(seg.label, style: const TextStyle(color: kLight, fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                if (seg.degrees > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text('${seg.degrees.toInt()}°', style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                
                Theme(
                  data: Theme.of(context).copyWith(cardColor: const Color(0xFF222222)),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onSelected: (val) {
                      if (val == 'delete') {
                        rack.removeSegment(index);
                      } else if (val == 'edit') {
                        if (seg.type == RunSegmentType.straight) {
                          setState(() {
                            _editingSegmentIndex = index;
                            _isAddingStraightSegment = false;
                            straightRunLengthCtl.text = RackState.inchFmt(seg.length).replaceAll('"', '');
                          });
                          _showKeypad(straightRunLengthCtl);
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (seg.type == RunSegmentType.straight)
                        const PopupMenuItem(value: 'edit', child: Text('Edit Length')),
                      const PopupMenuItem(value: 'delete', child: Text('Remove Step', style: TextStyle(color: kRed))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 14, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (seg.type == RunSegmentType.straight) ...[
                   _hubDetailRow('Total Length Added', RackState.inchFmt(seg.length)),
                   _hubDetailRow('Material Used', '${seg.materials['stick']} sticks'),
                ] else if (seg.type == RunSegmentType.bend) ...[
                   if (seg.stub != null)
                      _hubDetailRow('Stub (to back of 90)', RackState.inchFmt(seg.stub!)),
                   if (seg.leg != null)
                      _hubDetailRow('Leg (after turn)', RackState.inchFmt(seg.leg!)),
                   
                   if (seg.degrees == 90.0 && index > 0) ...[
                      const SizedBox(height: 12),
                      _CornerDiagram(
                        segmentIndex: index,
                        inOffset: seg.inSupportOffset,
                        outOffset: seg.outSupportOffset,
                        onChanged: (inVal, outVal) {
                          _showAdjustSubsequentDialog(index, inVal, outVal);
                        },
                      ),
                   ],
                ],
                
                // Professional Overhang Details & SUPPORTS
                ...() {
                  final double start = rack.runSequence.sublist(0, index).fold(0.0, (sum, s) => sum + s.length);
                  final double end = start + seg.length;
                  
                  // Precision filtering: ensure supports belong to THIS segment stage only
                  final supportsInSegment = rack.supportPositions.where((p) {
                    if (index == 0) return p >= 0 && p <= end;
                    return p > start && p <= end;
                  }).toList();
                  
                  final double lastSup = supportsInSegment.isEmpty 
                      ? (index == 0 ? 0.0 : start) 
                      : supportsInSegment.last;

                  final double overhang = end - lastSup;

                  final List<Widget> segmentItems = [
                    const Divider(color: Colors.white10, height: 12),
                    _hubDetailRow('Pipe past Support', RackState.inchFmt(overhang)),
                  ];

                  if (supportsInSegment.isNotEmpty) {
                    segmentItems.add(const SizedBox(height: 12));
                    segmentItems.add(const Text('SUPPORTS', style: TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1)));
                    segmentItems.add(const SizedBox(height: 6));
                    
                    for (var pos in supportsInSegment) {
                       final supIdx = rack.supportPositions.indexOf(pos);
                       segmentItems.add(_supportListRow(supIdx + 1, pos, index: supIdx));
                    }
                  }
                  
                  return segmentItems;
                }(),
                const SizedBox(height: 4),
              ],
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _hubDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _supportListRow(int num, double pos, {required int index}) {
    final String? label = rack.getSupportLabel(pos);
    final bool isSelected = _editingSupportIndex == index;
    
    // Logic: Extract the user-friendly relative value from the label if possible
    // e.g. "Horizontal (off Wall) | 50\"" -> we want to show 50" as the main editable number
    String mainValueDisp = "";
    String cleanTitle = label ?? 'Support $num';
    String distText = "";
    
    if (label != null && label.contains(' | ')) {
      final parts = label.split(' | ');
      if (label.contains('Turn')) {
        // Special case for 90 degree turnaround supports
        // label looks like: "Support (Before Turn) | 24\" | 42\" from last coupling"
        mainValueDisp = parts[1]; // "24\""
        cleanTitle = '$mainValueDisp from back of 90';
        if (parts.length > 2) {
           distText = parts[2]; // "42\" from last coupling"
        }
      } else {
        cleanTitle = parts[0];
        mainValueDisp = parts[1];
        if (parts.length > 2) {
          distText = parts[2];
        }
      }
    } else {
      // Default to gap-based for normal sequential supports
      double distFromLast = pos;
      if (index > 0) {
        distFromLast = pos - rack.supportPositions[index - 1];
      }
      mainValueDisp = RackState.inchFmt(distFromLast);
    }

    if (cleanTitle == 'Support') cleanTitle = 'Next Support';

    if (cleanTitle == 'Horizontal (off Wall)') {
      distText = '$mainValueDisp from wall';
    } else if (cleanTitle == 'Vertical (from Box)' || cleanTitle == 'Support (from Box)') {
      distText = '$mainValueDisp from box';
    } else if (distText.isEmpty) {
      distText = (index == 0) 
          ? 'First Support: $mainValueDisp'
          : '$mainValueDisp from last';
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _editingSupportIndex = index;
          supportPosCtl.text = mainValueDisp.replaceAll('"', '');
          _clearOnNextInput = true;
        });
        _showKeypad(supportPosCtl);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? kGreen.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: kGreen, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanTitle, 
                    style: TextStyle(
                      color: isSelected ? kGreen : Colors.white70, 
                      fontSize: 14, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  Text(distText, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('Actual Run Dist: ${RackState.feetInchFmt(pos)}', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? kGreen : Colors.white24, width: 1.2),
              ),
              child: Text(
                isSelected ? (supportPosCtl.text.isEmpty ? '0"' : (supportPosCtl.text.contains('"') ? supportPosCtl.text : '${supportPosCtl.text}"')) : mainValueDisp,
                style: TextStyle(color: isSelected ? kLight : kGreen, fontSize: 18, fontWeight: FontWeight.w900)
              ),
            ),
            const SizedBox(width: 6),
            Theme(
              data: Theme.of(context).copyWith(cardColor: const Color(0xFF222222)),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white24, size: 20),
                onSelected: (val) {
                  if (val == 'delete') rack.removeSupport(index);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'delete', child: Text('Remove Support', style: TextStyle(color: kRed))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  bool get _showInitialWorkflowArrows {
    return true; // Always show both arrows once in results phase
  }

  bool get _showNextBendArrowOnly {
    return _rackNextBendMode &&
        !_showRackSetupStart &&
        (_isParallel90sMode || _isOffsetMode || _isKick90sMode);
  }

  @override
  Widget build(BuildContext context) {
    final rack = Provider.of<RackState>(context);
    
    // Safety Guard: If list is empty, don't build result-dependent widgets yet
    if (rack.allConduits.isEmpty) {
      return const Scaffold(backgroundColor: kBlack, body: Center(child: CircularProgressIndicator()));
    }

    final selectedPipeIndexInSet = (rack.allConduits.isNotEmpty && rack.selectedPipeIndex < rack.allConduits.length)
        ? (rack.selectedPipeIndex % 3)
        : 0;
    final selectedPipeIndex = rack.selectedPipeIndex;

    final conduit = (rack.allConduits.isNotEmpty && selectedPipeIndex < rack.allConduits.length)
        ? rack.allConduits[selectedPipeIndex]
        : rack.current;

    final markA = RackState.inchFmt(conduit.markA);
    final markB = RackState.inchFmt(conduit.markB);
    final cut = RackState.inchFmt(conduit.ol);

    final labels = List.generate(3, (i) => (_currentSet * 3) + i + 1);
    final bool parallel90Complete =
        _isParallel90sMode &&
            stubCtl.text.trim().isNotEmpty &&
            legCtl.text.trim().isNotEmpty;
    const spacing = 4.0; // Standardized to match setup screens (e.g. _buildRackSetupStartScreen)

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        automaticallyImplyLeading: false,

        leadingWidth: 165,

        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 2),
            IconButton(
              icon: const Icon(Icons.home, color: kLight, size: 24),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                  (route) => false,
                );
              },
            ),
            if (!_showRackSetupStart || _isOffsetMode || _isKick90sMode || _isParallel90sMode) ...[
              SizedBox(
                width: 54,
                child: _MiniArrowButton(
                  label: '⬅',
                  onTap: _topLeftArrowTap,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 54,
                child: _MiniArrowButton(
                  label: '➡',
                  onTap: _topRightArrowTap,
                ),
              ),
            ],
          ],
        ),

        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: false, // Scoot title to the left
        elevation: 0.5,
        title: Transform.translate(
          offset: const Offset(-12, 0), // Nudge to avoid arrow crowding
          child: const Text(
            'Rack Builder',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _infoAnimCtrl,
                child: AnimatedBuilder(
                  animation: _infoAnimCtrl,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (rect) {
                        return SweepGradient(
                          colors: [
                            (_hubRecentlyUpdated ? Colors.blueAccent : kLight).withAlpha(0),
                            (_hubRecentlyUpdated ? Colors.blueAccent : kLight).withAlpha((255 * (0.2 + (0.7 * (0.5 + 0.5 * math.sin(_infoAnimCtrl.value * 2 * math.pi))))).toInt()),
                            (_hubRecentlyUpdated ? Colors.blueAccent : kLight).withAlpha(0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(rect);
                      },
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _hubRecentlyUpdated ? Colors.blueAccent : kLight, width: 2.0)),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                icon: Text('H', style: TextStyle(color: _hubRecentlyUpdated ? Colors.blueAccent : kLight, fontSize: 18, fontWeight: FontWeight.w900)),
                onPressed: _toggleProjectHub,
              ),
            ],
          ),
          const SizedBox(width: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              if (!_hasViewedInfo)
                RotationTransition(
                  turns: _infoAnimCtrl,
                  child: AnimatedBuilder(
                    animation: _infoAnimCtrl,
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
                                              math.sin(_infoAnimCtrl.value *
                                                  2 *
                                                  math.pi)))),
                              kLight.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(rect);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
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
                icon: const Icon(Icons.info_outline, color: kLight, size: 24),
                onPressed: () {
                  setState(() => _hasViewedInfo = true);
                  _showInfoDialog();
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(spacing),
            child: Container(
              padding: EdgeInsets.zero,
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                children: <Widget>[
                  if (_showRackSetupStart && !_isOffsetMode) ...[
                    _buildRackSetupStartScreen(),
                    _RackSetupGuideBar(
                      text: _isProjectHubVisible 
                          ? 'PROJECT HUB: Review your construction stages. Expand a stage to view its supports and geometry. Tap any measurement to edit.'
                          : _rackSetupInfoText,
                      isHubVisible: _isProjectHubVisible,
                    ),
                  ] else ...[
                    if (_isOffsetMode && !_showRackResults)
                      Column(
                        children: [
                          if (!_showOffsetBendingMethod && !_showOffsetGeometryResults) ...[
                            if (rack.calcMode == RackCalcMode.rollingOffset ||
                                rack.calcMode == RackCalcMode.parallelRollingOffset)
                              _RollingInputCard(
                                distanceCtl: rollingDistanceCtl,
                                verticalCtl: rollingVerticalCtl,
                                horizontalCtl: rollingHorizontalCtl,
                                overallCtl: rollingOverallCtl,
                                angleCtl: rollingAngleCtl,
                                onDistanceTap: () => _showKeypad(rollingDistanceCtl),
                                onVerticalTap: () => _showKeypad(rollingVerticalCtl),
                                onHorizontalTap: () => _showKeypad(rollingHorizontalCtl),
                                onOverallTap: () => _showKeypad(rollingOverallCtl),
                                onAngleTap: () => _showKeypad(rollingAngleCtl),
                                activeController: _activeController,
                                isFullStick: rack.isFullStick,
                                onFullStickToggle: (val) => rack.setFullStick(val),
                                isExpanded: _offsetMeasurementsExpanded,
                                onHeaderTap: () => setState(() => _offsetMeasurementsExpanded = !_offsetMeasurementsExpanded),
                                spacingValue: _rackSpacingIsCenterToCenter 
                                    ? RackState.inchFmt(math.max(0, RackState.parseInches(runC2C.text) - _rackPipeOd(_rackDefaultPipeSize)))
                                    : RackState.inchFmt(RackState.parseInches(runC2C.text)),
                                c2cValue: _rackSpacingIsCenterToCenter
                                    ? RackState.inchFmt(RackState.parseInches(runC2C.text))
                                    : RackState.inchFmt(
                                        (_rackPipeSizes.isNotEmpty ? _rackPipeOd(_rackPipeSizes.first) / 2 : 0.0) +
                                        RackState.parseInches(runC2C.text) +
                                        (_rackPipeSizes.length > 1 ? _rackPipeOd(_rackPipeSizes[1]) / 2 : (_rackPipeSizes.isNotEmpty ? _rackPipeOd(_rackPipeSizes.first) / 2 : 0.0))
                                      ),
                              )
                            else
                              _OffsetInputCard(
                                heightCtl: offsetHeightCtl,
                                angleCtl: offsetAngleCtl,
                                distanceCtl: offsetDistanceCtl,
                                overallCtl: offsetOverallCtl,
                                onHeightTap: () => _showKeypad(offsetHeightCtl),
                                onAngleTap: () => _showKeypad(offsetAngleCtl),
                                onDistanceTap: () => _showKeypad(offsetDistanceCtl),
                                onOverallTap: () => _showKeypad(offsetOverallCtl),
                                activeController: _activeController,
                                isFullStick: rack.isFullStick,
                                onFullStickToggle: (val) => rack.setFullStick(val),
                                isExpanded: _offsetMeasurementsExpanded,
                                onHeaderTap: () => setState(() => _offsetMeasurementsExpanded = !_offsetMeasurementsExpanded),
                                spacingValue: _rackSpacingIsCenterToCenter 
                                    ? RackState.inchFmt(math.max(0, RackState.parseInches(runC2C.text) - _rackPipeOd(_rackDefaultPipeSize)))
                                    : RackState.inchFmt(RackState.parseInches(runC2C.text)),
                                c2cValue: _rackSpacingIsCenterToCenter
                                    ? RackState.inchFmt(RackState.parseInches(runC2C.text))
                                    : RackState.inchFmt(
                                        (_rackPipeSizes.isNotEmpty ? _rackPipeOd(_rackPipeSizes.first) / 2 : 0.0) +
                                        RackState.parseInches(runC2C.text) +
                                        (_rackPipeSizes.length > 1 ? _rackPipeOd(_rackPipeSizes[1]) / 2 : (_rackPipeSizes.isNotEmpty ? _rackPipeOd(_rackPipeSizes.first) / 2 : 0.0))
                                      ),
                              ),
                            const SizedBox(height: 12),
                            _buildSupportPlanningBar(),
                            const SizedBox(height: 8),
                            _buildBottomButtons(),
                            const SizedBox(height: 8),
                            _BeveledButton(
                              active: true,
                              onTap: () {
                                if (rack.isRollingMode) {
                                  _onRollingInputSubmitted();
                                } else {
                                  _onOffsetInputSubmitted();
                                }
                                setState(() {
                                  _offsetMeasurementsExpanded = false;
                                  _showOffsetBendingMethod = true;
                                  _hideKeypad();
                                });
                              },
                              child: const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  color: kLight,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ] else if (_showOffsetBendingMethod) ...[
                            _buildUniversalBendingMethodCard(),
                            const SizedBox(height: 12),
                            _BeveledButton(
                              active: true,
                              onTap: () {
                                setState(() {
                                  _showOffsetBendingMethod = false;
                                  _showOffsetGeometryResults = true;
                                });
                              },
                              child: const Text(
                                'CALCULATE',
                                style: TextStyle(
                                  color: kLight,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ] else if (_showOffsetGeometryResults) ...[
                            _buildOffsetGeometryResultsCard(),
                            const SizedBox(height: 12),
                            _BeveledButton(
                              active: true,
                              onTap: () {
                                // Add to Hub
                                final label = rack.isRollingMode ? 'Rolling Offset' : 'Offset';
                                rack.addBendSegment(label, rack.bendAngle * 2, rack.isFullStick ? 120.0 : rack.overallLength, multiplier: _rackPipeCount);
                                _triggerHubFlash();

                                setState(() {
                                  _showRackResults = true;
                                  _showOffsetInputs = false;
                                  _showRackSetupStart = false;
                                  _showOffsetBendingMethod = false;
                                  _showOffsetGeometryResults = false;
                                  _hideKeypad();
                                });
                              },
                              child: const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  color: kLight,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else if (_isKick90sMode)
                      Column(
                        children: [
                          if (_showKickMeasurements) ...[
                            _SectionContainer(
                              label: '4. KICK MEASUREMENTS',
                              children: [
                                _subHeader(
                                  label: 'Kick Type',
                                  isExpanded: _showKickTypeCard,
                                  onToggle: () {
                                    setState(() {
                                      _showKickTypeCard = !_showKickTypeCard;
                                      if (_showKickTypeCard) {
                                        _kickTypeConfirmed = false;
                                        _showKickBendingMethodCard = false;
                                      }
                                    });
                                  },
                                ),
                                if (_showKickTypeCard) ...[
                                  const SizedBox(height: 4),
                                  _buildKickTypeCard(),
                                ],
                                if (_kickTypeConfirmed) ...[
                                  const SizedBox(height: 4),
                                  _Kick90RackInputCard(
                                    isExpanded: _kickMeasurementsExpanded,
                                    onHeaderTap: () {
                                      setState(() {
                                        _kickMeasurementsExpanded = !_kickMeasurementsExpanded;
                                      });
                                    },
                                    onContinue: () {
                                      _applyKickRackInputsToState();
                                      _sendPipeProgressionOffsetsToRackState();
                                      _hideKeypad();
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        _kickMeasurementsExpanded = false;
                                        _showKickBendingMethodCard = true;
                                        _kickBendingMethodConfirmed = true;
                                      });
                                    },
                                    stubCtl: kickStubCtl,
                                    kickHeightCtl: kickHeightCtl,
                                    kickAngleCtl: kickAngleCtl,
                                    kickMatchBendCtl: kickMatchBendCtl,
                                    legCtl: kickLegCtl,
                                    spacingCtl: runC2C,
                                    activeController: _activeController,
                                    kickMarkMethod: rack.bendingMethod,
                                    usesMatchBendInput: _kickUsesMatchBendInput,
                                    isCenterToCenter: _rackSpacingIsCenterToCenter,
                                    onStubTap: () => _showKeypad(kickStubCtl),
                                    onKickHeightTap: () => _showKeypad(kickHeightCtl),
                                    onKickAngleTap: () => _showKeypad(kickAngleCtl),
                                    onKickMatchBendTap: () => _showKeypad(kickMatchBendCtl),
                                    onUseNotch: () {
                                      setState(() {
                                        rack.setBendingMethod(bending_data.BendingMethod.notch);
                                      });
                                    },
                                    onUseCenterline: () {
                                      setState(() {
                                        rack.setBendingMethod(bending_data.BendingMethod.centerline);
                                      });
                                    },
                                    onLegTap: () => _showKeypad(kickLegCtl),
                                    onSpacingTap: () => _showKeypad(runC2C),
                                    onSpaceBetweenTap: () {
                                      setState(() {
                                        _rackSpacingIsCenterToCenter = false;
                                      });
                                      _sendPipeProgressionOffsetsToRackState();
                                    },
                                    onCenterToCenterTap: () {
                                      setState(() {
                                        _rackSpacingIsCenterToCenter = true;
                                      });
                                      _sendPipeProgressionOffsetsToRackState();
                                    },
                                    isFromBox: rack.isFromBox,
                                    distanceFromBoxCtl: distanceFromBoxCtl,
                                    onDistanceFromBoxTap: () => _showKeypad(distanceFromBoxCtl),
                                    measureToTop: rack.measureToTop,
                                    onToggleStrut: () => setState(() => rack.setMeasureToTop(!rack.measureToTop)),
                                  ),
                                ],
                                if (_showKickBendingMethodCard) ...[
                                  const SizedBox(height: 4),
                                  _buildKickBendingMethodCard(),
                                  const SizedBox(height: 8),
                                  _BeveledButton(
                                    active: false,
                                    redOutline: true,
                                    subtle: true,
                                    onTap: () {
                                      _applyKickRackInputsToState();
                                      _sendPipeProgressionOffsetsToRackState();
                                      _hideKeypad();
                                      FocusScope.of(context).unfocus();

                                      setState(() {
                                        _showKickBendingMethodCard = false;
                                        _kickBendingMethodConfirmed = false;
                                        _showKickMeasurements = false;
                                        _showKickTypeSelector = true;
                                      });
                                      _startKickResultCycle();
                                    },
                                    child: const Text(
                                      'CALCULATE',
                                      style: TextStyle(
                                        color: kLight,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            // GRAPHIC IS ALWAYS VISIBLE BELOW THE MAIN CONTAINER
                            if (!_showKickTypeSelector) ...[
                              _KickStylePictureCard(
                                selectedKickStyle: _selectedKickStyle,
                                selectedPipeIndexInSet: selectedPipeIndexInSet,
                                kickDirection: _kickDirection,
                                labels: labels,
                                showDots: false,
                                cardHeight: 210, // Slightly shorter for setup
                                onDirectionChanged: (value) {
                                  setState(() {
                                    _kickDirection = value;
                                  });
                                },
                                onDotTap: (_) {},
                              ),
                              const SizedBox(height: 4),
                              if (_showKickTypeCard) ...[
                                _buildKickDirectionRow(),
                                const SizedBox(height: 4),
                              ],
                            ],
                            if (!_showKickTypeSelector && !_showKickBendingMethodCard)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFC8C8C8),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  _kickTypeConfirmed
                                      ? 'Enter the measurements for the first kick. The next pipes in the rack will be calculated on the results screen.'
                                      : 'Choose a kick type and compare it with the picture, then press Continue to enter measurements.\nTip: Rotate your phone to landscape mode to visualize the conduit layout from a top-down view.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: kLight,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                          ],
                          if (_showKickTypeSelector) ...[
                            _SectionTitleButton(
                              label: '5. RESULTS',
                              fontSize: 19,
                              height: 50,
                              isActive: true,
                              onTap: () {},
                            ),
                            const SizedBox(height: 4),
                            _buildRackPreview(showSizeButtons: false),
                            Column(
                              children: [
                                const SizedBox(height: 4),
                                _buildKickResultsCard(),
                                const SizedBox(height: 4),
                                _KickStylePictureCard(
                                  selectedKickStyle: _selectedKickStyle,
                                  cardHeight: 220, // Increased height for Results to fix alignment
                                  selectedPipeIndexInSet: selectedPipeIndexInSet,
                                  kickDirection: _kickDirection,
                                  labels: labels,
                                  onDirectionChanged: (value) {
                                    setState(() {
                                      _kickDirection = value;
                                    });
                                  },
                                  onDotTap: (pipeIndexInSet) {
                                    final trueIndex = (_currentSet * 3) + pipeIndexInSet;
                                    if (trueIndex < _rackPipeCount) {
                                      setState(() {
                                        _selectedRackPipe = trueIndex;
                                      });
                                      rack.select(trueIndex);
                                    }
                                  },
                                ),
                                const SizedBox(height: 4),
                                _buildKickMarkedPipeCard(),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(180),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFC0C0C0),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    _showKickResultAlternative
                                        ? 'Hub (H) has recorded materials & total degrees. Use (⬅) for your next construction stage.'
                                        : (_selectedKickStyle == 'Across'
                                            ? 'Across: Rack orientation flips. Box spacing varies by angle. Review marks via conduit selector.'
                                            : _selectedKickStyle == 'Forward'
                                            ? 'Forward: Spacing stays tight to the run. Review marks via conduit selector.'
                                            : _selectedKickStyle == 'Same Angle'
                                            ? 'Same Angle: Uniform kicks. Review individual marks via conduit selector.'
                                            : 'Same Start: Bends share the same start mark. Review via conduit selector.'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: kLight,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      )
                    else
                      Column(
                        children: [
                          if (_isParallel90sMode &&
                              (!_parallel90ShowResults || _showParallel90Measurements)) ...[
                            _buildParallel90sInputs(),
                          ],
                        ],
                      ),
                  ],

                  if (_isParallel90sMode && _parallel90ShowResults) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showParallel90Measurements = !_showParallel90Measurements;
                          });
                        },
                        child: Text(
                          _showParallel90Measurements ? 'Hide Measurements' : 'Show Measurements',
                          style: const TextStyle(color: kLight, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // RESULTS AREA
                  if (!_showRackSetupStart &&
                      (!_isOffsetMode || _showRackResults) &&
                      (!_isParallel90sMode || _parallel90ShowResults)) ...[
                    if (!_isKick90sMode) ...[
                      _buildRackPreview(showSizeButtons: false),
                      const SizedBox(height: 4),
                      _MarksCard(
                        markA: markA,
                        markB: markB,
                        shift: selectedPipeIndex <= 0 ? '0' : RackState.inchFmt(rack.graduationForPipe(selectedPipeIndex)),
                        cut: cut,
                        isParallel90s: _isParallel90sMode,
                        parallel90Complete: parallel90Complete,
                        rack: rack,
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (!_isKick90sMode)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Transform.translate(
                            offset: const Offset(0, pipeVisualizationVerticalOffset),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: AspectRatio(
                                      aspectRatio: designW / designH,
                                      child: LayoutBuilder(
                                        builder: (context, c) {
                                          final scale = (c.maxWidth / designW < c.maxHeight / designH)
                                              ? c.maxWidth / designW
                                              : c.maxHeight / designH;
                                          final canvasW = designW * scale;
                                          final canvasH = designH * scale;
                                          final offsetX = (c.maxWidth - canvasW) / 2;
                                          final offsetY = (c.maxHeight - canvasH) / 2;

                                          double sx(double x) => x * scale;
                                          double sy(double y) => y * scale;

                                          int visualPipeIndex(int visualIndex) {
                                            if (_isParallel90sMode) {
                                              if (_parallel90Direction == 'left' || _parallel90Direction == 'right') {
                                                return 2 - visualIndex;
                                              }
                                              return visualIndex;
                                            }
                                            if (_isOffsetMode && rack.offsetDirectionSign == -1) {
                                              return 2 - visualIndex;
                                            }
                                            return visualIndex;
                                          }

                                          Color dotColorForVisual(int visualIndex) {
                                            final pipeIndex = visualPipeIndex(visualIndex);
                                            return selectedPipeIndexInSet == pipeIndex ? kRed : Colors.white38;
                                          }

                                          double extraYBubbles = 0.0;
                                          double extraYMarks = 0.0;
                                          double extraYPipe = 0.0;
                                          double pipeScaleX = 0.9;

                                          if (_isOffsetMode) {
                                            if (rack.offsetDirectionSign == -1) {
                                              extraYBubbles = leftOffsetDotShift;
                                              extraYMarks = leftOffsetMarkShift;
                                              extraYPipe = leftOffsetPipeShift;
                                              pipeScaleX = leftOffsetPipeScaleX;
                                            } else if (rack.offsetDirectionSign == 1) {
                                              extraYBubbles = rightOffsetDotShift;
                                              extraYMarks = rightOffsetMarkShift;
                                              extraYPipe = rightOffsetPipeShift;
                                              pipeScaleX = rightOffsetPipeScaleX;
                                            } else {
                                              extraYBubbles = upOffsetDotShift;
                                              extraYMarks = upOffsetMarkShift;
                                              extraYPipe = upOffsetPipeShift;
                                              pipeScaleX = upOffsetPipeScaleX;
                                            }
                                          }

                                          final dotPosX = _isParallel90sMode ? dotXRight : dotX;

                                          return Stack(
                                            clipBehavior: Clip.none,
                                            children: <Widget>[
                                              Positioned(
                                                left: offsetX + sx(mainGraphicXShift),
                                                top: offsetY + sy(measurementPipeOffsetY + mainGraphicYShift + visualGlobalYShift + dotsAndPipesYShift),
                                                width: canvasW,
                                                height: canvasH,
                                                child: _offsetAssetPath.isEmpty
                                                    ? const SizedBox.shrink()
                                                    : Transform.scale(
                                                        scaleX: mainGraphicScale,
                                                        scaleY: mainGraphicScale,
                                                        child: Image.asset(
                                                          _offsetAssetPath,
                                                          fit: BoxFit.fill,
                                                          filterQuality: FilterQuality.high,
                                                        ),
                                                      ),
                                              ),
                                              _dotAt(
                                                offsetX + sx(dotPosX),
                                                offsetY + sy(dotY3 + kickPipesVerticalOffset + extraYBubbles + visualGlobalYShift + dotsAndPipesYShift),
                                                dotColorForVisual(0),
                                              ),
                                              _dotAt(
                                                offsetX + sx(dotPosX),
                                                offsetY + sy(dotY2 + kickPipesVerticalOffset + extraYBubbles + visualGlobalYShift + dotsAndPipesYShift),
                                                dotColorForVisual(1),
                                              ),
                                              _dotAt(
                                                offsetX + sx(dotPosX),
                                                offsetY + sy(dotY1 + kickPipesVerticalOffset + extraYBubbles + visualGlobalYShift + dotsAndPipesYShift),
                                                dotColorForVisual(2),
                                              ),
                                              if (_isParallel90sMode) ...[
                                                _downMark(
                                                  offsetX + sx(bottomCX),
                                                  offsetY + sy(bottomAY + 80 + visualGlobalYShift),
                                                  'A',
                                                  markA,
                                                ),
                                                _downMark(
                                                  offsetX + sx(bottomAX + 80),
                                                  offsetY + sy(bottomAY + visualGlobalYShift),
                                                  'C (cut)',
                                                  cut,
                                                ),
                                              ] else ...[
                                                Positioned(
                                                  left: offsetX + sx(bottomCX),
                                                  top: offsetY + sy(bottomAY + 20 + extraYPipe + visualGlobalYShift),
                                                  width: canvasW * pipeScaleX,
                                                  height: sy(80),
                                                  child: Image.asset(
                                                    'assets/images/rack_builder/pipe_5_straight.png',
                                                    fit: BoxFit.fill,
                                                    filterQuality: FilterQuality.high,
                                                  ),
                                                ),
                                                _downMark(
                                                  offsetX + sx(bottomBX),
                                                  offsetY + sy(bottomAY + 80 + extraYMarks + visualGlobalYShift),
                                                  'B',
                                                  markB,
                                                ),
                                                _downMark(
                                                  offsetX + sx(bottomAX),
                                                  offsetY + sy(bottomAY + 80 + extraYMarks + visualGlobalYShift),
                                                  'A',
                                                  markA,
                                                ),
                                                _downMark(
                                                  offsetX + sx(bottomCX),
                                                  offsetY + sy(bottomAY + 80 + extraYMarks + visualGlobalYShift),
                                                  'C',
                                                  cut,
                                                ),
                                              ]
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                _InfoBar(
                                  xShift: measureTextXShift,
                                  isParallel90s: _isParallel90sMode,
                                  expanded: _showInfo,
                                  measureFromTail: rack.current.measureFromTail,
                                  onMore: () => setState(() => _showInfo = !_showInfo),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],

                  if (!_showRackSetupStart && _isParallel90sMode && !_parallel90ShowResults) ...[
                    const SizedBox(height: spacing),
                    _BeveledButton(
                      active: true,
                      onTap: () {
                        final stub = RackState.parseInches(stubCtl.text);
                        final leg = RackState.parseInches(legCtl.text);
                        final gain = _selectedRackBender?.gain ?? rack.benderGain;
                        final takeup = _selectedRackBender?.deduct ?? rack.benderTakeup;

                        if (stub > 0 && leg > 0) {
                          _saveStateFromActiveController(); 

                          String label = rack.isFromBox ? '90° Up (Box Transition)' : '90° Rack';

                          // Add to Hub with metadata
                          rack.addBendSegment(
                            label, 
                            90.0, 
                            stub + leg - gain, 
                            multiplier: _rackPipeCount,
                            stub: stub,
                            leg: leg,
                            gain: gain,
                            takeup: takeup,
                          );
                          _triggerHubFlash();

                          setState(() {
                            _parallel90ShowResults = true;
                            _showParallel90Measurements = false;
                            _activeController = null;
                            _isKeypadVisible = false;
                            _clearOnNextInput = false;
                          });
                        }
                      },
                      child: const Text(
                        'CALCULATE & FINISH',
                        style: TextStyle(
                          color: kLight,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: spacing),
                    _RackInfoBar(
                      isOffsetMode: false,
                      isRollingMode: false,
                      needsDirection: false,
                      showResults: false,
                      isFromBox: rack.isFromBox,
                    ),
                  ],
                  const SizedBox(height: spacing),
                  if (_isParallel90sMode && _parallel90ShowResults) ...[
                    const SizedBox(height: 8),
                    if (_showHubGuidance)
                      _RackInfoBar(
                        isOffsetMode: false,
                        isRollingMode: false,
                        needsDirection: false,
                        showResults: true,
                        isFromBox: rack.isFromBox,
                        isHubVisible: _isProjectHubVisible,
                      ),
                  ],
                  if (_isOffsetMode && !_showRackResults) ...[
                    const SizedBox(height: spacing),
                    _RackInfoBar(
                      isOffsetMode: _isOffsetMode,
                      isRollingMode: rack.isRollingMode,
                      needsDirection: _rollingNeedsDirection,
                      showResults: false,
                      isBendingMethod: _showOffsetBendingMethod,
                      isFromBox: rack.isFromBox,
                      isHubVisible: _isProjectHubVisible,
                    ),
                  ],
                  if (_isOffsetMode && _showRackResults) ...[
                    const SizedBox(height: 4),
                    if (_showHubGuidance)
                      _RackInfoBar(
                        isOffsetMode: _isOffsetMode,
                        isRollingMode: rack.isRollingMode,
                        needsDirection: false,
                        showResults: true,
                        isFromBox: rack.isFromBox,
                        isHubVisible: _isProjectHubVisible,
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (_isProjectHubVisible)
            _buildProjectHub(),
          if (_isNameEntryMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(220),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Name Custom Bender',
                          style: TextStyle(
                            color: kLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 46,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: kBlack,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white54, width: 1.2),
                          ),
                          child: Text(
                            _customBenderName.isEmpty
                                ? 'Enter bender name'
                                : _customBenderName,
                            style: TextStyle(
                              color: _customBenderName.isEmpty
                                  ? Colors.white38
                                  : kLight,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _BeveledButton(
                                onTap: () {
                                  setState(() {
                                    _isNameEntryMode = false;
                                    _customBenderName = '';
                                  });
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: kLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BeveledButton(
                                active: _customBenderName.trim().isNotEmpty,
                                onTap: _customBenderName.trim().isEmpty
                                    ? null
                                    : _saveCustomBender,
                                child: const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: kLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AlphaInputKeypad(onTap: _onNameKeyTap),
                ],
              ),
            ),
          if (_isKeypadVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: NumericInputKeypad(onTap: _onKeypadTap),
            ),
        ],
      ),
    );
  }

  Widget _tapRect(
      double left, double top, double w, double h, VoidCallback onTap) {
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: const SizedBox.shrink()),
    );
  }

  Widget _dotAt(double x, double y, Color color) => Positioned(
        left: x,
        top: y,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 4)
              ]),
        ),
      );

  Widget _downMark(double x, double y, String label, String value) =>
      Positioned(
        left: x,
        top: y - 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white54, width: 1),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        spreadRadius: 1)
                  ]),
              child: Row(
                children: [
                  Text('$label: ',
                      style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                  Text(value,
                      style: const TextStyle(
                          color: kLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 0),
            const RotatedBox(
              quarterTurns: 1,
              child: Text("➜",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
}

class _Parallel90sInputCard extends StatelessWidget {
  const _Parallel90sInputCard({
    required this.stubCtl,
    required this.legCtl,
    required this.onStubTap,
    required this.onLegTap,
    required this.isKeypadVisible,
    this.activeController,
    this.onAlignEnds,
  });

  final TextEditingController stubCtl;
  final TextEditingController legCtl;
  final VoidCallback onStubTap;
  final VoidCallback onLegTap;
  final bool isKeypadVisible;
  final TextEditingController? activeController;
  final VoidCallback? onAlignEnds;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: <Widget>[
            Expanded(
              child: _buildButton(
                'Stub',
                stubCtl,
                onStubTap,
                activeController == stubCtl,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildButton(
                'Leg',
                legCtl,
                onLegTap,
                activeController == legCtl,
              ),
            ),
          ],
        ),
        if (onAlignEnds != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _BeveledButton(
              height: 34,
              onTap: onAlignEnds!,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.align_horizontal_left, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'ALIGN ALL ENDS (MAX PIPE)',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButton(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isGuided,
      ) {
    final bool isActivelyEditing = isGuided && isKeypadVisible;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActivelyEditing
              ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
              : const [Color(0xFF4E4E52), Color(0xFF2C3030)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGuided ? kRed : const Color(0xFF9E9E9E),
          width: isGuided ? 2.0 : 1.1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ctl.text.isEmpty ? '0"' : '${ctl.text}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggleButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rack = Provider.of<RackState>(context);
    return Row(
      children: [
        Expanded(
          child: _BeveledButton(
            active:rack.kick90RackStyle == Kick90RackStyle.parallel,
            onTap: () => rack.setKick90RackStyle(Kick90RackStyle.parallel),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("90s",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                RotatedBox(
                  quarterTurns: -1,
                  child: Text("➜",
                      style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.8),
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _BeveledButton(
            active: rack.kick90RackStyle == Kick90RackStyle.parallel,
            onTap: () => rack.setKick90RackStyle(Kick90RackStyle.perpendicular),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("90s",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Text("➜",
                    style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.8),
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
class _MiniArrowButton extends StatelessWidget {
  const _MiniArrowButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54, 
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8A1010),
              Color(0xFFD12A2A),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFC8C8C8),
            width: 1.1,
          ),
        ),
        child: Center(
          child: Transform.scale(
            scaleX: label == '⬅' ? -1 : 1,
            child: const Text(
              "➜",
              style: TextStyle(
                color: kLight,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _BeveledButton extends StatelessWidget {
  const _BeveledButton({
    this.active = false,
    this.redOutline = false,
    this.subtle = false,
    this.primary = false, // High contrast Primary style
    required this.onTap,
    required this.child,
    this.height = 45,
    this.width,
  });

  final bool active;
  final VoidCallback? onTap;
  final Widget child;
  final bool redOutline;
  final bool subtle;
  final bool primary;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8A1010), Color(0xFFC82828)],
              )
            : primary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF333333), Color(0xFF111111)],
                  )
                : subtle
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: enabled
                            ? const [Color(0xFF454548), Color(0xFF2B2D2D)]
                            : [Colors.grey.shade800, Colors.grey.shade900],
                      ),
        color: subtle && !active ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: redOutline
              ? kRed
              : primary
                  ? const Color(0xFFE0E0E0) // Bright Silver for Pop
                  : subtle
                      ? Colors.white38
                      : const Color(0xFF8C8C8C),
          width: (redOutline || primary) ? 1.7 : 0.9,
        ),

      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _SectionTitleButton extends StatelessWidget {
  const _SectionTitleButton({
    required this.label,
    this.onTap,
    this.onReset,
    this.isActive = false,
    this.isCheckmark = false,
    this.height = 44,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onReset;
  final bool isActive;
  final bool isCheckmark;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
              : (isEnabled
                  ? const [Color(0xFF4E4E52), Color(0xFF2C3030)]
                  : [Colors.grey.shade800, Colors.grey.shade900]),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9E9E9E),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 36), // Balanced spacer for Reset button on right
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isEnabled ? Colors.white : Colors.grey.shade500,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isCheckmark) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: kGreen, size: 24),
                      ],
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onReset != null) ...[
            Container(width: 1, color: Colors.white24, height: height * 0.6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onReset,
              child: Container(
                width: 48,
                height: height,
                alignment: Alignment.center,
                child: const Icon(Icons.refresh, color: kLight, size: 22),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StyledPipeChip extends StatelessWidget {
  const _StyledPipeChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BeveledButton(
      active: selected,
      onTap: onTap,
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15)),
    );
  }
}



class _MarksCard extends StatelessWidget {
  const _MarksCard({
    required this.markA,
    required this.markB,
    required this.shift,
    required this.cut,
    this.isParallel90s = false,
    this.parallel90Complete = false,
    required this.rack,
  });

  final String markA;
  final String markB;
  final String shift;
  final String cut;
  final bool isParallel90s;
  final bool parallel90Complete;
  final RackState rack;

  @override
  Widget build(BuildContext context) {
    String travelText = "";
    if (rack.calcMode == RackCalcMode.offset || rack.calcMode == RackCalcMode.parallelOffset || rack.calcMode == RackCalcMode.rollingOffset || rack.calcMode == RackCalcMode.parallelRollingOffset) {
      final double offsetVal = (rack.calcMode == RackCalcMode.rollingOffset || rack.calcMode == RackCalcMode.parallelRollingOffset)
          ? math.sqrt(math.pow(rack.offsetHeight, 2) + math.pow(rack.offsetHorizontal, 2))
          : rack.offsetHeight;
      final double angle = rack.bendAngle;
      if (angle > 0 && angle.isFinite) {
        final double travel = offsetVal / math.sin(angle * math.pi / 180.0);
        travelText = RackState.inchFmt(travel);
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(
            'Mark A',
            markA,
            valueHot: isParallel90s && parallel90Complete,
          ),

          if (!isParallel90s) ...[
            const SizedBox(height: 6),
            _row('Mark B', markB),
            const SizedBox(height: 6),
            _row('Distance Between Bends', travelText.isEmpty ? '—' : travelText, isWide: true),
            const SizedBox(height: 6),
            _row('Shift (Graduation)', shift),
          ],

          const SizedBox(height: 6),

          _row(
            'Mark C (Cut)',
            cut,
            valueHot: !isParallel90s || parallel90Complete,
          ),

          const SizedBox(height: 10),

          if (!rack.isFromBox)
            _BeveledButton(
              height: 40,
              subtle: true,
              onTap: () {
                double exportSpacing = rack.centerToCenterSpacing;
                if (rack.calcMode == RackCalcMode.kick90 &&
                    (rack.kick90RackStyle == Kick90RackStyle.sameAngle ||
                        rack.kick90RackStyle == Kick90RackStyle.sameStart)) {
                  // Plane Change / Cross Kick effective spacing calculation
                  final angleRad = rack.kickAngle * math.pi / 180.0;
                  if (math.cos(angleRad).abs() > 0.1) {
                    exportSpacing = rack.centerToCenterSpacing / math.cos(angleRad);
                  }
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BoxLayoutModeScreen(
                      prePopulatedConduits: rack.allConduits,
                      preCalculatedCenterToCenter: exportSpacing,
                      preCalculatedCenterMarks: rack.boxCenterMarks, // ADDED
                      showBackButton: true,
                    ),
                  ),
                );
              },
              child: const Text(
                'EXPORT TO BOX LAYOUT (Optional)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(
      String label,
      String value, {
        bool valueHot = false,
        bool isWide = true,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Container(
          width: isWide ? 185 : 140,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: valueHot
                  ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
                  : const [Color(0xFF5A5A5F), Color(0xFF2C3030)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFD0D0D0),
              width: 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _OffsetInputCard extends StatelessWidget {
  const _OffsetInputCard({
    required this.distanceCtl,
    required this.heightCtl,
    required this.overallCtl,
    required this.onDistanceTap,
    required this.onHeightTap,
    required this.onOverallTap,
    required this.angleCtl,
    required this.onAngleTap,
    required this.spacingValue,
    required this.c2cValue,
    required this.isFullStick,
    required this.onFullStickToggle,
    required this.isExpanded,
    required this.onHeaderTap,
    this.activeController,
  });

  final TextEditingController distanceCtl;
  final TextEditingController heightCtl;
  final TextEditingController overallCtl;
  final TextEditingController angleCtl;
  final String spacingValue;
  final String c2cValue;
  final bool isFullStick;
  final ValueChanged<bool> onFullStickToggle;

  final VoidCallback onAngleTap;
  final VoidCallback onDistanceTap;
  final VoidCallback onHeightTap;
  final VoidCallback onOverallTap;
  final TextEditingController? activeController;

  final bool isExpanded;
  final VoidCallback onHeaderTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onHeaderTap,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'OFFSET MEASUREMENTS',
                        style: TextStyle(
                          color: kLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      isExpanded ? '⌃' : '⌄',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 6),
              _inputRow(
                'Offset Height',
                heightCtl,
                onHeightTap,
                activeController == heightCtl,
              ),
              const SizedBox(height: 6),
              _inputRow(
                'Angle',
                angleCtl,
                onAngleTap,
                activeController == angleCtl,
                suffix: '°',
              ),
              const SizedBox(height: 6),
              _inputRow(
                'Distance to Obstruction',
                distanceCtl,
                onDistanceTap,
                activeController == distanceCtl,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Full Stick (10ft)?',
                      style: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    child: _FullStickToggle(
                      value: isFullStick,
                      onChanged: onFullStickToggle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.white10)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Container(height: 1, color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 8),
              if (!isFullStick) ...[
                _inputRow(
                  'Overall Length',
                  overallCtl,
                  onOverallTap,
                  activeController == overallCtl,
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.centerRight,
                  child: const Text('Locked at 120"', style: TextStyle(color: kGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(height: 1, color: Colors.white24),
              ),
              const SizedBox(height: 10),
              _displayRow('Space Between Pipes', spacingValue),
              const SizedBox(height: 6),
              _displayRow('Center to Center', c2cValue),
            ],
          ],
      ),
    );
  }

  Widget _displayRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value.endsWith('"') ? value : '$value"', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _inputRow(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isActive, {
        String suffix = '"',
      }) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        SizedBox(
          width: 150,
          child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: ctl,
                readOnly: true,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  suffixText: ctl.text.trim().endsWith(suffix) ? '' : suffix,
                  suffixStyle: const TextStyle(color: Colors.white),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: isActive ? 1.8 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  fillColor: Colors.white12,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _RollingInputCard extends StatelessWidget {
  const _RollingInputCard({
    required this.distanceCtl,
    required this.verticalCtl,
    required this.horizontalCtl,
    required this.overallCtl,
    required this.angleCtl,
    required this.onDistanceTap,
    required this.onVerticalTap,
    required this.onHorizontalTap,
    required this.onOverallTap,
    required this.onAngleTap,
    required this.spacingValue,
    required this.c2cValue,
    required this.isFullStick,
    required this.onFullStickToggle,
    required this.isExpanded,
    required this.onHeaderTap,
    this.activeController,
  });

  final TextEditingController distanceCtl;
  final TextEditingController verticalCtl;
  final TextEditingController horizontalCtl;
  final TextEditingController overallCtl;
  final TextEditingController angleCtl;
  final String spacingValue;
  final String c2cValue;
  final bool isFullStick;
  final ValueChanged<bool> onFullStickToggle;

  final VoidCallback onDistanceTap;
  final VoidCallback onVerticalTap;
  final VoidCallback onHorizontalTap;
  final VoidCallback onOverallTap;
  final VoidCallback onAngleTap;

  final TextEditingController? activeController;

  final bool isExpanded;
  final VoidCallback onHeaderTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onHeaderTap,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ROLLING OFFSET MEASUREMENTS',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    isExpanded ? '⌃' : '⌄',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 6),
            _inputRow(
              'Vertical Offset',
              verticalCtl,
              onVerticalTap,
              activeController == verticalCtl,
            ),
            const SizedBox(height: 6),
            _inputRow(
              'Horizontal Roll',
              horizontalCtl,
              onHorizontalTap,
              activeController == horizontalCtl,
            ),
            const SizedBox(height: 6),
            _inputRow(
              'Angle',
              angleCtl,
              onAngleTap,
              activeController == angleCtl,
              suffix: '°',
            ),
            const SizedBox(height: 6),
            _inputRow(
              'Distance to Obstruction',
              distanceCtl,
              onDistanceTap,
              activeController == distanceCtl,
            ),
            const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Full Stick (10ft)?',
                      style: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    child: _FullStickToggle(
                      value: isFullStick,
                      onChanged: onFullStickToggle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.white10)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Container(height: 1, color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 8),
              if (!isFullStick) ...[
                _inputRow(
                  'Overall Length',
                  overallCtl,
                  onOverallTap,
                  activeController == overallCtl,
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.centerRight,
                  child: const Text('Locked at 120"', style: TextStyle(color: kGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(height: 1, color: Colors.white24),
            ),
            const SizedBox(height: 10),
            _displayRow('Space Between Pipes', spacingValue),
            const SizedBox(height: 6),
            _displayRow('Center to Center', c2cValue),
          ],
        ],
      ),
    );
  }
  Widget _displayRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value.endsWith('"') ? value : '$value"', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _inputRow(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isActive, {
        String suffix = '"',
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 128,
          child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: ctl,
                readOnly: true,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  suffixText: ctl.text.trim().endsWith(suffix) ? '' : suffix,
                  suffixStyle: const TextStyle(color: Colors.white),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: isActive ? 1.8 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isActive ? kRed : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  fillColor: Colors.white12,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}



class _KickStylePictureCard extends StatelessWidget {
  const _KickStylePictureCard({
    required this.selectedKickStyle,
    required this.selectedPipeIndexInSet,
    required this.kickDirection,
    required this.labels,
    required this.onDirectionChanged,
    required this.onDotTap,
    this.showDots = true,
    this.cardHeight = 240,
  });
  final String selectedKickStyle;
  final int selectedPipeIndexInSet;
  final String kickDirection;
  final List<int> labels;
  final ValueChanged<String> onDirectionChanged;
  final ValueChanged<int> onDotTap;
  final bool showDots;
  final double cardHeight;

  int _visualToPipeIndex(int visualIndex) {
    // visualIndex: 0 = top, 1 = middle, 2 = bottom
    //
    // Right kick:
    // P1 should be top, P2 middle, P3 bottom.
    //
    // Left kick:
    // P1 bottom, P2 middle, P3 top.
    if (kickDirection == 'right') {
      return visualIndex;
    }

    return 2 - visualIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cardHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.5,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
                 child: Transform.translate(
                  offset: const Offset(-12, 0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(1.0, 1.2),
                    child: Image.asset(
                      selectedKickStyle == 'Across'
                          ? (kickDirection == 'left'
                          ? 'assets/images/rack_builder/parallel_90_2.png'
                          : 'assets/images/rack_builder/parallel_90.png')
                          : 'assets/images/rack_builder/kick_90_forward.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          ),

          if (showDots)
            Positioned(
              top: kickDirection == 'left' ? 25 : 91                   ,
              right: -5,
            child: Column(
              children: List.generate(3, (visualIndex) {
                final pipeIndex = _visualToPipeIndex(visualIndex);
                final active = pipeIndex == selectedPipeIndexInSet;


                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: GestureDetector(
                    onTap: () => onDotTap(pipeIndex),
                    child: _KickDot(
                      active: active,
                    ),
                  ),
                );
              }),
            ),
          ),


        ],
      ),
    );
  }
}
class _KickDot extends StatelessWidget {
  const _KickDot({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? kRed : Colors.black,
        border: Border.all(
          color: active ? kRed : const Color(0xFFC0C0C0),
          width: active ? 2 : 1.3,
        ),
      ),
    );
  }
}

class _Kick90RackInputCard extends StatelessWidget {
  const _Kick90RackInputCard({
    required this.isExpanded,
    required this.onHeaderTap,
    required this.onContinue,
    required this.stubCtl,
    required this.kickHeightCtl,
    required this.kickAngleCtl,
    required this.legCtl,
    required this.spacingCtl,
    required this.activeController,
    required this.isCenterToCenter,
    required this.onStubTap,
    required this.onKickHeightTap,
    required this.onKickAngleTap,
    required this.onLegTap,
    required this.onSpacingTap,
    required this.onSpaceBetweenTap,
    required this.onCenterToCenterTap,
    required this.kickMatchBendCtl,
    required this.usesMatchBendInput,
    required this.kickMarkMethod,
    required this.onUseNotch,
    required this.onUseCenterline,
    required this.onKickMatchBendTap,
    this.onBack,
    this.onNext,
    this.isFromBox = false,
    this.distanceFromBoxCtl,
    this.onDistanceFromBoxTap,
    this.onToggleStrut,
    this.measureToTop = true,
  });
  final bool isExpanded;
  final VoidCallback onHeaderTap;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final TextEditingController stubCtl;
  final TextEditingController kickHeightCtl;
  final TextEditingController kickAngleCtl;
  final TextEditingController legCtl;
  final TextEditingController spacingCtl;
  final TextEditingController? activeController;
  final bool isCenterToCenter;
  final TextEditingController kickMatchBendCtl;

  final bool usesMatchBendInput;

  final VoidCallback onKickMatchBendTap;
  final bending_data.BendingMethod kickMarkMethod;
  final VoidCallback onUseNotch;
  final VoidCallback onUseCenterline;

  final VoidCallback onStubTap;
  final VoidCallback onKickHeightTap;
  final VoidCallback onKickAngleTap;
  final VoidCallback onLegTap;
  final VoidCallback onSpacingTap;
  final VoidCallback onSpaceBetweenTap;
  final VoidCallback onCenterToCenterTap;

  final bool isFromBox;
  final TextEditingController? distanceFromBoxCtl;
  final VoidCallback? onDistanceFromBoxTap;
  final VoidCallback? onToggleStrut;
  final bool measureToTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.5,
        ),
      ),
        child: Column(
          children: [
          GestureDetector(
          onTap: onHeaderTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'MEASUREMENTS',
                    style: TextStyle(
                      color: kLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  isExpanded ? '⌃' : '⌄',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isExpanded) ...[
    const SizedBox(height: 6),

    if (isFromBox && distanceFromBoxCtl != null) ...[
      _row(
        'Box Top to Strut',
        distanceFromBoxCtl!,
        onDistanceFromBoxTap!,
        activeController == distanceFromBoxCtl,
        leadingInput: GestureDetector(
          onTap: onToggleStrut,
          child: Container(
            width: 54,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8A1010), Color(0xFFD12A2A)],
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFC0C0C0), width: 0.8),
            ),
            child: Center(
              child: Text(
                measureToTop ? 'TOP' : 'BOT',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
    ],

    _row('Stub Height', stubCtl, onStubTap, activeController == stubCtl),
          const SizedBox(height: 6),

          _row('Kick Height', kickHeightCtl, onKickHeightTap,
              activeController == kickHeightCtl),
          const SizedBox(height: 6),

          if (usesMatchBendInput)
            _row(
              '90 ➜ Match Bend',
              kickMatchBendCtl,
              onKickMatchBendTap,
              activeController == kickMatchBendCtl,
            )
          else
            _row(
              'Kick Angle',
              kickAngleCtl,
              onKickAngleTap,
              activeController == kickAngleCtl,
              suffix: '°',
            ),




          const SizedBox(height: 8),

          if (!isFromBox) ...[
            _row(
              'Leg Length',
              legCtl,
              onLegTap,
              activeController == legCtl,
            ),
            const SizedBox(height: 8),
          ],

          if (onBack != null && onNext != null) ...[
            Row(
              children: [
                Expanded(
                  child: _MiniArrowButton(
                    label: '⬅',
                    onTap: onBack!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniArrowButton(
                    label: '➡',
                    onTap: onNext!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          SizedBox(
            width: double.infinity,
            child: _BeveledButton(
              active: false,
              redOutline: true,
              subtle: true,
              onTap: onContinue,
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

  Widget _row(
      String label,
      TextEditingController ctl,
      VoidCallback onTap,
      bool active, {
        String suffix = '"',
        Widget? leadingInput,
      }) {
    final String value = ctl.text.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFC8C8C8), // Standard border
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (leadingInput != null) ...[
              leadingInput,
              const SizedBox(width: 8),
            ],
            Container(
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active ? kGreen : Colors.white38, // Green highlight when active
                  width: active ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                value.isEmpty
                    ? '0$suffix'
                    : (value.endsWith(suffix) ? value : '$value$suffix'),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: active ? kGreen : kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          _SectionTitleButton(
            label: label,
            fontSize: 19,
            height: 60,
            isActive: true,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

Widget _subHeader({
  required String label,
  required bool isExpanded,
  required VoidCallback onToggle,
}) {
  return GestureDetector(
    onTap: onToggle,
    child: Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.white54,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class _Parallel90MeasurementsCard extends StatelessWidget {
  const _Parallel90MeasurementsCard({
    required this.stubCtl,
    required this.legCtl,
    required this.spacingCtl,
    required this.activeController,

    required this.isCenterToCenter,

    required this.onStubTap,
    required this.onLegTap,
    required this.onSpacingTap,

    required this.onSpaceBetweenTap,
    required this.onCenterToCenterTap,
    this.isFromBox = false,
    this.distanceFromBoxCtl,
    this.onDistanceFromBoxTap,
    this.onToggleStrut,
    required this.spacingValue,
    required this.c2cValue,
    this.measureToTop = true,
    this.onAlignEnds,
  });

  final TextEditingController stubCtl;
  final TextEditingController legCtl;
  final TextEditingController spacingCtl;

  final TextEditingController? activeController;

  final bool isCenterToCenter;

  final VoidCallback onStubTap;
  final VoidCallback onLegTap;
  final VoidCallback onSpacingTap;

  final VoidCallback onSpaceBetweenTap;
  final VoidCallback onCenterToCenterTap;

  final bool isFromBox;
  final TextEditingController? distanceFromBoxCtl;
  final VoidCallback? onDistanceFromBoxTap;
  final VoidCallback? onToggleStrut;
  final bool measureToTop;
  final String spacingValue;
  final String c2cValue;
  final VoidCallback? onAlignEnds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.5,
        ),
      ),

      child: Column(
        children: [

          if (isFromBox && distanceFromBoxCtl != null) ...[
            _row(
              'Box Top to Strut',
              distanceFromBoxCtl!,
              onDistanceFromBoxTap!,
              activeController == distanceFromBoxCtl,
              leadingInput: GestureDetector(
                onTap: onToggleStrut,
                child: Container(
                  width: 54,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8A1010), Color(0xFFD12A2A)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFC0C0C0), width: 0.8),
                  ),
                  child: Center(
                    child: Text(
                      measureToTop ? 'TOP' : 'BOT',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          _row(
            'Distance to Back of 90',
            stubCtl,
            onStubTap,
            activeController == stubCtl,
          ),

          if (!isFromBox) ...[
            const SizedBox(height: 8),
            _row(
              'Distance After 90',
              legCtl,
              onLegTap,
              activeController == legCtl,
              trailingInput: onAlignEnds != null ? _BeveledButton(
                width: 85,
                height: 32,
                onTap: onAlignEnds!,
                child: const Text(
                  'MAX PIPE',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ) : null,
            ),
          ],

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(height: 1, color: Colors.white24),
          ),
          const SizedBox(height: 10),

          _displayRow('Space Between Pipes', spacingValue),
          const SizedBox(height: 6),
          _displayRow('Center to Center', c2cValue),
        ],
      ),
    );
  }

  Widget _displayRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value.endsWith('"') ? value : '$value"', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _row(
      String label,
      TextEditingController ctl,
      VoidCallback onTap,
      bool active, {
        Widget? leadingInput,
        Widget? trailingInput,
      }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),

          borderRadius: BorderRadius.circular(8),

          border: Border.all(
            color: active ? kRed : const Color(0xFFC8C8C8),
            width: active ? 1.8 : 1.2,
          ),
        ),

        child: Row(
          children: [

            Expanded(
              child: Text(
                label,

                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            if (leadingInput != null) ...[
              leadingInput,
              const SizedBox(width: 8),
            ],
            
            if (trailingInput != null) ...[
              trailingInput,
              const SizedBox(width: 8),
            ],

            Container(
              width: 92,

              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),

              decoration: BoxDecoration(
                color: Colors.black,

                borderRadius: BorderRadius.circular(6),

                border: Border.all(
                  color: active ? kRed : Colors.white38,
                  width: active ? 1.5 : 1.0,
                ),
              ),

              child: Text(
                ctl.text.isEmpty
                    ? '0"'
                    : ctl.text,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SpacingCard extends StatelessWidget {
  const _SpacingCard({
    required this.isParallel90s,
    required this.runCtl,
    required this.boxCtl,
    required this.onRunTap,
    required this.onBoxTap,
    required this.isCenterToCenter,
    required this.onSpaceBetweenTap,
    required this.onCenterToCenterTap,
    this.activeController,
  });

  final bool isParallel90s;
  final TextEditingController runCtl;
  final TextEditingController boxCtl;
  final VoidCallback onRunTap;
  final VoidCallback onBoxTap;
  final bool isCenterToCenter;
  final VoidCallback onSpaceBetweenTap;
  final VoidCallback onCenterToCenterTap;
  final TextEditingController? activeController;

  @override
  Widget build(BuildContext context) {
    final active = activeController;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Spacing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 8),

          _buildTextFieldRow(
            isCenterToCenter ? '℄ to ℄' : 'Space',
            runCtl,
            onRunTap,
            active == runCtl,
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                height: 36,
                child: _BeveledButton(
                  active: !isCenterToCenter && active == runCtl,
                  onTap: onSpaceBetweenTap,
                  child: const Text(
                    'Space',
                    style: TextStyle(
                      color: kLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                height: 36,
                child: _BeveledButton(
                  active: isCenterToCenter && active == runCtl,
                  onTap: onCenterToCenterTap,
                  child: const Text(
                    '℄ to ℄',
                    style: TextStyle(
                      color: kLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (!isParallel90s) ...[
            const SizedBox(height: 8),
            _buildTextFieldRow(
              '℄ to ℄ Box',
              boxCtl,
              onBoxTap,
              active == boxCtl,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextFieldRow(
      String title,
      TextEditingController ctl,
      VoidCallback onTap,
      bool isActive,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          height: 44,
          child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: ctl,
                readOnly: true,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  suffixText: '"',
                  suffixStyle: const TextStyle(color: Colors.white),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isActive ? kRed : const Color(0xFFC8C8C8),
                      width: isActive ? 2.0 : 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isActive ? kRed : const Color(0xFFC8C8C8),
                      width: isActive ? 2.0 : 1.5,
                    ),
                  ),
                  fillColor:
                  isActive ? const Color(0xFF1A0A0A) : Colors.black,
                  filled: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _FullStickToggle extends StatelessWidget {
  const _FullStickToggle({required this.value, required this.onChanged, this.useLetters = false});
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool useLetters;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _toggleButton(useLetters ? 'Y' : 'YES', value, () => onChanged(true)),
        const SizedBox(width: 4),
        _toggleButton(useLetters ? 'N' : 'NO', !value, () => onChanged(false)),
      ],
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: useLetters ? 38 : 70,
        height: useLetters ? 28 : 34,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [Color(0xFF8A1010), Color(0xFFD12A2A)])
              : const LinearGradient(colors: [Color(0xFF3A3A3D), Color(0xFF1F1F21)]),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? kRed : const Color(0xFF8C8C8C), width: active ? 1.5 : 1.0),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: kLight, fontSize: useLetters ? 11 : 15, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
class _RackSetupGuideBar extends StatelessWidget {
  const _RackSetupGuideBar({
    required this.text,
    this.isHubVisible = false,
  });

  final String text;
  final bool isHubVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 58,
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHubVisible ? kLight : const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kLight,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
class _RackInfoBar extends StatelessWidget {
  const _RackInfoBar({
    required this.isOffsetMode,
    required this.isRollingMode,
    required this.needsDirection,
    required this.showResults,
    this.isBendingMethod = false,
    this.isFromBox = false,
    this.isHubVisible = false,
  });

  final bool isOffsetMode;
  final bool isRollingMode;
  final bool needsDirection;
  final bool showResults;
  final bool isBendingMethod;
  final bool isFromBox;
  final bool isHubVisible;

  Widget _arrow(int quarterTurns) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: const Text(
        '➜',
        style: TextStyle(
          color: kLight,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isHubVisible) {
      content = const Text(
        'PROJECT HUB: Review your construction stages. Expand a stage to view its supports and geometry. Tap any measurement to edit.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kLight,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      );
    } else if (showResults) {
      if (isOffsetMode) {
        content = const Text(
          'Select each pipe to view its marks.\n⬅ = next bend, ➡ = back to measurements.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kLight,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        );
      } else {
        content = RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: kLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
            children: const [
              TextSpan(
                text:
                'Parallel 90 complete. Select pipes above to view each mark. ',
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _MiniArrowIndicator(isLeft: true),
              ),
              TextSpan(text: ' = next bend, '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _MiniArrowIndicator(isLeft: false),
              ),
              TextSpan(text: ' = back to setup.'),
            ],
          ),
        );
      }
    } else if (isBendingMethod) {
      content = const Text(
        'These adjustments are calculated automatically. Place your physical bender marks using the method chosen.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kLight,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      );
    } else if (isOffsetMode && isRollingMode) {
      content = Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          const Text(
            'Fill measurements, then choose rolling direction:',
            style: TextStyle(
              color: kLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(2),
          const Text(
            'or',
            style: TextStyle(
              color: kLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(0),
        ],
      );
    } else if (isOffsetMode) {
      content = Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          const Text(
            'Fill measurements, then choose offset direction:',
            style: TextStyle(
              color: kLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(-1),
          const Text(
            '= up,',
            style: TextStyle(
              color: kLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(1),
          const Text(
            '= down,',
            style: TextStyle(
              color: kLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(2),
          const Text(
            '/',
            style: TextStyle(
              color: kLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          _arrow(0),
          const Text(
            '= left/right.',
            style: TextStyle(
              color: kLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      );
    } else if (!showResults && isFromBox) {
      content = const Text(
        'Enter vertical Stub and distance from Box Top to Strut. Use TOP if pipe rests on hardware (adds OD) or BOT if hanging (exact mark). Adjust spacing if needed.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kLight,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      );
    } else {
      content = const Text(
        'Enter stub and leg, adjust spacing or pipe sizes if needed, choose the 90 direction, then press Done.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kLight,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      );
    }

    return Container(
      height: isHubVisible ? 84 : ((isFromBox && !showResults) ? 84 : 70),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHubVisible ? kLight : const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Center(child: content),
    );
  }
}
class _InfoBar extends StatelessWidget {
  const _InfoBar({
    Key? key,
    required this.expanded,
    required this.onMore,
    this.isParallel90s = false,
    this.xShift = 0.0,
    this.measureFromTail = false,
  }) : super(key: key);

  final bool expanded;
  final VoidCallback onMore;
  final bool isParallel90s;
  final double xShift;
  final bool measureFromTail;

  @override
  Widget build(BuildContext context) {
    // Determine the intuitive arrow direction based on measurement side
    // Start (origin left): ➜ Measure from this end
    // Tail (origin right): Measure from this end ⬅
    
    final measureText = measureFromTail
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(xShift, 0),
                child: const Row(
                  children: [
                    Text(
                      'Measure from this end ',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    RotatedBox(
                      quarterTurns: 2,
                      child: Text(
                        "➜",
                        style: TextStyle(
                          color: kLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(xShift, 0),
                child: const Row(
                  children: [
                    Text(
                      "➜ ",
                      style: TextStyle(
                        color: kLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Measure from this end',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(child: measureText),
    );
  }
}

class _CornerDiagram extends StatefulWidget {
  const _CornerDiagram({
    super.key,
    required this.segmentIndex,
    required this.inOffset,
    required this.outOffset,
    required this.onChanged,
  });

  final int segmentIndex;
  final double inOffset;
  final double outOffset;
  final Function(double, double) onChanged;

  @override
  State<_CornerDiagram> createState() => _CornerDiagramState();
}

class _CornerDiagramState extends State<_CornerDiagram> {
  bool _isLeftTurn = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 140),
            painter: _CornerPainter(isLeftTurn: _isLeftTurn),
          ),
          
          // IN/OUT Labels
          if (!_isLeftTurn) ...[
            // RIGHT TURN LABELS
            Positioned(
              left: 120,
              bottom: 6, 
              child: Row(
                children: [
                  _BeveledInput(
                    value: RackState.inchFmt(widget.inOffset).replaceAll('"', ''),
                    width: 50,
                    height: 28,
                    onChanged: (val) => widget.onChanged(RackState.parseInches(val), widget.outOffset),
                  ),
                  const SizedBox(width: 8),
                  const Text('IN', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Positioned(
              left: 10,
              top: 25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OUT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  _BeveledInput(
                    value: RackState.inchFmt(widget.outOffset).replaceAll('"', ''),
                    width: 50,
                    height: 28,
                    onChanged: (val) => widget.onChanged(widget.inOffset, RackState.parseInches(val)),
                  ),
                ],
              ),
            ),
          ] else ...[
            // LEFT TURN LABELS (Mirrored vertically)
            Positioned(
              left: 120,
              bottom: 10,
              child: Row(
                children: [
                  _BeveledInput(
                    value: RackState.inchFmt(widget.outOffset).replaceAll('"', ''),
                    width: 50,
                    height: 28,
                    onChanged: (val) => widget.onChanged(widget.inOffset, RackState.parseInches(val)),
                  ),
                  const SizedBox(width: 8),
                  const Text('OUT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Positioned(
              left: 10,
              top: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('IN', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  _BeveledInput(
                    value: RackState.inchFmt(widget.inOffset).replaceAll('"', ''),
                    width: 50,
                    height: 28,
                    onChanged: (val) => widget.onChanged(RackState.parseInches(val), widget.outOffset),
                  ),
                ],
              ),
            ),
          ],

          // Flip Toggle Button
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () => setState(() => _isLeftTurn = !_isLeftTurn),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text('FLIP', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeveledInput extends StatelessWidget {
  const _BeveledInput({required this.value, required this.width, required this.height, required this.onChanged});
  final String value;
  final double width;
  final double height;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Text(
          '$value"',
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.isLeftTurn});
  final bool isLeftTurn;

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerXFactor = 0.25; 
    const double cornerYFactor = 0.70; 
    const double horizontalArrowLen = 120.0; 
    const double verticalArrowLen = 80.0;   
    const double tickGapFromPipe = 4.0;      
    const double tickLineLength = 12.0;     

    final Offset corner = Offset(size.width * cornerXFactor, size.height * cornerYFactor);

    final pipePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = kGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final tickPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (!isLeftTurn) {
      // RIGHT TURN (Bottom drawing)
      final path = Path();
      path.moveTo(size.width * 0.95, corner.dy); 
      path.lineTo(corner.dx, corner.dy);          
      path.lineTo(corner.dx, size.height * 0.05); 
      canvas.drawPath(path, pipePaint);

      // Horizontal Arrow: From right, point LEFT into corner
      _drawArrow(canvas, corner + Offset(horizontalArrowLen, 0), const Offset(-1, 0), horizontalArrowLen, arrowPaint);
      // Vertical Arrow: From corner, point UP to end
      _drawArrow(canvas, corner, const Offset(0, -1), verticalArrowLen, arrowPaint);

      // Ticks
      canvas.drawLine(Offset(corner.dx, corner.dy + tickGapFromPipe), Offset(corner.dx, corner.dy + tickGapFromPipe + tickLineLength), tickPaint);
      canvas.drawLine(Offset(corner.dx + horizontalArrowLen, corner.dy + tickGapFromPipe), Offset(corner.dx + horizontalArrowLen, corner.dy + tickGapFromPipe + tickLineLength), tickPaint);
      canvas.drawLine(Offset(corner.dx - tickGapFromPipe, corner.dy), Offset(corner.dx - tickGapFromPipe - tickLineLength, corner.dy), tickPaint);
      canvas.drawLine(Offset(corner.dx - tickGapFromPipe, corner.dy - verticalArrowLen), Offset(corner.dx - tickGapFromPipe - tickLineLength, corner.dy - verticalArrowLen), tickPaint);
    } else {
      // LEFT TURN (Top drawing)
      final path = Path();
      path.moveTo(corner.dx, size.height * 0.05); // Start at top
      path.lineTo(corner.dx, corner.dy);          // Down to corner
      path.lineTo(size.width * 0.95, corner.dy);  // Right to end
      canvas.drawPath(path, pipePaint);

      // Vertical Arrow: From top, point DOWN into corner
      _drawArrow(canvas, corner - Offset(0, verticalArrowLen), const Offset(0, 1), verticalArrowLen, arrowPaint);
      // Horizontal Arrow: From corner, point RIGHT to end
      _drawArrow(canvas, corner, const Offset(1, 0), horizontalArrowLen, arrowPaint);

      // Ticks (Outside)
      canvas.drawLine(Offset(corner.dx - tickGapFromPipe, corner.dy), Offset(corner.dx - tickGapFromPipe - tickLineLength, corner.dy), tickPaint);
      canvas.drawLine(Offset(corner.dx - tickGapFromPipe, corner.dy - verticalArrowLen), Offset(corner.dx - tickGapFromPipe - tickLineLength, corner.dy - verticalArrowLen), tickPaint);
      canvas.drawLine(Offset(corner.dx, corner.dy + tickGapFromPipe), Offset(corner.dx, corner.dy + tickGapFromPipe + tickLineLength), tickPaint);
      canvas.drawLine(Offset(corner.dx + horizontalArrowLen, corner.dy + tickGapFromPipe), Offset(corner.dx + horizontalArrowLen, corner.dy + tickGapFromPipe + tickLineLength), tickPaint);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset dir, double length, Paint paint) {
    final Offset end = start + Offset(dir.dx * length, dir.dy * length);
    canvas.drawLine(start, end, paint);
    final double headSize = 10;
    final Path head = Path();
    if (dir.dx != 0) { 
      head.moveTo(end.dx, end.dy);
      head.lineTo(end.dx - dir.dx * headSize, end.dy - headSize/1.8);
      head.lineTo(end.dx - dir.dx * headSize, end.dy + headSize/1.8);
    } else { 
      head.moveTo(end.dx, end.dy);
      head.lineTo(end.dx - headSize/1.8, end.dy - dir.dy * headSize);
      head.lineTo(end.dx + headSize/1.8, end.dy - dir.dy * headSize);
    }
    head.close();
    canvas.drawPath(head, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _MiniArrowIndicator extends StatelessWidget {
  const _MiniArrowIndicator({required this.isLeft});
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A1010),
            Color(0xFFD12A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Transform.scale(
          scaleX: isLeft ? -1 : 1,
          child: const Text(
            "➜",
            style: TextStyle(
              color: kLight,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}