import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:flutter/services.dart';
import 'code_screen.dart';
import 'package:pipe_and_wire_clean/keypad_6.dart';
import 'package:pipe_and_wire_clean/rack_builder_11.dart';
import 'package:provider/provider.dart';
import 'package:pipe_and_wire_clean/rack_state.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Kick90Screen(),
    ),
  );
}

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);


enum BoxLayoutConduitType { emt, grc } // Local enum for UI selection


class Kick90Screen extends StatefulWidget {
  const Kick90Screen({super.key});

  @override
  State<Kick90Screen> createState() => _Kick90ScreenState();
}

class _Kick90ScreenState extends State<Kick90Screen> {
  // State management for workflow
  int _currentStep = 0;
  bool _isBenderExpanded = true;
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;
  bool _isCalculateReady = false;
  bool get _isBenderSetupComplete =>
      _selectedBrand != null && _selectedPipeSize != null;
  static const double _resultsGraphicBlockHeight = 315.0;
  static const double _topGraphicPlaceholderHeight = 200.0;
  static const double _spaceBetweenTopAndBottomGraphic = 1.0;
  static const double _bottomMeasurementGraphicHeight = 110.0;

  // Bender & Conduit State
  BoxLayoutConduitType _selectedConduitType = BoxLayoutConduitType.emt;
  String? _selectedPipeSize;
  String? _selectedBrand;
  List<Map<String, String>> get _brands {
    final handBenders = bending_data.benderDatabase
        .where((b) =>
    !bending_data.mechanicalElectricBenderBrands.contains(b.brand))
        .map((b) => b.brand)
        .toSet()
        .toList()
      ..sort();

    final mechanicalElectric = bending_data.benderDatabase
        .where((b) =>
        bending_data.mechanicalElectricBenderBrands.contains(b.brand))
        .map((b) => b.brand)
        .toSet()
        .toList()
      ..sort();

    return [
      {'type': 'header', 'name': 'HAND BENDERS'},
      ...handBenders.map((name) => {'type': 'bender', 'name': name}),

      {'type': 'header', 'name': 'MECHANICAL / ELECTRIC'},
      ...mechanicalElectric.map((name) => {'type': 'bender', 'name': name}),
    ];
  }
  bending_data.BendingMethod _bendingMethod = bending_data.BendingMethod.arrow; // Uses BendingMethod from bending_data.dart

  // --- NEW: Custom Bender State ---
  bool _isEditMode = false;
  final List<bending_data.Bender> _customBenders = []; // Uses Bender from bending_data.dart
  List<Map<String, String>> _allBrands = []; // Combined list for dropdown

  // Controllers
  final stubCtrl = TextEditingController();
  final kickCtrl = TextEditingController();
  final angleCtrl = TextEditingController();
  final legCtrl = TextEditingController();
  final travelCtrl = TextEditingController(); // Added travel controller
  final takeUpCtrl = TextEditingController();
  final gainCtrl = TextEditingController();
  final radiusCtrl = TextEditingController();
  final setbackCtrl = TextEditingController();


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


  @override
  void initState() {
    super.initState();
    _updateBrandDropdown();


    final allInputCtrls = [
      stubCtrl,
      kickCtrl,
      angleCtrl,
      legCtrl,
      travelCtrl,
      takeUpCtrl,
      gainCtrl,
      radiusCtrl,
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
      stubCtrl,
      kickCtrl,
      angleCtrl,
      legCtrl,
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
        ..._brands,
        {'type': 'header', 'name': 'SAVED BENDERS'},
        ..._customBenders.map((b) => {
          'type': 'bender',
          'name': b.brand,
        }),
      ];
    });
  }

  void _updateCalculateButtonState() {
    final bool isReady = stubCtrl.text.isNotEmpty &&
        kickCtrl.text.isNotEmpty &&
        angleCtrl.text.isNotEmpty &&
        legCtrl.text.isNotEmpty &&
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

    setbackCtrl.text = fmtInches(setback, addInchMark: false);
  }
  void _updateRadiusFromGain() {
    if (!_isEditMode) return;

    final gainText = gainCtrl.text.trim();
    if (gainText.isEmpty || _selectedPipeSize == null) {
      radiusCtrl.text = '';
      return;
    }

    final gain = _parseInches(gainText);

    final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
        : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;

    final double factor = 2 - (math.pi / 2);

    if (pipeOD <= 0 || gain <= pipeOD || factor == 0) {
      radiusCtrl.text = '';
      return;
    }

    final clr = (gain - pipeOD) / factor;
    radiusCtrl.text = fmtInches(clr, addInchMark: false);
  }

  String _getNumericalStringPipeSize(String pipeSizeDisplayString) {
    if (pipeSizeDisplayString.isEmpty) return '';
    final double numericalValue = _parseInches(pipeSizeDisplayString);
    return numericalValue.toString();
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
        _isBenderExpanded = true;
      });
      return;
    }

    // Try to find a custom bender first
    bending_data.Bender? bender = _customBenders.firstWhereOrNull(
            (b) => b.model == _selectedBrand && b.conduitSize == _selectedPipeSize &&
            (b.conduitType == (
                _selectedConduitType == BoxLayoutConduitType.emt ? bending_data.ConduitType.emt :
                bending_data.ConduitType.rigid // Only EMT or GRC (Rigid) allowed
            )
            )
    );

    // If not found in custom benders, search the main benderDatabase (from bending_data.dart)
    bender ??= bending_data.benderDatabase.firstWhereOrNull(
            (b) => b.brand == _selectedBrand && b.conduitSize == _selectedPipeSize &&
            (b.conduitType == (
                _selectedConduitType == BoxLayoutConduitType.emt ? bending_data.ConduitType.emt :
                bending_data.ConduitType.rigid // Only EMT or GRC (Rigid) allowed
            )
            )
    );

    double calculatedGain = 0.0;
    double calculatedTravel = 0.0; // Declare calculatedTravel
    if (bender != null) {
      final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
          ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)] // Uses emtOD from bending_data.dart
          : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0; // Uses grcOD from bending_data.dart

      if (bender.clr > 0 && pipeOD > 0) {
        calculatedGain = bending_data.calculateGain90(bender.clr, pipeOD); // Uses calculateGain90 from bending_data.dart
      }
      calculatedTravel = (math.pi * bender.clr) / 2; // Calculate 90° Travel
    }

    setState(() {
      _rawTakeUp = bender?.deduct ?? 0.0;
      _rawGain = calculatedGain;

      travelCtrl.text = bender != null ? fmtInches(calculatedTravel, addInchMark: false) : ''; // Display 90° Travel
      takeUpCtrl.text = bender != null ? fmtInches(bender.deduct, addInchMark: false) : '';
      gainCtrl.text = bender != null
          ? fmtInches(calculatedGain, addInchMark: false)
          : '';
      radiusCtrl.text = bender != null ? fmtInches(bender.clr, addInchMark: false) : '';

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
      _isResultsExpanded = step == 3;

      if (step < 3) {
        markAOut = '';
        markBOut = '';
        markCOut = '';
      }
    });
  }

  void _startNewBend() {
    setState(() {
      stubCtrl.clear();
      kickCtrl.clear();
      angleCtrl.clear();
      legCtrl.clear();

      travelCtrl.clear();
      takeUpCtrl.clear();
      gainCtrl.clear();
      radiusCtrl.clear();
      setbackCtrl.clear();

      _selectedBrand = null;
      _selectedPipeSize = null;
      _selectedConduitType = BoxLayoutConduitType.emt;
      _bendingMethod = bending_data.BendingMethod.arrow;

      markAOut = '';
      markBOut = '';
      markCOut = '';
      _rawMarkA = 0.0;
      _rawMarkB = 0.0;
      _rawCut = 0.0;

      _isCalculateReady = false;
      _isEditMode = false;
      _showTravelField = false;

      _currentStep = 0;
      _isBenderExpanded = true;
      _isMeasurementsExpanded = false;
      _isResultsExpanded = false;
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
      text = text.replaceAll('"', '').replaceAll('°', '').trim(); // Remove degree symbol too
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
  double _csc(double degrees) {
    final radians = degrees * math.pi / 180.0;
    final s = math.sin(radians);
    if (s == 0) return 0.0;
    return 1.0 / s;
  }

  double _tanHalf(double degrees) {
    final radians = degrees * math.pi / 180.0;
    return math.tan(radians / 2.0);
  }

  double _hookCenterFor(double thetaDeg) {
    final r = _parseInches(radiusCtrl.text);
    final angleOnArc = thetaDeg / 2.0;
    return (math.pi * r * angleOnArc) / 180.0;
  }
  double _parseAngle(String text) {
    final cleaned = text
        .replaceAll('°', '')
        .replaceAll('"', '')
        .trim();

    if (cleaned.isEmpty) return 0.0;

    return _parseInches(cleaned);
  }
  Map<String, String> _getFilteredPipeSizes() {
    if (_selectedBrand == null) {
      return bending_data.pipeSizes; // Uses pipeSizes from bending_data.dart
    }

    final List<String> availableSizes = [];
    switch (_selectedBrand) {
      case 'Ideal':
      case 'Klein':
      case 'Gardner Bender':
      // Hand benders usually go up to 1.25"
        final int maxIndex = bending_data.pipeSizeOrder.indexOf('1.25'); // Uses pipeSizeOrder from bending_data.dart
        availableSizes.addAll(bending_data.pipeSizeOrder.sublist(0, maxIndex + 1));
        break;
      case 'Milwaukee':
      // Milwaukee hand benders usually go up to 1"
        final int maxIndex = bending_data.pipeSizeOrder.indexOf('1.0');
        availableSizes.addAll(bending_data.pipeSizeOrder.sublist(0, maxIndex + 1));
        break;
      case 'Greenlee 1818':
      case 'Greenlee 555':
      // Mechanical/Electric benders go up to 2"
        final int maxIndex = bending_data.pipeSizeOrder.indexOf('2.0');
        availableSizes.addAll(bending_data.pipeSizeOrder.sublist(0, maxIndex + 1));
        break;
      default:
      // For custom benders or others, show all sizes
        availableSizes.addAll(bending_data.pipeSizeOrder);
        break;
    }

    return Map.fromEntries(
      bending_data.pipeSizes.entries.where((entry) => availableSizes.contains(entry.key)),
    );
  }

  void calculate() {
    if (!_isCalculateReady) return;

    final stub = _parseInches(stubCtrl.text);
    final kickHeight = _parseInches(kickCtrl.text);
    final angleDeg = _parseAngle(angleCtrl.text);
    final leg = _parseInches(legCtrl.text);

    final takeUp = _parseInches(takeUpCtrl.text);
    final gain90 = _parseInches(gainCtrl.text);

    final pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
        : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ??
        0.0;

    if (stub == 0 || kickHeight == 0 || angleDeg == 0 || pipeOD == 0) return;

    final markA = stub - takeUp;
    final hypotenuse = kickHeight * _csc(angleDeg);
    final centerlineHypotenuse = hypotenuse - (pipeOD / 2.0);
    final centerKick = (stub - gain90) + centerlineHypotenuse;

    final double markB;
    if (_bendingMethod == bending_data.BendingMethod.arrow) {
      final arcLength = _hookCenterFor(angleDeg);
      markB = centerKick - arcLength;
    } else {
      markB = centerKick;
    }

    final shrink = kickHeight * _tanHalf(angleDeg);
    final olVal = stub + leg - gain90 + shrink;

    setState(() {
      _rawMarkA = markA;
      _rawMarkB = markB;
      _rawCut = olVal;

      markAOut = fmtInches(markA);
      markBOut = fmtInches(markB);
      markCOut = fmtInches(olVal);

      _currentStep = 3;
      _isResultsExpanded = true;
      _isMeasurementsExpanded = false;
      _isBenderExpanded = false;
    });

    _hideKeypad();
  }


  void _advanceKeypadFocus() {
    if (_activeController == stubCtrl) {
      _showKeypad(kickCtrl);
      return;
    }
    if (_activeController == kickCtrl) {
      _showKeypad(angleCtrl);
      return;
    }
    if (_activeController == angleCtrl) {
      _showKeypad(legCtrl);
      return;
    }
    if (_activeController == legCtrl) {
      calculate();
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
      _hideKeypad();
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
        controller.text = fmtInches(decimalValue, addInchMark: false); // Changed to always false
      }
      _advanceKeypadFocus(); // Advance focus after '✔'
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
      conduitType: _selectedConduitType == BoxLayoutConduitType.emt
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

    _updateBenderData();
    _hideKeypad();
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
        _activeController!.text = fmtInches(decimalValue, addInchMark: false); // Changed to always false
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Kick 90'),
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
                      border: Border.all(
                        color: const Color(0xFFC0C0C0),
                        width: 1.5,
                      ),
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
  Widget _sectionCard({
    required String title,
    bool isActive = false,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white54,
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: isActive
                      ? const [Color(0xFF8A1010), Color(0xFFD12A2A)]
                      : const [Color(0xFF5A5A5F), Color(0xFF232626)],
                ),
                border: Border.all(
                  color: Colors.white38,
                  width: 1.3,
                ),
              ),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (isActive && child != null) ...[
              const SizedBox(height: 10),
              child,
            ],
          ],
        ),
      ),
    );
  }
  Widget _actionButton(String label, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
        gradient: LinearGradient(
          colors: selected
              ? const [Color(0xFF7D1111), Color(0xFFB02020)]
              : const [Color(0xFF3A3A3A), Color(0xFF1E1E1E)],
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  Widget _fullButton(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3A3A), Color(0xFF1E1E1E)],
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  Widget _inputRow(String label) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 120,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withAlpha(180), width: 2),
          ),
        ),
      ],
    );
  }
  Widget _dropdownField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: const TextStyle(color: Colors.white54)),
          const Icon(Icons.arrow_drop_down, color: Colors.white54),
        ],
      ),
    );
  }
  Widget _infoBar(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
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


                    const SizedBox(height: 14),

                    if (_showTravelField) ...[
                      _inlineField('90° Travel', travelCtrl, suffix: '"'),
                      const SizedBox(height: 12),
                    ],

                    _inlineField(
                      'Take Up',
                      takeUpCtrl,
                      onTap: _isEditMode ? () => _showKeypad(takeUpCtrl) : null,
                      suffix: '"',
                    ),
                    const SizedBox(height: 12),

                    _inlineField(
                      'Gain90',
                      gainCtrl,
                      onTap: _isEditMode ? () => _showKeypad(gainCtrl) : null,
                      suffix: '"',
                    ),
                    const SizedBox(height: 12),

                    _inlineField('Setback', setbackCtrl, suffix: '"'),
                    const SizedBox(height: 12),

                    _inlineField(
                      'Radius / CLR',
                      radiusCtrl,
                      onTap: _isEditMode ? () => _showKeypad(radiusCtrl) : null,
                      suffix: '"',
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
                  _inlineField(
                    'Stub Height',
                    stubCtrl,
                    onTap: () => _showKeypad(stubCtrl),
                    suffix: '"',
                  ),
                  _inlineField(
                    'Kick Height',
                    kickCtrl,
                    onTap: () => _showKeypad(kickCtrl),
                    suffix: '"',
                  ),
                  _inlineField(
                    'Kick Angle',
                    angleCtrl,
                    onTap: () => _showKeypad(angleCtrl),
                    suffix: '°',
                  ),
                  _inlineField(
                    'Leg Length',
                    legCtrl,
                    onTap: () => _showKeypad(legCtrl),
                    suffix: '"',
                  ),
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
                  _buildResultModeButtons(),

                  const SizedBox(height: 6),

                  _resultRow('Mark A — Bend A', markAOut),
                  _resultRow('Mark B — Bend B', markBOut),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider(
                                  create: (_) => RackState(),
                                  child: RackBuilderScreen(
                                    initialMarkA: _rawMarkA,
                                    initialMarkB: _rawMarkB,
                                    initialCut: _rawCut,
                                    initialAngle: _parseAngle(angleCtrl.text),
                                    initialGain: _rawGain,
                                    initialTakeup: _rawTakeUp,
                                  ),
                                ),
                              ),
                            );
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
                          height: _topGraphicPlaceholderHeight,
                          child: ClipRect(
                            child: OverflowBox(
                              maxWidth: double.infinity,
                              maxHeight: double.infinity,
                              child: Transform.translate(
                                offset: const Offset(0, 20),
                                child: Image.asset(
                                  'assets/conduits/emt/pipe_1.png',
                                  width: MediaQuery.of(context).size.width * 1.0,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: _spaceBetweenTopAndBottomGraphic),

                        SizedBox(
                          height: _bottomMeasurementGraphicHeight,
                          child: _StarterResultGraphic(
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
  Widget _buildResultModeButtons() {
    final bool useArrow =
        _bendingMethod == bending_data.BendingMethod.arrow;

    return Row(
      children: [
        Expanded(
          child: _buildSilverButton(
            label: 'Use Arrow',
            height: 40,
            isActive: useArrow,
            onTap: () {
              setState(() {
                _bendingMethod = bending_data.BendingMethod.arrow;
              });

              if (_isCalculateReady) calculate();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSilverButton(
            label: 'Use Centerline',
            height: 40,
            isActive: !useArrow,
            onTap: () {
              setState(() {
                _bendingMethod = bending_data.BendingMethod.centerline;
              });

              if (_isCalculateReady) calculate();
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
                  value.isEmpty ? '—' : value,
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
  Widget _buildBenderSetupFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          _buildBrandSelector(),
          const SizedBox(height: 12),
          _buildConduitTypeSelector(),
          const SizedBox(height: 12),
          _buildPipeSizeSelector(),


          const SizedBox(height: 12),
          if (_showTravelField) // Conditionally display the travel field
            _inlineField('90° Travel', travelCtrl, suffix: '"'),
          _inlineField('Take Up', takeUpCtrl,
              onTap: _isEditMode ? () => _showKeypad(takeUpCtrl) : null, suffix: '"'),
          _inlineField('Gain90', gainCtrl,
              onTap: _isEditMode ? () => _showKeypad(gainCtrl) : null, suffix: '"'),
          _inlineField('Setback', setbackCtrl, suffix: '"'),
          _inlineField('Radius / CLR', radiusCtrl,
              onTap: _isEditMode ? () => _showKeypad(radiusCtrl) : null, suffix: '"'),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  Widget _buildConduitTypeSelector() {
    return Row(
      children: [
        Expanded(child: _buildSilverButton(label: 'EMT',
            height: 40,
            isActive: _selectedConduitType == BoxLayoutConduitType.emt,
            onTap: () {
              setState(() => _selectedConduitType = BoxLayoutConduitType.emt);
              _updateBenderData();
            })),
        const SizedBox(width: 10),
        Expanded(child: _buildSilverButton(label: 'Rigid',
            height: 40,
            isActive: _selectedConduitType == BoxLayoutConduitType.grc,
            onTap: () {
              setState(() => _selectedConduitType = BoxLayoutConduitType.grc);
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
          items: _getFilteredPipeSizes().keys.map((String value) {
            return DropdownMenuItem<String>(
                value: value, child: Text(bending_data.pipeSizes[value]!));
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
        backgroundColor: kBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC0C0C0), width: 1.4),
        ),
        title: const Text(
          'Kick 90',
          style: TextStyle(
            color: kLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'This tool calculates layout marks for a Kick 90 bend.\n\n'
                'The main goal is to lay out your cut mark and bend marks in one pull of the tape measure. '
                'You do not have to bend the 90, lay it down, and re-measure from the back of the 90. '
                'This eliminates stacked measurement errors and saves time in the field.\n\n'
                'Use Arrow:\n'
                'This lets your bender arrow act as the center of bend for the selected angle. '
                'The app adjusts your bend mark so you can place the arrow directly on the mark without charting centerlines.\n\n'
                'Use Centerline:\n'
                'This mode uses true center-of-bend marks. Use this if your bender is charted and you prefer marking the exact center of bend on the shoe.\n\n'
                'Parallel:\n'
                'Sends your results into Rack Builder so you can build multiple parallel kicks and keep them aligned.',
            style: TextStyle(
              color: kLight,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: kLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    String message;

    if (_isResultsExpanded) {
      if (_bendingMethod == bending_data.BendingMethod.arrow) {
        message =
        'Use Arrow lets your bender arrow act as the center of bend for the selected angle.';
      } else {
        message =
        'Use Centerline is for bends where you mark and use the actual center of bend on the shoe.';
      }
    } else if (_isBenderExpanded) {
      message = 'Select your bender, conduit type, and pipe size.';
    } else if (_isMeasurementsExpanded) {
      message = 'Enter stub height, kick height, kick angle, and leg length.';
    } else if (_currentStep == 2) {
      message = 'Tap Calculate to generate your Kick 90 marks.';
    } else {
      message = 'Start with your bender and conduit setup.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      constraints: const BoxConstraints(
        minHeight: 125,
      ),
      decoration: BoxDecoration(
        color: kBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC0C0C0),
          width: 1.4,
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kLight,
          fontSize: 18,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5)),
      child: child,
    );
  }

  Widget _buildSilverButton(
      {required String label, VoidCallback? onTap, bool isActive = false, bool isCheckmark = false, double height = 44, double fontSize = 15}) {
    final bool isEnabled = onTap != null;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey.shade500,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700)),
                if (isCheckmark) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: kGreen, size: 24)
                ]
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
    final bool isEditable = !isReadOnly;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: kLight))),
          const SizedBox(width: 12),
          SizedBox(
            width: 140, height: 48,
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
                        vertical: 14, horizontal: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: isActive ? kGreen : Colors.white54,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: kGreen, width: 2)),
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
class _StarterResultGraphic extends StatelessWidget {
  static const double _resultPipeBottomOffset = 15.0;
  static const double _resultMeasureTextBottomOffset = 2.0;

  const _StarterResultGraphic({
    required this.markA,
    required this.markB,
    required this.markC,
  });

  final String markA;
  final String markB;
  final String markC;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;

      return Stack(
        alignment: Alignment.topLeft,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: _resultPipeBottomOffset,
            left: -17,
            right: -23,
            child: Image.asset(
              'assets/conduits/emt/pipe_5_ol.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          _downMark(width * 0.9, 7, 'A', markA),
          _downMark(width * 0.4, 7, 'B', markB),
          _downMark(width * 0.11, 7, 'C', markC),
          const Positioned(
            bottom: _resultMeasureTextBottomOffset,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Measure from this end',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: kLight, size: 18),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _downMark(double x, double top, String label, String value) {
    return Positioned(
      left: x - 40,
      top: top + 15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(191),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              '$label: ${value.isEmpty ? "—" : value}',
              style: const TextStyle(
                color: kLight,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const Icon(Icons.arrow_downward, color: Colors.white70, size: 18),
        ],
      ),
    );
  }
}