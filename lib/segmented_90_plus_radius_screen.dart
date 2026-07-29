import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:pipe_and_wire_clean/radius_arc_finder_screen.dart';
import 'main_menu_screen.dart';
import 'code_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Segmented90PlusRadiusScreen(),
    ),
  );
}

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);

enum BoxLayoutConduitType { emt, grc }
enum SegmentedMode { arcOnly, stubbed90 }
enum ArcInputMode { boxToBox, arcAngle }
enum SurfaceFollowed { inside, outside }
enum SupportType { surface, strut }
enum StrutSizeOption { sevenEighths, oneAndFiveEighths, custom }

class Segmented90PlusRadiusScreen extends StatefulWidget {
  const Segmented90PlusRadiusScreen({super.key});

  @override
  State<Segmented90PlusRadiusScreen> createState() =>
      _Segmented90PlusRadiusScreenState();
}

class _Segmented90PlusRadiusScreenState
    extends State<Segmented90PlusRadiusScreen> with TickerProviderStateMixin {
  // Workflow state
  int _currentStep = 0;
  bool _isBenderExpanded = true;
  bool _isRadiusExpanded = false;
  bool _isDetailsExpanded = false;
  bool _isResultsExpanded = false;
  bool _isCalculateReady = false;
  SegmentedMode _segmentedMode = SegmentedMode.arcOnly;
  ArcInputMode _arcInputMode = ArcInputMode.boxToBox;

  late AnimationController _infoAnimCtrl;

  // Bender & conduit state
  BoxLayoutConduitType _selectedConduitType = BoxLayoutConduitType.emt;
  String? _selectedPipeSize;

// Surface-followed / support logic
  SurfaceFollowed _surfaceFollowed = SurfaceFollowed.inside;
  SupportType _supportType = SupportType.surface;
  StrutSizeOption _strutSizeOption = StrutSizeOption.oneAndFiveEighths;
  // Radius-from-length lock state
  bool _radiusWasGeneratedFromLength = false;
  double? _lockedPipeLength;
  double? _lockedArcAngleDeg;
  bool _showPipeLengthHelper = false;
  // Controllers
  final measurement1Ctrl = TextEditingController(); // Stub Height / Arc Box-to-Box Length
  final measurement2Ctrl = TextEditingController(); // Number of Shots
  final measurement3Ctrl = TextEditingController(); // Straight Before Bend (optional)
  final customStandoffCtrl = TextEditingController();
  final radiusCtrl = TextEditingController();
  final boxToBoxCtrl = TextEditingController(); // Arc Only total run / box-to-box length
  final arcAngleCtrl = TextEditingController();

  // Radius-from-pipe-length popup controllers
  final pipeLengthRadiusCtrl = TextEditingController();
  final pipeLengthArcAngleCtrl = TextEditingController();
  // Output variables
  String markAOut = '';
  String markBOut = '';
  String markCOut = '';
  String spacingOut = '';
  String shotsOut = '';
  String anglePerShotOut = '';

// Arc Only output variables
  String boxToBoxOut = '';
  String arcAngleOut = '';
  String recommendedBendAngleOut = '';
  String sticksRequiredOut = '';
  String firstOffsetOut = '';
  String bendsFirstStickOut = '';
  String lastBendFromEndOut = '';
  String finalStickCutOut = '';
  String option3Out = '';
  String option4Out = '';
  String option5Out = '';
  String option6Out = '';
  bool _showArcOptions = false;
  double? _selectedArcOptionDeg;

  Map<String, dynamic>? _arcOption3;
  Map<String, dynamic>? _arcOption4;
  Map<String, dynamic>? _arcOption5;
  Map<String, dynamic>? _arcOption6;
  // Keypad state
  bool _isKeypadVisible = false;
  TextEditingController? _activeController;
  bool _isNameEntryMode = false;
  String _customBenderName = '';

  bool _hasViewedInfo = false;

  @override
  void initState() {
    super.initState();
    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    final allInputCtrls = [
      measurement1Ctrl,
      measurement2Ctrl,
      measurement3Ctrl,
      radiusCtrl,
      boxToBoxCtrl,
      arcAngleCtrl,
      customStandoffCtrl,
    ];
    for (var ctrl in allInputCtrls) {
      ctrl.addListener(_updateCalculateButtonState);
    }
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    final allCtrls = [
      measurement1Ctrl,
      measurement2Ctrl,
      measurement3Ctrl,
      radiusCtrl,
      boxToBoxCtrl,
      arcAngleCtrl,
      pipeLengthRadiusCtrl,
      pipeLengthArcAngleCtrl,
    ];

    for (var ctrl in allCtrls) {
      ctrl.removeListener(_updateCalculateButtonState);
      ctrl.dispose();
    }

    super.dispose();
  }

  void _updateCalculateButtonState() {
    final bool hasRadius = radiusCtrl.text.isNotEmpty;
    final bool hasPipeSize = _selectedPipeSize != null;

    final bool isStubMode = _segmentedMode == SegmentedMode.stubbed90;
    
    final bool hasShots = measurement2Ctrl.text.isNotEmpty;
    final bool hasStub = measurement1Ctrl.text.isNotEmpty;

    final bool hasArcLength = boxToBoxCtrl.text.isNotEmpty;
    final bool hasArcAngle = arcAngleCtrl.text.isNotEmpty;

    final bool hasArcInput = _segmentedMode == SegmentedMode.arcOnly
        ? (_arcInputMode == ArcInputMode.boxToBox ? hasArcLength : hasArcAngle)
        : true;

    final bool isReady = hasRadius &&
        hasPipeSize &&
        (!isStubMode || (hasShots && hasStub)) &&
        (_segmentedMode != SegmentedMode.arcOnly || hasArcInput);

    if (isReady != _isCalculateReady) {
      setState(() {
        _isCalculateReady = isReady;
      });
    }
  }

  void _resetToStep(int step) {
    setState(() {
      _currentStep = step;
      _isBenderExpanded = step == 0;
      _isRadiusExpanded = step == 1;
      _isDetailsExpanded = step == 2;

      if (step < 4) {
        _isResultsExpanded = false;
        markAOut = '';
        markBOut = '';
        markCOut = '';
        spacingOut = '';
        shotsOut = '';
        anglePerShotOut = '';
      }
    });
  }

  void _startNewBend() {
    setState(() {
      measurement1Ctrl.clear();
      measurement2Ctrl.clear();
      measurement3Ctrl.clear();
      radiusCtrl.clear();
      customStandoffCtrl.clear();
      boxToBoxCtrl.clear();
      arcAngleCtrl.clear();

      _selectedPipeSize = null;
      _selectedConduitType = BoxLayoutConduitType.emt;

      _surfaceFollowed = SurfaceFollowed.inside;
      _supportType = SupportType.surface;
      _strutSizeOption = StrutSizeOption.oneAndFiveEighths;
      _segmentedMode = SegmentedMode.arcOnly;
      _arcInputMode = ArcInputMode.boxToBox;

      markAOut = '';
      markBOut = '';
      markCOut = '';
      spacingOut = '';
      shotsOut = '';
      anglePerShotOut = '';

      recommendedBendAngleOut = '';
      option3Out = '';
      option4Out = '';
      option5Out = '';
      option6Out = '';

      boxToBoxOut = '';
      arcAngleOut = '';
      sticksRequiredOut = '';
      firstOffsetOut = '';
      bendsFirstStickOut = '';
      lastBendFromEndOut = '';
      finalStickCutOut = '';

      _isCalculateReady = false;
      _isResultsExpanded = false;
      _currentStep = 0;
      _isBenderExpanded = true;
      _isRadiusExpanded = false;
      _isDetailsExpanded = false;
      _showArcOptions = false;
      _selectedArcOptionDeg = null;
      _arcOption3 = null;
      _arcOption4 = null;
      _arcOption5 = null;
      _arcOption6 = null;
      _activeController = null;
      _isKeypadVisible = false;
    });
  }

  String fmtInches(double x, {bool addInchMark = true}) {
    if (x == 0) return addInchMark ? '0"' : '0';

    final sign = x < 0 ? -1 : 1;
    double ax = x.abs();
    int whole = ax.floor();
    double frac = ax - whole;
    int sixteenths = (frac * 16).round();

    if (sixteenths == 16) {
      whole += 1;
      sixteenths = 0;
    }

    String fracStr = '';
    if (sixteenths > 0) {
      int g = _gcd(sixteenths, 16);
      int num = sixteenths ~/ g;
      int den = 16 ~/ g;
      fracStr = '$num/$den';
    }

    final body = (whole == 0 && fracStr.isNotEmpty)
        ? fracStr
        : (fracStr.isNotEmpty ? '$whole $fracStr' : '$whole');

    return '${sign < 0 ? '-' : ''}$body${addInchMark ? '"' : ''}';
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  double _parseInches(String text) {
    if (text.isEmpty) return 0.0;

    try {
      text = text.replaceAll('"', '').trim();

      double total = 0.0;

      if (text.contains(' ')) {
        final parts = text.split(' ');
        total += double.tryParse(parts[0]) ?? 0.0;

        if (parts.length > 1 && parts[1].contains('/')) {
          final fracParts = parts[1].split('/');
          final num = double.tryParse(fracParts[0]) ?? 0.0;
          final den = double.tryParse(fracParts[1]) ?? 1.0;
          if (den != 0) total += num / den;
        }
      } else if (text.contains('/')) {
        final fracParts = text.split('/');
        final num = double.tryParse(fracParts[0]) ?? 0.0;
        final den = double.tryParse(fracParts[1]) ?? 1.0;
        if (den != 0) total += num / den;
      } else {
        total = double.tryParse(text) ?? 0.0;
      }

      return total;
    } catch (_) {
      return 0.0;
    }
  }
  double _parseDegrees(String text) {
    if (text.isEmpty) return 0.0;
    text = text.replaceAll('°', '').replaceAll('"', '').trim();
    return double.tryParse(text) ?? 0.0;
  }
  bool _isAngleController(TextEditingController controller) {
    return controller == arcAngleCtrl || controller == pipeLengthArcAngleCtrl;
  }

  String _formatDegrees(double value) {
    if (!value.isFinite) return '';
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  double _sanitizeArcAngle(double value) {
    if (!value.isFinite) return 0.0;
    return value.clamp(0.0, 360.0);
  }
  Map<String, String> _getFilteredPipeSizes() {
    return bending_data.pipeSizes;
  }

  double _currentPipeOD() {
    if (_selectedPipeSize == null) return 0.0;

    return (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_selectedPipeSize]
        : bending_data.grcOD[_selectedPipeSize]) ??
        0.0;
  }

  double _currentStandoff() {
    if (_supportType == SupportType.surface) return 0.0;

    switch (_strutSizeOption) {
      case StrutSizeOption.sevenEighths:
        return 0.875;
      case StrutSizeOption.oneAndFiveEighths:
        return 1.625;
      case StrutSizeOption.custom:
        return _parseInches(customStandoffCtrl.text);
    }
  }

  double? _computedAdjustedBendRadius() {
    final double measuredRadius = _parseInches(radiusCtrl.text);
    final double pipeOD = _currentPipeOD();
    final double standoff = _currentStandoff();

    if (measuredRadius <= 0 || pipeOD <= 0) return null;

    final double adjustedRadius = _surfaceFollowed == SurfaceFollowed.inside
        ? measuredRadius - standoff - pipeOD
        : measuredRadius + standoff;

    if (!adjustedRadius.isFinite || adjustedRadius <= 0) return null;
    return adjustedRadius;
  }

  double? _computedCenterlineRadius() {
    final double measuredRadius = _parseInches(radiusCtrl.text);
    final double pipeOD = _currentPipeOD();
    final double standoff = _currentStandoff();

    if (measuredRadius <= 0 || pipeOD <= 0) return null;

    final double clr = _surfaceFollowed == SurfaceFollowed.inside
        ? measuredRadius - standoff - (pipeOD / 2.0)
        : measuredRadius + standoff + (pipeOD / 2.0);

    if (!clr.isFinite || clr <= 0) return null;
    return clr;
  }
  double? _radiusFromPipeLength({
    required double pipeLength,
    required double arcAngleDeg,
  }) {
    final double pipeOD = _currentPipeOD();
    final double standoff = _currentStandoff();

    if (pipeLength <= 0 || arcAngleDeg <= 0 || pipeOD <= 0) return null;

    final double denominator = (arcAngleDeg / 360.0) * (2 * math.pi);
    if (denominator <= 0) return null;

    // Step 1: Solve CENTERLINE radius
    final double clr = pipeLength / denominator;

    // Step 2: Convert to YOUR adjusted radius system
    final double adjustedRadius = _surfaceFollowed == SurfaceFollowed.inside
        ? clr - (pipeOD / 2.0) - standoff
        : clr - (pipeOD / 2.0) + standoff;

    if (!adjustedRadius.isFinite || adjustedRadius <= 0) return null;

    return adjustedRadius;
  }

  void calculate() {
    if (!_isCalculateReady) return;

    final double? adjustedRadius = _computedAdjustedBendRadius();
    if (adjustedRadius == null || adjustedRadius <= 0 || _selectedPipeSize == null) {
      return;
    }

    final double radius = adjustedRadius;

    final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_selectedPipeSize]
        : bending_data.grcOD[_selectedPipeSize]) ??
        0.0;

    double markA = 0.0;
    double markB = 0.0;
    double markC = 0.0;

    // Clear arc-only outputs before reusing
    boxToBoxOut = '';
    arcAngleOut = '';
    recommendedBendAngleOut = '';
    sticksRequiredOut = '';
    firstOffsetOut = '';
    bendsFirstStickOut = '';
    lastBendFromEndOut = '';
    finalStickCutOut = '';
    option3Out = '';
    option4Out = '';
    option5Out = '';
    option6Out = '';

    if (_segmentedMode == SegmentedMode.arcOnly) {
      double runLength = 0.0;

      if (_radiusWasGeneratedFromLength &&
          _arcInputMode == ArcInputMode.arcAngle &&
          _lockedPipeLength != null &&
          _lockedArcAngleDeg != null) {
        runLength = _lockedPipeLength!;
      } else if (_arcInputMode == ArcInputMode.boxToBox) {
        runLength = _parseInches(boxToBoxCtrl.text);
      } else {
        final double arcAngleDeg = _parseDegrees(arcAngleCtrl.text);
        if (arcAngleDeg <= 0) return;
        runLength = (arcAngleDeg / 360.0) * (2 * math.pi * radius);
      }

      if (runLength <= 0) return;

      const double stickLength = 120.0;
      const double couplingKeepClear = 2.0;

      final double actualArcAngleDeg =
      (_radiusWasGeneratedFromLength &&
          _arcInputMode == ArcInputMode.arcAngle &&
          _lockedArcAngleDeg != null)
          ? _lockedArcAngleDeg!
          : (runLength / radius) * (180 / math.pi);

      Map<String, dynamic> buildArcOption(double targetDeg) {
        final int bendMarks =
        math.max(2, (actualArcAngleDeg / targetDeg).round());

        final double actualAnglePerBend = actualArcAngleDeg / bendMarks;
        final double spacing = runLength / bendMarks;
        final double firstBendFromStart = spacing / 2.0;
        final double lastBendFromEnd = spacing / 2.0;
        final int sticksRequired = (runLength / stickLength).ceil();
        final double finalStickCut =
            runLength - (stickLength * (sticksRequired - 1));

        final List<double> marks = [];
        for (int i = 0; i < bendMarks; i++) {
          marks.add(firstBendFromStart + (i * spacing));
        }

        bool hitsCoupling = false;
        for (final mark in marks) {
          for (double coupling = stickLength;
          coupling < runLength + stickLength;
          coupling += stickLength) {
            if ((mark - coupling).abs() < couplingKeepClear) {
              hitsCoupling = true;
              break;
            }
          }
          if (hitsCoupling) break;
        }

        final double eighthError = ((spacing * 8) - (spacing * 8).round()).abs();

        final double score = (hitsCoupling ? 1000.0 : 0.0) +
            ((actualAnglePerBend - targetDeg).abs() * 100.0) +
            (eighthError * 10.0) +
            ((targetDeg - 5.0).abs());

        return {
          'targetDeg': targetDeg,
          'bendMarks': bendMarks,
          'actualAnglePerBend': actualAnglePerBend,
          'spacing': spacing,
          'firstBendFromStart': firstBendFromStart,
          'lastBendFromEnd': lastBendFromEnd,
          'sticksRequired': sticksRequired,
          'finalStickCut': finalStickCut,
          'hitsCoupling': hitsCoupling,
          'score': score,
        };
      }

      final option3 = buildArcOption(3.0);
      final option4 = buildArcOption(4.0);
      final option5 = buildArcOption(5.0);
      final option6 = buildArcOption(6.0);

      final options = [option3, option4, option5, option6];
      options.sort((a, b) =>
          (a['score'] as double).compareTo(b['score'] as double));

      final best = options.first;

      setState(() {
        boxToBoxOut = fmtInches(runLength);
        arcAngleOut = actualArcAngleDeg % 1 == 0
            ? '${actualArcAngleDeg.toStringAsFixed(0)}°'
            : '${actualArcAngleDeg.toStringAsFixed(1)}°';

        _arcOption3 = option3;
        _arcOption4 = option4;
        _arcOption5 = option5;
        _arcOption6 = option6;

        _showArcOptions = false;
        _selectedArcOptionDeg = best['targetDeg'] as double;

        _currentStep = 4;
        _isResultsExpanded = true;
        _isBenderExpanded = false;
        _isRadiusExpanded = false;
        _isDetailsExpanded = false;
        _hideKeypad();
      });

      _applySelectedArcOption(best);
      return;
    } else {
      final int shots = _parseInches(measurement2Ctrl.text).round();
      if (shots <= 0) return;

      final double developedLength = (math.pi * radius) / 2.0;
      final double spacing = developedLength / shots;
      final double anglePerShot = 90.0 / shots;

      final double stubHeight = _parseInches(measurement1Ctrl.text);
      final double legLength = _parseInches(measurement3Ctrl.text);

      if (stubHeight <= 0) return;

      final double startMark = stubHeight - (radius + (pipeOD / 2.0));

      markA = startMark + spacing;
      markB = startMark + developedLength;

      final double gain = ((2 - (math.pi / 2)) * radius) + pipeOD;
      markC = stubHeight + legLength - gain;

      setState(() {
        markAOut = fmtInches(markA);
        markBOut = fmtInches(markB);
        markCOut = fmtInches(markC);
        spacingOut = fmtInches(spacing);
        shotsOut = '$shots';
        anglePerShotOut = anglePerShot % 1 == 0
            ? '${anglePerShot.toStringAsFixed(0)}°'
            : '${anglePerShot.toStringAsFixed(1)}°';

        _currentStep = 4;
        _isResultsExpanded = true;
        _isBenderExpanded = false;
        _isRadiusExpanded = false;
        _isDetailsExpanded = false;
        _hideKeypad();
      });
    }
  }
  void _applySelectedArcOption(Map<String, dynamic> option) {
    final double perBend = option['actualAnglePerBend'] as double;

    setState(() {
      _selectedArcOptionDeg = option['targetDeg'] as double;

      spacingOut = fmtInches(option['spacing'] as double);
      bendsFirstStickOut = '${option['bendMarks']}';

      recommendedBendAngleOut =
      '${(option['targetDeg'] as double).toStringAsFixed(0)}° target';

      anglePerShotOut = perBend % 1 == 0
          ? '${perBend.toStringAsFixed(0)}°'
          : '${perBend.toStringAsFixed(1)}°';

      markAOut = fmtInches(option['firstBendFromStart'] as double);
      markBOut = fmtInches(option['lastBendFromEnd'] as double);

      sticksRequiredOut = '${option['sticksRequired']}';
      finalStickCutOut = fmtInches(option['finalStickCut'] as double);

      lastBendFromEndOut = (option['hitsCoupling'] as bool)
          ? 'Warning: bend near coupling'
          : '';
    });
  }

  Widget _buildArcOptionButton(double targetDeg, Map<String, dynamic>? option) {
    if (option == null) return const SizedBox.shrink();

    final bool isActive = _selectedArcOptionDeg == targetDeg;
    final bool hasCoupling = option['hitsCoupling'] as bool;

    return Expanded(
      child: _buildSilverButton(
        label: hasCoupling
            ? '${targetDeg.toStringAsFixed(0)}° *'
            : '${targetDeg.toStringAsFixed(0)}°',
        height: 38,
        fontSize: 14,
        isActive: isActive,
        onTap: () => _applySelectedArcOption(option),
      ),
    );
  }

  void _advanceKeypadFocus() {
    if (_activeController == radiusCtrl) {
      if (_segmentedMode == SegmentedMode.stubbed90) {
        return _showKeypad(measurement2Ctrl);
      }

      if (_segmentedMode == SegmentedMode.arcOnly) {
        return _showKeypad(
          _arcInputMode == ArcInputMode.boxToBox ? boxToBoxCtrl : arcAngleCtrl,
        );
      }
    }

    if (_activeController == measurement2Ctrl) {
      if (_segmentedMode == SegmentedMode.stubbed90) {
        return _showKeypad(measurement1Ctrl);
      }
      _hideKeypad();
      return;
    }

    if (_activeController == boxToBoxCtrl || _activeController == arcAngleCtrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isCalculateReady) {
          calculate();
        }
        _hideKeypad();
      });
      return;
    }

    if (_activeController == measurement1Ctrl ||
        _activeController == measurement3Ctrl ||
        _activeController == customStandoffCtrl ||
        _activeController == pipeLengthRadiusCtrl ||
        _activeController == pipeLengthArcAngleCtrl) {
      _hideKeypad();
      return;
    }

    _hideKeypad();
  }

  void _onKeypadTap(String value) {
    if (_activeController == null) return;

    final controller = _activeController!;
    final text = controller.text;
    final bool isAngleField = _isAngleController(controller);

    if (value == '⌫') {
      if (text.isNotEmpty) {
        controller.text = text.substring(0, text.length - 1);
      }
    } else if (value == '✔') {
      if (controller.text.isNotEmpty) {
        if (isAngleField) {
          final degreeValue = _sanitizeArcAngle(_parseDegrees(controller.text));
          controller.text = _formatDegrees(degreeValue);
        } else {
          final decimalValue = _parseInches(controller.text);
          controller.text = fmtInches(decimalValue);
        }
      }
      _advanceKeypadFocus();
    } else {
      if (!isAngleField &&
          value.contains('/') &&
          text.isNotEmpty &&
          !text.endsWith(' ')) {
        final lastChar = text.characters.last;
        if (lastChar != ' ' && int.tryParse(lastChar) != null) {
          controller.text += ' ';
        }
      }
      controller.text += value;
    }

    _updateCalculateButtonState();
  }

  void _showKeypad(TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      controller.clear();
    }
    setState(() {
      _activeController = controller;
      _isKeypadVisible = true;
    });
  }

  void _hideKeypad() {
    setState(() {
      if (_activeController != null && _activeController!.text.isNotEmpty) {
        if (_isAngleController(_activeController!)) {
          final degreeValue =
          _sanitizeArcAngle(_parseDegrees(_activeController!.text));
          _activeController!.text = _formatDegrees(degreeValue);
        } else {
          final decimalValue = _parseInches(_activeController!.text);
          _activeController!.text = fmtInches(decimalValue);
        }
      }
      _activeController = null;
      _isKeypadVisible = false;
    });

    _updateCalculateButtonState();
  }
  Future<void> _openRadiusFinderScreen() async {
    final double? solvedRadius = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => const RadiusArcFinderScreen(returnRadiusToCaller: true),
      ),
    );

    if (!mounted || solvedRadius == null || solvedRadius <= 0) return;

    setState(() {
      radiusCtrl.text = fmtInches(solvedRadius);
    });

    _updateCalculateButtonState();
  }
  Future<void> _showPipeLengthRadiusDialog() async {
    pipeLengthRadiusCtrl.clear();
    pipeLengthArcAngleCtrl.clear();

    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController? localActiveController;
        String resultText = '';

        String formatDegrees(double value) {
          if (value % 1 == 0) {
            return value.toStringAsFixed(0);
          }
          return value.toStringAsFixed(1);
        }

        return StatefulBuilder(
          builder: (context, setLocalState) {
            void solve() {
              final double pipeLength = _parseInches(pipeLengthRadiusCtrl.text);
              final double arcAngle = _parseDegrees(pipeLengthArcAngleCtrl.text);

              final double? solvedRadius = _radiusFromPipeLength(
                pipeLength: pipeLength,
                arcAngleDeg: arcAngle,
              );

              setLocalState(() {
                resultText = solvedRadius == null ? '' : fmtInches(solvedRadius);
              });
            }

            void localShowKeypad(TextEditingController controller) {
              setLocalState(() {
                localActiveController = controller;
              });
            }

            void localHideKeypad() {
              setLocalState(() {
                if (localActiveController == pipeLengthRadiusCtrl &&
                    localActiveController!.text.isNotEmpty) {
                  final decimalValue = _parseInches(localActiveController!.text);
                  localActiveController!.text = fmtInches(decimalValue);
                } else if (localActiveController == pipeLengthArcAngleCtrl &&
                    localActiveController!.text.isNotEmpty) {
                  final degreeValue = _parseDegrees(localActiveController!.text);
                  localActiveController!.text = formatDegrees(degreeValue);
                }

                localActiveController = null;
              });

              solve();
            }

            void localOnKeypadTap(String value) {
              if (localActiveController == null) return;

              final controller = localActiveController!;
              final text = controller.text;

              if (value == '⌫') {
                if (text.isNotEmpty) {
                  controller.text = text.substring(0, text.length - 1);
                }
              } else if (value == '✔') {
                localHideKeypad();
                return;
              } else {
                if (controller == pipeLengthRadiusCtrl &&
                    value.contains('/') &&
                    text.isNotEmpty &&
                    !text.endsWith(' ')) {
                  final lastChar = text.characters.last;
                  if (lastChar != ' ' && int.tryParse(lastChar) != null) {
                    controller.text += ' ';
                  }
                }
                controller.text += value;
              }

              solve();
              setLocalState(() {});
            }

            Widget localField(
                String label,
                TextEditingController controller, {
                  String? suffix,
                }) {
              final bool isActive = localActiveController == controller;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 16, color: kLight),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => localShowKeypad(controller),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: controller,
                            readOnly: true,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 18, color: kLight),
                            decoration: InputDecoration(
                              suffixText: suffix,
                              suffixStyle:
                              const TextStyle(fontSize: 18, color: kLight),
                              isDense: true,
                              filled: true,
                              fillColor: kBlack.withAlpha(128),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: isActive
                                      ? kGreen
                                      : kGreen.withAlpha(100),
                                  width: isActive ? 2 : 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide:
                                const BorderSide(color: kGreen, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF212121),
              title: const Text(
                'Radius from Pipe Length',
                style: TextStyle(color: kLight),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    localField('Pipe Length', pipeLengthRadiusCtrl),
                    const SizedBox(height: 8),
                    localField(
                      'Arc Angle (0–360°)',
                      pipeLengthArcAngleCtrl,
                      suffix: '°',
                    ),
                    const SizedBox(height: 14),
                    if (resultText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: kBlack.withAlpha(128),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kGreen, width: 1.5),
                        ),
                        child: Text(
                          'Radius: $resultText',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: kLight,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    NumericInputKeypad(onTap: localOnKeypadTap),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final double pipeLength = _parseInches(pipeLengthRadiusCtrl.text);
                    final double arcAngle = _parseDegrees(pipeLengthArcAngleCtrl.text);

                    final double? solvedRadius = _radiusFromPipeLength(
                      pipeLength: pipeLength,
                      arcAngleDeg: arcAngle,
                    );

                    if (solvedRadius == null) return;

                    setState(() {
                      radiusCtrl.text = fmtInches(solvedRadius);

                      arcAngleCtrl.text = _formatDegrees(_sanitizeArcAngle(arcAngle));

                      _arcInputMode = ArcInputMode.arcAngle;

                      _radiusWasGeneratedFromLength = true;
                      _lockedPipeLength = pipeLength;
                      _lockedArcAngleDeg = arcAngle;
                    });

                    _updateCalculateButtonState();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Use This Radius',
                    style: TextStyle(color: kGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHelpDialog() {
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
          'Segmented 90 Help',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _helpItem('Step 1: Conduit & Mode',
                    'Choose EMT or Rigid. Arc Only is for circular segments (like a bridge or large curve). Stubbed 90 is for a full 90-degree bend with a specific vertical stub height.'),
                const SizedBox(height: 12),
                _helpItem('Step 2: Radius Setup',
                    'Enter your measured radius. Use "Find Radius" tool, or "From Length" if you only know the total pipe length.'),
                const SizedBox(height: 12),
                _helpItem('Step 3: Bending Details',
                    'Specify "shots" (number of bends) for the 90, or enter dimensions for the Arc.'),
                const SizedBox(height: 12),
                _helpItem('Step 4: Results',
                    'Mark A, B, and C provide precise layout from the pipe end. For Arcs, follow the "Recommended Angle" for the smoothest result.'),
                const SizedBox(height: 16),
                const Text(
                  'Developed Length is automatically solved to ensure spacing is exact across the entire curve.',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontStyle: FontStyle.italic),
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

  Widget _helpItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: kGreen, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  void _setShotPreset(int shots) {
    setState(() {
      measurement2Ctrl.text = shots.toString();
    });
    _updateCalculateButtonState();
  }

  void _updateBenderData() {
    _updateCalculateButtonState();
  }

  Widget _buildInfoBar() {
    String infoText = '';

    if (_currentStep == 0) {
      infoText =
          'Select pipe type and size. Choose if you are bending only an arc of less than 90 degrees or a full 90 with a stub and leg.';
    } else if (_currentStep == 1) {
      if (_showPipeLengthHelper) {
        infoText =
            'From Length: Enter your cut pipe length and desired arc angle. The tool will calculate the exact radius needed to fit that length.';
      } else if (radiusCtrl.text.isNotEmpty) {
        infoText =
            'Choose Surface & Support: Selecting Inside/Outside and Mount type solves for the Adjusted Radius by compensating for pipe thickness and standoff.';
      } else {
        infoText =
            'Enter a measured radius, or use the "Find Radius" tool. Choose "From Length" to solve radius based on a specific cut length of pipe.';
      }
    } else if (_currentStep == 2) {
      if (_segmentedMode == SegmentedMode.stubbed90) {
        infoText =
            'Stubbed 90: Enter your vertical Stub height and optional Leg. Shots determines how many small bends form the 90° turn.';
      } else {
        if (_arcInputMode == ArcInputMode.boxToBox) {
          infoText =
              'Box-to-Box: Radius is the circle size. This step defines how much of that circle you use (Length) to solve for layout marks.';
        } else {
          infoText =
              'Arc Angle: Radius is the circle size. This step defines how much of that circle you use (Degrees) to solve for layout marks.';
        }
      }
    } else if (_currentStep == 3) {
      infoText = 'Step 4: All inputs ready. Press CALCULATE to see results.';
    } else if (_currentStep == 4) {
      if (_segmentedMode == SegmentedMode.arcOnly) {
        infoText =
            'Step 5: Follow layout marks. Use More Options for coupling avoidance.';
      } else {
        infoText =
            'Layout: Mark A is your first bend. Apply each bend at the calculated spacing until you reach Mark B (last bend). Mark C is your cut length.';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
        ),
        child: Text(
          infoText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kLight,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildSilverButton({
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
    bool isCheckmark = false,
    double height = 44,
    double fontSize = 15,
  }) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey.shade500,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isCheckmark) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: kGreen, size: 24),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inlineField(
      String label,
      TextEditingController c, {
        VoidCallback? onTap,
        String? suffix,
      }) {
    final bool isActive = _activeController == c;
    final bool isReadOnly = onTap == null;
    final bool isEditable = !isReadOnly;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isReadOnly ? null : () => _showKeypad(c),
            child: Container(
              width: 135,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: kBlack.withAlpha(160),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? kGreen : Colors.white38,
                  width: isActive ? 1.8 : 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: AbsorbPointer(
                      child: TextField(
                        controller: c,
                        readOnly: true,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 18,
                            color: kLight,
                            fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffixText: suffix,
                          suffixStyle: const TextStyle(
                              fontSize: 18,
                              color: kLight,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyValueField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 135,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: kBlack.withAlpha(160),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value.isNotEmpty ? const Color(0xFFC0C0C0) : Colors.white38,
                width: 1.2,
              ),
            ),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 18, color: kLight, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thinSectionDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      height: 2,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white38,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
  Widget _buildPipeLengthHelper() {
    final double pipeLength = _parseInches(pipeLengthRadiusCtrl.text);
    final double arcAngle = _parseDegrees(pipeLengthArcAngleCtrl.text);

    final double? solvedRadius = _radiusFromPipeLength(
      pipeLength: pipeLength,
      arcAngleDeg: arcAngle,
    );

    final String resultText = solvedRadius == null ? '' : fmtInches(solvedRadius);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kBlack.withAlpha(90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Radius from Pipe Length',
            style: TextStyle(
              color: kLight,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          _inlineField(
            'Pipe Length',
            pipeLengthRadiusCtrl,
            onTap: () => _showKeypad(pipeLengthRadiusCtrl),
            suffix: '"',
          ),
          const SizedBox(height: 8),

          _inlineField(
            'Arc Angle (0–360°)',
            pipeLengthArcAngleCtrl,
            onTap: () => _showKeypad(pipeLengthArcAngleCtrl),
            suffix: '°',
          ),

          const SizedBox(height: 10),

          _readOnlyValueField('Radius', resultText),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildSilverButton(
                  label: 'Cancel',
                  height: 38,
                  fontSize: 14,
                  onTap: () {
                    setState(() {
                      _showPipeLengthHelper = false;
                      pipeLengthRadiusCtrl.clear();
                      pipeLengthArcAngleCtrl.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSilverButton(
                  label: 'Use This Radius',
                  height: 38,
                  fontSize: 13,
                  onTap: solvedRadius == null
                      ? null
                      : () {
                    setState(() {
                      radiusCtrl.text = fmtInches(solvedRadius);

                      arcAngleCtrl.text = _formatDegrees(_sanitizeArcAngle(arcAngle));

                      _arcInputMode = ArcInputMode.arcAngle;

                      _radiusWasGeneratedFromLength = true;
                      _lockedPipeLength = pipeLength;
                      _lockedArcAngleDeg = arcAngle;

                      _showPipeLengthHelper = false;
                    });

                    _updateCalculateButtonState();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenderSection() {
    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '1. CONDUIT & MODE',
            fontSize: 19,
            height: 60,
            isActive: _currentStep == 0,
            onTap: () => _resetToStep(0),
          ),
          if (_isBenderExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                children: [
                  _buildBenderSetupFields(),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'Select Mode',
                        style: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Arc Only',
                          height: 40,
                          isActive: _segmentedMode == SegmentedMode.arcOnly,
                          onTap: () {
                            setState(() {
                              _segmentedMode = SegmentedMode.arcOnly;
                            });
                            _updateCalculateButtonState();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Stubbed 90',
                          height: 40,
                          isActive: _segmentedMode == SegmentedMode.stubbed90,
                          onTap: () {
                            setState(() {
                              _segmentedMode = SegmentedMode.stubbed90;
                            });
                            _updateCalculateButtonState();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildSilverButton(
                    label: 'Next',
                    height: 44,
                    isActive: _selectedPipeSize != null,
                    isCheckmark: _selectedPipeSize != null,
                    onTap: _selectedPipeSize == null
                        ? null
                        : () => _resetToStep(1),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadiusSection() {
    final bool isEnabled = _currentStep >= 1;
    final double? adjustedRadius = _computedAdjustedBendRadius();
    final String adjustedRadiusText =
        adjustedRadius == null ? '' : fmtInches(adjustedRadius);
    final bool hasRadius = radiusCtrl.text.isNotEmpty;

    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '2. RADIUS SETUP',
            fontSize: 19,
            height: 60,
            isActive: _currentStep == 1,
            onTap: isEnabled ? () => _resetToStep(1) : null,
          ),
          if (_isRadiusExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasRadius) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Enter Radius',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _inlineField(
                      'Measured Radius',
                      radiusCtrl,
                      onTap: () => _showKeypad(radiusCtrl),
                      suffix: '"',
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSilverButton(
                            label: 'Find Radius',
                            height: 40,
                            fontSize: 14,
                            onTap: _openRadiusFinderScreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSilverButton(
                            label: _showPipeLengthHelper
                                ? 'Hide Tool'
                                : 'From Length',
                            height: 40,
                            fontSize: 13,
                            isActive: _showPipeLengthHelper,
                            onTap: () {
                              setState(() {
                                _showPipeLengthHelper = !_showPipeLengthHelper;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_showPipeLengthHelper) _buildPipeLengthHelper(),
                  ] else ...[
                    _inlineField(
                      'Radius',
                      radiusCtrl,
                      onTap: () => _showKeypad(radiusCtrl),
                      suffix: '"',
                    ),
                  ],
                  if (hasRadius) ...[
                    const SizedBox(height: 4),
                    _thinSectionDivider(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Surface Followed',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSilverButton(
                            label: 'Inside Surface',
                            height: 40,
                            isActive:
                                _surfaceFollowed == SurfaceFollowed.inside,
                            onTap: () {
                              setState(() {
                                _surfaceFollowed = SurfaceFollowed.inside;
                              });
                              _updateCalculateButtonState();
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSilverButton(
                            label: 'Outside Surface',
                            height: 40,
                            isActive:
                                _surfaceFollowed == SurfaceFollowed.outside,
                            onTap: () {
                              setState(() {
                                _surfaceFollowed = SurfaceFollowed.outside;
                              });
                              _updateCalculateButtonState();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Support',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSilverButton(
                            label: 'Surface Mount',
                            height: 40,
                            isActive: _supportType == SupportType.surface,
                            onTap: () {
                              setState(() {
                                _supportType = SupportType.surface;
                              });
                              _updateCalculateButtonState();
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSilverButton(
                            label: 'Strut',
                            height: 40,
                            isActive: _supportType == SupportType.strut,
                            onTap: () {
                              setState(() {
                                _supportType = SupportType.strut;
                              });
                              _updateCalculateButtonState();
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_supportType == SupportType.strut) ...[
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'Strut Size',
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSilverButton(
                              label: '7/8"',
                              height: 40,
                              isActive: _strutSizeOption ==
                                  StrutSizeOption.sevenEighths,
                              onTap: () {
                                setState(() {
                                  _strutSizeOption =
                                      StrutSizeOption.sevenEighths;
                                });
                                _updateCalculateButtonState();
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildSilverButton(
                              label: '1-5/8"',
                              height: 40,
                              fontSize: 14,
                              isActive: _strutSizeOption ==
                                  StrutSizeOption.oneAndFiveEighths,
                              onTap: () {
                                setState(() {
                                  _strutSizeOption =
                                      StrutSizeOption.oneAndFiveEighths;
                                });
                                _updateCalculateButtonState();
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildSilverButton(
                              label: 'Custom',
                              height: 40,
                              isActive:
                                  _strutSizeOption == StrutSizeOption.custom,
                              onTap: () {
                                setState(() {
                                  _strutSizeOption = StrutSizeOption.custom;
                                });
                                _updateCalculateButtonState();
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_strutSizeOption == StrutSizeOption.custom) ...[
                        const SizedBox(height: 4),
                        _inlineField(
                          'Custom Standoff',
                          customStandoffCtrl,
                          onTap: () => _showKeypad(customStandoffCtrl),
                          suffix: '"',
                        ),
                      ],
                    ],
                    const SizedBox(height: 6),
                    _readOnlyValueField('Adjusted Radius', adjustedRadiusText),
                    const SizedBox(height: 6),
                    _buildSilverButton(
                      label: 'Next',
                      height: 44,
                      isActive: true,
                      isCheckmark: true,
                      onTap: () => _resetToStep(2),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final bool isEnabled = _currentStep >= 2;

    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '3. BENDING DETAILS',
            fontSize: 19,
            height: 60,
            isActive: _currentStep == 2,
            onTap: isEnabled ? () => _resetToStep(2) : null,
          ),
          if (_isDetailsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_segmentedMode == SegmentedMode.stubbed90) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Shot Count',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSilverButton(
                            label: '15 / 6°',
                            height: 40,
                            isActive: measurement2Ctrl.text == '15',
                            onTap: () => _setShotPreset(15),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSilverButton(
                            label: '18 / 5°',
                            height: 40,
                            isActive: measurement2Ctrl.text == '18',
                            onTap: () => _setShotPreset(18),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSilverButton(
                            label: '30 / 3°',
                            height: 40,
                            isActive: measurement2Ctrl.text == '30',
                            onTap: () => _setShotPreset(30),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _inlineField(
                      'Custom Shots',
                      measurement2Ctrl,
                      onTap: () => _showKeypad(measurement2Ctrl),
                    ),
                    const SizedBox(height: 4),
                    _inlineField(
                      'Stub Height',
                      measurement1Ctrl,
                      onTap: () => _showKeypad(measurement1Ctrl),
                      suffix: '"',
                    ),
                    _inlineField(
                      'Leg Length (opt)',
                      measurement3Ctrl,
                      onTap: () => _showKeypad(measurement3Ctrl),
                      suffix: '"',
                    ),
                  ] else ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Arc Input',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSilverButton(
                            label: 'Box-to-Box',
                            height: 40,
                            isActive: _arcInputMode == ArcInputMode.boxToBox,
                            onTap: () {
                              setState(() {
                                _arcInputMode = ArcInputMode.boxToBox;
                                arcAngleCtrl.clear();
                              });
                              _updateCalculateButtonState();
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSilverButton(
                            label: 'Arc Angle',
                            height: 40,
                            isActive: _arcInputMode == ArcInputMode.arcAngle,
                            onTap: () {
                              setState(() {
                                _arcInputMode = ArcInputMode.arcAngle;
                                boxToBoxCtrl.clear();
                              });
                              _updateCalculateButtonState();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                      _inlineField(
                        _arcInputMode == ArcInputMode.boxToBox
                            ? 'Run Length'
                            : 'Arc Angle',
                        _arcInputMode == ArcInputMode.boxToBox
                            ? boxToBoxCtrl
                            : arcAngleCtrl,
                        onTap: () => _showKeypad(
                          _arcInputMode == ArcInputMode.boxToBox
                              ? boxToBoxCtrl
                              : arcAngleCtrl,
                        ),
                        suffix:
                            _arcInputMode == ArcInputMode.arcAngle ? '°' : '"',
                      ),
                  ],
                  const SizedBox(height: 6),
                  _buildSilverButton(
                    label: 'Next',
                    height: 44,
                    isActive: true,
                    isCheckmark: true,
                    onTap: () => _resetToStep(3),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalculateSection() {
    return _buildGroupContainer(
      child: _buildSilverButton(
        label: '4. CALCULATE',
        isActive: _currentStep == 3 && _isCalculateReady,
        isCheckmark: _isCalculateReady,
        height: 60,
        fontSize: 19,
        onTap: _isCalculateReady ? calculate : null,
      ),
    );
  }

  Widget _buildResultsSection() {
    final bool isEnabled = _currentStep >= 4;
    final double? adjustedRadius = _computedAdjustedBendRadius();
    final String radiusText =
        adjustedRadius == null ? '' : fmtInches(adjustedRadius);

    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '5. RESULTS',
            fontSize: 19,
            height: 60,
            isActive: _currentStep == 4,
            onTap: isEnabled
                ? () => setState(() => _isResultsExpanded = !_isResultsExpanded)
                : null,
          ),
          if (_isResultsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
              child: Column(
                children: [
                  if (_segmentedMode == SegmentedMode.arcOnly) ...[
                    _resultRow('Radius', radiusText),
                    _resultRow(
                      _arcInputMode == ArcInputMode.boxToBox
                          ? 'Box-to-Box Length'
                          : 'Calculated Arc Length',
                      boxToBoxOut,
                    ),
                    _resultRow('Actual Arc Angle', arcAngleOut),
                    _resultRow('Selected Bend Angle', recommendedBendAngleOut),
                    _resultRow('Spacing Between Bends', spacingOut),
                    _resultRow('Total Bend Marks', bendsFirstStickOut),
                    _resultRow('Actual Angle Per Bend', anglePerShotOut),

                    const SizedBox(height: 6),

                    _resultRow('First Bend From Start', markAOut),
                    _resultRow('Last Bend From End', markBOut),
                    _resultRow('Sticks Required', sticksRequiredOut),
                    _resultRow('Final Stick Cut Length', finalStickCutOut),

                    if (lastBendFromEndOut.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _resultRow('Coupling Warning', lastBendFromEndOut),
                    ],

                    const SizedBox(height: 10),

                    _buildSilverButton(
                      label: _showArcOptions ? 'Hide More Options' : 'More Options',
                      height: 40,
                      onTap: () {
                        setState(() {
                          _showArcOptions = !_showArcOptions;
                        });
                      },
                    ),

                    if (_showArcOptions) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildArcOptionButton(3.0, _arcOption3),
                          const SizedBox(width: 4),
                          _buildArcOptionButton(4.0, _arcOption4),
                          const SizedBox(width: 4),
                          _buildArcOptionButton(5.0, _arcOption5),
                          const SizedBox(width: 4),
                          _buildArcOptionButton(6.0, _arcOption6),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '* indicates option may place a bend near a coupling.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ] else ...[
                    _resultRow('Radius', radiusText),
                    _resultRow('Mark A — First Bend', markAOut),
                    _resultRow('Mark B — Last Bend', markBOut),
                    _resultRow('Mark C — Cut Length', markCOut),
                    const SizedBox(height: 6),
                    _resultRow('Number of Bends', shotsOut),
                    _resultRow('Spacing Between Bends', spacingOut),
                    _resultRow('Bend Angle', anglePerShotOut),
                  ],
                  const SizedBox(height: 10),
                  _buildSilverButton(
                    label: 'Start New Bend',
                    height: 40,
                    onTap: _startNewBend,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
          color: kBlack.withAlpha(160),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC8C8C8), width: 1.1)),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Container(
            width: 132,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8A1010), Color(0xFFD12A2A)]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB0B0B0), width: 1)),
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 19,
                  color: Colors.white,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenderSetupFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        children: [
          _buildConduitTypeSelector(),
          const SizedBox(height: 4),
          _buildPipeSizeSelector(),
        ],
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
            isActive: _selectedConduitType == BoxLayoutConduitType.emt,
            onTap: () {
              setState(() => _selectedConduitType = BoxLayoutConduitType.emt);
              _updateBenderData();
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildSilverButton(
            label: 'Rigid',
            height: 40,
            isActive: _selectedConduitType == BoxLayoutConduitType.grc,
            onTap: () {
              setState(() => _selectedConduitType = BoxLayoutConduitType.grc);
              _updateBenderData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPipeSizeSelector() {
    final bool needsPipeSize = _selectedPipeSize == null;

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
          return _getFilteredPipeSizes().keys.map((String value) {
            final bool selected = value == _selectedPipeSize;
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
            border: Border.all(
              color: needsPipeSize ? kGreen : const Color(0xFFC0C0C0),
              width: needsPipeSize ? 2.0 : 1.2,
            ),
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
              Icon(
                  Icons.arrow_drop_down, color: needsPipeSize ? kGreen : Colors.white54, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {});
  }

  Future<void> _saveCustomBender() async {}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: true,
        leadingWidth: 150,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                (route) => false,
              ),
            ),
            IconButton(
              icon: const RotatedBox(
                quarterTurns: 2,
                child: Text(
                  "➜",
                  style: TextStyle(
                    color: kLight,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              onPressed: () {
                _hideKeypad();
                if (_currentStep > 0) {
                  _resetToStep(_currentStep - 1);
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: kLight),
              onPressed: _startNewBend,
            ),
          ],
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Segmented 90',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
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
                icon: const Icon(Icons.info_outline, color: kLight),
                onPressed: () {
                  setState(() => _hasViewedInfo = true);
                  _showHelpDialog();
                },
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CodeScreen(
                  initialCategory: CodeCategory.raceways,
                ),
              ),
            ),
            child: const Text(
              'NEC',
              style: TextStyle(
                color: kLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: ListView(
                children: [
                  _buildBenderSection(),
                  const SizedBox(height: 6),
                  _buildRadiusSection(),
                  const SizedBox(height: 6),
                  _buildDetailsSection(),
                  const SizedBox(height: 6),
                  _buildCalculateSection(),
                  const SizedBox(height: 6),
                  _buildResultsSection(),
                ],
              ),
            ),
          ),
          if (!_isKeypadVisible && !_isNameEntryMode) _buildInfoBar(),
          if (_isKeypadVisible) NumericInputKeypad(onTap: _onKeypadTap),
        ],
      ),
    );
  }
}
