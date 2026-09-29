import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'rack_state.dart';
import 'rack_change_editor.dart';
import 'rack_branches.dart';
import 'precise_inches_controller.dart';
import 'kick_rack_handoff.dart';
import 'saved_bend_result.dart';
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
import 'bend_visualization_config.dart';

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

enum _RackResultView { parallel90, offset, rollingOffset, kick90 }

class RackBuilderScreen extends StatefulWidget {
  final RackBranches? branches;
  final RackBranch? branch;
  final ValueChanged<int>? onBranchSelected;
  final KickRackHandoff? initialKick;
  final SavedBendResult? savedResult;
  const RackBuilderScreen({
    this.branches,
    this.branch,
    this.onBranchSelected,
    this.initialKick,
    this.savedResult,
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
    this.initialOffsetLayoutDirection =
        bending_data.OffsetLayoutDirection.towardObstruction,
    this.initialBender,
    this.initialBendingMethod,
    this.initialIsArrowMethod,
    this.initialBenderDirectionReversed,

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
  final bending_data.OffsetLayoutDirection initialOffsetLayoutDirection;
  final bending_data.Bender? initialBender;
  final bending_data.BendingMethod? initialBendingMethod;
  final bool? initialIsArrowMethod;
  final bool? initialBenderDirectionReversed;

  final bool startFromBoxTransition;
  final List<String>? boxLayoutPipeSizes;
  final double? boxLayoutSpacing;
  final bool boxLayoutIsCenterToCenter;
  final String? boxLayoutConduitType;

  @override
  State<RackBuilderScreen> createState() => _RackBuilderScreenState();
}

class _RackBuilderScreenState extends State<RackBuilderScreen>
    with TickerProviderStateMixin {
  late final RackState rack;
  RackBranches? _ownedBranches;
  RackBranches? get _branches => widget.branches ?? _ownedBranches;
  bool _splittingRack = false;
  final ScrollController _scrollCtl = ScrollController();
  final ScrollController _hubScrollCtl = ScrollController();
  final GlobalKey _supportAdderKey = GlobalKey();
  final GlobalKey _nextBendKey = GlobalKey();
  final GlobalKey _benderSectionKey = GlobalKey();

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

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
  bool _spacingReviewExpanded = false;
  String? _acceptedMixedSpacing;
  double? _gapBeforeMixedSizes;
  bool _offsetStartedFromRackSetup = false;
  bool _showRackResults = false;
  _RackResultView? _lastResultView;
  bool _resultCommitted = false;
  Object _resultCommitId = Object();
  SavedBendResult? _resultBeforeRackChange;
  bool _editingContinuingRack = false;
  List<double>? _continuingOffsets;
  String? _continuingLayoutKey;
  String get _rackLayoutKey => '${_rackPipeSizes.join('|')}:${runC2C.text}:$_rackSpacingIsCenterToCenter';
  bool get _lastResultCommitted => _resultCommitted;
  set _lastResultCommitted(bool value) {
    _resultCommitted = value;
    if (value) _resultBeforeRackChange = null;
  }
  void _beginNewBendResult() {
    _resultCommitId = Object();
    _lastResultCommitted = false;
  }
  bool _viewingLatestResult = false;
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

  String _selectedKickStyle = 'Parallel';
  String _selectedKickType = 'Parallel';

  bool _hubRecentlyUpdated = false;
  Object? _editingSegmentId;
  int? get _editingSegmentIndex => rack.segmentIndex(_editingSegmentId);
  set _editingSegmentIndex(int? index) {
    _editingSegmentId = index == null ? null : rack.runSequence[index].id;
  }
  int? _editingSupportIndex;
  double? _insertSupportAfter;
  final Set<Object> _expandedHubIds = {};
  bool _isAddingStraightSegment = false;
  int _straightSticksCount = 1;
  bool _startingPointFullStick = false;
  bool _skipStartingPoint = false;
  bool _reviewingStartingPoint = false;

  RunSegment? get _savedStartingPoint {
    if (rack.runSequence.isEmpty) return null;
    final first = rack.runSequence.first;
    return first.isBoxTransition || first.label == 'Initial Run' ? first : null;
  }
  bool _latestParallel90WasStartingPoint = false;
  String _startingPointMode = 'Straight'; // 'Straight' or '90Up'

  bool _showKickTypeCard = true;
  bool _kickTypeConfirmed = false;
  bool _kickHandoffActive = false;
  bool _kickMeasurementsExpanded = true;
  bool _showKickBendingMethodCard = false;
  bool _showTravelField = false;
  bool _kickBendingMethodConfirmed = false;
  bool _showOffsetBendingMethod = false;
  bool _showOffsetGeometryResults = false;
  bool _spacingInteracted = false;
  bool _spacingErrorGlow = false;
  bool _benderWarningActive = false;
  bool _strutLengthManuallyEdited = false;
  bool _showKickResultAlternative = false;
  Timer? _kickResultTimer;
  Timer? _spacingErrorTimer;
  bool _showSpacingError = false;

  Object? _editingSupportParentSegmentId;
  int? get _editingSupportParentSegmentIndex => rack.segmentIndex(_editingSupportParentSegmentId);
  set _editingSupportParentSegmentIndex(int? index) {
    _editingSupportParentSegmentId = index == null ? null : rack.runSequence[index].id;
  }
  bool _editingSupportIsIncoming = false;

  bool get _isRackBenderSetupComplete => _selectedRackBenderBrand != null;

  String _kickVerticalDirection = 'up';
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

  String get _parallel90AssetPath {
    return _parallel90Direction == 'left'
        ? 'assets/images/rack_builder/parallel_90s_left.png'
        : 'assets/images/rack_builder/parallel_90s_right.png';
  }

  String get _kickVisualVariant =>
      '$_kickVerticalDirection${_kickDirection == 'left' ? 'Left' : 'Right'}';

  String get _kickVisualVariantLabel =>
      '${_kickVerticalDirection == 'up' ? 'UP' : 'DOWN'} + ${_kickDirection.toUpperCase()}';

  String? get _kickAssetPath =>
      kickPictureAssets[_selectedKickStyle]?[_kickVisualVariant];

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
  final kickStubCtl = PreciseInchesController();
  final legCtl = PreciseInchesController();
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
  final TextEditingController startingPointDistanceCtl =
      TextEditingController();
  final TextEditingController wallToSupportCtl = TextEditingController();
  final TextEditingController firstSupportFromBoxCtl = TextEditingController();
  final TextEditingController rackDefaultPipeSizeCtl = TextEditingController();
  final TextEditingController firstSupportPosCtl = TextEditingController();
  final TextEditingController strutLengthCtl = TextEditingController();

  bool _isKeypadVisible = false;
  TextEditingController? _activeController;
  bool _clearOnNextInput = false;
  void _sendPipeProgressionOffsetsToRackState() {
    // Sync _rackPipeSizes with _rackPipeCount first to prevent RangeErrors
    while (_rackPipeSizes.length < _rackPipeCount) {
      _rackPipeSizes
          .add(_rackDefaultPipeSize.isEmpty ? '1/2"' : _rackDefaultPipeSize);
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
    if (_continuingLayoutKey == _rackLayoutKey && _continuingOffsets?.length == offsets.length) {
      offsets.setAll(0, _continuingOffsets!);
    } else {
      _continuingOffsets = null;
      _continuingLayoutKey = null;
    }
    rack.setPipeProgressionOffsets(offsets, sizes: _rackPipeSizes);

    // Restore every assigned size after edits; a global brand must not replace
    // another size group's chosen bender.
    for (final size in _rackPipeSizes.toSet()) {
      final assigned = _rackBenderByPipeKey['${_rackConduitType}_${_rackPipeSizeKey(size)}'];
      if (assigned != null) rack.assignBenderToSize(assigned);
    }
  }

  @override
  void initState() {
    super.initState();
    rack = Provider.of<RackState>(context, listen: false);
    if (widget.savedResult != null) {
      final saved = widget.savedResult!;
      _infoAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
      _isParallel90sMode = saved.settings['view'] == 'parallel90';
      _isOffsetMode = saved.settings['view'] == 'offset';
      _isKick90sMode = saved.settings['view'] == 'kick90';
      _parallel90Direction = saved.settings['direction']!;
      // Older in-session snapshots used the former display name.
      _selectedKickStyle = saved.settings['style'] == 'Across'
          ? 'Parallel' : saved.settings['style']!;
      _kickDirection = saved.settings['kickDirection']!;
      _kickVerticalDirection = saved.settings['kickVertical']!;
      _rackPipeCount = saved.pipes.length;
      _rackPipeSizes.addAll(saved.pipes.map((p) => p.size));
      return;
    }
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
      if (widget.branch != null) {
        _loadBranchConfiguration(widget.branch!);
        _goToChooseNextBend();
        return;
      }

      if (widget.startFromBoxTransition) {
        setState(() {
          _rackPipeCount = widget.boxLayoutPipeSizes?.length ?? 0;
          _rackPipeSizes.clear();
          if (widget.boxLayoutPipeSizes != null) {
            _rackPipeSizes.addAll(widget.boxLayoutPipeSizes!);
          }
          _rackDefaultPipeSize =
              _rackPipeSizes.isNotEmpty ? _rackPipeSizes.first : '1/2"';

          final double spacing = widget.boxLayoutSpacing ?? 0.0;
          runC2C.text = RackState.inchFmt(spacing);
          _rackSpacingIsCenterToCenter = widget.boxLayoutIsCenterToCenter;
          _spacingInteracted = true; // Explicit choice supplied by the handoff.
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
        _spacingInteracted = true;
        if (widget.initialDirection == -1) {
          rack.startOffsetLeft();
        } else if (widget.initialDirection == 1) {
          rack.startOffsetRight();
        } else if (widget.initialDirection == 2) {
          rack.startOffsetDown();
        } else {
          rack.startOffsetUp();
        }
        if (widget.startInRollingOffsetMode) {
          rack.startRollingOffset();
        }

        setState(() {
          _rackPipeCount = widget.initialPipeCount ?? 3;
          _rackPipeSizes.clear();
          _rackPipeSizes.addAll(widget.initialPipeSizes ?? []);

          // Guard: Sync sizes list immediately
          while (_rackPipeSizes.length < _rackPipeCount) {
            _rackPipeSizes.add(
                _rackDefaultPipeSize.isEmpty ? '1/2"' : _rackDefaultPipeSize);
          }

          runC2C.text = RackState.inchFmt(widget.initialSpacing ?? 2.0);

          _showRackResults = true;
          _showOffsetInputs = false;
          _lastResultView = widget.startInRollingOffsetMode
              ? _RackResultView.rollingOffset
              : _RackResultView.offset;
          _lastResultCommitted = false;
        });

        if (widget.startInRollingOffsetMode) {
          _rollingNeedsDirection = widget.initialDirection == null;
          rack.setFullStick(widget.initialFullStick);

          rack.setRollingOffsetInputs(
            distanceToObstruction: widget.initialDistance ?? 0,
            verticalOffset: widget.initialOffsetHeight ?? 0,
            horizontalOffset: widget.initialHorizontalRoll ?? 0,
            overallLengthValue: widget.initialOverallLength ?? 0,
            bendAngleValue: widget.initialAngle ?? 0,
            layoutDirection: widget.initialOffsetLayoutDirection,
          );
        } else {
          rack.setFullStick(widget.initialFullStick);
          rack.setOffsetInputs(
            distanceToObstruction: widget.initialDistance ?? 0,
            offsetHeightValue: widget.initialOffsetHeight ?? 0,
            overallLengthValue: widget.initialOverallLength ?? 0,
            bendAngleValue: widget.initialAngle ?? 0,
            layoutDirection: widget.initialOffsetLayoutDirection,
          );
        }
      }

      if (widget.initialSpacing != null) {
        runC2C.text = RackState.inchFmt(widget.initialSpacing!);
        rack.setSpacing(widget.initialSpacing!);
      }

      if (widget.startInRollingOffsetMode) {
        if (widget.initialDistance != null) {
          rollingDistanceCtl.text = RackState.inchFmt(widget.initialDistance!);
        }
        if (widget.initialOffsetHeight != null) {
          rollingVerticalCtl.text =
              RackState.inchFmt(widget.initialOffsetHeight!);
        }
        if (widget.initialHorizontalRoll != null) {
          rollingHorizontalCtl.text =
              RackState.inchFmt(widget.initialHorizontalRoll!);
        }
        if (widget.initialOverallLength != null) {
          rollingOverallCtl.text =
              RackState.inchFmt(widget.initialOverallLength!);
        }
        if (widget.initialAngle != null && widget.initialAngle! > 0) {
          rollingAngleCtl.text =
              widget.initialAngle!.toString().replaceAll('.0', '');
        }
      } else {
        if (widget.initialDistance != null) {
          offsetDistanceCtl.text = RackState.inchFmt(widget.initialDistance!);
        }
        if (widget.initialOffsetHeight != null) {
          offsetHeightCtl.text = RackState.inchFmt(widget.initialOffsetHeight!);
        }
        if (widget.initialOverallLength != null) {
          offsetOverallCtl.text =
              RackState.inchFmt(widget.initialOverallLength!);
        }
        if (widget.initialAngle != null && widget.initialAngle! > 0) {
          offsetAngleCtl.text =
              widget.initialAngle!.toString().replaceAll('.0', '');
        }
      }

      _updateTextControllers();
      _sendPipeProgressionOffsetsToRackState(); // Force sync of multi-pipe data
      _clearRackBenderIfPipeChanged();
      if (widget.startInOffsetMode || widget.startInRollingOffsetMode) {
        _applyInitialBenderHandoff();
        // Imported offsets open directly on Results: save the fully initialized
        // result now, using the same identity that Next Bend checks.
        _commitVisibleResultIfNeeded();
      }
      if (widget.initialKick != null) _applyInitialKickHandoff();
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
    if (_ownedBranches != null) {
      // Child providers own their branch states; the caller owns the main rack.
      _ownedBranches = null;
    }
    _infoAnimCtrl.dispose();
    _kickResultTimer?.cancel();
    _spacingErrorTimer?.cancel();
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
    strutLengthCtl.dispose();

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
    if (_choosingNextBend ||
        (!_shouldShowStartingPointMenu && _isRackBendTypeExpanded)) {
      final confirmation = rack.runSequence.isNotEmpty &&
              rack.runSequence.last.type == RunSegmentType.straight
          ? 'Your straight pieces have been added to the Hub.\n\n' : '';
      return '${confirmation}Select your next segment. Add 10-foot sticks, '
          'enter a custom straight length, or choose a new bend type.';
    }

    if (_isRackBenderExpanded) {
      return 'Select the bender you will use for each different pipe size. You can also create a custom bender.\n(Hand benders for RMC are one size larger.)';
    }

    if (_isRackBendTypeExpanded) {
      return 'This is where you get to the rack. Choose a straight section or a 90° up from your first box. Measure from the top of the box to the landing point on your rack (top or bottom).Then measure horizontally fom the wall or you can choose to use the remaining pipe to complete the bend';
    }

    if (!_showRackSetupOutput) {
      return 'Initialize your rack. Choose your pipe count, type, and size, then enter the spacing. Tap (i) for field guides. The Hub (H) will track your materials as you add bends.';
    }

    if (_rackSpacingIsCenterToCenter && _isMixedSizes) {
      return 'Mixed sizes can have different clear gaps at equal center spacing. Use the Spacing card above the rack dimensions to choose.';
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



  void _updateWallFromSupport() {
    final supportVal = RackState.parseInches(firstSupportPosCtl.text);
    if (supportVal > 0) {
      final wallVal = supportVal + rack.supportDepth;
      wallToSupportCtl.text = RackState.inchFmt(wallVal).replaceAll('"', '');
    }
  }

  void _syncStartingPointCalculations() {
    setState(() {});
  }

  void _resetRackSetup() {
    _hideKeypad();
    _spacingReviewExpanded = false;
    _acceptedMixedSpacing = null;
    _gapBeforeMixedSizes = null;

    setState(() {
      rackPipeCountCtl.clear();
      rackDefaultPipeSizeCtl.text = ''; // Fully clear
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
      _rackDefaultPipeSize = '';
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
      _lastResultView = null;
      _resultBeforeRackChange = null;
      _editingContinuingRack = false;
      _continuingOffsets = null;
      _continuingLayoutKey = null;
      _beginNewBendResult();
      _reviewingStartingPoint = false;
      _latestParallel90WasStartingPoint = false;
      _lastResultCommitted = false;
      _viewingLatestResult = false;
      _rollingNeedsDirection = false;
      _skipStartingPoint = false;

      _showRackSetupStart = true;
      _isRackSetupExpanded = true;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = false;

      firstSupportFromBoxCtl.clear();
      firstSupportPosCtl.clear();
      strutLengthCtl.clear();
      _strutLengthManuallyEdited = false;
      _activeController = rackPipeCountCtl;
      _isKeypadVisible = false;
      _clearOnNextInput = true;
      _spacingInteracted = false;
      _showHubGuidance = true; // Reset guidance for new run
    });

    rack.clearRunSequence();
    rack.setSpacing(0);
    rack.setIsFromBox(false);
    rack.setPipeProgressionOffsets(
        []); // This now ensures at least one pipe remains
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
      _syncControllersToBender(null);
    });
    rack.setParallel90BenderData(gain: 0, takeup: 0);
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

  void _resetKickInputsOnly() {
    _showKickTypeCard = true;
    _kickTypeConfirmed = false;
    _showKickBendingMethodCard = false;
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
    _saveStateFromActiveController();
    _sendPipeProgressionOffsetsToRackState();
    rack.setParallel90Direction(_parallel90Direction);
    rack.setStubLength(RackState.parseInches(stubCtl.text));
    rack.setLegLength(legCtl.inches);
    final maxLeg = rack.parallel90MaxLegLength;
    if (!maxLeg.isFinite || maxLeg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This stub and rack spacing cannot fit a 120-inch stick. Reduce the stub or spacing.'),
      ));
      return;
    }
    // Preserve the exact full-stick length independently of fractional display.
    final leg = maxLeg;
    setState(() {
      legCtl.setInches(leg);
    });
    rack.setLegLength(leg);
  }

  Widget _buildParallel90sInputs() {
    final double stub = RackState.parseInches(stubCtl.text);
    final double tail = legCtl.inches;
    // Preview the current inputs against the same cuts used by Results.
    final double lastPipeLength = rack.parallel90LongestCutLength +
        (stub - rack.stubLength) + (tail - rack.legLength);
    final bool exceeds10ft = lastPipeLength > 120.001;
    return Column(
      children: [
        if (_isParallel90sMode &&
            (!_parallel90ShowResults || _showParallel90Measurements)) ...[
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
              _align90Ends();
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
            onToggleStrut: () =>
                setState(() => rack.setMeasureToTop(!rack.measureToTop)),
            spacingValue: _rackSpacingIsCenterToCenter
                ? RackState.inchFmt(math.max(
                    0,
                    RackState.parseInches(runC2C.text) -
                        _rackPipeOd(_rackDefaultPipeSize)))
                : RackState.inchFmt(RackState.parseInches(runC2C.text)),
            c2cValue: _rackSpacingIsCenterToCenter
                ? RackState.inchFmt(RackState.parseInches(runC2C.text))
                : RackState.inchFmt(
                    _rackPipeOd(_rackPipeSizes.first) / 2 +
                        RackState.parseInches(runC2C.text) +
                        (_rackPipeCount > 1
                            ? _rackPipeOd(_rackPipeSizes[1]) / 2
                            : _rackPipeOd(_rackPipeSizes.first) / 2),
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
                    child: Text("➜",
                        style: TextStyle(
                            color: kLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
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
                    child: Text("➜",
                        style: TextStyle(
                            color: kLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
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
                    child: Text("➜",
                        style: TextStyle(
                            color: kLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
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
                  child: const Text("➜",
                      style: TextStyle(
                          color: kLight,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BeveledButton(
            active: true,
            onTap: () {
              final stubVal = RackState.parseInches(stubCtl.text);
              final legVal = legCtl.inches;
              final gainVal = _selectedRackBender?.gain ?? rack.benderGain;
              final takeupVal =
                  _selectedRackBender?.deduct ?? rack.benderTakeup;

              if (stubVal > 0 && legVal > 0) {
                _saveStateFromActiveController();

                String label =
                    rack.isFromBox ? '90° Up (Box Transition)' : '90° Rack';

                if (_parallel90ShowResults) return;
                // Add to Hub with metadata
                rack.addBendSegment(
                  label,
                  90.0,
                  stubVal + legVal - gainVal,
                  commitId: _resultCommitId,
        savedResult: _captureHubResult(),
                  multiplier: _rackPipeCount,
                  stub: stubVal,
                  leg: legVal,
                  gain: gainVal,
                  takeup: takeupVal,
                  direction: _parallel90Direction,
                );
                _triggerHubFlash();

                setState(() {
                  _parallel90ShowResults = true;
                  _showParallel90Measurements = false;
                  _lastResultView = _RackResultView.parallel90;
                  _latestParallel90WasStartingPoint = rack.isFromBox;
                  _lastResultCommitted = true;
                  _viewingLatestResult = false;
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
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _BeveledButton(
                    width: 100,
                    height: 32,
                    active: true,
                    onTap: _align90Ends,
                    child: const Text('ALIGN ENDS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
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

    return Column(
      children: [
        _buildRackSetupSection(),
        const SizedBox(height: 6),
        KeyedSubtree(key: _benderSectionKey, child: _buildRackBenderSection()),
        const SizedBox(height: 6),

        if (_savedStartingPoint != null) ...[
          _buildRackBendTypeSection(),
          const SizedBox(height: 6),
        ] else if (_reviewingStartingPoint || (rack.runSequence.isEmpty && !_skipStartingPoint)) ...[
          _buildRackBendTypeSection(), // Step 3: Starting Point
        ],

        if (rack.runSequence.isNotEmpty && _lastResultView != null) ...[
          _buildResultsSummarySection(), // Step 4: Previous Results
          const SizedBox(height: 6),
        ],

        if (!_reviewingStartingPoint && (rack.runSequence.isNotEmpty || _skipStartingPoint)) ...[
          // Leave enough room below this heading to scroll it to the top.
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Align(alignment: Alignment.topCenter,
                child: _buildNextBendSection()),
          ),
        ],

        // Provide extra scroll room when keypad is up
        if (_isKeypadVisible) const SizedBox(height: 390),
      ],
    );
  }

  String _addInchIfMissing(String value) {
    if (value.isEmpty) return '';
    if (value.endsWith('"')) {
      return value;
    }
    return '$value"';
  }

  bool _requireSpacingChoice() {
    if (_spacingInteracted && runC2C.text.isNotEmpty) return true;
    setState(() {
      _isRackSetupExpanded = true;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Choose Space Between or Center to Center and enter spacing first.'),
    ));
    return false;
  }

  Widget _buildRackSetupSection() {
    return _buildGroupContainer(
      child: Column(
        children: [
          _SectionTitleButton(
            label: '1. RACK SETUP',
            fontSize: 19,
            height: 60,
            isActive: _isRackSetupExpanded,
            onReset: _branches == null ? _resetRackSetup : null,
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
          if (!_isRackSetupExpanded &&
              _showRackSetupOutput &&
              !_isRackBenderExpanded &&
              !_isRackBendTypeExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Column(
                children: [
                  _buildRackPreview(showSizeButtons: true),
                  const SizedBox(height: 6),
                  _buildRackSpacingReview(),
                  const SizedBox(height: 6),
                  _buildRackWidthResult(),
                  const SizedBox(height: 6),
                  _BeveledButton(
                    active: true,
                    onTap: () {
                      if (!_requireSpacingChoice()) return;
                      _saveStateFromActiveController();
                      _hideKeypad();
                      setState(() {
                        _isRackSetupExpanded = false;
                        _isRackBenderExpanded = true;
                        _isRackBendTypeExpanded = false;
                      });
                      rack.forceRefresh();
                    },
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                          color: kLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
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
                  if (runC2C.text.isNotEmpty && _showSpacingError) ...[
                    () {
                      final error = _rackSpacingErrorText();
                      if (error == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 2),
                        child: Text(
                          '⚠️ $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }(),
                  ],
                  if (_spacingInteracted && runC2C.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _BeveledButton(
                      active: true,
                      onTap: () {
                        if (!_requireSpacingChoice()) return;
                        _saveStateFromActiveController();
                        _hideKeypad();
                        setState(() {
                          _showRackSetupOutput = true;
                          _isRackSetupExpanded = false;
                          _isRackBenderExpanded = false;
                          _isRackBendTypeExpanded = false;
                          _spacingErrorGlow = false;
                        });
                        rack.forceRefresh();
                        _scrollCtl.animateTo(0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut);
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
                  _spacingInteracted =
                      false; // Next step: show card border green
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: selected
                              ? [
                                  const Color(0xFF8A1010),
                                  const Color(0xFFD12A2A)
                                ]
                              : [
                                  const Color(0xFF3A3A3A),
                                  const Color(0xFF1E1E1E)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                            color: kLight,
                            fontSize: 17,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                }).toList();
              },
              child: Container(
                width: 92,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1A0A0A)
                      : const Color(0xFF111111),
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
        _showTravelField =
            bending_data.mechanicalElectricBenderBrands.contains(found.brand);
      });

      rack.assignBenderToSize(found);
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

      rack.assignBenderToSize(saved);
      return;
    }

    _selectedRackBender = null;
    _selectedRackBenderBrand = null;
    _syncControllersToBender(null);

    // RESET STATE: Clear math engine numbers if no bender is selected
    rack.setParallel90BenderData(gain: 0, takeup: 0);
  }

  void _applyInitialBenderHandoff() {
    final bender = widget.initialKick?.bender ?? widget.initialBender;
    if (bender != null) {
      _selectedRackBender = bender;
      _selectedRackBenderBrand = bender.brand;
      _rackBenderByPipeKey[_rackBenderMemoryKey()] = bender;
      _syncControllersToBender(bender);

      for (int i = 0; i < rack.allConduits.length; i++) {
        final sizeDisplay = i < _rackPipeSizes.length
            ? _rackPipeSizes[i]
            : _selectedRackPipeSizeDisplay();
        final key = '${_rackConduitType}_${_rackPipeSizeKey(sizeDisplay)}';
        _rackBenderByPipeKey[key] = bender;

        final pipe = rack.allConduits[i];
        pipe.benderBrand = bender.brand;
        pipe.benderGain = bender.gain;
        pipe.benderTakeup = bender.deduct;
        pipe.benderCLR = bender.clr;
        pipe.pipeOD = _rackPipeOd(sizeDisplay);
        pipe.benderOverridden = true;
      }
    }

    rack.setBendingMethod(
      widget.initialKick?.method ?? widget.initialBendingMethod ?? bending_data.BendingMethod.centerline,
      arrow: widget.initialKick != null ? false : (widget.initialIsArrowMethod ?? true),
      reverse: widget.initialKick != null ? false : (widget.initialBenderDirectionReversed ?? false),
    );
  }

  void _updateBrandDropdown() {
    final Set<String> uniqueCustomNames =
        _customBenders.map((b) => b.brand).toSet();

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
    travelCtl.text =
        RackState.inchFmt(bending_data.calculateTravel90(bender.clr));
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
          'conduitType':
              b.conduitType == bending_data.ConduitType.rigid ? 'rigid' : 'emt',
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

    rack.assignBenderToSize(newBender);

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
          final bender =
              _customBenders.firstWhereOrNull((b) => b.brand == name);
          if (bender != null) {
            setState(() {
              _isEditMode = true;
              _isNewBender = false;
              _selectedRackBenderBrand = null;
              _selectedRackBender = null;
              _rackBenderMatchError = null;

              // Force the rack to match the bender being edited
              _rackConduitType =
                  bender.conduitType == bending_data.ConduitType.rigid
                      ? 'Rigid'
                      : 'EMT';
              if (_selectedRackPipe >= 0 &&
                  _selectedRackPipe < _rackPipeSizes.length) {
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

    final travel90 =
        bender == null ? 0.0 : bending_data.calculateTravel90(bender.clr);

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
              if (!_requireSpacingChoice()) return;
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
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: [
                  _buildRackPreview(showSizeButtons: true),
                  if (bender == null && !_isEditMode) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFC0C0C0), width: 1.0),
                      ),
                      child: Center(
                        child: Text(
                          'Assigning bender to: ${_selectedRackPipeSizeDisplay()} pipes',
                          style: const TextStyle(
                              color: kLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w800),
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
                          color: (bender == null && !_isEditMode)
                              ? kGreen
                              : const Color(0xFFC0C0C0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isEditMode
                                  ? (_isNewBender
                                      ? 'Custom'
                                      : 'Editing: $_customBenderName')
                                  : (bender == null
                                      ? 'Select Bender Brand'
                                      : (bender.brand == bender.model ||
                                              bender.model == null ||
                                              bender.model!.isEmpty
                                          ? bender.brand
                                          : '${bender.brand} ${bender.model}')),
                              style: const TextStyle(
                                color: kLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.white54, size: 28),
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
                      _isEditMode
                          ? takeUpCtl.text
                          : (bender == null
                              ? '—'
                              : RackState.inchFmt(bender.deduct)),
                      onTap: _isEditMode ? () => _showKeypad(takeUpCtl) : null,
                    ),
                    _rackBenderResultRow(
                      'Gain90',
                      _isEditMode
                          ? gainCtl.text
                          : (bender == null ? '—' : RackState.inchFmt(gain90)),
                      onTap: _isEditMode ? () => _showKeypad(gainCtl) : null,
                    ),
                    _rackBenderResultRow(
                      'Radius / CLR',
                      _isEditMode
                          ? radiusCtl.text
                          : (bender == null
                              ? '—'
                              : RackState.inchFmt(bender.clr)),
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
                      onTap: bender == null || _isEditMode ? null : () {
                        _hideKeypad();
                        final missing = _getUnassignedSizes();
                        if (missing.isEmpty) {
                          setState(() {
                            _benderWarningActive = false;
                            _isRackBenderExpanded = false;
                            _isRackBendTypeExpanded = true;
                          });
                          return;
                        }
                        final next = _rackPipeSizes.indexOf(missing.first);
                        setState(() {
                          _selectedRackPipe = next;
                          _currentSet = next ~/ 3;
                          _benderWarningActive = false;
                          _skipRackBenderForNow = false;
                        });
                        rack.select(next);
                        _clearRackBenderIfPipeChanged();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final target = _benderSectionKey.currentContext;
                          if (mounted && target != null) {
                            Scrollable.ensureVisible(target,
                              duration: const Duration(milliseconds: 250));
                          }
                        });
                      },
                      label: _getUnassignedSizes().isEmpty ? 'Continue'
                          : 'Choose Bender for ${_getUnassignedSizes().first} Pipes',
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _rackBenderResultRow(String label, String value,
      {VoidCallback? onTap}) {
    final bool isActive = _activeController != null &&
        ((_activeController == takeUpCtl && label == 'Take Up') ||
            (_activeController == gainCtl && label == 'Gain90') ||
            (_activeController == radiusCtl && label == 'Radius / CLR'));

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
                value.isEmpty
                    ? '0"'
                    : (value.endsWith('"') ? value : '$value"'),
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
    // The menu should only show if the construction hub is empty.
    // Once any segment (Straight or Bend) is added, we move to the "Next Bend" phase.
    return rack.runSequence.isEmpty;
  }

  void _openStartingPointForm() {
    _hideKeypad();
    final stage = _savedStartingPoint;
    if (stage != null && rack.isSharedStage(stage.id)) {
      if (stage.savedResult != null) {
        _openSavedResult(stage.savedResult!);
      } else {
        setState(() => _isProjectHubVisible = true);
      }
      return;
    }
    setState(() {
      if (stage != null) {
        _startingPointMode = stage.type == RunSegmentType.straight ? 'Straight' : '90Up';
        if (stage.type == RunSegmentType.straight && startingPointDistanceCtl.text.isEmpty) {
          startingPointDistanceCtl.text = RackState.inchFmt(stage.length);
        }
      }
      _reviewingStartingPoint = true;
      _isRackBendTypeExpanded = true;
      _isRackSetupExpanded = false;
      _isRackBenderExpanded = false;
    });
  }

  Widget _buildRackBendTypeSection() {
    return _buildGroupContainer(
      child: Column(
        children: [
          _SectionTitleButton(
            label: '3. STARTING POINT (OPTIONAL)',
            fontSize: 19,
            height: 60,
            isActive: _isRackBendTypeExpanded &&
                (_savedStartingPoint == null || _reviewingStartingPoint),
            onReset: _branches == null ? _resetBendType : null,
            onTap: () {
              if (_savedStartingPoint != null) {
                if (_reviewingStartingPoint) {
                  _goToChooseNextBend();
                } else {
                  _openStartingPointForm();
                }
                return;
              }
              if (!_requireSpacingChoice()) return;
              setState(() {
                _isRackBendTypeExpanded = !_isRackBendTypeExpanded;
                if (_isRackBendTypeExpanded) {
                  _isRackSetupExpanded = false;
                  _isRackBenderExpanded = false;
                }
              });
            },
          ),
          if (_isRackBendTypeExpanded &&
              (_savedStartingPoint == null || _reviewingStartingPoint))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: [
                  _buildStartingPointSection(),
                  const SizedBox(height: 12),
                  if (_savedStartingPoint == null)
                  _BeveledButton(
                    height: 38,
                    onTap: () {
                      setState(() => _skipStartingPoint = true);
                      _goToChooseNextBend();
                    },
                    child: const Text(
                      'SKIP STARTING POINT ➜',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSummarySection() {
    // Number visible sections; Starting Point is hidden after it is added.
    final String stepNum = _savedStartingPoint != null || _reviewingStartingPoint ? '4' : '3';

    return _buildGroupContainer(
      child: Column(
        children: [
          _SectionTitleButton(
            label: '$stepNum. LATEST RESULTS',
            fontSize: 19,
            height: 60,
            isActive: false,
            onTap: _lastResultView == null ? null : _openLatestResult,
          ),
        ],
      ),
    );
  }

  RackBranch _branchConfiguration(String name, RackState state) => RackBranch(
    name: name, rack: state, spacing: RackState.parseInches(runC2C.text),
    centerToCenter: _rackSpacingIsCenterToCenter, conduitType: _rackConduitType,
    benders: Map.of(_rackBenderByPipeKey), strutLength: 0);

  void _loadBranchConfiguration(RackBranch branch) {
    _rackPipeSizes..clear()..addAll(rack.allConduits.map((p) => _addInchIfMissing(p.size)));
    _rackPipeCount = _rackPipeSizes.length;
    rackPipeCountCtl.text = '$_rackPipeCount';
    _rackDefaultPipeSize = _rackPipeSizes.first;
    rackDefaultPipeSizeCtl.text = _rackDefaultPipeSize;
    _rackConduitType = branch.conduitType;
    _rackSpacingIsCenterToCenter = branch.centerToCenter;
    runC2C.text = RackState.inchFmt(branch.spacing);
    _spacingInteracted = true;
    _continuingOffsets = List.of(rack.pipeProgressionOffsets);
    _continuingLayoutKey = _rackLayoutKey;
    _rackBenderByPipeKey..clear()..addAll(branch.benders);
    _selectedRackPipe = 0;
    _clearRackBenderIfPipeChanged();
    strutLengthCtl.text = RackState.inchFmt(branch.strutLength > 0
        ? branch.strutLength : _rackWidthNeeded() + 3.25);
    _strutLengthManuallyEdited = branch.strutLength > 0;
    _showRackSetupOutput = true;
    _lastResultCommitted = true;
    final saved = rack.runSequence.reversed.firstWhereOrNull((s) => s.savedResult != null)?.savedResult;
    _resultBeforeRackChange = saved;
    if (saved != null) {
      _lastResultView = saved.settings['view'] == 'kick90' ? _RackResultView.kick90 :
          saved.settings['view'] == 'parallel90' ? _RackResultView.parallel90 : _RackResultView.offset;
    }
  }

  void _applyRackRoutes(String name, List<int> branch, List<int> ended) {
    final kept = [for (int i = 0; i < _rackPipeSizes.length; i++) if (!ended.contains(i)) i];
    if (kept.isEmpty || kept.length == branch.length) return;
    final remapped = branch.map((i) => kept.indexOf(i)).toList();
    if (ended.isNotEmpty) {
      final sizes = [for (final i in kept) _rackPipeSizes[i]];
      final offsets = continuingOffsets(rack.pipeProgressionOffsets, kept);
      final width = offsets.last + (_rackPipeOd(sizes.first) + _rackPipeOd(sizes.last)) / 2;
      _applyContinuingRack(RackChange(kept, sizes, offsets,
          RackState.parseInches(runC2C.text), _rackSpacingIsCenterToCenter, width + 3.25));
    }
    if (branch.isNotEmpty) {
      _createRackBranch(name, remapped);
    } else {
      setState(() => _splittingRack = false);
    }
  }
  void _createRackBranch(String name, List<int> selected) {
    _hideKeypad();
    _ownedBranches ??= widget.branches == null
        ? RackBranches(_branchConfiguration('Main Rack', rack)) : null;
    final workspace = _branches!;
    final from = workspace.branches.indexWhere((b) => identical(b.rack, rack));
    final parentConfig = _branchConfiguration(workspace.branches[from].name, rack);
    workspace.split(from: from, name: name, selected: selected,
      spacing: parentConfig.spacing, centerToCenter: parentConfig.centerToCenter,
      conduitType: parentConfig.conduitType, benders: parentConfig.benders, strutLength: 0);
    _loadBranchConfiguration(parentConfig);
    setState(() { _splittingRack = false; _editingContinuingRack = false; });
    _selectRackBranch(workspace.branches.length - 1);
  }

  void _selectRackBranch(int index) {
    _hideKeypad();
    if (widget.onBranchSelected != null) {
      widget.onBranchSelected!(index);
    } else {
      setState(() => _branches!.active = index);
    }
  }

  Widget _activeRackSelector() {
    final workspace = _branches;
    if (workspace == null || workspace.branches.length < 2) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.all(8), child: Column(children: [
      Wrap(spacing: 6, runSpacing: 6, children: [for (int i = 0; i < workspace.branches.length; i++)
        _BeveledButton(width: 140, active: identical(workspace.branches[i].rack, rack),
          onTap: () => _selectRackBranch(i), child: Text(workspace.branches[i].name,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kLight, fontWeight: FontWeight.bold))),
      ]),
    ]));
  }

  void _applyContinuingRack(RackChange change) {
    if (_resultBeforeRackChange == null && _lastResultView != null) {
      _resultBeforeRackChange = rack.runSequence.reversed
          .firstWhereOrNull((stage) => stage.savedResult != null)?.savedResult;
    }
    rack.changeContinuingPipes(change.sources, change.sizes);
    setState(() {
      _rackPipeSizes..clear()..addAll(change.sizes);
      _rackPipeCount = change.sizes.length;
      rackPipeCountCtl.text = '$_rackPipeCount';
      _rackDefaultPipeSize = change.sizes.first;
      rackDefaultPipeSizeCtl.text = _rackDefaultPipeSize;
      _selectedRackPipe = 0;
      _rackSpacingIsCenterToCenter = change.centerToCenter;
      _spacingInteracted = true;
      runC2C.text = RackState.inchFmt(change.spacing);
      strutLengthCtl.text = RackState.inchFmt(change.strutLength);
      _strutLengthManuallyEdited = true;
      _continuingOffsets = List.of(change.offsets);
      _continuingLayoutKey = _rackLayoutKey;
      _editingContinuingRack = false;
    });
    _sendPipeProgressionOffsetsToRackState();
    _clearRackBenderIfPipeChanged();
    for (int i = 0; i < rack.allConduits.length; i++) {
      final bender = _rackBenderByPipeKey['${_rackConduitType}_${_rackPipeSizeKey(_rackPipeSizes[i])}'];
      if (bender == null) continue;
      final pipe = rack.allConduits[i];
      pipe.benderBrand = bender.brand;
      pipe.benderGain = bender.gain;
      pipe.benderTakeup = bender.deduct;
      pipe.benderCLR = bender.clr;
      pipe.pipeOD = _rackPipeOd(_rackPipeSizes[i]);
      pipe.benderOverridden = true;
    }
    if (_getUnassignedSizes().isNotEmpty) {
      setState(() {
        _isRackBenderExpanded = true;
        _isRackBendTypeExpanded = false;
        _benderWarningActive = false;
      });
    }
    rack.forceRefresh();
  }

  Widget _buildNextBendSection() {
    final canChangeRack = rack.runSequence.any((stage) => stage.type == RunSegmentType.bend);
    final stepNum = 3 + (_savedStartingPoint != null ? 1 : 0) +
        (rack.runSequence.isNotEmpty && _lastResultView != null ? 1 : 0);

    return _buildGroupContainer(
      child: Column(
        children: [
          KeyedSubtree(
            key: _nextBendKey,
            child: _SectionTitleButton(
            label: '$stepNum. NEXT BEND',
            fontSize: 19,
            height: 60,
            isActive: true, // Keep open by default in Next Bend mode
            onTap: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                // Offer continuation changes only after the first bend exists.
                _activeRackSelector(),
                if (canChangeRack) ...[
                if (_splittingRack)
                  RackSplitEditor(sizes: List.of(_rackPipeSizes), offsets: List.of(rack.pipeProgressionOffsets),
                    outsideDiameter: _rackPipeOd,
                    existingNames: _branches?.branches.map((b) => b.name).toList() ?? ['Main Rack'],
                    onCreate: _createRackBranch, onApply: _applyRackRoutes, onCancel: () => setState(() => _splittingRack = false))
                else ...[
                  RackPipeStrip(sizes: _rackPipeSizes, offsets: rack.pipeProgressionOffsets,
                    slotSpacing: RackState.parseInches(runC2C.text) +
                        (_rackSpacingIsCenterToCenter || _rackPipeSizes.isEmpty ? 0 : _rackPipeOd(_rackPipeSizes.first))),
                  const SizedBox(height: 8),
                  _BeveledButton(onTap: () => setState(() => _splittingRack = true),
                    child: const Text('CONTINUE / BRANCH / END PIPES',
                      style: TextStyle(color: kLight, fontWeight: FontWeight.w800))),
                ],
                const SizedBox(height: 8),
                ],
                if (!canChangeRack || (!_editingContinuingRack && !_splittingRack)) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.blueAccent.withAlpha(100), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ADD STRAIGHTS',
                                style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1)),
                            Text('10ft (120") Sticks',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BeveledButton(
                            width: 40,
                            height: 40,
                            onTap: () => setState(() => _straightSticksCount =
                                math.max(1, _straightSticksCount - 1)),
                            child: const Text('-',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            width: 45,
                            alignment: Alignment.center,
                            child: Text('$_straightSticksCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                          ),
                          _BeveledButton(
                            width: 40,
                            height: 40,
                            onTap: () => setState(() => _straightSticksCount++),
                            child: const Text('+',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          _BeveledButton(
                            width: 80,
                            height: 40,
                            active: true,
                            onTap: () {
                              rack.addStraightSegment(
                                  _straightSticksCount * 120.0,
                                  multiplier: _rackPipeCount);
                              _triggerHubFlash();
                              setState(() => _straightSticksCount = 1);
                            },
                            child: const Text('ADD',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                _BeveledButton(
                  onTap: () {
                    _hideKeypad();
                    setState(() {
                      _isAddingStraightSegment = !_isAddingStraightSegment;
                      _editingSegmentIndex = null;
                      straightRunLengthCtl.clear();
                    });
                  },
                  child: Text(_isAddingStraightSegment
                      ? 'Close Custom Straight Length ▴'
                      : 'Add Custom Straight Length ▾',
                      style: const TextStyle(color: kLight, fontWeight: FontWeight.w700)),
                ),
                if (_isAddingStraightSegment) ...[
                  const SizedBox(height: 8),
                  _buildStraightPipeAdder(),
                ],
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _BeveledButton(
                        onTap: () {
                          rack.resetParallel90sState();
                          rack.setCalcMode(RackCalcMode.parallel90);
                          _beginNewBendResult();
                          rack.setIsFromBox(false);
                          setState(() {
                            _showRackSetupStart = false;
                            _isParallel90sMode = true;
                            stubCtl.clear();
                            legCtl.clear();
                            _parallel90ShowResults = false;
                            _showParallel90Measurements = true;
                            _activeController = stubCtl;
                            _isKeypadVisible = false;
                            _clearOnNextInput = true;
                          });
                        },
                        child: const Text('90s',
                            style: TextStyle(
                                color: kLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BeveledButton(
                        onTap: _chooseNewOffset,
                        child: const Text('Offsets',
                            style: TextStyle(
                                color: kLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
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
                          _beginNewBendResult();
                          setState(() {
                            _showRackSetupStart = false;
                            _isKick90sMode = true;
                            _activeController = kickStubCtl;
                            _isKeypadVisible = false;
                            _clearOnNextInput = true;
                          });
                          rack.setCalcMode(RackCalcMode.kick90);
                        },
                        child: const Text('Kick 90s',
                            style: TextStyle(
                                color: kLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
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
    final od = _rackPipeOd(
        _rackDefaultPipeSize.isEmpty ? '0.5' : _rackDefaultPipeSize);

    // Vertical Rise component (including Top/Bot landing adjustment)
    final verticalRise = rack.measureToTop ? (distBoxRaw + od) : distBoxRaw;

    return verticalRise;
  }

  double _calculateStartingPointLeg() {
    final distBoxRaw = RackState.parseInches(distanceFromBoxCtl.text);
    final od = _rackPipeOd(
        _rackDefaultPipeSize.isEmpty ? '0.5' : _rackDefaultPipeSize);
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
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2),
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
                  child: Text('RESET',
                      style: TextStyle(
                          color: kRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
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
                child: const Text('Straight',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BeveledButton(
                height: 34,
                active: _startingPointMode == '90Up',
                onTap: () => setState(() => _startingPointMode = '90Up'),
                child: const Text('90 Up from Box',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
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
          if (startingPointDistanceCtl.text.isNotEmpty &&
              startingPointDistanceCtl.text != '0"') ...[
            const SizedBox(height: 8),
            _BeveledButton(
              height: 40,
              active: false,
              redOutline: true,
              onTap: () {
                final dist =
                    RackState.parseInches(startingPointDistanceCtl.text);
                if (_savedStartingPoint != null) {
                  _goToChooseNextBend();
                  return;
                }
                if (!dist.isFinite || dist <= 0) return;
                rack.addStraightSegment(dist,
                    multiplier: _rackPipeCount, customLabel: 'Initial Run');
                _triggerHubFlash();
                _hideKeypad();
                _goToChooseNextBend();
              },
              child: Text(
                _savedStartingPoint == null ? 'ADD INITIAL RUN TO HUB' : 'BACK TO NEXT BEND',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12),
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
                        gradient: const LinearGradient(
                            colors: [Color(0xFF8A1010), Color(0xFFD12A2A)]),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Center(
                        child: Text(
                          rack.measureToTop ? 'TOP' : 'BOT',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Support Type:',
                          style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
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
                            child: const Text('1-5/8"',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
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
                            child: const Text('7/8"',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
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
                  onTap: _startingPointFullStick
                      ? null
                      : () => _showKeypad(wallToSupportCtl),
                  noBorder: true,
                  trailingSide: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'FULL\nSTICK?',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
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
                              final distBoxRaw = RackState.parseInches(
                                  distanceFromBoxCtl.text);
                              final od = _rackPipeOd(
                                  _rackDefaultPipeSize.isEmpty
                                      ? '0.5'
                                      : _rackDefaultPipeSize);
                              final verticalComponent = rack.measureToTop
                                  ? (distBoxRaw + od)
                                  : distBoxRaw;
                              final gain = _selectedRackBender?.gain ?? 0.0;
                              final horizontalComponent =
                                  120.0 - verticalComponent + gain;
                              wallToSupportCtl.text =
                                  RackState.inchFmt(horizontalComponent)
                                      .replaceAll('"', '');
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
                    final distBox =
                        RackState.parseInches(distanceFromBoxCtl.text);
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
                  child: const Text('KICK THIS 90?',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BeveledButton(
                  height: 40,
                  active: true,
                  onTap: () async {
                    if (_savedStartingPoint != null) {
                      _goToChooseNextBend();
                      return;
                    }
                    final stub = _calculateStartingPointStub();
                    final leg = _calculateStartingPointLeg();

                    if (stub > 0 && leg > 0) {
                      if (_parallel90ShowResults) return;
                      final cut = stub + leg - (_selectedRackBender?.gain ?? rack.benderGain);
                      if (cut > 120.001) {
                        final proceed = await showDialog<bool>(context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: kBlack,
                            title: const Text('Exceeds a full stick', style: TextStyle(color: kLight)),
                            content: Text('This 90 needs ${RackState.inchFmt(cut)} of pipe, '
                                '${RackState.inchFmt(cut - 120)} over a 120-inch stick. '
                                'Reduce the measurements or use Full Stick.',
                                style: const TextStyle(color: kLight)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Go Back', style: TextStyle(color: kLight))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Continue Anyway', style: TextStyle(color: kRed))),
                            ],
                          ));
                        if (!mounted || proceed != true) return;
                      }
                      _saveStateFromActiveController();

                      // Clear any existing starting supports to prevent duplicates
                      rack.removeSupportsByLabel('Vertical (from Box)');
                      rack.removeSupportsByLabel('Horizontal (off Wall)');

                      // Transition state to 90s results page
                      rack.setStubLength(stub);
                      rack.setLegLength(leg);
                      rack.setCalcMode(RackCalcMode.parallel90);
                      rack.setIsFromBox(
                          true); // Mark as Box Transition to disable graduation math

                      // Add starting supports
                      // 1. Vertical support (from Box)
                      final distBoxSupport =
                          RackState.parseInches(firstSupportFromBoxCtl.text);
                      if (distBoxSupport > 0) {
                        rack.addSupport(distBoxSupport,
                            label:
                                'Vertical (from Box) | ${RackState.inchFmt(distBoxSupport)}');
                      } else {
                        // Default to 36" if zero/empty to match field standard
                        rack.addSupport(36.0,
                            label: 'Vertical (from Box) | 36"');
                      }

                      // 2. Horizontal support (the user entered 'First Support (from Wall)')
                      final firstSupFromWall =
                          RackState.parseInches(firstSupportPosCtl.text);
                      if (firstSupFromWall > 0) {
                        // Position is Rise + Support distance off wall
                        rack.addSupport(stub + firstSupFromWall,
                            label:
                                'Horizontal (off Wall) | ${RackState.inchFmt(firstSupFromWall)}');
                      }

                      setState(() {
                        _showRackSetupStart = false;

                        _isOffsetMode = false;
                        _isKick90sMode = false;
                        _reviewingStartingPoint = false;
                        _isNextRackMode = true;
                        _isParallel90sMode = true;
                        _parallel90ShowResults = true;
                        _showParallel90Measurements = false;
                        _lastResultView = _RackResultView.parallel90;
                  _latestParallel90WasStartingPoint = rack.isFromBox;
                        _lastResultCommitted = false;
                        _viewingLatestResult = false;

                        _activeController = null;
                        _isKeypadVisible = false;
                        _clearOnNextInput = false;
                      });
                      _commitVisibleResultIfNeeded();
                    }
                  },
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _supportMoveDialogOpen = false;
  bool _stageLayoutDialogOpen = false;

  Future<bool?> _quickSupportDialog(String title, String message,
      {String action = 'ADD SUPPORT', String dismiss = 'NOT NOW'}) {
    return showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF252525),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.5)),
      title: Text(title, style: const TextStyle(color: kLight)),
      content: Text(message, style: const TextStyle(color: Colors.white70)),
      actions: [Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _BeveledButton(active: true, onTap: () => Navigator.pop(ctx, true),
            child: Text(action, style: const TextStyle(color: kLight, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          _BeveledButton(onTap: () => Navigator.pop(ctx, false),
            child: Text(dismiss, style: const TextStyle(color: kLight, fontWeight: FontWeight.w800))),
        ]))],
    ));
  }

  Map<double, double> _supportGaps() {
    final points = <double>{0, ...rack.supportPositions, rack.supportRunLength}
        .where((p) => p >= 0 && p <= rack.supportRunLength).toList()..sort();
    return {for (var i = 1; i < points.length; i++) points[i - 1]: points[i]};
  }

  Future<void> _checkSupportGaps(Map<double, double> before,
      List<double> previousSupports, double previousEnd) async {
    _hideKeypad();
    // Only flag gaps changed by this edit, not unrelated existing gaps.
    for (final gap in _supportGaps().entries) {
      if (gap.value - gap.key <= 120.001 || before[gap.key] == gap.value) continue;
      if (!mounted) return;
      final add = await _quickSupportDialog('Support gap',
          'Gap is now ${RackState.inchFmt(gap.value - gap.key)} (over 120″). Add a support?');
      if (!mounted) return;
      if (add == true) {
        // Open the existing editor so the user chooses the actual location.
        setState(() {
          _editingSupportIndex = null;
          _editingSupportParentSegmentIndex = null;
          _insertSupportAfter = gap.key;
          supportPosCtl.text = '120';
          _activeController = supportPosCtl;
          _clearOnNextInput = true;
          _isKeypadVisible = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final target = _supportAdderKey.currentContext;
          if (mounted && target != null) Scrollable.ensureVisible(target,
            duration: const Duration(milliseconds: 250));
        });
        return;
      }
    }
    final beyond = rack.supportPositions.where((p) => p > rack.supportRunLength &&
        (!previousSupports.contains(p) || p <= previousEnd)).length;
    if (beyond > 0 && mounted) {
      await _quickSupportDialog('Support beyond pipe',
          '$beyond support(s) are now beyond the pipe end. Keep them for a future extension or edit them in the Hub.',
          action: 'OK', dismiss: 'CLOSE');
    }
  }

  Future<void> _confirmStageLayoutChange(Object id, {double? newLength}) async {
    if (_stageLayoutDialogOpen) return;
    final index = rack.segmentIndex(id);
    if (index == null) return;
    _stageLayoutDialogOpen = true;
    final before = _supportGaps();
    final positions = List<double>.from(rack.supportPositions);
    final end = rack.supportRunLength;
    _hideKeypad();
    try {
      if (newLength == null) {
        final remove = await _quickSupportDialog('Remove stage?',
            'Existing supports will stay in place.', action: 'REMOVE', dismiss: 'CANCEL');
        if (!mounted || remove != true) return;
      }
      final current = rack.segmentIndex(id);
      if (current == null) return;
      if (newLength == null) {
        rack.removeSegment(current);
      } else {
        rack.updateSegment(current, length: newLength);
      }
      setState(() { _editingSegmentIndex = null; _editingSupportIndex = null; });
      await _checkSupportGaps(before, positions, end);
    } finally {
      _stageLayoutDialogOpen = false;
    }
  }

  Future<void> _confirmSupportInsert(double distance) async {
    final anchor = _insertSupportAfter;
    if (anchor == null || _supportMoveDialogOpen || !distance.isFinite || distance <= 0) return;
    final fromStart = anchor == 0 && !rack.supportPositions.contains(0);
    final inserted = fromStart
        ? (rack.supportPositions.isEmpty || distance < rack.supportPositions.first) &&
            !rack.isSharedSupport(distance)
        : rack.insertSupportAfter(anchor, distance, moveDownstream: false);
    if (fromStart && inserted) rack.addPlannedSupport(distance);
    if (!inserted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:
        Text('Enter a distance smaller than the gap to the next support.')));
    }
    setState(() => _insertSupportAfter = null);
  }
  Future<void> _confirmSupportMove(double measurement) async {
    if (_supportMoveDialogOpen) return;
    final index = _editingSupportIndex;
    if (index == null || index >= rack.supportPositions.length) return;
    final original = rack.supportPositions[index];
    final parent = _editingSupportParentSegmentIndex;
    final label = rack.getSupportLabel(original);
    double position;
    if (parent != null && label != null && label.contains('Turn') &&
        rack.runSequence[parent].distanceBefore90 != null) {
      final start = rack.runSequence.take(parent).fold<double>(0, (sum, s) => sum + s.supportLength);
      final corner = start + rack.runSequence[parent].distanceBefore90!;
      position = corner + (_editingSupportIsIncoming ? -measurement : measurement);
    } else if (label == 'Support (from Run Start)' ||
        (!rack.hubStartsAtBox &&
          (label == 'Vertical (from Box)' || label == 'Support (from Box)'))) {
      position = measurement;
    } else if (label != null && label.contains(' | ') &&
        (label.contains('from Box') || label.contains('off Wall'))) {
      position = original + measurement - RackState.parseInches(label.split(' | ')[1]);
    } else {
      position = (index == 0 ? 0 : rack.supportPositions[index - 1]) + measurement;
    }
    final delta = position - original;
    if (delta.abs() < 0.000001) {
      setState(() {
        _editingSupportIndex = null;
        _editingSupportParentSegmentIndex = null;
      });
      return;
    }
    _supportMoveDialogOpen = true;
    final before = _supportGaps();
    final positions = List<double>.from(rack.supportPositions);
    final end = rack.supportRunLength;
    try {
      if (!rack.moveSupport(index, position)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Keep the support between its neighboring supports.')));
        return;
      }
      setState(() {
        _editingSupportIndex = null;
        _editingSupportParentSegmentIndex = null;
      });
      await _checkSupportGaps(before, positions, end);
    } finally {
      _supportMoveDialogOpen = false;
    }
  }
  void _applyInitialKickHandoff() {
    final source = widget.initialKick!;
    _kickHandoffActive = true;
    _rackPipeCount = widget.initialPipeCount ?? 3;
    _rackPipeSizes.clear();
    _rackPipeSizes.addAll(widget.initialPipeSizes ??
        List.filled(_rackPipeCount, source.bender.conduitSize));
    _rackDefaultPipeSize = _rackPipeSizes.first;
    _rackConduitType = widget.boxLayoutConduitType ?? 'EMT';
    _rackSpacingIsCenterToCenter = widget.initialSpacingIsC2C;
    _spacingInteracted = true;
    rackPipeCountCtl.text = '$_rackPipeCount';
    rackDefaultPipeSizeCtl.text = _rackDefaultPipeSize;
    runC2C.text = RackState.inchFmt(widget.initialSpacing ?? 2);
    rack.setConduitType(_rackConduitType);
    rack.setIsFromBox(false);
    rack.setCalcMode(RackCalcMode.kick90);
    _isKick90sMode = true;
    _isParallel90sMode = false;
    _isOffsetMode = false;
    _showRackSetupStart = false;
    _showRackSetupOutput = true;
    _skipStartingPoint = true;
    _showKickMeasurements = true;
    _showRackResults = false;
    _showKickTypeSelector = false;
    _showKickTypeCard = true;
    _kickTypeConfirmed = false;
    _kickMeasurementsExpanded = true;
    _showKickBendingMethodCard = false;
    _selectedKickStyle = 'Parallel';
    _selectedKickType = 'Parallel';
    _activeController = null;
    _isKeypadVisible = false;
    _sendPipeProgressionOffsetsToRackState();
    _applyInitialBenderHandoff(); // Common bender/method restore with per-pipe overrides.
    kickStubCtl.setInches(source.stub);
    kickHeightCtl.text = RackState.inchFmt(source.height);
    kickAngleCtl.text = '${source.angle}°';
    kickLegCtl.text = RackState.inchFmt(source.leg);
    kickMatchBendCtl.clear();
    _applyKickRackInputsToState();
  }

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: child,
    );
  }

  Widget _rackSetupInfoRow(String label, String value,
      {VoidCallback? onTap,
      Widget? leadingInput,
      Widget? trailingBottom,
      Widget? trailingSide,
      bool noBorder = false}) {
    final bool isActive =
        (label == 'Pipe Count' && _activeController == rackPipeCountCtl) ||
            (label == 'Default Pipe Size (Temporary)' &&
                _activeController == rackDefaultPipeSizeCtl) ||
            (label == 'Spacing' && _activeController == runC2C) ||
            (label == 'Vertical (Box to Rack)' &&
                _activeController == distanceFromBoxCtl) ||
            (label == 'Vertical Support (from Box)' &&
                _activeController == firstSupportFromBoxCtl) ||
            (label == 'Horizontal (Off Wall)' &&
                _activeController == wallToSupportCtl) ||
            (label == 'First Support (from Wall)' &&
                _activeController == firstSupportPosCtl);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: noBorder ? Colors.transparent : Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: noBorder
              ? null
              : Border.all(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1A0A0A)
                        : const Color(0xFF111111),
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
      case '1/2':
        return '0.5';
      case '3/4':
        return '0.75';
      case '1':
        return '1.0';
      case '1 1/4':
        return '1.25';
      case '1 1/2':
        return '1.5';
      case '2':
        return '2.0';
      case '2 1/2':
        return '2.5';
      case '3':
        return '3.0';
      case '3 1/2':
        return '3.5';
      case '4':
        return '4.0';
      default:
        final d = double.tryParse(s);
        if (d != null) {
          return d.toString().contains('.')
              ? d.toString()
              : '${d.toString()}.0';
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
    if (_continuingLayoutKey == _rackLayoutKey && _continuingOffsets?.length == count) {
      return _continuingOffsets!.last + _rackPipeOd(_rackPipeSizes.first) / 2 +
          _rackPipeOd(_rackPipeSizes.last) / 2;
    }

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
      _rackPipeSizes
          .add(_rackDefaultPipeSize.isEmpty ? '1/2"' : _rackDefaultPipeSize);
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
                    // These picture variants start with Pipe 1 on the left.
                    // This changes only the rack strip, not photograph dots
                    // or the pipe identities used for calculated marks.
                    final bool kickInsideOnLeft = _isKick90sMode &&
                        ((_selectedKickStyle == '90 → Match Bend' &&
                            _kickVisualVariant == 'upRight') ||
                          (_selectedKickStyle == 'Same Angle 2' &&
                            _kickVisualVariant == 'upRight') ||
                          (_selectedKickStyle == 'Parallel' &&
                            _kickVisualVariant == 'downLeft'));
                    final bool flipRight = (_isKick90sMode && !kickInsideOnLeft) ||
                        (_isOffsetMode && rack.offsetDirectionSign == 1) ||
                        (_isParallel90sMode && _parallel90Direction == 'right');

                    final int index =
                        flipRight ? pipeCount - 1 - visualIndex : visualIndex;

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
                                  color:
                                      selected ? kRed : const Color(0xFFC8C8C8),
                                  width: selected ? 2.8 : 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  index < _rackPipeSizes.length
                                      ? _addInchIfMissing(_rackPipeSizes[index])
                                      : '—',
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

  Widget _buildRackSpacingReview() {
    final choiceKey = _rackPipeSizes.join('|');
    final ask = _isMixedSizes && _rackSpacingIsCenterToCenter &&
        _acceptedMixedSpacing != choiceKey;
    return Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ask ? kGreen : Colors.white54, width: ask ? 1.8 : 1.2)),
      child: Column(children: [
        _BeveledButton(onTap: () => setState(() => _spacingReviewExpanded = !_spacingReviewExpanded),
          child: Text('Spacing: ${_rackSpacingIsCenterToCenter ? "Center to Center" : "Space Between"} '
              '${runC2C.text} ${_spacingReviewExpanded ? "▴" : "▾"}',
            textAlign: TextAlign.center, style: const TextStyle(color: kLight, fontWeight: FontWeight.bold))),
        if (ask) ...[
          const Padding(padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Mixed pipe sizes will have different clear gaps. Keep center spacing or use equal gaps?',
              textAlign: TextAlign.center, style: TextStyle(color: kLight))),
          Row(children: [
            Expanded(child: _BeveledButton(height: 54,
              onTap: () => setState(() { _acceptedMixedSpacing = choiceKey; _spacingReviewExpanded = false; }),
              child: const Text('Keep Center\nto Center', textAlign: TextAlign.center,
                style: TextStyle(color: kLight, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 8),
            Expanded(child: _BeveledButton(height: 54, onTap: () {
              if (_activeController != null) _saveStateFromActiveController();
              setState(() {
                _rackSpacingIsCenterToCenter = false;
                _spacingInteracted = true;
                _spacingReviewExpanded = true;
                _activeController = runC2C;
                _isKeypadVisible = true;
                _clearOnNextInput = true;
                final gap = _gapBeforeMixedSizes;
                runC2C.text = gap != null && gap > 0 ? RackState.inchFmt(gap) : '';
                rack.setSpacing(gap != null && gap > 0 ? gap : 0);
                _sendPipeProgressionOffsetsToRackState();
              });
            }, child: const Text('Use Equal Gaps', textAlign: TextAlign.center,
              style: TextStyle(color: kLight, fontWeight: FontWeight.bold)))),
          ]),
        ],
        if (_spacingReviewExpanded) ...[
          const SizedBox(height: 8),
          _buildDualSpacingCard(),
        ],
      ]));
  }

  Widget _buildDualSpacingCard() {
    final bool hasInput = runC2C.text.trim().isNotEmpty;
    final double spacingVal =
        hasInput ? RackState.parseInches(runC2C.text) : 0.0;

    // Only use OD if default pipe size has been set to something other than 0/empty
    final bool hasPipeSize =
        _rackDefaultPipeSize.isNotEmpty && _rackDefaultPipeSize != '0"';
    final double od = hasPipeSize ? _rackPipeOd(_rackDefaultPipeSize) : 0.0;

    String spaceBetweenDisp = "—";
    String centerToCenterDisp = "—";

    if (hasInput && spacingVal > 0) {
      if (_rackSpacingIsCenterToCenter) {
        centerToCenterDisp = RackState.inchFmt(spacingVal);
        spaceBetweenDisp =
            hasPipeSize ? RackState.inchFmt(math.max(0, spacingVal - od)) : "—";
      } else {
        spaceBetweenDisp = RackState.inchFmt(spacingVal);
        centerToCenterDisp =
            hasPipeSize ? RackState.inchFmt(spacingVal + od) : "—";
      }
    } else if (hasInput) {
      // User has focused/started but hasn't entered a real number yet
      if (_rackSpacingIsCenterToCenter) {
        centerToCenterDisp = runC2C.text;
        spaceBetweenDisp = "—";
      } else {
        spaceBetweenDisp = runC2C.text;
        centerToCenterDisp = "—";
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
    if (_isMixedSizes && hasInput && spacingVal > 0 && _rackPipeSizes.length > 1) {
      final converted = <double>[];
      for (int i = 1; i < _rackPipeSizes.length; i++) {
        final radii = (_rackPipeOd(_rackPipeSizes[i - 1]) + _rackPipeOd(_rackPipeSizes[i])) / 2;
        converted.add(_rackSpacingIsCenterToCenter ? spacingVal - radii : spacingVal + radii);
      }
      final low = converted.reduce(math.min), high = converted.reduce(math.max);
      final display = low < 0 ? 'Overlap' :
          (high - low).abs() < 0.000001 ? RackState.inchFmt(low) :
          '${RackState.inchFmt(low)}–${RackState.inchFmt(high)}';
      if (_rackSpacingIsCenterToCenter) { spaceBetweenDisp = display; }
      else { centerToCenterDisp = display; }
    }
    // Border is green ONLY when we have focus on Spacing but haven't clicked a button yet
    final bool cardGlowGreen =
        (_activeController == runC2C && !_spacingInteracted) ||
            _spacingErrorGlow;
    final bool spacingIsActiveInput =
        (_activeController == runC2C && _spacingInteracted);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Border is green ONLY when waiting for user to click a row (Next Step)
          color: cardGlowGreen
              ? kGreen
              : (isMixedWarning ? kRed : const Color(0xFFC0C0C0)),
          width: (cardGlowGreen || isMixedWarning) ? 2.0 : 1.2,
        ),
      ),
      child: Column(
        children: [
          _dualSpacingRow(
            label: 'Space Between',
            value: spaceBetweenDisp,
            isActive: _spacingInteracted && !_rackSpacingIsCenterToCenter,
            // Individual button glows green ONLY when it is actively being edited
            isGlow: (spacingIsActiveInput && !_rackSpacingIsCenterToCenter),
            onTap: () {
              setState(() {
                _spacingInteracted =
                    true; // Turn off card border, turn on button border
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
            isActive: _spacingInteracted && _rackSpacingIsCenterToCenter,
            // Individual row button glows green ONLY when it is actively being edited
            isGlow: (spacingIsActiveInput && _rackSpacingIsCenterToCenter),
            onTap: () {
              setState(() {
                _spacingInteracted =
                    true; // Turn off card border, turn on button border
                if (!_rackSpacingIsCenterToCenter) {
                  _acceptedMixedSpacing = null;
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
    final widthNeeded = _rackWidthNeeded();

    // Suggested Strut: Width + 3-1/4" (1-5/8" overhang on each side)
    final double suggestedStrut = widthNeeded + 3.25;

    // Auto-calculate suggested strut ONLY if it hasn't been manually edited and isn't currently being edited
    if (!_strutLengthManuallyEdited &&
        widthNeeded > 0 &&
        _activeController != strutLengthCtl) {
      strutLengthCtl.text =
          RackState.inchFmt(suggestedStrut).replaceAll('"', '');
    }

    Widget row(String label, String value,
        {VoidCallback? onTap, bool highlight = false, bool isGlow = false}) {
      final bool isInteractive = onTap != null;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
            10, 6, 6, 6), // Nudged right side padding to 6px
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isGlow ? kGreen : const Color(0xFFC8C8C8),
            width: isGlow || isInteractive ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: highlight
                        ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
                        : const [Color(0xFF5A5A5F), Color(0xFF2C3030)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isGlow || isInteractive
                        ? kGreen
                        : const Color(0xFFD0D0D0),
                    width: isGlow || isInteractive ? 1.8 : 1.1,
                  ),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: kLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row(
          'Edge to Edge Distance of Pipes',
          RackState.inchFmt(widthNeeded),
          highlight: true,
        ),
        if (widthNeeded > 0) ...[
          const SizedBox(height: 6),
          row(
            'Suggested Strut Length',
            strutLengthCtl.text.isEmpty ? '0"' : strutLengthCtl.text,
            onTap: () => _showKeypad(strutLengthCtl),
            isGlow: _activeController == strutLengthCtl,
          ),
        ],
      ],
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
    if (_rackPipeSizes.isEmpty ||
        _selectedRackPipe < 0 ||
        _selectedRackPipe >= _rackPipeSizes.length) {
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
            if (_selectedRackPipe >= 0 &&
                _selectedRackPipe < _rackPipeSizes.length) {
              if (size != _rackPipeSizes[_selectedRackPipe] && !_isMixedSizes) {
                final spacing = RackState.parseInches(runC2C.text);
                _gapBeforeMixedSizes = _rackSpacingIsCenterToCenter
                    ? spacing - _rackPipeOd(_rackPipeSizes.first) : spacing;
              }
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
      legCtl.setInches(rack.legLength);
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

  Future<void> _chooseNewOffset() async {
    final rolling = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Offset Type', style: TextStyle(color: kLight)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BeveledButton(
              redOutline: true,
              onTap: () => Navigator.pop(dialogContext, false),
              child: const Text('Standard Offset', style: TextStyle(color: kLight)),
            ),
            const SizedBox(height: 12),
            _BeveledButton(
              redOutline: true,
              onTap: () => Navigator.pop(dialogContext, true),
              child: const Text('Rolling Offset', style: TextStyle(color: kLight)),
            ),
          ],
        ),
        actions: [TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel', style: TextStyle(color: kLight)),
        )],
      ),
    );
    if (!mounted || rolling == null) return;
    _beginNewBendResult();
    for (final controller in [offsetDistanceCtl, offsetHeightCtl,
      offsetOverallCtl, offsetAngleCtl, rollingDistanceCtl, rollingVerticalCtl,
      rollingHorizontalCtl, rollingOverallCtl, rollingAngleCtl]) {
      controller.clear();
    }
    rack.setOffsetInputs(distanceToObstruction: 0, offsetHeightValue: 0,
        overallLengthValue: 0, bendAngleValue: 0);
    rack.setRollingOffsetInputs(distanceToObstruction: 0, verticalOffset: 0,
        horizontalOffset: 0, overallLengthValue: 0, bendAngleValue: 0);
    rack.startOffsetUp();
    if (rolling) rack.startRollingOffset();
    rack.setFullStick(false);
    setState(() {
      _showRackSetupStart = false;
      _isOffsetMode = true;
      _isParallel90sMode = false;
      _isKick90sMode = false;
      _showOffsetInputs = true;
      _offsetMeasurementsExpanded = true;
      _showOffsetBendingMethod = false;
      _showOffsetGeometryResults = false;
      _showRackResults = false;
      _viewingLatestResult = false;
      _activeController = rolling ? rollingVerticalCtl : offsetHeightCtl;
      _isKeypadVisible = false;
      _clearOnNextInput = true;
    });
    if (_scrollCtl.hasClients) _scrollCtl.jumpTo(0);
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
    if (widget.savedResult != null) {
      final index = _currentSet * 3 + i;
      if (index < rack.allConduits.length) setState(() => rack.select(index));
      return;
    }
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

    final parsed = controller is PreciseInchesController
        ? controller.inches : RackState.parseInches(value);
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
      _showRackSetupOutput =
          _rackPipeCount > 0 && runC2C.text.trim().isNotEmpty;
      setState(() => _showSpacingError = true);
    } else if (controller == stubCtl) {
      stubCtl.text = formatted;
      rack.setStubLength(parsed);
    } else if (controller == legCtl) {
      legCtl.setInches(parsed);
      rack.setLegLength(parsed);
    } else if (controller == kickStubCtl) {
      kickStubCtl.setInches(parsed);
      _applyKickRackInputsToState();
    } else if (controller == kickLegCtl) {
      kickLegCtl.text = formatted;
      _applyKickRackInputsToState();
    } else if (controller == kickHeightCtl) {
      kickHeightCtl.text = formatted;
      _applyKickRackInputsToState();
    } else if (controller == kickMatchBendCtl) {
      kickMatchBendCtl.text = formatted;
      _applyKickRackInputsToState();
    } else if (controller == kickAngleCtl) {
      final angle = double.tryParse(value.replaceAll('°', '').trim()) ?? 0.0;
      kickAngleCtl.text = '${angle.toStringAsFixed(angle % 1 == 0 ? 0 : 1)}°';
      _applyKickRackInputsToState();
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
      if (_insertSupportAfter != null) {
        _confirmSupportInsert(parsed);
      } else if (_editingSupportIndex != null) {
        _confirmSupportMove(parsed);
      } else {
        // A new support is measured from the last committed support.
        if (!parsed.isFinite || parsed <= 0) return;
        double prevPos =
            rack.supportPositions.isEmpty ? 0.0 : rack.supportPositions.last;
        rack.addPlannedSupport(prevPos + parsed,
            label: rack.supportPositions.isEmpty
                ? (rack.hubStartsAtBox
                    ? 'Vertical (from Box)'
                    : 'Support (from Run Start)')
                : null);
      }
    } else if (controller == strutLengthCtl) {
      strutLengthCtl.text = formatted;
      _strutLengthManuallyEdited = true;
    } else if (controller == straightRunLengthCtl) {
      if (!parsed.isFinite || parsed <= 0) return;
      straightRunLengthCtl.text = formatted;
      if (_editingSegmentId != null) {
        final index = _editingSegmentIndex;
        if (index != null) _confirmStageLayoutChange(rack.runSequence[index].id, newLength: parsed);
        _editingSegmentIndex = null;
      } else if (_isAddingStraightSegment) {
        rack.addStraightSegment(parsed,
            multiplier: _rackPipeCount);
        _isAddingStraightSegment = false;
      }
      _triggerHubFlash();
    } else if (controller == offsetHeightCtl ||
        controller == offsetAngleCtl ||
        controller == offsetDistanceCtl ||
        controller == offsetOverallCtl) {
      if (controller == offsetAngleCtl) {
        controller.text = value.endsWith('°') ? value : '$value°';
      } else {
        controller.text = formatted;
      }
      _onOffsetInputSubmitted();
    } else if (controller == rollingVerticalCtl ||
        controller == rollingHorizontalCtl ||
        controller == rollingAngleCtl ||
        controller == rollingDistanceCtl ||
        controller == rollingOverallCtl) {
      if (controller == rollingAngleCtl) {
        controller.text = value.endsWith('°') ? value : '$value°';
      } else {
        controller.text = formatted;
      }
      _onRollingInputSubmitted();
    }
  }

  void _showKeypad(TextEditingController controller) {
    if (_activeController != null && _activeController != controller) {
      _saveStateFromActiveController();
    }

    setState(() {
      _activeController = controller;
      _isKeypadVisible = true;
      _clearOnNextInput = false; // We are clearing immediately below instead

      // BLANK OUT IMMEDIATELY
      if (controller == offsetAngleCtl ||
          controller == rollingAngleCtl ||
          controller == kickAngleCtl) {
        controller.text = '0°';
      } else if (controller == rackPipeCountCtl) {
        controller.text = '';
      } else {
        controller.text = '0"';
      }

      if (controller == runC2C) {
        _spacingErrorGlow = false;
        setState(() => _showSpacingError = false);
      }

      // Immediate visual feedback: Clear and flag manual mode for these fields
      if (controller == supportPosCtl ||
          controller == nextRackDistanceCtl ||
          controller == strutLengthCtl) {
        controller.text = '0"';
        if (controller == strutLengthCtl) {
          _strutLengthManuallyEdited =
              true; // Stop auto-overwriting immediately
        }
      }

      if (controller == rackPipeCountCtl ||
          controller == rackDefaultPipeSizeCtl ||
          controller == runC2C) {
        _showRackSetupOutput = false;
      }
    });
  }

  void _hideKeypad() {
    setState(() {
      _activeController = null;
      _isKeypadVisible = false;
      _insertSupportAfter = null;
    });
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final controller = _activeController!;
    if (value != '✔' && controller is PreciseInchesController) {
      controller.beginManualEdit();
    }

    if (value == '⌫') {
      setState(() {
        final bool needsInch = (controller == stubCtl ||
            controller == legCtl ||
            controller == runC2C ||
            controller == boxC2C ||
            controller == distanceFromBoxCtl ||
            controller == wallToSupportCtl ||
            controller == firstSupportPosCtl ||
            controller == startingPointDistanceCtl ||
            controller == supportPosCtl ||
            controller == nextRackDistanceCtl ||
            controller == strutLengthCtl ||
            controller == offsetHeightCtl ||
            controller == offsetDistanceCtl ||
            controller == offsetOverallCtl ||
            controller == rollingVerticalCtl ||
            controller == rollingHorizontalCtl ||
            controller == rollingDistanceCtl ||
            controller == rollingOverallCtl ||
            controller == kickStubCtl ||
            controller == kickHeightCtl ||
            controller == kickMatchBendCtl ||
            controller == kickLegCtl);

        final bool needsDegree = (controller == offsetAngleCtl ||
            controller == rollingAngleCtl ||
            controller == kickAngleCtl);

        if (controller.text.isNotEmpty) {
          String t = controller.text;
          if (needsInch && t.endsWith('"')) t = t.substring(0, t.length - 1);
          if (needsDegree && t.endsWith('°')) t = t.substring(0, t.length - 1);

          if (t.isNotEmpty) {
            t = t.substring(0, t.length - 1);
            if (needsInch)
              controller.text = '$t"';
            else if (needsDegree)
              controller.text = '$t°';
            else
              controller.text = t;

            if (controller.text == '"' || controller.text == '°') {
              controller.text = (controller.text == '"') ? '0"' : '0°';
            }
          }
        }
      });
      return;
    }

    if (value == '✔' && controller == supportPosCtl) {
      _saveStateFromActiveController();
      _hideKeypad();
      return;
    }

    if (value == '✔') {
      _saveStateFromActiveController();

      // Sequential advance for Setup
      if (controller == rackPipeCountCtl) {
        _hideKeypad();
        // REMOVED: _showRackBenderPicker(); (No longer jumps prematurely)
        return;
      }

      // Sequential advance for 90s
      if (controller == stubCtl) {
        _showKeypad(legCtl);
        return;
      }

      // Sequential advance for Offset
      if (controller == offsetHeightCtl) {
        _showKeypad(offsetAngleCtl);
        return;
      }
      if (controller == offsetAngleCtl) {
        _showKeypad(offsetDistanceCtl);
        return;
      }
      if (controller == offsetDistanceCtl) {
        if (rack.isFullStick) {
          _hideKeypad();
        } else {
          _showKeypad(offsetOverallCtl);
        }
        return;
      }

      // Sequential advance for Rolling Offset
      if (controller == rollingVerticalCtl) {
        _showKeypad(rollingHorizontalCtl);
        return;
      }
      if (controller == rollingHorizontalCtl) {
        _showKeypad(rollingAngleCtl);
        return;
      }
      if (controller == rollingAngleCtl) {
        _showKeypad(rollingDistanceCtl);
        return;
      }
      if (controller == rollingDistanceCtl) {
        if (rack.isFullStick) {
          _hideKeypad();
        } else {
          _showKeypad(rollingOverallCtl);
        }
        return;
      }

      // Sequential advance for Kick 90s
      if (controller == kickStubCtl) {
        if (!rack.isFromBox) {
          _showKeypad(kickLegCtl);
        } else {
          _showKeypad(kickHeightCtl);
        }
        return;
      }
      if (controller == kickLegCtl) {
        _showKeypad(kickHeightCtl);
        return;
      }
      if (controller == kickHeightCtl) {
        if (_kickUsesMatchBendInput) {
          _showKeypad(kickMatchBendCtl);
        } else {
          _showKeypad(kickAngleCtl);
        }
        return;
      }
      if (controller == kickAngleCtl || controller == kickMatchBendCtl) {
        _hideKeypad();
        return;
      }

      _hideKeypad();
      return;
    }

    setState(() {
      // Logic for Start Point and 90s: automatic inches
      final bool needsInch = (controller == stubCtl ||
          controller == legCtl ||
          controller == runC2C ||
          controller == boxC2C ||
          controller == distanceFromBoxCtl ||
          controller == wallToSupportCtl ||
          controller == firstSupportPosCtl ||
          controller == startingPointDistanceCtl ||
          controller == supportPosCtl ||
          controller == nextRackDistanceCtl ||
          controller == strutLengthCtl ||
          controller == offsetHeightCtl ||
          controller == offsetDistanceCtl ||
          controller == offsetOverallCtl ||
          controller == rollingVerticalCtl ||
          controller == rollingHorizontalCtl ||
          controller == rollingDistanceCtl ||
          controller == rollingOverallCtl ||
          controller == kickStubCtl ||
          controller == kickHeightCtl ||
          controller == kickMatchBendCtl ||
          controller == kickLegCtl);

      final bool needsDegree = (controller == offsetAngleCtl ||
          controller == rollingAngleCtl ||
          controller == kickAngleCtl);

      if (controller == runC2C) {
        _showSpacingError = false;
        _spacingErrorTimer?.cancel();
        _spacingErrorTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showSpacingError = true);
        });
      }

      // Clear if it's a fresh focus, zero, or flagged
      if (_clearOnNextInput ||
          controller.text == '0"' ||
          controller.text == '0°' ||
          controller.text == '0') {
        if (needsInch)
          controller.text = '"';
        else if (needsDegree)
          controller.text = '°';
        else
          controller.text = '';
        _clearOnNextInput = false;
      }

      String valToAppend = value.replaceAll('°', '').replaceAll('"', '');
      if (value.contains('/')) {
        String currentClean =
            controller.text.replaceAll('"', '').replaceAll('°', '').trim();
        if (currentClean.isNotEmpty && !currentClean.endsWith(' ')) {
          valToAppend = ' ' + valToAppend;
        }
      }

      // Append text while preserving the mark at the end
      if (needsInch) {
        String current = controller.text.replaceAll('"', '');
        String next = current + valToAppend;
        controller.text = '$next"';
      } else if (needsDegree) {
        String current = controller.text.replaceAll('°', '');
        String next = current + valToAppend;
        controller.text = '$next°';
      } else {
        controller.text = controller.text + valToAppend;
      }
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
    final stub = kickStubCtl.inches;
    final kickHeight = RackState.parseInches(kickHeightCtl.text);
    final leg = RackState.parseInches(kickLegCtl.text);
    final angle = double.tryParse(
          kickAngleCtl.text.replaceAll('°', '').trim(),
        ) ??
        30.0;
    final matchBendDistance = RackState.parseInches(kickMatchBendCtl.text);

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
      style: _selectedKickStyle == 'Parallel'
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

  double get _kickLongestCutLength {
    if (rack.allConduits.isEmpty) return 0.0;
    double longestLength = 0.0;
    for (final pipe in rack.allConduits) {
      if (pipe.ol.isFinite && pipe.ol > longestLength) {
        longestLength = pipe.ol;
      }
    }
    return longestLength;
  }

  int get _kickLongestPipeNumber {
    if (rack.allConduits.isEmpty) return 0;
    int longestIndex = 0;
    double longestLength = double.negativeInfinity;
    for (int i = 0; i < rack.allConduits.length; i++) {
      final length = rack.allConduits[i].ol;
      if (length.isFinite && length > longestLength) {
        longestLength = length;
        longestIndex = i;
      }
    }
    return longestIndex + 1;
  }

  bool get _kickInputsReadyForLengthCheck {
    final hasBackDistance = kickStubCtl.inches > 0;
    final hasAfterDistance = kickLegCtl.text.trim().isNotEmpty;
    final hasHeight = RackState.parseInches(kickHeightCtl.text) > 0;
    final hasGeometry = _kickUsesMatchBendInput
        ? RackState.parseInches(kickMatchBendCtl.text) > 0
        : (double.tryParse(kickAngleCtl.text.replaceAll('°', '').trim()) ?? 0) >
            0;
    return hasBackDistance && hasAfterDistance && hasHeight && hasGeometry;
  }

  void _useMaximumKickStub() {
    if (!_kickInputsReadyForLengthCheck) return;
    _applyKickRackInputsToState();
    final currentStub = kickStubCtl.inches;
    final longestCut = _kickLongestCutLength;
    if (longestCut <= 0 || !longestCut.isFinite) return;

    final optimizedStub = currentStub + (120.0 - longestCut);
    // Keep exact precision for calculations; only the field display is rounded.
    // Subsequent navigation must not parse that rounded display back into state.
    final fittingStub = optimizedStub;
    final minimumStub = _selectedRackBender?.deduct ?? rack.benderTakeup;
    if (fittingStub < minimumStub) return;

    setState(() {
      kickStubCtl.setInches(fittingStub);
      _applyKickRackInputsToState();
    });
  }

  void _continueKickMeasurements({bool allowOverlength = false}) {
    _applyKickRackInputsToState();
    _sendPipeProgressionOffsetsToRackState();

    if (!allowOverlength &&
        _kickInputsReadyForLengthCheck &&
        _kickLongestCutLength > 120.001) {
      _hideKeypad();
      FocusScope.of(context).unfocus();
      setState(() {
        _kickMeasurementsExpanded = true;
        _showKickBendingMethodCard = false;
        _kickBendingMethodConfirmed = false;
      });
      return;
    }

    _hideKeypad();
    FocusScope.of(context).unfocus();
    setState(() {
      _kickMeasurementsExpanded = false;
      _showKickBendingMethodCard = true;
      _kickBendingMethodConfirmed = true;
    });
  }

  bool get _kickUsesMatchBendInput {
    return _selectedKickStyle == '90 → Match Bend' ||
        _selectedKickStyle == '90 → Match Bend 2';
  }

  bool get _kickUsesAngleInput {
    return !_kickUsesMatchBendInput;
  }

  Widget _buildKickDirectionRow() {
    Widget arrowButton({
      required int quarterTurns,
      required bool active,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: _BeveledButton(
          active: active,
          onTap: onTap,
          child: RotatedBox(
            quarterTurns: quarterTurns,
            child: const Text(
              '➜',
              style: TextStyle(
                color: kLight,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
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
          const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('KICK DIRECTION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text('TURN DIRECTION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                arrowButton(
                  quarterTurns: 3,
                  active: _kickVerticalDirection == 'up',
                  onTap: () => setState(() => _kickVerticalDirection = 'up'),
                ),
                const SizedBox(width: 4),
                arrowButton(
                  quarterTurns: 1,
                  active: _kickVerticalDirection == 'down',
                  onTap: () => setState(() => _kickVerticalDirection = 'down'),
                ),
                const SizedBox(width: 12),
                arrowButton(
                  quarterTurns: 2,
                  active: _kickDirection == 'left',
                  onTap: () => setState(() => _kickDirection = 'left'),
                ),
                const SizedBox(width: 4),
                arrowButton(
                  quarterTurns: 0,
                  active: _kickDirection == 'right',
                  onTap: () => setState(() => _kickDirection = 'right'),
                ),
              ],
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

    if (_selectedKickStyle == 'Parallel') {
      return runCenterToCenter * bending_data.calculateCosecant(rack.kickAngle);
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

              if (buttonValue == 'Parallel') {
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
              ? const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('90', style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w800)),
                    SizedBox(width: 6),
                    Text('➜', style: TextStyle(color: kLight, fontSize: 20, fontWeight: FontWeight.w900)),
                    SizedBox(width: 6),
                    Text('Match Bend', style: TextStyle(color: kLight, fontSize: 14, fontWeight: FontWeight.w800)),
                  ]),
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
                typeButton('Parallel'),
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
                  _kickMeasurementsExpanded = true;
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
    final bool isMachineBender = bending_data.mechanicalElectricBenderBrands
        .contains(_selectedRackBenderBrand);

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
                      rack.setBendingMethod(
                          bending_data.BendingMethod.centerline,
                          arrow: true);
                    });
                  },
                  child: const Text('ARROW',
                      style: TextStyle(
                          color: kLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _BeveledButton(
                  active: !rack.isArrowMethod &&
                      (rack.bendingMethod == bending_data.BendingMethod.notch ||
                          rack.bendingMethod ==
                              bending_data.BendingMethod.hook),
                  onTap: () {
                    setState(() {
                      final m = isMachineBender
                          ? bending_data.BendingMethod.hook
                          : bending_data.BendingMethod.notch;
                      _kickMarkMethod = m;
                      rack.setBendingMethod(m, arrow: false);
                    });
                  },
                  child: Text(isMachineBender ? 'HOOK' : 'NOTCH',
                      style: const TextStyle(
                          color: kLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _BeveledButton(
                  active: !rack.isArrowMethod &&
                      rack.bendingMethod ==
                          bending_data.BendingMethod.centerline,
                  onTap: () {
                    setState(() {
                      _kickMarkMethod = bending_data.BendingMethod.centerline;
                      rack.setBendingMethod(
                          bending_data.BendingMethod.centerline,
                          arrow: false);
                    });
                  },
                  child: const Text('℄ LINE',
                      style: TextStyle(
                          color: kLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
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
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                _BeveledButton(
                  width: 90,
                  height: 34,
                  active: !rack.isBenderDirectionReversed,
                  onTap: () => setState(() => rack
                      .setBendingMethod(rack.bendingMethod, reverse: false)),
                  child: const Text('FORWARD',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                _BeveledButton(
                  width: 90,
                  height: 34,
                  active: rack.isBenderDirectionReversed,
                  onTap: () => setState(() =>
                      rack.setBendingMethod(rack.bendingMethod, reverse: true)),
                  child: const Text('REVERSE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _getBendingMethodExplanation(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKickBendingMethodCard() {
    final bool isMachineBender = bending_data.mechanicalElectricBenderBrands
        .contains(_selectedRackBenderBrand);

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
            style: TextStyle(
                color: kLight, fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BeveledButton(
                  active: rack.bendingMethod ==
                      (isMachineBender
                          ? bending_data.BendingMethod.hook
                          : bending_data.BendingMethod.notch),
                  onTap: () {
                    setState(() {
                      rack.setBendingMethod(
                          isMachineBender
                              ? bending_data.BendingMethod.hook
                              : bending_data.BendingMethod.notch,
                          arrow: false);
                    });
                  },
                  child: Text(isMachineBender ? 'USE HOOK' : 'USE NOTCH',
                      style: const TextStyle(
                          color: kLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BeveledButton(
                  active: rack.bendingMethod ==
                      bending_data.BendingMethod.centerline,
                  onTap: () {
                    setState(() {
                      rack.setBendingMethod(
                          bending_data.BendingMethod.centerline,
                          arrow: false);
                    });
                  },
                  child: const Text('USE CENTERLINE',
                      style: TextStyle(
                          color: kLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Text(
              rack.bendingMethod == bending_data.BendingMethod.centerline
                  ? "90: Use the bender arrow at Mark A. KICK: Align the center-of-bend mark for the selected kick angle at Mark B. Mark C is the cut length."
                  : (isMachineBender
                      ? "90: Use the bender arrow at Mark A. KICK: Align the front edge of the hook at Mark B. Mark C is the cut length."
                      : "90: Use the bender arrow at Mark A. KICK: Use the 45° notch at Mark B. The app adjusts the kick mark automatically; Mark C is the cut length."),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.35),
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
        ? math.sqrt(
            math.pow(rack.offsetHeight, 2) + math.pow(rack.offsetHorizontal, 2))
        : rack.offsetHeight;
    final double angle = rack.bendAngle;

    // PULL DATA FROM THE ACTUAL SELECTED BENDER/CONDUIT DATA in RackState
    final pipe = rack.allConduits.first;
    final double clr = pipe.benderCLR ?? rack.kickCLR;
    final double pipeOD = pipe.pipeOD ?? rack.kickPipeOD;
    final double takeUp = pipe.benderTakeup ?? rack.benderTakeup;

    final double shrink = offsetVal * math.tan((angle * math.pi / 180.0) / 2.0);

    double radAdj = 0.0;
    double refAdj = 0.0;
    String refLabel = 'Reference Adjustment';

    if (!rack.isArrowMethod && clr > 0) {
      radAdj =
          bending_data.calculateRadiusAdjustment(clr: clr, angleDeg: angle);
      if (rack.bendingMethod == bending_data.BendingMethod.notch) {
        refAdj =
            bending_data.calculate45NotchCorrection(clr: clr, angleDeg: angle);
        refLabel = 'Notch Adjustment';
      } else if (rack.bendingMethod == bending_data.BendingMethod.hook) {
        refAdj = bending_data.calculateFrontHookAdjustment(
            deduct: takeUp, clr: clr, pipeOD: pipeOD, angleDeg: angle);
        refLabel = 'Front Hook Adjustment';
      }
    }

    final double travel = offsetVal / math.sin(angle * math.pi / 180.0);

    // START WITH RAW CENTER MARK
    final double rawCenterA = rack.offsetDistance + shrink;

    // APPLY BENDER ADJUSTMENT (Mirror main result logic)
    double firstAdjustedA = rawCenterA;
    if (!rack.isArrowMethod && clr > 0) {
      final double baseMarkA = rawCenterA - radAdj;
      firstAdjustedA = bending_data.convertCenterMarkToBenderReference(
        centerMark: baseMarkA,
        method: rack.bendingMethod,
        clr: clr,
        deduct: takeUp,
        pipeOD: pipeOD,
        angleDeg: angle,
        reverse: rack.isBenderDirectionReversed,
      );
    }

    // GRADUATION CHECK: Calculate where the LAST pipe's Mark A will land
    final double spacing = rack.centerToCenterSpacing;
    final int count = _rackPipeCount;
    double maxMarkA = firstAdjustedA;

    if (count > 1) {
      // For Parallel Offsets (Left/Right), the shift per pipe is spacing * tan(angle/2)
      final double shiftPerPipe =
          spacing * math.tan((angle * math.pi / 180.0) / 2.0);
      maxMarkA = firstAdjustedA + (shiftPerPipe * (count - 1));
    }

    final double maxLen =
        rack.isFullStick ? 120.0 : rack.overallLength + shrink;
    final bool isOverLength = maxMarkA > (maxLen - 0.5); // 1/2" safety buffer

    Widget resRow(String label, String value, {bool isRed = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isRed
                      ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)]
                      : [const Color(0xFF5A5A5F), const Color(0xFF2C3030)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isRed ? kRed : const Color(0xFFD0D0D0), width: 1.2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isOverLength ? kRed : const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('OFFSET GEOMETRY',
              style: TextStyle(
                  color: kLight, fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (isOverLength) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: kRed.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kRed)),
              child: const Text(
                '⚠️ IMPOSSIBLE BEND\nMark A exceeds pipe length!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: kRed, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ],
          resRow('Shrink', RackState.inchFmt(shrink)),
          resRow('Distance Between Bends', RackState.inchFmt(travel)),
          resRow('Mark A (Furthest Pipe)', RackState.inchFmt(maxMarkA),
              isRed: isOverLength),
          resRow('Radius Adjustment',
              rack.isArrowMethod ? '—' : RackState.inchFmt(radAdj)),
          resRow(
              refLabel,
              (rack.isArrowMethod ||
                      rack.bendingMethod ==
                          bending_data.BendingMethod.centerline)
                  ? '—'
                  : RackState.inchFmt(refAdj)),
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
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Workflow:',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Start by entering the measurements for your first pipe (the inside of the turn). The app automatically adjusts stubs, legs, and kick heights for subsequent pipes to maintain perfectly parallel spacing.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Notch:',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Standard for hand benders. Translates center-of-bend measurements to the 45° notch / teardrop.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Hook:',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Standard for machine benders. Translates center-of-bend measurements to the front edge of the hook.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Centerline:',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose this if you have marked your own center-of-bend lines on the shoe.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
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
        _beginNewBendResult();
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
                rack.setOffsetDirection(-1);
                setState(() => _rollingNeedsDirection = false);
              },
              child: const RotatedBox(
                quarterTurns: 2,
                child: Text("➜",
                    style: TextStyle(
                        color: kLight,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(width: spacing),

          if (!rack.isRollingMode) ...[
          // UP
          Expanded(
            child: _BeveledButton(
              active: rack.offsetDirectionSign == 0,
              onTap: () {
                rack.setOffsetDirection(0);
                setState(() => _rollingNeedsDirection = false);
              },
              child: const RotatedBox(
                quarterTurns: -1,
                child: Text("➜",
                    style: TextStyle(
                        color: kLight,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(width: spacing),

          // DOWN
          Expanded(
            child: _BeveledButton(
              active: rack.offsetDirectionSign == 2,
              onTap: () {
                rack.setOffsetDirection(2);
                setState(() => _rollingNeedsDirection = false);
              },
              child: const RotatedBox(
                quarterTurns: 1,
                child: Text("➜",
                    style: TextStyle(
                        color: kLight,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(width: spacing),

          ],
          // RIGHT
          Expanded(
            child: _BeveledButton(
              active: rack.offsetDirectionSign == 1,
              onTap: () {
                rack.setOffsetDirection(1);
                setState(() => _rollingNeedsDirection = false);
              },
              child: const Text("➜",
                  style: TextStyle(
                      color: kLight,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
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
                onTap: _chooseNewOffset,
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
                    _beginNewBendResult();
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
    _kickHandoffActive = false;
    _reviewingStartingPoint = false;
    _hideKeypad();
    FocusScope.of(context).unfocus();

    rack.setIsFromBox(
        false); // Move out of transition mode for subsequent bends

    setState(() {
      _viewingLatestResult = false;
      _isProjectHubVisible = false; // Hide Hub to show the menu
      _showRackSetupStart = true;
      _choosingNextBend = true;
      _reviewingStartingPoint = false;
      _showKickTypeCard = true;
      _kickTypeConfirmed = false;
      _showKickBendingMethodCard = false;
      _rackNextBendMode = true;
      _straightSticksCount = 1;

      // Expand the Bend Type section for the next stage
      _isRackSetupExpanded = false;
      _isRackBenderExpanded = false;
      _isRackBendTypeExpanded = true;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_choosingNextBend) return;
      final nextBendContext = _nextBendKey.currentContext;
      if (nextBendContext != null) {
        final heading = nextBendContext.findRenderObject() as RenderBox?;
        final viewport = Scrollable.of(nextBendContext).position.viewportDimension;
        final alignmentSpace = viewport - (heading?.size.height ?? 60);
        final alignment = alignmentSpace > 0
            ? (0.04 - 15 / alignmentSpace).clamp(0.0, 1.0).toDouble()
            : 0.0;
        Scrollable.ensureVisible(nextBendContext,
            alignment: alignment,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOut);
      }
    });
  }

  bool get _isResultVisible =>
      (_isParallel90sMode && _parallel90ShowResults) ||
      (_isOffsetMode && _showRackResults) ||
      (_isKick90sMode && _showKickTypeSelector);

  bool get _canAdvanceToNextBend => _isResultVisible;

  bool get _canGoBackOneStep =>
      Navigator.canPop(context) ||
      _isProjectHubVisible ||
      !_showRackSetupStart ||
      _isOffsetMode ||
      _isParallel90sMode ||
      _isKick90sMode ||
      _choosingNextBend ||
      _isRackBenderExpanded ||
      _isRackBendTypeExpanded;

  void _openLatestResult() {
    if (_resultBeforeRackChange != null) {
      _openSavedResult(_resultBeforeRackChange!);
      return;
    }
    final resultView = _lastResultView;
    if (resultView == null) return;

    _hideKeypad();
    if (resultView == _RackResultView.parallel90) {
      rack.setIsFromBox(_latestParallel90WasStartingPoint);
      rack.forceRefresh();
      stubCtl.text = RackState.inchFmt(rack.stubLength);
      legCtl.setInches(rack.legLength);
    }
    _reviewingStartingPoint = false;
    setState(() {
      _isParallel90sMode = false;
      _isOffsetMode = false;
      _isKick90sMode = false;
      _parallel90ShowResults = false;
      _showRackResults = false;
      _showKickTypeSelector = false;

      switch (resultView) {
        case _RackResultView.parallel90:
          _isParallel90sMode = true;
          _parallel90ShowResults = true;
          _showParallel90Measurements = false;
          break;
        case _RackResultView.offset:
        case _RackResultView.rollingOffset:
          _isOffsetMode = true;
          _showRackResults = true;
          _showOffsetInputs = false;
          _showOffsetBendingMethod = false;
          _showOffsetGeometryResults = false;
          break;
        case _RackResultView.kick90:
          _isKick90sMode = true;
          _showKickMeasurements = false;
          _showKickTypeSelector = true;
          _showKickBendingMethodCard = false;
          break;
      }

      _showRackSetupStart = false;
      _viewingLatestResult = true;
    });
  }

  void _commitVisibleResultIfNeeded() {
    if (_lastResultCommitted) return;

    if (_isParallel90sMode && _parallel90ShowResults) {
      final label = rack.isFromBox ? '90° Up (Box Transition)' : '90° Rack';
      final gain = _selectedRackBender?.gain ?? rack.benderGain;
      final takeup = _selectedRackBender?.deduct ?? rack.benderTakeup;
      rack.addBendSegment(
        label,
        90.0,
        rack.stubLength + rack.legLength - gain,
        commitId: _resultCommitId,
        savedResult: _captureHubResult(),
        multiplier: _rackPipeCount,
        stub: rack.stubLength,
        leg: rack.legLength,
        gain: gain,
        takeup: takeup,
        direction: _parallel90Direction,
      );
    } else if (_isKick90sMode && _showKickTypeSelector) {
      rack.addBendSegment(
        'Kick 90',
        90.0 + rack.kickAngle,
        rack.kickStubLength + rack.kickLegLength,
        commitId: _resultCommitId,
        savedResult: _captureHubResult(),
        multiplier: _rackPipeCount,
        stub: rack.kickStubLength,
        leg: rack.kickLegLength,
        direction: _kickDirection,
      );
    } else if (_isOffsetMode && _showRackResults) {
      final label = rack.isRollingMode ? 'Rolling Offset' : 'Offset';
      rack.addBendSegment(
        label,
        rack.bendAngle * 2,
        rack.isFullStick ? 120.0 : rack.overallLength,
        commitId: _resultCommitId,
        savedResult: _captureHubResult(),
        multiplier: _rackPipeCount,
      );
    }

    _lastResultCommitted = true;
    _triggerHubFlash();
  }

  void _advanceToNextBend() {
    _hideKeypad();
    FocusScope.of(context).unfocus();

    if (_canAdvanceToNextBend) {
      _commitVisibleResultIfNeeded();
      _goToChooseNextBend();
    }
  }

  void _goBackOneStep() {
    _hideKeypad();
    FocusScope.of(context).unfocus();

    if (_isProjectHubVisible) {
      setState(() => _isProjectHubVisible = false);
      return;
    }

    if ((widget.startInOffsetMode || widget.startInRollingOffsetMode) &&
        _isResultVisible &&
        !_lastResultCommitted) {
      Navigator.pop(context);
      return;
    }

    if (_isParallel90sMode && _parallel90ShowResults &&
        _latestParallel90WasStartingPoint) {
      setState(() {
        _reviewingStartingPoint = true;

        _isParallel90sMode = false;
        _parallel90ShowResults = false;
        _showRackSetupStart = true;
        _isRackBendTypeExpanded = true;
        _choosingNextBend = false;
      });
      return;
    }
    if (_isParallel90sMode && _parallel90ShowResults) {
      setState(() {
        _viewingLatestResult = false;
        _parallel90ShowResults = false;
        _showParallel90Measurements = true;
      });
      return;
    }

    if (_isOffsetMode && _showRackResults) {
      setState(() {
        _viewingLatestResult = false;
        _showRackResults = false;
        _showOffsetInputs = false;
        _showOffsetGeometryResults = true;
        _showOffsetBendingMethod = false;
      });
      return;
    }

    if (_isKick90sMode && _showKickTypeSelector) {
      setState(() {
        _viewingLatestResult = false;
        _showKickTypeSelector = false;
        _showKickMeasurements = true;
        _showKickBendingMethodCard = true;
        _kickBendingMethodConfirmed = true;
      });
      return;
    }

    if (_isKick90sMode) {
      if (_showKickBendingMethodCard) {
        setState(() {
          _showKickBendingMethodCard = false;
          _kickTypeConfirmed = true;
          _kickMeasurementsExpanded = true;
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
      if (_kickHandoffActive && _lastResultView == null) {
        Navigator.pop(context);
        return;
      }
      _returnToBendTypeScreen();
      return;
    }

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
          _showOffsetInputs = true;
          _offsetMeasurementsExpanded = true;
        });
        return;
      }
      _returnToBendTypeScreen();
      return;
    }

    if (_isParallel90sMode) {
      _returnToBendTypeScreen();
      return;
    }

    if (_choosingNextBend && _lastResultView != null) {
      _openLatestResult();
      return;
    }
    if (_choosingNextBend && _savedStartingPoint != null) {
      _openStartingPointForm();
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(0, duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
      return;
    }

    if (_isRackBendTypeExpanded && _skipStartingPoint && rack.runSequence.isEmpty) {
      setState(() => _skipStartingPoint = false);
      return;
    }
    if (_isRackBendTypeExpanded) {
      _returnToBenderScreen();
      return;
    }

    if (_isRackBenderExpanded) {
      setState(() {
        _isRackBenderExpanded = false;
        _isRackSetupExpanded = true;
      });
      return;
    }

    Navigator.maybePop(context);
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
        _expandedHubIds.clear(); // COLLAPSE ALL BY DEFAULT
        _showHubGuidance = true;
      }
      _hubGuidanceTimer?.cancel(); // REMOVE AUTO-HIDE TIMER
    });
  }

  Widget _buildProjectHub() {
    final summary = _branches?.materials ?? rack.projectMaterialSummary;
    final totalSticks = summary.sticks;
    final totalPipeFeet = summary.footage;
    final totalDeg = rack.totalRunDegrees;
    final bool warning = totalDeg > 360;

    return Positioned.fill(
      child: Stack(
        children: [
          // FULL SCREEN DARKNESS: Completely hides previous screen
          GestureDetector(
            onTap: () {
              _hideKeypad();
              setState(() => _isProjectHubVisible = false);
            },
            child: Container(color: kBlack),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 110,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -7) {
                  _hideKeypad();
                  setState(() => _isProjectHubVisible = false);
                }
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFC0C0C0), width: 2.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(200),
                          blurRadius: 15,
                          spreadRadius: 2),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // TOP DASHBOARD: Machined Metal Look
                      _activeRackSelector(),
                      if (_branches != null) const Text('Materials: all racks · Stages/supports: active rack',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _materialMiniItem('Sticks', '$totalSticks'),
                                  _materialMiniItem(
                                      'Couplings', '${summary.couplings}'),
                                  _materialMiniItem('Stock Footage',
                                      '${totalPipeFeet.toInt()} ft'),
                                  _materialMiniItem(
                                      'Run Dist',
                                      RackState.feetInchFmt(
                                          rack.totalRunLength)),
                                  _materialMiniItem(
                                      'Degrees', '${totalDeg.toInt()}°',
                                      valueColor: warning ? kRed : kLight),
                                ],
                              ),
                            ),
                            Container(
                                width: 1, height: 30, color: Colors.white10),
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: kRed, size: 20),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    title: Text(_branches == null ? 'Clear Hub?' : 'Clear branch additions?',
                                        style: const TextStyle(color: Colors.white)),
                                    content: Text(_branches == null
                                        ? 'This will permanently delete all segments in your current rack run.'
                                        : 'Remove additions on this rack after its split. Shared upstream stages and other racks stay unchanged.',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('CANCEL',
                                              style: TextStyle(
                                                  color: Colors.white54))),
                                      TextButton(
                                          onPressed: () {
                                            rack.clearRunSequence();
                                            Navigator.pop(context);
                                          },
                                          child: const Text('CLEAR ALL',
                                              style: TextStyle(
                                                  color: kRed,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1.5, color: const Color(0xFFC0C0C0)),

                      if (warning)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: kRed,
                          child: const Text('⚠️ NEC 360° LIMIT EXCEEDED',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: kLight,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                        ),

                      Expanded(
                        child: ListView(
                          controller: _hubScrollCtl,
                          padding: const EdgeInsets.all(12),
                          children: [
                            ...() {
                              final List<Widget> items = [];
                              for (int i = 0;
                                  i < rack.runSequence.length;
                                  i++) {
                                items.add(_buildSegmentCard(
                                    i + 1, rack.runSequence[i],
                                    index: i));
                              }
                              return items;
                            }(),
                            if (_isAddingStraightSegment)
                              _buildStraightPipeAdder(
                                  isHub: true),
                            if (rack.supportPositions.any((p) => p > rack.supportRunLength)) ...[
                              const SizedBox(height: 12),
                              const Text('PLANNED SUPPORTS BEYOND CONDUIT',
                                  style: TextStyle(color: kGreen, fontWeight: FontWeight.w700)),
                              for (var i = 0; i < rack.supportPositions.length; i++)
                                if (rack.supportPositions[i] > rack.supportRunLength)
                                  _supportListRow(i + 1, rack.supportPositions[i], index: i),
                            ],
                            if (_activeController == supportPosCtl &&
                                _editingSupportIndex == null)
                              _buildSupportAdder(),
                            if (rack.runSequence.isEmpty &&
                                !_isAddingStraightSegment)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 40.0),
                                  child: Text(
                                    'No segments added. Start below.',
                                    style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ADD NEW SUPPORT',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      // Opening or canceling the editor must not
                                      // insert a support before the gap is entered.
                                      supportPosCtl.text = rack.supportPositions.isEmpty ? '' : '120';
                                      _insertSupportAfter = null;
                                      _editingSupportIndex = null;
                                      _clearOnNextInput = true;
                                    });
                                    _showKeypad(supportPosCtl);

                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      final entryContext = _supportAdderKey.currentContext;
                                      if (entryContext != null) {
                                        Scrollable.ensureVisible(entryContext,
                                            alignment: 0.1,
                                            duration: const Duration(milliseconds: 250),
                                            curve: Curves.easeOut);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: kGreen.withAlpha(40),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: kGreen.withAlpha(100)),
                                    ),
                                    child: const Text('+ SUPPORT',
                                        style: TextStyle(
                                            color: kGreen,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ],
                            ),
                            if (_isKeypadVisible) const SizedBox(height: 450),
                          ],
                        ),
                      ),

                      // BOTTOM ACTION CONSOLE
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                          ),
                          border: Border(
                              top: BorderSide(
                                  color: Color(0xFFC0C0C0), width: 1.5)),
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
                                    height: 52,
                                    primary: true,
                                    onTap: () {
                                      setState(() {
                                        _isAddingStraightSegment = true;
                                        _editingSegmentIndex = null;
                                        straightRunLengthCtl.clear();
                                      });
                                      _showKeypad(straightRunLengthCtl);
                                    },
                                    child: const Text('+ STRAIGHT',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _BeveledButton(
                                    height: 52,
                                    primary: true,
                                    onTap: _goToChooseNextBend,
                                    child: const Text('+ BEND',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _BeveledButton(
                                    height: 52,
                                    primary: true,
                                    onTap: () {
                                      rack.addFittingSegment('Pull Box', 0.0);
                                      _triggerHubFlash();
                                      _goToChooseNextBend();
                                    },
                                    child: const Text('+ PULL POINT',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
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
            ),
          ),

          // HUD-SPECIFIC INFO BAR (BRIGHT & ON TOP)
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: _RackInfoBar(
              isOffsetMode: false,
              isRollingMode: false,
              needsDirection: false,
              showResults: true,
              isHubVisible: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAdder() {
    const accent = kGreen;
    final String currentVal = supportPosCtl.text;

    return Container(
      key: _supportAdderKey,
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
              Expanded(
                child: Text(
                  _insertSupportAfter == null ? 'NEXT SUPPORT' : 'INSERT SUPPORT',
                  style: const TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () { _insertSupportAfter = null; _hideKeypad(); },
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
                          _addInchIfMissing(currentVal),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900),
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
                  _saveStateFromActiveController();
                  _hideKeypad();
                  _triggerHubFlash();
                },
                child: const Text('ADD',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _insertSupportAfter != null
                ? 'Distance after selected support at ${RackState.inchFmt(_insertSupportAfter!)} from run start.'
                : rack.supportPositions.isEmpty
                ? 'Distance from run start.'
                : 'Distance from previous support.',
            style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 11,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _materialMiniItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? kLight,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildStraightPipeAdder({bool isHub = false}) {
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1),
                    ),
                    Text(
                      '10ft (120") Sticks',
                      style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (isHub)
                IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () =>
                      setState(() => _isAddingStraightSegment = false),
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
                    width: 38,
                    height: 38,
                    onTap: () {
                      setState(() {
                        _straightSticksCount =
                            math.max(1, _straightSticksCount - 1);
                        straightRunLengthCtl.text =
                            (_straightSticksCount * 120).toString();
                      });
                    },
                    child: const Text('-',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    width: 36,
                    alignment: Alignment.center,
                    child: Text('$_straightSticksCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900)),
                  ),
                  _BeveledButton(
                    width: 38,
                    height: 38,
                    onTap: () {
                      setState(() {
                        _straightSticksCount++;
                        straightRunLengthCtl.text =
                            (_straightSticksCount * 120).toString();
                      });
                    },
                    child: const Text('+',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
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

                  if (!length.isFinite || length <= 0) return;
                  rack.addStraightSegment(length,
                      multiplier: _rackPipeCount);
                  _triggerHubFlash();

                  setState(() {
                    _isAddingStraightSegment = false;
                    _straightSticksCount = 1;
                    straightRunLengthCtl.clear();
                    _hideKeypad();
                  });
                },
                child: const Text('ADD',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Custom Length Input (Matches ADD button size and sits below it)
          Row(
            children: [
              const Expanded(child: Text('Custom segment length',
                  style: TextStyle(color: kLight, fontSize: 14,
                      fontWeight: FontWeight.w600))),
              GestureDetector(
                onTap: () {
                  if (straightRunLengthCtl.text.isEmpty ||
                      straightRunLengthCtl.text == '0') {
                    straightRunLengthCtl.text =
                        (_straightSticksCount * 120).toString();
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
                      color: kGreen,
                      width:
                          _activeController == straightRunLengthCtl ? 2.0 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      straightRunLengthCtl.text.isEmpty
                          ? '${_straightSticksCount * 120}"'
                          : _addInchIfMissing(straightRunLengthCtl.text),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
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
      case RunSegmentType.straight:
        accent = Colors.blueAccent;
        icon = Icons.linear_scale;
        break;
      case RunSegmentType.bend:
        accent = kRed;
        icon = Icons.architecture;
        break;
      case RunSegmentType.fitting:
        accent = kGreen;
        icon = Icons.crop_square;
        break;
    }

    final bool isEditing = _editingSegmentIndex == index;
    final bool isExpanded = _expandedHubIds.contains(seg.id);

    return Column(
      key: ObjectKey(seg.id),
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedHubIds.remove(seg.id);
              } else {
                _expandedHubIds.add(seg.id);
              }
            });
          },
          child: Container(
            margin: EdgeInsets.only(bottom: isExpanded ? 0 : 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(10))
                  : BorderRadius.circular(10),
              border: Border.all(
                  color: isEditing ? accent : accent.withAlpha(80),
                  width: isEditing ? 2.0 : 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: accent.withAlpha(40), shape: BoxShape.circle),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STAGE $num',
                          style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                      if (rack.isSharedStage(seg.id))
                        const Text('Shared before split · View only', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      if (isEditing && seg.type == RunSegmentType.straight)
                        Text(_addInchIfMissing(straightRunLengthCtl.text),
                            style: const TextStyle(
                                color: kLight,
                                fontSize: 17,
                                fontWeight: FontWeight.w900))
                      else
                        Text(seg.label,
                            style: const TextStyle(
                                color: kLight,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                if (seg.degrees > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text('${seg.degrees.toInt()}°',
                        style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ),
                Theme(
                  data: Theme.of(context)
                      .copyWith(cardColor: const Color(0xFF222222)),
                  child: PopupMenuButton<String>(
                    enabled: !rack.isSharedStage(seg.id),
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onSelected: (val) {
                      if (val == 'delete') {
                        final currentIndex = rack.segmentIndex(seg.id);
                        if (currentIndex != null) _confirmStageLayoutChange(seg.id);
                      } else if (val == 'edit') {
                        if (seg.type == RunSegmentType.straight) {
                          setState(() {
                            _editingSegmentId = seg.id;
                            _isAddingStraightSegment = false;
                            straightRunLengthCtl.text =
                                RackState.inchFmt(seg.length)
                                    .replaceAll('"', '');
                          });
                          _showKeypad(straightRunLengthCtl);
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (seg.type == RunSegmentType.straight)
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit Length')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Remove Step',
                              style: TextStyle(color: kRed))),
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
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (seg.type == RunSegmentType.straight) ...[
                  _hubDetailRow(
                      'Total Length Added', RackState.inchFmt(seg.length)),
                ] else if (seg.type == RunSegmentType.bend) ...[
                  if (seg.savedResult != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        alignment: Alignment.centerLeft,
                        child: _BeveledButton(
                          height: 40,
                          onTap: () => _openSavedResult(seg.savedResult!),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility, color: kLight, size: 20),
                                SizedBox(width: 8),
                                Text('VIEW RESULTS',
                                    style: TextStyle(color: kLight,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('Saved results unavailable for this earlier stage.', style: TextStyle(color: Colors.white54)),
                  if (seg.savedResult != null && seg.savedResult!.settings['view'] == 'offset') ...[
                    _hubDetailRow('Offset height', RackState.inchFmt(seg.savedResult!.inputs['Offset height']!)),
                    _hubDetailRow('Angle', '${seg.savedResult!.inputs['Bend angle']}°'),
                  ],
                  if (seg.distanceAfter90 != null)
                    _hubDetailRow('Distance from Back of 90 (OUT)', RackState.inchFmt(seg.distanceAfter90!)),
                  if (seg.has90Corner) ...[
                    const SizedBox(height: 12),
                    _CornerDiagram(
                      segmentIndex: index,
                      inOffset: rack.hasCornerSupport(seg.id, incoming: true) ? seg.inSupportOffset : null,
                      outOffset: rack.hasCornerSupport(seg.id, incoming: false) ? seg.outSupportOffset : null,
                      isLeftTurn:
                          seg.direction == 'left' || seg.direction == 'down',

                    ),
                  ],
                ],

                // Professional Overhang Details & SUPPORTS
                ...() {
                  final double start = rack.runSequence
                      .sublist(0, index)
                      .fold(0.0, (sum, s) => sum + s.supportLength);
                  final double end = start + seg.supportLength;

                  final supportsInSegment = rack.supportPositions.where((p) {
                    if (index == 0) return p >= 0 && p <= end;
                    return p > start && p <= end;
                  }).toList();

                  final double lastSup = supportsInSegment.isEmpty
                      ? (index == 0 ? 0.0 : start)
                      : supportsInSegment.last;

                  final double overhang = end - lastSup;
                  final Color overhangColor = overhang < 0
                      ? kRed
                      : (overhang < 3.0 ? Colors.amber : kLight);

                  final List<Widget> segmentItems = [];

                  segmentItems
                      .add(const Divider(color: Colors.white10, height: 12));
                  if (seg.type == RunSegmentType.bend && seg.distanceBefore90 != null) {
                    segmentItems.add(_hubDetailRow(
                        'Distance to Back of 90 (IN)', RackState.inchFmt(seg.distanceBefore90!)));
                  }
                  if (supportsInSegment.isNotEmpty) {
                    segmentItems.add(const SizedBox(height: 12));
                    segmentItems.add(const Text('SUPPORTS',
                        style: TextStyle(
                            color: kGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1)));
                    segmentItems.add(const SizedBox(height: 6));

                    for (var pos in supportsInSegment) {
                      final supIdx = rack.supportPositions.indexOf(pos);
                      segmentItems.add(_supportListRow(supIdx + 1, pos,
                          index: supIdx, parentSegmentIndex: index));
                    }
                  }

                  segmentItems.add(
                    _hubDetailRow(
                      supportsInSegment.isEmpty
                          ? 'Stage length (no supports)'
                          : 'Pipe beyond last support',
                      RackState.inchFmt(overhang),
                      valueColor: overhangColor,
                    ),
                  );

                  if (overhang < 0) {
                    segmentItems.add(
                      const Text(
                        '⚠️ ADJ SUPPORT: Pipe too short to reach!',
                        style: TextStyle(
                            color: kRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w900),
                      ),
                    );
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

  Widget _hubDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? kLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _supportListRow(int num, double pos,
      {required int index, int? parentSegmentIndex}) {
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
        cleanTitle = label.contains('Before') ? 'Before turn (IN)' : 'After turn (OUT)';
        if (parts.length > 2) {
          distText = parts[2]; // Additional reference for the incoming support
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

    if (label?.contains('Turn') ?? false) {
      final incoming = label!.contains('Before');
      if (incoming && parentSegmentIndex == 0) {
        distText = '${RackState.inchFmt(pos)} from starting point';
      }
      final reference = incoming
          ? 'Support → back of 90: $mainValueDisp'
          : 'Back of 90 → support: $mainValueDisp';
      distText = incoming && distText.isNotEmpty
          ? '$reference\n$distText'
          : reference;
    }
    if (cleanTitle == 'Support') {
      cleanTitle = 'Next Support';
      mainValueDisp = RackState.inchFmt(pos - (index == 0 ? 0 : rack.supportPositions[index - 1]));
      distText = '$mainValueDisp from previous support';
    }

    if (cleanTitle == 'Horizontal (off Wall)') {
      distText = '$mainValueDisp from wall';
    } else if (cleanTitle == 'Vertical (from Box)' ||
        cleanTitle == 'Support (from Box)') {
      if (rack.hubStartsAtBox) {
        distText = '$mainValueDisp from box';
      } else {
        // Also correct the old automatic label on an existing skipped-start run.
        cleanTitle = 'Support (from Run Start)';
        mainValueDisp = RackState.inchFmt(pos);
        distText = '$mainValueDisp from run start';
      }
    } else if (cleanTitle == 'Support (from Run Start)') {
      mainValueDisp = RackState.inchFmt(pos);
      distText = '$mainValueDisp from run start';
    } else if (distText.isEmpty) {
      distText = (index == 0)
          ? (pos == 36.0 && rack.hubStartsAtBox
              ? '$mainValueDisp from box'
              : '$mainValueDisp from run start')
          : '$mainValueDisp from previous support';
    }

    if (parentSegmentIndex != null && !(label?.contains('Turn') ?? false)) {
      final start = rack.runSequence.take(parentSegmentIndex)
          .fold<double>(0, (sum, s) => sum + s.supportLength);
      distText += '\n${RackState.inchFmt(pos - start)} from stage start';
    } else if (pos > rack.supportRunLength) {
      distText += '\n${RackState.inchFmt(pos - rack.supportRunLength)} beyond conduit end';
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (rack.isSharedSupport(pos)) return;
        if (_activeController == supportPosCtl && _editingSupportIndex != null) {
          _saveStateFromActiveController();
          _hideKeypad();
          return;
        }
        setState(() {
          _insertSupportAfter = null;
          _editingSupportIndex = index;
          _editingSupportParentSegmentIndex = parentSegmentIndex;
          _editingSupportIsIncoming = label?.contains('Before') ?? false;
          supportPosCtl.text = mainValueDisp.replaceAll('"', '');
          _clearOnNextInput = true;
        });
        _showKeypad(supportPosCtl);
        // Preserve the selected measurement until the first actual key press.
        supportPosCtl.text = mainValueDisp.replaceAll('"', '');
        _clearOnNextInput = true;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
                  Text(cleanTitle,
                      style: TextStyle(
                          color: isSelected ? kGreen : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text(distText,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
                  if (rack.isSharedSupport(pos)) const Text('Shared before split',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isSelected ? kGreen : Colors.white24, width: 1.2),
              ),
              child: Text(
                  isSelected
                      ? (supportPosCtl.text.isEmpty
                          ? '0"'
                          : (supportPosCtl.text.contains('"')
                              ? supportPosCtl.text
                              : '${supportPosCtl.text}"'))
                      : mainValueDisp,
                  style: TextStyle(
                      color: isSelected ? kLight : kGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 6),
            Theme(
              data: Theme.of(context)
                  .copyWith(cardColor: const Color(0xFF222222)),
              child: PopupMenuButton<String>(
                enabled: !rack.isSharedSupport(pos),
                icon: const Icon(Icons.more_vert,
                    color: Colors.white24, size: 20),
                onSelected: (val) {
                  if (val == 'insert') {
                    _hideKeypad();
                    setState(() {
                      _editingSupportIndex = null;
                      _editingSupportParentSegmentIndex = null;
                      _activeController = supportPosCtl;
                      _insertSupportAfter = pos;
                      supportPosCtl.text = '';
                      _isKeypadVisible = true;
                      _clearOnNextInput = true;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final target = _supportAdderKey.currentContext;
                      if (mounted && target != null) Scrollable.ensureVisible(target,
                        duration: const Duration(milliseconds: 250));
                    });
                  } else if (val == 'delete') {
                    // Deleting changes support indices; discard any open editor.
                    _hideKeypad();
                    setState(() {
                      _editingSupportIndex = null;
                      _editingSupportParentSegmentIndex = null;
                      _editingSupportIsIncoming = false;
                      supportPosCtl.clear();
                    });
                    rack.removeSupport(index);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'insert', child: Text('Insert after this support')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Remove Support',
                          style: TextStyle(color: kRed))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.branches != null || widget.savedResult != null) return _buildScreen(context);
    final workspace = _ownedBranches;
    return IndexedStack(index: workspace?.active ?? 0, children: [
      TickerMode(enabled: (workspace?.active ?? 0) == 0, child: _buildScreen(context)),
      if (workspace != null) for (int i = 1; i < workspace.branches.length; i++)
        ChangeNotifierProvider<RackState>(key: ObjectKey(workspace.branches[i]),
          create: (_) => workspace.branches[i].rack,
          child: TickerMode(enabled: workspace.active == i,
            child: RackBuilderScreen(branches: workspace, branch: workspace.branches[i],
              onBranchSelected: (index) => setState(() => workspace.active = index)))),
    ]);
  }

  Widget _buildScreen(BuildContext context) {
    if (widget.savedResult != null) return _buildSavedResults(context);
    final mq = MediaQuery.of(context);
    final bottomSafe = mq.padding.bottom;

    final rack = Provider.of<RackState>(context);

    // Safety Guard: If list is empty, don't build result-dependent widgets yet
    if (rack.allConduits.isEmpty) {
      return const Scaffold(
          backgroundColor: kBlack,
          body: Center(child: CircularProgressIndicator()));
    }

    final selectedPipeIndexInSet = (rack.allConduits.isNotEmpty &&
            rack.selectedPipeIndex < rack.allConduits.length)
        ? (rack.selectedPipeIndex % 3)
        : 0;
    final selectedPipeIndex = rack.selectedPipeIndex;

    final conduit = (rack.allConduits.isNotEmpty &&
            selectedPipeIndex < rack.allConduits.length)
        ? rack.allConduits[selectedPipeIndex]
        : rack.current;

    final markA = RackState.inchFmt(conduit.markA);
    final markB = RackState.inchFmt(conduit.markB);
    final cut = RackState.inchFmt(conduit.ol);

    final labels = List.generate(3, (i) => (_currentSet * 3) + i + 1);
    final bool parallel90Complete = _isParallel90sMode &&
        stubCtl.text.trim().isNotEmpty &&
        legCtl.text.trim().isNotEmpty;
    const spacing = 2.0;

    // --- STICKY FOOTER LOGIC ---
    Widget? stickyFooter;
    if (_showRackSetupStart && !_isOffsetMode) {
      stickyFooter = _RackSetupGuideBar(
        text: _isProjectHubVisible
            ? 'PROJECT HUB: Review your construction stages. Expand a stage to view its supports and geometry. Tap any measurement to edit.'
            : _rackSetupInfoText,
        isHubVisible: _isProjectHubVisible,
      );
    } else if (!_showRackSetupStart &&
        _isParallel90sMode &&
        !_parallel90ShowResults) {
      stickyFooter = _RackInfoBar(
        isOffsetMode: false,
        isRollingMode: false,
        needsDirection: false,
        showResults: false,
        isFromBox: rack.isFromBox,
      );
    } else if (_isParallel90sMode && _parallel90ShowResults) {
      if (_showHubGuidance || rack.isFromBox || _isVertical90) {
        stickyFooter = _RackInfoBar(
          isVertical90: _isVertical90,
          isOffsetMode: false,
          isRollingMode: false,
          needsDirection: false,
          showResults: true,
          isFromBox: rack.isFromBox,
          isHubVisible: false,
        );
      }
    } else if (_isOffsetMode && !_showRackResults) {
      stickyFooter = _RackInfoBar(
        isOffsetMode: _isOffsetMode,
        isRollingMode: rack.isRollingMode,
        needsDirection: _rollingNeedsDirection,
        showResults: false,
        isBendingMethod: _showOffsetBendingMethod,
        isGeometry: _showOffsetGeometryResults,
        isFromBox: rack.isFromBox,
        isHubVisible: _isProjectHubVisible,
      );
    } else if (_isOffsetMode && _showRackResults) {
      if (_showHubGuidance || _isStraightOffset) {
        stickyFooter = _RackInfoBar(
          isStraightOffset: _isStraightOffset,
          isOffsetMode: _isOffsetMode,
          isRollingMode: rack.isRollingMode,
          needsDirection: false,
          showResults: true,
          isFromBox: rack.isFromBox,
          isHubVisible: _isProjectHubVisible,
        );
      }
    } else if (_isKick90sMode && _showKickTypeSelector) {
      stickyFooter = _RackInfoBar(
        isOffsetMode: false,
        isRollingMode: false,
        needsDirection: false,
        showResults: true,
        isFromBox: false,
        isKick90Results: true,
        showKickLandscapeHint: _selectedKickStyle == 'Parallel',
      );
    }

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
                  MaterialPageRoute(
                      builder: (context) => const MainMenuScreen()),
                  (route) => false,
                );
              },
            ),
            if (_canAdvanceToNextBend) ...[
              SizedBox(
                width: 54,
                child: _MiniArrowButton(
                  label: '⬅',
                  key: const ValueKey('rack-next-bend'),
                  onTap: _advanceToNextBend,
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (_canGoBackOneStep)
              SizedBox(
                width: 54,
                child: _MiniArrowButton(
                  label: '➡',
                  key: const ValueKey('rack-back'),
                  onTap: _goBackOneStep,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: false,
        elevation: 0.5,
        title: Transform.translate(
          offset: const Offset(-12, 0),
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
                            (_hubRecentlyUpdated ? Colors.blueAccent : kLight)
                                .withAlpha(0),
                            (_hubRecentlyUpdated ? Colors.blueAccent : kLight)
                                .withAlpha((255 *
                                        (0.2 +
                                            (0.7 *
                                                (0.5 +
                                                    0.5 *
                                                        math.sin(_infoAnimCtrl
                                                                .value *
                                                            2 *
                                                            math.pi)))))
                                    .toInt()),
                            (_hubRecentlyUpdated ? Colors.blueAccent : kLight)
                                .withAlpha(0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(rect);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _hubRecentlyUpdated
                                    ? Colors.blueAccent
                                    : kLight,
                                width: 2.0)),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                icon: Text('H',
                    style: TextStyle(
                        color: _hubRecentlyUpdated ? Colors.blueAccent : kLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
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
                              kLight.withValues(
                                  alpha: 0.2 +
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
      body: SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollCtl,
                        padding:
                            EdgeInsets.fromLTRB(2, spacing, 2, bottomSafe + 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_showRackSetupStart && !_isOffsetMode) ...[
                              _buildRackSetupStartScreen(),
                            ] else ...[
                              if (_isOffsetMode && !_showRackResults)
                                Column(
                                  children: [
                                    if (!_showOffsetBendingMethod &&
                                        !_showOffsetGeometryResults) ...[
                                      if (rack.calcMode ==
                                              RackCalcMode.rollingOffset ||
                                          rack.calcMode ==
                                              RackCalcMode
                                                  .parallelRollingOffset)
                                        _RollingInputCard(
                                          distanceCtl: rollingDistanceCtl,
                                          verticalCtl: rollingVerticalCtl,
                                          horizontalCtl: rollingHorizontalCtl,
                                          overallCtl: rollingOverallCtl,
                                          angleCtl: rollingAngleCtl,
                                          onDistanceTap: () =>
                                              _showKeypad(rollingDistanceCtl),
                                          onVerticalTap: () =>
                                              _showKeypad(rollingVerticalCtl),
                                          onHorizontalTap: () =>
                                              _showKeypad(rollingHorizontalCtl),
                                          onOverallTap: () =>
                                              _showKeypad(rollingOverallCtl),
                                          onAngleTap: () =>
                                              _showKeypad(rollingAngleCtl),
                                          activeController: _activeController,
                                          isFullStick: rack.isFullStick,
                                          onFullStickToggle: (val) =>
                                              rack.setFullStick(val),
                                          isExpanded:
                                              _offsetMeasurementsExpanded,
                                          onHeaderTap: () => setState(() =>
                                              _offsetMeasurementsExpanded =
                                                  !_offsetMeasurementsExpanded),
                                          spacingValue: _rackSpacingIsCenterToCenter
                                              ? RackState.inchFmt(math.max(
                                                  0,
                                                  RackState.parseInches(
                                                          runC2C.text) -
                                                      _rackPipeOd(
                                                          _rackDefaultPipeSize)))
                                              : RackState.inchFmt(
                                                  RackState.parseInches(
                                                      runC2C.text)),
                                          c2cValue: _rackSpacingIsCenterToCenter
                                              ? RackState.inchFmt(
                                                  RackState.parseInches(
                                                      runC2C.text))
                                              : RackState.inchFmt((_rackPipeSizes
                                                          .isNotEmpty
                                                      ? _rackPipeOd(_rackPipeSizes.first) /
                                                          2
                                                      : 0.0) +
                                                  RackState.parseInches(
                                                      runC2C.text) +
                                                  (_rackPipeSizes.length > 1
                                                      ? _rackPipeOd(_rackPipeSizes[1]) /
                                                          2
                                                      : (_rackPipeSizes.isNotEmpty
                                                          ? _rackPipeOd(
                                                                  _rackPipeSizes
                                                                      .first) /
                                                              2
                                                          : 0.0))),
                                        )
                                      else
                                        _OffsetInputCard(
                                          heightCtl: offsetHeightCtl,
                                          angleCtl: offsetAngleCtl,
                                          distanceCtl: offsetDistanceCtl,
                                          overallCtl: offsetOverallCtl,
                                          onHeightTap: () =>
                                              _showKeypad(offsetHeightCtl),
                                          onAngleTap: () =>
                                              _showKeypad(offsetAngleCtl),
                                          onDistanceTap: () =>
                                              _showKeypad(offsetDistanceCtl),
                                          onOverallTap: () =>
                                              _showKeypad(offsetOverallCtl),
                                          activeController: _activeController,
                                          isFullStick: rack.isFullStick,
                                          onFullStickToggle: (val) =>
                                              rack.setFullStick(val),
                                          isExpanded:
                                              _offsetMeasurementsExpanded,
                                          onHeaderTap: () => setState(() =>
                                              _offsetMeasurementsExpanded =
                                                  !_offsetMeasurementsExpanded),
                                          spacingValue: _rackSpacingIsCenterToCenter
                                              ? RackState.inchFmt(math.max(
                                                  0,
                                                  RackState.parseInches(
                                                          runC2C.text) -
                                                      _rackPipeOd(
                                                          _rackDefaultPipeSize)))
                                              : RackState.inchFmt(
                                                  RackState.parseInches(
                                                      runC2C.text)),
                                          c2cValue: _rackSpacingIsCenterToCenter
                                              ? RackState.inchFmt(
                                                  RackState.parseInches(
                                                      runC2C.text))
                                              : RackState.inchFmt((_rackPipeSizes
                                                          .isNotEmpty
                                                      ? _rackPipeOd(_rackPipeSizes.first) /
                                                          2
                                                      : 0.0) +
                                                  RackState.parseInches(
                                                      runC2C.text) +
                                                  (_rackPipeSizes.length > 1
                                                      ? _rackPipeOd(_rackPipeSizes[1]) /
                                                          2
                                                      : (_rackPipeSizes.isNotEmpty
                                                          ? _rackPipeOd(
                                                                  _rackPipeSizes
                                                                      .first) /
                                                              2
                                                          : 0.0))),
                                        ),
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
                                      const SizedBox(height: 8),
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
                                          'CONTINUE',
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
                                          if (_showRackResults) return;
                                          final label = rack.isRollingMode
                                              ? 'Rolling Offset'
                                              : 'Offset';
                                          rack.addBendSegment(
                                              label,
                                              rack.bendAngle * 2,
                                              rack.isFullStick
                                                  ? 120.0
                                                  : rack.overallLength,
                                              commitId: _resultCommitId,
        savedResult: _captureHubResult(),
                                              multiplier: _rackPipeCount);
                                          _triggerHubFlash();
                                          setState(() {
                                            _showRackResults = true;
                                            _showOffsetInputs = false;
                                            _showRackSetupStart = false;
                                            _lastResultView = rack.isRollingMode
                                                ? _RackResultView.rollingOffset
                                                : _RackResultView.offset;
                                            _lastResultCommitted = true;
                                            _viewingLatestResult = false;
                                            _showOffsetBendingMethod = false;
                                            _showOffsetGeometryResults = false;
                                            _hideKeypad();
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
                                          if (_kickHandoffActive && widget.initialKick?.clearanceWarning != null)
                                            Padding(padding: const EdgeInsets.all(8), child: Text('Original standalone bend: ${widget.initialKick!.clearanceWarning}', style: const TextStyle(color: Colors.amber))),
                                          _subHeader(
                                            label: 'Kick Type',
                                            isExpanded: _showKickTypeCard,
                                            onToggle: () {
                                              setState(() {
                                                _showKickTypeCard =
                                                    !_showKickTypeCard;
                                                if (_showKickTypeCard) {
                                                  _kickTypeConfirmed = false;
                                                  _showKickBendingMethodCard =
                                                      false;
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
                                              isExpanded:
                                                  _kickMeasurementsExpanded,
                                              onHeaderTap: () {
                                                setState(() {
                                                  _kickMeasurementsExpanded =
                                                      !_kickMeasurementsExpanded;
                                                });
                                              },
                                              onContinue: () =>
                                                  _continueKickMeasurements(),
                                              onContinueAnyway: () =>
                                                  _continueKickMeasurements(
                                                      allowOverlength: true),
                                              stubCtl: kickStubCtl,
                                              kickHeightCtl: kickHeightCtl,
                                              kickAngleCtl: kickAngleCtl,
                                              kickMatchBendCtl:
                                                  kickMatchBendCtl,
                                              legCtl: kickLegCtl,
                                              spacingCtl: runC2C,
                                              activeController:
                                                  _activeController,
                                              kickMarkMethod:
                                                  rack.bendingMethod,
                                              usesMatchBendInput:
                                                  _kickUsesMatchBendInput,
                                              isCenterToCenter:
                                                  _rackSpacingIsCenterToCenter,
                                              onStubTap: () =>
                                                  _showKeypad(kickStubCtl),
                                              onKickHeightTap: () =>
                                                  _showKeypad(kickHeightCtl),
                                              onKickAngleTap: () =>
                                                  _showKeypad(kickAngleCtl),
                                              onKickMatchBendTap: () =>
                                                  _showKeypad(kickMatchBendCtl),
                                              onUseNotch: () {
                                                setState(() {
                                                  rack.setBendingMethod(
                                                      bending_data
                                                          .BendingMethod.notch);
                                                });
                                              },
                                              onUseCenterline: () {
                                                setState(() {
                                                  rack.setBendingMethod(
                                                      bending_data.BendingMethod
                                                          .centerline);
                                                });
                                              },
                                              onLegTap: () =>
                                                  _showKeypad(kickLegCtl),
                                              onUseMaxStub: _useMaximumKickStub,
                                              longestCutLength:
                                                  _kickInputsReadyForLengthCheck
                                                      ? _kickLongestCutLength
                                                      : 0.0,
                                              longestPipeNumber:
                                                  _kickInputsReadyForLengthCheck
                                                      ? _kickLongestPipeNumber
                                                      : 0,
                                              maxStubCanFit:
                                                  _kickInputsReadyForLengthCheck &&
                                                      RackState.parseInches(
                                                                  kickStubCtl
                                                                      .text) +
                                                              (120.0 -
                                                                  _kickLongestCutLength) >=
                                                          (_selectedRackBender
                                                                  ?.deduct ??
                                                              rack.benderTakeup),
                                              onSpacingTap: () =>
                                                  _showKeypad(runC2C),
                                              onSpaceBetweenTap: () {
                                                setState(() {
                                                  _rackSpacingIsCenterToCenter =
                                                      false;
                                                });
                                                _sendPipeProgressionOffsetsToRackState();
                                              },
                                              onCenterToCenterTap: () {
                                                setState(() {
                                                  _rackSpacingIsCenterToCenter =
                                                      true;
                                                });
                                                _sendPipeProgressionOffsetsToRackState();
                                              },
                                              isFromBox: rack.isFromBox,
                                              distanceFromBoxCtl:
                                                  distanceFromBoxCtl,
                                              onDistanceFromBoxTap: () =>
                                                  _showKeypad(
                                                      distanceFromBoxCtl),
                                              measureToTop: rack.measureToTop,
                                              onToggleStrut: () => setState(
                                                  () => rack.setMeasureToTop(
                                                      !rack.measureToTop)),
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
                                                if (_showKickTypeSelector) return;
                                                _applyKickRackInputsToState();
                                                _sendPipeProgressionOffsetsToRackState();
                                                _hideKeypad();
                                                FocusScope.of(context)
                                                    .unfocus();
                                                setState(() {
                                                  _showKickBendingMethodCard =
                                                      false;
                                                  _kickBendingMethodConfirmed =
                                                      false;
                                                  _showKickMeasurements = false;
                                                  _showKickTypeSelector = true;
                                                  _lastResultView =
                                                      _RackResultView.kick90;
                                                  _lastResultCommitted = false;
                                                  _viewingLatestResult = false;
                                                });
                                                _commitVisibleResultIfNeeded();
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
                                      if (!_showKickTypeSelector) ...[
                                        () {
                                          final styleData = kickPreviewConfig[
                                                      _selectedKickStyle]
                                                  ?[_kickVisualVariant] ??
                                              [-12.0, -10.0, 1.0, 1.0];
                                          return _KickStylePictureCard(
                                            selectedKickStyle:
                                                _selectedKickStyle,
                                            selectedPipeIndexInSet:
                                                selectedPipeIndexInSet,
                                            kickDirection: _kickDirection,
                                            assetPath: _kickAssetPath,
                                            variantLabel:
                                                _kickVisualVariantLabel,
                                            labels: labels,
                                            showDots: false,
                                            cardHeight: 210,
                                            imgScaleX: styleData[2],
                                            imgScaleY: styleData[3],
                                            imgYShift: styleData[1],
                                            imgXShift: styleData[0],
                                            onDirectionChanged: (value) {
                                              setState(() {
                                                _kickDirection = value;
                                              });
                                            },
                                            onDotTap: (_) {},
                                          );
                                        }(),
                                        const SizedBox(height: 6),
                                        if (_showKickTypeCard) ...[
                                          _buildKickDirectionRow(),
                                          const SizedBox(height: 8),
                                        ],
                                      ],
                                      if (!_showKickTypeSelector &&
                                          !_showKickBendingMethodCard)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withAlpha(180),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFC8C8C8),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Text(
                                            _kickTypeConfirmed
                                                ? 'Enter the inside pipe (Pipe 1) first. Begin at the stub end: Mark A locates the 90, Mark B locates the kick, and Mark C is the cut length. MAX STUB keeps Leg Length fixed and adjusts Stub Height so the longest pipe finishes at 120".'
                                                : 'Choose a kick type, then select Kick Up or Down and Turn Left or Right. Compare the preview with your layout, then press Continue to enter the inside-pipe measurements.',
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
                                    ],
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    if (_isParallel90sMode &&
                                        (!_parallel90ShowResults ||
                                            _showParallel90Measurements)) ...[
                                      _buildParallel90sInputs(),
                                    ],
                                  ],
                                ),
                            ],
                            if (_isParallel90sMode &&
                                _parallel90ShowResults) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showParallel90Measurements =
                                          !_showParallel90Measurements;
                                    });
                                  },
                                  child: Text(
                                    _showParallel90Measurements
                                        ? 'Hide Measurements'
                                        : 'Show Measurements',
                                    style: const TextStyle(
                                        color: kLight,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (!_showRackSetupStart &&
                                ((_isOffsetMode && _showRackResults) ||
                                    (_isParallel90sMode &&
                                        _parallel90ShowResults) ||
                                    (_isKick90sMode &&
                                        _showKickTypeSelector))) ...[
                              _buildRackPreview(showSizeButtons: false),
                              const SizedBox(height: 6),
                              _MarksCard(
                                markA: markA,
                                markB: markB,
                                shift: selectedPipeIndex <= 0
                                    ? '0'
                                    : RackState.inchFmt(rack
                                        .graduationForPipe(selectedPipeIndex)),
                                cut: cut,
                                isParallel90s: _isParallel90sMode,
                                parallel90Complete: parallel90Complete,
                                rack: rack,
                              ),
                              const SizedBox(height: 6),
                              if (rack.kickClearanceWarning != null)
                                Padding(padding: const EdgeInsets.all(8),
                                  child: Text(rack.kickClearanceWarning!,
                                    style: const TextStyle(color: Colors.amber),
                                    textAlign: TextAlign.center)),
                              _buildResultPicture(context),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (stickyFooter != null)
                      Padding(
                        padding:
                            EdgeInsets.fromLTRB(10, 6, 10, bottomSafe + 10),
                        child: stickyFooter,
                      ),
                  ],
                ),
                if (_isProjectHubVisible) _buildProjectHub(),
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
                            border: Border.all(
                                color: const Color(0xFFC0C0C0), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              const Text('Name Custom Bender',
                                  style: TextStyle(
                                      color: kLight,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                height: 46,
                                alignment: Alignment.centerLeft,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                    color: kBlack,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white54, width: 1.2)),
                                child: Text(
                                    _customBenderName.isEmpty
                                        ? 'Enter bender name'
                                        : _customBenderName,
                                    style: TextStyle(
                                        color: _customBenderName.isEmpty
                                            ? Colors.white38
                                            : kLight,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                      child: _BeveledButton(
                                          onTap: () => setState(() {
                                                _isNameEntryMode = false;
                                                _customBenderName = '';
                                              }),
                                          child: const Text('Cancel',
                                              style: TextStyle(
                                                  color: kLight,
                                                  fontWeight:
                                                      FontWeight.w800)))),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: _BeveledButton(
                                          active: _customBenderName
                                              .trim()
                                              .isNotEmpty,
                                          onTap:
                                              _customBenderName.trim().isEmpty
                                                  ? null
                                                  : _saveCustomBender,
                                          child: const Text('Save',
                                              style: TextStyle(
                                                  color: kLight,
                                                  fontWeight:
                                                      FontWeight.w800)))),
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
                      bottom: bottomSafe + 5,
                      left: 0,
                      right: 0,
                      child: NumericInputKeypad(onTap: _onKeypadTap)),
              ],
            );
          },
        ),
      ),
    );
  }

  bool get _isStraightOffset => _isOffsetMode && !rack.isRollingMode &&
      (rack.offsetDirectionSign == 0 || rack.offsetDirectionSign == 2);

  bool get _isVertical90 => _isParallel90sMode &&
      (_parallel90Direction == 'up' || _parallel90Direction == 'down');

  Widget _buildResultPicture(BuildContext context) {
    if (_isStraightOffset) return const SizedBox.shrink();
    if (_isParallel90sMode && rack.isFromBox) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    final conduit = rack.current;
    final markA = RackState.inchFmt(conduit.markA);
    final markB = RackState.inchFmt(conduit.markB);
    final cut = RackState.inchFmt(conduit.ol);
    final selectedPipeIndexInSet = rack.selectedPipeIndex % 3;
    return SizedBox(
                                height: (_isVertical90 ? 0.5 : 1.0) * math.max(
                                  (mq.size.width - 20) * (designH / designW),
                                  mq.size.height *
                                      (_isKick90sMode
                                          ? (kickResultCardHeightFractions[
                                                      _selectedKickStyle]
                                                  ?[_kickVisualVariant] ??
                                              resultsCardHeightViewportFraction)
                                          : resultsCardHeightViewportFraction),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFC0C0C0),
                                        width: 1.5),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, c) {
                                      final scale = (c.maxWidth / designW);
                                      final canvasW = designW * scale;
                                      final canvasH = designH * scale;
                                      double sx(double x) => x * scale;
                                      double sy(double y) => y * scale;
                                      double mainY = 0, mainScale = 1.0;
                                      double mainScaleY = 1.0;
                                      double dotPosX = 0;
                                      double dotPosX2 = 0;
                                      double dotPosX3 = 0;
                                      double dY1 = 0, dY2 = 0, dY3 = 0;
                                      String currentAsset = '';
                                      final styleData =
                                          kickResultsConfig[_selectedKickStyle]
                                                  ?[_kickVisualVariant] ??
                                              [
                                                -12.0,
                                                -150.0,
                                                1.0,
                                                1.0,
                                                100.0,
                                                1050.0,
                                                1800.0,
                                                1880.0,
                                                565.0,
                                                410.0,
                                                260.0
                                              ];
                                      double currentXShift =
                                          styleData[kickImageXIndex];
                                      double currentYShift =
                                          styleData[kickImageYIndex];
                                      double currentScaleX =
                                          styleData[kickImageScaleXIndex];
                                      double currentScaleY =
                                          styleData[kickImageScaleYIndex];
                                      if (_isParallel90sMode) {
                                        final bool isLeft =
                                            _parallel90Direction == 'left';
                                        mainY = isLeft
                                            ? p90MainYShift_Left
                                            : p90MainYShift_Right;
                                        mainScale = isLeft
                                            ? p90MainScale_Left
                                            : p90MainScale_Right;
                                        mainScaleY = isLeft
                                            ? p90MainScaleY_Left
                                            : p90MainScaleY_Right;
                                        dotPosX = isLeft
                                            ? p90DotX_Left
                                            : p90DotX_Right;
                                        dotPosX2 = dotPosX;
                                        dotPosX3 = dotPosX;
                                        dY1 = isLeft
                                            ? p90DotY1_Left
                                            : p90DotY1_Right;
                                        dY2 = isLeft
                                            ? p90DotY2_Left
                                            : p90DotY2_Right;
                                        dY3 = isLeft
                                            ? p90DotY3_Left
                                            : p90DotY3_Right;
                                        currentAsset = _parallel90AssetPath;
                                      } else if (_isOffsetMode) {
                                        if (rack.offsetDirectionSign == -1) {
                                          mainY = offMainY_Left;
                                        } else if (rack.offsetDirectionSign ==
                                            1) {
                                          mainY = offMainY_Right;
                                        } else if (rack.offsetDirectionSign ==
                                            2) {
                                          mainY = offMainY_Down;
                                        } else {
                                          mainY = offMainY_Up;
                                        }
                                        mainScale = offsetMainScale;
                                        mainScaleY = offsetMainScale;
                                        final bool isLeft =
                                            rack.offsetDirectionSign == -1;
                                        dotPosX = isLeft
                                            ? offDotX_Left
                                            : offDotX_Right;
                                        dotPosX2 = dotPosX;
                                        dotPosX3 = dotPosX;
                                        dY1 = isLeft
                                            ? offDotY1_Left
                                            : offDotY1_Right;
                                        dY2 = isLeft
                                            ? offDotY2_Left
                                            : offDotY2_Right;
                                        dY3 = isLeft
                                            ? offDotY3_Left
                                            : offDotY3_Right;
                                        currentAsset = _offsetAssetPath;
                                      } else if (_isKick90sMode) {
                                        mainY = currentYShift;
                                        mainScale = 1.0;
                                        final bool dotsAreHorizontal =
                                            kickDotsHorizontal[
                                                        _selectedKickStyle]
                                                    ?[_kickVisualVariant] ??
                                                false;
                                        if (dotsAreHorizontal) {
                                          final dots =
                                              kickHorizontalDotPositions[
                                                          _selectedKickStyle]
                                                      ?[_kickVisualVariant] ??
                                                  const [
                                                    260.0,
                                                    900.0,
                                                    650.0,
                                                    900.0,
                                                    1400.0,
                                                    900.0
                                                  ];
                                          dotPosX = dots[0];
                                          dY1 = dots[1];
                                          dotPosX2 = dots[2];
                                          dY2 = dots[3];
                                          dotPosX3 = dots[4];
                                          dY3 = dots[5];
                                        } else {
                                          dotPosX = styleData[kickDotXIndex];
                                          dotPosX2 = dotPosX;
                                          dotPosX3 = dotPosX;
                                          dY1 = styleData[kickDotY1Index];
                                          dY2 = styleData[kickDotY2Index];
                                          dY3 = styleData[kickDotY3Index];
                                        }
                                        currentAsset = _kickAssetPath ?? '';
                                      }
                                      currentAsset = widget.savedResult?.settings['asset'] ?? currentAsset;
                                      int visualPipeIndex(int visualIndex) {
                                        // Parallel 90 dots are supplied below
                                        // in photograph order (top = 2,
                                        // middle = 1, bottom = 0). The left
                                        // photograph already follows that
                                        // order, so reversing it again makes
                                        // P1 select the outside pipe.
                                        if (_isParallel90sMode &&
                                            _parallel90Direction == 'right')
                                          return 2 - visualIndex;
                                        if (_isOffsetMode &&
                                            rack.offsetDirectionSign == -1)
                                          return 2 - visualIndex;
                                        if (_isKick90sMode) {
                                          final reverseForPicture =
                                              kickReversePipeOrder[
                                                      _selectedKickStyle]
                                                  ?[_kickVisualVariant];
                                          if (reverseForPicture != null) {
                                            return reverseForPicture
                                                ? 2 - visualIndex
                                                : visualIndex;
                                          }
                                        }
                                        if (_isKick90sMode &&
                                            _selectedKickStyle ==
                                                'Same Angle' &&
                                            _kickDirection == 'right')
                                          return 2 - visualIndex;
                                        if (_isKick90sMode &&
                                            _kickDirection == 'left')
                                          return 2 - visualIndex;
                                        return visualIndex;
                                      }

                                      Color dotColorForVisual(int visualIndex) {
                                        return selectedPipeIndexInSet ==
                                                visualPipeIndex(visualIndex)
                                            ? kRed
                                            : Colors.white38;
                                      }

                                      return Stack(
                                        clipBehavior: Clip.hardEdge,
                                        children: <Widget>[
                                          if (!_isVertical90 && widget.savedResult != null && currentAsset.isEmpty && !_isKick90sMode)
                                            const Positioned.fill(child: Center(child: Text('No photograph available for this saved direction.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)))),
                                          if (_isKick90sMode &&
                                              currentAsset.isEmpty)
                                            Positioned.fill(
                                              child: _MissingKickPhoto(
                                                style: _selectedKickStyle,
                                                variantLabel:
                                                    _kickVisualVariantLabel,
                                              ),
                                            ),
                                          if (!_isVertical90 && !(_isKick90sMode &&
                                              currentAsset.isEmpty))
                                            Positioned(
                                              left: sx(20.0 +
                                                  (_isParallel90sMode
                                                      ? (_parallel90Direction ==
                                                              'left'
                                                          ? p90MainXShift_Left
                                                          : p90MainXShift_Right)
                                                      : 0.0)),
                                              bottom: sy(mainY),
                                              width: canvasW,
                                              height: canvasH,
                                              child: currentAsset.isEmpty
                                                  ? const SizedBox.shrink()
                                                  : _isKick90sMode
                                                      ? Center(
                                                          child: Transform
                                                              .translate(
                                                            offset: Offset(
                                                                sx(currentXShift),
                                                                0),
                                                            child: Transform(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              transform: Matrix4
                                                                  .diagonal3Values(
                                                                      currentScaleX,
                                                                      currentScaleY,
                                                                      1.0),
                                                              child:
                                                                  Image.asset(
                                                                currentAsset,
                                                                fit: BoxFit
                                                                    .contain,
                                                                filterQuality:
                                                                    FilterQuality
                                                                        .high,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : Transform(
                                                          alignment:
                                                              Alignment.center,
                                                          transform: Matrix4
                                                              .diagonal3Values(
                                                                  mainScale,
                                                                  mainScaleY,
                                                                  1.0),
                                                          child: Image.asset(
                                                            currentAsset,
                                                            fit: BoxFit.fill,
                                                            filterQuality:
                                                                FilterQuality
                                                                    .high,
                                                          ),
                                                        ),
                                            ),
                                          if (!_isVertical90 && !(_isKick90sMode &&
                                              currentAsset.isEmpty)) ...[
                                            _dotAt(
                                                sx(dotPosX),
                                                sy(dY1),
                                                dotColorForVisual(
                                                    _isKick90sMode ? 0 : 2)),
                                            _dotAt(sx(dotPosX2), sy(dY2),
                                                dotColorForVisual(1)),
                                            _dotAt(
                                                sx(dotPosX3),
                                                sy(dY3),
                                                dotColorForVisual(
                                                    _isKick90sMode ? 2 : 0)),
                                          ],
                                          Positioned(
                                            left: sx(bottomPipePaddingX),
                                            bottom: sy(bottomPipeGlue),
                                            width: sx(designW -
                                                (bottomPipePaddingX * 2)),
                                            height: sy(80),
                                            child: Image.asset(
                                              'assets/conduits/emt/pipe_5_ol.png',
                                              fit: BoxFit.fill,
                                              filterQuality: FilterQuality.high,
                                            ),
                                          ),
                                          () {
                                            final bool measureFromLeft =
                                                !rack.current.measureFromTail;
                                            double pA, pB, pC;
                                            if (_isParallel90sMode) {
                                              final p90MarkBottom =
                                                  _parallel90Direction == 'left'
                                                      ? p90BottomMarkGlue_Left
                                                      : p90BottomMarkGlue_Right;
                                              pA = measureFromLeft
                                                  ? sx(p90MarkA_Right_X)
                                                  : sx(p90MarkA_Left_X);
                                              pC = measureFromLeft
                                                  ? sx(p90MarkC_Left_X)
                                                  : sx(p90MarkC_Right_X);
                                              return Stack(
                                                children: [
                                                  _downMarkAtBottom(
                                                      pA,
                                                      sy(p90MarkBottom),
                                                      'A',
                                                      markA),
                                                  _downMarkAtBottom(
                                                      pC,
                                                      sy(p90MarkBottom),
                                                      'C',
                                                      cut),
                                                ],
                                              );
                                            } else if (_isKick90sMode) {
                                              return Stack(
                                                children: [
                                                  _downMarkAtBottom(
                                                      sx(styleData[
                                                          kickMarkAIndex]),
                                                      sy(bottomMarkGlue),
                                                      'A',
                                                      markA,
                                                      centerOnX: true),
                                                  _downMarkAtBottom(
                                                      sx(styleData[
                                                          kickMarkBIndex]),
                                                      sy(bottomMarkGlue),
                                                      'B',
                                                      markB,
                                                      centerOnX: true),
                                                  _downMarkAtBottom(
                                                      sx(styleData[
                                                          kickMarkCIndex]),
                                                      sy(bottomMarkGlue),
                                                      'C',
                                                      cut,
                                                      centerOnX: true),
                                                ],
                                              );
                                            } else {
                                              final bool isLeft =
                                                  rack.offsetDirectionSign ==
                                                      -1;
                                              double pC = sx(isLeft
                                                  ? offMarkC_Left_X
                                                  : offMarkC_Right_X);
                                              double pA = sx(isLeft
                                                  ? offMarkA_Left_X
                                                  : offMarkA_Right_X);
                                              double pB = sx(isLeft
                                                  ? offMarkB_Left_X
                                                  : offMarkB_Right_X);
                                              return Stack(
                                                children: [
                                                  _downMarkAtBottom(
                                                      pC,
                                                      sy(bottomMarkGlue),
                                                      'C',
                                                      cut),
                                                  _downMarkAtBottom(
                                                      pA,
                                                      sy(bottomMarkGlue),
                                                      'A',
                                                      markA),
                                                  _downMarkAtBottom(
                                                      pB,
                                                      sy(bottomMarkGlue),
                                                      'B',
                                                      markB),
                                                ],
                                              );
                                            }
                                          }(),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: sy(bottomMeasureTextGlue),
                                            child: _InfoBar(
                                              expanded: _showInfo,
                                              onMore: () => setState(
                                                  () => _showInfo = !_showInfo),
                                              measureFromTail:
                                                  rack.current.measureFromTail,
                                              showOnLeftOverride:
                                                  _isKick90sMode ? true : null,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              );
  }

  SavedBendResult _captureHubResult() => rack.captureResult({
    'view': _isParallel90sMode ? 'parallel90' : (_isKick90sMode ? 'kick90' : 'offset'),
    'style': _selectedKickStyle, 'kickDirection': _kickDirection,
    'kickVertical': _kickVerticalDirection,
    'asset': _isParallel90sMode ? _parallel90AssetPath :
        (_isKick90sMode ? (_kickAssetPath ?? '') : _offsetAssetPath),
    'spacingMode': _rackSpacingIsCenterToCenter ? 'Center to center' : 'Space between',
    'enteredSpacing': runC2C.text,
    'strutLength': strutLengthCtl.text,
    if (_isKick90sMode && _kickHandoffActive && widget.initialKick?.clearanceWarning != null)
      'sourceClearanceWarning': widget.initialKick!.clearanceWarning!,
  });

  void _openSavedResult(SavedBendResult saved) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      ChangeNotifierProvider(create: (_) => RackState.fromSavedResult(saved),
        child: RackBuilderScreen(savedResult: saved))));
  }

  Widget _buildSavedResults(BuildContext context) {
    final saved = widget.savedResult!;
    final pipe = saved.pipes[rack.selectedPipeIndex];
    // Derive the finished length from this snapshot, never the current bend.
    final finishedOffsetLength = _isOffsetMode && saved.settings['fullStick'] == 'true'
        ? bending_data.calculateOffsetLayout(
            verticalOffset: saved.inputs['Offset height']!,
            horizontalRoll: saved.mode.toLowerCase().contains('rolling')
                ? saved.inputs['Horizontal roll']! : 0,
            angleDeg: saved.inputs['Bend angle']!,
            distanceToObstruction: saved.inputs['Distance']!,
            requestedFinishedOverallLength: 0,
            layoutDirection: saved.settings['layout'] == 'towardObstruction'
                ? bending_data.OffsetLayoutDirection.towardObstruction
                : bending_data.OffsetLayoutDirection.pastObstruction,
            useFullStick: true,
            stockLength: pipe.markC,
          ).finishedOverallLength
        : saved.inputs['Overall length'];
    final title = _isParallel90sMode ? 'Parallel 90' :
        (_isKick90sMode ? 'Kick 90 — $_selectedKickStyle' :
          (saved.mode.toLowerCase().contains('rolling') ? 'Rolling Offset' : 'Offset'));
    final inputKeys = _isParallel90sMode ? ['Stub', 'Leg'] :
        (_isKick90sMode ? ['Kick stub', 'Kick leg', 'Kick height', 'Kick angle', 'Match bend distance'] :
          ['Distance', 'Offset height', if (saved.mode.toLowerCase().contains('rolling')) 'Horizontal roll', 'Overall length', 'Bend angle']);
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(title: Text('Saved $title'), backgroundColor: kBlack),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(10), children: [
        const Text('Saved results • Read-only', style: TextStyle(color: Colors.white70)),
        if (saved.settings['kickClearanceWarning'] != null)
          Text(saved.settings['kickClearanceWarning']!, style: const TextStyle(color: Colors.amber)),
        if (saved.settings['kickClearanceWarning'] == null && saved.settings['sourceClearanceWarning'] != null)
          Text('Original standalone bend: ${saved.settings['sourceClearanceWarning']}', style: const TextStyle(color: Colors.amber)),
        Wrap(spacing: 8, children: List.generate(saved.pipes.length, (i) => ChoiceChip(
          label: Text('Pipe ${i + 1}'), selected: rack.selectedPipeIndex == i,
          onSelected: (_) => setState(() { rack.select(i); _selectedRackPipe = i; _currentSet = i ~/ 3; }),
        ))),
        _hubDetailRow('Pipe ${rack.selectedPipeIndex + 1}', '${pipe.size} ${pipe.conduitType.toUpperCase()}'),
        _hubDetailRow('Mark A', RackState.inchFmt(pipe.markA)),
        if (!_isParallel90sMode) _hubDetailRow('Mark B', RackState.inchFmt(pipe.markB)),
        _hubDetailRow('Mark C / Cut', RackState.inchFmt(pipe.markC)),
        // The same picture/mark renderer as the active calculator, with frozen data.
        _buildResultPicture(context),
        const SizedBox(height: 12),
        _hubDetailRow('Bender', pipe.bender ?? 'Custom / unspecified'),
        _hubDetailRow('Method', saved.settings['arrow'] == 'true' ? 'Arrow' : saved.settings['method']!),
        _hubDetailRow('Orientation', saved.settings['reverse'] == 'true' ? 'Reverse' : 'Forward'),
        _hubDetailRow('Direction', _isKick90sMode ? _kickVisualVariantLabel :
          (_isParallel90sMode ? saved.settings['direction']! : const {'-1': 'Left', '0': 'Up', '1': 'Right', '2': 'Down'}[saved.settings['offsetDirection']] ?? 'Unspecified')),
        if (_isOffsetMode) _hubDetailRow('Layout', saved.settings['layout'] == 'towardObstruction' ? 'Toward obstruction' : 'Past obstruction'),
        _hubDetailRow(saved.settings['spacingMode']!, saved.settings['enteredSpacing']!),
        for (final key in inputKeys) _hubDetailRow(key,
          key.toLowerCase().contains('angle') ? '${saved.inputs[key]}°' : RackState.inchFmt(
              key == 'Overall length' ? finishedOffsetLength! : saved.inputs[key]!)),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: kLight,
            side: const BorderSide(color: Color(0xFF8C8C8C)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('BACK TO HUB'),
        ),
      ])),
    );
  }

  Widget _dotAt(double x, double bottom, Color color) => Positioned(
        left: x,
        bottom: bottom,
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

  Widget _downMarkAtBottom(
          double x, double bottomDist, String label, String value,
          {bool centerOnX = false}) =>
      Positioned(
        left: x,
        bottom: bottomDist,
        child: FractionalTranslation(
          translation: Offset(centerOnX ? -0.5 : 0.0, 0.0),
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
                          color: Colors.black54, blurRadius: 4, spreadRadius: 1)
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
        ),
      );
}

class _MiniArrowButton extends StatelessWidget {
  const _MiniArrowButton({
    super.key,
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
                      const SizedBox(
                          width:
                              36), // Balanced spacer for Reset button on right
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isEnabled ? Colors.white : Colors.grey.shade500,
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
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
          _row('Mark A', markA, valueHot: true),
          const SizedBox(height: 2),
          if (!isParallel90s && rack.calcMode != RackCalcMode.kick90) ...[
            _row('Mark B', markB),
            const SizedBox(height: 2),
            _row('Shift (Graduation)', shift),
            const SizedBox(height: 2),
          ],
          if (rack.calcMode == RackCalcMode.kick90) ...[
            _row('Mark B', markB),
            const SizedBox(height: 2),
          ],
          _row('Mark C', cut, valueHot: false),
          if (!isParallel90s) ...[
            const SizedBox(height: 2),
            _row('Angle',
                '${rack.current.angle.toStringAsFixed(rack.current.angle % 1 == 0 ? 0 : 1)}°'),
          ],
          const SizedBox(height: 4),
          if (!rack.isFromBox)
            _BeveledButton(
              height: 34,
              subtle: true,
              onTap: () {
                double exportSpacing = rack.centerToCenterSpacing;
                if (rack.calcMode == RackCalcMode.kick90 &&
                    (rack.kick90RackStyle == Kick90RackStyle.sameAngle ||
                        rack.kick90RackStyle == Kick90RackStyle.sameStart)) {
                  final angleRad = rack.kickAngle * math.pi / 180.0;
                  if (math.cos(angleRad).abs() > 0.1) {
                    exportSpacing =
                        rack.centerToCenterSpacing / math.cos(angleRad);
                  }
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BoxLayoutModeScreen(
                      prePopulatedConduits: rack.allConduits,
                      preCalculatedCenterToCenter: exportSpacing,
                      preCalculatedCenterMarks: rack.boxCenterMarks,
                      showBackButton: true,
                    ),
                  ),
                );
              },
              child: const Text(
                'EXPORT TO BOX LAYOUT (Optional)',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
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
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
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
                  child: Text('OR',
                      style: TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
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
                child: const Text('Locked at 120"',
                    style: TextStyle(
                        color: kGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
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
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value.endsWith('"') ? value : '$value"',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
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
          child: Text(title,
              style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          width: 150,
          child: Container(
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
                    suffixStyle:
                        const TextStyle(color: Colors.white, fontSize: 18),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isActive ? kGreen : Colors.white38,
                        width: isActive ? 1.8 : 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isActive ? kGreen : Colors.white38,
                        width: 1.5,
                      ),
                    ),
                    fillColor: isActive ? kGreen.withAlpha(40) : Colors.white12,
                    filled: true,
                  ),
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
                  child: Text('OR',
                      style: TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
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
                child: const Text('Locked at 120"',
                    style: TextStyle(
                        color: kGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
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
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value.endsWith('"') ? value : '$value"',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 150,
          child: Container(
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
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    suffixText: ctl.text.trim().endsWith(suffix) ? '' : suffix,
                    suffixStyle:
                        const TextStyle(color: Colors.white, fontSize: 18),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isActive ? kGreen : Colors.white38,
                        width: isActive ? 1.8 : 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isActive ? kGreen : Colors.white38,
                        width: 1.5,
                      ),
                    ),
                    fillColor: isActive ? kGreen.withAlpha(40) : Colors.white12,
                    filled: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MissingKickPhoto extends StatelessWidget {
  const _MissingKickPhoto({
    required this.style,
    required this.variantLabel,
  });

  final String style;
  final String variantLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white38, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                color: Colors.white54, size: 30),
            const SizedBox(height: 8),
            Text(
              '$style — $variantLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kLight,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'PHOTO NEEDED',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KickStylePictureCard extends StatelessWidget {
  const _KickStylePictureCard({
    required this.selectedKickStyle,
    required this.selectedPipeIndexInSet,
    required this.kickDirection,
    required this.assetPath,
    required this.variantLabel,
    required this.labels,
    required this.onDirectionChanged,
    required this.onDotTap,
    this.showDots = true,
    this.cardHeight = 240,
    this.imgScaleX = 1.0,
    this.imgScaleY = 1.0,
    this.imgXShift = -12.0,
    this.imgYShift = 0.0,
  });
  final String selectedKickStyle;
  final int selectedPipeIndexInSet;
  final String kickDirection;
  final String? assetPath;
  final String variantLabel;
  final List<int> labels;
  final ValueChanged<String> onDirectionChanged;
  final ValueChanged<int> onDotTap;
  final bool showDots;
  final double cardHeight;
  final double imgScaleX;
  final double imgScaleY;
  final double imgXShift;
  final double imgYShift;

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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: assetPath == null
                ? _MissingKickPhoto(
                    style: selectedKickStyle,
                    variantLabel: variantLabel,
                  )
                : Transform.translate(
                    offset: Offset(imgXShift, imgYShift),
                    child: Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.diagonal3Values(imgScaleX, imgScaleY, 1.0),
                      child: Image.asset(
                        assetPath!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
          ),
          if (showDots)
            Positioned(
              top: kickDirection == 'left' ? 25 : 91,
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
    required this.onContinueAnyway,
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
    required this.onUseMaxStub,
    required this.longestCutLength,
    required this.longestPipeNumber,
    required this.maxStubCanFit,
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
  final VoidCallback onContinueAnyway;
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
  final VoidCallback onUseMaxStub;
  final double longestCutLength;
  final int longestPipeNumber;
  final bool maxStubCanFit;
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
    final bool showLengthWarning =
        longestCutLength > 120.001 && activeController == null;
    final overage = longestCutLength - 120.0;
    final overageLabel = overage > 0 && overage < 1 / 16
        ? 'less than 1/16"' : RackState.inchFmt(overage);

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
                      border: Border.all(
                          color: const Color(0xFFC0C0C0), width: 0.8),
                    ),
                    child: Center(
                      child: Text(
                        measureToTop ? 'TOP' : 'BOT',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            _row(
              'Stub Height',
              stubCtl,
              onStubTap,
              activeController == stubCtl,
              trailingInput: _BeveledButton(
                width: 78,
                height: 30,
                onTap: maxStubCanFit ? onUseMaxStub : null,
                child: const Text(
                  'MAX STUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (!isFromBox) ...[
              _row(
                'Leg Length',
                legCtl,
                onLegTap,
                activeController == legCtl,
              ),
              const SizedBox(height: 6),
            ],
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
            if (showLengthWarning)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D2E00),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber, width: 1.2),
                ),
                child: Column(
                  children: [
                    Text(
                      maxStubCanFit
                          ? '⚠️ Pipe $longestPipeNumber exceeds 10ft by $overageLabel. Keep Leg Length fixed and tap MAX STUB, edit Stub Height, or continue anyway.'
                          : '⚠️ This Kick 90 cannot fit on a 10ft stick by reducing Stub Height to the bender minimum. Change the geometry or continue anyway.',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (maxStubCanFit) ...[
                          Expanded(
                            child: _BeveledButton(
                              height: 30,
                              onTap: onUseMaxStub,
                              child: const Text(
                                'MAX STUB',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: _BeveledButton(
                            height: 30,
                            subtle: true,
                            onTap: onContinueAnyway,
                            child: const Text(
                              'CONTINUE ANYWAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
            if (!showLengthWarning)
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
    Widget? trailingInput,
  }) {
    final String value = ctl.text.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFC8C8C8),
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
            if (trailingInput != null) ...[
              trailingInput,
              const SizedBox(width: 8),
            ],
            SizedBox(
              width: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active ? kGreen : Colors.white38,
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
                    border:
                        Border.all(color: const Color(0xFFC0C0C0), width: 0.8),
                  ),
                  child: Center(
                    child: Text(
                      measureToTop ? 'TOP' : 'BOT',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11),
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
              trailingInput: onAlignEnds != null
                  ? _BeveledButton(
                      width: 85,
                      height: 32,
                      onTap: onAlignEnds!,
                      child: const Text(
                        'MAX PIPE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900),
                      ),
                    )
                  : null,
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
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value.endsWith('"') ? value : '$value"',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
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
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? kGreen : const Color(0xFFC8C8C8),
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
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active ? kGreen : Colors.white38,
                    width: active ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  ctl.text.isEmpty ? '0"' : ctl.text,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullStickToggle extends StatelessWidget {
  const _FullStickToggle(
      {required this.value, required this.onChanged, this.useLetters = false});
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
              ? const LinearGradient(
                  colors: [Color(0xFF8A1010), Color(0xFFD12A2A)])
              : const LinearGradient(
                  colors: [Color(0xFF3A3A3D), Color(0xFF1F1F21)]),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? kRed : const Color(0xFF8C8C8C),
              width: active ? 1.5 : 1.0),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                color: kLight,
                fontSize: useLetters ? 11 : 15,
                fontWeight: FontWeight.w900),
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
    this.isGeometry = false,
    this.isFromBox = false,
    this.isHubVisible = false,
    this.isKick90Results = false,
    this.showKickLandscapeHint = false,
    this.isStraightOffset = false,
    this.isVertical90 = false,
  });

  final bool isOffsetMode;
  final bool isStraightOffset;
  final bool isVertical90;
  final bool isRollingMode;
  final bool needsDirection;
  final bool showResults;
  final bool isBendingMethod;
  final bool isGeometry;
  final bool isFromBox;
  final bool isHubVisible;
  final bool isKick90Results;
  final bool showKickLandscapeHint;

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
    } else if (showResults && isKick90Results) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Begin with the inside pipe (Pipe 1) and measure from the stub end. Mark A locates the 90, Mark B locates the kick, and Mark C is the cut length.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (showKickLandscapeHint) ...[
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.screen_rotation, color: Colors.amber, size: 19),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Try turning your phone to landscape for a new perspective.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    } else if (showResults) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVertical90) ...[
            const Text(
              'For up/down 90s, pipes with the same size and bender use the same Mark A and Mark C measurements. Mark A locates the 90 using the take-up; Mark C is the cut length.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kLight, fontSize: 16,
                  fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 8),
          ],
          if (isStraightOffset)
            const Text(
              'These offsets go straight up or down, so pipes with the same size '
              'and bender use the same marks and cut length. Left/right parallel '
              'offsets shift the marks between pipes.\n\n'
              'Tap H to review saved results, supports, and material totals after each bend.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kLight, fontSize: 16,
                  fontWeight: FontWeight.w700, height: 1.3),
            )
          else if (isFromBox)
            const Text(
              'These 90s come straight out from the wall, so pipes with the same size '
              'and bender use the same measurements.\n\n'
              'After each bend, tap H to review your saved results, support locations, '
              'and running material totals in the Hub.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kLight, fontSize: 16,
                  fontWeight: FontWeight.w700, height: 1.3),
            )
          else const Text(
            'Select pipes above to view each mark.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: kLight, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          // ALIGNED LEGEND TABLE
          SizedBox(
            width: 260,
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(54),
                1: FixedColumnWidth(26),
                2: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    const _MiniArrowIndicator(isLeft: true),
                    const Center(
                        child: Text('=',
                            style: TextStyle(
                                color: kLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w900))),
                    const Text('next bend',
                        style: TextStyle(
                            color: kLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const TableRow(
                    children: [SizedBox(height: 4), SizedBox(), SizedBox()]),
                TableRow(
                  children: [
                    const _MiniArrowIndicator(isLeft: false),
                    const Center(
                        child: Text('=',
                            style: TextStyle(
                                color: kLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w900))),
                    Text(isFromBox ? 'back to starting point' : 'back to measurements',
                        style: const TextStyle(
                            color: kLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else if (isBendingMethod) {
      content = const Text(
        'Choose your bending method. The geometry results will update based on this selection.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kLight,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      );
    } else if (isGeometry) {
      content = const Text(
        'Review your offset geometry. "Mark A (Furthest Pipe)" ensures the last conduit in your rack will fit your stick length.',
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
        'Distance to Back  of 90 = coupling to back of turn on inside pipe. Distance After 90 = run length after turn. Tap MAX PIPE to use the most pipe possible after the back of outer 90. Check the hub for rack positioning.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kLight,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 40), // Reduced from 50
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 4), // Tightened from 6
      decoration: BoxDecoration(
        color: isHubVisible ? kBlack : Colors.black.withAlpha(180),
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
    this.forceOnLeft = false,
    this.showOnLeftOverride,
  }) : super(key: key);

  final bool expanded;
  final VoidCallback onMore;
  final bool isParallel90s;
  final double xShift;
  final bool measureFromTail;
  final bool forceOnLeft;
  final bool? showOnLeftOverride;

  @override
  Widget build(BuildContext context) {
    const chunkyStyle = TextStyle(
        color: kLight, fontSize: 24, fontWeight: FontWeight.w900, height: 1.0);
    const textStyle =
        TextStyle(color: kLight, fontSize: 16, fontWeight: FontWeight.w800);

    final bool measureFromLeft = !measureFromTail;

    // USER RULE:
    // measureFromLeft (Long Tail) -> Indicator on RIGHT, Arrow RIGHT
    // !measureFromLeft (Short Tail) -> Indicator on LEFT, Arrow LEFT
    final bool showOnLeft =
        showOnLeftOverride ?? (forceOnLeft || !measureFromLeft);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: measureInstructionVerticalPadding,
        horizontal: measureInstructionHorizontalPadding,
      ),
      child: Transform.translate(
        offset: Offset(
          showOnLeft
              ? measureInstructionLeftXShift
              : measureInstructionRightXShift,
          0,
        ),
        child: Row(
          mainAxisAlignment:
              showOnLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (showOnLeft) ...[
              // Arrow points LEFT on the Left side
              Transform.translate(
                offset: const Offset(0, measureInstructionLeftArrowYShift),
                child: const RotatedBox(
                  quarterTurns: 2,
                  child: Text("➜", style: chunkyStyle),
                ),
              ),
              const SizedBox(width: measureInstructionArrowGap),
              const Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Measure from this end', style: textStyle))),
            ] else ...[
              // Arrow points RIGHT on the Right side
              const Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Measure from this end', style: textStyle))),
              const SizedBox(width: measureInstructionArrowGap),
              Transform.translate(
                offset: const Offset(0, measureInstructionRightArrowYShift),
                child: const Text("➜", style: chunkyStyle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CornerDiagram extends StatelessWidget {
  const _CornerDiagram({
    super.key,
    required this.segmentIndex,
    required this.inOffset,
    required this.outOffset,
    required this.isLeftTurn,
  });

  final int segmentIndex;
  final double? inOffset;
  final double? outOffset;
  final bool isLeftTurn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double w = constraints.maxWidth;
      const double h = 140.0;

      const double cornerXFactor = 0.25;
      final double cornerYFactor = isLeftTurn ? 0.30 : 0.70;
      final Offset corner = Offset(w * cornerXFactor, h * cornerYFactor);

      const double hLen = 120.0;
      const double vLen = 80.0;

      return Container(
        height: h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: Size(w, h),
              painter: _CornerPainter(isLeftTurn: isLeftTurn),
            ),

            // IN Group (Horizontal) - Centered on arrow
            Positioned(
              left: corner.dx + (hLen / 2) - 25,
              top: isLeftTurn ? corner.dy - 40 : corner.dy + 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (inOffset != null) _BlueprintInput(
                    value: RackState.inchFmt(inOffset!).replaceAll('"', ''),
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  const Text('IN',
                      style: TextStyle(
                          color: kLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),

            // OUT Group (Vertical) - Centered on leg
            Positioned(
              left: corner.dx - 70, // Nudged right
              top: isLeftTurn
                  ? corner.dy + (vLen / 2) - 24
                  : corner.dy - (vLen / 2) - 24, // Better vertical centering
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('OUT',
                      style: TextStyle(
                          color: kLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8), // More space below word OUT
                  if (outOffset != null) _BlueprintInput(
                    value: RackState.inchFmt(outOffset!).replaceAll('"', ''),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _BlueprintInput extends StatelessWidget {
  const _BlueprintInput({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          '$value"',
          style: const TextStyle(
            color: kLight,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}

class _MiniArrowIndicator extends StatelessWidget {
  const _MiniArrowIndicator({required this.isLeft});
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 26,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A1010),
            Color(0xFFD12A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 0.9,
        ),
      ),
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(isLeft ? -1.1 : 1.1, 1.0, 1.0),
          child: const Text(
            "➜",
            style: TextStyle(
              color: kLight,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
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
    final double cornerYFactor = isLeftTurn ? 0.30 : 0.70;
    const double hLen = 120.0;
    const double vLen = 80.0;
    const double tickGap = 5.0;
    const double tickLen = 14.0;

    final Offset corner =
        Offset(size.width * cornerXFactor, size.height * cornerYFactor);

    final pipePaint = Paint()
      ..color = Colors.white.withAlpha(120) // Solid contrast
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = kGreen
      ..strokeWidth = 3.5 // Bolder green arrows
      ..style = PaintingStyle.stroke;

    final tickPaint = Paint()
      ..color = Colors.white // Solid white ticks
      ..strokeWidth = 2.0 // Bolder white ticks
      ..style = PaintingStyle.stroke;

    // Draw Pipe (The conduit)
    final path = Path();
    path.moveTo(size.width * 0.95, corner.dy);
    path.lineTo(corner.dx, corner.dy);
    if (!isLeftTurn) {
      path.lineTo(corner.dx, size.height * 0.05);
    } else {
      path.lineTo(corner.dx, size.height * 0.95);
    }
    canvas.drawPath(path, pipePaint);

    if (!isLeftTurn) {
      // RIGHT TURN (Bottom-Left Corner)
      // Horizontal Arrow: From right, point LEFT into corner
      _drawArrow(canvas, corner + Offset(hLen, 0), const Offset(-1, 0), hLen,
          arrowPaint);
      // Vertical Arrow: From corner, point UP
      _drawArrow(canvas, corner, const Offset(0, -1), vLen, arrowPaint);

      // Ticks (Outside of the L-shape)
      // Corner Ticks
      canvas.drawLine(Offset(corner.dx, corner.dy + tickGap),
          Offset(corner.dx, corner.dy + tickGap + tickLen), tickPaint);
      canvas.drawLine(Offset(corner.dx - tickGap, corner.dy),
          Offset(corner.dx - tickGap - tickLen, corner.dy), tickPaint);

      // End Ticks
      canvas.drawLine(Offset(corner.dx + hLen, corner.dy + tickGap),
          Offset(corner.dx + hLen, corner.dy + tickGap + tickLen), tickPaint);
      canvas.drawLine(Offset(corner.dx - tickGap, corner.dy - vLen),
          Offset(corner.dx - tickGap - tickLen, corner.dy - vLen), tickPaint);
    } else {
      // LEFT TURN (Top-Left Corner)
      // Horizontal Arrow: From right, point LEFT into corner
      _drawArrow(canvas, corner + Offset(hLen, 0), const Offset(-1, 0), hLen,
          arrowPaint);
      // Vertical Arrow: From corner, point DOWN
      _drawArrow(canvas, corner, const Offset(0, 1), vLen, arrowPaint);

      // Ticks (Outside of the L-shape)
      // Corner Ticks
      canvas.drawLine(Offset(corner.dx, corner.dy - tickGap),
          Offset(corner.dx, corner.dy - tickGap - tickLen), tickPaint);
      canvas.drawLine(Offset(corner.dx - tickGap, corner.dy),
          Offset(corner.dx - tickGap - tickLen, corner.dy), tickPaint);

      // End Ticks
      canvas.drawLine(Offset(corner.dx + hLen, corner.dy - tickGap),
          Offset(corner.dx + hLen, corner.dy - tickGap - tickLen), tickPaint);
      canvas.drawLine(Offset(corner.dx - tickGap, corner.dy + vLen),
          Offset(corner.dx - tickGap - tickLen, corner.dy + vLen), tickPaint);
    }
  }

  void _drawArrow(
      Canvas canvas, Offset start, Offset dir, double length, Paint paint) {
    final Offset end = start + Offset(dir.dx * length, dir.dy * length);
    canvas.drawLine(start, end, paint);
    const double headSize = 10;
    final Path head = Path();
    if (dir.dx != 0) {
      head.moveTo(end.dx, end.dy);
      head.lineTo(end.dx - dir.dx * headSize, end.dy - headSize / 1.8);
      head.lineTo(end.dx - dir.dx * headSize, end.dy + headSize / 1.8);
    } else {
      head.moveTo(end.dx, end.dy);
      head.lineTo(end.dx - headSize / 1.8, end.dy - dir.dy * headSize);
      head.lineTo(end.dx + headSize / 1.8, end.dy - dir.dy * headSize);
    }
    head.close();
    canvas.drawPath(head, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
