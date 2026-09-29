import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:flutter/services.dart';
import 'code_screen.dart';
import 'package:pipe_and_wire_clean/keypad_6.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_menu_screen.dart';
import 'bender_picker_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BenderStartingPointScreen(),
    ),
  );
}

// ===== THEME =====
const kRed = Color(0xFFE53935);
const kBlack = Colors.black;
const kLight = Colors.white;
const kGreen = Color(0xFF4CAF50);


enum BoxLayoutConduitType { emt, grc } // Local enum for UI selection


class BenderStartingPointScreen extends StatefulWidget {
  const BenderStartingPointScreen({super.key});

  @override
  State<BenderStartingPointScreen> createState() => _BenderStartingPointScreenState();
}

class _BenderStartingPointScreenState extends State<BenderStartingPointScreen> with TickerProviderStateMixin {
  // State management for workflow
  int _currentStep = 0;
  bool _isBenderExpanded = true;
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;
  bool _showBendingMethodCard = false;
  bool _bendingMethodCardExpanded = false;
  bool _isCalculateReady = false;
  bool get _isBenderSetupComplete =>
      _selectedBrand != null && _selectedPipeSize != null;
  static const double _resultsGraphicBlockHeight = 315.0;
  static const double _topGraphicPlaceholderHeight = 200.0;
  static const double _spaceBetweenTopAndBottomGraphic = 1.0;
  static const double _bottomMeasurementGraphicHeight = 110.0;

  late final AnimationController _infoAnimCtrl;
  bool _hasViewedInfo = false;

  // Bender & Conduit State
  BoxLayoutConduitType _selectedConduitType = BoxLayoutConduitType.emt;
  String? _selectedPipeSize;
  String? _selectedBrand;
  List<Map<String, String>> get _brands => bending_data.getGroupedBenderBrands();
  bending_data.BendingMethod _bendingMethod = bending_data.BendingMethod.notch; // Uses BendingMethod from bending_data.dart

  // --- NEW: Custom Bender State ---
  bool _isEditMode = false;
  bool _isNewBender = false; // Flag to distinguish between Creating and Editing
  final List<bending_data.Bender> _customBenders = []; // Uses Bender from bending_data.dart
  List<Map<String, String>> _allBrands = []; // Combined list for dropdown

  // Controllers
  final measurement1Ctrl = TextEditingController();
  final measurement2Ctrl = TextEditingController();
  final measurement3Ctrl = TextEditingController();
  final travelCtrl = TextEditingController(); // Added travel controller
  final takeUpCtrl = TextEditingController();
  final gainCtrl = TextEditingController();
  final radiusCtrl = TextEditingController();
  final setbackCtrl = TextEditingController();


  // Output variables
  String markAOut = '';
  String markBOut = '';
  String markCOut = '';


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
    _loadCustomBenders();
    _updateBrandDropdown();


    final allInputCtrls = [
      measurement1Ctrl,
      measurement2Ctrl,
      measurement3Ctrl,
      travelCtrl, // Added travel controller
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
  }

  void _updateGainFromRadius() {
    if (!_isEditMode || _activeController != radiusCtrl) return;

    final radiusText = radiusCtrl.text.trim();
    if (radiusText.isEmpty || _selectedPipeSize == null) {
      gainCtrl.text = '';
      return;
    }

    final radius = _parseInches(radiusText);
    final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
        : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;

    if (pipeOD <= 0 || radius <= 0) return;

    final gain = bending_data.calculateGain90(radius, pipeOD);
    gainCtrl.text = fmtInches(gain, addInchMark: false);

    // Also update travel
    travelCtrl.text = fmtInches((math.pi * radius) / 2, addInchMark: false);

    _infoAnimCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _infoAnimCtrl.dispose();
    final allCtrls = [
      measurement1Ctrl,
      measurement2Ctrl,
      measurement3Ctrl,
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
    radiusCtrl.removeListener(_updateGainFromRadius);

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
          'type': 'custom_bender',
          'name': b.brand,
        }),
      ];
    });
  }

  void _updateCalculateButtonState() {
    final bool isReady = measurement1Ctrl.text.isNotEmpty &&
        measurement2Ctrl.text.isNotEmpty &&
        measurement3Ctrl.text.isNotEmpty &&
        _selectedPipeSize != null &&
        _selectedBrand != null;
    if (isReady != _isCalculateReady) {
      setState(() {
        _isCalculateReady = isReady;
      });
    }
  }

  Future<void> _loadCustomBenders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('rack_custom_benders');

    if (raw == null || raw.isEmpty) return;

    final List decoded = jsonDecode(raw);

    setState(() {
      _customBenders.clear();
      _customBenders.addAll(decoded.map((item) {
        return bending_data.Bender(
          brand: item['brand'],
          model: item['model'] ?? item['brand'],
          conduitSize: item['conduitSize'],
          conduitType: item['conduitType'] == 'rigid'
              ? bending_data.ConduitType.rigid
              : bending_data.ConduitType.emt,
          clr: (item['clr'] as num).toDouble(),
          deduct: (item['deduct'] as num).toDouble(),
          gain: (item['gain'] as num).toDouble(),
        );
      }));
      _updateBrandDropdown();
    });
  }

  Future<void> _saveCustomBendersToDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_customBenders.map((b) => {
      'brand': b.brand,
      'model': b.model,
      'conduitSize': b.conduitSize,
      'conduitType': b.conduitType == bending_data.ConduitType.rigid ? 'rigid' : 'emt',
      'clr': b.clr,
      'deduct': b.deduct,
      'gain': b.gain,
    }).toList());

    await prefs.setString('rack_custom_benders', encoded);
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
    if (!_isEditMode || _activeController != gainCtrl) return;

    final gainText = gainCtrl.text.trim();
    if (gainText.isEmpty || _selectedPipeSize == null) {
      radiusCtrl.text = '';
      return;
    }

    final gain = _parseInches(gainText);

    final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_getNumericalStringPipeSize(_selectedPipeSize!)]
        : bending_data.grcOD[_getNumericalStringPipeSize(_selectedPipeSize!)]) ?? 0.0;

    const double factor = 2 - (math.pi / 2);

    if (pipeOD <= 0 || gain <= pipeOD || factor == 0) {
      radiusCtrl.text = '';
      return;
    }

    final clr = bending_data.calculateCLRFromGain(gain, pipeOD);
    radiusCtrl.text = fmtInches(clr, addInchMark: false);

    // Also update travel
    travelCtrl.text = fmtInches((math.pi * clr) / 2, addInchMark: false);
  }

  String _getNumericalStringPipeSize(String pipeSizeDisplayString) {
    if (pipeSizeDisplayString.isEmpty) return '';
    final double numericalValue = _parseInches(pipeSizeDisplayString);
    return numericalValue.toString();
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

  void _startNewBend() {
    setState(() {
      measurement1Ctrl.clear();
      measurement2Ctrl.clear();
      measurement3Ctrl.clear();

      travelCtrl.clear();
      takeUpCtrl.clear();
      gainCtrl.clear();
      radiusCtrl.clear();
      setbackCtrl.clear();

      _selectedBrand = null;
      _selectedPipeSize = null;
      _selectedConduitType = BoxLayoutConduitType.emt;
      _bendingMethod = bending_data.BendingMethod.notch;

      markAOut = '';
      markBOut = '';
      markCOut = '';

      _isCalculateReady = false;
      _isEditMode = false;
      _isNewBender = false;
      _customBenderName = '';
      _showTravelField = false;

      _currentStep = 0;
      _isBenderExpanded = true;
      _isMeasurementsExpanded = false;
      _isResultsExpanded = false;
      _showBendingMethodCard = false;
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

  Map<String, String> _getFilteredPipeSizes() {
    return bending_data.getFilteredPipeSizes(_selectedBrand);
  }

  void calculate() {
    if (!_isCalculateReady) return;

    markAOut = '';
    markBOut = '';
    markCOut = '';

    setState(() {
      _currentStep = 3;
      _isBenderExpanded = false;
      _isMeasurementsExpanded = false;
      _isResultsExpanded = true;
      _hideKeypad();
    });
  }


  void _advanceKeypadFocus() {
    if (_activeController == measurement1Ctrl) {
      _showKeypad(measurement2Ctrl);
      return;
    }
    if (_activeController == measurement2Ctrl) {
      _showKeypad(measurement3Ctrl);
      return;
    }
    if (_activeController == measurement3Ctrl) {
      _hideKeypad();
      setState(() {
        _isMeasurementsExpanded = false;
        _showBendingMethodCard = true;
        _bendingMethodCardExpanded = true;
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

    setState(() {
      if (value == '⌫') {
        if (text.isNotEmpty) {
          controller.text = text.substring(0, text.length - 1);
        }
      } else if (value == '✔') {
        if (controller.text.isNotEmpty) {
          final decimalValue = _parseInches(controller.text);
          controller.text = fmtInches(decimalValue, addInchMark: false);
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
    });
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
      // Overwrite Logic:
      _customBenders.removeWhere((b) =>
          b.brand == name &&
          b.conduitSize == newBender.conduitSize &&
          b.conduitType == newBender.conduitType);

      _customBenders.add(newBender);
      _saveCustomBendersToDevice();
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
        _activeController!.text = fmtInches(decimalValue, addInchMark: false);
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
        // Balanced for Home + Back Arrow + Reset
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MainMenuScreen()),
                      (route) => false,
                );
              },
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
                    _showBendingMethodCard = false;
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
            'Starting Point',
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
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: ListView(
                children: [
                  if (!_isResultsExpanded) ...[
                    _buildBenderSection(),
                    const SizedBox(height: 6),

                    _buildMeasurementsSection(),
                    const SizedBox(height: 6),
                    
                    if (_showBendingMethodCard) ...[
                      _buildBendingMethodCard(),
                      const SizedBox(height: 6),
                    ],

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
                  const SizedBox(height: 6),

                  // MODIFIED: This button now disappears once a bender is selected
                  // It only shows if NO selection is made, or if we are actively editing
                  if (!_isEditMode && !_isBenderSetupComplete)
                    _buildSilverButton(
                        label: 'Create / Edit Custom Bender',
                        height: 40,
                        onTap: _toggleEditMode
                    ),

                  if (_isBenderSetupComplete || _isEditMode) ...[
                    const SizedBox(height: 10),

                    if (!_isEditMode)
                      _inlineField(
                        'Bender Model',
                        TextEditingController(
                          text: bending_data.benderDatabase
                              .firstWhereOrNull(
                                (b) =>
                            b.brand == _selectedBrand &&
                                b.conduitSize == _selectedPipeSize &&
                                b.conduitType == (
                                    _selectedConduitType ==
                                        BoxLayoutConduitType.emt ? bending_data
                                        .ConduitType.emt :
                                    bending_data.ConduitType.rigid
                                ),
                          )
                              ?.model ?? 'Custom',
                        ),
                        onTap: null,
                      ),

                    const SizedBox(height: 6),

                    if (_showTravelField)
                      _inlineField('90° Travel', travelCtrl, suffix: '"'),

                    _inlineField('Take Up', takeUpCtrl, onTap: _isEditMode
                        ? () => _showKeypad(takeUpCtrl)
                        : null, suffix: '"'),
                    _inlineField('Gain90', gainCtrl,
                        onTap: _isEditMode ? () => _showKeypad(gainCtrl) : null,
                        suffix: '"'),
                    _inlineField('Setback', setbackCtrl, suffix: '"'),
                    _inlineField('Radius / CLR', radiusCtrl, onTap: _isEditMode
                        ? () => _showKeypad(radiusCtrl) : null, suffix: '"'),

                    const SizedBox(height: 10),

                    if (_isEditMode)
                      Row(
                        children: [
                          Expanded(
                            child: _buildSilverButton(
                              label: 'Save Custom Bender',
                              height: 40,
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
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildSilverButton(label: 'Cancel',
                                height: 40,
                                onTap: _cancelEditMode),
                          ),
                        ],
                      )
                    else
                      _buildSilverButton(
                        label: 'Done',
                        height: 40,
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
            fontSize: 19,
            height: 60,
            isActive: _isMeasurementsExpanded,
            onTap: canOpen
                ? () {
              setState(() {
                _currentStep = 1;
                _isMeasurementsExpanded = !_isMeasurementsExpanded;

                if (_isMeasurementsExpanded) {
                  _isBenderExpanded = false;
                  _isResultsExpanded = false;
                  _showBendingMethodCard = false;
                }
              });
            }
                : null,
          ),
          if (_isMeasurementsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                children: [
                  _inlineField(
                    'Measurement A',
                    measurement1Ctrl,
                    onTap: () => _showKeypad(measurement1Ctrl),
                    suffix: '"',
                  ),
                  _inlineField(
                    'Measurement B',
                    measurement2Ctrl,
                    onTap: () => _showKeypad(measurement2Ctrl),
                    suffix: '"',
                  ),
                  _inlineField(
                    'Measurement C',
                    measurement3Ctrl,
                    onTap: () => _showKeypad(measurement3Ctrl),
                    suffix: '"',
                  ),
                  if (_isCalculateReady) ...[
                    const SizedBox(height: 10),
                    _buildSilverButton(
                      label: 'Continue',
                      height: 40,
                      isActive: true,
                      onTap: () {
                        _hideKeypad();
                        setState(() {
                          _isMeasurementsExpanded = false;
                          _showBendingMethodCard = true;
                          _bendingMethodCardExpanded = true;
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

  Widget _buildBendingMethodCard() {
    final bool isMachineBender =
        bending_data.mechanicalElectricBenderBrands.contains(_selectedBrand);
    return _buildGroupContainer(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _bendingMethodCardExpanded = !_bendingMethodCardExpanded;
              });
            },
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'BENDING METHOD',
                      style: TextStyle(
                        color: kLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _bendingMethodCardExpanded ? '⌃' : '⌄',
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
          if (_bendingMethodCardExpanded) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildSilverButton(
                    label: isMachineBender ? 'USE HOOK' : 'USE NOTCH',
                    height: 40,
                    isActive: isMachineBender
                        ? _bendingMethod == bending_data.BendingMethod.hook
                        : _bendingMethod == bending_data.BendingMethod.notch,
                    onTap: () {
                      setState(() {
                        _bendingMethod = isMachineBender
                            ? bending_data.BendingMethod.hook
                            : bending_data.BendingMethod.notch;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: _buildSilverButton(
                    label: 'USE CENTERLINE',
                    height: 40,
                    isActive: _bendingMethod == bending_data.BendingMethod.centerline,
                    onTap: () => setState(() => _bendingMethod = bending_data.BendingMethod.centerline),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculateSection() {
    return _buildGroupContainer(
      child: _buildSilverButton(
        label: '3. CALCULATE',
        isActive: _showBendingMethodCard,
        isCheckmark: _showBendingMethodCard,
        height: 60,
        fontSize: 20,
        onTap: _showBendingMethodCard
            ? () {
          _hideKeypad();
          setState(() {
            _currentStep = 3;
            _isBenderExpanded = false;
            _isMeasurementsExpanded = false;
            _isResultsExpanded = true;
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
              padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
              child: Column(
                children: [
                  _resultRow('Mark A — Bend A', markAOut),
                  _resultRow('Mark B — Bend B', markBOut),
                  _resultRow('Mark C — Cut Length', markCOut),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Start New Bend',
                          height: 40,
                          onTap: _startNewBend,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSilverButton(
                          label: 'Option',
                          height: 40,
                          onTap: () {},
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

  Widget _resultRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
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
        const SizedBox(width: 6.0), // Center gap now matches border gap
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


  void _showBrandPicker() {
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
              _selectedConduitType = custom.conduitType == bending_data.ConduitType.emt
                  ? BoxLayoutConduitType.emt
                  : BoxLayoutConduitType.grc;
            }
          });
          _updateBenderData();
        },
        onDelete: (name) {
          setState(() {
            _customBenders.removeWhere((b) => b.brand == name);
            _saveCustomBendersToDevice();
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
              _selectedConduitType = bender.conduitType == bending_data.ConduitType.emt
                  ? BoxLayoutConduitType.emt
                  : BoxLayoutConduitType.grc;

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
      onTap: _showBrandPicker,
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
          'Starting Point Help',
          style: TextStyle(
            color: kLight,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text(
                  'Generic starting point for new bending calculations.',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Use this tool to find layout marks for any angle based on your bender\'s characteristics.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 20),
                Text(
                  'Use Notch:',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Standard for hand benders. Pipe & Wire translates center-of-bend measurements to the 45° notch / teardrop.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Hook:',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Standard for machine benders. Pipe & Wire translates center-of-bend measurements to the front edge of the hook.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.4),
                ),
                SizedBox(height: 16),
                Text(
                  'Use Centerline:',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  }

  Widget _buildInfoBar() {
    String message;

    if (_isResultsExpanded) {
      message = 'Bender Starting Point complete. Marks are measured from one end.';
    } else if (_isBenderExpanded) {
      message = 'Select your bender, conduit type, and pipe size.\nYou can also create and save your own custom bender.';
    } else if (_showBendingMethodCard && _bendingMethodCardExpanded) {
      final bool isMachineBender =
          bending_data.mechanicalElectricBenderBrands.contains(_selectedBrand);
      if (isMachineBender) {
        message = 'USE HOOK:\n'
            'Translates center-of-bend to the front edge of the bender hook.\n\n'
            'USE CENTERLINE:\n'
            'Choose this if you have marked your own center-of-bend lines on the shoe.';
      } else {
        message = 'USE NOTCH:\n'
            'Translates center-of-bend to the 45° notch / teardrop on your hand bender.\n\n'
            'USE CENTERLINE:\n'
            'Choose this if your bender already has center-of-bend markings.';
      }
    } else if (_isMeasurementsExpanded) {
      message = 'Enter the measurements for your bend.';
    } else if (_currentStep == 2) {
      message = 'Tap CALCULATE to generate your marks.';
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
      padding: const EdgeInsets.all(6.0), // Uniform 6px gap to the border
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
      ),
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

    // NEW: Logic to prevent double symbols (°) or (")
    // If the controller already has the symbol, we hide the suffix logic.
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

class _BeveledButton extends StatelessWidget {
  const _BeveledButton(
      {this.active = false, required this.onTap, required this.child});

  final bool active;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Container(
      height: 46,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: active
                  ? [const Color(0xFF8A1010), const Color(0xFFD12A2A)]
                  : enabled
                  ? [const Color(0xFF4E4E52), const Color(0xFF2C3030)]
                  : [Colors.grey.shade800, Colors.grey.shade900]
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1)
      ),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Center(child: child)
          )
      ),
    );
  }
}
class _StarterResultGraphic extends StatelessWidget {
  static const double _marksTopPosition = 7.0;
  static const double _resultPipeBottomOffset = 10.0;
  static const double _resultMeasureTextBottomOffset = 0.0;

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
            left: 6,
            right: 6,
            child: Image.asset(
              'assets/conduits/emt/pipe_5_ol.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          _downMark(width * 0.9, _marksTopPosition, 'A', markA),
          _downMark(width * 0.4, _marksTopPosition, 'B', markB),
          _downMark(width * 0.11, _marksTopPosition, 'C', markC),
          Positioned(
            bottom: _resultMeasureTextBottomOffset,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Measure from this end',
                  style: TextStyle(
                    color: kLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "➜",
                  style: TextStyle(
                    color: kLight,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
          const RotatedBox(
            quarterTurns: 1,
            child: Text(
              "➜",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

