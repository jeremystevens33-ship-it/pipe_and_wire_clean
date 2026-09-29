import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'keypad_5.dart';
import 'keypad_6.dart';
import 'rack_builder_11.dart';
import 'rack_state.dart';
import 'main_menu_screen.dart';
import 'bender_picker_dialog.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OffsetStartingPointScreen(),
    ),
  );
}

const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);

class OffsetStartingPointScreen extends StatefulWidget {
  const OffsetStartingPointScreen({super.key});

  @override
  State<OffsetStartingPointScreen> createState() =>
      _OffsetStartingPointScreenState();
}

class _OffsetStartingPointScreenState extends State<OffsetStartingPointScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isBenderExpanded = true;
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;
  bool _showLayoutDirectionCard = false;
  bool _showBendingMethodCard = false;
  bool _bendingMethodCardExpanded = false;
  bool _isCalculateReady = false;
  bool _isSpaceBetweenMode = true;
  int _parallelDirection = 0;

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

  bool get _isBenderSetupComplete =>
      _selectedBrand != null && _selectedPipeSize != null;

  String? _selectedBrand;
  String? _selectedPipeSize;
  bending_data.Bender? _selectedBenderData;
  bending_data.BendingMethod _bendingMethod =
      bending_data.BendingMethod.centerline;
  bool _isArrowMethod = true;
  bool _isBenderDirectionReversed = false; // Forward/Reverse Hook
  bending_data.OffsetLayoutDirection _offsetLayoutDirection =
      bending_data.OffsetLayoutDirection.towardObstruction;
  final List<bending_data.Bender> _customBenders = [];
  List<Map<String, String>> _allBrands = [];

  bool _isKeypadVisible = false;
  TextEditingController? _activeController;
  bool _isNameEntryMode = false;
  String _customBenderName = '';

  bool _showParallelSetup = false;
  bool _isRollingOffset = false;
  bool _isQuickMode = true;
  bool _useFullStick = false;
  bool _modeTouched = false;
  bool _typeTouched = false;
  final GlobalKey _resultsSectionKey = GlobalKey();

  final distanceCtl = TextEditingController();
  final offsetHeightCtl = TextEditingController();
  final rollingVerticalCtl = TextEditingController();
  final rollingHorizontalCtl = TextEditingController();
  final overallCtl = TextEditingController();
  final angleCtl = TextEditingController();
  final parallelSpacingCtl = TextEditingController();
  final parallelPipeCountCtl = TextEditingController();
  final parallelPipeSizeCtl = TextEditingController();

  final takeUpCtl = TextEditingController();
  final gainCtl = TextEditingController();
  final radiusCtl = TextEditingController();
  final setbackCtl = TextEditingController();

  String _parallelConduitType = 'EMT';
  final ScrollController _scrollCtl = ScrollController();
  String markA = '';
  String markB = '';
  String markC = '';
  String shrinkOut = '';
  String travelOut = '';
  String straightFinishOut = '';
  double _rawMarkA = 0.0;
  double _rawMarkB = 0.0;
  double _rawCut = 0.0;
  double _rawTakeUp = 0.0;
  double _rawGain = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCustomBenders();
    _updateBrandDropdown();

    parallelSpacingCtl.addListener(_onParallelSpacingChanged);
    distanceCtl.addListener(_onInputChanged);
    offsetHeightCtl.addListener(_onInputChanged);
    rollingVerticalCtl.addListener(_onInputChanged);
    rollingHorizontalCtl.addListener(_onInputChanged);
    overallCtl.addListener(_onInputChanged);
    angleCtl.addListener(_onInputChanged);

    distanceCtl.addListener(_updateCalculateReady);
    offsetHeightCtl.addListener(_updateCalculateReady);
    rollingVerticalCtl.addListener(_updateCalculateReady);
    rollingHorizontalCtl.addListener(_updateCalculateReady);
    overallCtl.addListener(_updateCalculateReady);
    angleCtl.addListener(_updateCalculateReady);

    takeUpCtl.addListener(_updateSetback);
    gainCtl.addListener(_updateSetback);
    gainCtl.addListener(_updateRadiusFromGain);
    radiusCtl.addListener(_updateGainFromRadius);

    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  void _onParallelSpacingChanged() => setState(() {});
  void _onInputChanged() => setState(() {});

  void _updateCalculateReady() {
    bool ready = false;
    if (_isRollingOffset) {
      if (_isQuickMode) {
        ready = rollingVerticalCtl.text.isNotEmpty &&
            rollingHorizontalCtl.text.isNotEmpty &&
            angleCtl.text.isNotEmpty;
      } else {
        final bool baseInputs = rollingVerticalCtl.text.isNotEmpty &&
            rollingHorizontalCtl.text.isNotEmpty &&
            angleCtl.text.isNotEmpty &&
            distanceCtl.text.isNotEmpty;
        ready = baseInputs && (_useFullStick || overallCtl.text.isNotEmpty);
      }
    } else {
      if (_isQuickMode) {
        ready = offsetHeightCtl.text.isNotEmpty && angleCtl.text.isNotEmpty;
      } else {
        final bool baseInputs = offsetHeightCtl.text.isNotEmpty &&
            angleCtl.text.isNotEmpty &&
            distanceCtl.text.isNotEmpty;
        ready = baseInputs && (_useFullStick || overallCtl.text.isNotEmpty);
      }
    }
    if (ready != _isCalculateReady) {
      setState(() => _isCalculateReady = ready);
    }
  }

  Future<void> _loadCustomBenders() async {
    final benders = await bending_data.BenderStore.load();
    setState(() {
      _customBenders.clear();
      _customBenders.addAll(benders);
      _updateBrandDropdown();
    });
  }

  void _updateBrandDropdown() {
    final brands = bending_data.getGroupedBenderBrands();
    setState(() {
      _allBrands = [
        ...brands,
        {'type': 'header', 'name': 'SAVED BENDERS'},
        ..._customBenders
            .map((b) => {'type': 'custom_bender', 'name': b.brand}),
      ];
    });
  }

  void _updateSetback() {
    final takeUp = parseInches(takeUpCtl.text);
    final gain = parseInches(gainCtl.text);
    if (takeUp > 0 && gain > 0) setbackCtl.text = fmtInches(takeUp - gain);
  }

  void _updateGainFromRadius() {
    if (_activeController != radiusCtl) return;
    final radiusText = radiusCtl.text.trim();
    if (radiusText.isEmpty || _selectedPipeSize == null) {
      gainCtl.text = '';
      return;
    }
    final radius = parseInches(radiusText);
    final double pipeOD = (_parallelConduitType == 'Rigid'
            ? bending_data
                .grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
            : bending_data
                .emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ??
        0.0;
    if (pipeOD <= 0 || radius <= 0) return;
    gainCtl.text = fmtInches(bending_data.calculateGain90(radius, pipeOD));
  }

  void _updateRadiusFromGain() {
    if (_activeController != gainCtl) return;
    final gainText = gainCtl.text.trim();
    if (gainText.isEmpty || _selectedPipeSize == null) {
      radiusCtl.text = '';
      return;
    }
    final gain = parseInches(gainText);
    final double pipeOD = (_parallelConduitType == 'Rigid'
            ? bending_data
                .grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
            : bending_data
                .emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ??
        0.0;
    if (pipeOD <= 0 || gain <= pipeOD) {
      radiusCtl.text = '';
      return;
    }
    radiusCtl.text = fmtInches(bending_data.calculateCLRFromGain(gain, pipeOD));
  }

  @override
  void dispose() {
    for (var c in [
      distanceCtl,
      offsetHeightCtl,
      rollingVerticalCtl,
      rollingHorizontalCtl,
      overallCtl,
      angleCtl,
      parallelSpacingCtl,
      takeUpCtl,
      gainCtl,
      radiusCtl,
      setbackCtl
    ]) {
      c.dispose();
    }
    _scrollCtl.dispose();
    _infoAnimCtrl.dispose();
    super.dispose();
  }

  void _showKeypad(TextEditingController c, {bool clearFirst = true}) {
    setState(() {
      if (_activeController != c) _commitActiveFieldFormatting();
      _activeController = c;
      if (clearFirst && c.text.isNotEmpty) c.clear();
      _isKeypadVisible = true;
    });
  }

  void _hideKeypad() {
    setState(() {
      _commitActiveFieldFormatting();
      _activeController = null;
      _isKeypadVisible = false;
    });
  }

  void _continueFromMeasurements() {
    _hideKeypad();
    if (!_isCalculateReady) return;

    if (!_isQuickMode) {
      setState(() {
        _currentStep = 2;
        _isMeasurementsExpanded = false;
        _isResultsExpanded = false;
        _showLayoutDirectionCard = true;
        _showBendingMethodCard = true;
        _bendingMethodCardExpanded = true;
      });
      return;
    }

    setState(() {
      _currentStep = 2;
      _isMeasurementsExpanded = false;
      _isResultsExpanded = false;
      _showLayoutDirectionCard = false;
      _showBendingMethodCard = false;
      _bendingMethodCardExpanded = false;
    });
  }

  void _continueFromLayoutDirection() {
    setState(() {
      _currentStep = 2;
      _showLayoutDirectionCard = false;
      _showBendingMethodCard = true;
      _bendingMethodCardExpanded = true;
    });
  }

  void _goBackOneStep() {
    _hideKeypad();

    if (_currentStep >= 3) {
      setState(() {
        _currentStep = 2;
        _isBenderExpanded = false;
        _isMeasurementsExpanded = false;
        _isResultsExpanded = false;
        _showLayoutDirectionCard = false;
        _showBendingMethodCard = !_isQuickMode;
        _bendingMethodCardExpanded = !_isQuickMode;
      });
      return;
    }

    if (_currentStep == 2) {
      if (!_isQuickMode &&
          _showBendingMethodCard &&
          !_showLayoutDirectionCard) {
        setState(() {
          _isBenderExpanded = false;
          _isMeasurementsExpanded = false;
          _isResultsExpanded = false;
          _showLayoutDirectionCard = true;
          _showBendingMethodCard = true;
          _bendingMethodCardExpanded = true;
        });
        return;
      }

      setState(() {
        _currentStep = 1;
        _isBenderExpanded = false;
        _isMeasurementsExpanded = true;
        _isResultsExpanded = false;
        _showLayoutDirectionCard = false;
        _showBendingMethodCard = false;
        _bendingMethodCardExpanded = false;
      });
      return;
    }

    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _isBenderExpanded = true;
        _isMeasurementsExpanded = false;
        _isResultsExpanded = false;
        _showLayoutDirectionCard = false;
        _showBendingMethodCard = false;
      });
      return;
    }

    Navigator.maybePop(context);
  }

  void _advanceFocus() {
    if (_isRollingOffset) {
      if (_activeController == rollingVerticalCtl) {
        _showKeypad(rollingHorizontalCtl);
      } else if (_activeController == rollingHorizontalCtl) {
        _showKeypad(angleCtl);
      } else if (_activeController == angleCtl) {
        if (_isQuickMode) {
          _continueFromMeasurements();
        } else {
          _showKeypad(distanceCtl);
        }
      } else if (_activeController == distanceCtl) {
        if (_useFullStick) {
          _continueFromMeasurements();
        } else {
          _showKeypad(overallCtl);
        }
      } else if (_activeController == overallCtl) {
        _continueFromMeasurements();
      }
    } else {
      if (_activeController == offsetHeightCtl) {
        _showKeypad(angleCtl);
      } else if (_activeController == angleCtl) {
        if (_isQuickMode) {
          _continueFromMeasurements();
        } else {
          _showKeypad(distanceCtl);
        }
      } else if (_activeController == distanceCtl) {
        if (_useFullStick) {
          _continueFromMeasurements();
        } else {
          _showKeypad(overallCtl);
        }
      } else if (_activeController == overallCtl) {
        _continueFromMeasurements();
      }
    }
    if (_activeController == parallelPipeCountCtl) {
      _showKeypad(parallelPipeSizeCtl);
    } else if (_activeController == parallelPipeSizeCtl) {
      _showKeypad(parallelSpacingCtl);
    } else if (_activeController == parallelSpacingCtl) {
      _hideKeypad();
    }
  }

  void _commitActiveFieldFormatting() {
    final c = _activeController;
    if (c == null || c.text.trim().isEmpty) return;
    if (c == angleCtl) {
      final angle = double.tryParse(c.text.replaceAll('°', '').trim()) ?? 0;
      if (angle > 0) c.text = angle.toString().replaceAll('.0', '');
      return;
    }
    final v = parseInches(c.text);
    c.text = v == 0
        ? ''
        : (c == parallelPipeCountCtl
            ? v.toInt().toString()
            : fmtInches(v).replaceAll('"', ''));
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final c = _activeController!;
    final text = c.text;
    if (value == '⌫') {
      if (text.isNotEmpty) c.text = text.substring(0, text.length - 1);
      return;
    }
    if (value == '✔') {
      _advanceFocus();
      return;
    }
    final String cleanValue = value.replaceAll('°', '');
    if (cleanValue.contains('/') && text.isNotEmpty && !text.endsWith(' ')) {
      if (int.tryParse(text[text.length - 1]) != null) c.text += ' ';
    }
    c.text += cleanValue;
  }

  void calculate() {
    final distance = parseInches(distanceCtl.text);

    final angle = parseInches(angleCtl.text);

    final double offsetHeight;
    if (_isRollingOffset) {
      final vertical = parseInches(rollingVerticalCtl.text);
      final horizontal = parseInches(rollingHorizontalCtl.text);
      if (vertical <= 0 || horizontal <= 0) return;
      offsetHeight =
          math.sqrt((vertical * vertical) + (horizontal * horizontal));
    } else {
      offsetHeight = parseInches(offsetHeightCtl.text);
    }

    if (_isQuickMode) {
      if (offsetHeight <= 0 || angle <= 0 || angle >= 90) return;
    } else {
      if (distance <= 0 || offsetHeight <= 0 || angle <= 0 || angle >= 90)
        return;
      if (!_useFullStick && parseInches(overallCtl.text) <= 0) return;
    }

    final offsetLayout = bending_data.calculateOffsetLayout(
      verticalOffset: _isRollingOffset
          ? parseInches(rollingVerticalCtl.text)
          : offsetHeight,
      horizontalRoll:
          _isRollingOffset ? parseInches(rollingHorizontalCtl.text) : 0.0,
      angleDeg: angle,
      distanceToObstruction: distance,
      requestedFinishedOverallLength: parseInches(overallCtl.text),
      layoutDirection: _offsetLayoutDirection,
      useFullStick: _useFullStick,
    );
    final shrink = offsetLayout.shrink;
    final distanceBetweenBends = offsetLayout.distanceBetweenBends;
    final cutLength = offsetLayout.cutLength;
    final finishedOverallLength = offsetLayout.finishedOverallLength;

    // The fields are displayed as field-friendly fractions, but predefined
    // benders retain their exact database values for all calculations.
    final clr = _selectedBenderData?.clr ?? parseInches(radiusCtl.text);
    final takeUp = _selectedBenderData?.deduct ?? parseInches(takeUpCtl.text);
    final gain = _selectedBenderData?.gain ?? parseInches(gainCtl.text);

    final pipeSizeKey = _getNumericalStringPipeSize(_selectedPipeSize ?? '0.5');
    final double pipeOD = (_parallelConduitType == 'Rigid'
            ? bending_data.grcOD[pipeSizeKey]
            : bending_data.emtOD[pipeSizeKey]) ??
        0.706;

    final arrowMarkA = offsetLayout.markA;
    final arrowMarkB = offsetLayout.markB;

    double finalMarkA = arrowMarkA;
    double finalMarkB = arrowMarkB;

    if (!_isArrowMethod && clr > 0) {
      final centerMarks = bending_data.calculateOffsetCenterMarks(
        layout: offsetLayout,
        layoutDirection: _offsetLayoutDirection,
        clr: clr,
        angleDeg: angle,
      );

      finalMarkA = bending_data.convertCenterMarkToBenderReference(
          centerMark: centerMarks.markA,
          method: _bendingMethod,
          clr: clr,
          deduct: takeUp,
          pipeOD: pipeOD,
          angleDeg: angle,
          reverse: _isBenderDirectionReversed);
      finalMarkB = bending_data.convertCenterMarkToBenderReference(
          centerMark: centerMarks.markB,
          method: _bendingMethod,
          clr: clr,
          deduct: takeUp,
          pipeOD: pipeOD,
          angleDeg: angle,
          reverse: _isBenderDirectionReversed);
    }

    setState(() {
      _rawMarkA = finalMarkA;
      _rawMarkB = finalMarkB;
      _rawCut = cutLength;
      _rawTakeUp = takeUp;
      _rawGain = gain;

      markA = fmtInches(finalMarkA);
      markB = fmtInches(finalMarkB);
      markC = fmtInches(cutLength);

      shrinkOut = fmtInches(shrink);
      travelOut = fmtInches(distanceBetweenBends);
      straightFinishOut = fmtInches(finishedOverallLength);
      _activeController = null;
      _isKeypadVisible = false;
      _isMeasurementsExpanded = false;
      _isResultsExpanded = true;
      _showLayoutDirectionCard = false;
      _showBendingMethodCard = !_isQuickMode;
      _bendingMethodCardExpanded = false;
      _showParallelSetup = false;
    });

    Future.delayed(
      const Duration(milliseconds: 50),
      () {
        if (!mounted) return;
        final resultsContext = _resultsSectionKey.currentContext;
        if (resultsContext != null && resultsContext.mounted) {
          Scrollable.ensureVisible(
            resultsContext,
            alignment: 0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  void _startNewBend() {
    setState(() {
      for (var c in [
        distanceCtl,
        offsetHeightCtl,
        rollingVerticalCtl,
        rollingHorizontalCtl,
        overallCtl,
        angleCtl,
        parallelSpacingCtl
      ]) {
        c.clear();
      }
      markA = '';
      markB = '';
      markC = '';
      shrinkOut = '';
      travelOut = '';
      _showParallelSetup = false;
      _isResultsExpanded = false;
      _isMeasurementsExpanded = false;
      _isBenderExpanded = true;
      _showLayoutDirectionCard = false;
      _isKeypadVisible = false;
      _modeTouched = false;
      _typeTouched = false;
      _currentStep = 0;
    });
  }

  void _openRackBuilder() {
    final int count = int.tryParse(parallelPipeCountCtl.text) ?? 3;
    final double spacing = parseInches(parallelSpacingCtl.text);
    final String sizeName = _selectedPipeSize != null
        ? bending_data.pipeSizes[_selectedPipeSize] ?? '1/2"'
        : '1/2"';
    final bending_data.Bender? selectedBender = _selectedBenderData ??
        (_selectedBrand != null && _selectedPipeSize != null
            ? bending_data.Bender(
                brand: _selectedBrand!,
                model: _selectedBrand,
                conduitSize: _selectedPipeSize!,
                conduitType: _parallelConduitType == 'Rigid'
                    ? bending_data.ConduitType.rigid
                    : bending_data.ConduitType.emt,
                clr: parseInches(radiusCtl.text),
                deduct: parseInches(takeUpCtl.text),
                gain: parseInches(gainCtl.text),
              )
            : null);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
                create: (_) => RackState(),
                child: RackBuilderScreen(
                  initialDistance: parseInches(distanceCtl.text),
                  initialOffsetHeight: _isRollingOffset
                      ? parseInches(rollingVerticalCtl.text)
                      : parseInches(offsetHeightCtl.text),
                  initialHorizontalRoll: _isRollingOffset
                      ? parseInches(rollingHorizontalCtl.text)
                      : null,
                  initialOverallLength:
                      _useFullStick ? 120.0 : parseInches(overallCtl.text),
                  initialAngle: double.tryParse(
                          angleCtl.text.replaceAll('°', '').trim()) ??
                      0,
                  initialSpacing: spacing,
                  initialPipeCount: count,
                  initialPipeSizes: List.generate(count, (_) => sizeName),
                  initialFullStick: _useFullStick,
                  boxLayoutConduitType: _parallelConduitType,
                  startInOffsetMode: true,
                  startInRollingOffsetMode: _isRollingOffset,
                  initialDirection: _parallelDirection,
                  initialSpacingIsC2C: !_isSpaceBetweenMode,
                  initialOffsetLayoutDirection: _offsetLayoutDirection,
                  initialBender: selectedBender,
                  initialBendingMethod: _bendingMethod,
                  initialIsArrowMethod: _isArrowMethod,
                  initialBenderDirectionReversed: _isBenderDirectionReversed,
                ))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: true,
        leadingWidth: 96,
        leading: Row(children: [
          IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MainMenuScreen()),
                  (route) => false)),
          IconButton(
            icon: const RotatedBox(
                quarterTurns: 2,
                child: Text("➜",
                    style: TextStyle(
                        color: kLight,
                        fontSize: 26,
                        fontWeight: FontWeight.w900))),
            onPressed: _goBackOneStep,
          ),
        ]),
        title: const Text('Offsets',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showHelpDialog())
        ],
      ),
      body: Column(children: [
        Expanded(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: ListView(controller: _scrollCtl, children: [
                  _buildBenderSection(),
                  const SizedBox(height: 6),
                  _buildMeasurementsSection(),
                  const SizedBox(height: 6),
                  _buildBendingMethodCard(),
                  const SizedBox(height: 6),
                  _buildCalculateSection(),
                  const SizedBox(height: 6),
                  KeyedSubtree(
                      key: _resultsSectionKey, child: _buildResultsSection()),
                ]))),
        if (!_isKeypadVisible && !_isNameEntryMode) _buildInfoBarWidget(),
        if (_isNameEntryMode) AlphaInputKeypad(onTap: _onNameKeyTap),
        if (_isKeypadVisible) NumericInputKeypad(onTap: _onKeypadTap),
      ]),
    );
  }

  Widget _buildInfoBarWidget() {
    String message;
    if (_isResultsExpanded) {
      if (_isQuickMode) {
        message = 'Quick offset complete. Travel and shrink are final.';
      } else if (_isArrowMethod) {
        message =
            'A, B, and C are ready-to-use marks; shrink is included.\nTap Parallel to build the rack.';
      } else {
        message =
            'A, B, and C are ready-to-use marks; all bender adjustments are included.';
      }
    } else if (_showBendingMethodCard &&
        _bendingMethodCardExpanded &&
        _showLayoutDirectionCard) {
      message = _offsetLayoutDirection ==
              bending_data.OffsetLayoutDirection.towardObstruction
          ? 'TOWARD OBSTRUCTION: The entered distance controls the far bend.\nShrink is included when positioning that layout mark.'
          : 'PAST OBSTRUCTION: The entered distance controls the start of the first bend.\nThe second bend is one travel distance farther.';
    } else if (_showBendingMethodCard && _bendingMethodCardExpanded) {
      final bool isMachineBender =
          bending_data.mechanicalElectricBenderBrands.contains(_selectedBrand);
      if (isMachineBender) {
        message =
            'USE HOOK: Translates center-of-bend to machine hook.\nUSE CENTERLINE: For shoes with custom center marks.';
      } else {
        message =
            'USE NOTCH: Translates center-of-bend to hand bender notch.\nUSE CENTERLINE: For shoes with center marks.';
      }
    } else if (_currentStep == 0) {
      message =
          'Select your bender and pipe size, or tap Skip to use standard Arrow marks.';
    } else if (_currentStep == 1) {
      message =
          'Enter offset height and bend angle. Accuracy depends on your measurements.';
    } else {
      message = 'Generate results to see layout marks.';
    }

    final bool compactResultsBar = _isResultsExpanded;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(4, compactResultsBar ? 4 : 8, 4, 0),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compactResultsBar ? 3 : 16,
      ),
      constraints: BoxConstraints(minHeight: compactResultsBar ? 0 : 125),
      decoration: BoxDecoration(
        color: kBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.4),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: kLight,
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildBenderSection() {
    return _buildGroupContainer(
        child: Column(children: [
      _buildSilverButton(
          label: '1. BENDER & CONDUIT',
          fontSize: 19,
          height: 60,
          isActive: _currentStep == 0,
          onTap: () => setState(() {
                _currentStep = 0;
                _isBenderExpanded = !_isBenderExpanded;
                if (_isBenderExpanded) {
                  _isMeasurementsExpanded = false;
                  _isResultsExpanded = false;
                  _showLayoutDirectionCard = false;
                  _showBendingMethodCard = false;
                }
              })),
      if (_isBenderExpanded)
        Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(children: [
              _buildBrandSelector(),
              const SizedBox(height: 6),
              _buildConduitTypeSelector(),
              const SizedBox(height: 6),
              _buildPipeSizeSelector(),
              if (!_isBenderSetupComplete) ...[
                const SizedBox(height: 6),
                _buildSilverButton(
                    label: 'SKIP BENDER INFO',
                    height: 40,
                    onTap: () => setState(() {
                          _selectedBrand = null;
                          _selectedPipeSize = null;
                          _selectedBenderData = null;
                          _isArrowMethod = true;
                          _bendingMethod =
                              bending_data.BendingMethod.centerline;
                          _currentStep = 1;
                          _isBenderExpanded = false;
                          _isMeasurementsExpanded = true;
                        }))
              ],
              if (_isBenderSetupComplete) ...[
                const SizedBox(height: 10),
                _inlineField('Take Up', takeUpCtl, suffix: '"', readOnly: true),
                _inlineField('Gain90', gainCtl, suffix: '"', readOnly: true),
                _inlineField('Radius / CLR', radiusCtl,
                    suffix: '"', readOnly: true),
                const SizedBox(height: 10),
                _buildSilverButton(
                    label: 'DONE',
                    height: 44,
                    isActive: true,
                    isCheckmark: true,
                    onTap: () => setState(() {
                          _currentStep = 1;
                          _isBenderExpanded = false;
                          _isMeasurementsExpanded = true;
                        }))
              ]
            ]))
    ]));
  }

  Widget _buildBrandSelector() {
    return GestureDetector(
      onTap: _showBrandPicker,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC0C0C0), width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedBrand ?? 'Select Bender Brand',
                style: TextStyle(
                  color: (_selectedBrand == null) ? Colors.white70 : kLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildConduitTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSilverButton(
            label: 'EMT',
            height: 40,
            isActive: _parallelConduitType == 'EMT',
            onTap: () {
              setState(() => _parallelConduitType = 'EMT');
              _updateBenderData();
            },
          ),
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: _buildSilverButton(
            label: 'RIGID',
            height: 40,
            isActive: _parallelConduitType == 'Rigid',
            onTap: () {
              setState(() => _parallelConduitType = 'Rigid');
              _updateBenderData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPipeSizeSelector() {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        color: const Color(0xFF151515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFC8C8C8), width: 1.5),
        ),
        onSelected: (newValue) {
          setState(() => _selectedPipeSize = newValue);
          _updateBenderData();
        },
        itemBuilder: (context) {
          final sizes = bending_data.getFilteredPipeSizes(_selectedBrand);
          return sizes.keys.map((String value) {
            final bool selected = value == _selectedPipeSize;
            return PopupMenuItem<String>(
              value: value,
              height: 44,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  bending_data.pipeSizes[value]!,
                  style: const TextStyle(
                      color: kLight, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC0C0C0), width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedPipeSize == null
                      ? 'Select Pipe Size'
                      : (bending_data.pipeSizes[_selectedPipeSize] ?? ''),
                  style: TextStyle(
                    color: _selectedPipeSize == null ? Colors.white70 : kLight,
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
    );
  }

  Widget _buildMeasurementsSection() {
    final bool canOpen =
        _selectedBrand == null || _isBenderSetupComplete || _currentStep >= 1;
    return _buildGroupContainer(
        child: Column(children: [
      _buildSilverButton(
          label: '2. OFFSET MEASUREMENTS',
          fontSize: 19,
          height: 60,
          isActive: _currentStep == 1,
          onTap: canOpen
              ? () => setState(() {
                    _currentStep = 1;
                    _isMeasurementsExpanded = !_isMeasurementsExpanded;
                    if (_isMeasurementsExpanded) {
                      _isBenderExpanded = false;
                      _isResultsExpanded = false;
                      _showLayoutDirectionCard = false;
                      _showBendingMethodCard = false;
                    }
                  })
              : null),
      if (_isMeasurementsExpanded)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: _buildChoiceButton(
                        label: 'Quick',
                        selected: _isQuickMode,
                        touched: _modeTouched,
                        onTap: () => setState(() {
                              _isQuickMode = true;
                              _modeTouched = true;
                            }))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildChoiceButton(
                        label: 'Full',
                        selected: !_isQuickMode,
                        touched: _modeTouched,
                        onTap: () => setState(() {
                              _isQuickMode = false;
                              _modeTouched = true;
                            }))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _buildChoiceButton(
                        label: 'Standard Offset',
                        selected: !_isRollingOffset,
                        touched: _typeTouched,
                        onTap: () => setState(() {
                              _isRollingOffset = false;
                              _showParallelSetup = false;
                              _typeTouched = true;
                            }))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildChoiceButton(
                        label: 'Rolling Offset',
                        selected: _isRollingOffset,
                        touched: _typeTouched,
                        onTap: () => setState(() {
                              _isRollingOffset = true;
                              _showParallelSetup = false;
                              _typeTouched = true;
                            }))),
              ]),
              const SizedBox(height: 10),
              if (_isRollingOffset) ...[
                _inlineField('Vertical Offset', rollingVerticalCtl,
                    suffix: '"', onTap: () => _showKeypad(rollingVerticalCtl)),
                _inlineField('Horizontal Roll', rollingHorizontalCtl,
                    suffix: '"',
                    onTap: () => _showKeypad(rollingHorizontalCtl)),
              ] else ...[
                _inlineField('Offset Height', offsetHeightCtl,
                    suffix: '"', onTap: () => _showKeypad(offsetHeightCtl)),
              ],
              _inlineField('Bend Angle', angleCtl,
                  suffix: '°', onTap: () => _showKeypad(angleCtl)),
              if (!_isQuickMode) ...[
                _inlineField('Distance to Obstruction', distanceCtl,
                    suffix: '"', onTap: () => _showKeypad(distanceCtl)),
                const SizedBox(height: 8),
                Row(children: [
                  const Expanded(
                      child: Text('Full Stick (10ft)?',
                          style: TextStyle(color: kLight, fontSize: 16))),
                  _buildChoiceButton(
                    label: 'YES',
                    width: 70,
                    height: 34,
                    fontSize: 12,
                    selected: _useFullStick,
                    touched: true,
                    onTap: () => setState(() {
                      _useFullStick = true;
                      overallCtl.clear();
                      _updateCalculateReady();
                    }),
                  ),
                  const SizedBox(width: 8),
                  _buildChoiceButton(
                    label: 'NO',
                    width: 70,
                    height: 34,
                    fontSize: 12,
                    selected: !_useFullStick,
                    touched: true,
                    onTap: () => setState(() {
                      _useFullStick = false;
                      _updateCalculateReady();
                    }),
                  ),
                ]),
                if (!_useFullStick) ...[
                  const SizedBox(height: 4),
                  _inlineField('Finished Overall Length', overallCtl,
                      suffix: '"', onTap: () => _showKeypad(overallCtl)),
                ],
              ],
              if (_isCalculateReady) ...[
                const SizedBox(height: 10),
                _buildSilverButton(
                    label: _selectedBrand == null ? 'DONE' : 'CONTINUE',
                    height: 44,
                    isActive: true,
                    onTap: () {
                      _continueFromMeasurements();
                    })
              ]
            ]))
    ]));
  }

  Widget _buildBendingMethodCard() {
    final bool canOpen =
        _currentStep >= 2 && !_isQuickMode && _showBendingMethodCard;
    final bool hasBenderData = _isBenderSetupComplete;
    final bool isMachineBender = _selectedBrand != null &&
        bending_data.mechanicalElectricBenderBrands.contains(_selectedBrand);
    return _buildGroupContainer(
        child: Column(children: [
      _buildSilverButton(
          label: '3. BENDING METHOD',
          fontSize: 19,
          height: 60,
          isActive: _currentStep == 2 && canOpen,
          onTap: canOpen
              ? () => setState(() {
                    _currentStep = 2;
                    _isBenderExpanded = false;
                    _isMeasurementsExpanded = false;
                    _isResultsExpanded = false;
                    _bendingMethodCardExpanded = !_bendingMethodCardExpanded;
                  })
              : null),
      if (_bendingMethodCardExpanded) ...[
        const SizedBox(height: 6),
        if (_showLayoutDirectionCard) ...[
          Row(children: [
            Expanded(
                child: _buildChoiceButton(
                    label: 'TOWARD OBSTRUCTION',
                    selected: _offsetLayoutDirection ==
                        bending_data.OffsetLayoutDirection.towardObstruction,
                    touched: true,
                    fontSize: 12,
                    onTap: () => setState(() => _offsetLayoutDirection =
                        bending_data.OffsetLayoutDirection.towardObstruction))),
            const SizedBox(width: 6),
            Expanded(
                child: _buildChoiceButton(
                    label: 'PAST OBSTRUCTION',
                    selected: _offsetLayoutDirection ==
                        bending_data.OffsetLayoutDirection.pastObstruction,
                    touched: true,
                    fontSize: 12,
                    onTap: () => setState(() => _offsetLayoutDirection =
                        bending_data.OffsetLayoutDirection.pastObstruction))),
          ]),
          const SizedBox(height: 8),
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  _offsetLayoutDirection ==
                          bending_data.OffsetLayoutDirection.towardObstruction
                      ? 'Toward: the entered distance controls the far bend near the obstruction; shrink is included in its layout location.'
                      : 'Past: the entered distance controls the start of the first bend; shrink is not added to that mark, and the second bend is one travel distance farther.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.3))),
          const SizedBox(height: 8),
          _buildSilverButton(
              label: 'CONTINUE',
              height: 44,
              isActive: true,
              isCheckmark: true,
              onTap: _continueFromLayoutDirection),
        ] else ...[
          Row(children: [
            Expanded(
                child: _buildSilverButton(
                    label: 'ARROW',
                    height: 40,
                    isActive: _isArrowMethod,
                    onTap: () => setState(() {
                          _isArrowMethod = true;
                          _bendingMethod =
                              bending_data.BendingMethod.centerline;
                        }))),
            const SizedBox(width: 4),
            Expanded(
                child: _buildSilverButton(
                    label: isMachineBender ? 'HOOK' : 'NOTCH',
                    height: 40,
                    isActive: hasBenderData &&
                        !_isArrowMethod &&
                        (_bendingMethod == bending_data.BendingMethod.notch ||
                            _bendingMethod == bending_data.BendingMethod.hook),
                    onTap: hasBenderData
                        ? () => setState(() {
                              _isArrowMethod = false;
                              _bendingMethod = isMachineBender
                                  ? bending_data.BendingMethod.hook
                                  : bending_data.BendingMethod.notch;
                            })
                        : null)),
            const SizedBox(width: 4),
            Expanded(
                child: _buildSilverButton(
                    label: '℄ LINE',
                    height: 40,
                    isActive: hasBenderData &&
                        !_isArrowMethod &&
                        _bendingMethod == bending_data.BendingMethod.centerline,
                    onTap: hasBenderData
                        ? () => setState(() {
                              _isArrowMethod = false;
                              _bendingMethod =
                                  bending_data.BendingMethod.centerline;
                            })
                        : null)),
          ]),
          const SizedBox(height: 8),
          if (!_isArrowMethod) ...[
            Row(children: [
              const Expanded(
                  child: Text('Bender Orientation',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold))),
              _buildChoiceButton(
                  label: 'FORWARD',
                  width: 90,
                  height: 34,
                  fontSize: 12,
                  selected: !_isBenderDirectionReversed,
                  touched: true,
                  onTap: () =>
                      setState(() => _isBenderDirectionReversed = false)),
              const SizedBox(width: 4),
              _buildChoiceButton(
                  label: 'REVERSE',
                  width: 90,
                  height: 34,
                  fontSize: 12,
                  selected: _isBenderDirectionReversed,
                  touched: true,
                  onTap: () =>
                      setState(() => _isBenderDirectionReversed = true)),
            ]),
            const SizedBox(height: 8),
          ],
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  hasBenderData
                      ? _getBendingMethodExplanation()
                      : 'No bender data was selected. Standard Arrow marks will be used.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.3))),
        ],
      ]
    ]));
  }

  Widget _buildCalculateSection() {
    final bool showCalculate = _currentStep == 2 &&
        (_isQuickMode || (_showBendingMethodCard && !_showLayoutDirectionCard));
    final bool isActive = showCalculate;
    return _buildGroupContainer(
        child: _buildSilverButton(
            label: '4. CALCULATE',
            isActive: isActive,
            isCheckmark: isActive,
            height: 60,
            fontSize: 20,
            onTap: isActive
                ? () {
                    _hideKeypad();
                    setState(() {
                      _currentStep = 3;
                      _showLayoutDirectionCard = false;
                      _showBendingMethodCard = !_isQuickMode;
                      _bendingMethodCardExpanded = false;
                    });
                    calculate();
                  }
                : null));
  }

  Widget _buildResultsSection() {
    final bool canOpen = _currentStep >= 3;
    return _buildGroupContainer(
        child: Column(children: [
      _buildSilverButton(
          label: '5. RESULTS',
          fontSize: 20,
          height: 60,
          isActive: _currentStep == 3,
          onTap: canOpen
              ? () => setState(() {
                    _currentStep = 3;
                    _isResultsExpanded = !_isResultsExpanded;
                    if (_isResultsExpanded) {
                      _isBenderExpanded = false;
                      _isMeasurementsExpanded = false;
                      _showLayoutDirectionCard = false;
                      _showBendingMethodCard = !_isQuickMode;
                      _bendingMethodCardExpanded = false;
                    }
                  })
              : null),
      if (_isResultsExpanded)
        Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Column(children: [
              _buildOffsetExtras(),
              if (!_isQuickMode) _offsetMarksCard(),
              if (!_isQuickMode) ...[
                const SizedBox(height: 8),
                _OffsetResultGraphic(
                    markB: markB,
                    markA: markA,
                    markC: markC,
                    isBenderDirectionReversed: _isBenderDirectionReversed),
                const SizedBox(height: 12)
              ],
              if (_isQuickMode)
                _buildSilverButton(
                    label: 'Start New Bend', height: 44, onTap: _startNewBend)
              else
                Row(children: [
                  Expanded(
                      child: _buildSilverButton(
                          label: 'Start New Bend',
                          height: 44,
                          onTap: _startNewBend)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildSilverButton(
                          label: 'Parallel',
                          height: 44,
                          isActive: _showParallelSetup,
                          onTap: () {
                            setState(() {
                              _showParallelSetup = !_showParallelSetup;
                              _activeController = null;
                              _isKeypadVisible = false;
                            });
                            if (!_showParallelSetup) return;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Future.delayed(const Duration(milliseconds: 200),
                                  () {
                                if (_scrollCtl.hasClients)
                                  _scrollCtl.animateTo(
                                      _scrollCtl.position.maxScrollExtent,
                                      duration:
                                          const Duration(milliseconds: 500),
                                      curve: Curves.easeOut);
                              });
                            });
                          })),
                ]),
              if (_showParallelSetup) ...[
                const SizedBox(height: 8),
                _parallelSetupCard()
              ],
            ]))
    ]));
  }

  void _showHelpDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF2C3030),
                title: const Text('Offset Info',
                    style:
                        TextStyle(color: kLight, fontWeight: FontWeight.bold)),
                content: const SingleChildScrollView(
                    child: Text(
                        'Quick mode:\nUse this when you only need offset size, bend angle, distance between bends, and shrink.\n\nFull mode:\nUse this when you need layout marks A, B, and C.\n\nStandard Offset:\nUses offset height and bend angle.\n\nRolling Offset:\nUses vertical offset + horizontal roll to calculate the true offset.',
                        style: TextStyle(color: kLight, height: 1.45))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close', style: TextStyle(color: kRed)))
                ]));
  }

  String _getBendingMethodExplanation() {
    if (_isArrowMethod)
      return 'USE ARROW: Standard geometric center marks. Align your bender arrow with the marks on the pipe.';
    switch (_bendingMethod) {
      case bending_data.BendingMethod.centerline:
        return 'USE CENTERLINE: Uses center-of-bend markings you have made on the shoe.';
      case bending_data.BendingMethod.notch:
        return 'USE NOTCH: Translates center-of-bend measurements to the 45° notch / teardrop on your hand bender.';
      case bending_data.BendingMethod.hook:
        return 'USE HOOK: Translates center-of-bend measurements to the front edge of the machine bender hook.';
    }
  }

  void _onNameKeyTap(String value) {
    if (value == '⌫') {
      if (_customBenderName.isNotEmpty)
        setState(() => _customBenderName =
            _customBenderName.substring(0, _customBenderName.length - 1));
      return;
    }
    if (value == 'CLEAR') {
      setState(() => _customBenderName = '');
      return;
    }
    if (value == '✔') {
      _finishSaveCustomBender();
      return;
    }
    if (_customBenderName.length < 24)
      setState(() => _customBenderName += value);
  }

  void _finishSaveCustomBender() {
    final name = _customBenderName.trim();
    if (name.isEmpty) return;
    final newBender = bending_data.Bender(
        brand: name,
        model: name,
        conduitSize: _selectedPipeSize ?? '0.5',
        conduitType: _parallelConduitType == 'Rigid'
            ? bending_data.ConduitType.rigid
            : bending_data.ConduitType.emt,
        clr: parseInches(radiusCtl.text),
        deduct: parseInches(takeUpCtl.text),
        gain: parseInches(gainCtl.text));
    setState(() {
      _customBenders.add(newBender);
      bending_data.BenderStore.save(newBender);
      _updateBrandDropdown();
      _selectedBrand = name;
      _isNameEntryMode = false;
      _customBenderName = '';
    });
    _updateBenderData();
    _hideKeypad();
  }

  void _showBrandPicker() {
    final brands = bending_data.getGroupedBenderBrands();
    showDialog(
        context: context,
        builder: (context) => BenderPickerDialog(
            allBrands: brands,
            selectedBrand: _selectedBrand,
            onSelected: (name) {
              setState(() => _selectedBrand = name);
              _updateBenderData();
            }));
  }

  void _updateBenderData() {
    if (_selectedBrand == null || _selectedPipeSize == null) return;
    final type = _parallelConduitType == 'Rigid'
        ? bending_data.ConduitType.rigid
        : bending_data.ConduitType.emt;
    final bender = <bending_data.Bender>[
      ...bending_data.benderDatabase,
      ..._customBenders,
    ].firstWhereOrNull((b) =>
        b.brand == _selectedBrand &&
        b.conduitSize == _selectedPipeSize &&
        b.conduitType == type);
    if (bender != null) {
      setState(() {
        _selectedBenderData = bender;
        takeUpCtl.text = RackState.inchFmt(bender.deduct, addInchMark: false);
        gainCtl.text = RackState.inchFmt(bender.gain, addInchMark: false);
        radiusCtl.text = RackState.inchFmt(bender.clr, addInchMark: false);
      });
    } else {
      _selectedBenderData = null;
    }
  }

  Widget _buildOffsetExtras() {
    if (travelOut.isEmpty) {
      return const SizedBox.shrink();
    }

    final double offsetSize = _isRollingOffset
        ? math.sqrt(
            math.pow(parseInches(rollingVerticalCtl.text), 2) +
                math.pow(parseInches(rollingHorizontalCtl.text), 2),
          )
        : parseInches(offsetHeightCtl.text);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8C8C8),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _cleanResultRow(
            'Offset Size',
            fmtInches(offsetSize),
          ),
          const SizedBox(height: 6),
          _cleanResultRow(
            'Bend Angle',
            '${angleCtl.text.replaceAll('°', '').trim()}°',
          ),
          const SizedBox(height: 6),
          _cleanResultRow(
            'Distance Between Bends',
            travelOut,
          ),
          const SizedBox(height: 6),
          _cleanResultRow(
            'Shrink',
            shrinkOut,
          ),
          const SizedBox(height: 6),
          _cleanResultRow(
            _useFullStick ? 'Actual Finish Distance' : 'Overall Length',
            straightFinishOut,
          ),
        ],
      ),
    );
  }

  Widget _parallelSetupCard() {
    return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
            color: Colors.black.withAlpha(180),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Parallel Setup',
              style: TextStyle(
                  color: kLight, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _inlineField('Pipe Count', parallelPipeCountCtl, suffix: null,
              onTap: () {
            _showKeypad(parallelPipeCountCtl, clearFirst: true);
          }),
          const SizedBox(height: 4),
          _inlineField('Spacing', parallelSpacingCtl, suffix: '"', onTap: () {
            _showKeypad(parallelSpacingCtl, clearFirst: true);
          }),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
                child: _buildChoiceButton(
              label: 'Space Between',
              height: 44,
              fontSize: 14,
              selected: _isSpaceBetweenMode,
              touched: true,
              onTap: () => setState(() => _isSpaceBetweenMode = true),
            )),
            const SizedBox(width: 4),
            Expanded(
                child: _buildChoiceButton(
              label: 'Center to Center',
              height: 44,
              fontSize: 14,
              selected: !_isSpaceBetweenMode,
              touched: true,
              onTap: () => setState(() => _isSpaceBetweenMode = false),
            )),
          ]),
          const SizedBox(height: 8),
          Center(
              child: Text(
                  _isRollingOffset
                      ? 'RACK PROGRESSION DIRECTION'
                      : 'OFFSET DIRECTION',
                  style: const TextStyle(
                      color: kLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w900))),
          const SizedBox(height: 6),
          if (_isRollingOffset)
            Row(children: [
              Expanded(child: _directionArrow(2, -1)), // Left
              const SizedBox(width: 4),
              Expanded(child: _directionArrow(0, 1)), // Right
            ])
          else
            Row(children: [
              Expanded(
                  child: Column(children: [
                _directionArrow(2, -1), // Left
                const SizedBox(height: 4),
                _directionArrow(1, 2), // Down
              ])),
              const SizedBox(width: 4),
              Expanded(
                  child: Column(children: [
                _directionArrow(-1, 0), // Up
                const SizedBox(height: 4),
                _directionArrow(0, 1), // Right
              ])),
            ]),
          const SizedBox(height: 8),
          const Center(
              child: Text('3-7-10 Support Rule Aware',
                  style: TextStyle(
                      color: kGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          _buildSilverButton(
            label: 'SHOW RESULTS',
            height: 60,
            fontSize: 20,
            isActive: parallelSpacingCtl.text.trim().isNotEmpty &&
                parallelPipeCountCtl.text.trim().isNotEmpty &&
                (!_isRollingOffset ||
                    _parallelDirection == -1 ||
                    _parallelDirection == 1),
            onTap: (!_isRollingOffset ||
                    _parallelDirection == -1 ||
                    _parallelDirection == 1)
                ? _openRackBuilder
                : null,
          ),
        ]));
  }

  Widget _directionArrow(int turns, int val) {
    final active = _parallelDirection == val;
    return GestureDetector(
        onTap: () => setState(() => _parallelDirection = val),
        child: Container(
            height: 50,
            decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFF8A1010), Color(0xFFD12A2A)])
                    : const LinearGradient(
                        colors: [Color(0xFF3A3A3D), Color(0xFF1F1F21)]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: active ? kRed : const Color(0xFF8C8C8C),
                    width: active ? 2.0 : 1.2)),
            child: RotatedBox(
                quarterTurns: turns,
                child: const Center(
                    child: Text("➜",
                        style: TextStyle(
                            color: kLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w900))))));
  }

  Widget _offsetMarksCard() {
    return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
            color: Colors.black.withAlpha(180),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5)),
        child: Column(children: [
          _cleanResultRow('Mark A', markA),
          const SizedBox(height: 6),
          _cleanResultRow('Mark B', markB),
          const SizedBox(height: 6),
          _cleanResultRow('Mark C (Cut)', markC, isCut: true)
        ]));
  }

  Widget _cleanResultRow(String label, String value, {bool isCut = false}) {
    return Row(children: [
      Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 17,
                  fontWeight: FontWeight.w700))),
      Container(
          width: 132,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCut
                      ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
                      : const [Color(0xFF5A5A5F), Color(0xFF2C3030)]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD0D0D0), width: 1.2)),
          child: Text(value.isEmpty ? '—' : value,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900))),
    ]);
  }

  Widget _buildGroupContainer({required Widget child, bool showBorder = true}) {
    return Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: showBorder
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5))
            : null,
        child: child);
  }

  Widget _buildSilverButton(
      {required String label,
      VoidCallback? onTap,
      bool isActive = false,
      bool redOutline = false,
      bool isCheckmark = false,
      double height = 44,
      double fontSize = 15}) {
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
                        : [Colors.grey.shade800, Colors.grey.shade900])),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: redOutline ? kRed : const Color(0xFF9E9E9E),
                width: redOutline ? 2.0 : 1.1)),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color:
                              isEnabled ? Colors.white : Colors.grey.shade500,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700)),
                  if (isCheckmark) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: kGreen, size: 20)
                  ]
                ])))));
  }

  Widget _buildChoiceButton(
      {required String label,
      required bool selected,
      required bool touched,
      required VoidCallback onTap,
      double height = 44,
      double? width,
      double fontSize = 15}) {
    final bool showFilled = selected && touched;
    return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
            gradient: showFilled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8A1010), Color(0xFFE53935)])
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3A3A3D), Color(0xFF1F1F21)]),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? kRed : const Color(0xFF9E9E9E),
                width: selected ? 2.0 : 1.2)),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Center(
                    child: Text(label,
                        style: TextStyle(
                            color: kLight,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w800))))));
  }

  Widget _inlineField(String label, TextEditingController c,
      {VoidCallback? onTap, String? suffix, bool readOnly = false}) {
    final bool isActive = _activeController == c;
    final bool effectiveReadOnly = readOnly || onTap == null;
    final bool greenInput = !effectiveReadOnly &&
        [offsetHeightCtl, rollingVerticalCtl, rollingHorizontalCtl,
          angleCtl, distanceCtl, overallCtl].contains(c);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 16, color: kLight))),
          const SizedBox(width: 12),
          SizedBox(
              width: 152,
              height: 48,
              child: GestureDetector(
                  onTap: effectiveReadOnly ? null : onTap,
                  child: AbsorbPointer(
                      child: TextField(
                          controller: c,
                          readOnly: true,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 18, color: kLight),
                          decoration: InputDecoration(
                              suffixText: suffix,
                              suffixStyle:
                                  const TextStyle(fontSize: 18, color: kLight),
                              isDense: true,
                              filled: true,
                              fillColor: isActive
                                  ? (greenInput ? const Color(0xFF0A1A0A) : const Color(0xFF1A0A0A))
                                  : Colors.black,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 10),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: greenInput ? kGreen : isActive
                                          ? kRed
                                          : const Color(0xFFC8C8C8),
                                      width: isActive ? 2.0 : 1.3)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: greenInput ? kGreen : kRed, width: 2)))))))
        ]));
  }

  String _getNumericalStringPipeSize(String s) => parseInches(s).toString();

  static String fmtInches(double x) {
    if (x.isNaN || x.isInfinite || x < 0) return '0"';
    final int whole = x.floor();
    final double remainder = x - whole;
    int sixteenths = (remainder * 16).round();
    if (sixteenths == 16) return '${whole + 1}"';
    if (sixteenths == 0) return '$whole"';
    int num = sixteenths;
    int den = 16;
    while (num % 2 == 0 && den > 2) {
      num ~/= 2;
      den ~/= 2;
    }
    if (whole == 0) return '$num/$den"';
    return '$whole $num/$den"';
  }

  static double parseInches(String input) {
    input = input.replaceAll('"', '').trim();
    if (input.isEmpty) return 0.0;
    final parts = input.split(' ');
    if (parts.length == 1)
      return parts.first.contains('/')
          ? _parseFraction(parts.first)
          : (double.tryParse(parts.first) ?? 0.0);
    return (double.tryParse(parts.first) ?? 0.0) + _parseFraction(parts.last);
  }

  static double _parseFraction(String fraction) {
    final fracParts = fraction.split('/');
    if (fracParts.length != 2) return 0.0;
    final num = double.tryParse(fracParts.first) ?? 0.0;
    final den = double.tryParse(fracParts.last) ?? 1.0;
    return den == 0 ? 0.0 : num / den;
  }
}

class _OffsetResultGraphic extends StatelessWidget {
  const _OffsetResultGraphic(
      {required this.markB,
      required this.markA,
      required this.markC,
      required this.isBenderDirectionReversed});
  final String markB, markA, markC;
  final bool isBenderDirectionReversed;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC8C8C8), width: 1.5)),
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(
              left: 6,
              right: 6,
              bottom: 44,
              child: Image.asset('assets/conduits/emt/pipe_5_ol.png',
                  fit: BoxFit.contain, filterQuality: FilterQuality.high)),
          _downMark(w * .15, 8, 'C', markC),
          _downMark(w * 0.45, 8, 'A', markA),
          _downMark(w * 0.74, 8, 'B', markB),
          Positioned(
            bottom: 4,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isBenderDirectionReversed ? 'Hook Faces ➜' : '⬅ Hook Faces',
                  style: TextStyle(
                    color: isBenderDirectionReversed
                        ? Colors.orangeAccent
                        : kLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Measure from this end',
                      style: TextStyle(
                        color: kLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "➜",
                      style: TextStyle(
                        color: kLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]);
      }),
    );
  }

  Widget _downMark(double x, double top, String label, String value) {
    return Positioned(
        left: x - 56,
        top: top,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 112,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.black.withAlpha(210),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFD0D0D0), width: 1.1)),
              child: Text('$label: ${value.isEmpty ? "—" : value}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                      color: kLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w800))),
          const SizedBox(height: 2),
          const RotatedBox(
              quarterTurns: 1,
              child: Text("➜",
                  style: TextStyle(
                      color: kLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w900))),
        ]));
  }
}
