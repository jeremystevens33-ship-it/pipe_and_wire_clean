import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data; // Using alias for clarity
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:pipe_and_wire_clean/keypad_6.dart';
import 'code_screen.dart';

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

class _BackToBack90ScreenV2State extends State<BackToBack90ScreenV2> {
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

  // Bender & Conduit State
  bending_data.ConduitType _selectedConduitType = bending_data.ConduitType.emt;
  String? _selectedPipeSize;
  String? _selectedBrand;
  bending_data.MarkBMethod _selectedMarkBMethod = bending_data.MarkBMethod.pushThrough;

  // --- NEW: Custom Bender State ---
  bool _isEditMode = false;
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
  double _parallelClearSpace = 0.0;
  double _parallelEffectiveOffset = 0.0;
  bool _isParallelEntryMode = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
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
        ..._customBenders.map((b) => {'type': 'bender', 'name': b.brand}),
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

  void _updateRadiusFromGain() {
    if (!_isEditMode) return;

    final gainText = gainCtrl.text.trim();
    if (gainText.isEmpty || _selectedPipeSize == null) {
      radiusCtrl.text = '';
      return;
    }

    final gain = _parseInches(gainText);

    final double pipeOD = (_selectedConduitType == bending_data.ConduitType.emt
        ? bending_data.emtOD[_selectedPipeSize]
        : bending_data.grcOD[_selectedPipeSize]) ?? 0.0;

    final double factor = 2 - (math.pi / 2);

    if (pipeOD <= 0 || gain <= pipeOD || factor == 0) {
      radiusCtrl.text = '';
      return;
    }

    final clr = (gain - pipeOD) / factor;
    radiusCtrl.text = fmtInches(clr);
  }

  void _updateBenderData() {
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
      _resetToStep(0);
      _showTravelField = false;

      parallelSpacingCtrl.clear();
      _isParallelMode = false;
      _isParallelEntryMode = false;
      _parallelClearSpace = 0.0;
      _parallelEffectiveOffset = 0.0;
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
      _parallelClearSpace = clearSpace;
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
        _parallelClearSpace = clearSpace;
        _parallelEffectiveOffset = clearSpace + od;
        _isParallelMode = true;
      } else {
        _parallelClearSpace = 0.0;
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
      _customBenders.add(newBender);
      _updateBrandDropdown();

      _selectedBrand = newBender.model;

      _isEditMode = false;
      _isNameEntryMode = false;
      _customBenderName = '';
    });

// 🔥 THIS IS THE FIX
    _updateBenderData();

    _hideKeypad();
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

      travelCtrl.clear();
      takeUpCtrl.clear();
      gainCtrl.clear();
      setbackCtrl.clear();
      radiusCtrl.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showTravelField) {
        _showKeypad(travelCtrl);
      } else {
        _showKeypad(takeUpCtrl);
      }
    });
  }

  void _cancelEditMode() {
    setState(() {
      _isEditMode = false;
    });

    _hideKeypad();
    _updateBenderData();
  }

  Future<void> _saveCustomBender() async {
    final ValueNotifier<String> nameValue = ValueNotifier<String>('');

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
          ),
          title: const Text(
            'Save Custom Bender',
            style: TextStyle(color: kLight, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: ValueListenableBuilder<String>(
              valueListenable: nameValue,
              builder: (context, value, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 62,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: kBlack.withAlpha(160),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: value.isNotEmpty ? const Color(0xFFC0C0C0) : Colors.white38,
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        value.isEmpty ? 'Enter a nickname' : value,
                        style: TextStyle(
                          color: value.isEmpty ? Colors.white38 : kLight,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildNameKeyRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'], nameValue),
                    const SizedBox(height: 8),
                    _buildNameKeyRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'], nameValue),
                    const SizedBox(height: 8),
                    _buildNameKeyRow(['Z', 'X', 'C', 'V', 'B', 'N', 'M'], nameValue),
                    const SizedBox(height: 8),
                    _buildNameKeyRow(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'], nameValue),
                    const SizedBox(height: 10),

                    Row(
                      children: List.generate(10, (index) {
                        Widget child = const SizedBox(height: 52);

                        if (index <= 3) {
                          child = _buildNamePadButton(
                            label: index == 1 ? 'Space' : '',
                            onTap: index == 1
                                ? () {
                              if (nameValue.value.length < 24) {
                                nameValue.value = '${nameValue.value} ';
                              }
                            }
                                : () {},
                          );
                        } else if (index == 5) {
                          child = _buildNamePadButton(
                            label: '⌫',
                            onTap: () {
                              if (nameValue.value.isNotEmpty) {
                                nameValue.value =
                                    nameValue.value.substring(0, nameValue.value.length - 1);
                              }
                            },
                          );
                        } else if (index == 7) {
                          child = _buildNamePadButton(
                            label: 'Clear',
                            onTap: () {
                              nameValue.value = '';
                            },
                          );
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: child,
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            Row(
              children: [
                Expanded(
                  child: _buildSilverButton(
                    label: 'Cancel',
                    height: 42,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: nameValue,
                    builder: (context, value, _) {
                      return _buildSilverButton(
                        label: 'Save',
                        height: 42,
                        isActive: true,
                        onTap: value.trim().isEmpty
                            ? null
                            : () => Navigator.of(context).pop(value.trim()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
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
        _customBenders.add(newBender);
        _updateBrandDropdown();
        _selectedBrand = newBender.model;
        _isEditMode = false;
      });
      _updateBenderData();
      _hideKeypad();
    }
  }

  Widget _buildNameKeyRow(List<String> keys, ValueNotifier<String> nameValue) {
    return Row(
      children: List.generate(10, (index) {
        final bool hasKey = index < keys.length;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: hasKey
                ? _buildNamePadButton(
              label: keys[index],
              onTap: () {
                if (nameValue.value.length < 24) {
                  nameValue.value = '${nameValue.value}${keys[index]}';
                }
              },
            )
                : const SizedBox(height: 52),
          ),
        );
      }),
    );
  }

  Widget _buildNamePadButton({
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return SizedBox(
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)]
                : [const Color(0xFF4E4E52), const Color(0xFF2C3030)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Back to Back 90'),
        foregroundColor: kLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelpDialog(context),
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
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
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
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                children: [
                  _buildBrandSelector(),
                  const SizedBox(height: 12),

                  _buildConduitTypeSelector(),
                  const SizedBox(height: 12),

                  _buildPipeSizeSelector(),

                  if (_isBenderSetupComplete) ...[
                    const SizedBox(height: 14),

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
                    const SizedBox(height: 12),

                    if (_showTravelField) ...[
                      _inlineField('90° Travel', travelCtrl),
                      const SizedBox(height: 12),
                    ],

                    _inlineField(
                      'Take Up',
                      takeUpCtrl,
                      onTap: _isEditMode ? () => _showKeypad(takeUpCtrl) : null,
                    ),
                    const SizedBox(height: 12),

                    _inlineField(
                      'Gain90',
                      gainCtrl,
                      onTap: _isEditMode ? () => _showKeypad(gainCtrl) : null,
                    ),
                    const SizedBox(height: 12),

                    _inlineField('Setback', setbackCtrl),
                    const SizedBox(height: 12),

                    _inlineField(
                      'Radius / CLR',
                      radiusCtrl,
                      onTap: _isEditMode ? () => _showKeypad(radiusCtrl) : null,
                    ),
                    const SizedBox(height: 16),

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
                      _buildSilverButton(
                        label: 'Create / Edit Custom Bender',
                        height: 44,
                        onTap: _toggleEditMode,
                      ),
                    ],

                    const SizedBox(height: 12),

                    _buildSilverButton(
                      label: 'Done',
                      height: 44,
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
                                _parallelClearSpace = 0.0;
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

  Widget _buildBrandSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white54)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBrand,
          isExpanded: true,
          hint: const Text(
              'Select Bender Brand', style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: kLight, fontSize: 18),
          items: _allBrands.map((brandData) {
            final type = brandData['type']!;
            final name = brandData['name']!;

            if (type == 'header') {
              return DropdownMenuItem<String>(
                value: 'header_$name',
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Text(
                        name,
                        style: const TextStyle(
                            color: kLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(color: Colors.white54, height: 1),
                  ],
                ),
              );
            }
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null && !newValue.startsWith('header_')) {
              setState(() => _selectedBrand = newValue);
              _updateBenderData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPipeSizeSelector() {
    // Get the filtered pipe sizes based on the currently selected brand
    final Map<String, String> filteredSizes = _getFilteredPipeSizes();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      decoration: BoxDecoration(color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white54)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPipeSize,
          isExpanded: true,
          hint: const Text(
              'Select Pipe Size', style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xFF333333),
          style: const TextStyle(color: kLight, fontSize: 18),
          // Use the filteredSizes map here
          items: filteredSizes.keys.map((String value) {
            return DropdownMenuItem<String>(
                value: value, child: Text(filteredSizes[value]!));
          }).toList(),
          onChanged: (newValue) {
            setState(() => _selectedPipeSize = newValue);
            _updateBenderData();
          },
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: const Text(
          'Back to Back 90 Help',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'Back-to-Back 90 — Pre-Cut Method',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This screen uses a pre-cut method. The cut length is calculated first, so you can usually pull your tape one time, mark the conduit, and then make both bends without stopping to measure off the back of a finished 90.',
                style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                'All bends in this method are made with the arrow.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'That is what makes this method different. Even when using the reverse-bender technique, you do not need the star here because the conduit is already pre-cut to the correct length.',
                style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
              ),

              SizedBox(height: 16),
              Text(
                'Push Through Method',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Push Through works best when the bends are closer together. After the first bend, you keep feeding the conduit through the bender and make the second bend without fully resetting your setup.',
                style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                'Reverse Bender Method',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Reverse Bender is helpful when the second bend is closer to the end of the conduit and there is not enough room to place the bender normally. In that case, you reverse the conduit in the bender and complete the second bend that way.',
                style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
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
                        color: isActive ? kGreen : Colors.white54,
                        width: isActive ? 2 : 1,
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
}

class _BackToBackResultGraphic extends StatelessWidget {
  static const double _resultMarksTopPadding = 6.0;
  static const double _resultPipeTopPadding = 10.0;
  static const double _resultPipeHeight = 18.0;
  static const double _resultMeasureTextTopPadding = 10.0;
  static const double _resultMeasureTextBottomPadding = 0.0;
  static const double _resultMeasureTextFontSize = 18.0;
  static const double _resultPipeBottomOffset = 10.0;
  static const double _resultMeasureTextBottomOffset = 0.0;
  const _BackToBackResultGraphic(
      {required this.markA, required this.markB, required this.markC});

  final String markA, markB, markC;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return Stack(
          alignment: Alignment.topLeft, clipBehavior: Clip.none, children: [
        Positioned(
          bottom: _resultPipeBottomOffset, left: -17, right: -23,
          child: Image.asset('assets/conduits/emt/pipe_5_ol.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high),
        ),
        _downMark(width * 0.9, 7, 'A', markA),
        _downMark(width * 0.4, 7, 'B', markB),
        _downMark(width * 0.11, 7, 'C', markC),
        const Positioned(
      bottom: _resultMeasureTextBottomOffset, right: 16,
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