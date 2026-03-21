import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:pipe_and_wire_clean/keypad_5.dart';
import 'package:pipe_and_wire_clean/bending_data.dart' as bending_data;
import 'package:flutter/services.dart'; // Added for SystemChrome

import 'code_screen.dart';


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

class _BenderStartingPointScreenState extends State<BenderStartingPointScreen> {
  // State management for workflow
  int _currentStep = 0;
  bool _isBenderExpanded = true;
  bool _isMeasurementsExpanded = false;
  bool _isResultsExpanded = false;
  bool _isCalculateReady = false;

  // Bender & Conduit State
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
  bending_data.BendingMethod _bendingMethod = bending_data.BendingMethod.arrow; // Uses BendingMethod from bending_data.dart

  // --- NEW: Custom Bender State ---
  bool _isEditMode = false;
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


  // Raw values
  double _rawMarkA = 0.0;
  double _rawMarkB = 0.0;
  double _rawCut = 0.0;
  double _rawTakeUp = 0.0;
  double _rawGain = 0.0;


  // Keypad State
  bool _isKeypadVisible = false;
  TextEditingController? _activeController;

  // Conditional Travel Field Visibility
  bool _showTravelField = false;


  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    final allCtrls = [
      measurement1Ctrl,
      measurement2Ctrl,
      measurement3Ctrl,
      travelCtrl, // Disposed travel controller
      takeUpCtrl,
      gainCtrl,
      radiusCtrl,
      setbackCtrl
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
        ..._customBenders.map((b) =>
        {'type': 'bender', 'name': b.brand})
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
        if (isReady) {
          _currentStep = 2;
        }
      });
    }
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
        travelCtrl.text = ''; // Clear travel
        takeUpCtrl.text = '';
        gainCtrl.text = '';
        setbackCtrl.text = '';
        radiusCtrl.text = '';
        _showTravelField = false; // Hide travel field
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
          ? bending_data.emtOD[_selectedPipeSize] // Uses emtOD from bending_data.dart
          : bending_data.grcOD[_selectedPipeSize]) ?? 0.0; // Uses grcOD from bending_data.dart

      if (bender.clr > 0 && pipeOD > 0) {
        calculatedGain = bending_data.calculateGain90(bender.clr, pipeOD); // Uses calculateGain90 from bending_data.dart
      }
      calculatedTravel = (math.pi * bender.clr) / 2; // Calculate 90° Travel
    }

    setState(() {
      _rawTakeUp = bender?.deduct ?? 0.0;
      _rawGain = calculatedGain;

      travelCtrl.text = bender != null ? fmtInches(calculatedTravel) : ''; // Display 90° Travel
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
      measurement1Ctrl.clear();
      measurement2Ctrl.clear();
      measurement3Ctrl.clear();

      travelCtrl.clear(); // Clear travel
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
      _isResultsExpanded = false;
      _isEditMode = false;
      _resetToStep(0);
      _showTravelField = false;
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
      return bending_data.pipeSizes; // Uses pipeSizes from bending_data.dart
    }

    final List<String> availableSizes = [];
    switch (_selectedBrand) {
      case 'IDEAL':
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

    // Clear previous results
    _rawCut = 0.0;
    _rawMarkA = 0.0;
    _rawMarkB = 0.0;
    markAOut = '';
    markBOut = '';
    markCOut = '';

    // Placeholder for new calculation logic
    // You will add your Segmented 90 + Radius calculation here
    // For now, it just advances the UI
    
    setState(() {
      _currentStep = 3;
      _isResultsExpanded = true;
      _isMeasurementsExpanded = false;
      _hideKeypad();
    });
  }


  void _advanceKeypadFocus() {
    if (_activeController == measurement1Ctrl) {
      return _showKeypad(measurement2Ctrl);
    }
    if (_activeController == measurement2Ctrl) {
      return _showKeypad(measurement3Ctrl);
    }
    if (_activeController == measurement3Ctrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isCalculateReady) {
          calculate();
        }
        _hideKeypad();
      });
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
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _hideKeypad();
      } else {
        if (travelCtrl.text.isEmpty) travelCtrl.text = '0"'; // Custom travel can be edited
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
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF212121),
            title: const Text(
                'Save Custom Bender', style: TextStyle(color: kLight)),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter a nickname'),
              style: const TextStyle(color: kLight),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: kRed))),
              TextButton(onPressed: () =>
                  Navigator.of(context).pop(nameController.text),
                  child: const Text('Save', style: TextStyle(color: kGreen))),
            ],
          ),
    );

    if (name != null && name.isNotEmpty) {
      final newBender = bending_data.Bender(
        brand: name,
        model: name, // Use name for model as well for custom benders
        conduitSize: _selectedPipeSize ?? 'N/A',
        conduitType: _selectedConduitType == BoxLayoutConduitType.emt
            ? bending_data.ConduitType.emt
            : bending_data.ConduitType.rigid, // Only EMT or GRC (Rigid) allowed
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
        title: const Text('Bender Starting Point'),
        foregroundColor: kLight,
        actions: [
          IconButton(icon: const Icon(Icons.info_outline),
              onPressed: () => _showHelpDialog(context)),
          TextButton(
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const CodeScreen())),
            child: const Text('NEC', style: TextStyle(
                color: kLight, fontSize: 18, fontWeight: FontWeight.bold)),
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
              if (!_isKeypadVisible) // Always show info bar if keypad not visible
                _buildInfoBar(),
              if (_isKeypadVisible)
                NumericInputKeypad(onTap: _onKeypadTap),
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
                  label: 'Done', height: 40,
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
    bool isEnabled = _currentStep >= 1;
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
                children: [
                  _inlineField('Measurement A', measurement1Ctrl,
                      onTap: () => _showKeypad(measurement1Ctrl)),
                  _inlineField('Measurement B', measurement2Ctrl,
                      onTap: () => _showKeypad(measurement2Ctrl)),
                  _inlineField('Measurement C', measurement3Ctrl,
                      onTap: () => _showKeypad(measurement3Ctrl)),
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
    bool isEnabled = _currentStep >= 3;
    return _buildGroupContainer(
      child: Column(
        children: [
          _buildSilverButton(
            label: '4. RESULTS',
            fontSize: 18,
            height: 50,
            isActive: _currentStep == 3,
            onTap: isEnabled ? () =>
                setState(() => _isResultsExpanded = !_isResultsExpanded) : null,
          ),
          if (_isResultsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
              child: Column(
                children: [
                  _resultRow('Result 1', markAOut),
                  _resultRow('Result 2', markBOut),
                  _resultRow('Result 3', markCOut),
                  const SizedBox(height: 15),
                  _buildSilverButton(label: 'Start New Bend',
                      height: 40,
                      onTap: _startNewBend),
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
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.white70)),
          Text(value, style: const TextStyle(
              fontSize: 18, color: kLight, fontWeight: FontWeight.bold)),
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
          if (_showTravelField) // Conditionally display the travel field
            _inlineField('90° Travel', travelCtrl),
          _inlineField('Take Up', takeUpCtrl,
              onTap: _isEditMode ? () => _showKeypad(takeUpCtrl) : null),
          _inlineField('Gain90', gainCtrl,
              onTap: _isEditMode ? () => _showKeypad(gainCtrl) : null),
          _inlineField('Setback', setbackCtrl),
          _inlineField('Radius / CLR', radiusCtrl,
              onTap: _isEditMode ? () => _showKeypad(radiusCtrl) : null),
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

  Widget _buildBendingMethodSelector() {
    return Row(
      children: [
        Expanded(child: _buildSilverButton(label: 'Use Arrow Mark',
            height: 40,
            isActive: _bendingMethod == bending_data.BendingMethod.arrow,
            onTap: () => setState(() => _bendingMethod = bending_data.BendingMethod.arrow))),
        const SizedBox(width: 10),
        Expanded(child: _buildSilverButton(label: 'Use Centerline',
            height: 40,
            isActive: _bendingMethod == bending_data.BendingMethod.centerline,
            onTap: () =>
                setState(() => _bendingMethod = bending_data.BendingMethod.centerline))),
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
    showDialog(context: context, builder: (context) =>
        AlertDialog(backgroundColor: const Color(0xFF212121),
            title: const Text('Bender Starting Point Help', style: TextStyle(color: kLight)),
            content: const SingleChildScrollView(child: ListBody(
                children: <Widget>[
                  Text('This is a generic starting point screen for new bending calculations.',
                      style: TextStyle(color: kLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                      '1. Bender & Conduit: First, select your bender brand, conduit type (EMT, GRC, etc.), and pipe size. This loads the correct data for the calculation.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 15),
                  Text('Gain vs. Take-Up:', style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                      '• GAIN is used only to determine the CUT LENGTH of the pipe. It ensures the final distance between bends is correct.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 10),
                  Text(
                      '• TAKE-UP is used only to determine WHERE TO MARK the pipe for bending.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 15),
                  Text('Bending Methods Explained:', style: TextStyle(
                      color: kLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
                  SizedBox(height: 10),
                  Text(
                      'This app provides two valid methods for marking your second bend. Both produce the same final result, so choose the one you are most comfortable with.',
                      style: TextStyle(color: Colors.white70)),
                ])),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: kRed)))
            ]));
  }

  Widget _buildInfoBar() {
    String infoText = "Step 1: Select your bender, conduit, and pipe size.";
    if (_currentStep == 1) {
      infoText = "Step 2: Enter the measurements for your bend.";
    } else if (_currentStep == 2) {
      infoText =
      "Step 3: All measurements entered. Press 'CALCULATE' to see results.";
    } else if (_currentStep == 3) {
      infoText = "Calculation complete. See results above.";
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Container(
        height: 120,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kBlack.withAlpha(128),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC0C0C0), width: 1.5)),
        child: Center(child: Text(infoText, textAlign: TextAlign.center,
            style: const TextStyle(color: kLight, fontSize: 18))),
      ),
    );
  }

  Widget _buildGroupContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
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
          colors: isActive ? [kRed, const Color(0xFFD43D37)] : (isEnabled ? [
            const Color(0xFF4E4E52),
            const Color(0xFF2C3030)
          ] : [Colors.grey.shade800, Colors.grey.shade900]),
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(6),
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
          Expanded(child: Text('''
              label, style: const TextStyle(fontSize: 16, color: kLight))),'''
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
                            color: isActive ? kGreen : (isEditable ? kGreen
                                .withAlpha(100) : Colors.white54),
                            width: isActive || isEditable ? 2 : 1)),
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
