import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;

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

  // Bender & conduit state
  BoxLayoutConduitType _selectedConduitType = BoxLayoutConduitType.emt;
  String? _selectedPipeSize;
  String? _selectedBrand;
  final List<Map<String, String>> _brands = [
    {'type': 'header', 'name': 'HAND BENDERS'},
    {'type': 'bender', 'name': 'IDEAL'},
    {'type': 'bender', 'name': 'Klein'},
    {'type': 'bender', 'name': 'Gardner Bender'},
    {'type': 'bender', 'name': 'Milwaukee'},
    {'type': 'header', 'name': 'MECHANICAL / ELECTRIC'},
    {'type': 'bender', 'name': 'Greenlee 1818'},
    {'type': 'bender', 'name': 'Greenlee 555'},
  ];
  bending_data.BendingMethod _bendingMethod =
      bending_data.BendingMethod.arrow;

  // Custom benders
  bool _isEditMode = false;
  final List<bending_data.Bender> _customBenders = [];
  List<Map<String, String>> _allBrands = [];

  // Controllers
  final measurement1Ctrl = TextEditingController(); // Stub Height
  final measurement2Ctrl = TextEditingController(); // Number of Shots
  final measurement3Ctrl =
  TextEditingController(); // Straight Before Bend (optional)

  final travelCtrl = TextEditingController();
  final takeUpCtrl = TextEditingController();
  final gainCtrl = TextEditingController();
  final radiusCtrl = TextEditingController();
  final setbackCtrl = TextEditingController();

  // Output variables
  String markAOut = '';
  String markBOut = '';
  String markCOut = '';
  String spacingOut = '';
  String shotsOut = '';
  String anglePerShotOut = '';

  // Raw values
  double _rawTakeUp = 0.0;
  double _rawGain = 0.0;

  // Keypad state
  bool _isKeypadVisible = false;
  TextEditingController? _activeController;

  // Travel field visibility
  bool _showTravelField = false;

  @override
  void initState() {
    super.initState();
    _updateBrandDropdown();

    final allInputCtrls = [
      measurement1Ctrl,
      measurement2Ctrl,
      measurement3Ctrl,
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
  }

  @override
  void dispose() {
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
      ctrl.dispose();
    }

    super.dispose();
  }

  void _updateBrandDropdown() {
    setState(() {
      _allBrands = [
        ..._brands,
        if (_customBenders.isNotEmpty)
          {'type': 'header', 'name': '--- MY BENDERS ---'},
        ..._customBenders.map((b) => {'type': 'bender', 'name': b.brand}),
      ];
    });
  }

  void _updateCalculateButtonState() {
    final bool hasRadius = radiusCtrl.text.isNotEmpty;
    final bool hasShots = measurement2Ctrl.text.isNotEmpty;
    final bool hasPipeSize = _selectedPipeSize != null;

    final bool needsStub = _segmentedMode == SegmentedMode.stubbed90;
    final bool hasStub = measurement1Ctrl.text.isNotEmpty;

    final bool isReady = hasRadius &&
        hasShots &&
        hasPipeSize &&
        (!needsStub || hasStub);

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


  void _updateSetback() {
    final takeUp = _parseInches(takeUpCtrl.text);
    final gain = _parseInches(gainCtrl.text);
    final setback = takeUp - gain;
    setbackCtrl.text = fmtInches(setback);
  }

  void _updateBenderData() {
    if (_selectedBrand == null || _selectedPipeSize == null) {
      setState(() {
        travelCtrl.text = '';
        takeUpCtrl.text = '';
        gainCtrl.text = '';
        setbackCtrl.text = '';
        _showTravelField = false;
      });
      return;
    }

    bending_data.Bender? bender = _customBenders.firstWhereOrNull(
          (b) =>
      b.model == _selectedBrand &&
          b.conduitSize == _selectedPipeSize &&
          (b.conduitType ==
              (_selectedConduitType == BoxLayoutConduitType.emt
                  ? bending_data.ConduitType.emt
                  : bending_data.ConduitType.rigid)),
    );

    bender ??= bending_data.benderDatabase.firstWhereOrNull(
          (b) =>
      b.brand == _selectedBrand &&
          b.conduitSize == _selectedPipeSize &&
          (b.conduitType ==
              (_selectedConduitType == BoxLayoutConduitType.emt
                  ? bending_data.ConduitType.emt
                  : bending_data.ConduitType.rigid)),
    );

    double calculatedGain = 0.0;
    double calculatedTravel = 0.0;

    if (bender != null) {
      final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
          ? bending_data.emtOD[_selectedPipeSize]
          : bending_data.grcOD[_selectedPipeSize]) ??
          0.0;

      if (bender.clr > 0 && pipeOD > 0) {
        calculatedGain = bending_data.calculateGain90(bender.clr, pipeOD);
      }

      calculatedTravel = (math.pi * bender.clr) / 2;
    }

    setState(() {
      _rawTakeUp = bender?.deduct ?? 0.0;
      _rawGain = calculatedGain;

      travelCtrl.text = bender != null ? fmtInches(calculatedTravel) : '';
      takeUpCtrl.text = bender != null ? fmtInches(bender.deduct) : '';
      gainCtrl.text = bender != null ? fmtInches(calculatedGain) : '';

      // only overwrite radius if a valid bender was found
      // if (bender != null) {
      //   radiusCtrl.text = fmtInches(bender.clr);
      // }

      // Hide this for now so it doesn't confuse segmented DL with shoe travel
      _showTravelField = false;

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
      spacingOut = '';
      shotsOut = '';
      anglePerShotOut = '';

      _isCalculateReady = false;
      _isResultsExpanded = false;
      _isEditMode = false;
      _showTravelField = false;

      _resetToStep(0);
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

  Map<String, String> _getFilteredPipeSizes() {
    if (_selectedBrand == null) {
      return bending_data.pipeSizes;
    }

    final List<String> availableSizes = [];

    switch (_selectedBrand) {
      case 'IDEAL':
      case 'Klein':
      case 'Gardner Bender':
        final int maxIndex = bending_data.pipeSizeOrder.indexOf('1.25');
        availableSizes
            .addAll(bending_data.pipeSizeOrder.sublist(0, maxIndex + 1));
        break;

      case 'Milwaukee':
        final int maxIndex = bending_data.pipeSizeOrder.indexOf('1.0');
        availableSizes
            .addAll(bending_data.pipeSizeOrder.sublist(0, maxIndex + 1));
        break;

      case 'Greenlee 1818':
      case 'Greenlee 555':
        final int maxIndex = bending_data.pipeSizeOrder.indexOf('2.0');
        availableSizes
            .addAll(bending_data.pipeSizeOrder.sublist(0, maxIndex + 1));
        break;

      default:
        availableSizes.addAll(bending_data.pipeSizeOrder);
        break;
    }

    return Map.fromEntries(
      bending_data.pipeSizes.entries
          .where((entry) => availableSizes.contains(entry.key)),
    );
  }

  Future<void> _showRadiusFinderDialog() async {
    final widthCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final diameterCtrl = TextEditingController();
    final circumferenceCtrl = TextEditingController();

    String mode = 'widthHeight';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF212121),
              title: const Text(
                'Find Radius / Arc',
                style: TextStyle(color: kLight),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Width + Height'),
                          selected: mode == 'widthHeight',
                          onSelected: (_) =>
                              setLocalState(() => mode = 'widthHeight'),
                        ),
                        ChoiceChip(
                          label: const Text('Diameter'),
                          selected: mode == 'diameter',
                          onSelected: (_) =>
                              setLocalState(() => mode = 'diameter'),
                        ),
                        ChoiceChip(
                          label: const Text('Circumference'),
                          selected: mode == 'circumference',
                          onSelected: (_) =>
                              setLocalState(() => mode = 'circumference'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (mode == 'widthHeight') ...[
                      _inlineFieldDialog('Width / Chord', widthCtrl),
                      const SizedBox(height: 10),
                      _inlineFieldDialog('Height / Rise', heightCtrl),
                    ],
                    if (mode == 'diameter') ...[
                      _inlineFieldDialog('Diameter', diameterCtrl),
                    ],
                    if (mode == 'circumference') ...[
                      _inlineFieldDialog('Circumference', circumferenceCtrl),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: kRed)),
                ),
                TextButton(
                  onPressed: () {
                    double radius = 0.0;

                    if (mode == 'widthHeight') {
                      final w = _parseInches(widthCtrl.text);
                      final h = _parseInches(heightCtrl.text);
                      if (w > 0 && h > 0) {
                        radius = ((h * h) + math.pow(w / 2, 2)) / (2 * h);
                      }
                    } else if (mode == 'diameter') {
                      final d = _parseInches(diameterCtrl.text);
                      if (d > 0) radius = d / 2;
                    } else if (mode == 'circumference') {
                      final c = _parseInches(circumferenceCtrl.text);
                      if (c > 0) radius = c / (2 * math.pi);
                    }

                    if (radius > 0) {
                      setState(() {
                        radiusCtrl.text = fmtInches(radius);
                      });
                      _updateCalculateButtonState();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Use Radius', style: TextStyle(color: kGreen)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _inlineFieldDialog(String label, TextEditingController c) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: kLight, fontSize: 16),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: kLight),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: kBlack.withAlpha(128),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: kGreen, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void calculate() {
    if (!_isCalculateReady) return;

    final double radius = _parseInches(radiusCtrl.text);
    final int shots = _parseInches(measurement2Ctrl.text).round();

    if (radius <= 0 || shots <= 0 || _selectedPipeSize == null) {
      return;
    }

    final double pipeOD = (_selectedConduitType == BoxLayoutConduitType.emt
        ? bending_data.emtOD[_selectedPipeSize]
        : bending_data.grcOD[_selectedPipeSize]) ??
        0.0;

    final double developedLength = (math.pi * radius) / 2.0;
    final double spacing = developedLength / shots;
    final double anglePerShot = 90.0 / shots;

    double markA = 0.0; // First Bend
    double markB = 0.0; // Last Bend
    double markC = 0.0; // Cut Length

    if (_segmentedMode == SegmentedMode.arcOnly) {
      // Arc only:
      // First bend is one spacing from the measured end.
      // Last bend is the full developed length from that same end.
      // Cut length equals developed length.
      markA = spacing;
      markB = developedLength;
      markC = developedLength;
    } else {
      // Stubbed 90:
      // User enters finished stub height and optional leg length.
      final double stubHeight = _parseInches(measurement1Ctrl.text);
      final double legLength = _parseInches(measurement3Ctrl.text);

      if (stubHeight <= 0) return;

      // Book-style start mark is hidden from the UI:
      // Start Mark = Stub Height - (CLR + O.D./2)
      final double startMark = stubHeight - (radius + (pipeOD / 2.0));

      // What the worker actually uses:
      markA = startMark + spacing;     // First Bend
      markB = startMark + developedLength; // Last Bend

      // Your app's official gain formula:
      final double gain = ((2 - (math.pi / 2)) * radius) + pipeOD;

      // Pre-cut overall length
      markC = stubHeight + legLength - gain;
    }

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

  void _advanceKeypadFocus() {
    if (_activeController == radiusCtrl) {
      return _showKeypad(measurement2Ctrl);
    }

    if (_activeController == measurement2Ctrl) {
      if (_segmentedMode == SegmentedMode.stubbed90) {
        return _showKeypad(measurement1Ctrl);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isCalculateReady) {
          calculate();
        }
        _hideKeypad();
      });
      return;
    }

    if (_activeController == measurement1Ctrl) {
      _hideKeypad();
      return;
    }

    if (_activeController == measurement3Ctrl) {
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
        final decimalValue = _parseInches(_activeController!.text);
        _activeController!.text = fmtInches(decimalValue);
      }
      _activeController = null;
      _isKeypadVisible = false;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _hideKeypad();
      } else {
        if (travelCtrl.text.isEmpty) travelCtrl.text = '0"';
        if (takeUpCtrl.text.isEmpty) takeUpCtrl.text = '0"';
        if (gainCtrl.text.isEmpty) gainCtrl.text = '0"';
        if (radiusCtrl.text.isEmpty) radiusCtrl.text = '0"';
      }
    });
  }

  Future<void> _saveCustomBender() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: const Text(
          'Save Custom Bender',
          style: TextStyle(color: kLight),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter a nickname'),
          style: const TextStyle(color: kLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: kRed)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('Save', style: TextStyle(color: kGreen)),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
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
      });

      _hideKeypad();
    }
  }

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

  Widget _buildBenderSection() {
    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '1. BENDER & CONDUIT',
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
                  _inlineField(
                    'Centerline Radius (CLR)',
                    radiusCtrl,
                    onTap: () => _showKeypad(radiusCtrl),
                  ),
                  const SizedBox(height: 8),
                  _buildSilverButton(
                    label: 'Don’t Know Radius? Find Radius / Arc',
                    height: 40,
                    fontSize: 14,
                    onTap: _showRadiusFinderDialog,
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      'Use conduit centerline radius. If wrapping an object, add stand-off plus 1/2 conduit O.D. to the object radius.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Typical Shot Counts',
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
                            });
                            _updateCalculateButtonState();
                          },
                        ),
                      ),
                    ],
                  ),

                  if (_segmentedMode == SegmentedMode.stubbed90) ...[
                    const SizedBox(height: 14),
                    _inlineField(
                      'Stub Height',
                      measurement1Ctrl,
                      onTap: () => _showKeypad(measurement1Ctrl),
                    ),
                    _inlineField(
                      'Leg Length (optional)',
                      measurement3Ctrl,
                      onTap: () => _showKeypad(measurement3Ctrl),
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
                  _resultRow('Mark A — First Bend', markAOut),
                  _resultRow('Mark B — Last Bend', markBOut),
                  _resultRow('Mark C — Cut Length', markCOut),
                  const SizedBox(height: 10),
                  _resultRow('Spacing Between Bends', spacingOut),
                  _resultRow('Shots', shotsOut),
                  _resultRow('Angle Per Shot', anglePerShotOut),
                  const SizedBox(height: 15),
                  _buildSilverButton(
                    label: 'Start New Bend',
                    height: 40,
                    onTap: _startNewBend,
                  ),
                  const SizedBox(height: 12),
                  _buildSilverButton(
                    label: 'BUILD A RACK',
                    height: 44,
                    onTap: () {
                      // Placeholder for future concentric / rack builder handoff
                    },
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
          _buildBrandSelector(),
          const SizedBox(height: 12),
          _buildConduitTypeSelector(),
          const SizedBox(height: 12),
          _buildPipeSizeSelector(),
          const SizedBox(height: 12),
          _buildBendingMethodSelector(),
          const SizedBox(height: 12),
          if (_showTravelField) _inlineField('90° Travel', travelCtrl),
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
            onTap: () => _showKeypad(radiusCtrl),
          ),
          const SizedBox(height: 12),
          _buildSilverButton(
            label: _isEditMode
                ? 'Save Custom Bender'
                : 'Create / Edit Custom Bender',
            height: 40,
            isActive: _isEditMode,
            onTap: _isEditMode ? _saveCustomBender : _toggleEditMode,
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

  Widget _buildBendingMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSilverButton(
            label: 'Use Arrow Mark',
            height: 40,
            isActive: _bendingMethod == bending_data.BendingMethod.arrow,
            onTap: () =>
                setState(() => _bendingMethod = bending_data.BendingMethod.arrow),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSilverButton(
            label: 'Use Centerline',
            height: 40,
            isActive: _bendingMethod == bending_data.BendingMethod.centerline,
            onTap: () => setState(
                  () => _bendingMethod = bending_data.BendingMethod.centerline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandSelector() {
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
          value: _selectedBrand,
          isExpanded: true,
          hint: const Text(
            'Select Bender Brand (optional)',
            style: TextStyle(color: Colors.white70),
          ),
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
                          color: kLight,
                          fontWeight: FontWeight.bold,
                        ),
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: const Text(
          'Segmented 90 + Radius Help',
          style: TextStyle(color: kLight),
        ),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'Use this screen to solve a segmented 90 using a centerline radius and a chosen number of shots.',
                style: TextStyle(
                  color: kLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '1. Select conduit type and pipe size. Brand is optional and only helps auto-fill CLR / take-up data when available.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 10),
              Text(
                '2. Enter stub height and number of shots. If you do not know the radius, use the Find Radius / Arc button.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 10),
              Text(
                '3. The app calculates developed length, spacing between bends, angle per shot, and bend mark locations.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    String infoText =
        'Step 1: Select conduit type, pipe size, and optional bender data.';

    if (_currentStep == 1) {
      infoText =
      'Step 2: Enter the conduit centerline radius first. Then choose a shot count. Use Arc Only for just the curve, or Stubbed 90 to add stub height and leg length.';
    } else if (_currentStep == 2) {
      infoText =
      'Step 3: Press CALCULATE to solve developed length, spacing, and bend marks.';
    } else if (_currentStep == 3) {
      infoText =
      'Calculation complete. Measure Mark A, Mark B, and Mark C from the same end of the pipe.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Container(
        height: 120,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBlack.withAlpha(128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5),
        ),
        child: Center(
          child: Text(
            infoText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kLight, fontSize: 18),
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
}