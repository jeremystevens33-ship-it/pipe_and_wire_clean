import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data; // Using alias for clarity
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:pipe_and_wire_clean/keypad_6.dart';
import 'code_screen.dart';
import 'bender_picker_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BackToBack90ScreenV2(),
    ),
  );
}

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);


class BackToBack90ScreenV2 extends StatefulWidget {
  const BackToBack90ScreenV2({super.key});

  @override
  State<BackToBack90ScreenV2> createState() => _BackToBack90ScreenV2State();
}

class _BackToBack90ScreenV2State extends State<BackToBack90ScreenV2> with TickerProviderStateMixin {
  static const double _resultsGraphicBlockHeight = 315.0;
  static const double _topPipeImageHeight = 200.0;
  static const double _topPipeImageTopPadding = 2.0;
  static const double _topPipeImageSidePadding = 0.0;
  static const double _spaceBetweenTopAndBottomGraphic = 1.0;
  static const double _bottomMeasurementGraphicHeight = 110.0;
  // State management for workflow
  int _currentStep = 0;
  bool _isBenderExpanded = true;
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;
  bool _isCalculateReady = false;
  bool get _isBenderSetupComplete =>
      _selectedBrand != null && _selectedPipeSize != null;

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

  // Bender & Conduit State
  bending_data.ConduitType _selectedConduitType = bending_data.ConduitType.emt;
  String? _selectedPipeSize;
  String? _selectedBrand;
  bending_data.MarkBMethod _selectedMarkBMethod = bending_data.MarkBMethod.pushThrough;

  // --- NEW: Custom Bender State ---
  bool _isEditMode = false;
  bool _isNewBender = false; // Flag to distinguish between Creating and Editing
  final List<bending_data.Bender> _customBenders = []; // Uses Bender from bending_data
  List<Map<String, String>> _allBrands = []; // Combined list for dropdown

  // Controllers
  final stub1Ctrl = TextEditingController();
  final stub2Ctrl = TextEditingController();
  final backToBackDistanceCtrl = TextEditingController();
  final travelCtrl = TextEditingController();
  final takeUpCtrl = TextEditingController();
  final gainCtrl = TextEditingController();
  final radiusCtrl = TextEditingController();
  final setbackCtrl = TextEditingController();
  final parallelSpacingCtrl = TextEditingController();
  // Output variables
  String markAOut = '';
  String markBOut = '';
  String markCOut = '';

  // Raw values
  double _rawMarkA = 0.0;
  double _rawMarkB = 0.0;
  double _rawCut = 0.0;
  double _rawTakeUp = 0.0;
  double _rawGain = 0.0;

  // Keypad State
  bool _isKeypadVisible = false;
  TextEditingController? _activeController;
  bool _isNameEntryMode = false;
  String _customBenderName = '';
  // Conditional Travel Field Visibility
  bool _showTravelField = false;
  bool _isParallelMode = false;
  double _parallelEffectiveOffset = 0.0;
  bool _isParallelEntryMode = false;

  @override
  void initState() {
    super.initState();
    _loadCustomBenders();
    _updateBrandDropdown();

    final allInputCtrls = [
      stub1Ctrl,
      stub2Ctrl,
      backToBackDistanceCtrl,
      travelCtrl,
      takeUpCtrl,
      gainCtrl,
      radiusCtrl
    ];
    for (var ctrl in allInputCtrls) {
      ctrl.addListener(_updateCalculateButtonState);
    }
    takeUpCtrl.addListener(_updateSetback);
    gainCtrl.addListener(_updateSetback);
    gainCtrl.addListener(_updateRadiusFromGain);
    radiusCtrl.addListener(_updateGainFromRadius);

    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    final allCtrls = [
      stub1Ctrl,
      stub2Ctrl,
      backToBackDistanceCtrl,
      parallelSpacingCtrl,
      travelCtrl,
      takeUpCtrl,
      gainCtrl,
      radiusCtrl,
      setbackCtrl,
    ];

    for (var ctrl in allCtrls) {
      ctrl.removeListener(_updateCalculateButtonState);
      ctrl.removeListener(_updateSetback);
    }

    gainCtrl.removeListener(_updateRadiusFromGain);

    for (var ctrl in allCtrls) {
      ctrl.dispose();
    }

    super.dispose();
  }

  void _updateBrandDropdown() {
    setState(() {
      _allBrands = [
        ...bending_data.getGroupedBenderBrands(),
        {'type': 'header', 'name': 'SAVED BENDERS'},
        ..._customBenders.map((b) => {'type': 'custom_bender', 'name': b.brand}),
      ];
    });
  }

  Map<String, String> _getFilteredPipeSizes() {
    return bending_data.getFilteredPipeSizes(_selectedBrand);
  }

  void _updateCalculateButtonState() {
    final bool isReady = stub1Ctrl.text.isNotEmpty &&
        stub2Ctrl.text.isNotEmpty &&
        backToBackDistanceCtrl.text.isNotEmpty &&
        _selectedPipeSize != null &&
        _selectedBrand != null;
    if (isReady != _isCalculateReady) {
      setState(() {
        _isCalculateReady = isReady;
        if (isReady) {
          _currentStep = 2;
        }
      });
    }
  }

  void _updateSetback() {
    final takeUpText = takeUpCtrl.text.trim();
    final gainText = gainCtrl.text.trim();

    if (takeUpText.isEmpty || gainText.isEmpty) {
      setbackCtrl.text = '';
      return;
    }

    final takeUp = _parseInches(takeUpText);
    final gain = _parseInches(gainText);
    final setback = takeUp - gain;

    setbackCtrl.text = fmtInches(setback);
  }

  void _updateGainFromRadius() {
    if (!_isEditMode || _activeController != radiusCtrl) return;

    final radiusText = radiusCtrl.text.trim();
    if (radiusText.isEmpty || _selectedPipeSize == null) {
      gainCtrl.text = '';
      return;
    }

    final radius = _parseInches(radiusText);
    final double pipeOD = (_selectedConduitType == bending_data.ConduitType.emt
        ? bending_data.emtOD[_selectedPipeSize]
        : bending_data.grcOD[_selectedPipeSize]) ?? 0.0;

    if (pipeOD <= 0 || radius <= 0) return;

    final gain = bending_data.calculateGain90(radius, pipeOD);
    gainCtrl.text = fmtInches(gain, addInchMark: false);

    // Also update travel
    travelCtrl.text = fmtInches(bending_data.calculateTravel90(radius), addInchMark: false);
  }

  void _updateRadiusFromGain() {
    if (!_isEditMode || _activeController != gainCtrl) return;

    final gainText = gainCtrl.text.trim();
    if (gainText.isEmpty || _selectedPipeSize == null) {
      radiusCtrl.text = '';
      return;
    }

    final gain = _parseInches(gainText);

    final double pipeOD = (_selectedConduitType == bending_data.ConduitType.emt
        ? bending_data.emtOD[_selectedPipeSize]
        : bending_data.grcOD[_selectedPipeSize]) ?? 0.0;

    const double factor = 2 - (math.pi / 2);

    if (pipeOD <= 0 || gain <= pipeOD || factor == 0) {
      radiusCtrl.text = '';
      return;
    }

    final clr = bending_data.calculateCLRFromGain(gain, pipeOD);
    radiusCtrl.text = fmtInches(clr, addInchMark: false);

    // Also update travel
    travelCtrl.text = fmtInches(bending_data.calculateTravel90(clr), addInchMark: false);
  }

  void _updateBenderData() {
    if (_isEditMode) return; // Prevent clearing fields while user is typing in Edit Mode

    if (_selectedBrand == null || _selectedPipeSize == null) {
      setState(() {
        travelCtrl.text = '';
        takeUpCtrl.text = '';
        gainCtrl.text = '';
        setbackCtrl.text = '';
        radiusCtrl.text = '';
        _showTravelField = false;
      });
      return;
    }

    // Try to find a custom bender first
    bending_data.Bender? bender = _customBenders.firstWhereOrNull(
            (b) => b.model == _selectedBrand && b.conduitSize == _selectedPipeSize &&
            (b.conduitType == (
                _selectedConduitType == bending_data.ConduitType.emt ? bending_data.ConduitType.emt :
                bending_data.ConduitType.rigid
            )
            )
    );

    // If not found in custom benders, search the main benderDatabase
    bender ??= bending_data.benderDatabase.firstWhereOrNull(
            (b) => b.brand == _selectedBrand && b.conduitSize == _selectedPipeSize &&
            (b.conduitType == (
                _selectedConduitType == bending_data.ConduitType.emt ? bending_data.ConduitType.emt :
                bending_data.ConduitType.rigid
            )
            )
    );

    double calculatedGain = 0.0;
    double calculatedTravel = 0.0;
    if (bender != null) {
      final double pipeOD = (_selectedConduitType == bending_data.ConduitType.emt
          ? bending_data.emtOD[_selectedPipeSize]
          : bending_data.grcOD[_selectedPipeSize]) ?? 0.0;

      if (bender.clr > 0 && pipeOD > 0) {
        calculatedGain = bending_data.calculateGain90(bender.clr, pipeOD);
      }
      calculatedTravel = bending_data.calculateTravel90(bender.clr);
    }

    setState(() {
      _rawTakeUp = bender?.deduct ?? 0.0;
      _rawGain = calculatedGain;

      travelCtrl.text = bender != null ? fmtInches(calculatedTravel) : '';
      takeUpCtrl.text = bender != null ? fmtInches(bender.deduct) : '';
      gainCtrl.text = bender != null
          ? fmtInches(calculatedGain)
          : '';
      radiusCtrl.text = bender != null ? fmtInches(bender.clr) : '';

      _showTravelField = bending_data.mechanicalElectricBenderBrands.contains(bender?.brand ?? '');

      _isBenderExpanded = _isBenderSetupComplete;
      _updateSetback();
      if (_isEditMode) {
        _isEditMode = false;
        _hideKeypad();
      }
    });
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
      }
    });
  }

  void _startNewBend() {
    setState(() {
      stub1Ctrl.clear();
      stub2Ctrl.clear();
      backToBackDistanceCtrl.clear();

      travelCtrl.clear();
      takeUpCtrl.clear();
      gainCtrl.clear();
      radiusCtrl.clear();
      setbackCtrl.clear();

      _selectedBrand = null;
      _selectedPipeSize = null;
      _selectedConduitType = bending_data.ConduitType.emt;
      _selectedMarkBMethod = bending_data.MarkBMethod.pushThrough;

      markAOut = '';
      markBOut = '';
      markCOut = '';
      _rawMarkA = 0.0;
      _rawMarkB = 0.0;
      _rawCut = 0.0;

      _isCalculateReady = false;
      _isResultsExpanded = false;
      _isEditMode = false;
      _isNewBender = false;
      _customBenderName = '';
      _resetToStep(0);
      _showTravelField = false;

      parallelSpacingCtrl.clear();
      _isParallelMode = false;
      _isParallelEntryMode = false;
      _parallelEffectiveOffset = 0.0;
    });
    _hideKeypad();
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
    } catch (e) {
      return 0.0;
    }
  }

  double _selectedPipeOD() {
    if (_selectedPipeSize == null) return 0.0;

    return (_selectedConduitType == bending_data.ConduitType.emt
        ? bending_data.emtOD[_selectedPipeSize]
        : bending_data.grcOD[_selectedPipeSize]) ??
        0.0;
  }

  Map<String, double>? _buildResultValues() {
    if (!_isCalculateReady) return null;

    final baseStub1 = _parseInches(stub1Ctrl.text);
    final baseStub2 = _parseInches(stub2Ctrl.text);
    final baseDistance = _parseInches(backToBackDistanceCtrl.text);
    final takeUp = _rawTakeUp;
    final gain = _rawGain;

    if (baseStub1 == 0 || baseStub2 == 0 || baseDistance == 0 || takeUp == 0 || gain == 0) {
      return null;
    }

    final double offset = _isParallelMode ? _parallelEffectiveOffset : 0.0;

    final double stub1 = baseStub1 + offset;
    final double stub2 = baseStub2 + offset;
    final double distance = baseDistance + (2 * offset);

    final double cut = bending_data.calculateBtbCutLength(stub1, distance, stub2, gain);
    final double markA = bending_data.calculateBtbMarkA(stub1, takeUp);

    final double markB = _selectedMarkBMethod == bending_data.MarkBMethod.pushThrough
        ? bending_data.calculateBtbMarkBPushThrough(markA, distance, gain)
        : bending_data.calculateBtbMarkBReverseBender(cut, stub2, takeUp);

    return {
      'markA': markA,
      'markB': markB,
      'cut': cut,
    };
  }

  void _applyParallelMeasurementsFromSpacing() {
    final clearSpace = _parseInches(parallelSpacingCtrl.text);
    final od = _selectedPipeOD();

    if (clearSpace <= 0 || od <= 0) return;

    final offset = clearSpace + od;

    final baseStub1 = _parseInches(stub1Ctrl.text);
    final baseStub2 = _parseInches(stub2Ctrl.text);
    final baseDistance = _parseInches(backToBackDistanceCtrl.text);

    if (baseStub1 <= 0 || baseStub2 <= 0 || baseDistance <= 0) return;

    final newStub1 = baseStub1 + offset;
    final newStub2 = baseStub2 + offset;
    final newDistance = baseDistance + (2 * offset);

    setState(() {
      _parallelEffectiveOffset = offset;
      _isParallelMode = true;
      _isParallelEntryMode = false;

      stub1Ctrl.text = fmtInches(newStub1);
      stub2Ctrl.text = fmtInches(newStub2);
      backToBackDistanceCtrl.text = fmtInches(newDistance);
    });
  }
  void calculate() {
    if (_isParallelEntryMode) {
      final clearSpace = _parseInches(parallelSpacingCtrl.text);
      final od = _selectedPipeOD();

      if (clearSpace > 0 && od > 0) {
        _parallelEffectiveOffset = clearSpace + od;
        _isParallelMode = true;
      } else {
        _parallelEffectiveOffset = 0.0;
        _isParallelMode = false;
      }

      _isParallelEntryMode = false;
    }

    final results = _buildResultValues();
    if (results == null) return;

    setState(() {
      _rawMarkA = results['markA']!;
      _rawMarkB = results['markB']!;
      _rawCut = results['cut']!;

      markAOut = fmtInches(_rawMarkA);
      markBOut = fmtInches(_rawMarkB);
      markCOut = fmtInches(_rawCut);

      _currentStep = 3;
      _isResultsExpanded = true;
      _isMeasurementsExpanded = false;
    });

    _hideKeypad();
  }
  void _advanceKeypadFocus() {
    if (_activeController == stub1Ctrl) {
      _showKeypad(stub2Ctrl);
      return;
    }
    if (_activeController == stub2Ctrl) {
      _showKeypad(backToBackDistanceCtrl);
      return;
    }
    if (_activeController == backToBackDistanceCtrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isCalculateReady) {
          calculate();
        } else {
          _hideKeypad();
        }
      });
      return;
    }

    if (_activeController == parallelSpacingCtrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hideKeypad();
        _applyParallelMeasurementsFromSpacing();
      });
      return;
    }

    if (_activeController == travelCtrl) {
      _showKeypad(takeUpCtrl);
      return;
    }
    if (_activeController == takeUpCtrl) {
      _showKeypad(gainCtrl);
      return;
    }
    if (_activeController == gainCtrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hideKeypad();
      });
      return;
    }
    if (_activeController == radiusCtrl) {
      _hideKeypad();
      return;
    }

    _hideKeypad();
  }
  void _onKeypadTap(String value) {
    if (_activeController == null) return;
    final controller = _activeController!;
    final text = controller.text;

    if (value == '⌫') {
      if (text.isNotEmpty) {
        controller.text = text.substring(0, text.length - 1);
      }
    } else if (value == '✔') {
      if (controller.text.isNotEmpty) {
        final decimalValue = _parseInches(controller.text);
        controller.text = fmtInches(decimalValue);
      }
      _advanceKeypadFocus();
    } else {
      if (value.contains('/') && text.isNotEmpty && !text.endsWith(' ')) {
        final lastChar = text.characters.last;
        if (lastChar != ' ' && int.tryParse(lastChar) != null) {
          controller.text += ' ';
        }
      }
      controller.text += value;
    }
  }

  void _onNameKeyTap(String value) {
    if (value == '⌫') {
      if (_customBenderName.isNotEmpty) {
        setState(() {
          _customBenderName =
              _customBenderName.substring(0, _customBenderName.length - 1);
        });
      }
      return;
    }

    if (value == 'CLEAR') {
      setState(() {
        _customBenderName = '';
      });
      return;
    }

    if (value == '✔') {
      _finishSaveCustomBender();
      return;
    }

    if (_customBenderName.length < 24) {
      setState(() {
        _customBenderName += value;
      });
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

  void _finishSaveCustomBender() {
    final name = _customBenderName.trim();
    if (name.isEmpty) return;

    final newBender = bending_data.Bender(
      brand: name,
      model: name,
      conduitSize: _selectedPipeSize ?? 'N/A',
      conduitType: _selectedConduitType == bending_data.ConduitType.emt
          ? bending_data.ConduitType.emt
          : bending_data.ConduitType.rigid,
      clr: _parseInches(radiusCtrl.text),
      deduct: _parseInches(takeUpCtrl.text),
      gain: _parseInches(gainCtrl.text),
    );

    setState(() {
      // OVERWRITE LOGIC:
      _customBenders.removeWhere((b) =>
      b.brand == name &&
          b.conduitSize == newBender.conduitSize &&
          b.conduitType == newBender.conduitType);

      _customBenders.add(newBender);
      bending_data.BenderStore.save(newBender);
      _updateBrandDropdown();
      _selectedBrand = newBender.model;

      _isEditMode = false;
      _isNameEntryMode = false;
      _customBenderName = '';
    });

    _updateBenderData();
    _hideKeypad();
  }

  void _updateResultDisplay() {
    final results = _buildResultValues();
    if (results == null) return;

    setState(() {
      _rawMarkA = results['markA']!;
      _rawMarkB = results['markB']!;
      _rawCut = results['cut']!;

      markAOut = fmtInches(_rawMarkA);
      markBOut = fmtInches(_rawMarkB);
      markCOut = fmtInches(_rawCut);
    });
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
      if (_activeController != null &&
          _activeController!.text.isNotEmpty) {
        final decimalValue = _parseInches(_activeController!.text);
        _activeController!.text = fmtInches(decimalValue);
      }
      _activeController = null;
      _isKeypadVisible = false;
    });
  }

  void _toggleEditMode() {
    if (_isEditMode) {
      setState(() {
        _isEditMode = false;
      });
      _hideKeypad();
      return;
    }

    setState(() {
      _isEditMode = true;
      _isNewBender = true;
      _selectedBrand = null;
      _customBenderName = '';

      travelCtrl.clear();
      takeUpCtrl.clear();
      gainCtrl.clear();
      setbackCtrl.clear();
      radiusCtrl.clear();
    });

    if (_selectedPipeSize != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_showTravelField) {
          _showKeypad(travelCtrl);
        } else {
          _showKeypad(takeUpCtrl);
        }
      });
    }
  }

  void _cancelEditMode() {
    setState(() {
      _isEditMode = false;
    });

    _hideKeypad();
    _updateBenderData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: kLight,
        centerTitle: true,
        leadingWidth: 160,
        leading: Row(
          children: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
                  setState(() {
                    _currentStep -= 1;
                    _isBenderExpanded = _currentStep == 0;
                    _isMeasurementsExpanded = _currentStep == 1;
                    _isResultsExpanded = _currentStep == 3;
                  });
                } else {
                  _startNewBend();
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
            'Back to Back 90',
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
                  _showHelpDialog(context);
                },
              ),
            ],
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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: ListView(
                children: [
                  if (!_isResultsExpanded) ...[
                    _buildBenderSection(),
                    const SizedBox(height: 6),

                    _buildMeasurementsSection(),
                    const SizedBox(height: 6),

                    _buildCalculateSection(),
                    const SizedBox(height: 6),
                  ],

                  _buildResultsSection(),


                ],
              ),
            ),
          ),

          // 🔥 RESULTS GRAPHIC + INFO BAR HANDLING (CLEAN BLOCK)

          if (!_isKeypadVisible && !_isNameEntryMode)
            _buildInfoBar(),

          if (_isNameEntryMode)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: kBlack.withAlpha(180),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Save Custom Bender',
                          style: TextStyle(
                            color: kLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: kBlack,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white54, width: 1.2),
                          ),
                          child: Text(
                            _customBenderName.isEmpty
                                ? 'Enter a nickname'
                                : _customBenderName,
                            style: TextStyle(
                              color: _customBenderName.isEmpty
                                  ? Colors.white38
                                  : kLight,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSilverButton(
                                label: 'Cancel',
                                height: 40,
                                onTap: () {
                                  setState(() {
                                    _isNameEntryMode = false;
                                    _customBenderName = '';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildSilverButton(
                                label: 'Save',
                                height: 40,
                                isActive: true,
                                onTap: _customBenderName.trim().isEmpty
                                    ? null
                                    : _finishSaveCustomBender,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AlphaInputKeypad(onTap: _onNameKeyTap),
              ],
            ),

          if (_isKeypadVisible)
            NumericInputKeypad(onTap: _onKeypadTap),
        ],
      ),
    );
  }

  Widget _buildBenderSection() {
    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '1. BENDER & CONDUIT',
            fontSize: 19,
            height: 60,
            isActive: _currentStep == 0,
            onTap: () {
              setState(() {
                _currentStep = 0;
                _isBenderExpanded = !_isBenderExpanded;

                if (_isBenderExpanded) {
                  _isMeasurementsExpanded = false;
                  _isResultsExpanded = false;
                }
              });
            },
          ),

          if (_isBenderExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                children: [
                  _buildBrandSelector(),
                  const SizedBox(height: 6),

                  _buildConduitTypeSelector(),
                  const SizedBox(height: 6),

                  _buildPipeSizeSelector(),

                  if (!_isEditMode && !_isBenderSetupComplete) ...[
                    const SizedBox(height: 6),
                    _buildSilverButton(
                      label: 'Create / Edit Custom Bender',
                      height: 44,
                      onTap: _toggleEditMode,
                    ),
                  ],

                  if (_isBenderSetupComplete || _isEditMode) ...[
                    const SizedBox(height: 10),

                    // Bender Model Row
                    _inlineField(
                      'Bender Model',
                      TextEditingController(
                        text: bending_data.benderDatabase.firstWhereOrNull(
                              (b) => b.brand == _selectedBrand &&
                                  b.conduitSize == _selectedPipeSize &&
                                  b.conduitType == (
                                  _selectedConduitType == bending_data.ConduitType.emt ? bending_data.ConduitType.emt :
                                  bending_data.ConduitType.rigid
                                  ),
                        )?.model ?? 'Custom',
                      ),
                      onTap: null, // Read-only
                    ),

                    if (_showTravelField) ...[
                      _inlineField('90° Travel', travelCtrl),
                    ],

                    _inlineField(
                      'Take Up',
                      takeUpCtrl,
                      onTap: _isEditMode ? () => _showKeypad(takeUpCtrl) : null,
                    ),

                    _inlineField(
                      'Gain90',
                      gainCtrl,
                      onTap: _isEditMode ? () => _showKeypad(gainCtrl) : null,
                    ),

                    _inlineField('Setback', setbackCtrl),

                    _inlineField(
                      'Radius / CLR',
                      radiusCtrl,
                      onTap: _isEditMode ? () => _showKeypad(radiusCtrl) : null,
                    ),
                    const SizedBox(height: 10),

                    if (_isEditMode) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildSilverButton(
                              label: 'Save Custom Bender',
                              height: 44,
                              isActive: true,
                              onTap: () {
                                setState(() {
                                  _isNameEntryMode = true;
                                  _customBenderName = '';
                                  _isKeypadVisible = false;
                                  _activeController = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSilverButton(
                              label: 'Cancel',
                              height: 44,
                              onTap: _cancelEditMode,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Removed duplicate button here
                    ],

                    const SizedBox(height: 10),

                    _buildSilverButton(
                      label: 'Done',
                      height: 44,
                      isActive: true,
                      isCheckmark: true,
                      onTap: () {
                        setState(() {
                          _isBenderExpanded = false;
                          _currentStep = 1;
                          _isMeasurementsExpanded = true;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    final bool canOpen = _selectedBrand != null && _selectedPipeSize != null;

    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '2. MEASUREMENTS',
            fontSize: 20,
            height: 60,
            isActive: _currentStep == 1,
            onTap: canOpen
                ? () {
              setState(() {
                _currentStep = 1;
                _isMeasurementsExpanded = !_isMeasurementsExpanded;

                if (_isMeasurementsExpanded) {
                  _isBenderExpanded = false;
                  _isResultsExpanded = false;
                }
              });
            }
                : null,
          ),
          if (_isMeasurementsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                children: [
                  if (_isParallelEntryMode) ...[
                    _inlineField(
                      'Open Distance Between Pipes',
                      parallelSpacingCtrl,
                      onTap: () => _showKeypad(parallelSpacingCtrl),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    _inlineField(
                      _isParallelMode ? 'Parallel Stub 1' : 'Stub 1 Height',
                      stub1Ctrl,
                      onTap: () => _showKeypad(stub1Ctrl),
                    ),
                    _inlineField(
                      _isParallelMode ? 'Parallel Stub 2' : 'Stub 2 Height',
                      stub2Ctrl,
                      onTap: () => _showKeypad(stub2Ctrl),
                    ),
                    _inlineField(
                      _isParallelMode ? 'Parallel Back to Back' : 'Back to Back Distance',
                      backToBackDistanceCtrl,
                      onTap: () => _showKeypad(backToBackDistanceCtrl),
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

  Widget _buildCalculateSection() {
    return _buildGroupContainer(
      child: _buildSilverButton(
        label: '3. CALCULATE',
        isActive: _currentStep == 2,
        isCheckmark: _isCalculateReady,
        height: 60,
        fontSize: 20,
        onTap: _isCalculateReady
            ? () {
          setState(() {
            _currentStep = 2;
            _isBenderExpanded = false;
            _isMeasurementsExpanded = false;
            _isResultsExpanded = false;
          });
          calculate();
        }
            : null,
      ),
    );
  }

  Widget _buildResultsSection() {
    final bool canOpen =
        _currentStep >= 3 ||
            markAOut.isNotEmpty ||
            markBOut.isNotEmpty ||
            markCOut.isNotEmpty;

    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '4. RESULTS',
            fontSize: 20,
            height: 60,
            isActive: _currentStep == 3,
            onTap: canOpen
                ? () {
              setState(() {
                _currentStep = 3;
                _isResultsExpanded = !_isResultsExpanded;

                if (_isResultsExpanded) {
                  _isBenderExpanded = false;
                  _isMeasurementsExpanded = false;
                }
              });
            }
                : null,
          ),
          if (_isResultsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
              child: Column(
                children: [
                  _buildMethodSelector(),

                  const SizedBox(height: 6),

                  _resultRow('Mark A — First Bend', markAOut),
                  _resultRow('Mark B — Second Bend', markBOut),
                  _resultRow('Mark C — Cut Length', markCOut),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Start New Bend',
                          height: 38,
                          onTap: _startNewBend,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Parallel',
                          height: 38,
                          onTap: () {
                            if (_isParallelMode || _isParallelEntryMode) {
                              setState(() {
                                _isParallelMode = false;
                                _isParallelEntryMode = false;
                                _parallelEffectiveOffset = 0.0;
                                parallelSpacingCtrl.clear();
                              });
                              calculate();
                            } else {
                              setState(() {
                                _isParallelEntryMode = true;
                                _isParallelMode = false;
                                _isResultsExpanded = false;
                                _isMeasurementsExpanded = true;
                                _currentStep = 1;

                                parallelSpacingCtrl.clear();
                              });

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _showKeypad(parallelSpacingCtrl);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  SizedBox(
                    height: _resultsGraphicBlockHeight,
                    child: Column(
                      children: [
                        SizedBox(
                          height: _topPipeImageHeight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: _topPipeImageTopPadding,
                              left: _topPipeImageSidePadding,
                              right: _topPipeImageSidePadding,
                            ),
                            child: Center(
                              child: Image.asset(
                                _isParallelMode
                                    ? 'assets/images/btb_parallel.png'
                                    : 'assets/images/btb_1.png',
                                width: double.infinity,
                                fit: BoxFit.fitWidth,
                                alignment: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: _spaceBetweenTopAndBottomGraphic),
                        SizedBox(
                          height: _bottomMeasurementGraphicHeight,
                          child: _BackToBackResultGraphic(
                            markA: markAOut,
                            markB: markBOut,
                            markC: markCOut,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSilverButton(
            label: 'Push Through',
            height: 40,
            isActive: _selectedMarkBMethod == bending_data.MarkBMethod.pushThrough,
            onTap: () {
              setState(() {
                _selectedMarkBMethod = bending_data.MarkBMethod.pushThrough;
                _updateResultDisplay();
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSilverButton(
            label: 'Reverse Bender',
            height: 40,
            isActive: _selectedMarkBMethod == bending_data.MarkBMethod.reverseBender,
            onTap: () {
              setState(() {
                _selectedMarkBMethod = bending_data.MarkBMethod.reverseBender;
                _updateResultDisplay();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _resultRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(145),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 132,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8A1010), Color(0xFFD12A2A)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB0B0B0), width: 1),
                ),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConduitTypeSelector() {
    return Row(
      children: [
        Expanded(child: _buildSilverButton(label: 'EMT',
            height: 40,
            isActive: _selectedConduitType == bending_data.ConduitType.emt,
            onTap: () {
              setState(() => _selectedConduitType = bending_data.ConduitType.emt);
              _updateBenderData();
            })),
        const SizedBox(width: 10),
        Expanded(child: _buildSilverButton(label: 'Rigid',
            height: 40,
            isActive: _selectedConduitType == bending_data.ConduitType.rigid,
            onTap: () {
              setState(() => _selectedConduitType = bending_data.ConduitType.rigid);
              _updateBenderData();
            })),
      ],
    );
  }

  void _showBenderPicker() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(220),
      builder: (context) => BenderPickerDialog(
        allBrands: _allBrands,
        selectedBrand: _selectedBrand,
        onSelected: (name) {
          final custom = _customBenders.firstWhereOrNull((b) => b.brand == name);
          setState(() {
            _selectedBrand = name;
            if (custom != null) {
              _selectedPipeSize = custom.conduitSize;
              _selectedConduitType = custom.conduitType;
            }
          });
          _updateBenderData();
        },
        onDelete: (name) {
          setState(() {
            _customBenders.removeWhere((b) => b.brand == name);
            bending_data.BenderStore.delete(name);
            _updateBrandDropdown();
            if (_selectedBrand == name) {
              _selectedBrand = null;
              _updateBenderData();
            }
          });
        },
        onEdit: (name) {
          final bender = _customBenders.firstWhereOrNull((b) => b.brand == name);
          if (bender != null) {
            setState(() {
              _isEditMode = true;
              _isNewBender = false;
              _selectedBrand = null;
              _selectedPipeSize = bender.conduitSize;
              _selectedConduitType = bender.conduitType;

              takeUpCtrl.text = fmtInches(bender.deduct, addInchMark: false);
              gainCtrl.text = fmtInches(bender.gain, addInchMark: false);
              radiusCtrl.text = fmtInches(bender.clr, addInchMark: false);
              
              final setback = bender.deduct - bender.gain;
              setbackCtrl.text = fmtInches(setback, addInchMark: false);

              _customBenderName = bender.brand;
            });
            _showKeypad(takeUpCtrl);
          }
        },
      ),
    );
  }

  Widget _buildBrandSelector() {
    return GestureDetector(
      onTap: _showBenderPicker,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFC0C0C0),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _isEditMode
                    ? (_isNewBender ? 'Custom' : 'Editing: $_customBenderName')
                    : (_selectedBrand ?? 'Select Bender Brand'),
                style: TextStyle(
                  color: (_selectedBrand == null && !_isEditMode)
                      ? Colors.white70
                      : kLight,
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

  Widget _buildPipeSizeSelector() {
    final bool needsPipeSize = (_selectedBrand != null || _isEditMode) && _selectedPipeSize == null;

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
          if (_isEditMode) {
            _showKeypad(takeUpCtrl);
          }
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

  void _showHelpDialog(BuildContext context) {
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
          'Back to Back Help',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Solve for two 90° bends made back-to-back on a single piece of pipe.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Workflow:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter Stub 1 (the end you measure from), Stub 2 (the other end), and the finished distance between them.',
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Measurement Methods:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 4),
                Text(
                  '• PUSH THROUGH: Keep bender facing same end for both bends.\n'
                  '• REVERSE BENDER: Face bender towards measurement end for first bend, then turn around for the second.',
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

  Widget _buildInfoBar() {
    String infoText;

    if (_currentStep == 0 && !_isBenderSetupComplete) {
      infoText = "Step 1: Select your bender, conduit, and pipe size.";
    } else if (_currentStep == 0 && _isBenderSetupComplete) {
      infoText =
      'Step 1: Review the loaded bender values. Press "Done" to continue, or create a custom bender to match your setup.';
    } else if (_currentStep == 1) {
      infoText = "Step 2: Enter Stub 1, Stub 2, and Back to Back Distance.";
    } else if (_currentStep == 2) {
      infoText =
      "Step 3: All measurements entered. Press 'CALCULATE' to see results.";
    } else {
      if (_selectedMarkBMethod == bending_data.MarkBMethod.pushThrough) {
        infoText =
        'All bends use the arrow. Layout marks and cut length in one pull. Push Through for tighter spacing.';
      } else {
        infoText =
        'All bends use the arrow. Layout marks and cut length in one pull. Reverse bender when second bend is near the end.';
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Container(
        height: 118,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
        ),
        child: Center(
          child: Text(
            infoText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kLight, fontSize: 20),
          ),
        ),
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
              ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)]
              : (isEnabled
              ? [const Color(0xFF4E4E52), const Color(0xFF2C3030)]
              : [Colors.grey.shade800, Colors.grey.shade900]),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inlineField(String label, TextEditingController c,
      {VoidCallback? onTap, String? suffix}) {
    final bool isActive = _activeController == c;
    final bool isReadOnly = onTap == null;

    final String? cleanSuffix = (suffix != null && c.text.contains(suffix))
        ? null
        : suffix;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
              child: Text(
                  label,
                  style: const TextStyle(fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600)
              )
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
                        style: const TextStyle(fontSize: 18,
                            color: kLight,
                            fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffixText: cleanSuffix,
                          // Use the smart suffix here
                          suffixStyle: const TextStyle(fontSize: 18,
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
}

class _BackToBackResultGraphic extends StatelessWidget {
  const _BackToBackResultGraphic(
      {required this.markA, required this.markB, required this.markC});

  final String markA, markB, markC;

  @override
  Widget build(BuildContext context) {
    const double resultPipeBottomOffset = 10.0;
    const double resultMeasureTextBottomOffset = 0.0;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return Stack(
          alignment: Alignment.topLeft, clipBehavior: Clip.none, children: [
        Positioned(
          bottom: resultPipeBottomOffset, left: -17, right: -23,
          child: Image.asset('assets/conduits/emt/pipe_5_ol.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high),
        ),
        _downMark(width * 0.9, 7, 'A', markA),
        _downMark(width * 0.4, 7, 'B', markB),
        _downMark(width * 0.11, 7, 'C', markC),
        const Positioned(
      bottom: resultMeasureTextBottomOffset, right: 16,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Measure from this end', style: TextStyle(
                color: kLight, fontWeight: FontWeight.w700, fontSize: 18)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: kLight, size: 18),
          ]),
        ),
      ]);
    });
  }

  Widget _downMark(double x, double top, String label, String value) {
    return Positioned(
      left: x - 40, top: top + 15,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black.withAlpha(191),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24)),
          child: Text('$label: $value', style: const TextStyle(
              color: kLight, fontWeight: FontWeight.w800)),
        ),
        const Icon(Icons.arrow_downward, color: Colors.white70, size: 18),
      ]),
    );
  }
}