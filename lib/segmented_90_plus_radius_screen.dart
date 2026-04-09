import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:pipe_and_wire_clean/radius_arc_finder_screen.dart';
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
    extends State<Segmented90PlusRadiusScreen> {
  // Workflow state
  int _currentStep = 0;
  bool _isBenderExpanded = true;
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;
  bool _isCalculateReady = false;
  SegmentedMode _segmentedMode = SegmentedMode.arcOnly;
  ArcInputMode _arcInputMode = ArcInputMode.boxToBox;

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

  @override
  void initState() {
    super.initState();

    final allInputCtrls = [
      measurement1Ctrl,
      measurement2Ctrl,
      measurement3Ctrl,
      radiusCtrl,
      boxToBoxCtrl,
      arcAngleCtrl,
    ];
    for (var ctrl in allInputCtrls) {
      ctrl.addListener(_updateCalculateButtonState);
    }
  }

  @override
  void dispose() {
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

    final bool needsShots = _segmentedMode == SegmentedMode.stubbed90;
    final bool needsStub = _segmentedMode == SegmentedMode.stubbed90;

    final bool hasShots = measurement2Ctrl.text.isNotEmpty;
    final bool hasStub = measurement1Ctrl.text.isNotEmpty;

    final bool hasArcLength = boxToBoxCtrl.text.isNotEmpty;
    final bool hasArcAngle = arcAngleCtrl.text.isNotEmpty;

    final bool hasArcInput = _segmentedMode == SegmentedMode.arcOnly
        ? (_arcInputMode == ArcInputMode.boxToBox ? hasArcLength : hasArcAngle)
        : true;

    final bool isReady = hasRadius &&
        hasPipeSize &&
        (!needsShots || hasShots) &&
        (!needsStub || hasStub) &&
        hasArcInput;

    if (isReady != _isCalculateReady) {
      setState(() {
        _isCalculateReady = isReady;
        if (isReady) {
          _currentStep = 2;
        }
      });
    }
  }

  void _setShotPreset(int shots) {
    setState(() {
      measurement2Ctrl.text = shots.toString();
    });
    _updateCalculateButtonState();
  }

  void _updateBenderData() {
    if (_selectedPipeSize == null) {
      return;
    }
    _updateCalculateButtonState();
  }

  void _resetToStep(int step) {
    setState(() {
      _currentStep = step;
      _isBenderExpanded = step == 0;
      _isMeasurementsExpanded = step == 1;

      if (step < 3) {
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
      _isMeasurementsExpanded = false;
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

        _currentStep = 3;
        _isResultsExpanded = true;
        _isMeasurementsExpanded = false;
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

        _currentStep = 3;
        _isResultsExpanded = true;
        _isMeasurementsExpanded = false;
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
        builder: (_) => const RadiusArcFinderScreen(),
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
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text(
            'Segmented 90 + Radius',
            style: TextStyle(color: kLight),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Use this screen to lay out either a stubbed segmented 90 or an arc-only bend from a chosen radius.',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),

                Text(
                  '1. Select conduit type and pipe size.',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 10),

                Text(
                  '2. Set your radius. Enter a measured radius, use Find Radius, or create one from pipe length.',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 10),

                Text(
                  '3. Choose the surface followed and support type. The app updates the adjusted bend radius automatically.',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 10),

                Text(
                  '4. For Arc Only, enter either box-to-box length or arc angle. Radius from Length can also fill the arc angle automatically.',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 10),

                Text(
                  '5. For Stubbed 90, choose a shot count, then enter stub height and optional leg length.',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 10),

                Text(
                  '6. The app calculates spacing, bend angle, bend marks, and cut layout based on your inputs.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: kRed),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoBar() {
    String infoText = 'Step 1: Select conduit type and pipe size.';

    if (_currentStep == 1) {
      if (_segmentedMode == SegmentedMode.arcOnly) {
        infoText =
        'Step 2: Enter radius, then choose Arc Input (box-to-box or 0–360° angle).';
      } else {
        infoText =
        'Step 2: Enter radius, then choose shots, stub height, and optional leg length.';
      }
    } else if (_currentStep == 2) {
      infoText = 'Step 3: Press CALCULATE.';
    } else if (_currentStep == 3) {
      if (_segmentedMode == SegmentedMode.arcOnly) {
        infoText =
        'Step 4: Use the selected bend angle. Tap More Options if needed.';
      } else {
        infoText =
        'Step 4: Measure Mark A, B, and C from the same end of the pipe.';
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
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
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
              ? [kRed, const Color(0xFFD43D37)]
              : (isEnabled
              ? [const Color(0xFF4E4E52), const Color(0xFF2C3030)]
              : [Colors.grey.shade800, Colors.grey.shade900]),
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
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
              onTap: isReadOnly ? null : () => _showKeypad(c),
              child: AbsorbPointer(
                child: TextField(
                  controller: c,
                  readOnly: true,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 18, color: kLight),
                  decoration: InputDecoration(
                    suffixText: suffix,
                    suffixStyle: const TextStyle(fontSize: 18, color: kLight),
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
                            : (isEditable
                            ? kGreen.withAlpha(100)
                            : Colors.white54),
                        width: isActive || isEditable ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: kGreen, width: 2),
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

  Widget _readOnlyValueField(String label, String value) {
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
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: kBlack.withAlpha(128),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value.isNotEmpty ? kGreen : Colors.white54,
                  width: value.isNotEmpty ? 2 : 1,
                ),
              ),
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 18, color: kLight),
              ),
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
        gradient: LinearGradient(
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
            label: '1. CONDUIT',
            fontSize: 18,
            height: 50,
            isActive: _currentStep == 0,
            onTap: () => _resetToStep(0),
          ),
          if (_isBenderExpanded)
            Column(
              children: [
                _buildBenderSetupFields(),
                const SizedBox(height: 12),
                _buildSilverButton(
                  label: 'Done',
                  height: 40,
                  onTap: () {
                    setState(() {
                      _isBenderExpanded = false;
                      _currentStep = 1;
                      _isMeasurementsExpanded = true;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    final bool isEnabled = _currentStep >= 1;
    final double? adjustedRadius = _computedAdjustedBendRadius();
    final String adjustedRadiusText =
    adjustedRadius == null ? '' : fmtInches(adjustedRadius);

    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '2. MEASUREMENTS',
            fontSize: 18,
            height: 50,
            isActive: _currentStep == 1,
            onTap: isEnabled ? () => _resetToStep(1) : null,
          ),
          if (_isMeasurementsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mode',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

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
                              measurement1Ctrl.clear();
                              measurement3Ctrl.clear();
                            });
                            _updateCalculateButtonState();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Stubbed 90',
                          height: 40,
                          isActive: _segmentedMode == SegmentedMode.stubbed90,
                          onTap: () {
                            setState(() {
                              _segmentedMode = SegmentedMode.stubbed90;
                              boxToBoxCtrl.clear();
                            });
                            _updateCalculateButtonState();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _thinSectionDivider(),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Radius Setup',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _inlineField(
                    'Measured Radius',
                    radiusCtrl,
                    onTap: () => _showKeypad(radiusCtrl),
                  ),
                  const SizedBox(height: 8),

                  Column(
                    children: [
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSilverButton(
                              label: _showPipeLengthHelper
                                  ? 'Hide Length Tool'
                                  : 'Radius from Length',
                              height: 40,
                              fontSize: 13,
                              isActive: _showPipeLengthHelper,
                              onTap: () {
                                setState(() {
                                  _showPipeLengthHelper = !_showPipeLengthHelper;

                                  if (!_showPipeLengthHelper) {
                                    pipeLengthRadiusCtrl.clear();
                                    pipeLengthArcAngleCtrl.clear();
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_showPipeLengthHelper) _buildPipeLengthHelper(),
                    ],
                  ),
                  const SizedBox(height: 10),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Surface Followed',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Inside Surface',
                          height: 40,
                          isActive: _surfaceFollowed == SurfaceFollowed.inside,
                          onTap: () {
                            setState(() {
                              _surfaceFollowed = SurfaceFollowed.inside;
                            });
                            _updateCalculateButtonState();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Outside Surface',
                          height: 40,
                          isActive: _surfaceFollowed == SurfaceFollowed.outside,
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

                  const SizedBox(height: 12),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Support',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

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
                      const SizedBox(width: 8),
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
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Strut Size',
                        style: TextStyle(
                          color: kLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSilverButton(
                            label: '7/8"',
                            height: 40,
                            isActive:
                            _strutSizeOption == StrutSizeOption.sevenEighths,
                            onTap: () {
                              setState(() {
                                _strutSizeOption =
                                    StrutSizeOption.sevenEighths;
                              });
                              _updateCalculateButtonState();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSilverButton(
                            label: 'Custom',
                            height: 40,
                            isActive: _strutSizeOption == StrutSizeOption.custom,
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
                      const SizedBox(height: 10),
                      _inlineField(
                        'Custom Standoff',
                        customStandoffCtrl,
                        onTap: () => _showKeypad(customStandoffCtrl),
                      ),
                    ],
                  ],

                  const SizedBox(height: 10),

                  _readOnlyValueField('Adjusted Bend Radius', adjustedRadiusText),

                  const SizedBox(height: 12),
                  _thinSectionDivider(),

                  if (_segmentedMode == SegmentedMode.stubbed90) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Shot Count',
                        style: TextStyle(
                          color: kLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

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
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSilverButton(
                            label: '18 / 5°',
                            height: 40,
                            isActive: measurement2Ctrl.text == '18',
                            onTap: () => _setShotPreset(18),
                          ),
                        ),
                        const SizedBox(width: 8),
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

                    const SizedBox(height: 10),

                    _inlineField(
                      'Custom Shots',
                      measurement2Ctrl,
                      onTap: () => _showKeypad(measurement2Ctrl),
                    ),

                    const SizedBox(height: 14),
                    _inlineField(
                      'Stub Height',
                      measurement1Ctrl,
                      onTap: () => _showKeypad(measurement1Ctrl),
                      suffix: '"',
                    ),
                    _inlineField(
                      'Leg Length (optional)',
                      measurement3Ctrl,
                      onTap: () => _showKeypad(measurement3Ctrl),
                    ),
                  ],

                  if (_segmentedMode == SegmentedMode.arcOnly) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Arc Input',
                        style: TextStyle(
                          color: kLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

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
                        const SizedBox(width: 10),
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

                    const SizedBox(height: 12),

                    _inlineField(
                      _arcInputMode == ArcInputMode.boxToBox
                          ? 'Box-to-Box Length'
                          : 'Arc Angle (0–360°)',
                      _arcInputMode == ArcInputMode.boxToBox ? boxToBoxCtrl : arcAngleCtrl,
                      onTap: () => _showKeypad(
                        _arcInputMode == ArcInputMode.boxToBox ? boxToBoxCtrl : arcAngleCtrl,
                      ),
                      suffix: _arcInputMode == ArcInputMode.arcAngle ? '°' : null,
                    ),
                  ],

                  const SizedBox(height: 12),
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
        label: '3. CALCULATE',
        isActive: _currentStep == 2 && _isCalculateReady,
        isCheckmark: _isCalculateReady,
        height: 50,
        fontSize: 18,
        onTap: _isCalculateReady ? calculate : null,
      ),
    );
  }

  Widget _buildResultsSection() {
    final bool isEnabled = _currentStep >= 3;
    final double? adjustedRadius = _computedAdjustedBendRadius();
    final String radiusText =
    adjustedRadius == null ? '' : fmtInches(adjustedRadius);

    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '4. RESULTS',
            fontSize: 18,
            height: 50,
            isActive: _currentStep == 3,
            onTap: isEnabled
                ? () => setState(() => _isResultsExpanded = !_isResultsExpanded)
                : null,
          ),
          if (_isResultsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
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

                    const SizedBox(height: 10),

                    _resultRow('First Bend From Start', markAOut),
                    _resultRow('Last Bend From End', markBOut),
                    _resultRow('Sticks Required', sticksRequiredOut),
                    _resultRow('Final Stick Cut Length', finalStickCutOut),

                    if (lastBendFromEndOut.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _resultRow('Coupling Warning', lastBendFromEndOut),
                    ],

                    const SizedBox(height: 14),

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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildArcOptionButton(3.0, _arcOption3),
                          const SizedBox(width: 8),
                          _buildArcOptionButton(4.0, _arcOption4),
                          const SizedBox(width: 8),
                          _buildArcOptionButton(5.0, _arcOption5),
                          const SizedBox(width: 8),
                          _buildArcOptionButton(6.0, _arcOption6),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                    const SizedBox(height: 10),
                    _resultRow('Number of Bends', shotsOut),
                    _resultRow('Spacing Between Bends', spacingOut),
                    _resultRow('Bend Angle', anglePerShotOut),
                  ],
                  const SizedBox(height: 15),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: kLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenderSetupFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          _buildConduitTypeSelector(),
          const SizedBox(height: 12),
          _buildPipeSizeSelector(),
          const SizedBox(height: 12),
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
        const SizedBox(width: 10),
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(
        color: kBlack.withAlpha(128),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white54),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPipeSize,
          isExpanded: true,
          hint: const Text(
            'Select Pipe Size',
            style: TextStyle(color: Colors.white70),
          ),
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: kLight, fontSize: 18),
          items: _getFilteredPipeSizes().keys.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(bending_data.pipeSizes[value]!),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() => _selectedPipeSize = newValue);
            _updateBenderData();
          },
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
        title: const Text('Segmented 90 + Radius'),
        foregroundColor: kLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showHelpDialog,
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CodeScreen()),
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kRed.withAlpha(178), width: 2),
          ),
          clipBehavior: Clip.none,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    _buildBenderSection(),
                    _buildMeasurementsSection(),
                    _buildCalculateSection(),
                    _buildResultsSection(),
                  ],
                ),
              ),
              if (!_isKeypadVisible) _buildInfoBar(),
              if (_isKeypadVisible) NumericInputKeypad(onTap: _onKeypadTap),
            ],
          ),
        ),
      ),
    );
  }
}
